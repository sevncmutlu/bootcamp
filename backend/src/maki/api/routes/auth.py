import hashlib
import json
from datetime import UTC, datetime, timedelta
from pathlib import Path

import jwt
from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, EmailStr, Field

router = APIRouter(prefix="/v1/auth", tags=["auth"])

_JWT_SECRET = "maki_finance_auth_secret_key_2026"
_JWT_ALGORITHM = "HS256"

_STORAGE_FILE = Path(__file__).parent.parent.parent / "users_store.json"
_USERS_DB: dict[str, dict] = {}
_EMAIL_TO_USER_ID: dict[str, str] = {}


def _load_users_from_disk():
    global _USERS_DB, _EMAIL_TO_USER_ID
    if _STORAGE_FILE.exists():
        try:
            with open(_STORAGE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                _USERS_DB = data.get("users", {})
                _EMAIL_TO_USER_ID = data.get("email_map", {})
        except Exception:
            _USERS_DB = {}
            _EMAIL_TO_USER_ID = {}


def _save_users_to_disk():
    try:
        with open(_STORAGE_FILE, "w", encoding="utf-8") as f:
            json.dump({
                "users": _USERS_DB,
                "email_map": _EMAIL_TO_USER_ID,
            }, f, indent=2)
    except Exception:
        pass


_load_users_from_disk()


def _hash_password(password: str) -> str:
    salt = b"maki_finance_secure_salt_2026"
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 100000)
    return key.hex()


class RegisterRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=6, max_length=128)
    display_name: str = Field(min_length=2, max_length=128)


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=1, max_length=128)


class ResetPasswordRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    new_password: str = Field(min_length=6, max_length=128)


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(min_length=1, max_length=128)
    new_password: str = Field(min_length=6, max_length=128)


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
    _load_users_from_disk()
    email_clean = req.email.strip().lower()
    if email_clean in _EMAIL_TO_USER_ID:
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
    _USERS_DB[user_id] = user_record
    _EMAIL_TO_USER_ID[email_clean] = user_id
    _save_users_to_disk()

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
    _load_users_from_disk()
    email_clean = req.email.strip().lower()
    user_id = _EMAIL_TO_USER_ID.get(email_clean)
    user = _USERS_DB.get(user_id) if user_id else None

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
    user_id = payload.get("sub")
    email = payload.get("email", "").lower()
    user = _USERS_DB.get(user_id)

    if not user:
        user_id = user_id or f"usr_{hashlib.md5(email.encode()).hexdigest()[:12]}"
        user = {
            "user_id": user_id,
            "email": email,
            "password_hash": "",
            "display_name": email.split("@")[0].capitalize() if "@" in email else "User",
            "avatar_url": None,
            "financial_goal": "track_spending",
            "created_at": datetime.now(UTC).isoformat(),
        }
        _USERS_DB[user_id] = user
        _EMAIL_TO_USER_ID[email] = user_id
        _save_users_to_disk()

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
    user_id = payload.get("sub")
    email = payload.get("email", "").lower()
    user = _USERS_DB.get(user_id)

    if not user:
        user_id = user_id or f"usr_{hashlib.md5(email.encode()).hexdigest()[:12]}"
        user = {
            "user_id": user_id,
            "email": email,
            "password_hash": "",
            "display_name": email.split("@")[0].capitalize() if "@" in email else "User",
            "avatar_url": None,
            "financial_goal": "track_spending",
            "created_at": datetime.now(UTC).isoformat(),
        }
        _USERS_DB[user_id] = user
        _EMAIL_TO_USER_ID[email] = user_id

    if req.display_name is not None:
        user["display_name"] = req.display_name.strip()
    if req.email is not None:
        new_email = req.email.strip().lower()
        if new_email != user["email"]:
            if new_email in _EMAIL_TO_USER_ID and _EMAIL_TO_USER_ID[new_email] != user_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Bu e-posta adresi başka bir hesap tarafından kullanılıyor.",
                )
            _EMAIL_TO_USER_ID.pop(user["email"], None)
            user["email"] = new_email
            _EMAIL_TO_USER_ID[new_email] = user_id
    if req.avatar_url is not None:
        user["avatar_url"] = req.avatar_url
    if req.financial_goal is not None:
        user["financial_goal"] = req.financial_goal

    _save_users_to_disk()

    return UserProfileResponse(
        user_id=user["user_id"],
        email=user["email"],
        display_name=user["display_name"],
        avatar_url=user["avatar_url"],
        financial_goal=user["financial_goal"],
        created_at=user["created_at"],
    )


@router.delete("/account")
async def delete_account(authorization: str = Header(...)):
    payload = _verify_token(authorization)
    user_id = payload.get("sub")
    user = _USERS_DB.pop(user_id, None)

    if user:
        _EMAIL_TO_USER_ID.pop(user["email"], None)
        _save_users_to_disk()

    return {"status": "success", "message": "Hesap başarıyla silindi."}


@router.post("/reset-password")
async def reset_password(req: ResetPasswordRequest):
    email_clean = req.email.strip().lower()
    user_id = _EMAIL_TO_USER_ID.get(email_clean)
    user = _USERS_DB.get(user_id) if user_id else None

    if not user:
        user_id = f"usr_{hashlib.md5(email_clean.encode()).hexdigest()[:12]}"
        user = {
            "user_id": user_id,
            "email": email_clean,
            "password_hash": _hash_password(req.new_password),
            "display_name": email_clean.split("@")[0].capitalize() if "@" in email_clean else "User",
            "avatar_url": None,
            "financial_goal": "track_spending",
            "created_at": datetime.now(UTC).isoformat(),
        }
        _USERS_DB[user_id] = user
        _EMAIL_TO_USER_ID[email_clean] = user_id
    else:
        user["password_hash"] = _hash_password(req.new_password)

    _save_users_to_disk()

    return {"status": "success", "message": "Şifre başarıyla güncellendi."}


@router.put("/change-password")
async def change_password(req: ChangePasswordRequest, authorization: str = Header(...)):
    payload = _verify_token(authorization)
    user_id = payload.get("sub")
    user = _USERS_DB.get(user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Kullanıcı bulunamadı.",
        )

    if user.get("password_hash") != _hash_password(req.old_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mevcut şifre yanlış.",
        )

    user["password_hash"] = _hash_password(req.new_password)
    _save_users_to_disk()
    return {"status": "success", "message": "Şifreniz başarıyla değiştirildi."}


@router.get("/users")
async def list_users():
    users_summary = [
        {
            "user_id": u["user_id"],
            "email": u["email"],
            "display_name": u["display_name"],
            "created_at": u.get("created_at"),
        }
        for u in _USERS_DB.values()
    ]
    return {
        "total_users": len(_USERS_DB),
        "users": users_summary,
    }
