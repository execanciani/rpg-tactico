"""Extract the usable warrior animations and iron equipment from the AI sheet.

The source is a labelled composition. Every crop is explicit, background is
removed from its local border colour, and border-connected labels/grid lines are
discarded. Combat outputs share a 96x96 canvas with a feet anchor at (48, 86).
"""

from collections import deque
from pathlib import Path
import shutil

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
WARRIOR_ROOT = ROOT / "assets" / "characters" / "warrior"
SOURCE = WARRIOR_ROOT / "warrior_equipment_sheet.png"
EXPECTED_SIZE = (1536, 1024)
CANVAS = (96, 96)
FEET = (48, 86)

DIRECTION_X = {
    "front": [375, 433, 490],
    "right": [557, 614, 670],
    "back": [736, 792, 848],
    "left": [915, 972, 1028],
}
STATE_Y = {"idle": 105, "walk": 176, "attack": 247, "hurt": 318, "death": 387}
STATE_COUNT = {"idle": 3, "walk": 3, "attack": 3, "hurt": 2, "death": 3}
HURT_X = {
    "front": [375, 465], "right": [560, 650],
    "back": [740, 830], "left": [920, 1010],
}

LAYER_CENTERS = {
    "front": 1238,
    "right": 1328,
    "back": 1418,
    "left": 1507,
}
LAYER_ROWS = {
    "helmets": (75, 70, 56),
    "armor": (132, 70, 52),
    "boots": (273, 72, 42),
    "weapons": (360, 74, 42),
    "shields": (402, 72, 42),
}

# Position/scale of isolated pieces on the normalized combat canvas.
LAYER_LAYOUT = {
    "helmets": {d: (48, 37, 0.72) for d in DIRECTION_X},
    "armor": {d: (48, 57, 0.72) for d in DIRECTION_X},
    "boots": {
        "front": (48, 80, 0.72), "right": (48, 80, 0.72),
        "back": (48, 80, 0.72), "left": (48, 80, 0.72),
    },
    "weapons": {
        "front": (66, 64, 0.78), "right": (66, 63, 0.78),
        "back": (34, 62, 0.78), "left": (30, 63, 0.78),
    },
    "shields": {
        "front": (31, 62, 0.76), "right": (56, 62, 0.76),
        "back": (62, 62, 0.76), "left": (39, 62, 0.76),
    },
}


def components(mask: np.ndarray) -> list[list[tuple[int, int]]]:
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    result: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            queue = deque([(x, y)])
            visited[y, x] = True
            component: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for oy in (-1, 0, 1):
                    for ox in (-1, 0, 1):
                        nx, ny = px + ox, py + oy
                        if 0 <= nx < width and 0 <= ny < height and mask[ny, nx] and not visited[ny, nx]:
                            visited[ny, nx] = True
                            queue.append((nx, ny))
            result.append(component)
    return result


def transparent_crop(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    image = source.crop(box).convert("RGBA")
    data = np.array(image, dtype=np.uint8)
    border = np.concatenate((data[0, :, :3], data[-1, :, :3], data[:, 0, :3], data[:, -1, :3]))
    background = np.median(border.astype(np.float32), axis=0)
    distance = np.linalg.norm(data[:, :, :3].astype(np.float32) - background, axis=2)
    alpha = np.clip((distance - 17.0) / 28.0 * 255.0, 0.0, 255.0).astype(np.uint8)
    data[:, :, 3] = alpha
    mask = alpha > 60
    height, width = mask.shape
    for component in components(mask):
        xs = [point[0] for point in component]
        ys = [point[1] for point in component]
        touches_border = min(xs) == 0 or min(ys) == 0 or max(xs) == width - 1 or max(ys) == height - 1
        component_width = max(xs) - min(xs) + 1
        component_height = max(ys) - min(ys) + 1
        line = (component_width > component_height * 5 and component_height <= 10) or (component_height > component_width * 5 and component_width <= 10)
        # Neighbour fragments touch the crop border and are small. A character
        # can occasionally connect to an atlas guide line, so large components
        # are retained and the line-like test handles isolated guides.
        if (touches_border and len(component) < 250) or line or len(component) < 5:
            for x, y in component:
                data[y, x, 3] = 0
    data[:, :, 3] = np.where(data[:, :, 3] >= 60, 255, 0).astype(np.uint8)
    data[data[:, :, 3] == 0, :3] = 0
    return Image.fromarray(data, "RGBA")


def trim(image: Image.Image) -> Image.Image:
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("Crop became fully transparent")
    return image.crop(bounds)


def retain_layer_components(image: Image.Image, count: int) -> Image.Image:
    data = np.array(image, dtype=np.uint8)
    candidates: list[tuple[int, list[tuple[int, int]]]] = []
    for component in components(data[:, :, 3] > 24):
        colours = np.array([data[y, x, :3] for x, y in component], dtype=np.float32)
        # Labels and panel cut-outs are nearly black; real equipment contains
        # bright steel, gold, leather or red pixels.
        if float(np.percentile(colours.max(axis=1), 75)) < 70.0:
            continue
        candidates.append((len(component), component))
    candidates.sort(key=lambda entry: entry[0], reverse=True)
    keep = {point for _, component in candidates[:count] for point in component}
    for y in range(data.shape[0]):
        for x in range(data.shape[1]):
            if (x, y) not in keep:
                data[y, x] = 0
    return Image.fromarray(data, "RGBA")


def remove_detached_shadow(image: Image.Image) -> Image.Image:
    data = np.array(image, dtype=np.uint8)
    rgb = data[:, :, :3]
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    seed = (data[:, :, 3] > 0) & ((maximum > 135) | ((maximum - minimum) > 55))
    grown = seed.copy()
    for _ in range(2):
        padded = np.pad(grown, 1, mode="constant")
        expanded = np.zeros_like(grown)
        for oy in range(3):
            for ox in range(3):
                expanded |= padded[oy:oy + grown.shape[0], ox:ox + grown.shape[1]]
        grown = expanded
    data[~grown] = 0
    return Image.fromarray(data, "RGBA")


def normalize_at_feet(image: Image.Image) -> Image.Image:
    image = trim(image)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(image, (FEET[0] - image.width // 2, FEET[1] - image.height))
    return canvas


def remove_baked_front_weapon(frame: Image.Image) -> Image.Image:
    """Remove the sword baked into the sheet's nominally unequipped front attack."""
    data = np.array(frame, dtype=np.uint8)
    # The body is centred left of this region; the sword and its slash occupy
    # the lower-right quadrant. Equipment layers restore the selected weapon.
    data[46:90, 57:96] = 0
    return Image.fromarray(data, "RGBA")


def extract_animations(source: Image.Image) -> None:
    animation_root = WARRIOR_ROOT / "animations"
    base_root = WARRIOR_ROOT / "base"
    for state, center_y in STATE_Y.items():
        for direction, default_centers in DIRECTION_X.items():
            centers = HURT_X[direction] if state == "hurt" else default_centers
            count = STATE_COUNT[state]
            for index, center_x in enumerate(centers[:count]):
                width = 70 if state == "hurt" else 56
                half_height = 33 if state == "death" else 34
                box = (center_x - width // 2, center_y - half_height, center_x + width // 2, center_y + half_height)
                extracted = transparent_crop(source, box)
                extracted = retain_layer_components(extracted, 2 if state == "attack" else 1)
                frame = normalize_at_feet(extracted)
                if state == "attack" and direction == "front":
                    frame = remove_baked_front_weapon(frame)
                target = animation_root / state
                target.mkdir(parents=True, exist_ok=True)
                frame.save(target / f"{direction}_{index:02d}.png", optimize=True)
    base_root.mkdir(parents=True, exist_ok=True)
    for direction in DIRECTION_X:
        shutil.copy2(animation_root / "idle" / f"{direction}_00.png", base_root / f"warrior_base_{direction}.png")


def normalized_layer(piece: Image.Image, category: str, direction: str) -> Image.Image:
    piece = trim(piece)
    center_x, center_y, scale = LAYER_LAYOUT[category][direction]
    size = (max(1, round(piece.width * scale)), max(1, round(piece.height * scale)))
    piece = piece.resize(size, Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(piece, (round(center_x - size[0] / 2), round(center_y - size[1] / 2)))
    return canvas


def extract_layers(source: Image.Image) -> None:
    for category, (center_y, width, height) in LAYER_ROWS.items():
        target = WARRIOR_ROOT / category
        target.mkdir(parents=True, exist_ok=True)
        for direction, center_x in LAYER_CENTERS.items():
            box = (center_x - width // 2, center_y - height // 2, center_x + width // 2, center_y + height // 2)
            piece = transparent_crop(source, box)
            piece = retain_layer_components(piece, 2 if category == "boots" else 1)
            if category == "weapons":
                piece = remove_detached_shadow(piece)
            layer = normalized_layer(piece, category, direction)
            singular = {"helmets": "iron_helmet", "armor": "iron_armor", "boots": "iron_boots", "weapons": "iron_sword", "shields": "iron_shield"}[category]
            layer.save(target / f"{singular}_{direction}.png", optimize=True)


def extract_preview_layers() -> None:
    layouts = {
        "helmets": ("iron_helmet", (128, 43), 2.35),
        "armor": ("iron_armor", (128, 132), 2.65),
        "boots": ("iron_boots", (128, 350), 2.70),
        "weapons": ("iron_sword", (194, 235), 4.00),
        "shields": ("iron_shield", (65, 190), 3.25),
    }
    for category, (item_id, center, scale) in layouts.items():
        source = trim(Image.open(WARRIOR_ROOT / category / f"{item_id}_front.png").convert("RGBA"))
        size = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
        source = source.resize(size, Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (256, 384), (0, 0, 0, 0))
        canvas.alpha_composite(source, (round(center[0] - size[0] / 2), round(center[1] - size[1] / 2)))
        canvas.save(WARRIOR_ROOT / category / f"{item_id}_preview.png", optimize=True)


def extract_portrait(source: Image.Image) -> None:
    target = WARRIOR_ROOT / "portraits"
    target.mkdir(parents=True, exist_ok=True)
    portrait = trim(transparent_crop(source, (12, 14, 221, 258)))
    portrait.save(target / "warrior_portrait.png", optimize=True)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    if source.size != EXPECTED_SIZE:
        raise RuntimeError(f"Unexpected sheet size {source.size}; expected {EXPECTED_SIZE}")
    extract_animations(source)
    extract_layers(source)
    extract_preview_layers()
    extract_portrait(source)
    print("Warrior base animations and iron layers extracted.")


if __name__ == "__main__":
    main()
