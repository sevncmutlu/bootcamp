import re
from typing import Final

from starlette.datastructures import Headers, MutableHeaders
from starlette.types import ASGIApp, Message, Receive, Scope, Send
from structlog.contextvars import bind_contextvars, clear_contextvars

from maki.common.ids import new_ulid

_SAFE_REQUEST_ID: Final = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")


class RequestContextMiddleware:
    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        candidate = Headers(scope=scope).get("X-Request-ID")
        request_id = (
            candidate if candidate and _SAFE_REQUEST_ID.fullmatch(candidate) else new_ulid()
        )
        scope.setdefault("state", {})["request_id"] = request_id
        clear_contextvars()
        bind_contextvars(request_id=request_id)

        async def send_with_request_id(message: Message) -> None:
            if message["type"] == "http.response.start":
                MutableHeaders(scope=message)["X-Request-ID"] = request_id
            await send(message)

        try:
            await self.app(scope, receive, send_with_request_id)
        finally:
            clear_contextvars()
