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

from google import genai
from google.genai import types
import os

# Load API Key from environment
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

class ReceiptItem(BaseModel):
    name: str
    price: float
    quantity: int

class ReceiptResponse(BaseModel):
    store_name: str
    date: str # YYYY-MM-DD
    items: List[ReceiptItem]
    total: float
    category: str

@app.post("/api/ocr", response_model=ReceiptResponse)
async def parse_receipt(file: UploadFile = File(...)):
    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")
    
    contents = await file.read()
    
    # Graceful fallback if API key is not configured locally
    if not GEMINI_API_KEY:
        return ReceiptResponse(
            store_name="Demo Market Inc. (No API Key)",
            date="2026-07-15",
            items=[
                ReceiptItem(name="Default Grocery Item", price=120.0, quantity=1),
                ReceiptItem(name="Bilingual Book", price=80.0, quantity=1)
            ],
            total=200.0,
            category="Market"
        )
    
    try:
        # Initialize Google GenAI client
        client = genai.Client(api_key=GEMINI_API_KEY)
        
        # Prepare multimodal payload
        image_part = types.Part.from_bytes(
            data=contents,
            mime_type=file.content_type
        )
        
        prompt = (
            "Analyze this receipt image. Extract the store name, date of purchase "
            "(in YYYY-MM-DD format), list of individual items with price and quantity, "
            "the total sum paid, and classify the category of the purchase into one of the "
            "following categories: Market, Restaurant, Rent, Bills, Transport, Fun."
        )
        
        # Call Gemini multimodal model
        response = client.models.generate_content(
            model='gemini-2.0-flash',
            contents=[prompt, image_part],
            config={
                'response_mime_type': 'application/json',
                'response_schema': ReceiptResponse,
            }
        )
        
        # Return parsed JSON directly
        if response.parsed:
            return response.parsed
            
        # Fallback raw parsing if parsed isn't populated
        import json
        data = json.loads(response.text)
        return ReceiptResponse(**data)
        
    except Exception as e:
        print(f"Error parsing receipt with Gemini: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to parse receipt: {str(e)}")

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
