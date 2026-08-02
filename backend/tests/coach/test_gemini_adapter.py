import httpx
import pytest

from maki.coach.gemini_adapter import GeminiAdapter
from maki.coach.ports import CoachProviderError


async def test_gemini_uses_header_key_and_reads_text_response() -> None:
    seen_request: httpx.Request | None = None

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal seen_request
        seen_request = request
        return httpx.Response(
            200,
            json={
                "candidates": [{"content": {"parts": [{"text": "Haftalık bütçeni gözden geçir."}]}}]
            },
        )

    client = httpx.AsyncClient(transport=httpx.MockTransport(handler))
    adapter = GeminiAdapter(
        api_key="g" * 32,
        model_name="gemini-3.5-flash-lite",
        client=client,
    )

    answer = await adapter.answer(question="Bütçemi nasıl düzenlerim?")

    assert answer == "Haftalık bütçeni gözden geçir."
    assert seen_request is not None
    assert seen_request.headers["x-goog-api-key"] == "g" * 32
    assert "g" * 32 not in str(seen_request.url)
    await client.aclose()


@pytest.mark.parametrize("status", [401, 403])
async def test_gemini_auth_failure_is_not_retryable(status: int) -> None:
    client = httpx.AsyncClient(
        transport=httpx.MockTransport(lambda _request: httpx.Response(status))
    )
    adapter = GeminiAdapter(
        api_key="g" * 32,
        model_name="gemini-3.5-flash-lite",
        client=client,
    )

    with pytest.raises(CoachProviderError) as caught:
        await adapter.answer(question="Merhaba")

    assert caught.value.code == "PROVIDER_AUTH_FAILED"
    assert caught.value.retryable is False
    await client.aclose()
