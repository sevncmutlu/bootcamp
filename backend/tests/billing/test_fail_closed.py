import pytest

from maki.billing.verification import (
    BillingVerificationService,
    ProviderNotConfigured,
)


async def test_missing_store_provider_fails_closed() -> None:
    service = BillingVerificationService(
        billing=None,
        google=None,
        apple=None,
    )

    with pytest.raises(ProviderNotConfigured):
        await service.verify_google(
            package_name="com.team120.maki.maki_app",
            purchase_token="gizli",  # noqa: S106
            subject_id="cihaz-1",
        )
