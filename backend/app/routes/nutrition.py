from datetime import datetime, timezone

from flask import Blueprint, g, jsonify, request

from ..auth import require_auth
from ..extensions import get_db
from ..services.interaction_logger import log_interaction

bp = Blueprint("nutrition", __name__, url_prefix="/api/nutrition")


def _today() -> str:
    return datetime.now(timezone.utc).date().isoformat()


@bp.post("/habits/toggle")
@require_auth
def toggle_habit():
    body = request.get_json(force=True) or {}
    habit_id = body.get("habit_id")
    completed = bool(body.get("completed"))
    if not habit_id:
        return jsonify({"error": "habit_id is required"}), 400

    db = get_db()
    db.habits_log.update_one(
        {"user_id": g.user_id, "date": _today(), "habit_id": habit_id},
        {"$set": {"completed": completed, "updated_at": datetime.now(timezone.utc)}},
        upsert=True,
    )
    log_interaction(g.user_id, "habit_log", {"habit_id": habit_id, "completed": completed}, source="user")
    return jsonify({"status": "ok"})


@bp.post("/meals")
@require_auth
def log_meal():
    body = request.get_json(force=True) or {}
    description = (body.get("description") or "").strip()
    if not description:
        return jsonify({"error": "description is required"}), 400

    db = get_db()
    now = datetime.now(timezone.utc)
    db.meals_log.insert_one({"user_id": g.user_id, "description": description, "logged_at": now})
    log_interaction(g.user_id, "nutrition_log", {"kind": "meal", "description": description}, source="user")
    return jsonify({"status": "ok"})


@bp.post("/water")
@require_auth
def log_water():
    body = request.get_json(force=True) or {}
    glasses = int(body.get("glasses", 0))

    db = get_db()
    db.water_log.update_one(
        {"user_id": g.user_id, "date": _today()},
        {"$set": {"glasses": glasses, "updated_at": datetime.now(timezone.utc)}},
        upsert=True,
    )
    log_interaction(g.user_id, "nutrition_log", {"kind": "water", "glasses": glasses}, source="user")
    return jsonify({"status": "ok"})
