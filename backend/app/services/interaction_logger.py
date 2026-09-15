"""Central, UUID-keyed interaction log.

Every meaningful thing that happens to a user — chat turns with the AI
coach (including the raw Gemini response), goals set during onboarding or
by a human coach, workout plans assigned, workout execution summaries,
Strava activity syncs, and nutrition/habit logs — gets written here in
addition to whatever normalized collection serves the app's own queries.

The key is the user's Supabase auth UUID (`user_id`), reused as-is rather
than minting a second identity system. This collection is the raw dataset
intended for training a future in-house SLM: `scripts/export_training_data.py`
dumps it back out per-user as JSONL.
"""

from datetime import datetime, timezone

from flask import current_app

from ..extensions import get_db
from . import gemini_service

VALID_TYPES = {
    "onboarding_completed",
    "goal_set",
    "workout_plan_assigned",
    "workout_execution_summary",
    "chat_message",
    "nutrition_log",
    "habit_log",
    "strava_activity_synced",
    "coach_request_created",
    "coach_request_resolved",
    "form_analysis_completed",
    "chat_routed_to_coach",
}

# Types worth embedding for semantic search (see retrieval_service.py) — ones
# with enough natural-language substance to be useful as retrieval context.
# Structural/operational types (plan assignment, Strava syncs, coach request
# lifecycle) are left out; they're better served by a direct query than a
# semantic one.
EMBEDDABLE_TYPES = {
    "onboarding_completed",
    "goal_set",
    "workout_execution_summary",
    "chat_message",
    "nutrition_log",
    "habit_log",
}


def embedding_text(type_: str, payload: dict) -> str | None:
    """Renders a payload as a short natural-language string to embed. Returns
    None when the payload doesn't have enough substance to be worth it."""
    if type_ == "chat_message":
        return f"Athlete asked: {payload.get('user_message', '')}\nReply: {payload.get('coach_reply', '')}"
    if type_ == "nutrition_log":
        if payload.get("kind") == "water":
            return f"Logged water intake: {payload.get('glasses')} glasses"
        return f"Logged a meal: {payload.get('description', '')}"
    if type_ == "habit_log":
        status = "completed" if payload.get("completed") else "not completed"
        return f"Habit '{payload.get('habit_id')}' marked {status}"
    if type_ == "workout_execution_summary":
        exercises = ", ".join(payload.get("completed_exercise_ids") or [])
        return f"Completed workout (plan {payload.get('plan_id')}, day {payload.get('day_id')}): {exercises}"
    if type_ == "goal_set":
        return f"Set primary goal: {payload.get('primary_goal')}"
    if type_ == "onboarding_completed":
        return (
            f"Onboarding: experience {payload.get('experience_level')}, "
            f"goal {payload.get('primary_goal')}, "
            f"{payload.get('days_per_week')} days/week, "
            f"equipment {payload.get('equipment_access')}"
        )
    return None


def _embed_best_effort(user_id: str, interaction_id, type_: str, payload: dict, created_at) -> None:
    """Embeds the interaction for semantic search, if it's an embeddable type
    with real text. Never raises — a failed embedding should never affect the
    primary log write, which is the actual source of truth."""
    if type_ not in EMBEDDABLE_TYPES:
        return
    text = embedding_text(type_, payload)
    if not text:
        return

    try:
        vector = gemini_service.embed_text(text)
        if vector is None:
            return
        get_db().interaction_embeddings.insert_one(
            {
                "user_id": user_id,
                "interaction_id": interaction_id,
                "type": type_,
                "text": text,
                "embedding": vector,
                "created_at": created_at,
            }
        )
    except Exception:
        current_app.logger.warning("Failed to embed interaction %s", interaction_id, exc_info=True)


def log_interaction(user_id: str, type_: str, payload: dict, source: str = "system") -> None:
    if type_ not in VALID_TYPES:
        raise ValueError(f"Unknown interaction type: {type_}")

    created_at = datetime.now(timezone.utc)
    result = get_db().user_interactions.insert_one(
        {
            "user_id": user_id,
            "type": type_,
            "source": source,
            "payload": payload,
            "created_at": created_at,
        }
    )
    _embed_best_effort(user_id, result.inserted_id, type_, payload, created_at)
