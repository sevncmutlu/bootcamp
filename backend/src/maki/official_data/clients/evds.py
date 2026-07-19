import re
from collections.abc import Callable
from datetime import date, datetime

from pydantic import Field, ValidationError

from maki.common.models import ApiModel
from maki.official_data.clients.base import (
    OfficialHttpClient,
    ProviderSchemaError,
)
from maki.official_data.models import SeriesPoint, SourceSnapshot
from maki.official_data.normalization import normalize_decimal, parse_evds_date

_SERIES_ID = re.compile(r"^[A-Z0-9.]{2,64}$")
_RESPONSE_FIELD = re.compile(r"^[A-Z0-9_]{2,64}$")
_MAXIMUM_UNIT_LENGTH = 32


class _EvdsPayload(ApiModel):
    total_count: int = Field(alias="totalCount", ge=1)
    version: str | None = Field(default=None, min_length=1, max_length=128)
    items: list[dict[str, object]] = Field(min_length=1)


class _EvdsRow(ApiModel):
    period: str = Field(min_length=10, max_length=10)
    value: str = Field(min_length=1, max_length=64)


class EvdsClient:
    def __init__(  # noqa: PLR0913
        self,
        http: OfficialHttpClient,
        api_key: str,
        series_id: str,
        response_field: str,
        unit: str,
        start_date: date,
        end_date: date,
        clock: Callable[[], datetime],
    ) -> None:
        if not api_key.strip() or any(character.isspace() for character in api_key):
            msg = "EVDS API anahtarı boş veya boşluklu olamaz."
            raise ValueError(msg)
        if _SERIES_ID.fullmatch(series_id) is None:
            msg = "EVDS seri kimliği geçersiz."
            raise ValueError(msg)
        if _RESPONSE_FIELD.fullmatch(response_field) is None:
            msg = "EVDS yanıt alanı geçersiz."
            raise ValueError(msg)
        if not unit.strip() or len(unit) > _MAXIMUM_UNIT_LENGTH:
            msg = "EVDS birimi geçersiz."
            raise ValueError(msg)
        if start_date > end_date:
            msg = "EVDS başlangıç tarihi bitiş tarihinden sonra olamaz."
            raise ValueError(msg)
        self._http = http
        self._api_key = api_key
        self._series_id = series_id
        self._response_field = response_field
        self._unit = unit
        self._start_date = start_date
        self._end_date = end_date
        self._clock = clock

    async def fetch(self) -> SourceSnapshot:
        document = await self._http.get_json(
            self._path(),
            headers={"key": self._api_key},
        )
        try:
            payload = _EvdsPayload.model_validate(document.payload)
        except ValidationError as error:
            message = "EVDS yanıt şeması değişti."
            raise ProviderSchemaError(message) from error
        if payload.total_count != len(payload.items):
            message = "EVDS yanıt şeması nokta sayısıyla uyuşmuyor."
            raise ProviderSchemaError(message)

        retrieved_at = self._clock()
        rows = tuple(self._parse_row(item) for item in payload.items)
        points = tuple(
            sorted(
                (
                    SeriesPoint.model_validate(
                        {
                            "series_id": self._series_id,
                            "period": parse_evds_date(row.period),
                            "value": normalize_decimal(row.value),
                            "unit": self._unit,
                            "release_date": retrieved_at.date(),
                            "source_url": document.source_url,
                            "retrieved_at": retrieved_at,
                        }
                    )
                    for row in rows
                ),
                key=lambda point: (point.series_id, point.period),
            )
        )
        source_version = payload.version or _etag_version(document.etag)
        return SourceSnapshot(
            source_name="tcmb_evds",
            source_version=source_version,
            schema_version=1,
            content_sha256=document.content_sha256,
            etag=document.etag,
            points=points,
        )

    def _parse_row(self, item: dict[str, object]) -> _EvdsRow:
        allowed = {"Tarih", self._response_field, "UNIXTIME"}
        if set(item) - allowed or "Tarih" not in item or self._response_field not in item:
            message = "EVDS satır şeması değişti."
            raise ProviderSchemaError(message)
        try:
            return _EvdsRow.model_validate(
                {
                    "period": item["Tarih"],
                    "value": item[self._response_field],
                }
            )
        except ValidationError as error:
            message = "EVDS satır şeması değişti."
            raise ProviderSchemaError(message) from error

    def _path(self) -> str:
        start = self._start_date.strftime("%d-%m-%Y")
        end = self._end_date.strftime("%d-%m-%Y")
        return f"service/evds/series={self._series_id}&startDate={start}&endDate={end}&type=json"


def _etag_version(etag: str | None) -> str:
    if etag is None:
        message = "EVDS kaynak sürümü döndürmedi."
        raise ProviderSchemaError(message)
    version = etag.strip().strip('"')
    if not version:
        message = "EVDS kaynak sürümü boş."
        raise ProviderSchemaError(message)
    return version
