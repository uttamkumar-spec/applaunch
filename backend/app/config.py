import os


class Config:
    MONGODB_URI = os.environ.get("MONGODB_URI", "mongodb://localhost:27017")
    MONGODB_DB_NAME = os.environ.get("MONGODB_DB_NAME", "fitmovelab")

    SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
    SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET", "")
    SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

    GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
    GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")

    STRAVA_CLIENT_ID = os.environ.get("STRAVA_CLIENT_ID", "")
    STRAVA_CLIENT_SECRET = os.environ.get("STRAVA_CLIENT_SECRET", "")
    STRAVA_REDIRECT_URI = os.environ.get("STRAVA_REDIRECT_URI", "")

    CORS_ORIGINS = [o.strip() for o in os.environ.get("CORS_ORIGINS", "*").split(",")]
    SECRET_KEY = os.environ.get("FLASK_SECRET_KEY", "dev")

    # In-memory (default) only tracks limits within a single process — fine for
    # local dev, but each gunicorn worker would get its own independent limit
    # in production. Set to a Redis URL (e.g. redis://host:6379) to share state.
    RATELIMIT_STORAGE_URI = os.environ.get("RATELIMIT_STORAGE_URI", "memory://")
