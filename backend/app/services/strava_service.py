import time

import requests
from flask import current_app

from ..extensions import get_db

_TOKEN_URL = "https://www.strava.com/oauth/token"
_ACTIVITIES_URL = "https://www.strava.com/api/v3/athlete/activities"


class StravaError(Exception):
    pass


def build_authorize_url(user_id: str) -> str:
    client_id = current_app.config["STRAVA_CLIENT_ID"]
    redirect_uri = current_app.config["STRAVA_REDIRECT_URI"]
    if not client_id or not redirect_uri:
        raise StravaError("Strava is not configured on the server yet")

    return (
        "https://www.strava.com/oauth/authorize"
        f"?client_id={client_id}"
        f"&redirect_uri={redirect_uri}"
        "&response_type=code"
        "&approval_prompt=auto"
        "&scope=read,activity:read_all"
        f"&state={user_id}"
    )


def exchange_code_for_token(code: str) -> dict:
    try:
        res = requests.post(
            _TOKEN_URL,
            data={
                "client_id": current_app.config["STRAVA_CLIENT_ID"],
                "client_secret": current_app.config["STRAVA_CLIENT_SECRET"],
                "code": code,
                "grant_type": "authorization_code",
            },
            timeout=15,
        )
    except requests.exceptions.RequestException as exc:
        raise StravaError(f"Could not reach Strava: {exc}") from exc
    if res.status_code >= 400:
        raise StravaError(f"Strava token exchange failed: {res.text}")
    return res.json()


def save_tokens(user_id: str, token_data: dict) -> None:
    get_db().strava_tokens.update_one(
        {"user_id": user_id},
        {
            "$set": {
                "access_token": token_data["access_token"],
                "refresh_token": token_data["refresh_token"],
                "expires_at": token_data["expires_at"],
                "strava_athlete_id": token_data.get("athlete", {}).get("id"),
            }
        },
        upsert=True,
    )


def _refresh_if_needed(record: dict) -> dict:
    if record["expires_at"] > time.time() + 60:
        return record

    try:
        res = requests.post(
            _TOKEN_URL,
            data={
                "client_id": current_app.config["STRAVA_CLIENT_ID"],
                "client_secret": current_app.config["STRAVA_CLIENT_SECRET"],
                "refresh_token": record["refresh_token"],
                "grant_type": "refresh_token",
            },
            timeout=15,
        )
    except requests.exceptions.RequestException as exc:
        raise StravaError(f"Could not reach Strava: {exc}") from exc
    if res.status_code >= 400:
        raise StravaError(f"Strava token refresh failed: {res.text}")
    token_data = res.json()

    get_db().strava_tokens.update_one(
        {"user_id": record["user_id"]},
        {
            "$set": {
                "access_token": token_data["access_token"],
                "refresh_token": token_data["refresh_token"],
                "expires_at": token_data["expires_at"],
            }
        },
    )
    record.update(token_data)
    return record


def get_connection(user_id: str) -> dict | None:
    return get_db().strava_tokens.find_one({"user_id": user_id})


def fetch_activities(user_id: str, per_page: int = 15) -> list[dict]:
    record = get_connection(user_id)
    if not record:
        return []
    record = _refresh_if_needed(record)

    try:
        res = requests.get(
            _ACTIVITIES_URL,
            headers={"Authorization": f"Bearer {record['access_token']}"},
            params={"per_page": per_page},
            timeout=15,
        )
    except requests.exceptions.RequestException as exc:
        raise StravaError(f"Could not reach Strava: {exc}") from exc
    if res.status_code >= 400:
        raise StravaError(f"Strava activities fetch failed: {res.text}")

    return [
        {
            "id": a["id"],
            "name": a["name"],
            "type": a.get("type", "Workout"),
            "distance_km": round((a.get("distance") or 0) / 1000, 2),
            "moving_time_min": round((a.get("moving_time") or 0) / 60),
            "date": a.get("start_date"),
        }
        for a in res.json()
    ]
