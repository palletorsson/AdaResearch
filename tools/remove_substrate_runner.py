"""Remove grid_substrate_runner placements from a list of maps.

Reverse of place_substrate_runner.py. Used when a deployment was too broad
and the placements need to come out so the substrate can be re-deployed
intentionally with sequence-specific vocabulary.

Usage:
    python tools/remove_substrate_runner.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Maps that should NOT host grid_substrate_runner — its CA-specific defaults
# pollute the sequence's principle. Each sequence wants its own vocabulary.
TARGETS: list[str] = [
    "Fractal_Recursion",
    "Random_Definition",
    "Shader_01_Shaping",
    "Random_Noise_Types",
    "LSystems_Grammar_Lab",
    "Trans_Introduction",
    "PG_Genetic_Evolution",
    "Grand_Pattern_Museum",
    "GT_Foundations",
    "SearchPathfinding_Intro",
]


def load_map(name: str) -> tuple[Path, dict]:
    p = ROOT / "commons" / "maps" / name / "map_data.json"
    if not p.exists():
        return p, {}
    return p, json.loads(p.read_text(encoding="utf-8"))


def remove(map_name: str) -> str:
    p, data = load_map(map_name)
    if not data:
        return f"FAIL  {map_name}: map_data.json not found"
    layers = data.get("layers") or data.get("grid", {})
    interactables = layers.get("interactables")
    if not interactables:
        return f"FAIL  {map_name}: no interactables layer"

    found_at: tuple[int, int] | None = None
    for r in range(len(interactables)):
        row = interactables[r]
        for c in range(len(row)):
            cell = str(row[c])
            if cell.startswith("grid_substrate_runner"):
                found_at = (r, c)
                interactables[r][c] = " "
                break
        if found_at:
            break

    if not found_at:
        return f"SKIP  {map_name}: grid_substrate_runner not present"

    p.write_text(json.dumps(data, indent=2), encoding="utf-8")
    r, c = found_at
    return f"REMOVE {map_name}: row={r} col={c}"


def pathfinder(map_name: str) -> str:
    proc = subprocess.run(
        [sys.executable, "tools/map_pathfinder.py", "check", map_name],
        capture_output=True, text=True, cwd=ROOT,
    )
    out = (proc.stdout + proc.stderr).strip().splitlines()
    return out[-1] if out else ""


def main() -> int:
    print(f"removing grid_substrate_runner from {len(TARGETS)} maps")
    for name in TARGETS:
        msg = remove(name)
        print(f"  {msg}")
        if msg.startswith("REMOVE"):
            print(f"        pathfinder: {pathfinder(name)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
