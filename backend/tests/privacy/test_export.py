from datetime import UTC, datetime, timedelta

from maki.billing.models import (
    Entitlement,
    EntitlementStatus,
    Store,
    StoreEvent,
)
from maki.privacy.export import (
    DataExporter,
    ExportBillingEvent,
    ExportJob,
    SubjectDataSnapshot,
)

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class FakeExportRepository:
    def __init__(self) -> None:
        self.requested_hash: str | None = None

    async def load(self, *, subject_hash: str) -> SubjectDataSnapshot:
        self.requested_hash = subject_hash
        return SubjectDataSnapshot(
            entitlements=(_entitlement(),),
            jobs=(
                ExportJob(
                    job_id="01K00000000000000000000000",
                    kind="forecast",
                    status="succeeded",
                    created_at=NOW - timedelta(days=1),
                    completed_at=NOW,
                ),
            ),
            billing_events=(
                ExportBillingEvent(
                    store=Store.GOOGLE_PLAY,
                    product_id="maki_debt_pro",
                    event=StoreEvent.RENEWED,
                    occurred_at=NOW,
                    expires_at=NOW + timedelta(days=30),
                ),
            ),
        )


async def test_export_contains_only_owner_scoped_sanitized_server_records() -> None:
    repository = FakeExportRepository()
    exporter = DataExporter(repository=repository, clock=lambda: NOW)

    result = await exporter.export(subject_id="cihaz-1")
    document = result.model_dump_json()

    assert result.schema_version == "1.0"
    assert result.generated_at == NOW
    assert len(result.entitlements) == 1
    assert len(result.jobs) == 1
    assert len(result.billing_events) == 1
    assert repository.requested_hash is not None
    assert repository.requested_hash != "cihaz-1"
    assert "subject_hash" not in document
    assert "original_transaction_id" not in document
    assert "transaction_id" not in document
    assert "payload" not in document
    assert "official" not in document
    assert "cohort" not in document


def _entitlement() -> Entitlement:
    return Entitlement(
        subject_hash="a" * 64,
        product_id="maki_debt_pro",
        store=Store.GOOGLE_PLAY,
        status=EntitlementStatus.ACTIVE,
        original_transaction_id="gizli-islem",
        expires_at=NOW + timedelta(days=30),
        last_event_id="gizli-olay",
        last_event=StoreEvent.RENEWED,
        last_event_version=1,
        last_event_at=NOW,
    )
