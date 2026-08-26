from functools import wraps

import jwt
from flask import current_app, g, jsonify, request
from jwt import PyJWKClient

from .extensions import get_db


class AuthError(Exception):
    def __init__(self, message: str, status_code: int = 401):
        self.message = message
        self.status_code = status_code


def _extract_token() -> str:
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        raise AuthError("Missing bearer token")
    return header[len("Bearer ") :]


_jwks_client: PyJWKClient | None = None


def _get_jwks_client() -> PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        supabase_url = current_app.config["SUPABASE_URL"]
        _jwks_client = PyJWKClient(f"{supabase_url}/auth/v1/.well-known/jwks.json")
    return _jwks_client


def verify_supabase_jwt(token: str) -> dict:
    """Supabase signs auth tokens with the shared legacy HS256 secret on
    older projects, or with an asymmetric key (ES256/RS256) verified via
    Supabase's published JWKS on newer ones — check which this token uses
    rather than assuming."""
    try:
        alg = jwt.get_unverified_header(token).get("alg")
    except jwt.PyJWTError as exc:
        raise AuthError(f"Invalid or expired token: {exc}") from exc

    try:
        if alg == "HS256":
            secret = current_app.config["SUPABASE_JWT_SECRET"]
            if not secret:
                raise AuthError("Server is not configured for authentication yet", 503)
            return jwt.decode(token, secret, algorithms=["HS256"], audience="authenticated")

        signing_key = _get_jwks_client().get_signing_key_from_jwt(token)
        return jwt.decode(token, signing_key.key, algorithms=["ES256", "RS256"], audience="authenticated")
    except jwt.PyJWTError as exc:
        raise AuthError(f"Invalid or expired token: {exc}") from exc


def require_auth(fn):
    """Verifies the Supabase-issued JWT and sets g.user_id / g.user_email.

    Does NOT create a profile — callers that need one should read/create it
    from the `users` collection keyed by g.user_id (the Supabase auth UUID,
    reused everywhere as the canonical user identifier).
    """

    @wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            token = _extract_token()
            payload = verify_supabase_jwt(token)
        except AuthError as exc:
            return jsonify({"error": exc.message}), exc.status_code

        g.user_id = payload["sub"]
        g.user_email = payload.get("email")
        g.user_metadata = payload.get("user_metadata", {}) or {}
        return fn(*args, **kwargs)

    return wrapper


def require_role(*roles):
    """Stacks on top of require_auth; checks the caller's Mongo profile role."""

    def decorator(fn):
        @wraps(fn)
        @require_auth
        def wrapper(*args, **kwargs):
            db = get_db()
            profile = db.users.find_one({"_id": g.user_id}, {"role": 1})
            role = (profile or {}).get("role", "athlete")
            g.role = role
            if role not in roles:
                return jsonify({"error": "Forbidden for this role"}), 403
            return fn(*args, **kwargs)

        return wrapper

    return decorator
