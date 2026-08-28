import base64
import tempfile
from pathlib import Path

from flask import Blueprint, g, jsonify, request

from ..auth import require_auth
from ..extensions import limiter
from ..services import gemini_service, vision_service
from ..services.interaction_logger import log_interaction

bp = Blueprint("form_analysis", __name__, url_prefix="/api/ai")

MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB
MAX_VIDEO_BYTES = 25 * 1024 * 1024  # 25 MB — keep base64 payloads reasonable
MAX_VIDEO_FRAMES = 6


def _estimate_b64_bytes(b64_string: str) -> int:
    padding = b64_string.count("=")
    return (len(b64_string) * 3) // 4 - padding


def _analyse_single_image(image_b64: str, question: str | None) -> dict:
    image_bytes = base64.b64decode(image_b64)
    width, height = vision_service.get_image_dimensions(image_bytes)
    result = gemini_service.analyse_form(image_b64, width, height, question)
    flaws = result.get("flaws", [])

    try:
        annotated_bytes = vision_service.draw_annotations(image_bytes, flaws)
        annotated_b64 = base64.b64encode(annotated_bytes).decode()
    except Exception:
        annotated_b64 = image_b64

    return {
        "summary": result.get("summary", ""),
        "flaws": flaws,
        "muscles_needing_strength": result.get("muscles_needing_strength", []),
        "recommended_exercises": result.get("recommended_exercises", []),
        "annotated_image_base64": annotated_b64,
    }


@bp.post("/analyse-media")
@require_auth
@limiter.limit("8/minute")
def analyse_media():
    body = request.get_json(force=True) or {}
    question = (body.get("question") or "").strip() or None
    image_b64 = body.get("image_base64")
    video_b64 = body.get("video_base64")

    if not image_b64 and not video_b64:
        return jsonify({"error": "image_base64 or video_base64 is required"}), 400
    if image_b64 and video_b64:
        return jsonify({"error": "provide only one of image_base64 or video_base64"}), 400

    if image_b64 and _estimate_b64_bytes(image_b64) > MAX_IMAGE_BYTES:
        return jsonify({"error": "image exceeds the 10MB limit"}), 413
    if video_b64 and _estimate_b64_bytes(video_b64) > MAX_VIDEO_BYTES:
        return jsonify({"error": "video exceeds the 25MB limit — try a shorter clip"}), 413

    try:
        if image_b64:
            result = _analyse_single_image(image_b64, question)
            media_kind = "image"
        else:
            result = _analyse_video(video_b64, question)
            media_kind = "video"
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    except gemini_service.GeminiError as exc:
        return jsonify({"error": str(exc)}), 502

    log_interaction(
        g.user_id,
        "form_analysis_completed",
        {
            "media_kind": media_kind,
            "question": question,
            "summary": result.get("summary"),
            "flaws": _flaws_for_log(result),
            "muscles_needing_strength": result.get("muscles_needing_strength", []),
            "recommended_exercises": result.get("recommended_exercises", []),
        },
        source="gemini_2.5_flash",
    )

    return jsonify(result)


def _flaws_for_log(result: dict) -> list:
    """Central log stores the structured coaching signal, not raw media."""
    if "frames" in result:
        return [
            {"timestamp_seconds": f["timestamp_seconds"], "flaws": f["flaws"]} for f in result["frames"]
        ]
    return result.get("flaws", [])


def _analyse_video(video_b64: str, question: str | None) -> dict:
    video_bytes = base64.b64decode(video_b64)

    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as f:
            f.write(video_bytes)
            tmp_path = f.name

        raw_frames, duration = vision_service.extract_video_frames(tmp_path, MAX_VIDEO_FRAMES)
    finally:
        if tmp_path:
            Path(tmp_path).unlink(missing_ok=True)

    if not raw_frames:
        raise ValueError("Could not extract frames from this video")

    frames_out = []
    per_frame_summaries = []
    all_muscles: list[str] = []
    all_exercises: list[str] = []

    for i, frame_bytes in enumerate(raw_frames):
        frame_b64 = base64.b64encode(frame_bytes).decode()
        width, height = vision_service.get_image_dimensions(frame_bytes)

        base_question = question or "Analyse this athlete's form and muscular balance."
        frame_question = f"{base_question} (frame {i + 1} of {len(raw_frames)}, video duration {duration}s)"
        try:
            result = gemini_service.analyse_form(frame_b64, width, height, frame_question)
        except gemini_service.GeminiError:
            continue

        flaws = result.get("flaws", [])
        per_frame_summaries.append(f"Frame {i + 1}: {result.get('summary', '')}")
        all_muscles.extend(result.get("muscles_needing_strength", []))
        all_exercises.extend(result.get("recommended_exercises", []))

        if not flaws:
            continue

        try:
            annotated_bytes = vision_service.draw_annotations(frame_bytes, flaws)
            annotated_b64 = base64.b64encode(annotated_bytes).decode()
        except Exception:
            annotated_b64 = frame_b64

        timestamp = round((i / max(len(raw_frames) - 1, 1)) * duration, 1)
        frames_out.append(
            {
                "frame_number": i + 1,
                "timestamp_seconds": timestamp,
                "annotated_image_base64": annotated_b64,
                "flaws": flaws,
            }
        )

    if per_frame_summaries:
        try:
            rollup = gemini_service.summarise_form_check_frames(
                question or "Analyse this athlete's form and muscular balance.", per_frame_summaries
            )
        except gemini_service.GeminiError:
            rollup = {"summary": f"Found {len(frames_out)} frame(s) worth a closer look.", "muscles_needing_strength": [], "recommended_exercises": []}
    else:
        rollup = {"summary": "Could not analyse this video — try a clearer, well-lit clip.", "muscles_needing_strength": [], "recommended_exercises": []}

    return {
        "summary": rollup.get("summary", ""),
        "muscles_needing_strength": rollup.get("muscles_needing_strength") or list(dict.fromkeys(all_muscles)),
        "recommended_exercises": rollup.get("recommended_exercises") or list(dict.fromkeys(all_exercises)),
        "frames": frames_out,
        "duration_seconds": duration,
    }
