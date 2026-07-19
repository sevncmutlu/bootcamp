import re
import sys
from collections.abc import MutableMapping
from typing import TextIO

import structlog
from opentelemetry import trace
from structlog.typing import EventDict, Processor, WrappedLogger

from maki.observability.attributes import safe_attributes

_EVENT_NAME = re.compile(r"^[a-z0-9_.-]{1,64}$")
_REQUEST_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")


def configure_logging(*, development: bool, stream: TextIO | None = None) -> None:
    renderer: Processor
    if development:
        renderer = structlog.dev.ConsoleRenderer(colors=False)
    else:
        renderer = structlog.processors.JSONRenderer(sort_keys=True, ensure_ascii=False)

    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            _sanitize_event,
            renderer,
        ],
        wrapper_class=structlog.make_filtering_bound_logger(20),
        logger_factory=structlog.PrintLoggerFactory(file=stream or sys.stdout),
        cache_logger_on_first_use=False,
    )


def _sanitize_event(
    _logger: WrappedLogger,
    _method_name: str,
    event_dict: EventDict,
) -> EventDict:
    event = event_dict.pop("event", "")
    level = event_dict.pop("level", "info")
    timestamp = event_dict.pop("timestamp", "")
    exc_info = event_dict.pop("exc_info", None)
    request_id = event_dict.pop("request_id", None)
    error_code = event_dict.pop("error_code", None)

    event_name = (
        event if isinstance(event, str) and _EVENT_NAME.fullmatch(event) else "invalid.event"
    )
    result: EventDict = {
        "event": event_name,
        "level": level,
        "service": "maki-backend",
        "timestamp": timestamp,
    }
    if isinstance(request_id, str) and _REQUEST_ID.fullmatch(request_id):
        result["request_id"] = request_id
    if isinstance(error_code, str):
        safe_error = safe_attributes({"error.code": error_code})
        result.update(safe_error)

    result.update(safe_attributes(event_dict))
    _add_trace_context(result)
    error_type = _exception_type(exc_info)
    if error_type is not None:
        result["error.type"] = error_type
    return result


def _add_trace_context(event_dict: MutableMapping[str, object]) -> None:
    context = trace.get_current_span().get_span_context()
    if not context.is_valid:
        return
    event_dict["trace_id"] = trace.format_trace_id(context.trace_id)
    event_dict["span_id"] = trace.format_span_id(context.span_id)


def _exception_type(exc_info: object) -> str | None:
    if exc_info is True:
        exception_type = sys.exc_info()[0]
        return exception_type.__name__ if exception_type is not None else None
    if isinstance(exc_info, tuple) and exc_info and isinstance(exc_info[0], type):
        return exc_info[0].__name__
    return None
