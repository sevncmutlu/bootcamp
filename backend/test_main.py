from fastapi.testclient import TestClient
from main import app
import pytest

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_chat_fallback():
    payload = {
        "message": "Hello coach, how can I save money?",
        "history": []
    }
    response = client.post("/api/chat", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "reply" in data
    assert "sources" in data

def test_ocr_fallback():
    # Pass a mockup image with the correct image mime type
    files = {"file": ("test_receipt.png", b"fake_bytes", "image/png")}
    response = client.post("/api/ocr", files=files)
    assert response.status_code == 200
    data = response.json()
    assert "store_name" in data
    assert "total" in data
    assert "category" in data
    assert len(data["items"]) > 0

def test_forecast_calculation():
    payload = {
        "transactions": [
            {"date": "2026-07-10", "amount": 10.0},
            {"date": "2026-07-11", "amount": 15.0},
            {"date": "2026-07-12", "amount": 20.0}
        ]
    }
    response = client.post("/api/forecast", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "forecast" in data
    assert len(data["forecast"]) == 7

def test_debt_simulator():
    payload = {
        "debts": [
            {"name": "Card A", "balance": 1000.0, "interest_rate": 12.0, "min_payment": 50.0}
        ],
        "monthly_budget": 200.0,
        "strategy": "avalanche"
    }
    response = client.post("/api/debt-simulator", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "months_to_debt_free" in data
    assert "total_interest_paid" in data
    assert len(data["payoff_schedule"]) > 0

def test_inflation_comparison():
    # Test with standard user spending
    payload = {
        "category_spending": {
            "Market": 1000.0,
            "Rent": 2000.0,
            "Bills": 1000.0
        }
    }
    response = client.post("/api/inflation-comparison", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "personal_inflation" in data
    assert "official_inflation" in data
    assert data["official_inflation"] == 32.11
    assert len(data["breakdown"]) == 6
    
    # Test zero spending fallback
    payload_empty = {"category_spending": {}}
    response_empty = client.post("/api/inflation-comparison", json=payload_empty)
    assert response_empty.status_code == 200
    data_empty = response_empty.json()
    assert data_empty["personal_inflation"] == 32.11
