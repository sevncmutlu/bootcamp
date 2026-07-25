import hashlib
from datetime import UTC, datetime, timedelta

import jwt
from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, EmailStr, Field

router = APIRouter(prefix="/v1/auth", tags=["auth"])

# Secret key for JWT signing
_JWT_SECRET = "maki_finance_auth_secret_key_2026"
_JWT_ALGORITHM = "HS256"

# In-memory store for development / demo mode
_USERS_DB: dict[str, dict] = {}


def _hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


class RegisterRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=6, max_length=128)
    display_name: str = Field(min_length=2, max_length=128)


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=6, max_length=128)


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    display_name: str
    avatar_url: str | None = None
    financial_goal: str | None = None


class UserProfileResponse(BaseModel):
    user_id: str
    email: str
    display_name: str
    avatar_url: str | None = None
    financial_goal: str | None = None
    created_at: str


class UpdateProfileRequest(BaseModel):
    display_name: str | None = None
    email: str | None = None
    avatar_url: str | None = None
    financial_goal: str | None = None


def _create_token(user_id: str, email: str) -> str:
    now = datetime.now(UTC)
    payload = {
        "sub": user_id,
        "email": email,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(days=30)).timestamp()),
    }
    return jwt.encode(payload, _JWT_SECRET, algorithm=_JWT_ALGORITHM)


def _verify_token(token: str) -> dict:
    try:
        if token.startswith("Bearer "):
            token = token[7:]
        return jwt.decode(token, _JWT_SECRET, algorithms=[_JWT_ALGORITHM])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Oturum jetonu geçersiz veya süresi doldu.",
        ) from e


@router.post("/register", response_model=AuthTokenResponse)
async def register(req: RegisterRequest):
    email_clean = req.email.strip().lower()
    if email_clean in _USERS_DB:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu e-posta adresi ile zaten kayıtlı bir hesap var.",
        )

    user_id = f"usr_{hashlib.md5(email_clean.encode()).hexdigest()[:12]}"
    created_at = datetime.now(UTC).isoformat()

    user_record = {
        "user_id": user_id,
        "email": email_clean,
        "password_hash": _hash_password(req.password),
        "display_name": req.display_name.strip(),
        "avatar_url": None,
        "financial_goal": "track_spending",
        "created_at": created_at,
    }
    _USERS_DB[email_clean] = user_record

    token = _create_token(user_id, email_clean)
    return AuthTokenResponse(
        access_token=token,
        user_id=user_id,
        email=email_clean,
        display_name=user_record["display_name"],
        avatar_url=user_record["avatar_url"],
        financial_goal=user_record["financial_goal"],
    )


@router.post("/login", response_model=AuthTokenResponse)
async def login(req: LoginRequest):
    email_clean = req.email.strip().lower()
    user = _USERS_DB.get(email_clean)

    if not user or user["password_hash"] != _hash_password(req.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-posta adresi veya şifre hatalı.",
        )

    token = _create_token(user["user_id"], email_clean)
    return AuthTokenResponse(
        access_token=token,
        user_id=user["user_id"],
        email=email_clean,
        display_name=user["display_name"],
        avatar_url=user["avatar_url"],
        financial_goal=user["financial_goal"],
    )


@router.get("/me", response_model=UserProfileResponse)
async def get_current_user(authorization: str = Header(...)):
    payload = _verify_token(authorization)
    email = payload.get("email", "").lower()
    user = _USERS_DB.get(email)

    if not user:
        user = {
            "user_id": payload.get("sub", f"usr_{hashlib.md5(email.encode()).hexdigest()[:12]}"),
            "email": email,
            "password_hash": "",
            "display_name": email.split("@")[0].capitalize() if "@" in email else "User",
            "avatar_url": None,
            "financial_goal": "track_spending",
            "created_at": datetime.now(UTC).isoformat(),
        }
        _USERS_DB[email] = user

    return UserProfileResponse(
        user_id=user["user_id"],
        email=user["email"],
        display_name=user["display_name"],
        avatar_url=user["avatar_url"],
        financial_goal=user["financial_goal"],
        created_at=user["created_at"],
    )


@router.put("/profile", response_model=UserProfileResponse)
async def update_profile(req: UpdateProfileRequest, authorization: str = Header(...)):
    payload = _verify_token(authorization)
    email = payload.get("email", "").lower()
    user = _USERS_DB.get(email)

    if not user:
        user = {
            "user_id": payload.get("sub", f"usr_{hashlib.md5(email.encode()).hexdigest()[:12]}"),
            "email": email,
            "password_hash": "",
            "display_name": email.split("@")[0].capitalize() if "@" in email else "User",
            "avatar_url": None,
            "financial_goal": "track_spending",
            "created_at": datetime.now(UTC).isoformat(),
        }
        _USERS_DB[email] = user

    if req.display_name is not None:
        user["display_name"] = req.display_name.strip()
    if req.email is not None:
        new_email = req.email.strip().lower()
        if new_email != email:
            if new_email in _USERS_DB:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Bu e-posta adresi başka bir hesap tarafından kullanılıyor.",
                )
            _USERS_DB.pop(email, None)
            user["email"] = new_email
            _USERS_DB[new_email] = user
    if req.avatar_url is not None:
        user["avatar_url"] = req.avatar_url
    if req.financial_goal is not None:
        user["financial_goal"] = req.financial_goal

    return UserProfileResponse(
        user_id=user["user_id"],
        email=user["email"],
        display_name=user["display_name"],
        avatar_url=user["avatar_url"],
        financial_goal=user["financial_goal"],
        created_at=user["created_at"],
    )
