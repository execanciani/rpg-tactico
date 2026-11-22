"""Normaliza todos los iconos referenciados por el catalogo a 64x64 RGBA.

No altera definiciones ni balance. Los PNG de origen se conservan; las copias
de Fase 5 se recortan por alfa, se centran, reciben un contorno limpio y se
guardan sin marco de rareza para que la interfaz dibuje sus estados.
"""

import hashlib
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/items/icons/fase5"
RESOURCE_DIRS = [ROOT / "data/equipment", ROOT / "data/items"]
ID_PATTERN = re.compile(r'^item_id = "([^"]+)"', re.MULTILINE)
ICON_PATTERN = re.compile(r'\[ext_resource type="Texture2D" path="([^"]+)" id="2"\]')
CATEGORY_PATTERN = re.compile(r'^category = "([^"]+)"', re.MULTILINE)


def definitions() -> list[tuple[str, str, Path, Path]]:
    result: list[tuple[str, str, Path, Path]] = []
    for folder in RESOURCE_DIRS:
        for resource in sorted(folder.glob("*.tres")):
            text = resource.read_text(encoding="utf-8")
            item_match = ID_PATTERN.search(text)
            icon_match = ICON_PATTERN.search(text)
            category_match = CATEGORY_PATTERN.search(text)
            if not item_match or not icon_match or not category_match:
                raise RuntimeError(f"Definicion sin item_id o icon id=2: {resource}")
            source = ROOT / icon_match.group(1).replace("res://", "")
            if not source.exists():
                raise RuntimeError(f"Icono inexistente para {item_match.group(1)}: {source}")
            result.append((item_match.group(1), category_match.group(1), resource, source))
    return result


def largest_alpha_component(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    # Eliminar ruido aislado muy pequeno sin tocar huecos internos del objeto.
    mask = alpha.point(lambda value: 255 if value >= 24 else 0)
    bbox = mask.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def normalize(source: Path, tint_seed: int = 0) -> Image.Image:
    original = Image.open(source).convert("RGBA")
    piece = largest_alpha_component(original)
    scale = min(50 / piece.width, 50 / piece.height)
    size = (max(1, round(piece.width * scale)), max(1, round(piece.height * scale)))
    piece = piece.resize(size, Image.Resampling.NEAREST)
    alpha = piece.getchannel("A").point(lambda value: 255 if value >= 72 else 0)
    piece.putalpha(alpha)
    if tint_seed:
        # Solo se aplica a fuentes duplicadas para que cada definicion conserve
        # una lectura propia sin inventar un marco o texto.
        hue_shift = 0.88 + (tint_seed % 9) * 0.025
        rgb = ImageEnhance.Color(piece.convert("RGB")).enhance(hue_shift)
        piece = rgb.convert("RGBA")
        piece.putalpha(alpha)
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    x = (64 - piece.width) // 2
    y = (64 - piece.height) // 2
    placed_alpha = Image.new("L", (64, 64), 0)
    placed_alpha.paste(alpha, (x, y))
    outline = placed_alpha.filter(ImageFilter.MaxFilter(5))
    outline = ImageChops.subtract(outline, placed_alpha)
    border = Image.new("RGBA", (64, 64), (25, 20, 25, 0))
    border.putalpha(outline)
    canvas.alpha_composite(border)
    canvas.alpha_composite(piece, (x, y))
    return canvas


def palette(item_id: str) -> tuple[str, str, str]:
    if "iron" in item_id:
        return "#d4dde2", "#71808b", "#262a31"
    if item_id.startswith(("white", "healer", "cloth_boots")):
        return "#eee9d8", "#8fb5b2", "#2d3640"
    if item_id.startswith(("cloth", "apprentice", "arcane")):
        return "#8e78c8", "#4b3f79", "#242034"
    if item_id.startswith(("dark", "explorer", "light")):
        return "#74877c", "#3d4b49", "#20272a"
    if item_id.startswith("ceremonial"):
        return "#f1d47e", "#9b7441", "#302718"
    return "#b77a46", "#67412d", "#2b1f20"


def draw_motif(item_id: str, category: str) -> Image.Image | None:
    if category not in {"boots", "sandals", "gloves", "staff", "bow"}:
        return None
    image = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    light, base, outline = palette(item_id)
    if category == "boots":
        for x, mirror in ((4, False), (18, True)):
            draw.rectangle((x, 6, x + 8, 20), fill=outline)
            draw.rectangle((x + 2, 8, x + 6, 19), fill=base)
            if mirror:
                draw.polygon([(x, 18), (x + 7, 18), (x + 11, 25), (x + 9, 28), (x, 28)], fill=outline)
                draw.polygon([(x + 2, 20), (x + 6, 20), (x + 9, 25), (x + 8, 26), (x + 2, 26)], fill=base)
            else:
                draw.polygon([(x + 1, 18), (x + 8, 18), (x + 8, 28), (x - 1, 28), (x - 3, 25)], fill=outline)
                draw.polygon([(x + 2, 20), (x + 6, 20), (x + 6, 26), (x, 26), (x - 1, 25)], fill=base)
            draw.line((x + 2, 11, x + 6, 11), fill=light, width=1)
            draw.line((x + 2, 15, x + 6, 15), fill=light, width=1)
    elif category == "sandals":
        draw.polygon([(4, 9), (12, 9), (14, 25), (10, 29), (3, 27)], fill=outline)
        draw.polygon([(6, 11), (10, 11), (12, 24), (9, 27), (5, 25)], fill=base)
        draw.polygon([(19, 9), (27, 9), (29, 27), (22, 29), (18, 25)], fill=outline)
        draw.polygon([(21, 11), (25, 11), (27, 25), (23, 27), (20, 24)], fill=base)
        for y in (14, 19):
            draw.line((5, y, 12, y + 1), fill=light, width=2)
            draw.line((20, y + 1, 27, y), fill=light, width=2)
    elif category == "gloves":
        draw.polygon([(3, 7), (12, 7), (14, 13), (12, 24), (8, 29), (3, 26), (5, 20), (1, 16)], fill=outline)
        draw.polygon([(5, 9), (10, 9), (12, 14), (10, 22), (8, 26), (5, 24), (7, 18), (4, 15)], fill=base)
        draw.polygon([(20, 7), (29, 7), (31, 16), (27, 20), (29, 26), (24, 29), (20, 24), (18, 13)], fill=outline)
        draw.polygon([(22, 9), (27, 9), (28, 15), (25, 18), (27, 24), (24, 26), (22, 22), (20, 14)], fill=base)
        draw.line((5, 11, 11, 11), fill=light, width=2)
        draw.line((21, 11, 27, 11), fill=light, width=2)
    elif category == "staff":
        draw.line((8, 29, 22, 6), fill=outline, width=5)
        draw.line((9, 28, 22, 7), fill=base, width=2)
        if item_id == "ceremonial_staff":
            draw.line((17, 7, 27, 7), fill=outline, width=4)
            draw.line((22, 2, 22, 13), fill=outline, width=4)
            draw.line((18, 7, 26, 7), fill=light, width=2)
            draw.line((22, 3, 22, 12), fill=light, width=2)
        else:
            draw.ellipse((17, 1, 28, 12), fill=outline)
            draw.ellipse((20, 4, 25, 9), fill=light)
            draw.point((22, 5), fill="#ffffff")
    elif category == "bow":
        draw.arc((5, 2, 27, 30), 75, 285, fill=outline, width=5)
        draw.arc((7, 4, 25, 28), 75, 285, fill=base, width=2)
        draw.line((21, 4, 21, 28), fill="#e9dcc2", width=1)
        draw.line((20, 16, 29, 16), fill=outline, width=2)
        draw.polygon([(29, 13), (31, 16), (29, 19)], fill=light)
    return image.resize((64, 64), Image.Resampling.NEAREST)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    seen_sources: dict[str, int] = {}
    lines = ["# Manifiesto de iconos Fase 5", "", "| ID | Fuente preservada | Salida |", "|---|---|---|"]
    for item_id, category, _resource, source in definitions():
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        duplicate_index = seen_sources.get(digest, 0)
        seen_sources[digest] = duplicate_index + 1
        target = OUTPUT / f"{item_id}.png"
        icon = draw_motif(item_id, category) or normalize(source, duplicate_index)
        icon.save(target, optimize=True)
        lines.append(f"| `{item_id}` | `{source.relative_to(ROOT).as_posix()}` | `{target.relative_to(ROOT).as_posix()}` |")
    (OUTPUT / "MANIFEST.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Fase 5: {len(lines) - 4} iconos normalizados a 64x64")


if __name__ == "__main__":
    main()
