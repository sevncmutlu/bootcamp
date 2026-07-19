import re
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

from maki.official_data.clients.base import ProviderSchemaError

_SIMPLE_DECIMAL = re.compile(r"^-?\d+(?:[.,]\d+)?$")
_TURKISH_GROUPED_DECIMAL = re.compile(r"^-?\d{1,3}(?:\.\d{3})+,\d+$")


def normalize_decimal(value: str) -> Decimal:
    stripped = value.strip()
    if _TURKISH_GROUPED_DECIMAL.fullmatch(stripped):
        normalized = stripped.replace(".", "").replace(",", ".")
    elif _SIMPLE_DECIMAL.fullmatch(stripped):
        normalized = stripped.replace(",", ".")
    else:
        message = "Sağlayıcı ondalık değer şeması geçersiz."
        raise ProviderSchemaError(message)
    try:
        parsed = Decimal(normalized)
    except InvalidOperation as error:
        message = "Sağlayıcı ondalık değeri ayrıştırılamadı."
        raise ProviderSchemaError(message) from error
    if not parsed.is_finite():
        message = "Sağlayıcı ondalık değeri sonlu değil."
        raise ProviderSchemaError(message)
    return parsed


def parse_month(value: str) -> date:
    try:
        parsed = datetime.strptime(value, "%Y-%m").date()  # noqa: DTZ007
    except ValueError as error:
        message = "Sağlayıcı aylık dönem şeması geçersiz."
        raise ProviderSchemaError(message) from error
    return parsed.replace(day=1)


def parse_evds_date(value: str) -> date:
    try:
        return datetime.strptime(value, "%d-%m-%Y").date()  # noqa: DTZ007
    except ValueError as error:
        message = "EVDS tarih şeması geçersiz."
        raise ProviderSchemaError(message) from error


def parse_iso_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError as error:
        message = "Sağlayıcı yayın tarihi şeması geçersiz."
        raise ProviderSchemaError(message) from error
