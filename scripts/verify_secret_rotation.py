#!/usr/bin/env python3
"""
N.Y Kitchen POS - Supabase Device Secret Rotation Verification Script

Purpose:
  Verifies that a rotated SUPABASE_DEVICE_SECRET protects the database:
  1. NO_SECRET (control): Request without x-device-secret is denied (HTTP 401/403 or 0 rows).
  2. OLD_SECRET: Request with old secret is denied (HTTP 401/403 or 0 rows).
  3. NEW_SECRET: Request with new secret is accepted (HTTP 200 with >=1 row).

Security Rules:
  - Uses Python standard library only (no 3rd-party dependencies).
  - Reads credentials strictly from environment variables. Never reads from .env or files.
  - Never prints, logs, or writes any secret, URL, key, or response body.
  - Supports --dry-run for offline validation without initiating network calls.
"""

import sys
import os
import argparse
import json
import urllib.request
import urllib.error
from datetime import datetime, timezone

TARGET_TABLE = "users"
REQUIRED_ENV_VARS = [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "OLD_DEVICE_SECRET",
    "NEW_DEVICE_SECRET",
]
EVIDENCE_FILE_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "docs", "security", "evidence", "secret_rotation_check.txt"
)


def validate_environment():
    missing = [var for var in REQUIRED_ENV_VARS if not os.environ.get(var)]
    if missing:
        sys.stderr.write(
            f"ERROR: Missing required environment variable(s): {', '.join(missing)}\n"
            f"Set them in your shell session before running this script.\n"
        )
        sys.exit(1)


def make_request(base_url, anon_key, device_secret=None):
    """
    Performs a read-only GET request to the target table (users?select=id&limit=1).
    Never prints or logs the response body.
    Returns: (status_code: int, row_count: int)
    """
    endpoint = f"{base_url.rstrip('/')}/rest/v1/{TARGET_TABLE}?select=id&limit=1"
    headers = {
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
        "Accept": "application/json",
    }
    if device_secret is not None:
        headers["x-device-secret"] = device_secret

    req = urllib.request.Request(endpoint, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            status_code = response.status
            body = response.read().decode("utf-8")
            try:
                data = json.loads(body)
                row_count = len(data) if isinstance(data, list) else 0
            except Exception:
                row_count = 0
            return status_code, row_count
    except urllib.error.HTTPError as e:
        return e.code, 0
    except Exception:
        sys.stderr.write("Network request failed.\n")
        return 0, 0


def main():
    parser = argparse.ArgumentParser(
        description="Verify Supabase SUPABASE_DEVICE_SECRET rotation against users table."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate that environment variables are set without making network calls."
    )
    args = parser.parse_args()

    # Step 1: Validate environment variables are present
    validate_environment()

    if args.dry_run:
        print("DRY-RUN VALIDATION: All required environment variables are set.")
        print(f"Target verification table: {TARGET_TABLE}?select=id&limit=1")
        print("Requests to be executed: NO_SECRET (control), OLD_SECRET, NEW_SECRET")
        print("No network requests were executed.")
        sys.exit(0)

    supabase_url = os.environ["SUPABASE_URL"]
    anon_key = os.environ["SUPABASE_ANON_KEY"]
    old_secret = os.environ["OLD_DEVICE_SECRET"]
    new_secret = os.environ["NEW_DEVICE_SECRET"]

    # Step 2: Request 1 (Control - No Secret header)
    no_status, no_rows = make_request(supabase_url, anon_key, device_secret=None)

    # Step 3: Request 2 (Old Secret)
    old_status, old_rows = make_request(supabase_url, anon_key, device_secret=old_secret)

    # Step 4: Request 3 (New Secret)
    new_status, new_rows = make_request(supabase_url, anon_key, device_secret=new_secret)

    # Output one line each for status code and row count (no URLs, keys, or body)
    print(f"NO_SECRET:  HTTP {no_status}, Rows: {no_rows}")
    print(f"OLD_SECRET: HTTP {old_status}, Rows: {old_rows}")
    print(f"NEW_SECRET: HTTP {new_status}, Rows: {new_rows}")

    # Note on Supabase RLS: When a query fails an RLS USING expression, PostgREST
    # typically returns HTTP 200 with an empty list `[]` (0 rows) rather than an HTTP 403 error,
    # unless an explicit rejection is triggered.
    if no_rows > 0:
        result_message = "INCONCLUSIVE: the secret does not protect this table"
        print(f"Result: {result_message}")
        overall_pass = False
    else:
        no_rejected = (no_status in (401, 403)) or (no_status == 200 and no_rows == 0)
        old_rejected = (old_status in (401, 403)) or (old_status == 200 and old_rows == 0)
        new_accepted = (new_status == 200 and new_rows > 0)

        if no_rejected and old_rejected and new_accepted:
            result_message = "PASS"
            overall_pass = True
        else:
            result_message = "FAIL"
            overall_pass = False
        print(f"Result: {result_message}")

    # Step 5: Save redacted evidence file
    try:
        os.makedirs(os.path.dirname(EVIDENCE_FILE_PATH), exist_ok=True)
        timestamp = datetime.now(timezone.utc).isoformat()
        evidence_content = (
            f"Date (UTC): {timestamp}\n"
            f"Table: {TARGET_TABLE}\n"
            f"NO_SECRET:  HTTP {no_status}, Rows: {no_rows}\n"
            f"OLD_SECRET: HTTP {old_status}, Rows: {old_rows}\n"
            f"NEW_SECRET: HTTP {new_status}, Rows: {new_rows}\n"
            f"Result: {result_message}\n"
        )
        with open(EVIDENCE_FILE_PATH, "w", encoding="utf-8") as f:
            f.write(evidence_content)
    except Exception as e:
        sys.stderr.write(f"Warning: Could not save evidence file: {e}\n")

    if not overall_pass:
        sys.exit(1)


if __name__ == "__main__":
    main()
