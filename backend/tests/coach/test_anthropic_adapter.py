import json
from pathlib import Path
from types import SimpleNamespace

import anthropic
import httpx
import pytest

from maki.coach.anthropic_adapter import AnthropicAdapter
from maki.coach.ports import CoachProviderError

_FIXTURE = Path("tests/fixtures/coach/anthropic-response.json").read_text(encoding="utf-8")


class StubMessages:
    def __init__(self, *, text: str = _FIXTURE, error: Exception | None = None) -> None:
        self.text = text
        self.error = error
        self.kwargs: dict[str, object] | None = None

    async def create(self, **kwargs: object) -> object:
        self.kwargs = kwargs
        if self.error is not None:
            raise self.error
        return SimpleNamespace(content=[SimpleNamespace(type="text", text=self.text)])


async def test_anthropic_response_is_validated_as_json() -> None:
    messages = StubMessages()
    adapter = AnthropicAdapter(messages=messages, model_name="claude-test")

    answer = await adapter.answer(
        system_prompt="Sabit sistem.",
        user_prompt="Kaynaklı soru.",
    )

    assert answer.answer.startswith("Haziran")
    assert answer.cited_source_numbers == (1,)
    assert messages.kwargs is not None
    assert messages.kwargs["model"] == "claude-test"
    assert messages.kwargs["temperature"] == 0


async def test_broken_provider_json_is_rejected() -> None:
    adapter = AnthropicAdapter(
        messages=StubMessages(text=json.dumps({"answer": "eksik"})),
        model_name="claude-test",
    )

    with pytest.raises(CoachProviderError, match="doğrulanamadı") as captured:
        await adapter.answer(system_prompt="Sistem.", user_prompt="Soru.")

    assert captured.value.retryable is False


@pytest.mark.parametrize(
    ("error", "code", "retryable"),
    [
        (
            anthropic.APITimeoutError(request=httpx.Request("POST", "https://api.anthropic.com")),
            "PROVIDER_TIMEOUT",
            True,
        ),
        (
            anthropic.RateLimitError(
                "rate limited",
                response=httpx.Response(
                    429,
                    request=httpx.Request(
                        "POST",
                        "https://api.anthropic.com",
                    ),
                ),
                body={},
            ),
            "PROVIDER_RATE_LIMITED",
            True,
        ),
        (
            anthropic.AuthenticationError(
                "bad key",
                response=httpx.Response(
                    401,
                    request=httpx.Request(
                        "POST",
                        "https://api.anthropic.com",
                    ),
                ),
                body={},
            ),
            "PROVIDER_AUTH_FAILED",
            False,
        ),
    ],
)
async def test_provider_errors_are_mapped_without_sdk_message(
    error: Exception,
    code: str,
    retryable: object,
) -> None:
    adapter = AnthropicAdapter(
        messages=StubMessages(error=error),
        model_name="claude-test",
    )

    with pytest.raises(CoachProviderError) as captured:
        await adapter.answer(system_prompt="Sistem.", user_prompt="Soru.")

    assert captured.value.code == code
    assert isinstance(retryable, bool)
    assert captured.value.retryable is retryable
    assert str(error) not in str(captured.value)
