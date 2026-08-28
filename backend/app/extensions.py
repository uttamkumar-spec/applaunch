from flask import g
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from pymongo import MongoClient
from pymongo.database import Database

_client: MongoClient | None = None
_db: Database | None = None


def _rate_limit_key() -> str:
    """Rate-limit per authenticated user where possible (set by
    app.auth.require_auth before the view runs), falling back to the
    caller's IP for unauthenticated requests."""
    return getattr(g, "user_id", None) or get_remote_address()


limiter = Limiter(key_func=_rate_limit_key, default_limits=[])


def init_mongo(app) -> None:
    global _client, _db
    _client = MongoClient(app.config["MONGODB_URI"])
    _db = _client[app.config["MONGODB_DB_NAME"]]

    _db.users.create_index("email", unique=True, sparse=True)
    _db.workout_completions.create_index([("user_id", 1), ("completed_at", -1)])
    _db.chat_messages.create_index([("user_id", 1), ("created_at", -1)])
    _db.habits_log.create_index([("user_id", 1), ("date", 1), ("habit_id", 1)], unique=True)
    _db.water_log.create_index([("user_id", 1), ("date", 1)], unique=True)
    _db.strava_tokens.create_index("user_id", unique=True)
    _db.coach_requests.create_index([("athlete_id", 1), ("status", 1)])
    _db.user_interactions.create_index([("user_id", 1), ("created_at", -1)])
    _db.user_interactions.create_index("type")


def get_db() -> Database:
    if _db is None:
        raise RuntimeError("MongoDB has not been initialized — call init_mongo(app) first.")
    return _db
