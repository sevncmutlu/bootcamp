from enum import StrEnum
from pathlib import Path
from typing import Annotated, Literal, Self

from pydantic import (
    AnyHttpUrl,
    BaseModel,
    ConfigDict,
    Field,
    PostgresDsn,
    RedisDsn,
    SecretStr,
    model_validator,
)
from pydantic_settings import BaseSettings, SettingsConfigDict


class Environment(StrEnum):
    DEVELOPMENT = "development"
    TEST = "test"
    PRODUCTION = "production"

    @property
    def is_development(self) -> bool:
        return self is Environment.DEVELOPMENT


class _SettingsModel(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        frozen=True,
        hide_input_in_errors=True,
        validate_default=True,
    )


class DatabaseSettings(_SettingsModel):
    dsn: PostgresDsn | None = None
    pool_size: int = Field(default=10, ge=1, le=50)
    max_overflow: int = Field(default=10, ge=0, le=100)
    pool_timeout_seconds: float = Field(default=5.0, gt=0, le=30)


class RedisSettings(_SettingsModel):
    dsn: RedisDsn | None = None
    socket_timeout_seconds: float = Field(default=2.0, gt=0, le=10)
    max_connections: int = Field(default=20, ge=1, le=200)


class TelemetrySettings(_SettingsModel):
    otlp_endpoint: AnyHttpUrl | None = None
    service_name: str = Field(default="maki-backend", min_length=1, max_length=64)
    trace_sample_ratio: float = Field(default=0.1, ge=0, le=1)


class SecuritySettings(_SettingsModel):
    jwt_public_key: str | None = Field(default=None, min_length=32)
    jwt_key_id: str = Field(default="primary", min_length=1, max_length=64)
    jwt_issuer: str = Field(default="maki", min_length=1, max_length=128)
    jwt_audience: str = Field(default="maki-mobile", min_length=1, max_length=128)
    max_request_age_seconds: int = Field(default=300, ge=30, le=900)


BillingProductId = Annotated[
    str,
    Field(pattern=r"^[a-z0-9_.-]{3,128}$"),
]


class BillingSettings(_SettingsModel):
    google_package_name: str = Field(
        default="com.team120.maki.maki_app",
        min_length=3,
        max_length=256,
    )
    apple_bundle_id: str = Field(
        default="com.team120.maki.makiApp",
        min_length=3,
        max_length=256,
    )
    allowed_products: tuple[BillingProductId, ...] = ("maki_debt_pro",)
    apple_environment: Literal["Production", "Sandbox"] = "Production"
    google_service_account_json: SecretStr | None = None
    apple_trusted_root_pem: SecretStr | None = None
    apple_account_token_secret: SecretStr | None = Field(
        default=None,
        min_length=32,
    )

    @model_validator(mode="after")
    def validate_apple_credentials(self) -> Self:
        configured = (
            self.apple_trusted_root_pem is not None,
            self.apple_account_token_secret is not None,
        )
        if any(configured) and not all(configured):
            msg = "Apple kök sertifikası ve hesap bağı sırrı birlikte ayarlanmalıdır."
            raise ValueError(msg)
        return self


class RetentionSettings(_SettingsModel):
    idempotency_hours: int = Field(default=24, ge=1, le=168)
    job_metadata_days: int = Field(default=7, ge=1, le=30)
    ocr_result_minutes: int = Field(default=10, ge=1, le=60)
    telemetry_days: int = Field(default=14, ge=1, le=30)
    batch_size: int = Field(default=1_000, ge=1, le=10_000)


class OcrSettings(_SettingsModel):
    detection_model_dir: Path | None = None
    recognition_model_dir: Path | None = None

    @model_validator(mode="after")
    def validate_model_directories(self) -> Self:
        configured = (
            self.detection_model_dir is not None,
            self.recognition_model_dir is not None,
        )
        if any(configured) and not all(configured):
            msg = "OCR tespit ve tanıma model dizinleri birlikte ayarlanmalıdır."
            raise ValueError(msg)
        return self


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        env_nested_delimiter="__",
        env_prefix="MAKI_",
        extra="forbid",
        frozen=True,
        hide_input_in_errors=True,
        validate_default=True,
    )

    environment: Environment = Environment.DEVELOPMENT
    database: DatabaseSettings = Field(default_factory=DatabaseSettings)
    redis: RedisSettings = Field(default_factory=RedisSettings)
    telemetry: TelemetrySettings = Field(default_factory=TelemetrySettings)
    security: SecuritySettings = Field(default_factory=SecuritySettings)
    billing: BillingSettings = Field(default_factory=BillingSettings)
    retention: RetentionSettings = Field(default_factory=RetentionSettings)
    ocr: OcrSettings = Field(default_factory=OcrSettings)
    anthropic_api_key: SecretStr | None = None
    anthropic_model: str = Field(
        default="claude-sonnet-4-6",
        min_length=1,
        max_length=128,
    )
    evds_api_key: SecretStr | None = None
    enable_insecure_dev_auth: bool = False

    @model_validator(mode="after")
    def validate_environment_contract(self) -> Self:
        if self.enable_insecure_dev_auth and not self.environment.is_development:
            msg = "Güvensiz geliştirme kimliği yalnızca geliştirme ortamında açılabilir."
            raise ValueError(msg)

        if self.environment is not Environment.PRODUCTION:
            return self

        missing = self._missing_production_settings()
        if missing:
            msg = f"Üretim ayarları eksik: {', '.join(missing)}."
            raise ValueError(msg)
        return self

    def _missing_production_settings(self) -> tuple[str, ...]:
        required = (
            ("database.dsn", self.database.dsn),
            ("redis.dsn", self.redis.dsn),
            ("security.jwt_public_key", self.security.jwt_public_key),
            ("telemetry.otlp_endpoint", self.telemetry.otlp_endpoint),
        )
        return tuple(name for name, value in required if value is None)
