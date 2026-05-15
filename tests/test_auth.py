import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.utils.enums import Role

client = TestClient(app)

def test_register_user():
    # Test successful registration
    response = client.post(
        "/api/v1/users/",
        json={
            "name": "Test User",
            "email": "test@example.com",
            "password": "testpassword",
            "role": Role.USER.value
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data

def test_register_duplicate_email():
    # Test registration with existing email
    response = client.post(
        "/api/v1/users/",
        json={
            "name": "Another User",
            "email": "test@example.com",
            "password": "anotherpassword"
        }
    )
    assert response.status_code == 409
    assert response.json()["detail"] == "Email already registered"

def test_login_success():
    # Test successful login
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@example.com",
            "password": "testpassword"
        }
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Logged in successfully"
    assert "access_token" in response.cookies

def test_login_invalid_credentials():
    # Test login with wrong password
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@example.com",
            "password": "wrongpassword"
        }
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"
    assert "access_token" not in response.cookies

def test_logout():
    # 1. Login to get cookie
    login_res = client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@example.com",
            "password": "testpassword"
        }
    )
    assert "access_token" in login_res.cookies
    cookies = login_res.cookies
    
    # 2. Logout
    logout_res = client.post(
        "/api/v1/auth/logout",
        cookies=cookies
    )
    assert logout_res.status_code == 200
    assert logout_res.json()["message"] == "Logged out successfully"
    # El navegador debería recibir una instrucción para borrar la cookie
    # (En TestClient, verificamos que la cookie esté vacía o marcada para borrar)
    assert logout_res.cookies.get("access_token") == "" or logout_res.cookies.get("access_token") is None
    
    # 3. Try to use blacklisted token (sending the old cookie)
    protected_res = client.post(
        "/api/v1/auth/logout",
        cookies=cookies
    )
    assert protected_res.status_code == 401
    assert protected_res.json()["detail"] == "Token has been revoked"
