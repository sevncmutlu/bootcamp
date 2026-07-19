from collections.abc import Callable
from datetime import datetime

from pydantic import Field, ValidationError

from maki.common.models import ApiModel
from maki.official_data.clients.base import (
    OfficialHttpClient,
    ProviderSchemaError,
)
from maki.official_data.models import SeriesPoint, SourceSnapshot
from maki.official_data.normalization import (
    normalize_decimal,
    parse_iso_date,
    parse_month,
)


class _TuikRow(ApiModel):
    series_code: str = Field(alias="seriesCode", pattern=r"^[A-Z0-9_.-]{2,64}$")
    period: str = Field(min_length=7, max_length=7)
    value: str = Field(min_length=1, max_length=64)
    unit: str = Field(min_length=1, max_length=32)
    release_date: str = Field(alias="releaseDate", min_length=10, max_length=10)


class _TuikPayload(ApiModel):
    version: str = Field(min_length=1, max_length=128)
    data: list[_TuikRow] = Field(min_length=1)


class TuikClient:
    def __init__(
        self,
        http: OfficialHttpClient,
        endpoint_path: str,
        clock: Callable[[], datetime],
    ) -> None:
        if not endpoint_path or endpoint_path.startswith(("http://", "https://")):
            msg = "TÜİK uç yolu göreli olmalıdır."
            raise ValueError(msg)
        self._http = http
        self._endpoint_path = endpoint_path
        self._clock = clock

    async def fetch(self) -> SourceSnapshot:
        document = await self._http.get_json(self._endpoint_path)
        try:
            payload = _TuikPayload.model_validate(document.payload)
        except ValidationError as error:
            message = "TÜİK yanıt şeması değişti."
            raise ProviderSchemaError(message) from error
        retrieved_at = self._clock()
        points = tuple(
            sorted(
                (
                    SeriesPoint.model_validate(
                        {
                            "series_id": row.series_code,
                            "period": parse_month(row.period),
                            "value": normalize_decimal(row.value),
                            "unit": row.unit,
                            "release_date": parse_iso_date(row.release_date),
                            "source_url": document.source_url,
                            "retrieved_at": retrieved_at,
                        }
                    )
                    for row in payload.data
                ),
                key=lambda point: (point.series_id, point.period),
            )
        )
        return SourceSnapshot(
            source_name="tuik",
            source_version=payload.version,
            schema_version=1,
            content_sha256=document.content_sha256,
            etag=document.etag,
            points=points,
        )
