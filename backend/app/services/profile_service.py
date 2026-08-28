from datetime import datetime, timezone

from ..extensions import get_db


def ensure_profile(user_id: str, email: str | None, name: str | None) -> dict:
    """Fetches the Mongo profile for this Supabase user, creating a default
    'athlete' one on first access (e.g. right after signup)."""
    db = get_db()
    profile = db.users.find_one({"_id": user_id})
    if profile:
        return profile

    profile = {
        "_id": user_id,
        "name": name or (email.split("@")[0] if email else "Athlete"),
        "email": email,
        "role": "athlete",
        "onboarding": {},
        "coach_id": None,
        "created_at": datetime.now(timezone.utc),
    }
    db.users.insert_one(profile)
    return profile


def get_profile(user_id: str) -> dict | None:
    return get_db().users.find_one({"_id": user_id})
