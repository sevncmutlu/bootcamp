import re
from typing import Final

from pydantic import Field

from maki.common.models import ApiModel
from maki.privacy.models import ScrubResult

_EMAIL_PATTERN: Final = re.compile(
    r"(?<![\w@])[\w.!#$%&'*+/=?^`{|}~-]+@(?:[\w-]+\.)+[\w-]{2,63}",
    flags=re.IGNORECASE,
)
_IBAN_PATTERN: Final = re.compile(r"(?<![A-Z0-9])TR\d{2}(?:[\s-]?\d){22}(?!\d)", re.IGNORECASE)
_CARD_PATTERN: Final = re.compile(r"(?<!\d)(?:\d[\s-]?){12,18}\d(?!\d)")
_PHONE_PATTERN: Final = re.compile(r"(?<!\d)(?:(?:\+|00)90[\s.-]?|0)?5\d{2}(?:[\s.-]?\d){7}(?!\d)")
_MASKS: Final = (
    (_EMAIL_PATTERN, "[EPOSTA]"),
    (_IBAN_PATTERN, "[IBAN]"),
    (_CARD_PATTERN, "[KART]"),
    (_PHONE_PATTERN, "[TELEFON]"),
)


class _ScrubInput(ApiModel):
    text: str = Field(max_length=2_000)


class TextScrubber:
    def scrub(self, text: str) -> ScrubResult:
        current = _ScrubInput(text=text).text
        replacements = 0
        for pattern, mask in _MASKS:
            current, count = pattern.subn(mask, current)
            replacements += count
        return ScrubResult(text=current, replacements=replacements)
