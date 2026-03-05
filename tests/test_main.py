import pytest
from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_get_products():
    response = client.get("/api/products")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
