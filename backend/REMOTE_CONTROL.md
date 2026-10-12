# Remote control API (backend preparation)

The in-script owner panel now exposes controls only in its same-server view.
The client settings include a session-only consent button. No automatic opt-in.
Existing telemetry and anchor recovery endpoints remain unchanged.

Client endpoints use the existing session Bearer token and client key:

- `PUT /api/v1/remote/consent` with `{"allowed":true}`: opt in for this session.
- `GET /api/v1/remote/status`: enabled state and suggested polling interval.
- `GET /api/v1/remote/commands`: pending, unexpired commands for this session.
- `POST /api/v1/remote/commands/{id}/ack` with result `applied`, `failed`, or `rejected`.

Admin endpoints require the existing ADMIN_TOKEN:

- `PUT /api/v1/admin/remote/sessions/{session_id}` with `controller_session_id`
  (an active owner script session) and `enabled`.
- `POST /api/v1/admin/remote/commands` with `controller_session_id`, `session_ids`
  (1–6 unique session IDs), `action`, and optionally `target_user_id`.
- `GET /api/v1/admin/remote`: active sessions, permissions, and latest command results.

Allowed actions: `anchor_on`, `anchor_off`, `short_fling_on`, `short_fling_off`,
`anchor_phase_on`, `anchor_phase_off`, `stop_remote`. Arbitrary code and arbitrary settings are not accepted.
All recipients must consent, be enabled, and share game/place/job with the owner.
The fling target must also be an active consenting participant on that server.
Enabling is limited to six active sessions globally. Commands expire after 15 seconds;
a new command cancels older pending commands for each recipient. Revoking permission
cancels pending commands, but cannot itself stop a currently running client action.

Client safeguards:

- Show explicit permission and revocation controls, stopping remote-owned actions on revocation.
- Discover enablement during normal backend communications, then poll every second only while enabled.
- Validate game/place/job and expiry again immediately before executing.
- Deduplicate command IDs: unacknowledged commands are retried, not exactly-once delivered.
- Use existing start/stop cleanup flows, never evaluate remote code.
- Map `stop_remote` only to actions initiated remotely, not unrelated manual features.
- Return actual execution results instead of treating receipt as success.

Session identities are client-reported in the existing backend. Owner UserId checks
do NOT independently verify Roblox identity; remote admin endpoints rely on ADMIN_TOKEN.
Do not expose that token in the Roblox script. No deployment or push is performed here.

The in-script panel uses `/api/v1/owner/remote` (GET),
`/api/v1/owner/remote/sessions/{session_id}` (PUT), and
`/api/v1/owner/remote/commands` (POST), authenticated using the existing private
owner-panel login token, never ADMIN_TOKEN. The controller script session must
belong to that panel owner. Selections expire with that exact script session.
When opt-in is disabled there are no additional remote polls. With consent but
without selection, status is checked at the normal 30-second interval; selection
enables command polling every second after the previous request completes.
Repeated connection errors stop remotely owned actions and revert to slow polling.
Conflicting/manual actions are rejected rather than silently replaced.
