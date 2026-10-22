"""Offline operator command. Prints a generated token once; stores only its hash."""
import argparse
import hashlib
import json
import os
import re
import secrets
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file", type=Path)
    parser.add_argument("id")
    parser.add_argument("role", choices=["device", "admin"])
    parser.add_argument("--rotate", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-zA-Z0-9_-]{1,64}", args.id):
        parser.error("Use 1-64 letters, digits, underscore or hyphen for the ID")
    entries = json.loads(args.file.read_text()) if args.file.exists() else []
    if any(row["id"] == args.id for row in entries) and not args.rotate:
        parser.error("ID already exists; use --rotate to replace its credential")
    token = secrets.token_urlsafe(32)
    entries = [row for row in entries if row["id"] != args.id]
    entries.append({"id": args.id, "role": args.role,
                    "token_sha256": hashlib.sha256(token.encode()).hexdigest()})
    args.file.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.file.with_suffix(".tmp")
    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w") as stream:
        json.dump(entries, stream, indent=2)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, args.file)
    print("Save this token securely; it will not be shown again:")
    print(token)
    print("Restart the backend after provisioning or rotation.")


if __name__ == "__main__":
    main()
