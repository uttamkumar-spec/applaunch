from datetime import datetime, timezone

from flask import Blueprint, g, jsonify, request

from ..auth import require_auth
from ..extensions import get_db
from ..services.interaction_logger import log_interaction
from ..services.seed_data import DEFAULT_PLAN

bp = Blueprint("workouts", __name__, url_prefix="/api/workouts")


@bp.get("/plans")
@require_auth
def get_plans():
    active = get_db().active_plans.find_one({"_id": g.user_id})
    plan = active["plan"] if active else DEFAULT_PLAN
    return jsonify([plan])


@bp.post("/plans/<plan_id>/complete")
@require_auth
def complete_workout(plan_id):
    body = request.get_json(force=True) or {}
    day_id = body.get("day_id")
    completed_exercise_ids = body.get("completed_exercise_ids", [])

    db = get_db()
    now = datetime.now(timezone.utc)
    db.workout_completions.insert_one(
        {
            "user_id": g.user_id,
            "plan_id": plan_id,
            "day_id": day_id,
            "completed_exercise_ids": completed_exercise_ids,
            "completed_at": now,
        }
    )

    log_interaction(
        g.user_id,
        "workout_execution_summary",
        {
            "plan_id": plan_id,
            "day_id": day_id,
            "completed_exercise_ids": completed_exercise_ids,
        },
        source="user",
    )

    return jsonify({"status": "logged"})
