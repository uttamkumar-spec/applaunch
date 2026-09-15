"""Creates the Atlas Vector Search index backing retrieval_service.py's
semantic_search(). This is an Atlas-only feature — it does nothing useful
against a local/self-hosted Mongo, and it's not something the app can create
for itself at startup, so it's a one-time manual step against your real
Atlas cluster.

Run this once per environment (dev, staging, prod each need their own),
after MONGODB_URI in that environment's .env points at the real Atlas
cluster. Index creation is asynchronous on Atlas's side — it can take up to
a minute or two after this script returns before semantic_search() starts
returning results; until then it just returns empty, which is the same
"index not ready yet" fallback as if this script had never been run.

Usage:
    python scripts/create_vector_index.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from pymongo import MongoClient  # noqa: E402
from pymongo.operations import SearchIndexModel  # noqa: E402

from app.services.retrieval_service import VECTOR_INDEX_NAME  # noqa: E402

# text-embedding-004's output dimensionality. Update this (and re-embed
# everything via backfill_embeddings.py) if GEMINI_EMBEDDING_MODEL changes
# to a model with a different output size.
_EMBEDDING_DIMENSIONS = 768


def main():
    uri = os.environ.get("MONGODB_URI", "mongodb://localhost:27017")
    db_name = os.environ.get("MONGODB_DB_NAME", "fitmovelab")
    collection = MongoClient(uri)[db_name].interaction_embeddings

    existing = {idx["name"] for idx in collection.list_search_indexes()}
    if VECTOR_INDEX_NAME in existing:
        print(f"Index '{VECTOR_INDEX_NAME}' already exists — nothing to do.")
        return

    model = SearchIndexModel(
        name=VECTOR_INDEX_NAME,
        type="vectorSearch",
        definition={
            "fields": [
                {
                    "type": "vector",
                    "path": "embedding",
                    "numDimensions": _EMBEDDING_DIMENSIONS,
                    "similarity": "cosine",
                },
                {"type": "filter", "path": "user_id"},
            ]
        },
    )
    collection.create_search_index(model=model)
    print(
        f"Requested creation of '{VECTOR_INDEX_NAME}' on interaction_embeddings. "
        "Atlas builds this asynchronously — it may take a minute or two before it's queryable."
    )


if __name__ == "__main__":
    main()
