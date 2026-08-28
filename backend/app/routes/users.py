from flask import Blueprint, g, jsonify, request

from ..auth import require_auth
from ..extensions import get_db
from ..services.interaction_logger import log_interaction
from ..services.profile_service import ensure_profile

bp = Blueprint("users", __name__, url_prefix="/api/users")


def _serialize_profile(profile: dict) -> dict:
    return {
        "id": profile["_id"],
        "name": profile.get("name"),
        "email": profile.get("email"),
        "role": profile.get("role", "athlete"),
        "onboarding": profile.get("onboarding", {}),
        "coach_id": profile.get("coach_id"),
    }


@bp.get("/me")
@require_auth
def get_me():
    profile = ensure_profile(g.user_id, g.user_email, g.user_metadata.get("full_name"))
    return jsonify(_serialize_profile(profile))


@bp.put("/me/onboarding")
@require_auth
def update_onboarding():
    body = request.get_json(force=True) or {}
    profile = ensure_profile(g.user_id, g.user_email, g.user_metadata.get("full_name"))

    db = get_db()
    db.users.update_one({"_id": g.user_id}, {"$set": {"onboarding": body}})

    log_interaction(g.user_id, "onboarding_completed", body, source="user")
    log_interaction(
        g.user_id,
        "goal_set",
        {"primary_goal": body.get("primary_goal"), "set_by": "onboarding"},
        source="user",
    )

    updated = get_db().users.find_one({"_id": g.user_id})
    return jsonify(_serialize_profile(updated))
