import time

import orjson
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from maki.observability.telemetry import Telemetry

_MAXIMUM_PROBLEM_BYTES = 8_192


class ObservabilityMiddleware:
    def __init__(self, app: ASGIApp, *, telemetry: Telemetry) -> None:
        self.app = app
        self.telemetry = telemetry

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        method = scope["method"]
        status_code = 500
        started = time.perf_counter()
        problem_body = bytearray()
        is_problem = False

        async def capture_status(message: Message) -> None:
            nonlocal is_problem, status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
                headers = dict(message.get("headers", ()))
                content_type = headers.get(b"content-type", b"")
                is_problem = content_type.startswith(b"application/problem+json")
            elif message["type"] == "http.response.body" and is_problem:
                remaining = _MAXIMUM_PROBLEM_BYTES - len(problem_body)
                if remaining > 0:
                    problem_body.extend(message.get("body", b"")[:remaining])
            await send(message)

        with self.telemetry.span(
            "maki.http.request",
            {"http.request.method": method},
        ):
            try:
                await self.app(scope, receive, capture_status)
            finally:
                attributes = {
                    "http.request.method": method,
                    "http.response.status_code": status_code,
                    "http.route": self._route_template(scope),
                    "error.code": self._problem_code(problem_body),
                }
                self.telemetry.set_current_span_attributes(attributes)
                self.telemetry.increment("maki.http.requests", attributes)
                self.telemetry.observe(
                    "maki.http.duration_ms",
                    (time.perf_counter() - started) * 1_000,
                    attributes,
                )

    @staticmethod
    def _route_template(scope: Scope) -> str | None:
        route = scope.get("route")
        template = getattr(route, "path", None)
        if isinstance(template, str):
            return template
        path = scope.get("path")
        return path if isinstance(path, str) else None

    @staticmethod
    def _problem_code(body: bytearray) -> str | None:
        if not body:
            return None
        try:
            payload = orjson.loads(body)
        except orjson.JSONDecodeError:
            return None
        if not isinstance(payload, dict):
            return None
        code = payload.get("kod")
        return code if isinstance(code, str) else None
