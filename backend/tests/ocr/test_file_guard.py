from io import BytesIO

import pytest
from PIL import Image

from maki.ocr.file_guard import FileGuard, ImageRejectedError


def test_executable_with_jpeg_name_is_rejected() -> None:
    guard = FileGuard(maximum_bytes=1024, maximum_pixels=10_000)

    with pytest.raises(ImageRejectedError, match="imzası"):
        guard.sanitize(b"MZ\x90\x00fake executable")


def test_corrupt_png_is_rejected() -> None:
    guard = FileGuard(maximum_bytes=1024, maximum_pixels=10_000)

    with pytest.raises(ImageRejectedError, match="bozuk"):
        guard.sanitize(b"\x89PNG\r\n\x1a\nbroken")


def test_size_and_pixel_limits_are_enforced() -> None:
    with pytest.raises(ImageRejectedError, match="boyut"):
        FileGuard(maximum_bytes=10, maximum_pixels=10_000).sanitize(b"\xff\xd8\xff" + b"x" * 20)

    image = Image.new("RGB", (100, 100), "white")
    with pytest.raises(ImageRejectedError, match="piksel"):
        FileGuard(maximum_bytes=100_000, maximum_pixels=5_000).sanitize(_encode(image, "PNG"))


def test_multiframe_png_is_rejected() -> None:
    first = Image.new("RGBA", (10, 10), "white")
    second = Image.new("RGBA", (10, 10), "black")
    buffer = BytesIO()
    first.save(
        buffer,
        format="PNG",
        save_all=True,
        append_images=[second],
        duration=100,
    )

    with pytest.raises(ImageRejectedError, match="tek kare"):
        FileGuard(maximum_bytes=100_000, maximum_pixels=10_000).sanitize(buffer.getvalue())


def test_valid_image_is_reencoded_without_exif() -> None:
    image = Image.new("RGB", (20, 10), "white")
    exif = Image.Exif()
    exif[0x010E] = "özel açıklama"
    source = BytesIO()
    image.save(source, format="JPEG", exif=exif)

    sanitized = FileGuard(
        maximum_bytes=100_000,
        maximum_pixels=10_000,
    ).sanitize(source.getvalue())

    with Image.open(BytesIO(sanitized.image_bytes)) as result:
        assert result.getexif() == {}
        assert result.size == (20, 10)


def _encode(image: Image.Image, image_format: str) -> bytes:
    buffer = BytesIO()
    image.save(buffer, format=image_format)
    return buffer.getvalue()
