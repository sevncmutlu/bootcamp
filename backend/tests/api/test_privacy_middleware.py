from collections.abc import AsyncIterator

from httpx import AsyncClient


async def test_forbidden_json_field_is_rejected_before_validation(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/test/strict",
        json={"count": 1, "meta": {"debt_balance": 5_000}},
    )

    assert response.status_code == 422
    assert response.json()["kod"] == "GIZLILIK_ALANI_REDDEDILDI"
    assert "5000" not in response.text


async def test_regular_route_rejects_body_larger_than_one_mebibyte(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/test/strict",
        content=b"x" * (1_048_576 + 1),
        headers={"Content-Type": "application/octet-stream"},
    )

    assert response.status_code == 413
    assert response.json()["kod"] == "ISTEK_COK_BUYUK"


async def test_chunked_body_is_limited_without_content_length(client: AsyncClient) -> None:
    async def chunks() -> AsyncIterator[bytes]:
        yield b"x" * 700_000
        yield b"x" * 400_000

    response = await client.post(
        "/api/v1/test/strict",
        content=chunks(),
        headers={"Content-Type": "application/octet-stream"},
    )

    assert response.status_code == 413
    assert response.json()["kod"] == "ISTEK_COK_BUYUK"
