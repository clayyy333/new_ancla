"""Opt-in, session-scoped remote commands. No arbitrary code execution."""
import uuid
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from .database import connection

PERSONAL_REMOTE_ACCOUNT = (11773278300, 'dayzero777')


def personal_remote_account(session):
    return (session['user_id'], session.get('username', '').lower()) == PERSONAL_REMOTE_ACCOUNT


def clear_remote_selection(db, session_id, timestamp):
    """Close both this recipient's grant and grants controlled by this session."""
    db.execute("UPDATE remote_commands SET acknowledged_at=?,result='cancelled' WHERE acknowledged_at IS NULL AND (target_session_id=? OR controller_session_id=?)", (timestamp, session_id, session_id))
    db.execute('UPDATE remote_controls SET enabled=0,controller_session_id=NULL WHERE session_id=? OR controller_session_id=?', (session_id, session_id))


def expire_remote_selections(db, cutoff, timestamp):
    # Cleanup before heartbeats refresh last_seen, so an expired grant cannot revive.
    stale = db.execute('''SELECT r.session_id FROM remote_controls r
        LEFT JOIN sessions t ON t.id=r.session_id
        LEFT JOIN sessions c ON c.id=r.controller_session_id
        WHERE r.enabled=1 AND (r.consent=0 OR t.id IS NULL OR c.id IS NULL
        OR t.ended_at IS NOT NULL OR c.ended_at IS NOT NULL
        OR t.last_seen<? OR c.last_seen<? OR t.game_id<>c.game_id
        OR t.place_id<>c.place_id OR t.job_id<>c.job_id OR t.user_id<>11773278300)''', (cutoff, cutoff)).fetchall()
    for row in stale:
        db.execute("UPDATE remote_commands SET acknowledged_at=?,result='cancelled' WHERE target_session_id=? AND acknowledged_at IS NULL", (timestamp, row['session_id']))
        db.execute('UPDATE remote_controls SET enabled=0,controller_session_id=NULL WHERE session_id=?', (row['session_id'],))


class Consent(BaseModel):
    allowed: bool


class Enable(BaseModel):
    controller_session_id: str = Field(min_length=1, max_length=128)
    enabled: bool


class Order(BaseModel):
    controller_session_id: str = Field(min_length=1, max_length=128)
    session_ids: list[str] = Field(min_length=1, max_length=6)
    action: Literal['anchor_on', 'anchor_off', 'anchor_phase_on', 'anchor_phase_off', 'short_fling_on', 'short_fling_off', 'stop_remote']
    target_user_id: int | None = Field(default=None, gt=0)


class Ack(BaseModel):
    result: Literal['applied', 'failed', 'rejected']


def create_router(require_admin, require_session, now, active_cutoff, owners, audit, require_owner_panel=None):
    router = APIRouter(prefix='/api/v1')

    def live(db, sid):
        expire_remote_selections(db, active_cutoff(), now())
        row = db.execute('SELECT * FROM sessions WHERE id=? AND ended_at IS NULL AND last_seen>=?', (sid, active_cutoff())).fetchone()
        if not row:
            raise HTTPException(409, 'Session offline or expired')
        value = dict(row)
        identity = db.execute('SELECT username FROM users WHERE user_id=?', (value['user_id'],)).fetchone()
        value['username'] = identity['username'] if identity else ''
        return value

    def same_server(a, b):
        return all(a[k] == b[k] for k in ('game_id', 'place_id', 'job_id'))

    def controller(db, sid):
        s = live(db, sid)
        if s['user_id'] not in owners:
            raise HTTPException(403, 'Controller must be an owner session')
        return s

    def eligible(db, target, owner):
        if not personal_remote_account(target):
            raise HTTPException(403, 'Remote control is restricted to the preauthorized personal account')
        if not same_server(target, owner):
            raise HTTPException(409, 'Different server')
        control = db.execute('SELECT * FROM remote_controls WHERE session_id=?', (target['id'],)).fetchone()
        if not control or not control['consent'] or not control['enabled'] or control['controller_session_id'] != owner['id']:
            raise HTTPException(403, 'Remote control not authorized')

    def cancel(db, sid):
        db.execute("UPDATE remote_commands SET acknowledged_at=?,result='cancelled' WHERE target_session_id=? AND acknowledged_at IS NULL", (now(), sid))

    @router.put('/remote/consent')
    def consent(payload: Consent, session=Depends(require_session)):
        with connection() as db:
            target = live(db, session['id'])
            if payload.allowed and not personal_remote_account(target):
                raise HTTPException(403, 'Account is not preauthorized')
            db.execute('INSERT INTO remote_controls(session_id,consent) VALUES(?,?) ON CONFLICT(session_id) DO UPDATE SET consent=excluded.consent', (session['id'], int(payload.allowed)))
            if not payload.allowed:
                db.execute('UPDATE remote_controls SET enabled=0,controller_session_id=NULL WHERE session_id=?', (session['id'],))
                cancel(db, session['id'])
            audit(db, 'remote_consent', session['id'], session['user_id'], {'allowed': payload.allowed})
        return {'ok': True}

    @router.put('/admin/remote/sessions/{session_id}', dependencies=[Depends(require_admin)])
    def enable(session_id: str, payload: Enable):
        with connection() as db:
            target = live(db, session_id)
            if not personal_remote_account(target):
                raise HTTPException(403, 'Account is not preauthorized')
            owner = controller(db, payload.controller_session_id)
            if not same_server(target, owner):
                raise HTTPException(409, 'Different server')
            control = db.execute('SELECT * FROM remote_controls WHERE session_id=?', (session_id,)).fetchone()
            if not control or not control['consent']:
                raise HTTPException(403, 'User consent required')
            count = db.execute('SELECT COUNT(*) FROM remote_controls r JOIN sessions s ON s.id=r.session_id WHERE r.enabled=1 AND r.consent=1 AND s.ended_at IS NULL AND s.last_seen>=? AND r.session_id<>?', (active_cutoff(), session_id)).fetchone()[0]
            if payload.enabled and count >= 6:
                raise HTTPException(409, 'Maximum six remotely controlled sessions')
            cancel(db, session_id)
            db.execute('UPDATE remote_controls SET enabled=?,controller_session_id=? WHERE session_id=?', (int(payload.enabled), owner['id'] if payload.enabled else None, session_id))
            audit(db, 'remote_enabled', session_id, target['user_id'], {'enabled': payload.enabled, 'controller': owner['id']})
        return {'ok': True}

    @router.get('/remote/status')
    def status(session=Depends(require_session)):
        with connection() as db:
            target = live(db, session['id'])
            control = db.execute('SELECT * FROM remote_controls WHERE session_id=?', (session['id'],)).fetchone()
            enabled = False
            if control and control['enabled'] and control['consent']:
                try:
                    enabled = same_server(target, controller(db, control['controller_session_id']))
                except HTTPException:
                    pass
        return {'enabled': enabled, 'poll_interval_seconds': 1 if enabled else 30}

    @router.post('/admin/remote/commands', dependencies=[Depends(require_admin)])
    def issue(payload: Order):
        if len(set(payload.session_ids)) != len(payload.session_ids):
            raise HTTPException(422, 'Duplicate sessions')
        if payload.action == 'short_fling_on' and payload.target_user_id is None:
            raise HTTPException(422, 'Fling target required')
        ids = []
        timestamp = now()
        with connection() as db:
            owner = controller(db, payload.controller_session_id)
            # Validate all recipients before queuing anything (atomic batch).
            targets = [live(db, sid) for sid in payload.session_ids]
            for target in targets:
                eligible(db, target, owner)
            if payload.action == 'short_fling_on':
                victim = db.execute('SELECT * FROM sessions WHERE user_id=? AND game_id=? AND place_id=? AND job_id=? AND ended_at IS NULL AND last_seen>=? ORDER BY last_seen DESC LIMIT 1', (payload.target_user_id, owner['game_id'], owner['place_id'], owner['job_id'], active_cutoff())).fetchone()
                permission = victim and db.execute('SELECT consent FROM remote_controls WHERE session_id=?', (victim['id'],)).fetchone()
                if not permission or not permission['consent'] or any(t['user_id'] == payload.target_user_id for t in targets):
                    raise HTTPException(403, 'Target must be a consenting participant, not a recipient')
            for target in targets:
                cancel(db, target['id'])
                cid = str(uuid.uuid4())
                db.execute('INSERT INTO remote_commands(id,target_session_id,controller_session_id,action,target_user_id,created_at,expires_at) VALUES(?,?,?,?,?,?,?)', (cid, target['id'], owner['id'], payload.action, payload.target_user_id, timestamp, timestamp + 15))
                ids.append(cid)
                audit(db, 'remote_command', target['id'], target['user_id'], {'id': cid, 'action': payload.action})
        return {'command_ids': ids, 'expires_at': timestamp + 15}

    @router.get('/remote/commands')
    def poll(session=Depends(require_session)):
        with connection() as db:
            target = live(db, session['id'])
            control = db.execute('SELECT * FROM remote_controls WHERE session_id=?', (session['id'],)).fetchone()
            if not control or not control['enabled'] or not control['consent']:
                return {'commands': [], 'enabled': False}
            try:
                owner = controller(db, control['controller_session_id'])
                eligible(db, target, owner)
            except HTTPException:
                return {'commands': [], 'enabled': False}
            rows = db.execute('SELECT * FROM remote_commands WHERE target_session_id=? AND controller_session_id=? AND acknowledged_at IS NULL AND expires_at>? ORDER BY created_at LIMIT 1', (target['id'], owner['id'], now())).fetchall()
            if rows and rows[0]['action'] == 'short_fling_on':
                participant = db.execute('SELECT s.id FROM sessions s JOIN remote_controls r ON r.session_id=s.id WHERE s.user_id=? AND s.game_id=? AND s.place_id=? AND s.job_id=? AND s.ended_at IS NULL AND s.last_seen>=? AND r.consent=1 LIMIT 1', (rows[0]['target_user_id'], target['game_id'], target['place_id'], target['job_id'], active_cutoff())).fetchone()
                if not participant:
                    cancel(db, target['id'])
                    return {'commands': [], 'enabled': True}
            for row in rows:
                db.execute('UPDATE remote_commands SET delivered_at=COALESCE(delivered_at,?) WHERE id=?', (now(), row['id']))
        return {'enabled': True, 'commands': [dict(r) | {'place_id': target['place_id'], 'job_id': target['job_id'], 'game_id': target['game_id']} for r in rows]}

    @router.post('/remote/commands/{command_id}/ack')
    def ack(command_id: str, payload: Ack, session=Depends(require_session)):
        with connection() as db:
            target = live(db, session['id'])
            row = db.execute('SELECT * FROM remote_commands WHERE id=? AND target_session_id=?', (command_id, session['id'])).fetchone()
            if not row:
                raise HTTPException(404, 'Command not found')
            if row['acknowledged_at'] is None:
                if row['expires_at'] <= now() or row['delivered_at'] is None:
                    raise HTTPException(409, 'Command expired or not delivered')
                owner = controller(db, row['controller_session_id'])
                eligible(db, target, owner)
                db.execute('UPDATE remote_commands SET acknowledged_at=?,result=? WHERE id=?', (now(), payload.result, command_id))
        return {'ok': True}

    @router.get('/admin/remote', dependencies=[Depends(require_admin)])
    def overview():
        with connection() as db:
            expire_remote_selections(db, active_cutoff(), now())
            sessions = db.execute('SELECT s.id,s.user_id,s.place_id,s.job_id,r.consent,r.enabled,r.controller_session_id FROM sessions s LEFT JOIN remote_controls r ON r.session_id=s.id WHERE s.ended_at IS NULL AND s.last_seen>=?', (active_cutoff(),)).fetchall()
            commands = db.execute('SELECT * FROM remote_commands ORDER BY created_at DESC LIMIT 100').fetchall()
        timestamp = now()
        return {'sessions': [dict(s) for s in sessions], 'commands': [dict(c) | {'status': c['result'] or ('expired' if c['expires_at'] <= timestamp else 'pending')} for c in commands]}

    if require_owner_panel is not None:
        def bound_owner(sid, panel):
            with connection() as db:
                owner = controller(db, sid)
                if owner['user_id'] != panel['user_id']:
                    raise HTTPException(403, 'Controller does not belong to panel owner')
            return owner

        @router.get('/owner/remote')
        def owner_overview(controller_session_id: str, panel=Depends(require_owner_panel)):
            owner = bound_owner(controller_session_id, panel)
            with connection() as db:
                expire_remote_selections(db, active_cutoff(), now())
                rows = db.execute('''SELECT s.id,s.user_id,u.username,s.anchored,s.anchor_mode,s.short_fling_enabled,
                    COALESCE(r.consent,0) AS consent,COALESCE(r.enabled,0) AS enabled,r.controller_session_id
                    FROM sessions s JOIN users u ON u.user_id=s.user_id LEFT JOIN remote_controls r ON r.session_id=s.id
                    WHERE s.game_id=? AND s.place_id=? AND s.job_id=? AND s.ended_at IS NULL AND s.last_seen>=?
                    ORDER BY s.last_seen DESC''', (owner['game_id'], owner['place_id'], owner['job_id'], active_cutoff())).fetchall()
                commands = db.execute('SELECT * FROM remote_commands WHERE controller_session_id=? ORDER BY created_at DESC LIMIT 100', (owner['id'],)).fetchall()
            return {'sessions': [dict(s) for s in rows], 'commands': [dict(c) | {'status': c['result'] or ('expired' if c['expires_at']<=now() else 'pending')} for c in commands]}

        @router.put('/owner/remote/sessions/{session_id}')
        def owner_enable(session_id: str, payload: Enable, panel=Depends(require_owner_panel)):
            bound_owner(payload.controller_session_id, panel)
            return enable(session_id, payload)

        @router.post('/owner/remote/commands')
        def owner_issue(payload: Order, panel=Depends(require_owner_panel)):
            bound_owner(payload.controller_session_id, panel)
            return issue(payload)

    return router
