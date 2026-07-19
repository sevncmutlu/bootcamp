from io import BytesIO

import numpy as np
from numpy.typing import NDArray
from PIL import Image


def decode_rgb(image_bytes: bytes) -> NDArray[np.uint8]:
    with Image.open(BytesIO(image_bytes)) as image:
        rgb = image.convert("RGB")
        try:
            return np.asarray(rgb, dtype=np.uint8).copy()
        finally:
            rgb.close()
