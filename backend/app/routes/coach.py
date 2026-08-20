from datetime import datetime, timedelta, timezone

from bson import ObjectId
from flask import Blueprint, g, jsonify, request

from ..auth import require_auth, require_role
from ..extensions import get_db, limiter
from ..services import gemini_service
from ..services.interaction_logger import log_interaction

bp = Blueprint("coach", __name__, url_prefix="/api")


@bp.get("/coaches")
@require_auth
def list_coaches():
    db = get_db()
    coaches = list(db.users.find({"role": "coach"}))
    return jsonify(
        [
            {
                "id": c["_id"],
                "name": c.get("name"),
                "specialty": (c.get("coach_profile") or {}).get("specialty", "General fitness"),
                "bio": (c.get("coach_profile") or {}).get("bio", ""),
                "athlete_count": db.users.count_documents({"coach_id": c["_id"]}),
            }
            for c in coaches
        ]
    )


@bp.post("/coach-requests")
@require_auth
def create_coach_request():
    body = request.get_json(force=True) or {}
    coach_id = body.get("coach_id")
    if not coach_id:
        return jsonify({"error": "coach_id is required"}), 400

    db = get_db()
    if not db.users.find_one({"_id": coach_id, "role": "coach"}):
        return jsonify({"error": "coach not found"}), 404

    doc = {
        "athlete_id": g.user_id,
        "coach_id": coach_id,
        "status": "pending",
        "ai_recommendation_note": body.get("ai_recommendation_note"),
        "created_at": datetime.now(timezone.utc),
    }
    result = db.coach_requests.insert_one(doc)

    log_interaction(
        g.user_id, "coach_request_created", {"coach_id": coach_id, "request_id": str(result.inserted_id)}, source="user"
    )
    return jsonify({"id": str(result.inserted_id), "status": "pending"}), 201


@bp.get("/coach/requests")
@require_role("coach")
def list_coach_requests():
    db = get_db()
    requests_ = list(db.coach_requests.find({"coach_id": g.user_id, "status": "pending"}))
    out = []
    for r in requests_:
        athlete = db.users.find_one({"_id": r["athlete_id"]}, {"name": 1})
        out.append(
            {
                "id": str(r["_id"]),
                "athlete_id": r["athlete_id"],
                "athlete_name": (athlete or {}).get("name", "Athlete"),
                "status": r["status"],
                "ai_recommendation_note": r.get("ai_recommendation_note"),
            }
        )
    return jsonify(out)


@bp.put("/coach/requests/<request_id>")
@require_role("coach")
def respond_to_request(request_id):
    body = request.get_json(force=True) or {}
    accept = bool(body.get("accept"))

    db = get_db()
    req = db.coach_requests.find_one({"_id": ObjectId(request_id), "coach_id": g.user_id})
    if not req:
        return jsonify({"error": "request not found"}), 404

    new_status = "accepted" if accept else "declined"
    db.coach_requests.update_one({"_id": req["_id"]}, {"$set": {"status": new_status}})

    if accept:
        db.users.update_one({"_id": req["athlete_id"]}, {"$set": {"coach_id": g.user_id}})

    log_interaction(
        req["athlete_id"],
        "coach_request_resolved",
        {"coach_id": g.user_id, "status": new_status},
        source="coach",
    )
    return jsonify({"status": new_status})


@bp.get("/coach/athletes")
@require_role("coach")
def list_athletes():
    db = get_db()
    athletes = list(db.users.find({"coach_id": g.user_id}))
    out = []
    for a in athletes:
        streak = 0
        cursor_date = datetime.now(timezone.utc).date()
        completed_dates = {
            c["completed_at"].date()
            for c in db.workout_completions.find({"user_id": a["_id"]}, {"completed_at": 1})
        }
        while cursor_date in completed_dates:
            streak += 1
            cursor_date -= timedelta(days=1)

        out.append(
            {
                "id": a["_id"],
                "name": a.get("name"),
                "primary_goal": (a.get("onboarding") or {}).get("primary_goal", "General fitness"),
                "current_streak": streak,
            }
        )
    return jsonify(out)


@bp.post("/coach/plans/generate")
@require_role("coach")
@limiter.limit("15/minute")
def generate_plan():
    body = request.get_json(force=True) or {}
    athlete_id = body.get("athlete_id")
    notes = body.get("notes")
    if not athlete_id:
        return jsonify({"error": "athlete_id is required"}), 400

    db = get_db()
    athlete = db.users.find_one({"_id": athlete_id})
    if not athlete:
        return jsonify({"error": "athlete not found"}), 404

    onboarding = athlete.get("onboarding") or {}
    profile_summary = (
        f"experience: {onboarding.get('experience_level', 'unknown')}, "
        f"goal: {onboarding.get('primary_goal', 'general fitness')}, "
        f"days/week available: {onboarding.get('days_per_week', 3)}, "
        f"equipment: {onboarding.get('equipment_access', 'none')}"
    )

    try:
        plan = gemini_service.generate_workout_plan(profile_summary, notes)
    except gemini_service.GeminiError as exc:
        return jsonify({"error": str(exc)}), 502

    return jsonify(plan)


@bp.post("/coach/plans/<athlete_id>/push")
@require_role("coach")
def push_plan(athlete_id):
    body = request.get_json(force=True) or {}
    db = get_db()

    athlete = db.users.find_one({"_id": athlete_id, "coach_id": g.user_id})
    if not athlete:
        return jsonify({"error": "athlete not found or not assigned to you"}), 404

    db.active_plans.update_one(
        {"_id": athlete_id},
        {"$set": {"plan": body, "assigned_by": g.user_id, "updated_at": datetime.now(timezone.utc)}},
        upsert=True,
    )

    log_interaction(
        athlete_id,
        "workout_plan_assigned",
        {"plan": body, "assigned_by_coach": g.user_id},
        source="coach",
    )
    return jsonify({"status": "pushed"})
