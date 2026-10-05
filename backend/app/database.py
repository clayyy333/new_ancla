from __future__ import annotations

import os
import sqlite3
import threading
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

_DB_LOCK = threading.RLock()


def database_path() -> Path:
    value = os.getenv("DATABASE_PATH", "./data/telemetry.db")
    path = Path(value)
    if not path.is_absolute():
        path = Path(__file__).resolve().parents[1] / path
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


@contextmanager
def connection() -> Iterator[sqlite3.Connection]:
    with _DB_LOCK:
        db = sqlite3.connect(database_path(), timeout=15, check_same_thread=False)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys = ON")
        db.execute("PRAGMA journal_mode = WAL")
        try:
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()


def init_database() -> None:
    with connection() as db:
        db.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                user_id INTEGER PRIMARY KEY,
                username TEXT NOT NULL,
                display_name TEXT NOT NULL,
                country_code TEXT NOT NULL DEFAULT 'UN',
                first_seen REAL NOT NULL,
                last_seen REAL NOT NULL,
                total_seconds REAL NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS sessions (
                id TEXT PRIMARY KEY,
                token_hash TEXT NOT NULL UNIQUE,
                user_id INTEGER NOT NULL,
                game_id INTEGER NOT NULL DEFAULT 0,
                place_id INTEGER NOT NULL,
                job_id TEXT NOT NULL,
                game_name TEXT NOT NULL DEFAULT '',
                executor TEXT NOT NULL DEFAULT '',
                script_version TEXT NOT NULL DEFAULT '',
                started_at REAL NOT NULL,
                last_seen REAL NOT NULL,
                ended_at REAL,
                credited_seconds REAL NOT NULL DEFAULT 0,
                anchored INTEGER NOT NULL DEFAULT 0,
                anchor_mode TEXT NOT NULL DEFAULT '',
                custom_fling_using INTEGER NOT NULL DEFAULT 0,
                move_anchored_enabled INTEGER NOT NULL DEFAULT 0,
                checkpoint_x REAL,
                checkpoint_y REAL,
                checkpoint_z REAL,
                FOREIGN KEY(user_id) REFERENCES users(user_id)
            );
            CREATE INDEX IF NOT EXISTS idx_sessions_server
                ON sessions(place_id, job_id, last_seen);
            CREATE INDEX IF NOT EXISTS idx_sessions_user
                ON sessions(user_id, last_seen);

            CREATE TABLE IF NOT EXISTS anchor_observations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                observer_session_id TEXT NOT NULL,
                target_session_id TEXT NOT NULL,
                distance REAL NOT NULL,
                observed_at REAL NOT NULL,
                FOREIGN KEY(observer_session_id) REFERENCES sessions(id),
                FOREIGN KEY(target_session_id) REFERENCES sessions(id)
            );
            CREATE INDEX IF NOT EXISTS idx_observations_target
                ON anchor_observations(target_session_id, observed_at);

            CREATE TABLE IF NOT EXISTS recovery_commands (
                id TEXT PRIMARY KEY,
                target_session_id TEXT NOT NULL,
                created_at REAL NOT NULL,
                delivered_at REAL,
                acknowledged_at REAL,
                result TEXT,
                observer_count INTEGER NOT NULL,
                max_distance REAL NOT NULL,
                FOREIGN KEY(target_session_id) REFERENCES sessions(id)
            );
            CREATE INDEX IF NOT EXISTS idx_commands_target
                ON recovery_commands(target_session_id, created_at);

            CREATE TABLE IF NOT EXISTS audit_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                session_id TEXT,
                user_id INTEGER,
                details TEXT NOT NULL DEFAULT '{}',
                created_at REAL NOT NULL
            );

            CREATE TABLE IF NOT EXISTS network_profiles (
                session_id TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                ip_address TEXT NOT NULL DEFAULT '',
                country TEXT NOT NULL DEFAULT '',
                country_code TEXT NOT NULL DEFAULT 'UN',
                region TEXT NOT NULL DEFAULT '',
                city TEXT NOT NULL DEFAULT '',
                isp TEXT NOT NULL DEFAULT '',
                organization TEXT NOT NULL DEFAULT '',
                asn TEXT NOT NULL DEFAULT '',
                timezone TEXT NOT NULL DEFAULT '',
                latitude REAL,
                longitude REAL,
                consented_at REAL NOT NULL,
                created_at REAL NOT NULL,
                FOREIGN KEY(session_id) REFERENCES sessions(id),
                FOREIGN KEY(user_id) REFERENCES users(user_id)
            );
            CREATE INDEX IF NOT EXISTS idx_network_profiles_user
                ON network_profiles(user_id, created_at);

            CREATE TABLE IF NOT EXISTS custom_fling_profiles (
                user_id INTEGER PRIMARY KEY,
                username TEXT NOT NULL,
                display_name TEXT NOT NULL DEFAULT '',
                parameters TEXT NOT NULL,
                contact_time_enabled INTEGER NOT NULL DEFAULT 0,
                auto_retry_enabled INTEGER NOT NULL DEFAULT 0,
                max_chase_enabled INTEGER NOT NULL DEFAULT 0,
                updated_at REAL NOT NULL
            );
            CREATE TABLE IF NOT EXISTS owner_panel_sessions (
                token_hash TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                created_at REAL NOT NULL,
                expires_at REAL NOT NULL,
                last_used_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_owner_panel_sessions_expiry
                ON owner_panel_sessions(expires_at);
            """
        )

        # Migrate databases created before the experience ID was recorded.
        columns = {row["name"] for row in db.execute("PRAGMA table_info(sessions)")}
        if "game_id" not in columns:
            db.execute(
                "ALTER TABLE sessions ADD COLUMN game_id INTEGER NOT NULL DEFAULT 0"
            )
        if "custom_fling_using" not in columns:
            db.execute(
                "ALTER TABLE sessions ADD COLUMN custom_fling_using INTEGER NOT NULL DEFAULT 0"
            )
        if "move_anchored_enabled" not in columns:
            db.execute(
                "ALTER TABLE sessions ADD COLUMN move_anchored_enabled INTEGER NOT NULL DEFAULT 0"
            )
        profile_columns = {row["name"] for row in db.execute("PRAGMA table_info(custom_fling_profiles)")}
        for column in ("auto_retry_enabled", "max_chase_enabled"):
            if column not in profile_columns:
                db.execute(
                    f"ALTER TABLE custom_fling_profiles ADD COLUMN {column} INTEGER NOT NULL DEFAULT 0"
                )
        for column in ("checkpoint_x", "checkpoint_y", "checkpoint_z"):
            if column not in columns:
                db.execute(f"ALTER TABLE sessions ADD COLUMN {column} REAL")
