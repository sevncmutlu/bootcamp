from datetime import UTC, datetime, timedelta

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from maki.common.config import Environment
from maki.security.attestation import AttestationVerifier
from maki.security.tokens import AuthenticationError, TokenIssuer, TokenVerifier


class MutableClock:
    def __init__(self) -> None:
        self.now = datetime(2026, 7, 19, 12, tzinfo=UTC)

    def __call__(self) -> datetime:
        return self.now

    def advance(self, *, seconds: int) -> None:
        self.now += timedelta(seconds=seconds)


@pytest.fixture
def token_services() -> tuple[TokenIssuer, TokenVerifier, MutableClock]:
    private_key = Ed25519PrivateKey.generate()
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    clock = MutableClock()
    issuer = TokenIssuer(
        private_key=private_pem,
        key_id="test-key",
        issuer="maki",
        audience="maki-mobile",
        clock=clock,
    )
    verifier = TokenVerifier(
        public_keys={"test-key": public_pem},
        issuer="maki",
        audience="maki-mobile",
        clock=clock,
    )
    return issuer, verifier, clock


def test_expired_token_is_rejected(
    token_services: tuple[TokenIssuer, TokenVerifier, MutableClock],
) -> None:
    issuer, verifier, clock = token_services
    token = issuer.issue(subject="anon-device", ttl_seconds=60)
    clock.advance(seconds=61)

    with pytest.raises(AuthenticationError) as error:
        verifier.verify(token)

    assert error.value.code == "OTURUM_SURESI_DOLDU"
    assert "anon-device" not in str(error.value)


def test_unknown_key_id_is_rejected(
    token_services: tuple[TokenIssuer, TokenVerifier, MutableClock],
) -> None:
    issuer, _, clock = token_services
    verifier = TokenVerifier(
        public_keys={},
        issuer="maki",
        audience="maki-mobile",
        clock=clock,
    )

    with pytest.raises(AuthenticationError) as error:
        verifier.verify(issuer.issue(subject="anon-device", ttl_seconds=60))

    assert error.value.code == "OTURUM_ANAHTARI_GECERSIZ"


async def test_production_attestation_fails_closed_without_provider() -> None:
    verifier = AttestationVerifier(
        environment=Environment.PRODUCTION,
        providers={},
        enable_insecure_dev_auth=False,
    )

    with pytest.raises(AuthenticationError) as error:
        await verifier.verify(provider="play_integrity", assertion="opaque")

    assert error.value.code == "CIHAZ_DOGRULANAMADI"


async def test_development_bypass_requires_explicit_flag() -> None:
    verifier = AttestationVerifier(
        environment=Environment.DEVELOPMENT,
        providers={},
        enable_insecure_dev_auth=True,
    )

    device = await verifier.verify(provider="development", assertion="local-device")

    assert device.provider == "development"
    assert device.subject_hash != "local-device"
