"""Device-authenticated sales replication; no remote mutation of POS accounts."""
import hashlib
import hmac
import json
import logging
import os
import re
import sqlite3
import threading
import time
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Literal

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field

MAX_BODY = 262144
LOG = logging.getLogger("nykitchen.security")


class Item(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    food_name: str = Field(min_length=1, max_length=200)
    quantity: int = Field(ge=1, le=10000)
    unit_price_cents: int = Field(ge=0, le=100000000)
    subtotal_cents: int = Field(ge=0, le=1000000000)


class Sale(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    local_id: int = Field(ge=1)
    receipt_number: str = Field(min_length=1, max_length=100)
    total_cents: int = Field(ge=0, le=1000000000)
    discount_cents: int = Field(ge=0, le=1000000000)
    payment_method: str = Field(min_length=1, max_length=40)
    status: Literal["Preparing", "Served", "Completed", "completed", "Cancelled", "Voided", "Refunded"]
    created_at: str = Field(min_length=1, max_length=40)
    items: list[Item] = Field(min_length=1, max_length=200)


class Batch(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    sales: list[Sale] = Field(min_length=1, max_length=50)


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def load_credentials(path):
    records = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(records, list) or not records:
        raise ValueError("Provision credentials before starting the backend")
    seen = set()
    for record in records:
        if (not isinstance(record, dict)
                or set(record) != {"id", "role", "token_sha256"}
                or not re.fullmatch(r"[a-zA-Z0-9_-]{1,64}", record["id"])
                or record["role"] not in ("device", "admin")
                or not re.fullmatch(r"[0-9a-f]{64}", record["token_sha256"])
                or record["id"] in seen):
            raise ValueError("Invalid credential configuration")
        seen.add(record["id"])
    if len({r["token_sha256"] for r in records}) != len(records):
        raise ValueError("Each principal requires a distinct token")
    return records


class Store:
    def __init__(self, path):
        self.path = str(path)
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with self.connection() as db:
            db.executescript("""
                CREATE TABLE IF NOT EXISTS revisions (
                    id INTEGER PRIMARY KEY, device_id TEXT NOT NULL,
                    local_id INTEGER NOT NULL, digest TEXT NOT NULL,
                    payload TEXT NOT NULL, received_at TEXT NOT NULL,
                    UNIQUE(device_id, local_id, digest));
                CREATE TABLE IF NOT EXISTS audit (
                    id INTEGER PRIMARY KEY, principal TEXT NOT NULL,
                    action TEXT NOT NULL, outcome TEXT NOT NULL,
                    created_at TEXT NOT NULL);
                CREATE INDEX IF NOT EXISTS revisions_device
                    ON revisions(device_id, local_id, id);
            """)

    @contextmanager
    def connection(self):
        db = sqlite3.connect(self.path, timeout=5)
        db.row_factory = sqlite3.Row
        try:
            with db:
                yield db
        finally:
            db.close()

    def audit(self, principal, action, outcome):
        with self.connection() as db:
            db.execute("INSERT INTO audit(principal,action,outcome,created_at) VALUES(?,?,?,?)",
                       (principal, action, outcome, utc_now()))


def create_app(database=None, credentials=None, requests_per_minute=120):
    # Missing config fails closed. Never create default credentials.
    credential_path = credentials or os.environ.get("NYK_CREDENTIALS_FILE")
    if not credential_path:
        raise ValueError("NYK_CREDENTIALS_FILE must be configured")
    principals = load_credentials(credential_path)
    store = Store(database or os.environ.get("NYK_DATABASE", "backend/data/sync.db"))
    app = FastAPI(title="N.Y Kitchen Sync API", docs_url=None, redoc_url=None, openapi_url=None)
    app.state.store = store
    windows = {}
    lock = threading.Lock()

    @app.middleware("http")
    async def limits(request: Request, call_next):
        peer = request.client.host if request.client else "unknown"
        now = time.monotonic()
        with lock:
            expired = [key for key, value in windows.items() if now - value[0] >= 60]
            for key in expired:
                del windows[key]
            if peer not in windows and len(windows) >= 1024:
                return JSONResponse({"detail": "Request limit reached"}, status_code=429)
            start, count = windows.get(peer, (now, 0))
            windows[peer] = (start, count + 1)
        if count >= requests_per_minute:
            LOG.warning("request_rate_limited")
            return JSONResponse({"detail": "Request limit reached"}, status_code=429,
                                headers={"Retry-After": "60"})
        # Bound chunked bodies too; do not trust Content-Length alone.
        body = bytearray()
        async for chunk in request.stream():
            body.extend(chunk)
            if len(body) > MAX_BODY:
                LOG.warning("request_body_rejected")
                return JSONResponse({"detail": "Request too large"}, status_code=413)
        request._body = bytes(body)
        try:
            response = await call_next(request)
        except Exception:
            LOG.error("request_failed")  # No request headers, payloads or secrets.
            response = JSONResponse({"detail": "Service unavailable"}, status_code=503)
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    @app.exception_handler(RequestValidationError)
    async def validation_error(request, exc):
        LOG.warning("request_validation_failed")
        return JSONResponse({"detail": "Invalid request"}, status_code=422)

    def authenticate(request: Request):
        header = request.headers.get("authorization", "")
        token = header[7:] if header.startswith("Bearer ") else ""
        digest = hashlib.sha256(token.encode()).hexdigest()
        matched = None
        for principal in principals:
            if hmac.compare_digest(principal["token_sha256"], digest):
                matched = principal
        if not token or len(token) > 512 or matched is None:
            store.audit("unknown", "authenticate", "denied")
            raise HTTPException(401, "Authentication required", headers={"WWW-Authenticate": "Bearer"})
        return matched

    def require(role):
        def check(principal=Depends(authenticate)):
            if principal["role"] != role:
                store.audit(principal["id"], "role_check", "denied")
                raise HTTPException(403, "Forbidden")
            return principal
        return check

    @app.get("/health")
    def health():
        return {"status": "ok", "service": "ny-kitchen-sync"}

    @app.get("/openapi.json")
    def schema(principal=Depends(require("admin"))):
        return app.openapi()

    @app.post("/v1/sales/sync")
    def sync(batch: Batch, principal=Depends(require("device"))):
        # Namespace comes from the server credential, never from the request body.
        inserted = 0
        with store.connection() as db:
            for sale in batch.sales:
                if any(i.subtotal_cents != i.unit_price_cents * i.quantity for i in sale.items):
                    raise HTTPException(422, "Invalid sale totals")
                if sum(i.subtotal_cents for i in sale.items) - sale.discount_cents != sale.total_cents:
                    raise HTTPException(422, "Invalid sale totals")
                try:
                    datetime.fromisoformat(sale.created_at)
                except ValueError:
                    raise HTTPException(422, "Invalid sale timestamp")
                payload = json.dumps(sale.model_dump(), sort_keys=True, separators=(",", ":"))
                digest = hashlib.sha256(payload.encode()).hexdigest()
                inserted += db.execute(
                    "INSERT OR IGNORE INTO revisions(device_id,local_id,digest,payload,received_at) VALUES(?,?,?,?,?)",
                    (principal["id"], sale.local_id, digest, payload, utc_now())).rowcount
            db.execute("INSERT INTO audit(principal,action,outcome,created_at) VALUES(?,?,?,?)",
                       (principal["id"], "sales_sync", "accepted", utc_now()))
        return {"accepted": len(batch.sales), "new_revisions": inserted}

    @app.get("/v1/admin/sales")
    def sales(after: int = 0, limit: int = 50, principal=Depends(require("admin"))):
        if after < 0 or not 1 <= limit <= 100:
            raise HTTPException(422, "Invalid page")
        with store.connection() as db:
            rows = db.execute(
                "SELECT * FROM revisions WHERE id IN (SELECT MAX(id) FROM revisions GROUP BY device_id,local_id) "
                "AND id > ? ORDER BY id LIMIT ?", (after, limit)).fetchall()
            db.execute("INSERT INTO audit(principal,action,outcome,created_at) VALUES(?,?,?,?)",
                       (principal["id"], "sales_read", "allowed", utc_now()))
        return {"sales": [{"revision": row["id"], "device_id": row["device_id"],
                           "received_at": row["received_at"], "sale": json.loads(row["payload"])} for row in rows]}

    @app.get("/v1/admin/audit")
    def audit(after: int = 0, limit: int = 50, principal=Depends(require("admin"))):
        if after < 0 or not 1 <= limit <= 100:
            raise HTTPException(422, "Invalid page")
        store.audit(principal["id"], "audit_read", "allowed")
        with store.connection() as db:
            rows = db.execute("SELECT * FROM audit WHERE id > ? ORDER BY id LIMIT ?", (after, limit)).fetchall()
        return {"events": [dict(row) for row in rows]}

    return app
