from datetime import datetime
from decimal import ROUND_HALF_EVEN, Decimal
from typing import TYPE_CHECKING, Annotated

from fastapi import APIRouter, Depends
from pydantic import Field, HttpUrl

from maki.api.dependencies import ServiceNotReadyError, official_data_repository
from maki.common.models import ApiModel
from maki.official_data.ports import OfficialDataRepository

if TYPE_CHECKING:
    from maki.official_data.models import SeriesPoint

_MINIMUM_POINTS = 2
_NO_SNAPSHOT_MESSAGE = "Yayınlanmış TÜİK verisi bulunamadı."
_MISSING_POINTS_MESSAGE = "Enflasyon değişimi için iki dönem veri gerekli."

router = APIRouter(prefix="/api/v1/official-data", tags=["resmî veri"])


class LatestInflationResponse(ApiModel):
    period: str = Field(pattern=r"^\d{4}-\d{2}$")
    previous_period: str = Field(pattern=r"^\d{4}-\d{2}$")
    rate_basis_points: int = Field(ge=-10_000, le=100_000)
    source: str
    source_url: HttpUrl
    retrieved_at: datetime


@router.get(
    "/inflation/latest",
    operation_id="official_inflation_latest",
    description="Yayınlanmış resmî TÜFE endeksinden son dönem değişimini döndürür.",
)
async def latest_inflation(
    repository: Annotated[OfficialDataRepository, Depends(official_data_repository)],
) -> LatestInflationResponse:
    snapshot = await repository.latest_published("tuik")
    if snapshot is None:
        raise ServiceNotReadyError(_NO_SNAPSHOT_MESSAGE)

    groups: dict[str, list[SeriesPoint]] = {}
    for point in snapshot.points:
        groups.setdefault(point.series_id, []).append(point)
    preferred = groups.get("TUFE_GENEL")
    points = preferred or next(
        (values for values in groups.values() if len(values) >= _MINIMUM_POINTS),
        [],
    )
    points = sorted(points, key=lambda item: item.period)
    if len(points) < _MINIMUM_POINTS or points[-2].value <= 0:
        raise ServiceNotReadyError(_MISSING_POINTS_MESSAGE)

    previous, latest = points[-2:]
    rate = ((latest.value / previous.value) - Decimal(1)) * Decimal(10_000)
    return LatestInflationResponse(
        period=latest.period.strftime("%Y-%m"),
        previous_period=previous.period.strftime("%Y-%m"),
        rate_basis_points=int(rate.quantize(Decimal(1), rounding=ROUND_HALF_EVEN)),
        source="TÜİK",
        source_url=latest.source_url,
        retrieved_at=latest.retrieved_at,
    )
