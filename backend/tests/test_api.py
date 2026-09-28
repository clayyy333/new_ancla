import importlib
import os
import tempfile

from fastapi.testclient import TestClient

_temp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_temp.close()
os.environ["DATABASE_PATH"] = _temp.name
os.environ["ADMIN_TOKEN"] = "admin-test-token"
os.environ["CLIENT_INGEST_KEY"] = "client-test-key"

main = importlib.import_module("app.main")


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
            json={"anchored": True, "anchor_mode": "test"},
        )
        assert response.status_code == 200

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
