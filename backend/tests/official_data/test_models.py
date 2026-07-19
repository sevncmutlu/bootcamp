from datetime import UTC, date, datetime
from decimal import Decimal

import pytest
from pydantic import ValidationError

from maki.official_data.models import SeriesPoint, SourceSnapshot


def test_series_point_rejects_naive_time_and_empty_source() -> None:
    with pytest.raises(ValidationError):
        SeriesPoint(
            series_id="TUFE_GENEL",
            period=date(2026, 6, 1),
            value="123.45",
            unit="index",
            release_date=date(2026, 7, 3),
            source_url="",
            retrieved_at=datetime(2026, 7, 3),  # noqa: DTZ001
        )


def test_series_point_accepts_decimal_string_without_float() -> None:
    point = SeriesPoint(
        series_id="TUFE_GENEL",
        period=date(2026, 6, 1),
        value="123.45",
        unit="index",
        release_date=date(2026, 7, 3),
        source_url="https://data.tuik.gov.tr/",
        retrieved_at=datetime(2026, 7, 3, tzinfo=UTC),
    )

    assert point.value == Decimal("123.45")


def test_series_point_rejects_float_and_non_month_start() -> None:
    common = {
        "series_id": "TUFE_GENEL",
        "unit": "index",
        "release_date": date(2026, 7, 3),
        "source_url": "https://data.tuik.gov.tr/",
        "retrieved_at": datetime(2026, 7, 3, tzinfo=UTC),
    }

    with pytest.raises(ValidationError):
        SeriesPoint(period=date(2026, 6, 1), value=123.45, **common)
    with pytest.raises(ValidationError):
        SeriesPoint(period=date(2026, 6, 2), value="123.45", **common)


def test_snapshot_rejects_unknown_field_and_invalid_digest() -> None:
    with pytest.raises(ValidationError):
        SourceSnapshot.model_validate(
            {
                "source_name": "tuik",
                "source_version": "2026-07-03",
                "schema_version": 1,
                "content_sha256": "bozuk",
                "etag": None,
                "points": [],
                "debug": True,
            }
        )
