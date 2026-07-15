from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

app = FastAPI(
    title="Maki Finance Coach API",
    description="Backend API for receipt parsing, AI coaching, forecasting, and debt simulation.",
    version="1.0.0"
)

# Request/Response Models
class ChatMessage(BaseModel):
    message: str
    history: Optional[List[dict]] = []

class ForecastRequest(BaseModel):
    transactions: List[dict] # Expected: [{"date": "YYYY-MM-DD", "amount": 12.34}]

class DebtSimulationRequest(BaseModel):
    debts: List[dict] # Expected: [{"name": "Card A", "balance": 1000.0, "interest_rate": 18.5, "min_payment": 50.0}]
    monthly_budget: float

@app.get("/")
def read_root():
    return {"message": "Welcome to Maki Finance Coach API"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/api/chat")
async def chat_with_coach(payload: ChatMessage):
    # Placeholder for Gemini Coach RAG conversational logic
    return {
        "reply": f"Maki here! I received your message: '{payload.message}'. Setup the Gemini API key to start real conversations.",
        "sources": []
    }

@app.post("/api/ocr")
async def parse_receipt(file: UploadFile = File(...)):
    # Placeholder for Gemini Multimodal Receipt Vision API
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")
    
    return {
        "store_name": "Sample Store Ltd.",
        "date": "2026-07-15",
        "items": [
            {"name": "Sample Item 1", "price": 100.0, "quantity": 1},
            {"name": "Sample Item 2", "price": 50.0, "quantity": 2}
        ],
        "total": 200.0,
        "category": "Market"
    }

@app.post("/api/forecast")
async def forecast_spending(payload: ForecastRequest):
    # Placeholder for Prophet Forecasting logic
    return {
        "forecast": [
            {"date": "2026-08-01", "predicted_amount": 150.0},
            {"date": "2026-08-02", "predicted_amount": 160.0}
        ]
    }

@app.post("/api/debt-simulator")
async def simulate_debt_payoff(payload: DebtSimulationRequest):
    # Placeholder for LightGBM/Rule-based Debt Payoff planning
    return {
        "months_to_debt_free": 12,
        "total_interest_paid": 450.0,
        "payoff_schedule": [
            {"month": 1, "remaining_balance": 950.0},
            {"month": 2, "remaining_balance": 900.0}
        ]
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
