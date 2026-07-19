from collections.abc import Mapping

from starlette.datastructures import Headers
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from maki.api.handlers import problem_response, request_id_from_scope
from maki.common.errors import ErrorCode

_DEFAULT_MAX_BYTES = 1_048_576
_MULTIPART_OVERHEAD_BYTES = 65_536
_RECEIPT_MAX_BYTES = 8_388_608 + _MULTIPART_OVERHEAD_BYTES
_RECEIPT_PATH = "/api/v1/receipts/jobs"


class BodyLimitMiddleware:
    def __init__(
        self,
        app: ASGIApp,
        *,
        default_max_bytes: int = _DEFAULT_MAX_BYTES,
        path_limits: Mapping[str, int] | None = None,
    ) -> None:
        self.app = app
        self.default_max_bytes = default_max_bytes
        self.path_limits = dict(path_limits or {_RECEIPT_PATH: _RECEIPT_MAX_BYTES})

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        limit = self.path_limits.get(scope["path"], self.default_max_bytes)
        if self._declared_length_exceeds_limit(scope, limit):
            await self._reject(scope, receive, send)
            return

        body, exceeded = await self._read_body(receive, limit)
        if exceeded:
            await self._reject(scope, receive, send)
            return

        await self.app(scope, self._replay(body), send)

    @staticmethod
    def _declared_length_exceeds_limit(scope: Scope, limit: int) -> bool:
        content_length = Headers(scope=scope).get("Content-Length")
        if content_length is None:
            return False
        try:
            return int(content_length) > limit
        except ValueError:
            return True

    @staticmethod
    async def _read_body(receive: Receive, limit: int) -> tuple[bytes, bool]:
        chunks: list[bytes] = []
        size = 0
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return b"", False
            chunk = message.get("body", b"")
            size += len(chunk)
            if size > limit:
                return b"", True
            chunks.append(chunk)
            if not message.get("more_body", False):
                return b"".join(chunks), False

    @staticmethod
    def _replay(body: bytes) -> Receive:
        sent = False

        async def receive() -> Message:
            nonlocal sent
            if sent:
                return {"type": "http.request", "body": b"", "more_body": False}
            sent = True
            return {"type": "http.request", "body": body, "more_body": False}

        return receive

    @staticmethod
    async def _reject(scope: Scope, receive: Receive, send: Send) -> None:
        response = problem_response(
            status_code=413,
            code=ErrorCode.BODY_TOO_LARGE,
            message="İstek gövdesi izin verilen sınırı aşıyor.",
            request_id=request_id_from_scope(scope),
        )
        await response(scope, receive, send)
