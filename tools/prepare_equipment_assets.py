"""Extract base bodies and generate original provisional equipment layers.

The supplied image is a composition, not an atlas. Portrait rectangles are
explicitly excluded and low-alpha/bright fringe noise is removed. Equipment is
drawn as separate transparent pixel-art layers for the static preview and the
96x96 combat canvas; it never gets baked into the character image.
"""

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "characters" / "base" / "base_characters.png"
BASE_OUT = SOURCE.parent / "extracted"
ITEM_OUT = ROOT / "assets" / "equipment"
EXPECTED_SIZE = (1672, 941)

BODY_CROPS = {
    "warrior": (0, 70, 330, 880),
    "mage": (335, 105, 680, 880),
    "archer": (675, 70, 1015, 880),
    "acolyte": (1025, 100, 1335, 880),
    "explorer": (1325, 100, 1672, 885),
}

PORTRAITS = [
    (205, 40, 345, 190), (540, 40, 680, 190), (870, 40, 1010, 190),
    (1200, 40, 1340, 190), (1515, 40, 1672, 190),
]

# id: body model, slot, primary colour, secondary colour, visual motif
ITEMS = {
    "iron_sword": ("warrior", "main_hand", "#d7dce0", "#6e7680", "sword"),
    "wooden_shield": ("warrior", "off_hand", "#9a6338", "#d1a05f", "shield"),
    "leather_helmet": ("warrior", "head", "#7a4c31", "#bd8250", "helmet"),
    "leather_armor": ("warrior", "torso", "#7a4c31", "#b97846", "armor"),
    "leather_boots": ("warrior", "feet", "#65402c", "#9b6845", "boots"),
    "apprentice_staff": ("mage", "main_hand", "#745132", "#76d5ff", "staff"),
    "arcane_robe": ("mage", "torso", "#51408f", "#9f83df", "robe"),
    "cloth_hood": ("mage", "head", "#554590", "#a78de1", "hood"),
    "cloth_gloves": ("mage", "hands", "#6b5aa2", "#cab9ec", "gloves"),
    "apprentice_sandals": ("mage", "feet", "#76523b", "#b9885d", "sandals"),
    "wooden_bow": ("archer", "main_hand", "#9d6a36", "#e4c47b", "bow"),
    "leather_vest": ("archer", "torso", "#6f4b31", "#9f744d", "vest"),
    "archer_gloves": ("archer", "hands", "#62432f", "#a77751", "gloves"),
    "light_boots": ("archer", "feet", "#5d4936", "#958063", "boots"),
    "ceremonial_staff": ("acolyte", "main_hand", "#c5ad72", "#fff0a6", "staff"),
    "healer_robe": ("acolyte", "torso", "#e8e5d5", "#8fc4b4", "robe"),
    "white_hood": ("acolyte", "head", "#eeeadd", "#a8d2c4", "hood"),
    "cloth_boots": ("acolyte", "feet", "#d7d0be", "#8eaa9f", "boots"),
    "iron_daggers": ("explorer", "main_hand", "#cbd1d5", "#59616b", "daggers"),
    "light_armor": ("explorer", "torso", "#3e4c4d", "#778a7b", "armor"),
    "dark_hood": ("explorer", "head", "#30383f", "#6b747b", "hood"),
    "explorer_boots": ("explorer", "feet", "#493a32", "#77604d", "boots"),
}


def clean_source() -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    if source.size != EXPECTED_SIZE:
        raise RuntimeError(f"Unexpected source size {source.size}; expected {EXPECTED_SIZE}")
    data = np.array(source, dtype=np.uint8)
    for left, top, right, bottom in PORTRAITS:
        data[top:bottom, left:right] = 0
    alpha = data[:, :, 3]
    rgb = data[:, :, :3]
    artifact = (
        ((rgb[:, :, 0] > 220) & (rgb[:, :, 1] < 55) & (rgb[:, :, 2] < 55))
        | ((rgb[:, :, 1] > 220) & (rgb[:, :, 0] < 70) & (rgb[:, :, 2] < 70))
        | ((rgb[:, :, 2] > 220) & (rgb[:, :, 0] < 70) & (rgb[:, :, 1] < 70))
    )
    keep = (alpha >= 64) & ~artifact
    data[:, :, 3] = np.where(keep, 255, 0).astype(np.uint8)
    data[~keep, :3] = 0
    return Image.fromarray(data)


def extract_bodies() -> None:
    BASE_OUT.mkdir(parents=True, exist_ok=True)
    source = clean_source()
    for body_id, crop_box in BODY_CROPS.items():
        crop = source.crop(crop_box)
        bbox = crop.getbbox()
        if bbox is None:
            raise RuntimeError(f"Empty body crop: {body_id}")
        crop = crop.crop(bbox)
        scale = min(240 / crop.width, 374 / crop.height)
        size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
        crop = crop.resize(size, Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (256, 384), (0, 0, 0, 0))
        canvas.alpha_composite(crop, ((256 - size[0]) // 2, 380 - size[1]))
        canvas.save(BASE_OUT / f"base_{body_id}.png", optimize=True)
        print(f"base_{body_id}.png: source {bbox}, normalized {canvas.size}")


def colours(primary: str, secondary: str) -> tuple[str, str, str]:
    return primary, secondary, "#25262b"


PREVIEW_ANCHORS = {
    "warrior": {"feet": (69, 190), "weapon_x": 198, "shield_x": 68},
    "mage": {"feet": (105, 148), "weapon_x": 193, "shield_x": 68},
    "archer": {"feet": (91, 172), "weapon_x": 199, "shield_x": 68},
    "acolyte": {"feet": (111, 145), "weapon_x": 194, "shield_x": 68},
    "explorer": {"feet": (101, 168), "weapon_x": 207, "shield_x": 68},
}


def draw_layer(size: tuple[int, int], body: str, slot: str, primary: str, secondary: str, motif: str) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    p, s, outline = colours(primary, secondary)
    if size == (256, 384):
        anchors = PREVIEW_ANCHORS[body]
        left_foot, right_foot = anchors["feet"]
        weapon_x = anchors["weapon_x"]
        feet_y = 354
        if slot == "head":
            # Crown plus side guards: the face remains visible instead of being
            # covered by a rectangular icon-like shape.
            draw.polygon([(91, 41), (99, 19), (128, 8), (157, 19), (165, 41), (151, 34), (105, 34)], fill=outline)
            draw.polygon([(97, 37), (104, 24), (128, 14), (152, 24), (159, 37), (148, 30), (108, 30)], fill=p)
            draw.polygon([(91, 38), (107, 35), (105, 67), (95, 75)], fill=outline)
            draw.polygon([(165, 38), (149, 35), (151, 67), (161, 75)], fill=outline)
            draw.polygon([(96, 40), (103, 39), (101, 63), (98, 67)], fill=p)
            draw.polygon([(160, 40), (153, 39), (155, 63), (158, 67)], fill=p)
            draw.line([(105, 30), (151, 30)], fill=s, width=4)
        elif slot == "torso":
            draw.polygon([(91, 107), (108, 91), (148, 91), (165, 107), (155, 204), (101, 204)], fill=outline)
            draw.polygon([(97, 110), (111, 98), (145, 98), (159, 110), (150, 197), (106, 197)], fill=p)
            draw.line([(128, 99), (128, 194)], fill=s, width=4)
            draw.line([(105, 145), (151, 145)], fill=s, width=4)
        elif slot == "hands":
            for x in (69, 177):
                draw.rounded_rectangle((x - 12, 151, x + 12, 192), radius=6, fill=outline)
                draw.rounded_rectangle((x - 8, 155, x + 8, 188), radius=5, fill=p)
        elif slot == "feet":
            for x in (left_foot, right_foot):
                draw.rounded_rectangle((x - 15, feet_y - 29, x + 15, feet_y + 20), radius=7, fill=outline)
                draw.rounded_rectangle((x - 10, feet_y - 24, x + 10, feet_y + 15), radius=5, fill=p)
                draw.line([(x - 8, feet_y - 7), (x + 8, feet_y - 7)], fill=s, width=4)
        elif slot == "main_hand":
            if motif in ("staff",):
                draw.line([(weapon_x, 86), (weapon_x - 12, 345)], fill=outline, width=10)
                draw.line([(weapon_x, 86), (weapon_x - 12, 345)], fill=p, width=5)
                draw.ellipse((weapon_x - 16, 55, weapon_x + 16, 87), fill=outline)
                draw.ellipse((weapon_x - 10, 61, weapon_x + 10, 81), fill=s)
            elif motif == "bow":
                draw.arc((157, 80, 234, 310), 80, 280, fill=outline, width=10)
                draw.arc((161, 84, 230, 306), 80, 280, fill=p, width=5)
                draw.line([(194, 92), (194, 298)], fill=s, width=3)
            elif motif == "daggers":
                for dx in (0, 26):
                    draw.polygon([(177 + dx, 162), (188 + dx, 145), (193 + dx, 205), (183 + dx, 215)], fill=outline)
                    draw.polygon([(181 + dx, 162), (187 + dx, 153), (189 + dx, 201), (185 + dx, 207)], fill=p)
            else:
                draw.polygon([(178, 270), (188, 102), (199, 91), (198, 270), (190, 303)], fill=outline)
                draw.polygon([(184, 265), (191, 109), (195, 103), (193, 265)], fill=p)
                draw.rectangle((176, 263, 204, 272), fill=s)
        elif slot == "off_hand":
            sx = anchors["shield_x"]
            draw.polygon([(sx - 28, 132), (sx + 9, 114), (sx + 37, 138), (sx + 30, 227), (sx + 2, 252), (sx - 25, 222)], fill=outline)
            draw.polygon([(sx - 21, 138), (sx + 8, 123), (sx + 30, 142), (sx + 24, 220), (sx + 2, 242), (sx - 18, 217)], fill=p)
            draw.line([(sx + 6, 127), (sx + 3, 238)], fill=s, width=5)
    else:
        # 96x96 combat layer, aligned to the existing normalized sprite canvas.
        if slot == "head":
            draw.polygon([(31, 35), (35, 17), (48, 11), (61, 17), (65, 35), (57, 29), (39, 29)], fill=outline)
            draw.polygon([(34, 33), (38, 20), (48, 15), (58, 20), (62, 33), (55, 26), (41, 26)], fill=p)
        elif slot == "torso":
            draw.polygon([(31, 40), (39, 34), (57, 34), (65, 40), (61, 68), (35, 68)], fill=outline)
            draw.polygon([(34, 42), (40, 37), (56, 37), (62, 42), (58, 65), (38, 65)], fill=p)
            draw.line([(38, 52), (58, 52)], fill=s, width=2)
        elif slot == "hands":
            draw.rectangle((26, 50, 33, 65), fill=outline); draw.rectangle((28, 52, 31, 63), fill=p)
            draw.rectangle((63, 50, 70, 65), fill=outline); draw.rectangle((65, 52, 68, 63), fill=p)
        elif slot == "feet":
            draw.rectangle((34, 73, 45, 86), fill=outline); draw.rectangle((36, 75, 43, 84), fill=p)
            draw.rectangle((51, 73, 62, 86), fill=outline); draw.rectangle((53, 75, 60, 84), fill=p)
        elif slot == "main_hand":
            if motif == "staff":
                draw.line([(70, 26), (67, 85)], fill=outline, width=5); draw.line([(70, 26), (67, 85)], fill=p, width=2)
                draw.ellipse((65, 18, 75, 28), fill=s)
            elif motif == "bow":
                draw.arc((59, 30, 82, 82), 75, 285, fill=p, width=3); draw.line([(71, 33), (71, 79)], fill=s, width=1)
            elif motif == "daggers":
                draw.line([(68, 48), (74, 70)], fill=p, width=4); draw.line([(76, 48), (82, 70)], fill=p, width=4)
            else:
                draw.polygon([(67, 74), (70, 30), (74, 27), (73, 75)], fill=outline)
                draw.line([(71, 31), (70, 72)], fill=p, width=2); draw.line([(65, 72), (77, 72)], fill=s, width=3)
        elif slot == "off_hand":
            draw.polygon([(20, 44), (32, 38), (41, 45), (39, 69), (30, 77), (21, 68)], fill=outline)
            draw.polygon([(23, 46), (31, 42), (38, 47), (36, 66), (30, 72), (24, 66)], fill=p)
    return image


def draw_icon(body: str, slot: str, primary: str, secondary: str, motif: str) -> Image.Image:
    layer = draw_layer((96, 96), body, slot, primary, secondary, motif)
    bbox = layer.getbbox()
    icon = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
    if bbox:
        piece = layer.crop(bbox)
        scale = min(34 / piece.width, 34 / piece.height)
        piece = piece.resize((max(1, round(piece.width * scale)), max(1, round(piece.height * scale))), Image.Resampling.NEAREST)
        icon.alpha_composite(piece, ((40 - piece.width) // 2, (40 - piece.height) // 2))
    return icon


def generate_equipment() -> None:
    for folder in (ITEM_OUT / "icons", ITEM_OUT / "preview", ITEM_OUT / "combat"):
        folder.mkdir(parents=True, exist_ok=True)
    for item_id, (body, slot, primary, secondary, motif) in ITEMS.items():
        draw_icon(body, slot, primary, secondary, motif).save(ITEM_OUT / "icons" / f"{item_id}.png", optimize=True)
        draw_layer((256, 384), body, slot, primary, secondary, motif).save(ITEM_OUT / "preview" / f"{item_id}.png", optimize=True)
        draw_layer((96, 96), body, slot, primary, secondary, motif).save(ITEM_OUT / "combat" / f"{item_id}.png", optimize=True)
        print(f"equipment {item_id}: {slot}")


def main() -> None:
    extract_bodies()
    generate_equipment()


if __name__ == "__main__":
    main()
