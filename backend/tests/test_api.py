import importlib
import os
import tempfile

from fastapi.testclient import TestClient

_temp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_temp.close()
os.environ["DATABASE_PATH"] = _temp.name
os.environ["ADMIN_TOKEN"] = "admin-test-token"
os.environ["CLIENT_INGEST_KEY"] = "client-test-key"
os.environ["OWNER_PANEL_KEY"] = "owner-test-key"

main = importlib.import_module("app.main")
main.NETWORK_INFO_ALLOWED_PLACE_IDS = {100}
main.OWNER_GAME_PLACE_ID = 100
main.ANCHOR_ALLOWED_GAME_ID = 200
main.ANCHOR_ALLOWED_PLACE_ID = 100


def client_headers(token=None):
    headers = {"X-Client-Key": "client-test-key"}
    if token:
        headers["Authorization"] = "Bearer " + token
    return headers


def start_session(client, user_id, username):
    response = client.post(
        "/api/v1/sessions/start",
        headers=client_headers(),
        json={
            "user_id": user_id,
            "username": username,
            "display_name": username,
            "game_id": 200,
            "place_id": 100,
            "job_id": "same-server",
            "game_name": "Test Game",
            "executor": "test",
            "script_version": "1.0",
            "country_code": "PE",
        },
    )
    assert response.status_code == 200
    return response.json()


def test_session_dashboard_and_anchor_recovery():
    with TestClient(main.app) as client:
        target = start_session(client, 1, "target")
        observer = start_session(client, 2, "observer")

        response = client.post(
            "/api/v1/sessions/heartbeat",
            headers=client_headers(target["session_token"]),
            json={
                "anchored": True,
                "gift_delivery_enabled": True,
                "move_anchored_enabled": True,
                "anchor_mode": "test",
                "checkpoint_x": 10.5,
                "checkpoint_y": 20.0,
                "checkpoint_z": -30.25,
            },
        )
        assert response.status_code == 200
        response = client.get(
            "/api/v1/anchor/targets",
            headers=client_headers(observer["session_token"]),
        )
        assert response.status_code == 200
        assert response.json()["targets"] == [
            {
                "user_id": 1,
                "username": "target",
                "anchor_mode": "test",
                "checkpoint_x": 10.5,
                "checkpoint_y": 20.0,
                "checkpoint_z": -30.25,
            }
        ]

        response = client.post(
            "/api/v1/anchor/observe",
            headers=client_headers(observer["session_token"]),
            json={"target_user_id": 1, "distance": 12.5},
        )
        assert response.status_code == 200
        assert response.json()["command_created"] is True

        response = client.get(
            "/api/v1/anchor/commands",
            headers=client_headers(target["session_token"]),
        )
        assert response.status_code == 200
        command = response.json()["commands"][0]
        assert command["type"] == "force_local_checkpoint_return"

        response = client.post(
            "/api/v1/anchor/commands/" + command["id"] + "/ack",
            headers=client_headers(target["session_token"]),
            json={"result": "returned"},
        )
        assert response.status_code == 200

        admin_headers = {"Authorization": "Bearer admin-test-token"}
        summary = client.get("/api/v1/admin/summary", headers=admin_headers)
        assert summary.status_code == 200
        assert summary.json()["total_users"] == 2
        sessions = client.get("/api/v1/admin/sessions", headers=admin_headers)
        assert sessions.status_code == 200
        assert len(sessions.json()["sessions"]) == 2
        target_session = next(item for item in sessions.json()["sessions"] if item["user_id"] == 1)
        assert target_session["gift_delivery_enabled"] == 1
        assert target_session["move_anchored_enabled"] == 1


def test_combined_anchor_modes_are_visible_without_recovery_targets():
    with TestClient(main.app) as client:
        target = start_session(client, 901, "combined-anchor-user")
        observer = start_session(client, 902, "combined-anchor-observer")
        admin_headers = {"Authorization": "Bearer admin-test-token"}
        for mode in ("Combinada", "Desfase"):
            response = client.post(
                "/api/v1/sessions/heartbeat",
                headers=client_headers(target["session_token"]),
                json={"anchored": True, "anchor_mode": mode,
                      "checkpoint_x": 1, "checkpoint_y": 2, "checkpoint_z": 3},
            )
            assert response.status_code == 200
            sessions = client.get("/api/v1/admin/sessions", headers=admin_headers)
            row = next(x for x in sessions.json()["sessions"] if x["user_id"] == 901)
            assert row["anchored"] == 1
            assert row["anchor_mode"] == mode
            targets = client.get("/api/v1/anchor/targets",
                                 headers=client_headers(observer["session_token"]))
            assert targets.status_code == 200
            assert all(x["user_id"] != 901 for x in targets.json()["targets"])
        response = client.post("/api/v1/sessions/heartbeat",
                               headers=client_headers(target["session_token"]),
                               json={"anchored": False})
        assert response.status_code == 200
        sessions = client.get("/api/v1/admin/sessions", headers=admin_headers)
        row = next(x for x in sessions.json()["sessions"] if x["user_id"] == 901)
        assert row["anchored"] == 0
        assert row["anchor_mode"] == ""


def test_short_fling_activity_transitions_and_session_end():
    with TestClient(main.app) as client:
        target = start_session(client, 903, "short-fling-user")
        admin_headers = {"Authorization": "Bearer admin-test-token"}

        def session_row():
            response = client.get("/api/v1/admin/sessions", headers=admin_headers)
            assert response.status_code == 200
            return next(x for x in response.json()["sessions"] if x["user_id"] == 903)

        assert session_row()["short_fling_enabled"] == 0
        for enabled in (True, False, True):
            response = client.post(
                "/api/v1/sessions/heartbeat",
                headers=client_headers(target["session_token"]),
                json={"short_fling_enabled": enabled},
            )
            assert response.status_code == 200
            row = session_row()
            assert row["short_fling_enabled"] == int(enabled)
            assert row["gift_delivery_enabled"] == 0
        response = client.post("/api/v1/sessions/end",
                               headers=client_headers(target["session_token"]))
        assert response.status_code == 200
        with main.connection() as db:
            ended = db.execute("SELECT short_fling_enabled FROM sessions WHERE id=?",
                               (target["session_id"],)).fetchone()
        assert ended["short_fling_enabled"] == 0


def test_folding_cleanup_activity_and_session_end():
    with TestClient(main.app) as client:
        target = start_session(client, 904, "folding-cleanup-user")

        def session_row():
            response = client.get(
                "/api/v1/admin/sessions",
                headers={"Authorization": "Bearer admin-test-token"},
            )
            assert response.status_code == 200
            return next(row for row in response.json()["sessions"] if row["user_id"] == 904)

        assert session_row()["folding_cleanup_enabled"] == 0
        for enabled in (True, False, True):
            response = client.post(
                "/api/v1/sessions/heartbeat",
                headers=client_headers(target["session_token"]),
                json={"folding_cleanup_enabled": enabled},
            )
            assert response.status_code == 200
            row = session_row()
            assert row["folding_cleanup_enabled"] == int(enabled)
            assert row["anchored"] == 0  # Cleanup does not require an anchor.
        response = client.post(
            "/api/v1/sessions/end", headers=client_headers(target["session_token"])
        )
        assert response.status_code == 200
        # Ended sessions are intentionally absent from the active-sessions API.
        with main.connection() as db:
            row = db.execute(
                "SELECT folding_cleanup_enabled FROM sessions WHERE id=?",
                (target["session_id"],),
            ).fetchone()
        assert row["folding_cleanup_enabled"] == 0


def test_folding_cleanup_column_migrates_existing_database(tmp_path, monkeypatch):
    from app.database import connection, init_database

    monkeypatch.setenv("DATABASE_PATH", str(tmp_path / "legacy.db"))
    init_database()
    with connection() as db:
        db.execute("ALTER TABLE sessions DROP COLUMN folding_cleanup_enabled")
    init_database()
    init_database()  # Startup migration must also be idempotent.
    with connection() as db:
        column = next(
            row for row in db.execute("PRAGMA table_info(sessions)")
            if row["name"] == "folding_cleanup_enabled"
        )
    assert column["notnull"] == 1
    assert column["dflt_value"] == "0"


def test_network_profile_requires_consent_and_is_admin_only():
    payload = {
        "user_id": 3,
        "username": "network-user",
        "display_name": "Network User",
        "game_id": 200,
        "place_id": 100,
        "job_id": "network-server",
        "country_code": "PE",
        "network_info": {
            "ip": "203.0.113.10",
            "country": "Peru",
            "country_code": "PE",
            "region": "Lima",
            "city": "Lima",
            "isp": "Example ISP",
            "organization": "Example Org",
            "asn": "AS64500",
            "timezone": "America/Lima",
            "latitude": -12.04,
            "longitude": -77.03,
        },
    }
    with TestClient(main.app) as client:
        denied = client.post("/api/v1/sessions/start", headers=client_headers(), json=payload)
        assert denied.status_code == 422

        payload["analytics_consent"] = True
        started = client.post("/api/v1/sessions/start", headers=client_headers(), json=payload)
        assert started.status_code == 200

        unauthenticated = client.get("/api/v1/admin/network-profiles")
        assert unauthenticated.status_code == 401

        profiles = client.get(
            "/api/v1/admin/network-profiles",
            headers={"Authorization": "Bearer admin-test-token"},
        )
        assert profiles.status_code == 200
        stored = profiles.json()["network_profiles"][0]
        assert stored["user_id"] == 3
        assert stored["country_code"] == "PE"
        assert stored["isp"] == "Example ISP"


def test_network_profile_is_ignored_outside_allowed_games():
    payload = {
        "user_id": 4,
        "username": "other-game-user",
        "display_name": "Other Game User",
        "game_id": 999,
        "place_id": 999,
        "job_id": "other-server",
        "analytics_consent": True,
        "network_info": {
            "ip": "203.0.113.20",
            "country": "Peru",
            "country_code": "PE",
        },
    }
    with TestClient(main.app) as client:
        started = client.post("/api/v1/sessions/start", headers=client_headers(), json=payload)
        assert started.status_code == 200

        profiles = client.get(
            "/api/v1/admin/network-profiles",
            headers={"Authorization": "Bearer admin-test-token"},
        )
        assert all(item["user_id"] != 4 for item in profiles.json()["network_profiles"])


def test_owner_panel_login_and_scoped_players():
    with TestClient(main.app) as client:
        start_session(client, 10, "server-player")

        wrong_owner = client.post(
            "/api/v1/owner/login",
            json={
                "user_id": 10,
                "username": "server-player",
                "key": "owner-test-key",
            },
        )
        assert wrong_owner.status_code == 401

        login = client.post(
            "/api/v1/owner/login",
            json={
                "user_id": 11739864999,
                "username": "psychoo778",
                "key": "owner-test-key",
            },
        )
        assert login.status_code == 200
        owner_headers = {"Authorization": "Bearer " + login.json()["token"]}

        server_players = client.get(
            "/api/v1/owner/players?scope=server&job_id=same-server",
            headers=owner_headers,
        )
        assert server_players.status_code == 200
        assert any(item["user_id"] == 10 for item in server_players.json()["players"])

        other_servers = client.get(
            "/api/v1/owner/players?scope=game&job_id=same-server",
            headers=owner_headers,
        )
        assert other_servers.status_code == 200
        assert all(item["user_id"] != 10 for item in other_servers.json()["players"])


def test_pyschoooow_can_login_as_owner():
    with TestClient(main.app) as client:
        login = client.post(
            "/api/v1/owner/login",
            json={
                "user_id": 11794166113,
                "username": "pyschoooow",
                "key": "owner-test-key",
            },
        )
        assert login.status_code == 200
        assert login.json()["token"]


def test_gift_pin_is_required_for_every_session_including_owners():
    with TestClient(main.app) as client:
        user = start_session(client, 99123, "gift-pin-user")
        headers = client_headers(user["session_token"])
        assert user["gift_access_unlocked"] is False
        wrong = client.post("/api/v1/gifts/unlock", headers=headers, json={"pin": "wrong"})
        assert wrong.status_code == 401
        unlocked = client.post("/api/v1/gifts/unlock", headers=headers, json={"pin": "777py"})
        assert unlocked.status_code == 200
        heartbeat = client.post("/api/v1/sessions/heartbeat", headers=headers, json={})
        assert heartbeat.json()["gift_access_unlocked"] is True
        owner = start_session(client, 11794166113, "pyschoooow")
        assert owner["gift_access_unlocked"] is False
        owner_headers = client_headers(owner["session_token"])
        owner_unlock = client.post("/api/v1/gifts/unlock", headers=owner_headers, json={"pin": "777py"})
        assert owner_unlock.status_code == 200


def test_gift_activity_transitions_and_legacy_client():
    with TestClient(main.app) as client:
        user = start_session(client, 905, "gift-activity-user")
        headers = client_headers(user["session_token"])
        admin = {"Authorization": "Bearer admin-test-token"}
        login = client.post("/api/v1/owner/login", json={
            "user_id": 11739864999, "username": "psychoo778", "key": "owner-test-key"})
        assert login.status_code == 200
        owner = {"Authorization": "Bearer " + login.json()["token"]}
        def row():
            response = client.get("/api/v1/admin/sessions", headers=admin)
            assert response.status_code == 200
            return next(x for x in response.json()["sessions"] if x["user_id"] == 905)
        assert row()["gift_delivery_enabled"] == 0
        assert client.post("/api/v1/sessions/heartbeat", headers=headers,
                           json={"custom_fling_using": True}).status_code == 200
        assert row()["gift_delivery_enabled"] == 0
        for enabled in (True, False, True):
            response = client.post("/api/v1/sessions/heartbeat", headers=headers,
                                   json={"gift_delivery_enabled": enabled})
            assert response.status_code == 200
            current = row()
            assert current["gift_delivery_enabled"] == int(enabled)
            assert current["anchored"] == 0
            assert "custom_fling_using" not in current
            scoped = client.get("/api/v1/owner/players?scope=server&job_id=same-server", headers=owner)
            assert scoped.status_code == 200
            player = next(x for x in scoped.json()["players"] if x["user_id"] == 905)
            assert player["gift_delivery_enabled"] == int(enabled)
        assert client.post("/api/v1/sessions/end", headers=headers).status_code == 200
        with main.connection() as db:
            ended = db.execute("SELECT gift_delivery_enabled FROM sessions WHERE id=?",
                               (user["session_id"],)).fetchone()
        assert ended["gift_delivery_enabled"] == 0


def test_gift_activity_legacy_database_migration(monkeypatch, tmp_path):
    from app.database import connection, init_database
    monkeypatch.setenv("DATABASE_PATH", str(tmp_path / "legacy.db"))
    init_database()
    with connection() as db:
        db.execute("ALTER TABLE sessions DROP COLUMN gift_delivery_enabled")
        db.execute("INSERT INTO users(user_id,username,display_name,first_seen,last_seen) VALUES(999,'legacy','legacy',1,1)")
        db.execute("INSERT INTO sessions(id,token_hash,user_id,place_id,job_id,started_at,last_seen,custom_fling_using) VALUES('legacy','legacy',999,100,'server',1,1,1)")
    init_database()
    init_database()
    with connection() as db:
        migrated = db.execute("SELECT custom_fling_using,gift_delivery_enabled FROM sessions WHERE id='legacy'").fetchone()
    assert migrated["custom_fling_using"] == 1
    assert migrated["gift_delivery_enabled"] == 0


def test_reception_block_is_pin_free_session_only_and_idempotent():
    with TestClient(main.app) as client:
        receiver = start_session(client, 91001, "recipient")
        sender = start_session(client, 91002, "sender")
        receiver_headers = client_headers(receiver["session_token"])
        sender_headers = client_headers(sender["session_token"])
        assert receiver["gift_access_unlocked"] is False
        assert receiver["gift_reception_blocked"] is False
        def blocked():
            result = client.get("/api/v1/gifts/reception-blocks", headers=sender_headers)
            assert result.status_code == 200
            return {x["user_id"]: x["remaining_seconds"] for x in result.json()["blocked_users"]}
        assert 91001 not in blocked()
        for _ in range(2):
            result = client.post("/api/v1/gifts/block-reception", headers=receiver_headers)
            assert result.status_code == 200
            assert result.json()["gift_reception_blocked"] is True
        assert 0 < blocked()[91001] <= main.SESSION_TIMEOUT
        with main.connection() as db:
            row = db.execute("SELECT gift_access_unlocked FROM sessions WHERE id=?", (receiver["session_id"],)).fetchone()
            assert row["gift_access_unlocked"] == 0
            count = db.execute("SELECT COUNT(*) AS n FROM audit_log WHERE session_id=? AND event_type='gift_reception_blocked'", (receiver["session_id"],)).fetchone()
            assert count["n"] == 1
        # Normal heartbeats preserve the one-way session preference.
        client.post("/api/v1/sessions/heartbeat", headers=receiver_headers, json={})
        assert 91001 in blocked()
        assert client.post("/api/v1/sessions/end", headers=receiver_headers).status_code == 200
        assert 91001 not in blocked()
        reopened = start_session(client, 91001, "recipient")
        assert reopened["gift_reception_blocked"] is False
        assert 91001 not in blocked()


def test_reception_new_execution_overrides_abandoned_block_and_does_not_revive_it():
    with TestClient(main.app) as client:
        old = start_session(client, 91003, "recipient-reopen")
        observer = start_session(client, 91004, "sender-reopen")
        headers = client_headers(observer["session_token"])
        assert client.post("/api/v1/gifts/block-reception", headers=client_headers(old["session_token"])).status_code == 200
        new = start_session(client, 91003, "recipient-reopen")
        def ids():
            return [x["user_id"] for x in client.get("/api/v1/gifts/reception-blocks", headers=headers).json()["blocked_users"]]
        assert 91003 not in ids()
        # Even a delayed old heartbeat cannot restore the earlier preference.
        client.post("/api/v1/sessions/heartbeat", headers=client_headers(old["session_token"]), json={})
        assert 91003 not in ids()
        assert client.post("/api/v1/sessions/end", headers=client_headers(new["session_token"])).status_code == 200
        assert 91003 not in ids()


def test_reception_blocks_are_scoped_expire_and_require_session(monkeypatch):
    with TestClient(main.app) as client:
        receiver = start_session(client, 91005, "scoped-recipient")
        observer = start_session(client, 91006, "scoped-sender")
        foreign = start_session(client, 91007, "foreign-recipient")
        for user in (receiver, foreign):
            assert client.post("/api/v1/gifts/block-reception", headers=client_headers(user["session_token"])).status_code == 200
        with main.connection() as db:
            db.execute("UPDATE sessions SET job_id='different-server' WHERE id=?", (foreign["session_id"],))
        headers = client_headers(observer["session_token"])
        rows = client.get("/api/v1/gifts/reception-blocks", headers=headers).json()["blocked_users"]
        assert 91005 in {x["user_id"] for x in rows}
        assert 91007 not in {x["user_id"] for x in rows}
        timestamp = main.now()
        monkeypatch.setattr(main, "now", lambda: timestamp+main.SESSION_TIMEOUT+1)
        assert client.get("/api/v1/gifts/reception-blocks", headers=headers).json()["blocked_users"] == []
        assert client.post("/api/v1/gifts/block-reception", headers=client_headers()).status_code == 401


def test_public_babycar_presence_has_no_backend_key_or_private_access():
    payload = {
        "user_id": 987654,
        "username": "babycar_user",
        "display_name": "Babycar User",
        "game_id": 200,
        "place_id": 100,
        "job_id": "babycar-server",
        "game_name": "Test Game",
        "executor": "Delta",
        "script_version": "babycar_sender_lite",
    }
    with TestClient(main.app) as client:
        rejected = client.post(
            "/api/v1/public/babycar/sessions/start",
            json={**payload, "script_version": "another_script"},
        )
        assert rejected.status_code == 403

        started = client.post("/api/v1/public/babycar/sessions/start", json=payload)
        assert started.status_code == 200
        token = started.json()["session_token"]
        public_headers = {"Authorization": "Bearer " + token}

        heartbeat = client.post(
            "/api/v1/public/babycar/sessions/heartbeat",
            headers=public_headers,
            json={"gift_delivery_enabled": True, "anchored": True},
        )
        assert heartbeat.status_code == 200

        private = client.post(
            "/api/v1/sessions/heartbeat", headers=public_headers, json={}
        )
        assert private.status_code == 401

        ended = client.post(
            "/api/v1/public/babycar/sessions/end", headers=public_headers
        )
        assert ended.status_code == 200
