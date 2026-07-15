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

class TransactionItem(BaseModel):
    date: str # YYYY-MM-DD
    amount: float

class ForecastRequest(BaseModel):
    transactions: List[TransactionItem]

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
    # Graceful mock fallback if API key is not configured locally
    if not GEMINI_API_KEY:
        is_turkish = any(word in payload.message.lower() for word in ["merhaba", "selam", "nasıl", "para", "borç", "bütçe", "harcama"])
        if is_turkish:
            reply = (
                "Merhaba! Ben bütçe koçunuz Maki. API anahtarınız henüz ayarlanmadığı için "
                "şu an demo modundayım. Ama bütçe yapmanıza ve borçlarınızı kapatmanıza her zaman yardımcı olabilirim!"
            )
        else:
            reply = (
                "Hello! I am Maki, your budget coach. Since the Gemini API key is not configured yet, "
                "I am running in demo mode. But I am always here to help you build budget sheets and manage expenses!"
            )
        return {"reply": reply, "sources": []}

    try:
        # Initialize GenAI client
        client = genai.Client(api_key=GEMINI_API_KEY)
        
        # Map conversation history
        contents = []
        for h in payload.history:
            role = h.get("role")
            text = h.get("text")
            if role and text:
                contents.append(types.Content(
                    role="user" if role == "user" else "model",
                    parts=[types.Part.from_text(text=text)]
                ))
        
        system_instruction = (
            "You are Maki, a highly supportive, bilingual (English and Turkish) personal finance coach. "
            "Your goal is to help users build healthy money habits, track daily expenses, reduce debt, "
            "and make smart saving choices. Be warm, empathetic, and encouraging. Never be judgmental. "
            "If the user asks questions in Turkish, reply in Turkish. If they ask in English, reply in English. "
            "Keep your answers concise, practical, and action-oriented. Try to format numbers nicely."
        )
        
        # Create chat session with system instruction and history
        chat = client.chats.create(
            model="gemini-2.0-flash",
            config=types.GenerateContentConfig(
                system_instruction=system_instruction
            ),
            history=contents
        )
        
        # Send user message
        response = chat.send_message(payload.message)
        
        return {
            "reply": response.text,
            "sources": []
        }
        
    except Exception as e:
        print(f"Error in Maki AI Coach: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to communicate with AI Coach: {str(e)}")

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


class ForecastDay(BaseModel):
    date: str
    predicted_amount: float

class ForecastResponse(BaseModel):
    forecast: List[ForecastDay]

@app.post("/api/forecast", response_model=ForecastResponse)
async def forecast_spending(payload: ForecastRequest):
    # Graceful exit if no transactions are provided
    if not payload.transactions:
        return ForecastResponse(forecast=[])

    try:
        import pandas as pd
        from prophet import Prophet
        
        # 1. Load transactions into Pandas
        data = [{"ds": tx.date, "y": tx.amount} for tx in payload.transactions]
        df = pd.DataFrame(data)
        
        # Ensure correct formats
        df['ds'] = pd.to_datetime(df['ds'])
        df['y'] = df['y'].astype(float)
        
        # Group duplicates (e.g. multiple expenses on same day)
        df = df.groupby('ds', as_index=False).sum()

        # Fallback: Prophet requires a minimum sample size to predict trends.
        # If less than 3 unique transaction days exist, we use a daily average.
        if len(df) < 3:
            avg_daily = df['y'].mean() if not df.empty else 0.0
            last_date = df['ds'].max() if not df.empty else pd.Timestamp.now()
            forecast_list = []
            for i in range(1, 8):
                future_day = last_date + pd.Timedelta(days=i)
                forecast_list.append(ForecastDay(
                    date=future_day.strftime('%Y-%m-%d'),
                    predicted_amount=max(0.0, float(avg_daily))
                ))
            return ForecastResponse(forecast=forecast_list)

        # 2. Fit the Prophet model (silencing logs for cleaner console output)
        import logging
        logging.getLogger('prophet').setLevel(logging.ERROR)
        
        m = Prophet(yearly_seasonality=False, weekly_seasonality=True, daily_seasonality=False)
        m.fit(df)

        # 3. Predict next 7 days
        future = m.make_future_dataframe(periods=7, include_history=False)
        forecast = m.predict(future)
        
        # 4. Map outputs
        forecast_list = []
        for _, row in forecast.iterrows():
            date_str = row['ds'].strftime('%Y-%m-%d')
            # Clamp predictions to >= 0.0
            predicted_val = max(0.0, float(row['yhat']))
            forecast_list.append(ForecastDay(
                date=date_str,
                predicted_amount=predicted_val
            ))
            
        return ForecastResponse(forecast=forecast_list)

    except Exception as e:
        print(f"Prophet fitting failed, falling back to moving average: {e}")
        try:
            # Safe linear/average fallback on exception
            import pandas as pd
            df = pd.DataFrame([{"ds": tx.date, "y": tx.amount} for tx in payload.transactions])
            avg_daily = df['y'].mean() if not df.empty else 0.0
            forecast_list = []
            for i in range(1, 8):
                future_day = pd.Timestamp.now() + pd.Timedelta(days=i)
                forecast_list.append(ForecastDay(
                    date=future_day.strftime('%Y-%m-%d'),
                    predicted_amount=max(0.0, float(avg_daily))
                ))
            return ForecastResponse(forecast=forecast_list)
        except Exception as inner_e:
            raise HTTPException(status_code=500, detail=f"Failed to generate forecast: {str(inner_e)}")

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
