import pytest
from pydantic import ValidationError

from maki.privacy.scrubber import TextScrubber


def test_scrubber_masks_supported_identifiers() -> None:
    text = "Bana a@b.com ve TR330006100519786457841326 için yardım et, 0532 111 22 33"

    result = TextScrubber().scrub(text)

    assert result.text == "Bana [EPOSTA] ve [IBAN] için yardım et, [TELEFON]"
    assert result.replacements == 3


def test_scrubber_masks_card_with_separators() -> None:
    result = TextScrubber().scrub("Kartım 4111-1111-1111-1111, e-posta kişi@örnek.com.")

    assert result.text == "Kartım [KART], e-posta [EPOSTA]."
    assert result.replacements == 2


def test_scrubber_rejects_oversized_text_without_echoing_it() -> None:
    private_text = "ö" * 2_001

    with pytest.raises(ValidationError) as error:
        TextScrubber().scrub(private_text)

    assert private_text not in str(error.value)
