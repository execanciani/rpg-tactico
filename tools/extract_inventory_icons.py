"""Extrae iconos limpios de la referencia y crea provisionales pixel art.

La referencia es una composicion RGB generada por IA, por lo que solamente se
recortan elementos que pueden separarse sin texto ni objetos vecinos. Los
materiales sin un recorte fiable se dibujan como reemplazos originales.
"""

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/ui/inventory/inventory_reference.png"
OUTPUT = ROOT / "assets/items/icons"
SIZE = 64


def _is_panel(pixel: tuple[int, int, int]) -> bool:
    r, g, b = pixel
    return max(pixel) < 105 and b >= r * 0.72 and b >= g * 0.78


def extract(name: str, box: tuple[int, int, int, int]) -> None:
    source = Image.open(SOURCE).convert("RGB").crop(box).resize((SIZE, SIZE), Image.Resampling.NEAREST)
    rgba = source.convert("RGBA")
    pixels = rgba.load()
    seen: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()
    for x in range(SIZE):
        queue.extend(((x, 0), (x, SIZE - 1)))
    for y in range(SIZE):
        queue.extend(((0, y), (SIZE - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < SIZE and 0 <= y < SIZE):
            continue
        seen.add((x, y))
        if not _is_panel(pixels[x, y][:3]):
            continue
        pixels[x, y] = (*pixels[x, y][:3], 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    # Los contadores de pila de la referencia ocupan la esquina inferior
    # derecha y no pertenecen al icono.
    for y in range(48, SIZE):
        for x in range(50, SIZE):
            pixels[x, y] = (0, 0, 0, 0)
    components: list[list[tuple[int, int]]] = []
    visited: set[tuple[int, int]] = set()
    for start_y in range(SIZE):
        for start_x in range(SIZE):
            if (start_x, start_y) in visited or pixels[start_x, start_y][3] == 0:
                continue
            component: list[tuple[int, int]] = []
            pending = [(start_x, start_y)]
            visited.add((start_x, start_y))
            while pending:
                x, y = pending.pop()
                component.append((x, y))
                for nx in range(x - 1, x + 2):
                    for ny in range(y - 1, y + 2):
                        if 0 <= nx < SIZE and 0 <= ny < SIZE and (nx, ny) not in visited and pixels[nx, ny][3] > 0:
                            visited.add((nx, ny))
                            pending.append((nx, ny))
            components.append(component)
    if components:
        largest = set(max(components, key=len))
        for y in range(SIZE):
            for x in range(SIZE):
                if pixels[x, y][3] > 0 and (x, y) not in largest:
                    pixels[x, y] = (0, 0, 0, 0)
    rgba.save(OUTPUT / f"{name}.png")


def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def ore() -> None:
    image, draw = canvas()
    outline = "#241d24"
    draw.polygon([(10, 43), (15, 25), (29, 14), (48, 20), (56, 38), (44, 52), (22, 54)], fill=outline)
    draw.polygon([(15, 41), (19, 27), (31, 19), (45, 24), (51, 37), (41, 47), (23, 49)], fill="#596775")
    draw.polygon([(19, 28), (31, 19), (29, 35), (15, 41)], fill="#8595a3")
    draw.polygon([(31, 19), (45, 24), (40, 39), (29, 35)], fill="#6f7e8d")
    draw.polygon([(29, 35), (40, 39), (41, 47), (23, 49)], fill="#3e4c5a")
    draw.rectangle((25, 25, 30, 29), fill="#c4d1d5")
    draw.rectangle((43, 31, 47, 35), fill="#a9b8c0")
    image.save(OUTPUT / "iron_ore.png")


def wood() -> None:
    image, draw = canvas()
    outline = "#2a1720"
    draw.polygon([(8, 38), (15, 22), (47, 17), (57, 28), (49, 44), (17, 49)], fill=outline)
    draw.polygon([(13, 37), (18, 26), (46, 21), (51, 30), (46, 40), (18, 44)], fill="#a85a29")
    draw.ellipse((40, 20, 57, 40), fill=outline)
    draw.ellipse((44, 24, 53, 36), fill="#d68b45")
    draw.ellipse((47, 27, 51, 34), outline="#784020", width=2)
    draw.line((18, 29, 44, 25), fill="#e0a25d", width=3)
    draw.line((16, 38, 45, 34), fill="#71351f", width=3)
    image.save(OUTPUT / "wood.png")


def leather() -> None:
    image, draw = canvas()
    outline = "#29171d"
    hide = [(18, 8), (30, 15), (45, 9), (42, 24), (55, 35), (42, 43), (37, 57), (25, 49), (10, 55), (13, 39), (5, 27), (20, 23)]
    draw.polygon(hide, fill=outline)
    inner = [(20, 13), (30, 20), (40, 15), (37, 27), (49, 35), (38, 39), (34, 51), (26, 44), (15, 49), (18, 37), (11, 28), (23, 27)]
    draw.polygon(inner, fill="#ad5b32")
    draw.polygon([(20, 13), (30, 20), (23, 27), (11, 28)], fill="#d4864e")
    draw.line((20, 35, 37, 28), fill="#e5a366", width=3)
    draw.line((28, 42, 39, 38), fill="#71301f", width=3)
    image.save(OUTPUT / "leather.png")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    # Celdas interiores: se excluyen sus marcos dorados y contadores.
    extract("small_health_potion", (934, 425, 998, 489))
    extract("small_mana_potion", (1025, 425, 1089, 489))
    extract("magic_crystal", (1406, 519, 1462, 575))
    ore()
    wood()
    leather()
    print(f"Inventario: 6 iconos escritos en {OUTPUT}")


if __name__ == "__main__":
    main()
