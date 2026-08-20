import json

import requests
from flask import current_app

_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

_COACH_SYSTEM_PROMPT = (
    "You are an encouraging, patient AI fitness coach inside the FitMoveLab app. "
    "Your users are complete beginners who may feel intimidated by fitness. "
    "Keep answers short (3-6 sentences unless asked for detail), avoid jargon, "
    "never shame the user for missed workouts or slow progress, and always suggest "
    "consulting a doctor before anything that sounds like a medical concern or an "
    "injury. Be specific and actionable rather than generic."
)

_PLAN_SYSTEM_PROMPT = (
    "You are a certified strength & conditioning coach writing a workout plan for a "
    "beginner athlete inside the FitMoveLab app. Respond with ONLY valid JSON matching "
    "this exact shape, no markdown fences, no commentary:\n"
    "{"
    '"title": string, "level": string, "description": string, '
    '"days": [{"id": string, "name": string, "exercises": ['
    '{"id": string, "name": string, "sets": number, "reps": string, '
    '"rest_seconds": number, "beginner_tip": string, "instructions": string}'
    "]}]}\n"
    "Use 2-4 training days, 3-6 exercises per day, and keep tips beginner-friendly."
)


class GeminiError(Exception):
    pass


def _call_gemini(
    system_prompt: str,
    user_prompt: str,
    json_output: bool = False,
    images_b64: list[str] | None = None,
) -> str:
    api_key = current_app.config["GEMINI_API_KEY"]
    model = current_app.config["GEMINI_MODEL"]
    if not api_key:
        raise GeminiError("Gemini is not configured on the server yet")

    parts = [{"inline_data": {"mime_type": "image/jpeg", "data": img}} for img in (images_b64 or [])]
    parts.append({"text": user_prompt})

    body = {
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "contents": [{"role": "user", "parts": parts}],
        "generationConfig": {"temperature": 0.7},
    }
    if json_output:
        body["generationConfig"]["responseMimeType"] = "application/json"

    try:
        res = requests.post(
            f"{_BASE_URL}/{model}:generateContent",
            params={"key": api_key},
            json=body,
            timeout=30,
        )
    except requests.exceptions.RequestException as exc:
        raise GeminiError(f"Could not reach Gemini: {exc}") from exc

    if res.status_code >= 400:
        raise GeminiError(f"Gemini API error {res.status_code}: {res.text}")

    data = res.json()
    try:
        return data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError) as exc:
        raise GeminiError(f"Unexpected Gemini response shape: {data}") from exc


def coach_reply(message: str, athlete_context: str | None = None) -> str:
    prompt = message if not athlete_context else f"Athlete context: {athlete_context}\n\nMessage: {message}"
    return _call_gemini(_COACH_SYSTEM_PROMPT, prompt).strip()


def coach_recommendation(message: str, coaches_summary: str) -> str:
    system = (
        "You help a beginner athlete figure out what kind of human coach would suit "
        "them, based on the athlete's message and the list of available coaches below. "
        "Recommend one (by name) if a good fit exists, explain briefly why, or say none "
        "are a great fit yet. Keep it to 3-4 sentences.\n\nAvailable coaches:\n"
        + coaches_summary
    )
    return _call_gemini(system, message).strip()


def generate_workout_plan(athlete_profile: str, notes: str | None) -> dict:
    prompt = f"Athlete profile: {athlete_profile}"
    if notes:
        prompt += f"\nCoach notes: {notes}"

    raw = _call_gemini(_PLAN_SYSTEM_PROMPT, prompt, json_output=True)
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise GeminiError(f"Gemini did not return valid JSON: {raw}") from exc


def _form_check_system_prompt(width: int, height: int) -> str:
    return (
        "You are an expert strength coach and physiotherapist screening a beginner "
        "athlete's photo or video frame for form issues. The image is "
        f"{width}x{height} pixels. Identify muscular imbalances, posture/alignment "
        "issues, form breakdowns, and injury risk. For each issue found, give a pixel "
        "coordinate (x, y) inside the image bounds pointing at the specific body part. "
        "Be encouraging, not alarming — this is for someone new to fitness. Respond "
        "with ONLY valid JSON matching this exact shape, no markdown fences, no "
        "commentary:\n"
        "{"
        '"summary": string, '
        '"flaws": [{"label": string, "explanation": string, "x": number, "y": number, '
        '"severity": "low"|"medium"|"high"}], '
        '"muscles_needing_strength": [string], '
        '"recommended_exercises": [string]'
        "}\n"
        "If the image is unclear, too zoomed out, or you can't confidently assess it, "
        'return an empty "flaws" array and say so in the summary rather than guessing.'
    )


def analyse_form(image_b64: str, width: int, height: int, question: str | None = None) -> dict:
    """Runs a single image (or video frame) through Gemini for a beginner-friendly
    form/muscular-imbalance check, returning structured flaws with pixel coordinates
    so the caller can draw annotations."""
    prompt = question or "Analyse this athlete's form, posture, and muscular balance."
    raw = _call_gemini(
        _form_check_system_prompt(width, height),
        prompt,
        json_output=True,
        images_b64=[image_b64],
    )
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise GeminiError(f"Gemini did not return valid JSON: {raw}") from exc


def summarise_form_check_frames(question: str, per_frame_summaries: list[str]) -> dict:
    """Rolls up several per-frame form-check results (from a video) into one
    cohesive coaching summary + a merged exercise list."""
    system = (
        "You are an expert strength coach. Merge these frame-by-frame form-check "
        "notes from one video into a single cohesive, encouraging summary for a "
        "beginner athlete, plus a de-duplicated list of recommended exercises and "
        "muscles needing strength work. Respond with ONLY valid JSON: "
        '{"summary": string, "muscles_needing_strength": [string], '
        '"recommended_exercises": [string]}'
    )
    prompt = f"Original question: {question}\n\n" + "\n\n".join(per_frame_summaries)
    raw = _call_gemini(system, prompt, json_output=True)
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise GeminiError(f"Gemini did not return valid JSON: {raw}") from exc
