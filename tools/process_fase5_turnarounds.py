"""Normaliza la hoja de turnarounds original de Fase 5 para Godot.

La fuente contiene cinco filas (clases) y cuatro columnas (orientaciones).
Cada figura se recorta por alfa, se reduce con nearest-neighbor, se limita a
una paleta estable y se ancla en (48, 88) dentro de un lienzo 96x96.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/characters/class_turnarounds_fase5.png"
CLASSES = ["warrior", "mage", "archer", "acolyte", "explorer"]
DIRECTIONS = ["front", "right", "back", "left"]
CANVAS = (96, 96)
ANCHOR = (48, 88)
MAX_SIZE = (70, 82)


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    return alpha.point(lambda value: 255 if value >= 24 else 0).getbbox() or (0, 0, image.width, image.height)


def isolate_largest(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(image.height):
        for x in range(image.width):
            if (x, y) in visited or pixels[x, y] < 24:
                continue
            pending = [(x, y)]
            visited.add((x, y))
            component: list[tuple[int, int]] = []
            while pending:
                px, py = pending.pop()
                component.append((px, py))
                for nx in range(px - 1, px + 2):
                    for ny in range(py - 1, py + 2):
                        if 0 <= nx < image.width and 0 <= ny < image.height and (nx, ny) not in visited and pixels[nx, ny] >= 24:
                            visited.add((nx, ny))
                            pending.append((nx, ny))
            components.append(component)
    if not components:
        return image
    keep = set(max(components, key=len))
    cleaned = image.copy()
    cleaned_alpha = cleaned.getchannel("A")
    cleaned_pixels = cleaned_alpha.load()
    for y in range(image.height):
        for x in range(image.width):
            if (x, y) not in keep:
                cleaned_pixels[x, y] = 0
    cleaned.putalpha(cleaned_alpha)
    return cleaned


def normalize(image: Image.Image) -> Image.Image:
    image = isolate_largest(image)
    cropped = image.crop(alpha_bbox(image))
    scale = min(MAX_SIZE[0] / cropped.width, MAX_SIZE[1] / cropped.height)
    size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    sprite = cropped.resize(size, Image.Resampling.NEAREST)
    alpha = sprite.getchannel("A").point(lambda value: 255 if value >= 96 else 0)
    # Reducir ruido cromatico sin suavizar contornos.
    rgb = sprite.convert("RGB").quantize(colors=40, method=Image.Quantize.MEDIANCUT).convert("RGB")
    sprite = rgb.convert("RGBA")
    sprite.putalpha(alpha)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    x = ANCHOR[0] - sprite.width // 2
    y = ANCHOR[1] - sprite.height
    canvas.alpha_composite(sprite, (x, y))
    return canvas


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    for row, class_id in enumerate(CLASSES):
        y0 = round(row * source.height / len(CLASSES))
        y1 = round((row + 1) * source.height / len(CLASSES))
        output = ROOT / f"assets/sprites/characters/{class_id}/idle"
        output.mkdir(parents=True, exist_ok=True)
        for column, direction in enumerate(DIRECTIONS):
            x0 = round(column * source.width / len(DIRECTIONS))
            x1 = round((column + 1) * source.width / len(DIRECTIONS))
            cell = source.crop((x0, y0, x1, y1))
            normalized = normalize(cell)
            normalized.save(output / f"fase5_{direction}_00.png")
    print("Fase 5: 20 vistas normalizadas a 96x96")


if __name__ == "__main__":
    main()
