"""Utility script to verify and sync local development SQLite passwords.

Usage:
  python scripts/sync_user_passwords.py
"""

import base64
import hashlib
import os
import sqlite3

CANDIDATE_PATHS = [
    os.path.expanduser(r"~\OneDrive\Documents\ny_kitchen.db"),
    os.path.expanduser(r"~\Documents\ny_kitchen.db"),
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ny_kitchen.db"),
]

def hash_password(password: str, salt_b64: str, iterations: int = 10000) -> str:
    salt = base64.b64decode(salt_b64)
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iterations, dklen=32)
    return base64.b64encode(key).decode("utf-8")

def find_db():
    for p in CANDIDATE_PATHS:
        if os.path.exists(p):
            return p
    return None

def main():
    db_path = find_db()
    if not db_path:
        print("No local ny_kitchen.db found in common user document directories.")
        return

    print(f"Opening database: {db_path}")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute("SELECT id, username, password_hash, role, status FROM users")
    rows = cur.fetchall()

    fixed = 0
    for user_id, username, stored_hash, role, status in rows:
        target_password = "admin123" if username == "admin" else "cashier123" if username == "cashier" else None
        if not target_password:
            continue

        salt = base64.b64encode(b"static_dev_salt_1234").decode("utf-8")
        hash_val = hash_password(target_password, salt, 10000)
        formatted_hash = f"{salt}:{hash_val}"

        cur.execute(
            "UPDATE users SET password_hash = ?, failed_login_count = 0, status = 'active' WHERE id = ?",
            (formatted_hash, user_id)
        )
        print(f"Synchronized user '{username}' ({role}) to verified password format.")
        fixed += 1

    conn.commit()
    conn.close()
    print(f"Finished. Synchronized {fixed} accounts.")

if __name__ == "__main__":
    main()
