"""In-app coach <-> athlete messaging (no SMS/WhatsApp/third-party provider —
messages are stored in Mongo and served over these APIs only).

Each coach/athlete pair has exactly one thread, keyed by
"{coach_id}:{athlete_id}" in `message_threads`, which also tracks
last-message-preview and per-side read timestamps so a coach's thread list
can show unread state without scanning every message.
"""

from datetime import datetime, timezone

from bson import ObjectId
from flask import Blueprint, g, jsonify, request

from ..auth import require_role
from ..extensions import get_db
from ..services.interaction_logger import log_interaction

bp = Blueprint("messages", __name__, url_prefix="/api/messages")


def _thread_key(coach_id: str, athlete_id: str) -> str:
    return f"{coach_id}:{athlete_id}"


def _send(db, coach_id: str, athlete_id: str, sender_role: str, text: str) -> None:
    now = datetime.now(timezone.utc)
    db.messages.insert_one(
        {
            "coach_id": coach_id,
            "athlete_id": athlete_id,
            "sender_id": g.user_id,
            "sender_role": sender_role,
            "text": text,
            "created_at": now,
        }
    )
    read_field = "coach_read_at" if sender_role == "coach" else "athlete_read_at"
    db.message_threads.update_one(
        {"_id": _thread_key(coach_id, athlete_id)},
        {
            "$set": {
                "coach_id": coach_id,
                "athlete_id": athlete_id,
                "last_message": text,
                "last_message_at": now,
                "last_sender_role": sender_role,
                read_field: now,
            }
        },
        upsert=True,
    )


def _serialize(m: dict) -> dict:
    return {
        "sender_id": m["sender_id"],
        "sender_role": m["sender_role"],
        "text": m["text"],
        "created_at": m["created_at"].isoformat(),
    }


@bp.get("/thread")
@require_role("athlete")
def get_my_thread():
    db = get_db()
    athlete = db.users.find_one({"_id": g.user_id}, {"coach_id": 1})
    coach_id = (athlete or {}).get("coach_id")
    if not coach_id:
        return jsonify([])

    messages = list(db.messages.find({"coach_id": coach_id, "athlete_id": g.user_id}).sort("created_at", 1))
    db.message_threads.update_one(
        {"_id": _thread_key(coach_id, g.user_id)},
        {"$set": {"athlete_read_at": datetime.now(timezone.utc)}},
        upsert=True,
    )
    return jsonify([_serialize(m) for m in messages])


@bp.post("/thread")
@require_role("athlete")
def send_to_coach():
    body = request.get_json(force=True) or {}
    text = (body.get("text") or "").strip()
    if not text:
        return jsonify({"error": "text is required"}), 400

    db = get_db()
    athlete = db.users.find_one({"_id": g.user_id}, {"coach_id": 1})
    coach_id = (athlete or {}).get("coach_id")
    if not coach_id:
        return jsonify({"error": "You don't have a coach yet"}), 400

    _send(db, coach_id, g.user_id, "athlete", text)
    log_interaction(g.user_id, "message_sent", {"to_coach": coach_id, "text": text}, source="user")
    return jsonify({"status": "sent"}), 201


@bp.get("/threads")
@require_role("coach")
def list_threads():
    db = get_db()
    athletes = list(db.users.find({"coach_id": g.user_id}, {"name": 1}))
    threads_by_athlete = {t["athlete_id"]: t for t in db.message_threads.find({"coach_id": g.user_id})}

    out = []
    for a in athletes:
        t = threads_by_athlete.get(a["_id"])
        last_message_at = (t or {}).get("last_message_at")
        coach_read_at = (t or {}).get("coach_read_at")
        unread = bool(
            t
            and t.get("last_sender_role") == "athlete"
            and last_message_at
            and (coach_read_at is None or last_message_at > coach_read_at)
        )
        out.append(
            {
                "athlete_id": a["_id"],
                "athlete_name": a.get("name", "Athlete"),
                "last_message": (t or {}).get("last_message"),
                "last_message_at": last_message_at.isoformat() if last_message_at else None,
                "unread": unread,
            }
        )
    out.sort(key=lambda r: r["last_message_at"] or "", reverse=True)
    return jsonify(out)


@bp.get("/thread/<athlete_id>")
@require_role("coach")
def get_thread_with_athlete(athlete_id):
    db = get_db()
    if not db.users.find_one({"_id": athlete_id, "coach_id": g.user_id}):
        return jsonify({"error": "athlete not found or not assigned to you"}), 404

    messages = list(db.messages.find({"coach_id": g.user_id, "athlete_id": athlete_id}).sort("created_at", 1))
    db.message_threads.update_one(
        {"_id": _thread_key(g.user_id, athlete_id)},
        {"$set": {"coach_read_at": datetime.now(timezone.utc)}},
        upsert=True,
    )
    return jsonify([_serialize(m) for m in messages])


@bp.post("/thread/<athlete_id>")
@require_role("coach")
def send_to_athlete(athlete_id):
    body = request.get_json(force=True) or {}
    text = (body.get("text") or "").strip()
    if not text:
        return jsonify({"error": "text is required"}), 400

    db = get_db()
    if not db.users.find_one({"_id": athlete_id, "coach_id": g.user_id}):
        return jsonify({"error": "athlete not found or not assigned to you"}), 404

    _send(db, g.user_id, athlete_id, "coach", text)
    log_interaction(athlete_id, "message_sent", {"from_coach": g.user_id, "text": text}, source="coach")
    return jsonify({"status": "sent"}), 201


@bp.post("/broadcast")
@require_role("coach")
def broadcast_to_group():
    """Sends one message into every member's individual thread — same
    approach as the existing bulk plan push, just for messages."""
    body = request.get_json(force=True) or {}
    group_id = body.get("group_id")
    text = (body.get("text") or "").strip()
    if not group_id or not text:
        return jsonify({"error": "group_id and text are required"}), 400

    db = get_db()
    group = db.groups.find_one({"_id": ObjectId(group_id), "coach_id": g.user_id})
    if not group:
        return jsonify({"error": "group not found"}), 404

    valid_athlete_ids = [
        a["_id"]
        for a in db.users.find({"_id": {"$in": group.get("athlete_ids", [])}, "coach_id": g.user_id}, {"_id": 1})
    ]

    for athlete_id in valid_athlete_ids:
        _send(db, g.user_id, athlete_id, "coach", text)
        log_interaction(
            athlete_id,
            "message_sent",
            {"from_coach": g.user_id, "text": text, "group_id": group_id},
            source="coach",
        )

    return jsonify({"status": "sent", "athlete_count": len(valid_athlete_ids)})
