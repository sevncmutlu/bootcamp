from datetime import UTC, date, datetime

import pytest
from pydantic import ValidationError

from maki.coach.models import SourceCard


def test_source_card_is_strict_and_requires_utc() -> None:
    with pytest.raises(ValidationError):
        SourceCard.model_validate(
            {
                "snapshot_id": "01ARZ3NDEKTSV4RRFFQ69G5FAV",
                "snapshot_digest": "a" * 64,
                "institution": "TÜİK",
                "series_id": "TUFE_GENEL",
                "period": date(2026, 6, 1),
                "value": "123.45",
                "unit": "index",
                "release_date": date(2026, 7, 3),
                "source_url": "https://data.tuik.gov.tr/",
                "retrieved_at": datetime(2026, 7, 3),  # noqa: DTZ001
                "unknown": True,
            }
        )


def test_source_card_accepts_decimal_text() -> None:
    card = SourceCard(
        snapshot_id="01ARZ3NDEKTSV4RRFFQ69G5FAV",
        snapshot_digest="a" * 64,
        institution="TÜİK",
        series_id="TUFE_GENEL",
        period=date(2026, 6, 1),
        value="123.45",
        unit="index",
        release_date=date(2026, 7, 3),
        source_url="https://data.tuik.gov.tr/",
        retrieved_at=datetime(2026, 7, 3, tzinfo=UTC),
    )

    assert str(card.value) == "123.45"
