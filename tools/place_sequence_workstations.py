"""Install the evolving Bauhaus Studio Workstation across the Void Tower's 26-sequence spine.

Uses tools/rooms_door.py::edit() exclusively so every write takes an automatic
git blob snapshot under refs/rooms/, validates zero duplicate IDs, preserves
floor order, and never touches any other floor or artifact row.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import rooms_door  # noqa: E402

SEQUENCE_WORKSTATIONS = [
    # (map_name, floor_idx, station, position, facing, color_palette_or_none)
    ("Trans_Body",                19,  "SW", [-10, 4.25],    0, None),
    ("Tutorial_3D",               24,  "NE", [10, -4.25],  180, None),
    ("Tutorial_Pattern",          39,  "SW", [-10, 4.25],    0, "bauhaus"),
    ("Vectors_Act5_ForceAsPlace", 55,  "NE", [10, -4.25],  180, "bauhaus"),
    ("WaveFunctions_Sine_Space",  64,  "NE", [10, -4.25],  180, "bauhaus"),
    ("Random_Walk",               81,  "SW", [-10, 4.25],    0, "bauhaus"),
    ("Noise_Perlin_Simplex",      98,  "NE", [10, -4.25],  180, "bauhaus"),
    ("CA_GameOfLife",            108,  "NE", [10, -4.25],  180, "bauhaus"),
    ("Fractal_MengerSponge",     118,  "NE", [10, -4.25],  180, "bauhaus"),
    ("LSystems_Growth",          122,  "NE", [10, -4.25],  180, "bauhaus"),
    ("ISO_Introduction",         145,  "SW", [-10, 4.25],    0, "bauhaus"),
]
RETIRED_FLOORS = ["Trans_Playground"]


def make_row(floor_idx: int, station: str, pos: list, facing: int, color_pal) -> dict:
    cfg = {
        "parts": {"Output": {"position": [0, 0, -4.25], "rotation": [0, 0, 0]}},
        "space_from": "scaffold_workstation_quads",
        "tier": 3,
        "prefabs_enabled": True,
        "studio": True,
        "palette": "bauhaus",
        "chamber_height": 5.4,
        "space_floor": floor_idx,
    }
    if color_pal:
        cfg["color_palette"] = color_pal
    return {
        "artifact": "scaffold_workstation_display",
        "config": cfg,
        "facing": facing,
        "height": 0,
        "id": "scaffold-workstation",
        "position": pos,
        "scale": 1,
        "station": station,
    }


def apply_placements(text: str) -> str:
    doc = json.loads(text)
    by_map = {f["map"]: (i, f) for i, f in enumerate(doc["floors"])}
    for retired in RETIRED_FLOORS:
        if retired in by_map:
            _, rfloor = by_map[retired]
            rfloor["artifacts"] = [a for a in rfloor["artifacts"] if a.get("id") != "scaffold-workstation"]
    for map_name, _hint_idx, station, pos, facing, color_pal in SEQUENCE_WORKSTATIONS:
        assert map_name in by_map, f"Missing map {map_name}"
        real_idx, floor_obj = by_map[map_name]
        row = make_row(real_idx, station, pos, facing, color_pal)
        arts = floor_obj["artifacts"]
        replaced = False
        for i, existing in enumerate(arts):
            if existing.get("id") == "scaffold-workstation":
                arts[i] = row
                replaced = True
                break
        if not replaced:
            arts.append(row)
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


def main() -> int:
    how = rooms_door.edit(apply_placements)
    print(f"rooms_door.edit -> {how} ({len(SEQUENCE_WORKSTATIONS)} sequence Studio Workstations installed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
