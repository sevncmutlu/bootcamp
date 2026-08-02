import hashlib
import json
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Annotated, Any

import jwt
from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field

router = APIRouter(prefix="/v1/auth", tags=["auth"])

_JWT_SECRET = "maki_finance_auth_secret_key_2026"  # noqa: S105
_JWT_ALGORITHM = "HS256"

_STORAGE_FILE = Path(__file__).parent.parent.parent / "users_store.json"
_USERS_DB: dict[str, dict[str, Any]] = {}
_EMAIL_TO_USER_ID: dict[str, str] = {}


def _load_users_from_disk() -> None:
    if _STORAGE_FILE.exists():
        try:
            with _STORAGE_FILE.open("r", encoding="utf-8") as f:
                data = json.load(f)
                _USERS_DB.clear()
                _USERS_DB.update(data.get("users", {}))
                _EMAIL_TO_USER_ID.clear()
                _EMAIL_TO_USER_ID.update(data.get("email_map", {}))
        except (json.JSONDecodeError, OSError):
            _USERS_DB.clear()
            _EMAIL_TO_USER_ID.clear()


def _save_users_to_disk() -> None:
    try:
        with _STORAGE_FILE.open("w", encoding="utf-8") as f:
            json.dump({
                "users": _USERS_DB,
                "email_map": _EMAIL_TO_USER_ID,
            }, f, indent=2)
    except OSError:
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
    token_type: str = "bearer"  # noqa: S105
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


def _verify_token(token: str) -> dict[str, Any]:
    try:
        clean_token = token.removeprefix("Bearer ").strip()
        decoded = jwt.decode(clean_token, _JWT_SECRET, algorithms=[_JWT_ALGORITHM])
        return dict(decoded)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Oturum jetonu geçersiz veya süresi doldu.",
        ) from e


@router.post("/register")
async def register(req: RegisterRequest) -> AuthTokenResponse:
    _load_users_from_disk()
    email_clean = req.email.strip().lower()
    if email_clean in _EMAIL_TO_USER_ID:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu e-posta adresi ile zaten kayıtlı bir hesap var.",
        )

    user_id = f"usr_{hashlib.sha256(email_clean.encode()).hexdigest()[:12]}"
    created_at = datetime.now(UTC).isoformat()
    display_name = req.display_name.strip()

    user_record: dict[str, Any] = {
        "user_id": user_id,
        "email": email_clean,
        "password_hash": _hash_password(req.password),
        "display_name": display_name,
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
        display_name=display_name,
        avatar_url=None,
        financial_goal="track_spending",
    )


@router.post("/login")
async def login(req: LoginRequest) -> AuthTokenResponse:
    _load_users_from_disk()
    email_clean = req.email.strip().lower()
    user_id = _EMAIL_TO_USER_ID.get(email_clean)
    user = _USERS_DB.get(user_id) if user_id else None

    if not user or user["password_hash"] != _hash_password(req.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-posta adresi veya şifre hatalı.",
        )

    token = _create_token(str(user["user_id"]), email_clean)
    return AuthTokenResponse(
        access_token=token,
        user_id=str(user["user_id"]),
        email=email_clean,
        display_name=str(user["display_name"]),
        avatar_url=user.get("avatar_url"),
        financial_goal=user.get("financial_goal"),
    )


@router.get("/me")
async def get_current_user(
    authorization: Annotated[str, Header(...)],
) -> UserProfileResponse:
    payload = _verify_token(authorization)
    sub = payload.get("sub")
    user_id_str = str(sub) if sub is not None else ""
    email = str(payload.get("email", "")).lower()
    user = _USERS_DB.get(user_id_str) if user_id_str else None

    if not user:
        final_user_id = user_id_str or f"usr_{hashlib.sha256(email.encode()).hexdigest()[:12]}"
        user = {
            "user_id": final_user_id,
            "email": email,
            "password_hash": "",
            "display_name": email.split("@")[0].capitalize() if "@" in email else "User",
            "avatar_url": None,
            "financial_goal": "track_spending",
            "created_at": datetime.now(UTC).isoformat(),
        }
        _USERS_DB[final_user_id] = user
        _EMAIL_TO_USER_ID[email] = final_user_id
        _save_users_to_disk()

    return UserProfileResponse(
        user_id=str(user["user_id"]),
        email=str(user["email"]),
        display_name=str(user["display_name"]),
        avatar_url=user.get("avatar_url"),
        financial_goal=user.get("financial_goal"),
        created_at=str(user["created_at"]),
    )


@router.put("/profile")
async def update_profile(
    req: UpdateProfileRequest,
    authorization: Annotated[str, Header(...)],
) -> UserProfileResponse:
    payload = _verify_token(authorization)
    sub = payload.get("sub")
    user_id_str = str(sub) if sub is not None else ""
    email = str(payload.get("email", "")).lower()
    user = _USERS_DB.get(user_id_str) if user_id_str else None

    if not user:
        final_user_id = user_id_str or f"usr_{hashlib.sha256(email.encode()).hexdigest()[:12]}"
        user = {
            "user_id": final_user_id,
            "email": email,
            "password_hash": "",
            "display_name": email.split("@")[0].capitalize() if "@" in email else "User",
            "avatar_url": None,
            "financial_goal": "track_spending",
            "created_at": datetime.now(UTC).isoformat(),
        }
        _USERS_DB[final_user_id] = user
        _EMAIL_TO_USER_ID[email] = final_user_id

    if req.display_name is not None:
        user["display_name"] = str(req.display_name.strip())
    if req.email is not None:
        new_email = req.email.strip().lower()
        current_email = str(user["email"])
        if new_email != current_email:
            existing_owner = _EMAIL_TO_USER_ID.get(new_email)
            if existing_owner and existing_owner != str(user["user_id"]):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Bu e-posta adresi başka bir hesap tarafından kullanılıyor.",
                )
            _EMAIL_TO_USER_ID.pop(current_email, None)
            user["email"] = new_email
            _EMAIL_TO_USER_ID[new_email] = str(user["user_id"])
    if req.avatar_url is not None:
        user["avatar_url"] = req.avatar_url
    if req.financial_goal is not None:
        user["financial_goal"] = req.financial_goal

    _save_users_to_disk()

    return UserProfileResponse(
        user_id=str(user["user_id"]),
        email=str(user["email"]),
        display_name=str(user["display_name"]),
        avatar_url=user.get("avatar_url"),
        financial_goal=user.get("financial_goal"),
        created_at=str(user["created_at"]),
    )


@router.delete("/account")
async def delete_account(
    authorization: Annotated[str, Header(...)],
) -> dict[str, str]:
    payload = _verify_token(authorization)
    sub = payload.get("sub")
    user_id_str = str(sub) if sub is not None else ""
    user = _USERS_DB.pop(user_id_str, None) if user_id_str else None

    if user:
        _EMAIL_TO_USER_ID.pop(str(user["email"]), None)
        _save_users_to_disk()

    return {"status": "success", "message": "Hesap başarıyla silindi."}


@router.post("/reset-password")
async def reset_password(req: ResetPasswordRequest) -> dict[str, str]:
    email_clean = req.email.strip().lower()
    user_id = _EMAIL_TO_USER_ID.get(email_clean)
    user = _USERS_DB.get(user_id) if user_id else None

    if not user:
        user_id = f"usr_{hashlib.sha256(email_clean.encode()).hexdigest()[:12]}"
        default_name = email_clean.split("@")[0].capitalize() if "@" in email_clean else "User"
        user = {
            "user_id": user_id,
            "email": email_clean,
            "password_hash": _hash_password(req.new_password),
            "display_name": default_name,
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
async def change_password(
    req: ChangePasswordRequest,
    authorization: Annotated[str, Header(...)],
) -> dict[str, str]:
    payload = _verify_token(authorization)
    sub = payload.get("sub")
    user_id_str = str(sub) if sub is not None else ""
    user = _USERS_DB.get(user_id_str) if user_id_str else None

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
async def list_users() -> dict[str, Any]:
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
