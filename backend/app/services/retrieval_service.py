"""Semantic search over one athlete's embedded interactions
(`interaction_embeddings`, populated best-effort by interaction_logger.py),
backed by Atlas Vector Search.

This degrades on purpose rather than ever raising: the Atlas Search index
(`interaction_embeddings_vector_index`, see scripts/create_vector_index.py)
is a manual, Atlas-only setup step outside the app's own control, and the
embedding backlog needs a one-time backfill (scripts/backfill_embeddings.py)
before older history is searchable. Until both have run, semantic_search()
simply returns no results — callers are expected to fall back to a simpler,
always-available retrieval (see lifestyle_summary.build_extended_context).
"""

from ..extensions import get_db
from . import gemini_service

VECTOR_INDEX_NAME = "interaction_embeddings_vector_index"


def semantic_search(user_id: str, query: str, limit: int = 10) -> list[dict]:
    query_vector = gemini_service.embed_text(query)
    if query_vector is None:
        return []

    try:
        pipeline = [
            {
                "$vectorSearch": {
                    "index": VECTOR_INDEX_NAME,
                    "path": "embedding",
                    "queryVector": query_vector,
                    "filter": {"user_id": user_id},
                    "numCandidates": max(limit * 10, 100),
                    "limit": limit,
                }
            },
            {
                "$project": {
                    "_id": 0,
                    "type": 1,
                    "text": 1,
                    "created_at": 1,
                    "score": {"$meta": "vectorSearchScore"},
                }
            },
        ]
        return list(get_db().interaction_embeddings.aggregate(pipeline))
    except Exception:
        # Most commonly: the Atlas Search index hasn't been created yet, or
        # this isn't an Atlas cluster at all (local/mongomock in tests).
        return []
