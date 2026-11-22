"""Rasterize authored 2D poses into six registered PNG atlases and review sheets."""

from __future__ import annotations

import argparse
import json
import math
from functools import cache
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/characters/warrior/modular"
DIRECTIONS = ("front", "right", "back", "left")
ITEMS = ("iron_boots", "iron_armor", "iron_helmet", "iron_sword", "iron_shield")
SIZE = 96
GROUND = (48, 86)
INK = "#211c2a"
STEEL = ("#394252", "#65788d", "#9bafbd", "#dbe6de")
SKIN = ("#804938", "#bc7757", "#e4a77a", "#f1c597")
CLOTH = ("#492a37", "#773847", "#a45456", "#c97467")
LEATHER = ("#342733", "#524047", "#765451", "#986b5b")

# Body shift (x,y), weapon swing, shield raise, stride, and fall angle.
POSES = {
    "idle": [(0, 0, 0, 0, 0, 0), (0, -1, 1, 0, 0, 0), (0, -2, -1, 1, 0, 0)],
    "walk": [(0, 0, -3, 2, 8, 0), (0, -2, -1, 1, 4, 0), (0, -3, 0, 0, 1, 0),
             (0, 0, 3, 2, -8, 0), (0, -2, 1, 1, -4, 0), (0, -3, 2, 1, -1, 0)],
    "attack": [(-3, 1, -10, 1, -3, 0), (-2, -3, -17, 5, -4, 0),
               (6, 1, 19, 7, 6, 0), (3, 2, 9, 3, 3, 0)],
    "hurt": [(-4, 2, -5, 4, -3, 0), (-2, 1, -2, 2, -1, 0)],
    "death": [(-2, 3, -3, 1, -3, 8), (-1, 6, -3, 3, -4, 26),
              (-1, 7, 0, 1, -3, 54), (0, 7, 0, 0, -3, 80)],
}


def blank(size=(SIZE, SIZE)):
    return Image.new("RGBA", size)


def polygon(draw, points, fill, outline=None):
    draw.polygon([(round(x), round(y)) for x, y in points], fill=fill, outline=outline)


def shape(draw, center, points, fill, outline=None, angle=0):
    co, si = math.cos(angle), math.sin(angle)
    x, y = center
    polygon(draw, [(x + a * co - b * si, y + a * si + b * co) for a, b in points], fill, outline)


def limb(draw, start, end, width, palette):
    draw.line([start, end], fill=INK, width=width)
    draw.line([start, end], fill=palette[1], width=width - 2)
    x, y = start
    a, b = end
    draw.line([(x - 1, y), (a - 1, b - 1)], fill=palette[2], width=2)


def foot(draw, center, facing, armored):
    palette = STEEL if armored else LEATHER
    toe = {"right": 4, "left": -4}.get(facing, 0)
    shape(draw, center, [(-4, -8), (3, -8), (toe + 4, -3), (toe + 4, 0),
                         (toe - 4, 0), (-5, -2)], palette[1], INK)
    shape(draw, center, [(-3, -7), (2, -7), (toe + 2, -4), (toe - 2, -4)], palette[2])
    if armored:
        shape(draw, center, [(toe - 2, -3), (toe + 2, -3), (toe + 2, -2), (toe - 2, -2)], palette[3])


@cache
def head(facing):
    source = Image.open(OUTPUT.parent / "warrior_turnaround_source.png").convert("RGBA")
    column = DIRECTIONS.index(facing)
    cell = source.crop((column * source.width // 4, 0, (column + 1) * source.width // 4,
                        round(source.height * 0.247)))
    cell.putalpha(cell.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0))
    cell = cell.crop(cell.getbbox())
    cell = cell.resize((21, 23), Image.Resampling.NEAREST)
    return cell


def helmet(draw, center, facing):
    side = {"right": 1, "left": -1}.get(facing, 0)
    shape(draw, center, [(-11,-6),(-8,-12),(-3,-15),(5,-14),(10,-10),(12,-5),
                         (10,7),(5,8),(7,0),(-7,0),(-6,8),(-10,6)], STEEL[1], INK)
    shape(draw, center, [(-8,-7),(-6,-11),(-2,-13),(5,-12),(8,-9),(3,-9),(-4,-6)], STEEL[2])
    shape(draw, center, [(-5,-10),(-2,-12),(1,-12),(-1,-10)], STEEL[3])
    if facing == "back":
        shape(draw, center, [(-9,-2),(9,-2),(8,6),(5,9),(-6,9),(-9,5)], STEEL[0], INK)
        shape(draw, center, [(-7,3),(7,3),(6,6),(-6,6)], STEEL[1])
    elif side:
        shape(draw, center, [(side*6,-4),(side*11,-4),(side*10,2),(side*6,4)], STEEL[0], INK)
    else:
        shape(draw, center, [(-2,-2),(2,-2),(2,4),(0,6),(-2,4)], STEEL[2], INK)


def chest(draw, center, facing, armored):
    wide = 10 if facing in ("left", "right") else 14
    palette = STEEL if armored else CLOTH
    shape(draw, center, [(-wide,2),(-wide+3,-5),(wide-3,-5),(wide,2),
                         (wide-4,18),(-wide+4,18)], palette[1], INK)
    shape(draw, center, [(-wide+3,0),(wide-3,0),(wide-6,8),(-wide+5,10)], palette[2])
    shape(draw, center, [(-wide+5,13),(wide-5,12),(wide-5,16),(-wide+5,16)], palette[0])
    if armored:
        shape(draw, center, [(-wide+1,1),(-wide+4,-3),(-wide+7,-2),(-wide+6,3)], STEEL[3])
        if facing != "back":
            shape(draw, center, [(-4,4),(0,2),(4,4),(0,8)], STEEL[3])
        else:
            shape(draw, center, [(-4,0),(-2,0),(3,12),(1,12)], STEEL[0])
    elif facing != "back":
        shape(draw, center, [(-3,13),(3,13),(3,16),(-3,16)], "#b38a5f", INK)


def sword(draw, grip, angle):
    shape(draw, grip, [(-2,-8),(2,-8),(2,5),(0,7),(-2,5)], "#96704e", INK, angle)
    shape(draw, grip, [(-2,-6),(-3,-23),(0,-29),(3,-25),(3,-6)], STEEL[2], INK, angle)
    shape(draw, grip, [(0,-8),(0,-27),(2,-23),(2,-9)], STEEL[3], angle=angle)
    shape(draw, grip, [(-6,-8),(6,-8),(5,-5),(-5,-5)], "#c19758", INK, angle)


def shield(draw, grip, facing, angle):
    width = 8 if facing in ("left", "right") else 11
    shape(draw, grip, [(-width,-10),(0,-14),(width,-10),(width-1,4),(4,10),
                       (0,13),(-4,10),(-width+1,4)], STEEL[2], INK, angle)
    shape(draw, grip, [(-width+3,-8),(0,-11),(width-3,-8),(width-3,3),
                       (0,9),(-width+3,3)], "#3d556e", angle=angle)
    shape(draw, grip, [(0,-5),(4,-1),(0,3),(-4,-1)], "#d4b076", angle=angle)


def arm(draw, start, end):
    elbow = (round((start[0] + end[0]) / 2), round((start[1] + end[1]) / 2) + 2)
    limb(draw, start, elbow, 9, SKIN)
    limb(draw, elbow, end, 8, SKIN)
    shape(draw, end, [(-3,-3),(2,-3),(3,-1),(2,3),(-2,3),(-3,1)], SKIN[2], INK)


def pose(facing, state, frame):
    dx, dy, swing, guard, stride, fall = POSES[state][frame]
    side = {"right": 1, "left": -1}.get(facing, 0)
    reverse = -1 if facing in ("back", "left") else 1
    body_x = 48 + dx * (side or reverse)
    body_y = 53 + dy
    head_at = (body_x + side * 2, body_y - 15)
    torso = (body_x, body_y)
    shoulder_w = 7 if side else 12
    weapon_x = -reverse * shoulder_w if side else reverse * shoulder_w
    shield_x = -weapon_x
    weapon_shoulder = (body_x + weapon_x, body_y + 1)
    shield_shoulder = (body_x + shield_x, body_y + 3)
    if side:
        grip = (body_x + weapon_x + side * (5 + swing), body_y + 15 - abs(swing)//2)
        brace = (body_x + shield_x + side * (3 + guard), body_y + 14 - guard)
    else:
        grip = (body_x + weapon_x + reverse * (4 + swing//3), body_y + 15 - abs(swing)//2)
        brace = (body_x + shield_x - reverse * 4, body_y + 14 - guard)
    widening = abs(stride) // 4
    feet = [(42 - widening, 85 - max(0, -stride)//2), (54 + widening, 85 - max(0, stride)//2)]
    if side:
        feet = [(46 - stride * side, 82), (50 + stride * side, 85)]
    sword_angle = reverse * (0.67 + swing * 0.085)
    if state == "attack" and frame == 1:
        sword_angle = reverse * -0.7
    elif state == "attack" and frame == 2:
        sword_angle = reverse * 2.6
    elif state == "attack" and frame == 3:
        sword_angle = reverse * 0.85
    layers = {name: blank() for name in ("body", *ITEMS)}
    draw = ImageDraw.Draw(layers["body"])
    for index, endpoint in enumerate(feet):
        hip = (body_x + (-5 if index == 0 else 5), body_y + 14)
        ankle = (endpoint[0], endpoint[1] - 4)
        limb(draw, hip, ankle, 10, LEATHER)
        foot(draw, endpoint, facing, False)
        foot(ImageDraw.Draw(layers["iron_boots"]), endpoint, facing, True)
    arm(draw, shield_shoulder, brace)
    if not side:
        arm(draw, weapon_shoulder, grip)
    shape(draw, head_at, [(-4,7),(4,7),(4,12),(-4,12)], SKIN[1], INK)
    chest(draw, torso, facing, False)
    chest(ImageDraw.Draw(layers["iron_armor"]), torso, facing, True)
    if side:
        near_arm = blank()
        arm(ImageDraw.Draw(near_arm), weapon_shoulder, grip)
        layers["body"].alpha_composite(near_arm)
        armor = layers["iron_armor"]
        armor.putalpha(ImageChops.subtract(armor.getchannel("A"), near_arm.getchannel("A")))
    layers["body"].alpha_composite(head(facing), (head_at[0] - 10, head_at[1] - 13))
    helmet(ImageDraw.Draw(layers["iron_helmet"]), head_at, facing)
    sword(ImageDraw.Draw(layers["iron_sword"]), grip, sword_angle)
    shield(ImageDraw.Draw(layers["iron_shield"]), brace, facing, reverse * (guard - 1) * 0.044)
    anchors = {"head": head_at, "torso": torso, "main_hand": grip,
               "off_hand": brace, "foot_a": feet[0], "foot_b": feet[1]}
    if fall:
        pivot = (48, 63)
        angle = reverse * fall
        co, si = math.cos(math.radians(angle)), math.sin(math.radians(angle))
        def rotated(point):
            x, y = point[0] - pivot[0], point[1] - pivot[1]
            return (round(pivot[0] + x*co + y*si), round(pivot[1] - x*si + y*co))
        extent = layers["body"].rotate(angle, center=pivot).getbbox()
        # Keep the falling silhouette above the ground. Translate all its pieces together.
        shift_y = GROUND[1] - extent[3]
        for name, layer in layers.items():
            tile = blank()
            tile.alpha_composite(layer.rotate(angle, center=pivot), (0, shift_y))
            layers[name] = tile
        anchors = {name: (x, y + shift_y) for name, point in anchors.items() for x, y in (rotated(point),)}
    return layers, anchors


def build(frame_directory=None):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    review = ROOT / "artifacts/warrior"
    review.mkdir(parents=True, exist_ok=True)
    atlases = {name: blank((SIZE * len(DIRECTIONS), SIZE * sum(map(len, POSES.values()))))
               for name in ("body", *ITEMS)}
    comparison = Image.new("RGBA", (SIZE * 4, SIZE * 2), "#354359")
    motion_sheet = Image.new("RGBA", atlases["body"].size, "#354359")
    anchor_file = {}
    row = 0
    for state, frames in POSES.items():
        seen = {direction: set() for direction in DIRECTIONS}
        for frame in range(len(frames)):
            for column, direction in enumerate(DIRECTIONS):
                layers, anchors = pose(direction, state, frame)
                signature = layers["body"].tobytes()
                assert signature not in seen[direction], (state, direction, frame)
                seen[direction].add(signature)
                anchor_file[f"{state}_{direction}:{frame}"] = anchors
                for name, layer in layers.items():
                    bounds = layer.getbbox()
                    assert bounds and min(bounds[:2]) > 0 and max(bounds[2:]) < SIZE, (name, state, direction, frame, bounds)
                    atlases[name].paste(layer, (column * SIZE, row * SIZE))
                    if frame_directory is not None:
                        target = frame_directory / name / state
                        target.mkdir(parents=True, exist_ok=True)
                        layer.save(target / f"{direction}_{frame:02d}.png", optimize=True)
                behind = []
                if (direction in ("left", "back") and (state, direction, frame) != ("attack", "left", 2)
                        and (state, direction) != ("death", "left")):
                    behind.append("iron_shield")
                if (direction == "back" and (state, frame) != ("attack", 2)) or (state, direction) == ("death", "right"):
                    behind.append("iron_sword")
                for name in behind + ["body"] + [item for item in ITEMS if item not in behind]:
                    motion_sheet.alpha_composite(layers[name], (column * SIZE, row * SIZE))
                if row == 0:
                    comparison.alpha_composite(layers["body"], (column * SIZE, 0))
            row += 1
    for name, atlas in atlases.items():
        atlas.save(OUTPUT / f"{name}.png", optimize=True)
    (OUTPUT / "anchors.json").write_text(json.dumps(anchor_file, separators=(",", ":")) + "\n", encoding="utf-8")
    comparison.paste(motion_sheet.crop((0, 0, SIZE * 4, SIZE)), (0, SIZE))
    comparison.resize((SIZE * 12, SIZE * 6), Image.Resampling.NEAREST).save(review / "comparacion.png")
    panel = Image.new("RGBA", (SIZE * 8, SIZE * 10), "#354359")
    panel.paste(motion_sheet.crop((0, 0, SIZE * 4, SIZE * 10)), (0, 0))
    panel.paste(motion_sheet.crop((0, SIZE * 10, SIZE * 4, SIZE * 19)), (SIZE * 4, 0))
    panel.save(review / "animaciones.png")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frames", type=Path, help="Also export individual transparent PNG frames")
    build(parser.parse_args().frames)
