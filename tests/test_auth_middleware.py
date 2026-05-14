import pytest
import datetime
from fastapi import FastAPI, Depends, Request
from fastapi.testclient import TestClient
from jose import jwt

from project.utils.decorators import require_auth, require_role, SECRET_KEY, ALGORITHM, BLACKLIST
from project.utils.enums import Role

app = FastAPI()

@app.get("/protected")
def protected_route(user=Depends(require_auth)):
    return {"message": "success"}

@app.get("/admin_only")
def admin_only_route(user=Depends(require_role([Role.ADMIN]))):
    return {"message": "admin success"}

@app.get("/superadmin_only")
def superadmin_only_route(user=Depends(require_role([Role.SUPERADMIN]))):
    return {"message": "superadmin success"}

client = TestClient(app)

def generate_token(user_id, role, exp_offset=3600):
    payload = {
        "user_id": user_id,
        "role": role,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(seconds=exp_offset)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def test_require_auth_missing_header():
    res = client.get("/protected")
    assert res.status_code == 401
    assert "Missing or invalid authorization header" in res.json()["detail"]

def test_require_auth_invalid_token():
    res = client.get("/protected", headers={"Authorization": "Bearer invalid-token"})
    assert res.status_code == 401
    assert "Invalid token" in res.json()["detail"]

def test_require_auth_expired_token():
    token = generate_token(1, Role.USER.value, exp_offset=-3600)
    res = client.get("/protected", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 401
    assert "Token has expired" in res.json()["detail"]

def test_require_auth_blacklisted_token():
    token = generate_token(1, Role.USER.value)
    BLACKLIST.add(token)
    res = client.get("/protected", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 401
    assert "Token has been revoked" in res.json()["detail"]
    BLACKLIST.remove(token)

def test_require_auth_success():
    token = generate_token(1, Role.USER.value)
    res = client.get("/protected", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert res.json()["message"] == "success"

def test_require_role_user_in_admin_route():
    token = generate_token(1, Role.USER.value)
    res = client.get("/admin_only", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 403
    assert res.json()["detail"] == "Insufficient permissions"

def test_require_role_admin_in_superadmin_route():
    token = generate_token(1, Role.ADMIN.value)
    res = client.get("/superadmin_only", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 403
    assert res.json()["detail"] == "Insufficient permissions"

def test_require_role_superadmin_in_admin_route():
    token = generate_token(1, Role.SUPERADMIN.value)
    res = client.get("/admin_only", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    assert res.json()["message"] == "admin success"
