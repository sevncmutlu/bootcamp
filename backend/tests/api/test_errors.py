import re

from httpx import AsyncClient


async def test_validation_error_is_stable_and_turkish(client: AsyncClient) -> None:
    response = await client.post("/api/v1/test/strict", json={"count": "1"})

    assert response.status_code == 422
    body = response.json()
    assert body["kod"] == "DOGRULAMA_BASARISIZ"
    assert body["mesaj"] == "İstek alanları doğrulanamadı."
    assert body["istek_kimligi"]
    assert body["tekrar_denenebilir"] is False


async def test_internal_error_does_not_expose_exception(client: AsyncClient) -> None:
    response = await client.get("/api/v1/test/error")

    assert response.status_code == 500
    assert response.json()["mesaj"] == "Beklenmeyen bir hata oluştu."
    assert "özel-veri-123" not in response.text


async def test_request_id_is_preserved_only_when_safe(client: AsyncClient) -> None:
    safe_id = "mobil-istek_42"

    accepted = await client.get("/health/live", headers={"X-Request-ID": safe_id})
    regenerated = await client.get("/health/live", headers={"X-Request-ID": "space var"})

    assert accepted.headers["X-Request-ID"] == safe_id
    assert re.fullmatch(r"[0-9A-HJKMNP-TV-Z]{26}", regenerated.headers["X-Request-ID"])
