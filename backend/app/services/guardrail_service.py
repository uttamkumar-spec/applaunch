"""Keyword-based guardrail rules deciding whether an athlete's AI chat message
gets an instant AI reply or must be routed to their coach.

Allowlist model: only a message matching an enabled `auto_respond` rule gets
an instant AI answer. Everything else — including a message matching no rule
at all — routes to the coach. A `route_to_coach` match always wins over an
`auto_respond` match on the same message, whichever scope (platform vs coach)
either rule came from, so a coach's own rule can never suppress a platform
safety rule.
"""

from ..extensions import get_db


def _load_rules(coach_id: str | None) -> list[dict]:
    db = get_db()
    rules = list(db.chat_guardrails.find({"enabled": True, "scope": "platform"}))
    if coach_id:
        rules += list(db.chat_guardrails.find({"enabled": True, "scope": "coach", "coach_id": coach_id}))
    return sorted(rules, key=lambda r: r.get("priority", 100))


def _matches(message: str, rule: dict) -> bool:
    lowered = message.lower()
    return any(kw.lower() in lowered for kw in rule.get("keywords", []) if kw)


def resolve(message: str, coach_id: str | None) -> tuple[str, dict | None]:
    """Returns ("route", rule) — rule is None when nothing matched — or
    ("auto_respond", rule)."""
    matched = [r for r in _load_rules(coach_id) if _matches(message, r)]

    route_match = next((r for r in matched if r["action"] == "route_to_coach"), None)
    if route_match:
        return "route", route_match

    auto_match = next((r for r in matched if r["action"] == "auto_respond"), None)
    if auto_match:
        return "auto_respond", auto_match

    return "route", None
