from datetime import datetime, timezone

from flask import Blueprint, g, jsonify, request

from ..auth import require_role
from ..extensions import get_db
from ..services.supabase_admin_service import SupabaseAdminError, create_auth_user

bp = Blueprint("admin", __name__, url_prefix="/api/admin")

_DEFAULT_LIMITS = {"max_athletes_per_coach": 20, "daily_ai_messages_per_athlete": 50}


@bp.get("/users")
@require_role("admin")
def list_users():
    users = list(get_db().users.find({}))
    return jsonify(
        [
            {
                "id": u["_id"],
                "name": u.get("name"),
                "email": u.get("email"),
                "role": u.get("role", "athlete"),
                "created_at": u.get("created_at").isoformat() if u.get("created_at") else None,
            }
            for u in users
        ]
    )


@bp.post("/users")
@require_role("admin")
def create_user():
    body = request.get_json(force=True) or {}
    name = (body.get("name") or "").strip()
    email = (body.get("email") or "").strip()
    password = body.get("password") or ""
    role = body.get("role", "athlete")

    if not (name and email and password):
        return jsonify({"error": "name, email and password are required"}), 400
    if role not in ("athlete", "coach", "admin"):
        return jsonify({"error": "invalid role"}), 400

    try:
        user_id = create_auth_user(email, password, name)
    except SupabaseAdminError as exc:
        return jsonify({"error": str(exc)}), 502

    db = get_db()
    db.users.insert_one(
        {
            "_id": user_id,
            "name": name,
            "email": email,
            "role": role,
            "onboarding": {},
            "coach_id": None,
            "created_by_admin": g.user_id,
            "created_at": datetime.now(timezone.utc),
        }
    )
    return jsonify({"id": user_id, "name": name, "email": email, "role": role}), 201


@bp.get("/limits")
@require_role("admin")
def get_limits():
    limits = get_db().platform_config.find_one({"_id": "limits"}) or _DEFAULT_LIMITS
    return jsonify(
        {
            "max_athletes_per_coach": limits.get("max_athletes_per_coach", 20),
            "daily_ai_messages_per_athlete": limits.get("daily_ai_messages_per_athlete", 50),
        }
    )


@bp.put("/limits")
@require_role("admin")
def update_limits():
    body = request.get_json(force=True) or {}
    max_athletes = int(body.get("max_athletes_per_coach", 20))
    daily_messages = int(body.get("daily_ai_messages_per_athlete", 50))

    get_db().platform_config.update_one(
        {"_id": "limits"},
        {"$set": {"max_athletes_per_coach": max_athletes, "daily_ai_messages_per_athlete": daily_messages}},
        upsert=True,
    )
    return jsonify({"max_athletes_per_coach": max_athletes, "daily_ai_messages_per_athlete": daily_messages})
