from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends
from pydantic import Field, SecretStr

from maki.api.dependencies import (
    BillingVerificationPort,
    IdempotencyHeader,
    authenticated_subject,
    billing_verification,
)
from maki.billing.models import Entitlement, EntitlementStatus, Store
from maki.common.models import ApiModel

router = APIRouter(prefix="/api/v1/billing", tags=["abonelik"])


class GooglePlayVerificationRequest(ApiModel):
    store: Literal[Store.GOOGLE_PLAY]
    package_name: str = Field(
        min_length=3,
        max_length=256,
        pattern=r"^[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z0-9_]+)+$",
    )
    purchase_token: SecretStr = Field(min_length=1, max_length=4_096)


class AppStoreVerificationRequest(ApiModel):
    store: Literal[Store.APP_STORE]
    signed_transaction: SecretStr = Field(min_length=10, max_length=32_768)


VerificationRequest = Annotated[
    GooglePlayVerificationRequest | AppStoreVerificationRequest,
    Field(discriminator="store"),
]


class EntitlementView(ApiModel):
    store: Store
    product_id: str
    status: EntitlementStatus
    expires_at: datetime | None

    @classmethod
    def from_entitlement(cls, entitlement: Entitlement) -> "EntitlementView":
        return cls(
            store=entitlement.store,
            product_id=entitlement.product_id,
            status=entitlement.status,
            expires_at=entitlement.expires_at,
        )


class EntitlementCollection(ApiModel):
    items: tuple[EntitlementView, ...]


@router.post(
    "/verifications",
    operation_id="billing_verification_create",
    description="Mağaza kanıtını sunucuda doğrular ve abonelik hakkını günceller.",
)
async def create_verification(
    payload: VerificationRequest,
    _idempotency_key: IdempotencyHeader,
    subject_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[BillingVerificationPort, Depends(billing_verification)],
) -> EntitlementView:
    if isinstance(payload, GooglePlayVerificationRequest):
        entitlement = await service.verify_google(
            package_name=payload.package_name,
            purchase_token=payload.purchase_token.get_secret_value(),
            subject_id=subject_id,
        )
    else:
        entitlement = await service.verify_apple(
            signed_transaction=payload.signed_transaction.get_secret_value(),
            subject_id=subject_id,
        )
    return EntitlementView.from_entitlement(entitlement)


@router.get(
    "/entitlements",
    operation_id="billing_entitlement_list",
    description="Oturum sahibinin doğrulanmış abonelik haklarını döndürür.",
)
async def list_entitlements(
    subject_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[BillingVerificationPort, Depends(billing_verification)],
) -> EntitlementCollection:
    entitlements = await service.entitlements(subject_id=subject_id)
    return EntitlementCollection(
        items=tuple(EntitlementView.from_entitlement(entitlement) for entitlement in entitlements)
    )
