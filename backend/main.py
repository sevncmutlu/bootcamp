from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
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
from debt_model import debt_predictor

# Configure structured application logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("maki_main")

# Application-level constants read from environment at startup
GEMINI_API_KEY: str = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODEL: str = "gemini-3.1-flash-lite"

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load and index live economic data on app startup
    logger.info("Initializing RAG vector store on startup...")
    await rag_service.initialize()
    
    # Train the LightGBM model for debt payoff prediction
    logger.info("Initializing LightGBM debt model...")
    debt_predictor.train_model()
    yield

app = FastAPI(
    title="Maki Finance Coach API",
    description="Backend API for receipt parsing, AI coaching, forecasting, and debt simulation.",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request/Response Models
class ChatMessage(BaseModel):
    message: str
    history: Optional[List[dict]] = []
    primary_goal: Optional[str] = None
    locale: Optional[str] = None

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
    # Determine user language
    is_turkish = (payload.locale == "tr") if payload.locale else any(word in payload.message.lower() for word in ["merhaba", "selam", "nasıl", "para", "borç", "bütçe", "harcama", "haftalık", "yönetimi", "rehberi", "sırları"])

    # Graceful mock fallback if API key is not configured locally
    if not GEMINI_API_KEY:
        if "weekly budget check-in" in payload.message.lower() or "haftalık analiz" in payload.message.lower():
            reply = "Welcome to your Weekly Budget Check-in! Let's start with Step 1: How did you feel about your spending this week? Did you stick to your goals?" if not is_turkish else "Haftalık Bütçe Değerlendirmenize Hoş Geldiniz! 1. Adım ile başlayalım: Bu haftaki harcamalarınız hakkında ne hissediyorsunuz? Hedeflerinize sadık kalabildiniz mi?"
        elif "debt optimization" in payload.message.lower() or "borç yönetimi" in payload.message.lower():
            reply = "Let's optimize your debts! Would you prefer the Avalanche strategy (paying highest interest rate first to save money) or the Snowball strategy (paying smallest balances first for quick motivation)?" if not is_turkish else "Borçlarınızı optimize edelim! Çığ stratejisini mi (en yüksek faiz oranına sahip borcu önce ödemek) yoksa Kar Topu stratejisini mi (küçük bakiyeleri önce ödeyerek hızlı motivasyon kazanmak) tercih edersiniz?"
        elif "inflation impact" in payload.message.lower() or "enflasyon rehberi" in payload.message.lower():
            reply = "Turkey's current annual inflation rate is 38.21%. Which spending category (e.g. Market, Rent, Restaurants) do you feel is rising fastest in your personal budget?" if not is_turkish else "Türkiye'nin güncel yıllık enflasyon oranı %38.21'dir. Kişisel bütçenizde hangi harcama kategorisinin (örneğin Market, Kira, Restoran) en hızlı yükseldiğini hissediyorsunuz?"
        elif "savings hack" in payload.message.lower() or "tasarruf sırları" in payload.message.lower():
            reply = "Here are 3 quick savings hacks:\n1. Audit subscription trials.\n2. Prep meals at home.\n3. Wait 48 hours before impulse buys." if not is_turkish else "İşte 3 hızlı tasarruf ipucu:\n1. Aboneliklerinizi gözden geçirin.\n2. Evde yemek hazırlayın.\n3. Ani alışverişlerden önce 48 saat bekleyin."
        else:
            reply = DEMO_CHAT_REPLY_TR if is_turkish else DEMO_CHAT_REPLY_EN
            
        # Customize mock reply based on goal
        if payload.primary_goal == "learn_invest":
            reply += " (Focus Tip: Since you want to learn to invest, try reading about compound interest and diversification!)" if not is_turkish else " (Odak İpucu: Yatırım yapmayı öğrenmek istediğiniz için, bileşik faiz ve çeşitlendirme konularını okumayı deneyin!)"
        elif payload.primary_goal == "pay_debt":
            reply += " (Focus Tip: Since you want to pay down debt, remember to track highest interest rates first!)" if not is_turkish else " (Odak İpucu: Borçlarınızı ödemek istediğiniz için, öncelikle en yüksek faiz oranlarını takip etmeyi unutmayın!)"
        elif payload.primary_goal == "save_goal":
            reply += " (Focus Tip: Since you want to save for a major goal, check out our savings challenge modules!)" if not is_turkish else " (Odak İpucu: Büyük bir hedef için tasarruf etmek istediğiniz için, tasarruf meydan okuma modüllerimizi inceleyin!)"
        elif payload.primary_goal == "track_spending":
            reply += " (Focus Tip: Since you want to track daily spending, make sure to categorize your expenses regularly!)" if not is_turkish else " (Odak İpucu: Günlük harcamalarınızı takip etmek istediğiniz için, harcamalarınızı düzenli olarak kategorize etmeyi unutmayın!)"

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
            "You are Maki, a highly supportive personal finance coach. "
            f"You MUST write all your messages in {'Turkish' if is_turkish else 'English'}. "
            "Your goal is to help users build healthy money habits, track daily expenses, reduce debt, "
            "and make smart saving choices. Be warm, empathetic, and encouraging. Never be judgmental. "
            "Keep your answers concise, practical, and action-oriented. Try to format numbers nicely."
        )

        if payload.primary_goal:
            goal_guidance = ""
            if payload.primary_goal == "track_spending":
                goal_guidance = "\n\nThe user's primary goal is tracking daily spending. Proactively focus your coaching on expense categorization, budget limits, and identifying wasteful habits."
            elif payload.primary_goal == "save_goal":
                goal_guidance = "\n\nThe user's primary goal is saving for a major goal. Proactively focus your coaching on savings challenges, compound interest benefits, and building an emergency fund."
            elif payload.primary_goal == "pay_debt":
                goal_guidance = "\n\nThe user's primary goal is paying down existing debt. Proactively focus your coaching on debt reduction strategies, reducing interest expenses, and maintaining a debt repayment plan."
            elif payload.primary_goal == "learn_invest":
                goal_guidance = "\n\nThe user's primary goal is learning how to invest. Proactively focus your coaching on investment basics, asset allocation, diversification, and long-term wealth building."
            
            if goal_guidance:
                system_instruction += goal_guidance

        # Structured Session Prompts (US-18)
        session_prefix = ""
        user_message_lower = payload.message.lower()
        if "weekly budget check-in" in user_message_lower or "haftalık analiz" in user_message_lower:
            session_prefix = (
                "\n\n[STRUCTURED SESSION: Weekly Budget Check-in]\n"
                "Guide the user through a structured 3-step check-in:\n"
                "1. Ask them how their spending felt this week (warmly).\n"
                "2. Help them identify one unnecessary expense they can cut.\n"
                "3. Challenge them to set a small savings goal for next week.\n"
                "Respond by starting Step 1 in a friendly manner. Keep your response very brief."
            )
        elif "debt optimization" in user_message_lower or "borç yönetimi" in user_message_lower:
            session_prefix = (
                "\n\n[STRUCTURED SESSION: Debt Optimization]\n"
                "Help the user understand debt payoff strategy. Explain Snowball and Avalanche options simply. "
                "Ask them if they want to prioritize highest interest rates or smallest balances to get started. Keep it brief."
            )
        elif "inflation impact" in user_message_lower or "enflasyon rehberi" in user_message_lower:
            session_prefix = (
                "\n\n[STRUCTURED SESSION: Inflation Impact]\n"
                "Discuss Turkey's current inflation environment (headline 38.21% in June 2026). "
                "Ask the user which category (e.g. Market, Rent, Restaurants) they feel is rising fastest for them. Keep it brief."
            )
        elif "savings hack" in user_message_lower or "tasarruf sırları" in user_message_lower:
            session_prefix = (
                "\n\n[STRUCTURED SESSION: Savings Hack]\n"
                "Provide the user with exactly three highly actionable savings hacks they can try today. Keep it short and bulleted."
            )

        if session_prefix:
            system_instruction += session_prefix

        if rag_context:
            system_instruction += (
                f"\n\nGround your advice using the following official macroeconomic facts if relevant to the query:\n{rag_context}"
            )
        
        # Create chat session with system instruction and history
        chat = client.chats.create(
            model=GEMINI_MODEL,
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
    # Validate file type (handle web octet-stream fallbacks by inspecting extension)
    content_type = file.content_type or ""
    filename = file.filename or ""
    is_image_mime = content_type.startswith("image/")
    is_image_ext = filename.lower().endswith(('.png', '.jpg', '.jpeg', '.webp', '.heic'))
    
    if not is_image_mime and not is_image_ext:
        raise HTTPException(
            status_code=400,
            detail=f"Uploaded file must be an image. Got content_type: {content_type}, filename: {filename}"
        )
    
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
            model=GEMINI_MODEL,
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
    repayment_success_probability: float

@app.post("/api/debt-simulator", response_model=DebtSimulationResponse)
async def simulate_debt_payoff(payload: DebtSimulationRequest):
    # Graceful exit if no debts are submitted
    if not payload.debts:
        return DebtSimulationResponse(months_to_debt_free=0, total_interest_paid=0.0, payoff_schedule=[], repayment_success_probability=1.0)

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

        # Calculate LightGBM success probability
        total_balance = sum(d.balance for d in payload.debts)
        avg_interest_rate = (
            sum(d.interest_rate * d.balance for d in payload.debts) / total_balance 
            if total_balance > 0 else 0.0
        )
        total_min_payment = sum(d.min_payment for d in payload.debts)

        repayment_success_probability = debt_predictor.predict_success_probability(
            total_balance=total_balance,
            avg_interest_rate=avg_interest_rate,
            monthly_budget=payload.monthly_budget,
            total_min_payment=total_min_payment,
            strategy=payload.strategy
        )

        return DebtSimulationResponse(
            months_to_debt_free=months,
            total_interest_paid=round(total_interest_paid, 2),
            payoff_schedule=schedule,
            repayment_success_probability=round(repayment_success_probability, 4)
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
