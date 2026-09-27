from datetime import datetime, timedelta, timezone

from flask import Blueprint, g, jsonify

from ..auth import require_auth
from ..extensions import get_db
from ..services import strava_service

bp = Blueprint("progress", __name__, url_prefix="/api/progress")


@bp.get("/summary")
@require_auth
def get_summary():
    db = get_db()
    completions = list(
        db.workout_completions.find({"user_id": g.user_id}, {"completed_at": 1}).sort("completed_at", -1)
    )
    completed_dates = {c["completed_at"].date() for c in completions}

    # If Strava is connected, activity dates count toward the streak too —
    # the athlete shouldn't have to also manually mark a workout complete
    # in the app just because it was already tracked on Strava.
    strava_activity_count = 0
    if strava_service.get_connection(g.user_id):
        try:
            for activity in strava_service.fetch_activities(g.user_id, per_page=60):
                raw_date = activity.get("date")
                if raw_date:
                    completed_dates.add(datetime.fromisoformat(raw_date).date())
                    strava_activity_count += 1
        except strava_service.StravaError:
            pass

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
            "total_workouts_logged": len(completions) + strava_activity_count,
            "weekly_completion": weekly_completion,
        }
    )
