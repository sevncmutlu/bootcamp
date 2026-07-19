from datetime import UTC, datetime, timedelta

from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.billing.google_play import StoreVerificationError
from maki.billing.models import (
    Entitlement,
    EntitlementStatus,
    Store,
    StoreEvent,
)
from maki.common.config import Environment, Settings

from .job_fakes import FakeTokenVerifier, authorization_headers

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class FakeBillingVerification:
    def __init__(self, *, fail: bool = False) -> None:
        self.fail = fail
        self.google_token: str | None = None

    async def verify_google(
        self,
        *,
        package_name: str,
        purchase_token: str,
        subject_id: str,
    ) -> Entitlement:
        del package_name, subject_id
        self.google_token = purchase_token
        if self.fail:
            msg = "Mağaza işlemi geçersiz."
            raise StoreVerificationError(msg)
        return _entitlement()

    async def verify_apple(
        self,
        *,
        signed_transaction: str,
        subject_id: str,
    ) -> Entitlement:
        del signed_transaction, subject_id
        return _entitlement(store=Store.APP_STORE)

    async def entitlements(self, *, subject_id: str) -> tuple[Entitlement, ...]:
        del subject_id
        return (_entitlement(),)


async def test_billing_verification_hides_store_and_subject_secrets() -> None:
    billing = FakeBillingVerification()
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            billing_verification=billing,
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/billing/verifications",
            headers=authorization_headers(),
            json={
                "store": "google_play",
                "package_name": "com.team120.maki.maki_app",
                "purchase_token": "gizli-token",
            },
        )

    assert response.status_code == 200
    assert billing.google_token == "gizli-token"  # noqa: S105
    assert response.json() == {
        "store": "google_play",
        "product_id": "maki_debt_pro",
        "status": "active",
        "expires_at": "2026-08-18T12:00:00Z",
    }
    assert "gizli-token" not in response.text
    assert "subject_hash" not in response.text
    assert "original_transaction_id" not in response.text


async def test_apple_account_binding_cannot_be_overridden_by_client() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            billing_verification=FakeBillingVerification(),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/billing/verifications",
            headers=authorization_headers(),
            json={
                "store": "app_store",
                "signed_transaction": "a.b.c",
                "expected_account_token": "saldirgan-kimligi",
            },
        )

    assert response.status_code == 422


async def test_unconfigured_provider_returns_specific_retryable_problem() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(token_verifier=FakeTokenVerifier()),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/billing/verifications",
            headers=authorization_headers(),
            json={
                "store": "google_play",
                "package_name": "com.team120.maki.maki_app",
                "purchase_token": "gizli-token",
            },
        )

    assert response.status_code == 503
    assert response.json()["kod"] == "ODEME_DOGRULAMA_HAZIR_DEGIL"
    assert response.json()["tekrar_denenebilir"] is True


async def test_invalid_store_proof_returns_safe_problem() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            billing_verification=FakeBillingVerification(fail=True),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/billing/verifications",
            headers=authorization_headers(),
            json={
                "store": "google_play",
                "package_name": "com.team120.maki.maki_app",
                "purchase_token": "gizli-token",
            },
        )

    assert response.status_code == 422
    assert response.json()["kod"] == "ODEME_DOGRULANAMADI"
    assert "geçersiz" not in response.text


async def test_entitlements_are_owner_scoped_and_sanitized() -> None:
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            billing_verification=FakeBillingVerification(),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/billing/entitlements",
            headers=authorization_headers(),
        )

    assert response.status_code == 200
    assert response.json() == {
        "items": [
            {
                "store": "google_play",
                "product_id": "maki_debt_pro",
                "status": "active",
                "expires_at": "2026-08-18T12:00:00Z",
            }
        ]
    }


def _entitlement(*, store: Store = Store.GOOGLE_PLAY) -> Entitlement:
    return Entitlement(
        subject_hash="a" * 64,
        product_id="maki_debt_pro",
        store=store,
        status=EntitlementStatus.ACTIVE,
        original_transaction_id="gizli-islem",
        expires_at=NOW + timedelta(days=30),
        last_event_id="event-1",
        last_event=StoreEvent.RENEWED,
        last_event_version=1,
        last_event_at=NOW,
    )
