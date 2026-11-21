"""Extract and normalize the usable pieces from the supplied grass composition.

The source is an AI-authored composition rather than a regular atlas.  Crops are
therefore explicit and reviewed.  Low-alpha background noise is discarded and
all resizing uses nearest-neighbour sampling to preserve the pixel-art edges.
"""

from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "tilesets" / "grass" / "grass_tileset.png"
OUTPUT = SOURCE.parent
EXPECTED_SIZE = (1448, 1086)
ALPHA_THRESHOLD = 64

# (left, top, right, bottom), output canvas.  Flat tiles share one anchor-ready
# 72x48 canvas; decorative/height pieces retain their natural scaled height.
PIECES = {
    "grass_plain_01.png": ((20, 15, 278, 173), (72, 48)),
    "grass_plain_02.png": ((280, 15, 515, 173), (72, 48)),
    "grass_plain_03.png": ((516, 15, 746, 173), (72, 48)),
    "grass_plain_04.png": ((748, 15, 982, 173), (72, 48)),
    "grass_tall_01.png": ((984, 15, 1215, 173), (72, 48)),
    "grass_tall_02.png": ((1216, 15, 1448, 173), (72, 48)),
    "grass_flowers_01.png": ((20, 175, 278, 342), (72, 48)),
    "grass_flowers_02.png": ((748, 175, 982, 342), (72, 48)),
    "grass_flowers_03.png": ((984, 175, 1215, 342), (72, 48)),
    "grass_stones_01.png": ((20, 345, 278, 510), (72, 48)),
    "grass_stones_02.png": ((280, 345, 515, 510), (72, 48)),
    "grass_stones_03.png": ((516, 345, 746, 510), (72, 48)),
    "grass_block_01.png": ((20, 510, 278, 675), (72, 64)),
    "grass_block_02.png": ((280, 510, 515, 675), (72, 64)),
    "grass_edge_01.png": ((20, 675, 278, 850), (72, 64)),
    "grass_edge_02.png": ((280, 675, 515, 850), (72, 64)),
    # Stop before x=1205: the source has a detached fragment from the next
    # composition cell at the far right of this crop.
    "grass_stairs_01.png": ((984, 845, 1205, 1086), (72, 72)),
    "grass_stairs_02.png": ((1216, 845, 1448, 1086), (72, 72)),
}


def clean_crop(source: Image.Image, crop_box: tuple[int, int, int, int]) -> Image.Image:
    crop = np.array(source.crop(crop_box).convert("RGBA"), dtype=np.uint8)
    alpha = crop[:, :, 3]
    keep = alpha >= ALPHA_THRESHOLD
    if not keep.any():
        raise RuntimeError(f"No opaque pixels found in crop {crop_box}")
    # The composition contains brightly coloured RGB data at alpha 0..3.  A
    # binary alpha avoids green/black fringes when Godot samples the texture.
    crop[:, :, 3] = np.where(keep, 255, 0).astype(np.uint8)
    crop[~keep, :3] = 0
    ys, xs = np.where(keep)
    return Image.fromarray(crop).crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def normalize(piece: Image.Image, canvas_size: tuple[int, int]) -> Image.Image:
    target_width = 64
    scale = target_width / piece.width
    target_height = max(1, round(piece.height * scale))
    if target_height > canvas_size[1]:
        scale = canvas_size[1] / piece.height
        target_width = max(1, round(piece.width * scale))
        target_height = canvas_size[1]
    piece = piece.resize((target_width, target_height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    offset = ((canvas_size[0] - target_width) // 2, (canvas_size[1] - target_height) // 2)
    canvas.alpha_composite(piece, offset)
    return canvas


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    if source.size != EXPECTED_SIZE:
        raise RuntimeError(f"Unexpected source size {source.size}; expected {EXPECTED_SIZE}")
    for filename, (crop_box, canvas_size) in PIECES.items():
        result = normalize(clean_crop(source, crop_box), canvas_size)
        result.save(OUTPUT / filename, optimize=True)
        print(f"{filename}: {result.size}")


if __name__ == "__main__":
    main()
