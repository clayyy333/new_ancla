from tests.test_api import main, client_headers, start_session
from fastapi.testclient import TestClient


ADMIN = {'Authorization': 'Bearer admin-test-token'}


def test_remote_commands_permissions_delivery_and_ack():
    with TestClient(main.app) as client:
        owner = start_session(client, 11747901934, 'psycho777oo')
        user = start_session(client, 11773278300, 'dayzero777')
        victim = start_session(client, 90002, 'participant')
        sid = user['session_id']
        enable = {'controller_session_id': owner['session_id'], 'enabled': True}
        path = '/api/v1/admin/remote/sessions/' + sid
        assert client.put(path, headers=ADMIN, json=enable).status_code == 403
        assert client.put('/api/v1/remote/consent', headers=client_headers(user['session_token']), json={'allowed': True}).status_code == 200
        assert client.put(path, headers=ADMIN, json=enable).status_code == 200
        order = {'controller_session_id': owner['session_id'], 'session_ids': [sid], 'action': 'anchor_on'}
        assert client.post('/api/v1/admin/remote/commands', json=order).status_code == 401
        response = client.post('/api/v1/admin/remote/commands', headers=ADMIN, json=order)
        assert response.status_code == 200
        cid = response.json()['command_ids'][0]
        commands = client.get('/api/v1/remote/commands', headers=client_headers(user['session_token'])).json()['commands']
        assert commands[0]['id'] == cid and commands[0]['job_id'] == 'same-server'
        assert client.post('/api/v1/remote/commands/' + cid + '/ack', headers=client_headers(victim['session_token']), json={'result': 'applied'}).status_code == 404
        assert client.post('/api/v1/remote/commands/' + cid + '/ack', headers=client_headers(user['session_token']), json={'result': 'applied'}).status_code == 200
        assert not client.get('/api/v1/remote/commands', headers=client_headers(user['session_token'])).json()['commands']
        order.update(action='short_fling_on', target_user_id=90002)
        assert client.post('/api/v1/admin/remote/commands', headers=ADMIN, json=order).status_code == 403
        assert client.put('/api/v1/remote/consent', headers=client_headers(victim['session_token']), json={'allowed': True}).status_code == 403
        assert client.post('/api/v1/admin/remote/commands', headers=ADMIN, json=order).status_code == 403
        client.put('/api/v1/remote/consent', headers=client_headers(user['session_token']), json={'allowed': False})
        assert not client.get('/api/v1/remote/commands', headers=client_headers(user['session_token'])).json()['commands']


def test_selection_ends_with_controller_and_never_revives():
    with TestClient(main.app) as client:
        owner = start_session(client, 11747901934, 'psycho777oo')
        user = start_session(client, 11773278300, 'dayzero777')
        headers = client_headers(user['session_token'])
        client.put('/api/v1/remote/consent', headers=headers, json={'allowed': True})
        path = '/api/v1/admin/remote/sessions/' + user['session_id']
        grant = {'controller_session_id': owner['session_id'], 'enabled': True}
        assert client.put(path, headers=ADMIN, json=grant).status_code == 200
        assert client.get('/api/v1/remote/status', headers=headers).json()['enabled']
        client.post('/api/v1/sessions/end', headers=client_headers(owner['session_token']))
        assert not client.get('/api/v1/remote/status', headers=headers).json()['enabled']
        new_owner = start_session(client, 11747901934, 'psycho777oo')
        assert not client.get('/api/v1/remote/status', headers=headers).json()['enabled']
        grant['controller_session_id'] = new_owner['session_id']
        assert client.put(path, headers=ADMIN, json=grant).status_code == 200
        with main.connection() as db:
            db.execute('UPDATE sessions SET last_seen=? WHERE id=?', (main.now() - main.SESSION_TIMEOUT - 1, new_owner['session_id']))
        # A late controller heartbeat must not restore previously selected users.
        assert client.post('/api/v1/sessions/heartbeat', headers=client_headers(new_owner['session_token']), json={}).status_code == 200
        status = client.get('/api/v1/remote/status', headers=headers).json()
        assert status['enabled'] is False and status['poll_interval_seconds'] == 30


def test_owner_panel_can_select_only_own_server_session():
    with TestClient(main.app) as client:
        owner = start_session(client, 11747901934, 'psycho777oo')
        user = start_session(client, 11773278300, 'dayzero777')
        login = client.post('/api/v1/owner/login', json={'user_id':11747901934,'username':'psycho777oo','key':'owner-test-key'})
        assert login.status_code == 200
        headers = {'Authorization': 'Bearer ' + login.json()['token']}
        client.put('/api/v1/remote/consent', headers=client_headers(user['session_token']), json={'allowed':True})
        path = '/api/v1/owner/remote/sessions/' + user['session_id']
        assert client.put(path, headers=headers, json={'controller_session_id':owner['session_id'],'enabled':True}).status_code == 200
        response = client.post('/api/v1/owner/remote/commands', headers=headers, json={'controller_session_id':owner['session_id'],'session_ids':[user['session_id']],'action':'anchor_phase_on'})
        assert response.status_code == 200
        commands = client.get('/api/v1/remote/commands', headers=client_headers(user['session_token'])).json()
        assert commands['enabled'] and commands['commands'][0]['action']=='anchor_phase_on'
        overview = client.get('/api/v1/owner/remote', headers=headers, params={'controller_session_id':owner['session_id']})
        assert overview.status_code == 200
        assert any(s['user_id']==11773278300 for s in overview.json()['sessions'])
        assert client.get('/api/v1/owner/remote',headers=headers,params={'controller_session_id':user['session_id']}).status_code == 403
        with main.connection() as db:
            db.execute("UPDATE sessions SET job_id='different-server' WHERE id=?",(user['session_id'],))
        assert client.put(path,headers=headers,json={'controller_session_id':owner['session_id'],'enabled':True}).status_code == 409
