from datetime import datetime, timezone

from flask import Blueprint, current_app, g, jsonify, request

from ..auth import require_auth
from ..extensions import get_db, limiter
from ..services import gemini_service, guardrail_service
from ..services.interaction_logger import log_interaction
from ..services.profile_service import get_profile

bp = Blueprint("ai_chat", __name__, url_prefix="/api/ai")

# Allowlist model: a message only gets an instant AI reply when it matches an
# enabled auto_respond guardrail rule (see guardrail_service). Anything else —
# including a message matching no rule at all — routes to the athlete's coach,
# so an unmoderated AI reply is never the default for an unanticipated question.
_ROUTED_ACK_TEXT = "Thanks for asking — this one needs your coach's eyes on it. They'll follow up here shortly."

_NO_COACH_NUDGE_TEXT = (
    "This is a great question for a human coach to weigh in on, but you don't have one assigned yet. "
    'Head to "Find a Coach" to get matched with one — they\'ll be able to help with things like this.'
)


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


def _save_coach_side_reply(db, user_id: str, text: str) -> None:
    db.chat_messages.insert_one(
        {"user_id": user_id, "role": "coach", "text": text, "created_at": datetime.now(timezone.utc)}
    )


@bp.get("/chat/history")
@require_auth
def chat_history():
    db = get_db()
    messages = list(
        db.chat_messages.find({"user_id": g.user_id}, {"role": 1, "text": 1, "created_at": 1})
        .sort("created_at", 1)
        .limit(200)
    )
    return jsonify(
        [{"role": m["role"], "text": m["text"], "created_at": m["created_at"].isoformat()} for m in messages]
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

    profile = get_profile(g.user_id)
    coach_id = (profile or {}).get("coach_id")
    action, rule = guardrail_service.resolve(message, coach_id)

    if action == "route":
        if not coach_id:
            _save_coach_side_reply(db, g.user_id, _NO_COACH_NUDGE_TEXT)
            return jsonify({"reply": _NO_COACH_NUDGE_TEXT, "status": "needs_coach_assignment"})

        db.pending_coach_messages.insert_one(
            {
                "athlete_id": g.user_id,
                "coach_id": coach_id,
                "message": message,
                "matched_rule_id": rule["_id"] if rule else None,
                "matched_rule_label": rule.get("label") if rule else None,
                "status": "pending",
                "created_at": now,
            }
        )
        log_interaction(
            g.user_id,
            "chat_routed_to_coach",
            {"message": message, "matched_rule_label": (rule or {}).get("label")},
            source="system",
        )
        _save_coach_side_reply(db, g.user_id, _ROUTED_ACK_TEXT)
        return jsonify({"reply": _ROUTED_ACK_TEXT, "status": "routed_to_coach"})

    # auto_respond — rule is guaranteed non-None here (see guardrail_service.resolve)
    try:
        reply = gemini_service.coach_reply(message, _athlete_context(profile), rule.get("response_instructions"))
    except gemini_service.GeminiError as exc:
        return jsonify({"error": str(exc)}), 502

    _save_coach_side_reply(db, g.user_id, reply)
    log_interaction(
        g.user_id,
        "chat_message",
        {"user_message": message, "coach_reply": reply, "matched_rule_label": rule.get("label")},
        source=current_app.config["GEMINI_MODEL"],
    )

    return jsonify({"reply": reply, "status": "answered"})


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
        source=current_app.config["GEMINI_MODEL"],
    )
    return jsonify({"reply": reply})
