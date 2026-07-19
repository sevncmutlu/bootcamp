import warnings
from io import BytesIO
from typing import Literal

from PIL import Image, UnidentifiedImageError

from maki.ocr.models import SanitizedImage

_JPEG_SIGNATURE = b"\xff\xd8\xff"
_PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
_SUPPORTED_FORMATS = {"JPEG": "image/jpeg", "PNG": "image/png"}


class ImageRejectedError(Exception):
    """Fiş görseli güvenlik denetiminden geçemedi."""


class FileGuard:
    def __init__(
        self,
        *,
        maximum_bytes: int = 8 * 1024 * 1024,
        maximum_pixels: int = 40_000_000,
    ) -> None:
        if maximum_bytes <= 0 or maximum_pixels <= 0:
            msg = "Görsel sınırları sıfırdan büyük olmalıdır."
            raise ValueError(msg)
        self._maximum_bytes = maximum_bytes
        self._maximum_pixels = maximum_pixels

    def sanitize(self, data: bytes) -> SanitizedImage:
        if not data or len(data) > self._maximum_bytes:
            msg = "Fiş görseli boyut sınırını aşıyor."
            raise ImageRejectedError(msg)
        _require_signature(data)
        try:
            self._verify(data)
            return self._reencode(data)
        except ImageRejectedError:
            raise
        except (OSError, SyntaxError, UnidentifiedImageError, ValueError) as error:
            msg = "Fiş görseli bozuk veya desteklenmiyor."
            raise ImageRejectedError(msg) from error

    def _verify(self, data: bytes) -> None:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(BytesIO(data)) as image:
                self._validate_open_image(image)
                image.verify()

    def _reencode(self, data: bytes) -> SanitizedImage:
        with Image.open(BytesIO(data)) as image:
            self._validate_open_image(image)
            image.load()
            image_format = image.format
            if image_format not in _SUPPORTED_FORMATS:
                msg = "Fiş görseli yalnızca JPEG veya PNG olabilir."
                raise ImageRejectedError(msg)
            if image_format == "JPEG":
                clean = image.convert("RGB")
            else:
                clean = image.convert("RGBA" if "A" in image.getbands() else "RGB")
            output = BytesIO()
            try:
                clean.save(
                    output,
                    format=image_format,
                    optimize=False,
                    **({"quality": 95} if image_format == "JPEG" else {}),
                )
                encoded = output.getvalue()
            finally:
                output.close()
                clean.close()
            media_type: Literal["image/jpeg", "image/png"] = (
                "image/jpeg" if image_format == "JPEG" else "image/png"
            )
            return SanitizedImage(
                image_bytes=encoded,
                media_type=media_type,
                width=image.width,
                height=image.height,
            )

    def _validate_open_image(self, image: Image.Image) -> None:
        if image.format not in _SUPPORTED_FORMATS:
            msg = "Fiş görseli yalnızca JPEG veya PNG olabilir."
            raise ImageRejectedError(msg)
        if getattr(image, "n_frames", 1) != 1:
            msg = "Fiş görseli tek kare olmalıdır."
            raise ImageRejectedError(msg)
        if image.width * image.height > self._maximum_pixels:
            msg = "Fiş görseli piksel sınırını aşıyor."
            raise ImageRejectedError(msg)


def _require_signature(data: bytes) -> None:
    if data.startswith((_JPEG_SIGNATURE, _PNG_SIGNATURE)):
        return
    msg = "Fiş görseli dosya imzası desteklenmiyor."
    raise ImageRejectedError(msg)
