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

from ..extensions import get_db

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
}


def log_interaction(user_id: str, type_: str, payload: dict, source: str = "system") -> None:
    if type_ not in VALID_TYPES:
        raise ValueError(f"Unknown interaction type: {type_}")

    get_db().user_interactions.insert_one(
        {
            "user_id": user_id,
            "type": type_,
            "source": source,
            "payload": payload,
            "created_at": datetime.now(timezone.utc),
        }
    )
