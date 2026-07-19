import json
from datetime import UTC, datetime
from pathlib import Path
from typing import cast

import pytest

from maki.billing.google_play import (
    GooglePlayVerifier,
    GooglePublisherClient,
    StoreProviderUnavailableError,
    StoreVerificationError,
)
from maki.billing.models import EntitlementStatus, StoreEvent

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)
FIXTURE = Path(__file__).parents[1] / "fixtures" / "billing" / "google-subscription.json"


class FakePublisher:
    def __init__(self, response: dict[str, object]) -> None:
        self.response = response
        self.calls = 0

    async def get_subscription(
        self,
        *,
        package_name: str,
        purchase_token: str,
    ) -> dict[str, object]:
        del package_name, purchase_token
        self.calls += 1
        return self.response


class FakeGoogleRequest:
    def __init__(self, response: object) -> None:
        self.response = response

    def execute(self) -> object:
        if isinstance(self.response, Exception):
            raise self.response
        return self.response


class FakeSubscriptions:
    def __init__(self, response: object) -> None:
        self.response = response
        self.arguments: dict[str, str] = {}

    def get(self, **kwargs: str) -> FakeGoogleRequest:
        self.arguments = kwargs
        return FakeGoogleRequest(self.response)


class FakePurchases:
    def __init__(self, subscriptions: FakeSubscriptions) -> None:
        self._subscriptions = subscriptions

    def subscriptionsv2(self) -> FakeSubscriptions:
        return self._subscriptions


class FakeGoogleService:
    def __init__(self, subscriptions: FakeSubscriptions) -> None:
        self._purchases = FakePurchases(subscriptions)

    def purchases(self) -> FakePurchases:
        return self._purchases


class FakeGoogleApiError(RuntimeError):
    def __init__(self, status: int) -> None:
        self.resp = type("Response", (), {"status": status})()


async def test_google_response_is_bound_to_package_product_and_subject() -> None:
    publisher = FakePublisher(_response())
    verifier = GooglePlayVerifier(
        publisher=publisher,
        package_name="com.team120.maki.maki_app",
        allowed_products=frozenset({"maki_debt_pro"}),
        clock=lambda: NOW,
    )

    transaction = await verifier.verify(
        package_name="com.team120.maki.maki_app",
        purchase_token="gizli-token",  # noqa: S106
        subject_hash="a" * 64,
    )

    assert transaction.verified is True
    assert transaction.event is StoreEvent.RENEWED
    assert transaction.product_id == "maki_debt_pro"
    assert EntitlementStatus.ACTIVE.value == "active"


async def test_wrong_package_is_rejected_before_provider_call() -> None:
    publisher = FakePublisher(_response())
    verifier = GooglePlayVerifier(
        publisher=publisher,
        package_name="com.team120.maki.maki_app",
        allowed_products=frozenset({"maki_debt_pro"}),
        clock=lambda: NOW,
    )

    with pytest.raises(StoreVerificationError, match="paket"):
        await verifier.verify(
            package_name="com.attacker.app",
            purchase_token="gizli-token",  # noqa: S106
            subject_hash="a" * 64,
        )

    assert publisher.calls == 0


async def test_google_client_uses_subscription_v2_without_logging_token(
    caplog: pytest.LogCaptureFixture,
) -> None:
    subscriptions = FakeSubscriptions(_response())
    client = GooglePublisherClient(service=FakeGoogleService(subscriptions))

    response = await client.get_subscription(
        package_name="com.team120.maki.maki_app",
        purchase_token="cok-gizli-token",  # noqa: S106
    )

    assert response == _response()
    assert subscriptions.arguments == {
        "packageName": "com.team120.maki.maki_app",
        "token": "cok-gizli-token",
    }
    assert "cok-gizli-token" not in caplog.text


@pytest.mark.parametrize(
    ("status", "expected_error"),
    [
        (404, StoreVerificationError),
        (503, StoreProviderUnavailableError),
    ],
)
async def test_google_client_classifies_provider_failures(
    status: int,
    expected_error: type[Exception],
) -> None:
    client = GooglePublisherClient(
        service=FakeGoogleService(
            FakeSubscriptions(FakeGoogleApiError(status)),
        )
    )

    with pytest.raises(expected_error):
        await client.get_subscription(
            package_name="com.team120.maki.maki_app",
            purchase_token="gizli-token",  # noqa: S106
        )


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("acknowledgementState", "ACKNOWLEDGEMENT_STATE_PENDING"),
        ("subscriptionState", "SUBSCRIPTION_STATE_PENDING"),
        ("testPurchase", {}),
    ],
)
async def test_google_non_entitling_states_are_rejected(
    field: str,
    value: object,
) -> None:
    response = {**_response(), field: value}
    verifier = GooglePlayVerifier(
        publisher=FakePublisher(response),
        package_name="com.team120.maki.maki_app",
        allowed_products=frozenset({"maki_debt_pro"}),
        clock=lambda: NOW,
    )

    with pytest.raises(StoreVerificationError):
        await verifier.verify(
            package_name="com.team120.maki.maki_app",
            purchase_token="gizli-token",  # noqa: S106
            subject_hash="a" * 64,
        )


def _response() -> dict[str, object]:
    document: object = json.loads(FIXTURE.read_text(encoding="utf-8"))
    assert isinstance(document, dict)
    return cast("dict[str, object]", document)
