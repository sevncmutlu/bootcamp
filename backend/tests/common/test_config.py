import pytest
from pydantic import ValidationError

from maki.common.config import Environment, Settings


def test_production_rejects_missing_infrastructure() -> None:
    with pytest.raises(ValidationError, match="Üretim ayarları eksik"):
        Settings(environment=Environment.PRODUCTION)


def test_development_has_no_provider_secret_default() -> None:
    settings = Settings(environment=Environment.DEVELOPMENT)

    assert settings.anthropic_api_key is None
    assert settings.evds_api_key is None
    assert settings.billing.google_service_account_json is None
    assert settings.billing.apple_trusted_root_pem is None
    assert settings.retention.job_metadata_days == 7
    assert settings.enable_insecure_dev_auth is False


def test_settings_reject_unknown_fields() -> None:
    with pytest.raises(ValidationError):
        Settings.model_validate({"bilinmeyen": True})


def test_telemetry_ratio_must_be_bounded() -> None:
    with pytest.raises(ValidationError):
        Settings.model_validate({"telemetry": {"trace_sample_ratio": 1.1}})


def test_partial_apple_billing_configuration_is_rejected() -> None:
    with pytest.raises(ValidationError, match="birlikte"):
        Settings.model_validate(
            {
                "billing": {
                    "apple_trusted_root_pem": "-----BEGIN CERTIFICATE-----",
                }
            }
        )
