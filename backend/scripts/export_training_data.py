"""Dumps the central `user_interactions` log to JSONL — one line per event —
for use as training data for an in-house SLM later on.

Usage:
    python scripts/export_training_data.py                 # all users, all events
    python scripts/export_training_data.py --user-id UUID   # one user only
    python scripts/export_training_data.py --out data.jsonl
"""

import argparse
import json
import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from pymongo import MongoClient  # noqa: E402


def _json_default(value):
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user-id", help="Only export interactions for this Supabase user UUID")
    parser.add_argument("--out", default="training_data.jsonl")
    args = parser.parse_args()

    uri = os.environ.get("MONGODB_URI", "mongodb://localhost:27017")
    db_name = os.environ.get("MONGODB_DB_NAME", "fitmovelab")
    db = MongoClient(uri)[db_name]

    query = {"user_id": args.user_id} if args.user_id else {}
    cursor = db.user_interactions.find(query).sort([("user_id", 1), ("created_at", 1)])

    count = 0
    with open(args.out, "w") as f:
        for doc in cursor:
            doc["_id"] = str(doc["_id"])
            f.write(json.dumps(doc, default=_json_default) + "\n")
            count += 1

    print(f"Wrote {count} interaction records to {args.out}")


if __name__ == "__main__":
    main()
