from tests.test_api import main, start_session, client_headers
from fastapi.testclient import TestClient


def test_feature_block_same_server_and_normal_heartbeat():
    with TestClient(main.app) as c:
        owner=start_session(c,11747901934,'psycho777oo')
        user=start_session(c,98001,'feature-user')
        login=c.post('/api/v1/owner/login',json={'user_id':11747901934,'username':'psycho777oo','key':'owner-test-key'})
        h={'Authorization':'Bearer '+login.json()['token']}
        path='/api/v1/owner/remote/features/'+user['session_id']
        body={'controller_session_id':owner['session_id'],'blocked':True}
        assert c.put(path,json=body).status_code==401
        assert c.put(path,headers=h,json=body).status_code==200
        def heartbeat():
            return c.post('/api/v1/sessions/heartbeat',headers=client_headers(user['session_token']),json={}).json()
        assert heartbeat()['features_blocked'] is True
        # Recipient closing/reopening the script must not clear the owner's block.
        c.post('/api/v1/sessions/end', headers=client_headers(user['session_token']))
        user = start_session(c, 98001, 'feature-user')
        assert user['features_blocked'] is True
        assert heartbeat()['features_blocked'] is True
        path='/api/v1/owner/remote/features/'+user['session_id']
        body['blocked']=False
        assert c.put(path,headers=h,json=body).status_code==200
        assert heartbeat()['features_blocked'] is False
        with main.connection() as db:
            db.execute("UPDATE sessions SET job_id='another-server' WHERE id=?",(user['session_id'],))
        body['blocked']=True
        assert c.put(path,headers=h,json=body).status_code==409
        assert heartbeat()['features_blocked'] is False
        with main.connection() as db:
            db.execute("UPDATE sessions SET job_id='same-server' WHERE id=?",(user['session_id'],))
        assert c.put(path,headers=h,json=body).status_code==200
        c.post('/api/v1/sessions/end',headers=client_headers(owner['session_token']))
        assert heartbeat()['features_blocked'] is False
