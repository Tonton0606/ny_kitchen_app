import hashlib
import json

import pytest
from fastapi.testclient import TestClient

from backend.app import MAX_BODY, create_app


def header(role):
    return {"Authorization": "Bearer " + role * 32}


@pytest.fixture
def configured(tmp_path):
    credentials = tmp_path / "credentials.json"
    credentials.write_text(json.dumps([
        {"id": role, "role": "admin" if role == "admin" else "device",
         "token_sha256": hashlib.sha256((role * 32).encode()).hexdigest()}
        for role in ("device", "second", "admin")]))
    return tmp_path / "test.db", credentials


@pytest.fixture
def client(configured):
    with TestClient(create_app(*configured)) as value:
        yield value


@pytest.fixture
def sale():
    return {"local_id": 1, "receipt_number": "DEMO-001", "total_cents": 10000,
            "discount_cents": 0, "payment_method": "cash", "status": "Served",
            "created_at": "2026-10-22T10:00:00+08:00",
            "items": [{"food_name": "Demo meal", "quantity": 2,
                       "unit_price_cents": 5000, "subtotal_cents": 10000}]}


def test_health_and_missing_configuration(client, monkeypatch):
    assert client.get('/health').json()['status'] == 'ok'
    monkeypatch.delenv('NYK_CREDENTIALS_FILE', raising=False)
    with pytest.raises(ValueError):
        create_app()


def test_authentication_and_roles(client, sale):
    for headers in ({}, header('wrong')):
        assert client.post('/v1/sales/sync', json={'sales': [sale]}, headers=headers).status_code == 401
    assert client.get('/v1/admin/sales', headers=header('device')).status_code == 403
    assert client.get('/v1/admin/audit', headers=header('device')).status_code == 403
    assert client.post('/v1/sales/sync', json={'sales': [sale]}, headers=header('admin')).status_code == 403
    assert client.get('/v1/admin/sales', headers=header('admin')).json() == {'sales': []}
    events = client.get('/v1/admin/audit', headers=header('admin')).json()['events']
    assert any(e['action'] == 'role_check' and e['outcome'] == 'denied' for e in events)
    assert all('token' not in str(e) for e in events)


def test_retries_revisions_and_device_isolation(client, sale):
    send = lambda: client.post('/v1/sales/sync', json={'sales': [sale]}, headers=header('device'))
    assert send().json() == {'accepted': 1, 'new_revisions': 1}
    assert send().json()['new_revisions'] == 0
    sale['status'] = 'Refunded'
    assert send().json()['new_revisions'] == 1
    sale['status'] = 'Served'
    assert send().json()['new_revisions'] == 0  # Old replay cannot revert latest.
    assert client.post('/v1/sales/sync', json={'sales': [sale]}, headers=header('second')).status_code == 200
    rows = client.get('/v1/admin/sales', headers=header('admin')).json()['sales']
    assert len(rows) == 2
    assert next(r for r in rows if r['device_id'] == 'device')['sale']['status'] == 'Refunded'
    with client.app.state.store.connection() as db:
        assert db.execute('SELECT count(*) FROM revisions').fetchone()[0] == 3


@pytest.mark.parametrize('field', ['password_hash', 'face_encoding', 'device_id', 'role'])
def test_extra_fields_rejected_without_echo(client, sale, field):
    sale[field] = 'DO_NOT_ECHO'
    response = client.post('/v1/sales/sync', json={'sales': [sale]}, headers=header('device'))
    assert response.status_code == 422
    assert 'DO_NOT_ECHO' not in response.text


def test_invalid_batch_is_atomic(client, sale):
    invalid = dict(sale, local_id=2, total_cents=99)
    assert client.post('/v1/sales/sync', json={'sales': [sale, invalid]}, headers=header('device')).status_code == 422
    assert client.get('/v1/admin/sales', headers=header('admin')).json()['sales'] == []


def test_body_limit_and_schema_protection(client):
    assert client.post('/v1/sales/sync', content=b'x' * (MAX_BODY + 1), headers=header('device')).status_code == 413
    assert client.get('/openapi.json').status_code == 401
    assert client.get('/openapi.json', headers=header('device')).status_code == 403
    assert client.get('/openapi.json', headers=header('admin')).status_code == 200
    assert client.get('/docs').status_code == 404


def test_rate_limit(configured):
    with TestClient(create_app(*configured, requests_per_minute=2)) as client:
        assert client.get('/health').status_code == 200
        assert client.get('/health').status_code == 200
        assert client.get('/health').status_code == 429


def test_persistence_and_no_mutation_endpoint(configured, sale):
    with TestClient(create_app(*configured)) as client:
        assert client.post('/v1/sales/sync', json={'sales': [sale]}, headers=header('device')).status_code == 200
    with TestClient(create_app(*configured)) as client:
        assert len(client.get('/v1/admin/sales', headers=header('admin')).json()['sales']) == 1
        assert client.delete('/v1/admin/sales', headers=header('admin')).status_code == 405
        response = client.get('/v1/admin/sales?limit=1000', headers=header('admin'))
        assert response.status_code == 422
        assert response.headers['cache-control'] == 'no-store'
