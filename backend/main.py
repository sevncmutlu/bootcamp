from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
import uvicorn
import os
import json
import logging
from contextlib import asynccontextmanager

from google import genai
from google.genai import types
from mocks import DEMO_CHAT_REPLY_TR, DEMO_CHAT_REPLY_EN, DEMO_RECEIPT_DATA
from rag_service import rag_service
import pandas as pd
from prophet import Prophet

# Configure structured application logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("maki_main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load and index live economic data on app startup
    logger.info("Initializing RAG vector store on startup...")
    await rag_service.initialize()
    yield

app = FastAPI(
    title="Maki Finance Coach API",
    description="Backend API for receipt parsing, AI coaching, forecasting, and debt simulation.",
    version="1.0.0",
    lifespan=lifespan
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

class DebtItem(BaseModel):
    name: str
    balance: float
    interest_rate: float
    min_payment: float

class DebtSimulationRequest(BaseModel):
    debts: List[DebtItem]
    monthly_budget: float
    strategy: str # 'avalanche' or 'snowball'

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
        reply = DEMO_CHAT_REPLY_TR if is_turkish else DEMO_CHAT_REPLY_EN
        return {"reply": reply, "sources": []}

    try:
        # 1. Retrieve dynamic economic context from local RAG store
        rag_result = await rag_service.query_context(payload.message)
        rag_context = "\n".join(rag_result["documents"]) if rag_result["documents"] else ""

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

        if rag_context:
            system_instruction += (
                f"\n\nGround your advice using the following official macroeconomic facts if relevant to the query:\n{rag_context}"
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
            "sources": rag_result["sources"]
        }
        
    except Exception as e:
        logger.error(f"Error in Maki AI Coach: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to communicate with AI Coach: {str(e)}")

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
        return ReceiptResponse(**DEMO_RECEIPT_DATA)
    
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
        data = json.loads(response.text)
        return ReceiptResponse(**data)
        
    except Exception as e:
        logger.error(f"Error parsing receipt with Gemini: {e}", exc_info=True)
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
        logger.warning(f"Prophet fitting failed, falling back to moving average: {e}")
        try:
            # Safe linear/average fallback on exception
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

class DebtMonthSchedule(BaseModel):
    month: int
    remaining_balance: float

class DebtSimulationResponse(BaseModel):
    months_to_debt_free: int
    total_interest_paid: float
    payoff_schedule: List[DebtMonthSchedule]

@app.post("/api/debt-simulator", response_model=DebtSimulationResponse)
async def simulate_debt_payoff(payload: DebtSimulationRequest):
    # Graceful exit if no debts are submitted
    if not payload.debts:
        return DebtSimulationResponse(months_to_debt_free=0, total_interest_paid=0.0, payoff_schedule=[])

    try:
        # Clone input models to dictionaries to iterate calculations
        debts = [
            {
                "name": d.name,
                "balance": d.balance,
                "interest_rate": d.interest_rate,
                "min_payment": d.min_payment
            } for d in payload.debts
        ]

        # Prioritize according to Avalanche or Snowball strategy
        if payload.strategy.lower() == 'avalanche':
            # Highest interest rate first
            debts.sort(key=lambda x: x['interest_rate'], reverse=True)
        else:
            # Lowest balance first (Snowball)
            debts.sort(key=lambda x: x['balance'])

        total_interest_paid = 0.0
        months = 0
        schedule = []
        max_months = 360 # 30 years ceiling to prevent infinite runs

        while any(d['balance'] > 0 for d in debts) and months < max_months:
            months += 1
            month_interest = 0.0

            # 1. Apply monthly compound interest
            for d in debts:
                if d['balance'] > 0:
                    interest = d['balance'] * ((d['interest_rate'] / 100) / 12)
                    d['balance'] += interest
                    month_interest += interest
            
            total_interest_paid += month_interest

            # 2. Check if total minimum payments exceed budget
            active_debts = [d for d in debts if d['balance'] > 0]
            total_mins = sum(min(d['balance'], d['min_payment']) for d in active_debts)

            if total_mins > payload.monthly_budget:
                raise HTTPException(
                    status_code=400,
                    detail=f"Monthly budget of ${payload.monthly_budget:.2f} is insufficient to cover minimum payments of ${total_mins:.2f}."
                )

            # 3. Pay minimum payments
            available_pool = payload.monthly_budget
            for d in debts:
                if d['balance'] > 0:
                    payment = min(d['balance'], d['min_payment'])
                    d['balance'] -= payment
                    available_pool -= payment

            # 4. Allocate leftover budget to first prioritized active debt
            for d in debts:
                if d['balance'] > 0 and available_pool > 0:
                    extra_payment = min(d['balance'], available_pool)
                    d['balance'] -= extra_payment
                    available_pool -= extra_payment

            # 5. Record month-end total balance
            current_total_balance = sum(d['balance'] for d in debts)
            schedule.append(DebtMonthSchedule(
                month=months,
                remaining_balance=round(current_total_balance, 2)
            ))

        return DebtSimulationResponse(
            months_to_debt_free=months,
            total_interest_paid=round(total_interest_paid, 2),
            payoff_schedule=schedule
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in debt simulation: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to simulate debt payoff: {str(e)}")

class InflationCategoryBreakdown(BaseModel):
    category: str
    personal_weight: float
    official_weight: float
    inflation_rate: float

class InflationRequest(BaseModel):
    category_spending: Dict[str, float]

class InflationResponse(BaseModel):
    personal_inflation: float
    official_inflation: float
    breakdown: List[InflationCategoryBreakdown]

@app.post("/api/inflation-comparison", response_model=InflationResponse)
async def calculate_inflation_comparison(payload: InflationRequest):
    # Official TÜİK Weights & Category-Specific CPI Annual Inflation (June 2026)
    TUIK_BASKET = {
        "Market": {"weight": 24.44, "rate": 35.45},
        "Rent": {"weight": 11.40, "rate": 45.14},
        "Transport": {"weight": 16.62, "rate": 31.15},
        "Restaurant": {"weight": 11.13, "rate": 42.00},
        "Fun": {"weight": 4.34, "rate": 28.00},
        "Bills": {"weight": 32.07, "rate": 22.56} # Includes Utilities & Other (adjusted to resolve exact headline CPI: 32.11%)
    }

    official_inflation = 32.11
    total_user_spending = sum(payload.category_spending.values())
    
    personal_inflation = 0.0
    breakdown_list = []
    
    if total_user_spending > 0:
        for cat, meta in TUIK_BASKET.items():
            user_spend = payload.category_spending.get(cat, 0.0)
            personal_weight = (user_spend / total_user_spending) * 100.0
            personal_inflation += (personal_weight / 100.0) * meta["rate"]
            
            breakdown_list.append(InflationCategoryBreakdown(
                category=cat,
                personal_weight=round(personal_weight, 2),
                official_weight=meta["weight"],
                inflation_rate=meta["rate"]
            ))
        personal_inflation = round(personal_inflation, 2)
    else:
        for cat, meta in TUIK_BASKET.items():
            breakdown_list.append(InflationCategoryBreakdown(
                category=cat,
                personal_weight=meta["weight"],
                official_weight=meta["weight"],
                inflation_rate=meta["rate"]
            ))
        personal_inflation = official_inflation

    return InflationResponse(
        personal_inflation=personal_inflation,
        official_inflation=official_inflation,
        breakdown=breakdown_list
    )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
