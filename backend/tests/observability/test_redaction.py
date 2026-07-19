import io

import structlog

from maki.observability.attributes import safe_attributes
from maki.observability.logging import configure_logging


def test_safe_attributes_drop_sensitive_names_and_values() -> None:
    attributes = {
        "job.kind": "forecast",
        "amount": 1_250,
        "merchant_name": "Market",
        "user.email": "a@b.com",
        "error.code": "a@b.com",
        "http.route": "/api/v1/jobs/01K0N1P2Q3R4S5T6V7W8X9Y0ZA",
    }

    assert safe_attributes(attributes) == {"job.kind": "forecast"}


def test_safe_attributes_report_dropped_keys_without_values() -> None:
    dropped: list[str] = []

    result = safe_attributes(
        {"job.status": "succeeded", "card_number": "4111111111111111"},
        on_drop=dropped.append,
    )

    assert result == {"job.status": "succeeded"}
    assert dropped == ["card_number"]


def test_structured_log_never_contains_financial_or_exception_text() -> None:
    output = io.StringIO()
    configure_logging(development=False, stream=output)
    logger = structlog.get_logger("test")

    try:
        _raise_private_error()
    except RuntimeError:
        logger.exception(
            "job.failed",
            amount=1_250,
            merchant_name="Market",
            error_code="MODEL_HATASI",
            **{"job.kind": "forecast"},
        )

    rendered = output.getvalue()
    assert "job.failed" in rendered
    assert "forecast" in rendered
    assert "RuntimeError" in rendered
    assert "özel-tutar-1250" not in rendered
    assert "1250" not in rendered
    assert "Market" not in rendered


def _raise_private_error() -> None:
    msg = "özel-tutar-1250"
    raise RuntimeError(msg)
