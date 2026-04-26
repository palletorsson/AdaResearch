"""Place grid_substrate_runner on a list of spine maps in one pass.

For each (map_name, row, col), reads the map's map_data.json, sets the
specified interactables cell to "grid_substrate_runner", saves, runs
the pathfinder. Reports OK / FAIL per map.

Skips placements that would land on a non-floor cell or on an already-
occupied cell. Idempotent: re-running won't double-place.

Usage:
    python tools/place_substrate_runner.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# (map_name, row, col) — col is X, row is Z. Pick a cell expected to be
# walkable floor (h=1) where we won't collide with existing artifacts.
PLACEMENTS: list[tuple[str, int, int]] = [
    ("Fractal_Recursion",        2, 3),
    ("Random_Definition",        2, 3),
    ("Shader_01_Shaping",        2, 3),
    ("Random_Noise_Types",       2, 3),
    ("LSystems_Grammar_Lab",     2, 3),
    ("Trans_Introduction",       2, 3),
    ("PG_Genetic_Evolution",     2, 3),
    ("Grand_Pattern_Museum",     2, 3),
    ("GT_Foundations",           2, 3),
    ("SearchPathfinding_Intro",  2, 3),
]


def load_map(name: str) -> tuple[Path, dict]:
    p = ROOT / "commons" / "maps" / name / "map_data.json"
    if not p.exists():
        return p, {}
    return p, json.loads(p.read_text(encoding="utf-8"))


def is_floor(structure: list[list[str]], row: int, col: int) -> bool:
    if row < 0 or row >= len(structure):
        return False
    if col < 0 or col >= len(structure[row]):
        return False
    cell = str(structure[row][col]).strip()
    # h=1 is floor in the 3-layer grid convention.
    return cell == "1"


def find_open_floor(structure: list[list[str]], interactables: list[list[str]],
                     prefer_row: int, prefer_col: int) -> tuple[int, int] | None:
    """Find an open h=1 floor cell, preferring (row, col), then scanning rows."""
    if (is_floor(structure, prefer_row, prefer_col)
            and not interactables[prefer_row][prefer_col].strip()):
        return prefer_row, prefer_col
    for r in range(len(structure)):
        for c in range(len(structure[r])):
            if not is_floor(structure, r, c):
                continue
            if interactables[r][c].strip():
                continue
            return r, c
    return None


def place(map_name: str, prefer_row: int, prefer_col: int) -> str:
    p, data = load_map(map_name)
    if not data:
        return f"FAIL  {map_name}: map_data.json not found"
    # Map data uses either "layers" or "grid" depending on the era.
    layers = data.get("layers") or data.get("grid", {})
    structure = layers.get("structure")
    interactables = layers.get("interactables")
    if not structure or not interactables:
        return f"FAIL  {map_name}: missing structure or interactables"
    # Skip if already placed.
    for row in interactables:
        if any("grid_substrate_runner" in str(c) for c in row):
            return f"SKIP  {map_name}: already has grid_substrate_runner"
    spot = find_open_floor(structure, interactables, prefer_row, prefer_col)
    if not spot:
        return f"FAIL  {map_name}: no open h=1 floor found"
    r, c = spot
    interactables[r][c] = "grid_substrate_runner"
    p.write_text(json.dumps(data, indent=2), encoding="utf-8")
    return f"PLACE {map_name}: row={r} col={c}"


def pathfinder(map_name: str) -> str:
    proc = subprocess.run(
        [sys.executable, "tools/map_pathfinder.py", "check", map_name],
        capture_output=True, text=True, cwd=ROOT,
    )
    out = (proc.stdout + proc.stderr).strip().splitlines()
    last = out[-1] if out else ""
    return last


def main() -> int:
    print(f"placing grid_substrate_runner on {len(PLACEMENTS)} maps")
    for name, row, col in PLACEMENTS:
        msg = place(name, row, col)
        print(f"  {msg}")
        if msg.startswith("PLACE") or msg.startswith("SKIP"):
            check = pathfinder(name)
            print(f"        pathfinder: {check}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
