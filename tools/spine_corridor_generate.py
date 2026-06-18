#!/usr/bin/env python
"""
spine_corridor_generate.py -- procedural 16x8 map generator for spine-runner corridors.

Reads:
  - a sequence's artifact list (via its existing map_data.json files for now;
    later, via a sequence-level artifact manifest)
  - each artifact's spine_hints() via regex extraction from its .gd source
    (falls back to safe defaults if not declared)

Writes:
  - commons/maps/<MapName>/map_data.corridor.json  alongside the original

The SpineRunner loads map_data.corridor.json when it exists and the runner
is in corridor mode. The original map_data.json stays untouched.

Usage:
  python tools/spine_corridor_generate.py --sequence primitives
  python tools/spine_corridor_generate.py --sequence primitives --map Point_One --seed 42
  python tools/spine_corridor_generate.py --sequence primitives --candidates 100 --verbose
"""
from __future__ import annotations

import argparse
import json
import random
import re
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import structure_recipes

# ─── Filename convention — single source of truth ────────────────────────
# The corridor JSON sibling of map_data.json, loaded by GridDataComponent
# when prefer_corridor_variant is true. Both must stay identical.
CORRIDOR_FILENAME = "map_data.corridor.json"
BASE_MAP_FILENAME = "map_data.json"


def format_corridor_json(data: dict) -> str:
    """Emit compact, human-readable JSON for a corridor file.

    Layer rows (structure, utilities, interactables) go on a single line each,
    so the 16-row grid reads top-to-bottom like a map. Everything else uses
    standard indent=2.

    Example:
      "structure": [
        ["1","1","1","1","1","1","1","1"],
        ["1","1","1","1","1","1","1","1"],
        ...
      ]
    """
    lines: list[str] = ["{"]
    top_keys = list(data.keys())
    for ki, key in enumerate(top_keys):
        val = data[key]
        suffix = "," if ki < len(top_keys) - 1 else ""
        if key == "layers" and isinstance(val, dict):
            lines.append(f'  "layers": {{')
            layer_keys = list(val.keys())
            for li, lk in enumerate(layer_keys):
                rows = val[lk]
                lsuf = "," if li < len(layer_keys) - 1 else ""
                lines.append(f'    "{lk}": [')
                for ri, row in enumerate(rows):
                    row_json = json.dumps(row, separators=(",", ""))
                    rsuf = "," if ri < len(rows) - 1 else ""
                    lines.append(f'      {row_json}{rsuf}')
                lines.append(f'    ]{lsuf}')
            lines.append(f'  }}{suffix}')
        else:
            rendered = json.dumps(val, indent=2)
            rendered = "\n".join("  " + ln for ln in rendered.splitlines())
            rendered = rendered.lstrip()
            lines.append(f'  "{key}": {rendered}{suffix}')
    lines.append("}")
    return "\n".join(lines) + "\n"
SCAN_DIRS = [REPO / "commons", REPO / "algorithms"]
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"

# --- Corridor frame constants (must match SpineRunner exports) ---
FRAME_ROWS = 16   # z
FRAME_COLS = 8    # x
SPAWN_ROW = 1
SPAWN_COL = 3
TELEPORT_ROW = 15
TELEPORT_COL = 3

# Frame-budget ceilings (ms). 90Hz headset = 11.1ms; we leave headroom for player/env.
BUDGET_CEILING_MS = 9.0

# Role -> preferred row band (inclusive)
ROLE_ROW_BANDS = {
    "primary":    (5, 10),
    "supporting": (3, 12),
    "reflection": (12, 14),
    "ambient":    (2, 14),
}

DEFAULT_HINTS = {
    "role":         "supporting",
    "footprint":    [1, 1],
    "approach":     "any",
    "reading_dist": 1.0,
    "height":       0.0,
    "rotation_y":   -1,
    "budget_ms":    0.5,
    "tags":         [],
}

# --- Hint extraction via regex ------------------------------------------------

HINT_FUNC_RE = re.compile(
    r"func\s+spine_hints\s*\(\s*\)\s*(?:->\s*Dictionary)?\s*:\s*\n"
    r"(?P<body>(?:[^\S\n]*(?:\t| {2,}).*\n)+)",
    re.MULTILINE,
)

_KEY_PATTERNS = {
    "role":         (re.compile(r'"role"\s*:\s*"(\w+)"'),               "str"),
    "approach":     (re.compile(r'"approach"\s*:\s*"(\w+)"'),           "str"),
    "reading_dist": (re.compile(r'"reading_dist"\s*:\s*(-?[\d.]+)'),    "float"),
    "height":       (re.compile(r'"height"\s*:\s*(-?[\d.]+)'),          "float"),
    "rotation_y":   (re.compile(r'"rotation_y"\s*:\s*(-?\d+)'),         "int"),
    "budget_ms":    (re.compile(r'"budget_ms"\s*:\s*(-?[\d.]+)'),       "float"),
}
_FOOTPRINT_RE = re.compile(r'"footprint"\s*:\s*Vector2i\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)')
_TAGS_RE = re.compile(r'"tags"\s*:\s*\[([^\]]*)\]')
_TAG_STR_RE = re.compile(r'"([^"]+)"')


def scan_gd_files() -> dict[str, Path]:
    """Return token -> path for every artifact .gd with a .tscn sibling."""
    out: dict[str, Path] = {}
    for root in SCAN_DIRS:
        if not root.exists():
            continue
        for p in root.rglob("*.gd"):
            parts = set(p.parts)
            if "android" in parts or "_staging" in parts:
                continue
            if not p.with_suffix(".tscn").exists():
                continue
            out[p.stem] = p
    return out


def extract_hints(gd_path: Path) -> dict:
    """Parse spine_hints() body, return dict with all contract keys filled."""
    hints = dict(DEFAULT_HINTS)
    try:
        txt = gd_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return hints
    m = HINT_FUNC_RE.search(txt)
    if not m:
        return hints
    body = m.group("body")
    for key, (rx, kind) in _KEY_PATTERNS.items():
        mm = rx.search(body)
        if mm:
            raw = mm.group(1)
            if kind == "float":
                hints[key] = float(raw)
            elif kind == "int":
                hints[key] = int(raw)
            else:
                hints[key] = raw
    fp = _FOOTPRINT_RE.search(body)
    if fp:
        hints["footprint"] = [int(fp.group(1)), int(fp.group(2))]
    tags = _TAGS_RE.search(body)
    if tags:
        hints["tags"] = _TAG_STR_RE.findall(tags.group(1))
    return hints


# --- Sequence / map helpers ---------------------------------------------------

STYLES_PATH = REPO / "commons" / "maps" / "spine_styles.json"

_styles_cache: dict | None = None

def load_styles() -> dict:
    global _styles_cache
    if _styles_cache is None:
        if STYLES_PATH.exists():
            _styles_cache = _loose_json_loads(STYLES_PATH.read_text(encoding="utf-8"))
        else:
            _styles_cache = {"defaults": {}, "sequences": {}}
    return _styles_cache


def resolve_style(sequence_name: str, map_name: str) -> dict:
    """Returns the final style dict for this map: defaults + sequence + per-map."""
    styles = load_styles()
    style = dict(styles.get("defaults", {}))
    seq = styles.get("sequences", {}).get(sequence_name, {})
    # Shallow-merge sequence onto defaults (but skip per_map_overrides key)
    for k, v in seq.items():
        if k == "per_map_overrides":
            continue
        style[k] = v
    # Apply per-map override
    overrides = seq.get("per_map_overrides", {}).get(map_name, {})
    for k, v in overrides.items():
        style[k] = v
    return style


def _loose_json_loads(text: str):
    """Tolerate trailing commas in hand-authored JSON files."""
    cleaned = re.sub(r",\s*([\]}])", r"\1", text)
    return json.loads(cleaned)


def load_sequence_maps(seq: str) -> list[str]:
    sp = SEQ_DIR / f"{seq}.json"
    if not sp.exists():
        return []
    data = _loose_json_loads(sp.read_text(encoding="utf-8"))
    return list(data.get("sequences", {}).get(seq, {}).get("maps", []))


def extract_tokens_from_original(map_name: str) -> list[dict]:
    """Read existing map_data.json interactables layer, return list of token descriptors."""
    mp = MAPS_DIR / map_name / BASE_MAP_FILENAME
    if not mp.exists():
        return []
    try:
        mdata = _loose_json_loads(mp.read_text(encoding="utf-8"))
    except Exception:
        return []
    out: list[dict] = []
    layers = mdata.get("layers", {})
    for row in layers.get("interactables", []):
        if not isinstance(row, list):
            continue
        for cell in row:
            s = str(cell).strip()
            if not s:
                continue
            # Strip trailing "#mode:..." then split
            base = s.split("#", 1)[0]
            parts = base.split(":")
            token = parts[0].strip()
            if not token:
                continue
            extra_cfg = s.split("#", 1)[1] if "#" in s else ""
            rot = parts[1] if len(parts) > 1 else ""
            yoff = parts[2] if len(parts) > 2 else ""
            out.append({
                "token": token,
                "orig_rotation": rot,
                "orig_yoff": yoff,
                "extra_cfg": extra_cfg,
            })
    return out


# --- Placement algorithm ------------------------------------------------------

def overlaps(grid: list[list[str]], row: int, col: int, fw: int, fz: int) -> bool:
    for r in range(row, row + fz):
        for c in range(col, col + fw):
            if r < 0 or r >= FRAME_ROWS or c < 0 or c >= FRAME_COLS:
                return True
            if grid[r][c] != "":
                return True
    return False


def footprint_center(row: int, col: int, fw: int, fz: int) -> tuple[float, float]:
    return (col + fw / 2.0, row + fz / 2.0)  # (x, z) center in cell units


def cell_dist(a: tuple[float, float], b: tuple[float, float]) -> float:
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5


def south_approach_clear(grid: list[list[str]], row: int, col: int, fw: int) -> bool:
    """Require at least 2 rows south of the artifact's footprint to be empty."""
    target_row = row - 1
    steps = 0
    while target_row >= 0 and steps < 2:
        for c in range(col, col + fw):
            if c < 0 or c >= FRAME_COLS:
                return False
            if grid[target_row][c] != "":
                return False
        target_row -= 1
        steps += 1
    return steps > 0  # at least one clear row south


def score_layout(placements: list[dict], hints_map: dict) -> float:
    """Higher = better. Rewards role-fit, penalises overlap with spawn/teleport."""
    score = 0.0
    for p in placements:
        h = hints_map[p["token"]]
        role = h["role"]
        band = ROLE_ROW_BANDS.get(role, (0, FRAME_ROWS - 1))
        cx, cz = footprint_center(p["row"], p["col"], p["fw"], p["fz"])
        # Role-band fit: +2 if inside, -1 per row outside
        if band[0] <= cz <= band[1]:
            score += 2.0
        else:
            score -= abs(cz - ((band[0] + band[1]) / 2.0))
        # Bonus for south-approach when required and respected
        if h["approach"] == "south":
            score += 1.0
        # Penalty if too close to spawn or teleport cells
        dspawn = cell_dist((cx, cz), (SPAWN_COL + 0.5, SPAWN_ROW + 0.5))
        dtele = cell_dist((cx, cz), (TELEPORT_COL + 0.5, TELEPORT_ROW + 0.5))
        if dspawn < 1.5:
            score -= 2.0
        if dtele < 1.5:
            score -= 2.0
        # Centered on walkway bonus (col 3-4 is the middle)
        if role == "primary":
            score += 1.5 - abs(cx - (FRAME_COLS / 2.0))
    # Density: fewer empty cells behind the primary = higher immersion, up to a point
    return score


def try_place_artifacts(tokens: list[dict], hints_map: dict, rng: random.Random) -> tuple[list[dict] | None, float]:
    """One attempt. Returns (placements, score) or (None, 0) if budget over or unplaceable."""
    grid: list[list[str]] = [["" for _ in range(FRAME_COLS)] for _ in range(FRAME_ROWS)]
    placements: list[dict] = []
    total_budget = 0.0

    # Drop corridor-incompatible artifacts before any placement.
    # Two sources of truth:
    #   1. per-artifact spine_hints() tags "corridor_incompatible" / "oversized"
    #   2. global blacklist in spine_styles.json (for artifacts without a
    #      root GDScript or for token-level bans)
    styles = load_styles()
    blacklist = set(
        str(x) for x in styles.get("corridor_blacklist", [])
        if not str(x).startswith("_doc")
    )
    filtered: list[dict] = []
    dropped: list[str] = []
    for t in tokens:
        if t["token"] in blacklist:
            dropped.append(t["token"] + " (blacklist)")
            continue
        h = hints_map[t["token"]]
        tags = [str(x).lower() for x in h.get("tags", [])]
        if "corridor_incompatible" in tags or "oversized" in tags:
            dropped.append(t["token"] + " (hint tag)")
            continue
        filtered.append(t)
    if dropped:
        print(f"    dropped corridor-incompatible: {', '.join(dropped)}")
    tokens = filtered

    # Sort: primaries first (most constrained), then reflection, supporting, ambient
    order = {"primary": 0, "reflection": 1, "supporting": 2, "ambient": 3}
    sorted_tokens = sorted(tokens, key=lambda t: order.get(hints_map[t["token"]]["role"], 4))

    for tok in sorted_tokens:
        h = hints_map[tok["token"]]
        total_budget += float(h["budget_ms"])
        if total_budget > BUDGET_CEILING_MS:
            # Drop remaining; ambient/supporting excess gets skipped
            if h["role"] in ("ambient", "supporting"):
                continue
            else:
                return None, 0.0

        fw, fz = int(h["footprint"][0]), int(h["footprint"][1])
        role = h["role"]
        band = ROLE_ROW_BANDS.get(role, (0, FRAME_ROWS - 1))
        rd = float(h["reading_dist"])
        approach = h["approach"]

        placed = False
        for _attempt in range(80):
            row = rng.randint(band[0], max(band[0], min(band[1], FRAME_ROWS - fz)))
            col = rng.randint(0, max(0, FRAME_COLS - fw))
            if overlaps(grid, row, col, fw, fz):
                continue
            # Skip if it collides with spawn/teleport cells
            if (row <= SPAWN_ROW + 1 and abs(col - SPAWN_COL) <= 1 and tok == sorted_tokens[0]) and role != "primary":
                continue
            # Approach constraint
            if approach == "south":
                if not south_approach_clear(grid, row, col, fw):
                    continue
            # Reading-distance check against already-placed
            ok = True
            cx, cz = footprint_center(row, col, fw, fz)
            for p in placements:
                dx, dz = footprint_center(p["row"], p["col"], p["fw"], p["fz"])
                if cell_dist((cx, cz), (dx, dz)) < max(rd, float(hints_map[p["token"]]["reading_dist"])):
                    ok = False
                    break
            if not ok:
                continue
            # Claim cells
            for r in range(row, row + fz):
                for c in range(col, col + fw):
                    grid[r][c] = tok["token"]
            placements.append({
                "token": tok["token"],
                "row": row, "col": col, "fw": fw, "fz": fz,
                "extra_cfg": tok["extra_cfg"],
                "orig_rotation": tok["orig_rotation"],
                "orig_yoff": tok["orig_yoff"],
            })
            placed = True
            break

        if not placed and role == "primary":
            return None, 0.0
        # For non-primary: if we couldn't place, silently drop (ambient/supporting are optional)

    return placements, score_layout(placements, hints_map)


def generate_corridor(tokens: list[dict], hints_map: dict, candidates: int, base_seed: int, verbose: bool, style: dict | None = None, jitter: float = 0.0) -> dict | None:
    best = None
    best_score = -1e9
    for i in range(candidates):
        rng = random.Random(base_seed + i * 7919)
        placements, score = try_place_artifacts(tokens, hints_map, rng)
        if placements is None:
            continue
        if score > best_score:
            best_score = score
            best = placements
            if verbose:
                print(f"    candidate {i}: score={score:.2f}, placed={len(placements)}/{len(tokens)}")
    if best is None:
        return None
    data = build_map_data(best, best_score, style, jitter, base_seed)
    if style:
        data["_generated"]["style"] = {
            "structure_recipe": style.get("structure_recipe", "flat_corridor"),
            "lighting_preset":  style.get("lighting_preset", "neutral"),
            "biome_density":    style.get("biome_density", 0.0),
        }
    return data


def build_map_data(placements: list[dict], score: float, style: dict | None = None, jitter: float = 0.0, seed: int = 0) -> dict:
    """Turn a placement list into the map_data.json shape GridSystem consumes."""
    style = style or {}
    if jitter and jitter > 0.001:
        # jitter overrides the style recipe: a height FIELD (levels + voids), with
        # slopes + bridges derived below so it stays walkable. The central question, applied.
        recipe_name = "jittered_corridor"
        recipe_params = {"jitter": jitter, "seed": seed, "spine_col": SPAWN_COL}
    else:
        recipe_name = str(style.get("structure_recipe", "flat_corridor"))
        recipe_params = style.get("structure_params", {}) or {}
    structure = structure_recipes.build_structure(recipe_name, recipe_params)
    # Guarantee spawn + teleport cells walkable regardless of recipe
    structure = structure_recipes.guarantee_walkable(structure, [
        (SPAWN_ROW, SPAWN_COL), (TELEPORT_ROW, TELEPORT_COL),
    ])
    # Also guarantee every placed artifact's cell is walkable
    guarantee_cells = [(p["row"], p["col"]) for p in placements]
    structure = structure_recipes.guarantee_walkable(structure, guarantee_cells)

    utilities: list[list[str]] = [["" for _ in range(FRAME_COLS)] for _ in range(FRAME_ROWS)]
    interactables: list[list[str]] = [["" for _ in range(FRAME_COLS)] for _ in range(FRAME_ROWS)]

    utilities[SPAWN_ROW][SPAWN_COL] = "sp"
    utilities[TELEPORT_ROW][TELEPORT_COL] = "t"

    for p in placements:
        token = p["token"]
        rot = p["orig_rotation"] or "0"
        yoff = p["orig_yoff"] or "0"
        cell = f"{token}:{rot}:{yoff}"
        if p.get("extra_cfg"):
            cell += "#" + p["extra_cfg"]
        interactables[p["row"]][p["col"]] = cell

    # derive slopes (wp) + bridges (tc) so the jittered height field stays walkable
    n_wedge = n_bridge = 0
    if jitter and jitter > 0.001:
        wedges, bridges = structure_recipes.derive_connectors(structure)
        for (r, c) in bridges:
            structure[r][c] = "1"                          # a bridged void becomes walkable floor
        for (r, c) in wedges:
            if utilities[r][c] == "" and interactables[r][c] == "":
                utilities[r][c] = "wp"; n_wedge += 1       # ramp up a level step
        for (r, c) in bridges:
            if utilities[r][c] == "" and interactables[r][c] == "":
                utilities[r][c] = "tc"; n_bridge += 1      # transport cube over the gap

    return {
        "_generated": {
            "generator": "spine_corridor_generate.py",
            "version": 1,
            "frame": [FRAME_ROWS, FRAME_COLS],
            "placements": len(placements),
            "score": round(score, 2),
            "jitter": jitter,
            "wedges": n_wedge,
            "bridges": n_bridge,
        },
        "map_info": {
            "name": "SpineCorridor",
            "description": "Procedurally-generated 16x8 corridor",
            "version": "1.0",
            "dimensions": {
                "width":      FRAME_COLS,
                "depth":      FRAME_ROWS,
                "max_height": 6,
            },
        },
        "settings": {
            "gutter": 0.0,
            "cube_size": 1.0,
            "showgrid": False,
            "showfloor": True,
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
        },
    }


# --- Main ---------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequence", required=True)
    ap.add_argument("--map", help="restrict to one map in the sequence")
    ap.add_argument("--candidates", type=int, default=50)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--jitter", type=float, default=0.0, help="height-field roughness 0..1 — levels + voids, with slopes/bridges auto-derived")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    maps = load_sequence_maps(args.sequence)
    if not maps:
        print(f"no maps for sequence '{args.sequence}'", file=sys.stderr)
        return 1
    if args.map:
        if args.map not in maps:
            print(f"map '{args.map}' not in sequence '{args.sequence}'", file=sys.stderr)
            return 1
        maps = [args.map]

    gd_index = scan_gd_files()
    hints_cache: dict[str, dict] = {}

    def get_hints(token: str) -> dict:
        if token in hints_cache:
            return hints_cache[token]
        if token in gd_index:
            h = extract_hints(gd_index[token])
        else:
            h = dict(DEFAULT_HINTS)
        hints_cache[token] = h
        return h

    ok, fail, skipped = [], [], []
    for map_name in maps:
        tokens = extract_tokens_from_original(map_name)
        if not tokens:
            skipped.append(map_name)
            continue
        # Resolve hints per unique token
        hints_map: dict[str, dict] = {}
        for t in tokens:
            hints_map[t["token"]] = get_hints(t["token"])

        style = resolve_style(args.sequence, map_name)

        if args.verbose:
            print(f"\n[{map_name}] {len(tokens)} artifacts  recipe={style.get('structure_recipe')}")
            for t in tokens:
                h = hints_map[t["token"]]
                print(f"    {t['token']:<36s} role={h['role']:<11s} fp={h['footprint']} budget={h['budget_ms']}")

        result = generate_corridor(tokens, hints_map, args.candidates, args.seed, args.verbose, style, args.jitter)
        if result is None:
            print(f"[FAIL] {map_name} -- no viable layout in {args.candidates} candidates")
            fail.append(map_name)
            continue

        out_path = MAPS_DIR / map_name / CORRIDOR_FILENAME
        if args.dry_run:
            print(f"[DRY] {map_name} -> {result['_generated']['placements']} placed, score {result['_generated']['score']}")
        else:
            out_path.write_text(format_corridor_json(result), encoding="utf-8")
            print(f"[OK ] {map_name} -> {out_path.relative_to(REPO)}  placed={result['_generated']['placements']}  score={result['_generated']['score']}")
        ok.append(map_name)

    print("\n" + "-" * 60)
    print(f"Sequence: {args.sequence}   OK: {len(ok)}   FAIL: {len(fail)}   SKIPPED: {len(skipped)}")
    if fail:
        for m in fail:
            print(f"  FAIL: {m}")
    if skipped:
        for m in skipped:
            print(f"  skip: {m} (no source map_data.json)")
    return 0 if not fail else 2


if __name__ == "__main__":
    sys.exit(main())
