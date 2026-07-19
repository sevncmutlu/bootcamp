from typing import Protocol

from maki.coach.models import ProviderAnswer, RetrievedContext


class CoachProviderError(Exception):
    def __init__(
        self,
        *,
        code: str,
        message: str,
        retryable: bool,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.retryable = retryable


class CoachProvider(Protocol):
    async def answer(
        self,
        *,
        system_prompt: str,
        user_prompt: str,
    ) -> ProviderAnswer: ...


class SourceRetriever(Protocol):
    async def retrieve(
        self,
        query: str,
        limit: int,
    ) -> RetrievedContext: ...
