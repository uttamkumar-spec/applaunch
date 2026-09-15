from datetime import datetime, timezone

from bson import ObjectId
from flask import Blueprint, g, jsonify, request

from ..auth import require_role
from ..extensions import get_db

bp = Blueprint("guardrails", __name__, url_prefix="/api")

_VALID_ACTIONS = {"route_to_coach", "auto_respond"}


def _serialize(rule: dict) -> dict:
    return {
        "id": str(rule["_id"]),
        "scope": rule["scope"],
        "coach_id": rule.get("coach_id"),
        "label": rule.get("label"),
        "keywords": rule.get("keywords", []),
        "action": rule.get("action"),
        "response_instructions": rule.get("response_instructions"),
        "priority": rule.get("priority", 100),
        "enabled": rule.get("enabled", True),
    }


def _validate_body(body: dict) -> str | None:
    if not (body.get("label") or "").strip():
        return "label is required"
    if not [k for k in (body.get("keywords") or []) if (k or "").strip()]:
        return "keywords is required"
    if body.get("action") not in _VALID_ACTIONS:
        return "action must be route_to_coach or auto_respond"
    if body.get("action") == "auto_respond" and not (body.get("response_instructions") or "").strip():
        return "response_instructions is required for auto_respond rules"
    return None


def _create_rule(scope: str, coach_id: str | None, created_by: str):
    body = request.get_json(force=True) or {}
    error = _validate_body(body)
    if error:
        return jsonify({"error": error}), 400

    doc = {
        "scope": scope,
        "coach_id": coach_id,
        "label": body["label"].strip(),
        "keywords": [k.strip() for k in body["keywords"] if (k or "").strip()],
        "action": body["action"],
        "response_instructions": (body.get("response_instructions") or "").strip() or None,
        "priority": int(body.get("priority", 100)),
        "enabled": bool(body.get("enabled", True)),
        "created_by": created_by,
        "created_at": datetime.now(timezone.utc),
    }
    result = get_db().chat_guardrails.insert_one(doc)
    doc["_id"] = result.inserted_id
    return jsonify(_serialize(doc)), 201


def _update_rule(rule_id: str, owner_query: dict):
    db = get_db()
    rule = db.chat_guardrails.find_one({"_id": ObjectId(rule_id), **owner_query})
    if not rule:
        return jsonify({"error": "rule not found"}), 404

    body = request.get_json(force=True) or {}
    updates = {}
    if "label" in body:
        updates["label"] = (body["label"] or "").strip()
    if "keywords" in body:
        updates["keywords"] = [k.strip() for k in body["keywords"] if (k or "").strip()]
    if "action" in body:
        if body["action"] not in _VALID_ACTIONS:
            return jsonify({"error": "action must be route_to_coach or auto_respond"}), 400
        updates["action"] = body["action"]
    if "response_instructions" in body:
        updates["response_instructions"] = (body.get("response_instructions") or "").strip() or None
    if "priority" in body:
        updates["priority"] = int(body["priority"])
    if "enabled" in body:
        updates["enabled"] = bool(body["enabled"])
    updates["updated_at"] = datetime.now(timezone.utc)

    db.chat_guardrails.update_one({"_id": rule["_id"]}, {"$set": updates})
    return jsonify(_serialize(db.chat_guardrails.find_one({"_id": rule["_id"]})))


def _delete_rule(rule_id: str, owner_query: dict):
    result = get_db().chat_guardrails.delete_one({"_id": ObjectId(rule_id), **owner_query})
    if result.deleted_count == 0:
        return jsonify({"error": "rule not found"}), 404
    return jsonify({"status": "deleted"})


# --- Admin: platform-wide default rules, apply to every athlete ---


@bp.get("/admin/guardrails")
@require_role("admin")
def list_platform_guardrails():
    rules = list(get_db().chat_guardrails.find({"scope": "platform"}).sort("priority", 1))
    return jsonify([_serialize(r) for r in rules])


@bp.post("/admin/guardrails")
@require_role("admin")
def create_platform_guardrail():
    return _create_rule("platform", None, g.user_id)


@bp.put("/admin/guardrails/<rule_id>")
@require_role("admin")
def update_platform_guardrail(rule_id):
    return _update_rule(rule_id, {"scope": "platform"})


@bp.delete("/admin/guardrails/<rule_id>")
@require_role("admin")
def delete_platform_guardrail(rule_id):
    return _delete_rule(rule_id, {"scope": "platform"})


# --- Coach: their own rules, layered on top of platform defaults for their
# own athletes only ---


@bp.get("/coach/guardrails")
@require_role("coach")
def list_coach_guardrails():
    rules = list(get_db().chat_guardrails.find({"scope": "coach", "coach_id": g.user_id}).sort("priority", 1))
    return jsonify([_serialize(r) for r in rules])


@bp.post("/coach/guardrails")
@require_role("coach")
def create_coach_guardrail():
    return _create_rule("coach", g.user_id, g.user_id)


@bp.put("/coach/guardrails/<rule_id>")
@require_role("coach")
def update_coach_guardrail(rule_id):
    return _update_rule(rule_id, {"scope": "coach", "coach_id": g.user_id})


@bp.delete("/coach/guardrails/<rule_id>")
@require_role("coach")
def delete_coach_guardrail(rule_id):
    return _delete_rule(rule_id, {"scope": "coach", "coach_id": g.user_id})
