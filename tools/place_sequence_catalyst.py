"""Place one leased catalyst pedestal + counterpart vent per bound spine sequence.

Palle's plan (2026-07-26): the catalyst is placed at the beginning/middle of each
sequence and the player holds it for a bounded time — the timed lease returns the
tool, the knowledge stays. This tool applies that placement for every sequence in
the canonical binding table (commons/hazards/catalyst_sequence_binding.gd).

Per sequence:
  host map   = early/middle map (skip index 0, skip Chamber_* capstones, skip maps
               that already carry any catalyst token), closest to the 40% point
  pedestal   = catalyst_pedestal:0:0#sequence:auto#lease_s:45  near spawn
  vent       = catalyst_vent:0:0#emit_interval_s:2.5#wave_size:3#start_delay_s:5.0#sequence:auto
               farther out, so the brood is met while the lease runs
  validation = tools/map_pathfinder.py check <map>; on failure the edit is
               reverted and the next candidate map is tried

Usage:
    python tools/place_sequence_catalyst.py            # dry run (report picks)
    python tools/place_sequence_catalyst.py --apply    # write + validate
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from compact_map_json import compact_map  # noqa: E402

BINDING_GD = ROOT / "commons" / "hazards" / "catalyst_sequence_binding.gd"
PEDESTAL = "catalyst_pedestal:0:0#sequence:auto#lease_s:45"
VENT = "catalyst_vent:0:0#emit_interval_s:2.5#wave_size:3#start_delay_s:5.0#sequence:auto"
CATALYST_TOKENS = ("catalyst_pedestal", "catalyst_vent", "becoming_catalyst")


def bound_sequences() -> list[str]:
    """Sequence names parsed from the canonical BINDINGS table (stays in sync)."""
    text = BINDING_GD.read_text(encoding="utf-8")
    block = re.search(r"const BINDINGS: Dictionary = \{(.*?)\n\}", text, re.S).group(1)
    return re.findall(r'^\s*"([a-z_]+)":\s*\{', block, re.M)


def sequence_maps(seq: str) -> list[str]:
    path = ROOT / "commons" / "maps" / "sequences" / f"{seq}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    entry = data["sequences"].get(seq) or next(iter(data["sequences"].values()))
    maps = entry.get("maps") or entry.get("map_progression") or []
    return [m if isinstance(m, str) else (m.get("map_name") or m.get("name")) for m in maps]


def is_floor(tok: str) -> bool:
    tok = tok.strip()
    return tok.isdigit() and 1 <= int(tok) <= 5


def cell(layer: list, x: int, z: int) -> str:
    if z >= len(layer):
        return " "
    row = layer[z]
    return row[x] if x < len(row) else " "


def free_cells(layers: dict) -> list[tuple[int, int]]:
    struct = layers.get("structure") or []
    util = layers.get("utilities") or []
    inter = layers.get("interactables") or []
    out = []
    for z, row in enumerate(struct):
        for x, tok in enumerate(row):
            if not is_floor(tok):
                continue
            if cell(util, x, z).strip() or cell(inter, x, z).strip():
                continue
            out.append((x, z))
    return out


def open_neighbors(layers: dict, x: int, z: int) -> int:
    struct = layers.get("structure") or []
    inter = layers.get("interactables") or []
    n = 0
    for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if is_floor(cell(struct, x + dx, z + dz)) and not cell(inter, x + dx, z + dz).strip():
            n += 1
    return n


def spawn_pos(layers: dict) -> tuple[int, int] | None:
    for z, row in enumerate(layers.get("utilities") or []):
        for x, tok in enumerate(row):
            base = tok.strip().split("#")[0].split(":")[0]
            if base in ("s", "sp"):
                return (x, z)
    return None


def cheb(a: tuple[int, int], b: tuple[int, int]) -> int:
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]))


def pick_cells(layers: dict) -> tuple[tuple[int, int], tuple[int, int]] | None:
    sp = spawn_pos(layers)
    if sp is None:
        return None
    free = [c for c in free_cells(layers) if open_neighbors(layers, *c) >= 2]
    # pedestal: near spawn but not on top of it
    ped_pool = [c for c in free if 2 <= cheb(c, sp) <= 5] or [c for c in free if 2 <= cheb(c, sp) <= 8]
    if not ped_pool:
        return None
    # prefer interior cells (all 4 neighbors open) over edges, then closeness to spawn
    ped = min(ped_pool, key=lambda c: (-open_neighbors(layers, *c), cheb(c, sp)))
    # vent: away from both spawn and pedestal, aim ~6-8 cells from the pedestal
    vent_pool = [c for c in free if c != ped and cheb(c, ped) >= 5 and cheb(c, sp) >= 3]
    if not vent_pool:
        vent_pool = [c for c in free if c != ped and cheb(c, ped) >= 3 and cheb(c, sp) >= 2]
    if not vent_pool:
        return None
    vent = min(vent_pool, key=lambda c: (-open_neighbors(layers, *c), abs(cheb(c, ped) - 7)))
    return ped, vent


def ensure_layer(layers: dict, name: str, width: int, depth: int) -> list:
    layer = layers.setdefault(name, [])
    while len(layer) < depth:
        layer.append([" "] * width)
    for row in layer:
        while len(row) < width:
            row.append(" ")
    return layer


def has_catalyst(text: str) -> bool:
    return any(t in text for t in CATALYST_TOKENS)


def pathfinder_ok(map_name: str) -> bool:
    proc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "map_pathfinder.py"), "check", map_name],
        capture_output=True, text=True, cwd=str(ROOT),
    )
    return ", 0 FAIL" in proc.stdout


def candidates(names: list[str]) -> list[tuple[int, str]]:
    n = len(names)
    pool = [
        (i, m) for i, m in enumerate(names)
        if 1 <= i <= max(1, int(n * 0.6)) and not m.startswith("Chamber")
    ]
    pool.sort(key=lambda im: abs(im[0] - n * 0.4))
    return pool


def place_in_map(map_name: str, apply: bool) -> str | None:
    """Try to place pedestal+vent in map_name. Returns summary string on success."""
    path = ROOT / "commons" / "maps" / map_name / "map_data.json"
    if not path.exists():
        return None
    original = path.read_text(encoding="utf-8")
    if has_catalyst(original):
        return None
    data = json.loads(original)
    layers = data.get("layers") or {}
    picked = pick_cells(layers)
    if picked is None:
        return None
    ped, vent = picked
    summary = f"{map_name}: pedestal@{ped} vent@{vent}"
    if not apply:
        return summary
    struct = layers["structure"]
    width = max(len(r) for r in struct)
    inter = ensure_layer(layers, "interactables", width, len(struct))
    inter[ped[1]][ped[0]] = PEDESTAL
    inter[vent[1]][vent[0]] = VENT
    path.write_text(compact_map_from_data(data), encoding="utf-8")
    if not pathfinder_ok(map_name):
        path.write_text(original, encoding="utf-8")
        print(f"  REVERTED {map_name} (pathfinder fail)")
        return None
    return summary


def compact_map_from_data(data: dict) -> str:
    from compact_map_json import _ser
    return _ser(data, 0) + "\n"


def main() -> int:
    apply = "--apply" in sys.argv
    placed, skipped = [], []
    for seq in bound_sequences():
        names = sequence_maps(seq)
        result = None
        for _, map_name in candidates(names):
            result = place_in_map(map_name, apply)
            if result:
                break
        if result:
            placed.append(f"{seq:18s} -> {result}")
        else:
            skipped.append(seq)
    mode = "APPLIED" if apply else "DRY RUN"
    print(f"=== {mode}: {len(placed)} placed, {len(skipped)} skipped ===")
    for line in placed:
        print("  " + line)
    for seq in skipped:
        print(f"  SKIPPED {seq}: no viable host map")
    return 0 if not skipped else 1


if __name__ == "__main__":
    sys.exit(main())
