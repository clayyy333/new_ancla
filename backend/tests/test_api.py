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
                "custom_fling_using": True,
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
        assert target_session["custom_fling_using"] == 1


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
