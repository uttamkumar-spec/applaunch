"""One-time bootstrap helper: promote an existing user to coach/admin
directly in Mongo. Useful for creating the very first Admin account (sign
up normally as an athlete in the app, then run this once).

Usage:
    python scripts/promote_user.py --email you@example.com --role admin
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from pymongo import MongoClient  # noqa: E402


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--email", required=True)
    parser.add_argument("--role", required=True, choices=["athlete", "coach", "admin"])
    args = parser.parse_args()

    uri = os.environ.get("MONGODB_URI", "mongodb://localhost:27017")
    db_name = os.environ.get("MONGODB_DB_NAME", "fitmovelab")
    db = MongoClient(uri)[db_name]

    result = db.users.update_one({"email": args.email}, {"$set": {"role": args.role}})
    if result.matched_count == 0:
        print(f"No user found with email {args.email}. Sign up in the app first, then re-run this.")
        sys.exit(1)

    print(f"{args.email} is now role={args.role}")


if __name__ == "__main__":
    main()
