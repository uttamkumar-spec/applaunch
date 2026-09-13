"""Builds a compact lifestyle-data summary for one athlete — onboarding
answers, workout consistency, recent nutrition, recent chat history — so a
coach responding to a routed question has fast context without opening
several other screens, and so the AI drafting tool can ground its suggestion
in what we actually know about that athlete."""

from datetime import datetime, timezone

from ..extensions import get_db


def _current_streak(user_id: str) -> int:
    db = get_db()
    completed_dates = {
        c["completed_at"].date() for c in db.workout_completions.find({"user_id": user_id}, {"completed_at": 1})
    }
    streak = 0
    cursor = datetime.now(timezone.utc).date()
    while cursor in completed_dates:
        streak += 1
        cursor = cursor.fromordinal(cursor.toordinal() - 1)
    return streak


def build_summary(user_id: str) -> dict:
    db = get_db()
    profile = db.users.find_one({"_id": user_id}) or {}
    onboarding = profile.get("onboarding") or {}

    recent_meals = list(
        db.meals_log.find({"user_id": user_id}, {"description": 1}).sort("logged_at", -1).limit(3)
    )
    recent_water = db.water_log.find_one({"user_id": user_id}, sort=[("date", -1)])
    recent_chat = list(
        db.chat_messages.find({"user_id": user_id}, {"role": 1, "text": 1}).sort("created_at", -1).limit(6)
    )

    return {
        "name": profile.get("name"),
        "onboarding": onboarding,
        "current_streak": _current_streak(user_id),
        "total_workouts_logged": db.workout_completions.count_documents({"user_id": user_id}),
        "recent_meals": [m.get("description") for m in reversed(recent_meals)],
        "recent_water_glasses": (recent_water or {}).get("glasses"),
        "recent_chat": [{"role": m["role"], "text": m["text"]} for m in reversed(recent_chat)],
    }


def build_summary_text(user_id: str) -> str:
    """Renders build_summary() as a compact text block for an LLM prompt or
    a coach's at-a-glance view."""
    s = build_summary(user_id)
    onboarding = s["onboarding"]

    lines = [
        f"Athlete: {s['name'] or 'Unknown'}",
        f"Experience: {onboarding.get('experience_level', 'unknown')}, "
        f"goal: {onboarding.get('primary_goal', 'unknown')}, "
        f"days/week: {onboarding.get('days_per_week', 'unknown')}, "
        f"equipment: {onboarding.get('equipment_access', 'unknown')}",
        f"Workout consistency: {s['current_streak']}-day streak, "
        f"{s['total_workouts_logged']} workouts logged total",
    ]
    if s["recent_meals"]:
        lines.append("Recent meals logged: " + "; ".join(s["recent_meals"]))
    if s["recent_water_glasses"] is not None:
        lines.append(f"Last logged water intake: {s['recent_water_glasses']} glasses")
    if s["recent_chat"]:
        chat_lines = "\n".join(f"  {m['role']}: {m['text']}" for m in s["recent_chat"])
        lines.append(f"Recent chat history:\n{chat_lines}")

    return "\n".join(lines)


def build_extended_context(user_id: str, limit: int = 40) -> str:
    """A deeper pull of this athlete's history for a coach asking a specific
    follow-up question that the compact build_summary_text() doesn't cover —
    drawn straight from the central user_interactions log, since that's
    already the record of everything meaningful that's happened to this
    athlete (chat, nutrition, workouts, goals, form checks, Strava syncs)."""
    db = get_db()
    profile = db.users.find_one({"_id": user_id}) or {}
    onboarding = profile.get("onboarding") or {}

    interactions = list(
        db.user_interactions.find({"user_id": user_id}, {"type": 1, "source": 1, "payload": 1, "created_at": 1})
        .sort("created_at", -1)
        .limit(limit)
    )

    lines = [
        f"Athlete: {profile.get('name') or 'Unknown'}",
        f"Onboarding answers: {onboarding}",
        f"\nMost recent {len(interactions)} logged events, oldest first:",
    ]
    for i in reversed(interactions):
        lines.append(f"- [{i['created_at'].date()}] {i['type']} ({i.get('source', 'system')}): {i.get('payload')}")

    return "\n".join(lines)
