"""Extrae únicamente los retratos verificables de la referencia compuesta."""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/ui/character_selection/character_selection.png"
OUTPUT = ROOT / "assets/portraits/races"
EXPECTED_SIZE = (1672, 941)
CROPS = {
    "human": (232, 559, 433, 715),
    "elf": (486, 559, 686, 715),
    "dark_elf": (734, 559, 939, 715),
    "orc": (991, 559, 1187, 715),
    "dwarf": (1248, 559, 1453, 715),
}


def main() -> None:
    source = Image.open(SOURCE)
    if source.size != EXPECTED_SIZE:
        raise ValueError(f"La referencia cambió de tamaño: {source.size} != {EXPECTED_SIZE}")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for race_id, bounds in CROPS.items():
        target = OUTPUT / f"portrait_{race_id}.png"
        source.crop(bounds).save(target, optimize=True)
        print(f"{target.relative_to(ROOT)}: {Image.open(target).size}")


if __name__ == "__main__":
    main()
