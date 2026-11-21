"""Extrae y normaliza los recursos utilizables de la composición del mago."""

from __future__ import annotations

from dataclasses import dataclass
from collections import deque
from pathlib import Path
import shutil

import numpy as np
from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
MAGE_ROOT = ROOT / "assets/sprites/characters/mage"
SOURCE = MAGE_ROOT / "mage_spritesheet.png"
CLASS_PORTRAITS = ROOT / "assets/portraits/classes"
EXPECTED_SIZE = (1536, 1024)
COMBAT_CANVAS = (96, 96)
COMBAT_FEET = (48, 86)
SCALE = 0.5


@dataclass(frozen=True)
class Frame:
    folder: str
    name: str
    box: tuple[int, int, int, int]
    anchor: tuple[int, int]
    mirror_to: tuple[str, str] | None = None


FRAMES = [
    Frame("idle", "front_00", (598, 23, 727, 181), (654, 171)),
    Frame("idle", "right_00", (799, 25, 910, 181), (850, 171), ("idle", "left_mirrored_00")),
    Frame("idle", "back_00", (968, 21, 1105, 181), (1035, 171)),
    Frame("idle", "left_00", (1128, 25, 1246, 181), (1181, 171)),
    Frame("walk", "right_00", (584, 247, 691, 369), (637, 361), ("walk", "left_03")),
    Frame("walk", "right_01", (721, 247, 827, 369), (780, 361), ("walk", "left_02")),
    Frame("walk", "right_02", (861, 247, 972, 369), (923, 361), ("walk", "left_01")),
    Frame("walk", "right_03", (995, 247, 1101, 369), (1053, 361), ("walk", "left_00")),
    Frame("cast", "right_00", (574, 385, 691, 516), (635, 507), ("cast", "left_03")),
    Frame("cast", "right_01", (711, 385, 837, 516), (777, 507), ("cast", "left_02")),
    Frame("cast", "right_02", (849, 380, 986, 516), (915, 507), ("cast", "left_01")),
    Frame("cast", "right_03", (991, 383, 1160, 516), (1067, 507), ("cast", "left_00")),
    Frame("attack", "right_00", (570, 523, 699, 653), (636, 644), ("attack", "left_03")),
    Frame("attack", "right_01", (705, 520, 842, 653), (777, 644), ("attack", "left_02")),
    Frame("attack", "right_02", (846, 518, 990, 653), (916, 644), ("attack", "left_01")),
    Frame("attack", "right_03", (990, 518, 1160, 653), (1064, 644), ("attack", "left_00")),
    Frame("hurt", "right_00", (580, 662, 694, 791), (637, 783), ("hurt", "left_02")),
    Frame("hurt", "right_01", (711, 661, 842, 791), (779, 783), ("hurt", "left_01")),
    Frame("hurt", "right_02", (849, 665, 978, 791), (918, 783), ("hurt", "left_00")),
    Frame("death", "right_00", (580, 797, 693, 928), (638, 920)),
    Frame("death", "right_01", (704, 797, 837, 928), (775, 920)),
    Frame("death", "right_02", (839, 811, 978, 928), (911, 920)),
    Frame("death", "right_03", (974, 824, 1122, 928), (1057, 920)),
]

EFFECTS = {
    "magic_circle_00": (1232, 238, 1496, 361),
    "orb_00": (1233, 380, 1267, 438),
    "orb_01": (1270, 374, 1339, 444),
    "orb_02": (1332, 365, 1410, 451),
    "orb_03": (1401, 356, 1507, 459),
    "ice_00": (1235, 483, 1310, 555),
    "ice_01": (1305, 466, 1405, 558),
    "ice_02": (1410, 457, 1504, 558),
    "explosion_00": (1224, 688, 1344, 770),
    "explosion_01": (1340, 673, 1504, 770),
}


def transparent_crop(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    image = source.crop(box).convert("RGBA")
    data = np.asarray(image).copy()
    border = np.concatenate((data[0, :, :3], data[-1, :, :3], data[:, 0, :3], data[:, -1, :3]))
    background = np.median(border.astype(np.float32), axis=0)
    distance = np.linalg.norm(data[:, :, :3].astype(np.float32) - background, axis=2)
    alpha = np.clip((distance - 22.0) / 34.0 * 255.0, 0.0, 255.0).astype(np.uint8)
    data[:, :, 3] = alpha
    return clean_border_artifacts(Image.fromarray(data, "RGBA"))


def clean_border_artifacts(image: Image.Image) -> Image.Image:
    data = np.asarray(image).copy()
    mask = data[:, :, 3] > 20
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    for start_y in range(height):
        for start_x in range(width):
            if not mask[start_y, start_x] or visited[start_y, start_x]:
                continue
            queue = deque([(start_x, start_y)])
            visited[start_y, start_x] = True
            component: list[tuple[int, int]] = []
            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for offset_y in (-1, 0, 1):
                    for offset_x in (-1, 0, 1):
                        if offset_x == 0 and offset_y == 0:
                            continue
                        next_x, next_y = x + offset_x, y + offset_y
                        if 0 <= next_x < width and 0 <= next_y < height and mask[next_y, next_x] and not visited[next_y, next_x]:
                            visited[next_y, next_x] = True
                            queue.append((next_x, next_y))
            xs = [point[0] for point in component]
            ys = [point[1] for point in component]
            component_width = max(xs) - min(xs) + 1
            component_height = max(ys) - min(ys) + 1
            line_fragment = (component_width > component_height * 5 and component_height <= 10) or (component_height > component_width * 5 and component_width <= 10)
            if line_fragment:
                for x, y in component:
                    data[y, x, 3] = 0
    return Image.fromarray(data, "RGBA")


def trim(image: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("El recorte quedó completamente transparente")
    return image.crop(bounds), bounds


def normalize_frame(source: Image.Image, frame: Frame) -> Image.Image:
    extracted = transparent_crop(source, frame.box)
    extracted, bounds = trim(extracted)
    scaled_size = (max(1, round(extracted.width * SCALE)), max(1, round(extracted.height * SCALE)))
    extracted = extracted.resize(scaled_size, Image.Resampling.NEAREST)
    anchor_x = round((frame.anchor[0] - frame.box[0] - bounds[0]) * SCALE)
    anchor_y = round((frame.anchor[1] - frame.box[1] - bounds[1]) * SCALE)
    destination = (COMBAT_FEET[0] - anchor_x, COMBAT_FEET[1] - anchor_y)
    canvas = Image.new("RGBA", COMBAT_CANVAS, (0, 0, 0, 0))
    canvas.alpha_composite(extracted, destination)
    return canvas


def extract_portraits(source: Image.Image) -> None:
    portrait_folder = MAGE_ROOT / "portraits"
    portrait_folder.mkdir(parents=True, exist_ok=True)
    small, _ = trim(transparent_crop(source, (414, 76, 527, 195)))
    large, _ = trim(transparent_crop(source, (72, 54, 345, 350)))
    full_body, _ = trim(transparent_crop(source, (12, 443, 371, 990)))
    small.save(portrait_folder / "portrait_small.png", optimize=True)
    large.save(portrait_folder / "portrait_large.png", optimize=True)
    full_body.save(portrait_folder / "full_body.png", optimize=True)
    CLASS_PORTRAITS.mkdir(parents=True, exist_ok=True)
    shutil.copy2(portrait_folder / "portrait_small.png", CLASS_PORTRAITS / "portrait_human_mage.png")


def extract_frames(source: Image.Image) -> None:
    for frame in FRAMES:
        target_folder = MAGE_ROOT / frame.folder
        target_folder.mkdir(parents=True, exist_ok=True)
        normalized = normalize_frame(source, frame)
        normalized.save(target_folder / f"{frame.name}.png", optimize=True)
        if frame.mirror_to is not None:
            mirror_folder, mirror_name = frame.mirror_to
            target = MAGE_ROOT / mirror_folder
            target.mkdir(parents=True, exist_ok=True)
            ImageOps.mirror(normalized).save(target / f"{mirror_name}.png", optimize=True)
    shutil.copy2(MAGE_ROOT / "idle/front_00.png", MAGE_ROOT / "walk/front_00.png")
    shutil.copy2(MAGE_ROOT / "idle/back_00.png", MAGE_ROOT / "walk/back_00.png")


def extract_effects(source: Image.Image) -> None:
    target_folder = MAGE_ROOT / "effects"
    target_folder.mkdir(parents=True, exist_ok=True)
    for name, box in EFFECTS.items():
        effect = transparent_crop(source, box)
        data = np.asarray(effect).copy()
        red, green, blue = data[:, :, 0], data[:, :, 1], data[:, :, 2]
        gold = (red > 90) & (red > blue * 1.35) & (green > blue * 1.05)
        data[gold, 3] = 0
        effect, _ = trim(clean_border_artifacts(Image.fromarray(data, "RGBA")))
        effect.save(target_folder / f"{name}.png", optimize=True)


def main() -> None:
    source = Image.open(SOURCE)
    if source.size != EXPECTED_SIZE:
        raise ValueError(f"La hoja cambió de tamaño: {source.size} != {EXPECTED_SIZE}")
    extract_portraits(source)
    extract_frames(source)
    extract_effects(source)
    print("Retratos, animaciones y efectos del mago extraídos correctamente.")


if __name__ == "__main__":
    main()
