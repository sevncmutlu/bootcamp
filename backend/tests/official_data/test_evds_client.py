from collections.abc import Awaitable, Callable
from datetime import UTC, date, datetime
from pathlib import Path

import httpx
import pytest

from maki.official_data.clients.base import (
    OfficialHttpClient,
    ProviderHttpError,
    ProviderSchemaError,
)
from maki.official_data.clients.evds import EvdsClient

_FIXTURE = Path("tests/fixtures/official_data/evds-series.json").read_bytes()
_NOW = datetime(2026, 7, 3, 12, tzinfo=UTC)


async def _no_sleep(_: float) -> None:
    return None


def _client(
    handler: Callable[[httpx.Request], Awaitable[httpx.Response]],
) -> tuple[httpx.AsyncClient, EvdsClient]:
    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    http = OfficialHttpClient(
        client=client,
        allowed_origin="https://evds3.tcmb.gov.tr/",
        sleeper=_no_sleep,
        jitter=lambda: 0,
    )
    return client, EvdsClient(
        http=http,
        api_key="secret-key",
        series_id="TP.FG.J0",
        response_field="TP_FG_J0",
        unit="percent",
        start_date=date(2026, 5, 1),
        end_date=date(2026, 6, 1),
        clock=lambda: _NOW,
    )


async def test_evds_key_is_only_in_header_and_fixture_is_parsed() -> None:
    async def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.host == "evds3.tcmb.gov.tr"
        assert "secret-key" not in str(request.url)
        assert request.headers["key"] == "secret-key"
        return httpx.Response(
            200,
            content=_FIXTURE,
            headers={"content-type": "application/json", "etag": '"evds-v1"'},
            request=request,
        )

    client, evds = _client(handler)
    async with client:
        snapshot = await evds.fetch()

    assert snapshot.source_name == "tcmb_evds"
    assert snapshot.source_version == "2026-07-03"
    assert [str(point.value) for point in snapshot.points] == ["87.25", "88.10"]


async def test_evds_retries_429_and_5xx_at_most_twice() -> None:
    attempts = 0

    async def handler(request: httpx.Request) -> httpx.Response:
        nonlocal attempts
        attempts += 1
        if attempts == 1:
            return httpx.Response(
                429,
                headers={"retry-after": "0"},
                request=request,
            )
        if attempts == 2:
            return httpx.Response(503, request=request)
        return httpx.Response(
            200,
            content=_FIXTURE,
            headers={"content-type": "application/json"},
            request=request,
        )

    client, evds = _client(handler)
    async with client:
        snapshot = await evds.fetch()

    assert snapshot.points
    assert attempts == 3


async def test_evds_timeout_is_mapped_without_provider_detail() -> None:
    async def handler(_: httpx.Request) -> httpx.Response:
        message = "sensitive-provider-detail"
        raise httpx.ReadTimeout(message)

    client, evds = _client(handler)
    async with client:
        with pytest.raises(ProviderHttpError, match="zaman aşımına"):
            await evds.fetch()


async def test_evds_missing_dynamic_series_field_is_schema_error() -> None:
    async def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={
                "totalCount": 1,
                "version": "2026-07-03",
                "items": [{"Tarih": "01-06-2026", "WRONG": "1"}],
            },
            request=request,
        )

    client, evds = _client(handler)
    async with client:
        with pytest.raises(ProviderSchemaError, match="şeması"):
            await evds.fetch()
