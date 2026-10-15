import math
from pydantic import ValidationError
from fastapi.testclient import TestClient
from tests.test_api import main, start_session, client_headers


def legacy_parameters():
    return dict(VERTICAL_DISTANCE=.1, LINEAR_SPEED=1000, ANGULAR_SPEED=1000,
                FLINGER_SPEED=1000, P=1, RECOVERY_DISTANCE=1, NEAR_DISTANCE=1,
                CONTACT_TIME=.1, FRONT_FLIP_SPEED=1, DISPLACEMENT_DISTANCE=1000)


def test_new_custom_options_and_legacy_defaults():
    profile=main.CustomFlingProfile(parameters=legacy_parameters())
    assert profile.parameters['SPIN_ENABLED']==1
    assert profile.parameters['LATERAL_ENABLED']==1
    assert profile.parameters['SHORT_ROUTE']==0
    assert profile.parameters['TRAVEL_TIME']==0
    for name,value in [('TRAVEL_TIME',math.nan),('SPIN_ENABLED',.5),('APPROACH_ANGLE',91)]:
        try:
            main.CustomFlingProfile(parameters=legacy_parameters() | {name:value})
        except ValidationError:
            pass
        else:
            raise AssertionError('Invalid parameter accepted: '+name)


def test_saved_custom_route_roundtrip():
    parameters=legacy_parameters() | dict(SHORT_ROUTE=1, APPROACH_ANGLE=90,
        VERTICAL_DISTANCE=0, TRAVEL_TIME=.5, HOME_INTERVAL=.1,
        SPIN_ENABLED=0, LATERAL_ENABLED=0)
    with TestClient(main.app) as client:
        session=start_session(client,95001,'custom-settings')
        response=client.put('/api/v1/custom-fling/profile',headers=client_headers(session['session_token']),json={'parameters':parameters})
        assert response.status_code==200,response.text
        login=client.post('/api/v1/owner/login',json={'user_id':11747901934,'username':'psycho777oo','key':'owner-test-key'})
        response=client.get('/api/v1/owner/custom-fling/profiles',headers={'Authorization':'Bearer '+login.json()['token']})
        assert response.status_code==200,response.text
        saved=next(p for p in response.json()['profiles'] if p['user_id']==95001)
        assert all(saved['parameters'][key]==value for key,value in parameters.items())
