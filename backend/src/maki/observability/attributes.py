import re
from collections.abc import Callable, Mapping

from maki.privacy.scrubber import TextScrubber

type AttributeValue = bool | int | float | str

_MAX_VALUE_LENGTH = 128
_MIN_HTTP_STATUS = 100
_MAX_HTTP_STATUS = 599
_MAX_RETRY_ATTEMPT = 100
_ALLOWED_KEYS = frozenset(
    {
        "deployment.environment",
        "error.code",
        "http.request.method",
        "http.response.status_code",
        "http.route",
        "job.kind",
        "job.outcome",
        "job.status",
        "model.name",
        "process.type",
        "provider.name",
        "queue.name",
        "retention.class",
        "retry.attempt",
        "service.operation",
    }
)
_ENUM_VALUES = {
    "deployment.environment": frozenset({"development", "test", "production"}),
    "http.request.method": frozenset({"DELETE", "GET", "PATCH", "POST", "PUT"}),
    "job.kind": frozenset(
        {
            "billing_verification",
            "coach",
            "forecast",
            "model_training",
            "receipt",
            "retention",
        }
    ),
    "job.outcome": frozenset({"failed", "retried", "succeeded"}),
    "job.status": frozenset({"accepted", "failed", "queued", "retry_wait", "running", "succeeded"}),
    "model.name": frozenset({"lightgbm", "lin_ts", "prophet", "seasonal_naive"}),
    "process.type": frozenset({"api", "dispatcher", "worker"}),
    "provider.name": frozenset(
        {"anthropic", "app_attest", "evds", "play_integrity", "redis", "tuik"}
    ),
    "retention.class": frozenset({"idempotency", "job_metadata", "ocr_result", "telemetry"}),
    "queue.name": frozenset({"maki:jobs", "maki:jobs:failed"}),
    "service.operation": frozenset(
        {
            "billing.verify",
            "coach.query",
            "forecast.create",
            "leaderboard.percentile",
            "privacy.delete",
            "privacy.export",
            "receipt.process",
            "sources.refresh",
        }
    ),
}
_ROUTE_TEMPLATES = frozenset(
    {
        "/api/v1/billing/entitlements",
        "/api/v1/billing/verifications",
        "/api/v1/coach/queries",
        "/api/v1/forecasts/jobs",
        "/api/v1/jobs/{job_id}",
        "/api/v1/leaderboard/percentiles",
        "/api/v1/privacy/data",
        "/api/v1/privacy/exports",
        "/api/v1/receipts/jobs",
        "/api/v1/sources",
        "/health/live",
        "/health/ready",
    }
)
_SAFE_TEXT = re.compile(r"^[A-Za-z0-9_.:/{}-]{1,128}$")
_ERROR_CODE = re.compile(r"^[A-Z0-9_]{3,64}$")
_scrubber = TextScrubber()


def safe_attributes(
    attributes: Mapping[str, object] | None,
    *,
    on_drop: Callable[[str], None] | None = None,
) -> dict[str, AttributeValue]:
    if not attributes:
        return {}

    result: dict[str, AttributeValue] = {}
    for key, value in attributes.items():
        sanitized = _sanitize(key, value)
        if sanitized is None:
            if on_drop is not None:
                on_drop(key)
            continue
        result[key] = sanitized
    return result


def _sanitize(key: str, value: object) -> AttributeValue | None:
    if key not in _ALLOWED_KEYS:
        return None
    if key == "http.response.status_code":
        return _bounded_int(value, minimum=_MIN_HTTP_STATUS, maximum=_MAX_HTTP_STATUS)
    if key == "retry.attempt":
        return _bounded_int(value, minimum=0, maximum=_MAX_RETRY_ATTEMPT)
    return _sanitize_text(key, value)


def _sanitize_text(key: str, value: object) -> str | None:
    if not isinstance(value, str):
        return None

    shortened = value[:_MAX_VALUE_LENGTH]
    if _scrubber.scrub(shortened).replacements:
        return None
    if key == "http.route":
        return shortened if shortened in _ROUTE_TEMPLATES else None
    allowed_values = _ENUM_VALUES.get(key)
    if allowed_values is not None:
        return shortened if shortened in allowed_values else None
    if key == "error.code":
        return shortened if _ERROR_CODE.fullmatch(shortened) else None
    return shortened if _SAFE_TEXT.fullmatch(shortened) else None


def _bounded_int(value: object, *, minimum: int, maximum: int) -> int | None:
    if not isinstance(value, int) or isinstance(value, bool):
        return None
    return value if minimum <= value <= maximum else None
