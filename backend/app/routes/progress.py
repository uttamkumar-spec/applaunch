from datetime import datetime, timedelta, timezone

from flask import Blueprint, g, jsonify

from ..auth import require_auth
from ..extensions import get_db

bp = Blueprint("progress", __name__, url_prefix="/api/progress")


@bp.get("/summary")
@require_auth
def get_summary():
    db = get_db()
    completions = list(
        db.workout_completions.find({"user_id": g.user_id}, {"completed_at": 1}).sort("completed_at", -1)
    )
    completed_dates = {c["completed_at"].date() for c in completions}

    today = datetime.now(timezone.utc).date()
    weekly_completion = [1.0 if (today - timedelta(days=i)) in completed_dates else 0.0 for i in range(6, -1, -1)]

    workouts_this_week = sum(1 for c in completed_dates if (today - c).days < 7)

    streak = 0
    cursor = today
    while cursor in completed_dates:
        streak += 1
        cursor -= timedelta(days=1)

    return jsonify(
        {
            "workouts_this_week": workouts_this_week,
            "workout_goal_this_week": 3,
            "current_streak": streak,
            "total_workouts_logged": len(completions),
            "weekly_completion": weekly_completion,
        }
    )
