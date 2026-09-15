"""One-time backfill: embeds existing user_interactions history into
interaction_embeddings so it's searchable via semantic search before the
vector index existed. New interactions get embedded automatically at write
time (see interaction_logger.py) — this script only needs to run once per
environment, and again if a new embeddable type is added and you want
historical coverage for it too.

Usage:
    python scripts/backfill_embeddings.py                 # all users
    python scripts/backfill_embeddings.py --user-id UUID   # one user only
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from app import create_app  # noqa: E402
from app.extensions import get_db  # noqa: E402
from app.services import gemini_service  # noqa: E402
from app.services.interaction_logger import EMBEDDABLE_TYPES, embedding_text  # noqa: E402


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-id", help="Only backfill this Supabase user UUID")
    args = parser.parse_args()

    app = create_app()
    with app.app_context():
        db = get_db()
        query = {"type": {"$in": sorted(EMBEDDABLE_TYPES)}}
        if args.user_id:
            query["user_id"] = args.user_id

        already_embedded = {doc["interaction_id"] for doc in db.interaction_embeddings.find({}, {"interaction_id": 1})}

        embedded, skipped = 0, 0
        for interaction in db.user_interactions.find(query):
            if interaction["_id"] in already_embedded:
                continue

            text = embedding_text(interaction["type"], interaction.get("payload") or {})
            if not text:
                skipped += 1
                continue

            vector = gemini_service.embed_text(text)
            if vector is None:
                skipped += 1
                continue

            db.interaction_embeddings.insert_one(
                {
                    "user_id": interaction["user_id"],
                    "interaction_id": interaction["_id"],
                    "type": interaction["type"],
                    "text": text,
                    "embedding": vector,
                    "created_at": interaction["created_at"],
                }
            )
            embedded += 1

        print(f"Embedded {embedded} interactions ({skipped} skipped — no text, or the embedding call failed).")


if __name__ == "__main__":
    main()
