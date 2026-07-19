import json
from datetime import UTC, datetime
from pathlib import Path

import httpx
import pytest

from maki.official_data.clients.base import (
    OfficialHttpClient,
    ProviderSchemaError,
    UnsafeProviderRedirectError,
)
from maki.official_data.clients.tuik import TuikClient

_FIXTURE = Path("tests/fixtures/official_data/tuik-cpi.json").read_bytes()
_NOW = datetime(2026, 7, 3, 12, tzinfo=UTC)


async def test_tuik_fixture_is_parsed_without_float() -> None:
    async def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.host == "data.tuik.gov.tr"
        return httpx.Response(
            200,
            content=_FIXTURE,
            headers={"content-type": "application/json", "etag": '"tuik-v1"'},
            request=request,
        )

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        snapshot = await TuikClient(
            http=OfficialHttpClient(
                client=client,
                allowed_origin="https://data.tuik.gov.tr/",
            ),
            endpoint_path="api/cpi",
            clock=lambda: _NOW,
        ).fetch()

    assert snapshot.source_name == "tuik"
    assert snapshot.source_version == "2026-07-03"
    assert str(snapshot.points[-1].value) == "123.45"


async def test_tuik_schema_change_is_not_returned_as_empty_snapshot() -> None:
    broken = json.dumps({"version": "2026-07-03", "rows": []}).encode()

    async def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            content=broken,
            headers={"content-type": "application/json"},
            request=request,
        )

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        tuik = TuikClient(
            http=OfficialHttpClient(
                client=client,
                allowed_origin="https://data.tuik.gov.tr/",
            ),
            endpoint_path="api/cpi",
            clock=lambda: _NOW,
        )
        with pytest.raises(ProviderSchemaError, match="şeması"):
            await tuik.fetch()


async def test_tuik_redirect_to_different_host_is_rejected() -> None:
    async def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            302,
            headers={"location": "https://evil.example/veri"},
            request=request,
        )

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        tuik = TuikClient(
            http=OfficialHttpClient(
                client=client,
                allowed_origin="https://data.tuik.gov.tr/",
            ),
            endpoint_path="api/cpi",
            clock=lambda: _NOW,
        )
        with pytest.raises(UnsafeProviderRedirectError, match="izinli"):
            await tuik.fetch()
