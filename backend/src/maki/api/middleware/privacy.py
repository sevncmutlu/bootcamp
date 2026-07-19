import orjson
from starlette.datastructures import Headers
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from maki.api.handlers import problem_response, request_id_from_scope
from maki.common.errors import ErrorCode
from maki.observability.telemetry import Telemetry
from maki.privacy.models import PrivacyViolation
from maki.privacy.policy import PrivacyPolicy


class PrivacyMiddleware:
    def __init__(
        self,
        app: ASGIApp,
        policy: PrivacyPolicy | None = None,
        telemetry: Telemetry | None = None,
    ) -> None:
        self.app = app
        self.policy = policy or PrivacyPolicy()
        self.telemetry = telemetry

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if not self._must_inspect(scope):
            await self.app(scope, receive, send)
            return

        body = await self._read_body(receive)
        violations = self._inspect(body)
        if violations:
            if self.telemetry is not None:
                self.telemetry.increment(
                    "maki.privacy.rejected",
                    {"http.route": scope["path"]},
                )
            response = problem_response(
                status_code=422,
                code=ErrorCode.PRIVACY_FIELD_REJECTED,
                message="İstek gizlilik politikasına uymuyor.",
                request_id=request_id_from_scope(scope),
                details=tuple(
                    {"alan": item.path, "neden": "Bu alan gönderilemez."} for item in violations
                ),
            )
            await response(scope, receive, send)
            return

        await self.app(scope, self._replay(body), send)

    @staticmethod
    def _must_inspect(scope: Scope) -> bool:
        if scope["type"] != "http" or not scope["path"].startswith("/api/v1"):
            return False
        content_type = Headers(scope=scope).get("Content-Type", "")
        return content_type.partition(";")[0].strip().casefold() == "application/json"

    @staticmethod
    async def _read_body(receive: Receive) -> bytes:
        chunks: list[bytes] = []
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return b""
            chunks.append(message.get("body", b""))
            if not message.get("more_body", False):
                return b"".join(chunks)

    def _inspect(self, body: bytes) -> tuple[PrivacyViolation, ...]:
        if not body:
            return ()
        try:
            value = orjson.loads(body)
        except orjson.JSONDecodeError:
            return ()
        return self.policy.inspect_json(value)

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
