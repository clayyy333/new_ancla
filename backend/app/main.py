from __future__ import annotations

import hashlib
import hmac
import json
import os
import re
import secrets
import time
import uuid
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Annotated, Literal

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field, field_validator

from .database import connection, init_database


def env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


def env_float(name: str, default: float) -> float:
    try:
        return float(os.getenv(name, str(default)))
    except ValueError:
        return default


SESSION_TIMEOUT = env_int("SESSION_TIMEOUT_SECONDS", 90)
MAX_HEARTBEAT_CREDIT = env_int("HEARTBEAT_MAX_CREDIT_SECONDS", 90)
REPORT_DISTANCE = env_float("ANCHOR_REPORT_DISTANCE", 4.0)
EXTREME_DISTANCE = env_float("ANCHOR_EXTREME_DISTANCE", 80.0)
OBSERVER_QUORUM = max(1, env_int("ANCHOR_OBSERVER_QUORUM", 1))
REPORT_WINDOW = env_float("ANCHOR_REPORT_WINDOW_SECONDS", 3.0)
COMMAND_COOLDOWN = env_float("ANCHOR_COMMAND_COOLDOWN_SECONDS", 3.0)
TRUST_PROXY_COUNTRY = os.getenv("TRUST_PROXY_COUNTRY_HEADER", "false").lower() == "true"
COUNTRY_PATTERN = re.compile(r"^[A-Z]{2}$")


def env_place_ids(name: str) -> set[int]:
    values: set[int] = set()
    for raw in os.getenv(name, "").split(","):
        candidate = raw.strip()
        if candidate.isdigit():
            values.add(int(candidate))
    return values


NETWORK_INFO_ALLOWED_PLACE_IDS = env_place_ids("NETWORK_INFO_ALLOWED_PLACE_IDS")
OWNER_USER_ID = env_int("OWNER_USER_ID", 10909992869)
OWNER_USERNAME = os.getenv("OWNER_USERNAME", "Thranduil553").strip().lower()
OWNER_GAME_PLACE_ID = env_int("OWNER_GAME_PLACE_ID", 12985361032)
OWNER_PANEL_SESSION_SECONDS = max(300, env_int("OWNER_PANEL_SESSION_SECONDS", 1800))


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def now() -> float:
    return time.time()


def active_cutoff() -> float:
    return now() - SESSION_TIMEOUT


def normalize_country(value: str | None) -> str:
    candidate = (value or "").strip().upper()
    return candidate if COUNTRY_PATTERN.fullmatch(candidate) else "UN"


def country_from_request(request: Request, reported: str | None) -> str:
    if TRUST_PROXY_COUNTRY:
        for header in ("cf-ipcountry", "x-country-code"):
            value = request.headers.get(header)
            if value:
                return normalize_country(value)
    return normalize_country(reported)


def row_dict(row):
    return dict(row) if row else None


class NetworkInfo(BaseModel):
    ip: str = Field(default="", max_length=64)
    country: str = Field(default="", max_length=100)
    country_code: str | None = Field(default=None, max_length=2)
    region: str = Field(default="", max_length=120)
    city: str = Field(default="", max_length=120)
    isp: str = Field(default="", max_length=180)
    organization: str = Field(default="", max_length=180)
    asn: str = Field(default="", max_length=40)
    timezone: str = Field(default="", max_length=80)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class SessionStart(BaseModel):
    user_id: int = Field(gt=0)
    username: str = Field(min_length=1, max_length=40)
    display_name: str = Field(min_length=1, max_length=80)
    place_id: int = Field(ge=0)
    job_id: str = Field(min_length=1, max_length=128)
    game_name: str = Field(default="", max_length=160)
    executor: str = Field(default="", max_length=60)
    script_version: str = Field(default="", max_length=40)
    country_code: str | None = Field(default=None, max_length=2)
    analytics_consent: bool = False
    network_info: NetworkInfo | None = None

    @field_validator("network_info")
    @classmethod
    def network_info_requires_consent(cls, value, info):
        if value is not None and not info.data.get("analytics_consent", False):
            raise ValueError("network_info requires analytics_consent=true")
        return value


class Heartbeat(BaseModel):
    anchored: bool = False
    anchor_mode: str = Field(default="", max_length=40)


class AnchorObservation(BaseModel):
    target_user_id: int = Field(gt=0)
    distance: float = Field(ge=0, le=1_000_000)


class CommandAck(BaseModel):
    result: Literal["returned", "already_stable", "anchor_disabled", "failed"]


class OwnerLogin(BaseModel):
    user_id: int = Field(gt=0)
    username: str = Field(min_length=1, max_length=40)
    key: str = Field(min_length=1, max_length=256)


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_database()
    yield


app = FastAPI(
    title="Fling Lua Telemetry Backend",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if os.getenv("ENABLE_DOCS", "true").lower() == "true" else None,
)
STATIC_DIR = Path(__file__).resolve().parents[1] / "static"


def require_client_key(x_client_key: Annotated[str | None, Header()] = None) -> None:
    expected = os.getenv("CLIENT_INGEST_KEY", "")
    if expected and not x_client_key:
        raise HTTPException(401, "Missing client key")
    if expected and not hmac.compare_digest(x_client_key or "", expected):
        raise HTTPException(403, "Invalid client key")


def require_admin(authorization: Annotated[str | None, Header()] = None) -> None:
    expected = os.getenv("ADMIN_TOKEN", "")
    if not expected:
        raise HTTPException(503, "ADMIN_TOKEN is not configured")
    supplied = authorization.removeprefix("Bearer ").strip() if authorization else ""
    if not supplied or not hmac.compare_digest(supplied, expected):
        raise HTTPException(401, "Invalid administrator token")


def require_owner_panel(
    authorization: Annotated[str | None, Header()] = None,
):
    supplied = authorization.removeprefix("Bearer ").strip() if authorization else ""
    if not supplied:
        raise HTTPException(401, "Missing owner panel token")
    timestamp = now()
    with connection() as db:
        session = db.execute(
            """SELECT * FROM owner_panel_sessions
               WHERE token_hash=? AND expires_at>?""",
            (token_hash(supplied), timestamp),
        ).fetchone()
        if not session or session["user_id"] != OWNER_USER_ID:
            raise HTTPException(401, "Invalid or expired owner panel token")
        db.execute(
            "UPDATE owner_panel_sessions SET last_used_at=? WHERE token_hash=?",
            (timestamp, token_hash(supplied)),
        )
    return row_dict(session)


def require_session(
    authorization: Annotated[str | None, Header()] = None,
    _: None = Depends(require_client_key),
):
    supplied = authorization.removeprefix("Bearer ").strip() if authorization else ""
    if not supplied:
        raise HTTPException(401, "Missing session token")
    with connection() as db:
        session = db.execute(
            "SELECT * FROM sessions WHERE token_hash=? AND ended_at IS NULL",
            (token_hash(supplied),),
        ).fetchone()
    if not session:
        raise HTTPException(401, "Invalid or ended session")
    return row_dict(session)


def audit(db, event_type: str, session_id=None, user_id=None, details=None) -> None:
    db.execute(
        "INSERT INTO audit_log(event_type,session_id,user_id,details,created_at) VALUES(?,?,?,?,?)",
        (event_type, session_id, user_id, json.dumps(details or {}, separators=(",", ":")), now()),
    )


@app.get("/health")
def health():
    return {"status": "ok", "time": now()}


@app.get("/", include_in_schema=False)
def dashboard():
    return FileResponse(STATIC_DIR / "index.html")


@app.post("/api/v1/sessions/start", dependencies=[Depends(require_client_key)])
def start_session(payload: SessionStart, request: Request):
    timestamp = now()
    session_id = str(uuid.uuid4())
    session_token = secrets.token_urlsafe(32)
    reported_country = payload.country_code
    if not reported_country and payload.network_info:
        reported_country = payload.network_info.country_code
    country = country_from_request(request, reported_country)
    with connection() as db:
        existing = db.execute("SELECT user_id FROM users WHERE user_id=?", (payload.user_id,)).fetchone()
        if existing:
            db.execute(
                """UPDATE users SET username=?,display_name=?,country_code=
                   CASE WHEN ?='UN' THEN country_code ELSE ? END,last_seen=? WHERE user_id=?""",
                (payload.username, payload.display_name, country, country, timestamp, payload.user_id),
            )
        else:
            db.execute(
                """INSERT INTO users(user_id,username,display_name,country_code,first_seen,last_seen)
                   VALUES(?,?,?,?,?,?)""",
                (payload.user_id, payload.username, payload.display_name, country, timestamp, timestamp),
            )
        db.execute(
            """INSERT INTO sessions(
                id,token_hash,user_id,place_id,job_id,game_name,executor,script_version,
                started_at,last_seen
            ) VALUES(?,?,?,?,?,?,?,?,?,?)""",
            (
                session_id,
                token_hash(session_token),
                payload.user_id,
                payload.place_id,
                payload.job_id,
                payload.game_name,
                payload.executor,
                payload.script_version,
                timestamp,
                timestamp,
            ),
        )
        if (
            payload.analytics_consent
            and payload.network_info
            and payload.place_id in NETWORK_INFO_ALLOWED_PLACE_IDS
        ):
            network = payload.network_info
            db.execute(
                """INSERT INTO network_profiles(
                    session_id,user_id,ip_address,country,country_code,region,city,
                    isp,organization,asn,timezone,latitude,longitude,consented_at,created_at
                ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    session_id,
                    payload.user_id,
                    network.ip.strip(),
                    network.country.strip(),
                    normalize_country(network.country_code or country),
                    network.region.strip(),
                    network.city.strip(),
                    network.isp.strip(),
                    network.organization.strip(),
                    network.asn.strip(),
                    network.timezone.strip(),
                    network.latitude,
                    network.longitude,
                    timestamp,
                    timestamp,
                ),
            )
        audit(db, "session_started", session_id, payload.user_id, {"place_id": payload.place_id})
    return {
        "session_id": session_id,
        "session_token": session_token,
        "heartbeat_interval_seconds": 30,
        "command_poll_interval_seconds": 1,
    }


@app.post("/api/v1/sessions/heartbeat")
def heartbeat(payload: Heartbeat, session=Depends(require_session)):
    timestamp = now()
    with connection() as db:
        current = db.execute(
            "SELECT last_seen FROM sessions WHERE id=? AND ended_at IS NULL", (session["id"],)
        ).fetchone()
        if not current:
            raise HTTPException(404, "Session ended")
        elapsed = max(0.0, min(float(MAX_HEARTBEAT_CREDIT), timestamp - current["last_seen"]))
        db.execute(
            """UPDATE sessions SET last_seen=?,credited_seconds=credited_seconds+?,
               anchored=?,anchor_mode=? WHERE id=?""",
            (timestamp, elapsed, int(payload.anchored), payload.anchor_mode if payload.anchored else "", session["id"]),
        )
        db.execute(
            "UPDATE users SET last_seen=?,total_seconds=total_seconds+? WHERE user_id=?",
            (timestamp, elapsed, session["user_id"]),
        )
    return {"ok": True, "credited_seconds": elapsed, "server_time": timestamp}


@app.post("/api/v1/sessions/end")
def end_session(session=Depends(require_session)):
    timestamp = now()
    with connection() as db:
        db.execute("UPDATE sessions SET ended_at=?,last_seen=?,anchored=0 WHERE id=?", (timestamp, timestamp, session["id"]))
        audit(db, "session_ended", session["id"], session["user_id"])
    return {"ok": True}


@app.post("/api/v1/anchor/observe")
def observe_anchor(payload: AnchorObservation, observer=Depends(require_session)):
    timestamp = now()
    if payload.distance < REPORT_DISTANCE:
        return {"accepted": False, "reason": "below_threshold"}

    with connection() as db:
        target = db.execute(
            """SELECT * FROM sessions
               WHERE user_id=? AND place_id=? AND job_id=? AND anchored=1
                 AND ended_at IS NULL AND last_seen>=?
               ORDER BY last_seen DESC LIMIT 1""",
            (
                payload.target_user_id,
                observer["place_id"],
                observer["job_id"],
                active_cutoff(),
            ),
        ).fetchone()
        if not target:
            return {"accepted": False, "reason": "target_not_active_and_anchored"}
        if target["id"] == observer["id"]:
            return {"accepted": False, "reason": "self_report"}

        db.execute(
            """INSERT INTO anchor_observations(observer_session_id,target_session_id,distance,observed_at)
               VALUES(?,?,?,?)""",
            (observer["id"], target["id"], payload.distance, timestamp),
        )

        reports = db.execute(
            """SELECT COUNT(DISTINCT observer_session_id) AS observers,MAX(distance) AS max_distance
               FROM anchor_observations WHERE target_session_id=? AND observed_at>=?""",
            (target["id"], timestamp - REPORT_WINDOW),
        ).fetchone()
        required = 1 if payload.distance >= EXTREME_DISTANCE else OBSERVER_QUORUM
        if reports["observers"] < required:
            return {
                "accepted": True,
                "command_created": False,
                "observers": reports["observers"],
                "required": required,
            }

        recent = db.execute(
            "SELECT id FROM recovery_commands WHERE target_session_id=? AND created_at>=? LIMIT 1",
            (target["id"], timestamp - COMMAND_COOLDOWN),
        ).fetchone()
        if recent:
            return {"accepted": True, "command_created": False, "reason": "cooldown"}

        command_id = str(uuid.uuid4())
        db.execute(
            """INSERT INTO recovery_commands(
                id,target_session_id,created_at,observer_count,max_distance
            ) VALUES(?,?,?,?,?)""",
            (command_id, target["id"], timestamp, reports["observers"], reports["max_distance"]),
        )
        audit(
            db,
            "anchor_recovery_created",
            target["id"],
            target["user_id"],
            {"observers": reports["observers"], "max_distance": reports["max_distance"]},
        )
    return {"accepted": True, "command_created": True, "command_id": command_id}


@app.get("/api/v1/anchor/commands")
def poll_commands(session=Depends(require_session)):
    if not session["anchored"]:
        return {"commands": []}
    timestamp = now()
    with connection() as db:
        rows = db.execute(
            """SELECT id,created_at,observer_count,max_distance FROM recovery_commands
               WHERE target_session_id=? AND acknowledged_at IS NULL
               ORDER BY created_at ASC LIMIT 5""",
            (session["id"],),
        ).fetchall()
        ids = [row["id"] for row in rows]
        if ids:
            placeholders = ",".join("?" for _ in ids)
            db.execute(
                f"UPDATE recovery_commands SET delivered_at=COALESCE(delivered_at,?) WHERE id IN ({placeholders})",
                (timestamp, *ids),
            )
    return {
        "commands": [
            {
                "id": row["id"],
                "type": "force_local_checkpoint_return",
                "created_at": row["created_at"],
                "observer_count": row["observer_count"],
                "max_distance": row["max_distance"],
            }
            for row in rows
        ]
    }


@app.post("/api/v1/anchor/commands/{command_id}/ack")
def acknowledge_command(command_id: str, payload: CommandAck, session=Depends(require_session)):
    with connection() as db:
        command = db.execute(
            "SELECT id FROM recovery_commands WHERE id=? AND target_session_id=?",
            (command_id, session["id"]),
        ).fetchone()
        if not command:
            raise HTTPException(404, "Command not found")
        db.execute(
            "UPDATE recovery_commands SET acknowledged_at=?,result=? WHERE id=?",
            (now(), payload.result, command_id),
        )
        audit(db, "anchor_recovery_ack", session["id"], session["user_id"], {"result": payload.result})
    return {"ok": True}


@app.post("/api/v1/owner/login")
def owner_login(payload: OwnerLogin):
    expected_key = os.getenv("OWNER_PANEL_KEY", "")
    if not expected_key:
        raise HTTPException(503, "OWNER_PANEL_KEY is not configured")
    valid_identity = (
        payload.user_id == OWNER_USER_ID
        and payload.username.strip().lower() == OWNER_USERNAME
    )
    if not valid_identity or not hmac.compare_digest(payload.key, expected_key):
        raise HTTPException(401, "Invalid owner credentials")

    timestamp = now()
    expires_at = timestamp + OWNER_PANEL_SESSION_SECONDS
    owner_token = secrets.token_urlsafe(32)
    with connection() as db:
        db.execute("DELETE FROM owner_panel_sessions WHERE expires_at<=?", (timestamp,))
        db.execute(
            """INSERT INTO owner_panel_sessions(
                token_hash,user_id,created_at,expires_at,last_used_at
            ) VALUES(?,?,?,?,?)""",
            (token_hash(owner_token), payload.user_id, timestamp, expires_at, timestamp),
        )
        audit(db, "owner_panel_login", user_id=payload.user_id)
    return {
        "token": owner_token,
        "expires_at": expires_at,
        "place_id": OWNER_GAME_PLACE_ID,
    }


@app.post("/api/v1/owner/logout")
def owner_logout(
    authorization: Annotated[str | None, Header()] = None,
    _: dict = Depends(require_owner_panel),
):
    supplied = authorization.removeprefix("Bearer ").strip() if authorization else ""
    with connection() as db:
        db.execute("DELETE FROM owner_panel_sessions WHERE token_hash=?", (token_hash(supplied),))
    return {"ok": True}


@app.get("/api/v1/owner/players")
def owner_players(
    scope: Literal["server", "game"],
    job_id: str | None = Query(default=None, max_length=128),
    limit: int = Query(default=200, ge=1, le=500),
    _: dict = Depends(require_owner_panel),
):
    if scope == "server" and not job_id:
        raise HTTPException(400, "Server scope requires job_id")

    clauses = [
        "s.place_id=?",
        "s.ended_at IS NULL",
        "s.last_seen>=?",
    ]
    values: list[object] = [OWNER_GAME_PLACE_ID, active_cutoff()]
    if scope == "server":
        clauses.append("s.job_id=?")
        values.append(job_id)
    elif job_id:
        clauses.append("s.job_id<>?")
        values.append(job_id)

    where = " AND ".join(clauses)
    with connection() as db:
        rows = db.execute(
            f"""SELECT u.user_id,u.username,u.display_name,u.country_code,
                MAX(s.last_seen) AS last_seen,
                COUNT(DISTINCT s.job_id) AS active_servers,
                COALESCE((
                    SELECT SUM(s2.credited_seconds)
                    FROM sessions s2
                    WHERE s2.user_id=u.user_id AND s2.place_id=?
                ),0) AS total_seconds
                FROM sessions s
                JOIN users u ON u.user_id=s.user_id
                WHERE {where}
                GROUP BY u.user_id,u.username,u.display_name,u.country_code
                ORDER BY last_seen DESC
                LIMIT ?""",
            (OWNER_GAME_PLACE_ID, *values, limit),
        ).fetchall()
    return {
        "scope": scope,
        "place_id": OWNER_GAME_PLACE_ID,
        "players": [row_dict(row) for row in rows],
    }


@app.get("/api/v1/admin/summary", dependencies=[Depends(require_admin)])
def admin_summary():
    cutoff = active_cutoff()
    with connection() as db:
        users = db.execute("SELECT COUNT(*) AS value FROM users").fetchone()["value"]
        active = db.execute(
            "SELECT COUNT(*) AS value FROM sessions WHERE ended_at IS NULL AND last_seen>=?", (cutoff,)
        ).fetchone()["value"]
        seconds = db.execute("SELECT COALESCE(SUM(total_seconds),0) AS value FROM users").fetchone()["value"]
        games = db.execute(
            "SELECT COUNT(DISTINCT place_id) AS value FROM sessions WHERE ended_at IS NULL AND last_seen>=?",
            (cutoff,),
        ).fetchone()["value"]
        servers = db.execute(
            """SELECT COUNT(*) AS value FROM (
               SELECT place_id,job_id FROM sessions
               WHERE ended_at IS NULL AND last_seen>=? GROUP BY place_id,job_id)""",
            (cutoff,),
        ).fetchone()["value"]
        anchored = db.execute(
            """SELECT COUNT(*) AS value FROM sessions
               WHERE ended_at IS NULL AND last_seen>=? AND anchored=1""",
            (cutoff,),
        ).fetchone()["value"]
    return {
        "total_users": users,
        "active_sessions": active,
        "total_hours": round(seconds / 3600, 2),
        "active_games": games,
        "active_servers": servers,
        "anchored_sessions": anchored,
    }


@app.get("/api/v1/admin/sessions", dependencies=[Depends(require_admin)])
def admin_sessions(
    scope: Literal["general", "focused"] = "general",
    place_id: int | None = None,
    job_id: str | None = Query(default=None, max_length=128),
    active_only: bool = True,
    limit: int = Query(default=200, ge=1, le=1000),
):
    clauses, values = [], []
    if active_only:
        clauses.append("s.ended_at IS NULL AND s.last_seen>=?")
        values.append(active_cutoff())
    if scope == "focused":
        if place_id is None or not job_id:
            raise HTTPException(400, "Focused scope requires place_id and job_id")
        clauses.extend(["s.place_id=?", "s.job_id=?"])
        values.extend([place_id, job_id])
    where = "WHERE " + " AND ".join(clauses) if clauses else ""
    values.append(limit)
    with connection() as db:
        rows = db.execute(
            f"""SELECT s.id,s.user_id,u.username,u.display_name,u.country_code,
                s.place_id,s.job_id,s.game_name,s.executor,s.script_version,
                s.started_at,s.last_seen,s.ended_at,s.credited_seconds,s.anchored,s.anchor_mode
                FROM sessions s JOIN users u ON u.user_id=s.user_id
                {where} ORDER BY s.last_seen DESC LIMIT ?""",
            values,
        ).fetchall()
    return {"sessions": [row_dict(row) for row in rows]}


@app.get("/api/v1/admin/users", dependencies=[Depends(require_admin)])
def admin_users(limit: int = Query(default=500, ge=1, le=2000)):
    with connection() as db:
        rows = db.execute(
            """SELECT user_id,username,display_name,country_code,first_seen,last_seen,
               total_seconds,(total_seconds/3600.0) AS total_hours
               FROM users ORDER BY last_seen DESC LIMIT ?""",
            (limit,),
        ).fetchall()
    return {"users": [row_dict(row) for row in rows]}


@app.get("/api/v1/admin/network-profiles", dependencies=[Depends(require_admin)])
def admin_network_profiles(limit: int = Query(default=500, ge=1, le=2000)):
    with connection() as db:
        rows = db.execute(
            """SELECT n.session_id,n.user_id,u.username,u.display_name,
               n.ip_address,n.country,n.country_code,n.region,n.city,n.isp,
               n.organization,n.asn,n.timezone,n.latitude,n.longitude,
               n.consented_at,n.created_at
               FROM network_profiles n
               JOIN users u ON u.user_id=n.user_id
               ORDER BY n.created_at DESC LIMIT ?""",
            (limit,),
        ).fetchall()
    return {"network_profiles": [row_dict(row) for row in rows]}


@app.get("/api/v1/admin/servers", dependencies=[Depends(require_admin)])
def admin_servers():
    with connection() as db:
        rows = db.execute(
            """SELECT place_id,job_id,MAX(game_name) AS game_name,COUNT(*) AS active_users,
               SUM(CASE WHEN anchored=1 THEN 1 ELSE 0 END) AS anchored_users,
               MAX(last_seen) AS last_seen
               FROM sessions WHERE ended_at IS NULL AND last_seen>=?
               GROUP BY place_id,job_id ORDER BY active_users DESC,last_seen DESC""",
            (active_cutoff(),),
        ).fetchall()
    return {"servers": [row_dict(row) for row in rows]}


@app.get("/api/v1/admin/recoveries", dependencies=[Depends(require_admin)])
def admin_recoveries(limit: int = Query(default=200, ge=1, le=1000)):
    with connection() as db:
        rows = db.execute(
            """SELECT c.*,s.user_id,u.username,s.place_id,s.job_id
               FROM recovery_commands c
               JOIN sessions s ON s.id=c.target_session_id
               JOIN users u ON u.user_id=s.user_id
               ORDER BY c.created_at DESC LIMIT ?""",
            (limit,),
        ).fetchall()
    return {"recoveries": [row_dict(row) for row in rows]}
