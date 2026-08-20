from flask import Blueprint, g, jsonify, request

from ..auth import require_auth
from ..services import strava_service
from ..services.interaction_logger import log_interaction

bp = Blueprint("strava", __name__, url_prefix="/api/strava")


@bp.get("/connect-url")
@require_auth
def connect_url():
    try:
        url = strava_service.build_authorize_url(g.user_id)
    except strava_service.StravaError as exc:
        return jsonify({"error": str(exc)}), 503
    return jsonify({"url": url})


@bp.get("/callback")
def callback():
    """Strava redirects the user's browser here after they approve access.
    Not behind require_auth — the caller is Strava, not our app — the
    user's identity comes from the `state` param we set in connect_url."""
    code = request.args.get("code")
    user_id = request.args.get("state")
    error = request.args.get("error")

    if error or not code or not user_id:
        return "Strava connection was cancelled or failed. You can close this window.", 400

    try:
        token_data = strava_service.exchange_code_for_token(code)
        strava_service.save_tokens(user_id, token_data)
    except strava_service.StravaError as exc:
        return f"Could not connect Strava: {exc}", 502

    log_interaction(user_id, "strava_activity_synced", {"event": "account_connected"}, source="strava")
    return (
        "<html><body style='font-family: sans-serif; text-align: center; padding-top: 80px;'>"
        "<h2>Strava connected 🎉</h2><p>You can close this window and return to the app.</p>"
        "</body></html>"
    )


@bp.get("/status")
@require_auth
def status():
    connected = strava_service.get_connection(g.user_id) is not None
    return jsonify({"connected": connected})


@bp.get("/activities")
@require_auth
def activities():
    try:
        data = strava_service.fetch_activities(g.user_id)
    except strava_service.StravaError as exc:
        return jsonify({"error": str(exc)}), 502

    if data:
        log_interaction(
            g.user_id,
            "strava_activity_synced",
            {"event": "activities_fetched", "count": len(data)},
            source="strava",
        )
    return jsonify(data)
