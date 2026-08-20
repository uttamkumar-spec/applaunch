from datetime import datetime, timezone

from flask import Blueprint, g, jsonify, request

from ..auth import require_auth
from ..extensions import get_db, limiter
from ..services import gemini_service
from ..services.interaction_logger import log_interaction
from ..services.profile_service import get_profile

bp = Blueprint("ai_chat", __name__, url_prefix="/api/ai")


def _athlete_context(profile: dict | None) -> str | None:
    if not profile:
        return None
    onboarding = profile.get("onboarding") or {}
    if not onboarding:
        return None
    return (
        f"experience: {onboarding.get('experience_level')}, "
        f"goal: {onboarding.get('primary_goal')}, "
        f"days/week: {onboarding.get('days_per_week')}, "
        f"equipment: {onboarding.get('equipment_access')}"
    )


@bp.post("/chat")
@require_auth
@limiter.limit("20/minute")
def chat():
    body = request.get_json(force=True) or {}
    message = (body.get("message") or "").strip()
    if not message:
        return jsonify({"error": "message is required"}), 400

    db = get_db()
    now = datetime.now(timezone.utc)
    db.chat_messages.insert_one({"user_id": g.user_id, "role": "user", "text": message, "created_at": now})

    try:
        profile = get_profile(g.user_id)
        reply = gemini_service.coach_reply(message, _athlete_context(profile))
    except gemini_service.GeminiError as exc:
        return jsonify({"error": str(exc)}), 502

    db.chat_messages.insert_one(
        {"user_id": g.user_id, "role": "coach", "text": reply, "created_at": datetime.now(timezone.utc)}
    )

    log_interaction(
        g.user_id,
        "chat_message",
        {"user_message": message, "coach_reply": reply},
        source="gemini_2.5_flash",
    )

    return jsonify({"reply": reply})


@bp.post("/coach-recommendation")
@require_auth
@limiter.limit("20/minute")
def coach_recommendation():
    """Lets the athlete ask the AI which of the available human coaches
    fits them best — the 'find a coach' flow described in the product
    requirements. Any coach mentioned by name can then be requested via
    POST /coach-requests, with this note attached for the coach to see."""
    body = request.get_json(force=True) or {}
    message = (body.get("message") or "").strip()
    if not message:
        return jsonify({"error": "message is required"}), 400

    db = get_db()
    coaches = list(db.users.find({"role": "coach"}, {"name": 1, "coach_profile": 1}))
    if not coaches:
        return jsonify({"reply": "There aren't any coaches on the platform yet — check back soon!"})

    coaches_summary = "\n".join(
        f"- {c.get('name')}: {(c.get('coach_profile') or {}).get('specialty', 'General fitness')} — "
        f"{(c.get('coach_profile') or {}).get('bio', '')}"
        for c in coaches
    )

    try:
        reply = gemini_service.coach_recommendation(message, coaches_summary)
    except gemini_service.GeminiError as exc:
        return jsonify({"error": str(exc)}), 502

    log_interaction(
        g.user_id,
        "chat_message",
        {"user_message": message, "coach_reply": reply, "kind": "coach_recommendation"},
        source="gemini_2.5_flash",
    )
    return jsonify({"reply": reply})
