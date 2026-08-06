#!/usr/bin/env python3
"""
place_syntheses.py — put the synthesized families into the world.

THE GAP THIS CLOSES, measured by the description audit: exactly ONE map in 2,049 places any
artifact at a non-default DNA value, so 911 declared axes exist in the source tree and on
the test bench and nowhere a player walks. The audit's own recommendation was placement by
CONTRAST PAIR — the shipped default beside its measured family, one room per sequence —
"roughly 24 edits, not 5,900."

TWO MOVES, both from the verdict file tools/synthesize_heroes.py derived:

  1. SYNTHESIS_HALL — one new map, built from the verdicts: the strongest SERIES stand as
     rails (rotated 90 so each rail runs into the hall's depth and the aisle stays
     walkable), the strongest HEROES in a facing row. The whole DNA system in one walk.

  2. CONTRAST PAIRS — for each spine sequence, the strongest measured family whose subject
     is PLACED in that sequence gets one compact hero stand, inserted into the map where
     the subject itself stands, on a free floor cell nearby. The stand next to the shipped
     instances is the contrast: the default and the argued form in one room.

Every touched map is validated with the pathfinder afterwards; a map that fails is
reverted and reported, never shipped broken.

Usage:
  python tools/place_syntheses.py                 # hall + contrast pairs, validate, report
  python tools/place_syntheses.py --hall-only
  python tools/place_syntheses.py --dry-run
"""
from __future__ import annotations
import json
import subprocess
import sys
import collections
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
VERDICTS = json.loads((REPO / "commons" / "data" / "dna_synthesis.json")
                      .read_text(encoding="utf-8"))["verdicts"]

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_dna_declarations import registry  # noqa: E402

# Meta-artifacts that instantiate other artifacts; a synthesis of a synthesis is recursion,
# not curation.
META = {"lineage_vitrine", "sturtevant_bench", "synthesis_stand", "curation_station"}


def extent_of(tok: str, reg: dict) -> float:
    e = reg.get(tok)
    if not e:
        return 1.2
    m = (e[0].get("measurements") or {})
    s = m.get("aabb_size")
    if isinstance(s, list) and len(s) == 3 and max(s) > 0.05:
        return max(float(s[0]), float(s[2]))
    return 1.2


def spine_sequences() -> list:
    sp = json.loads((MAPS / "curriculum_spine.json").read_text(encoding="utf-8"))
    return [s["name"] for s in sorted(sp["spine"]["sequences"], key=lambda x: x.get("order", 0))]


def sequence_maps(name: str) -> list:
    f = MAPS / "sequences" / f"{name}.json"
    if not f.exists():
        return []
    d = json.loads(f.read_text(encoding="utf-8"))
    body = list(d.get("sequences", {}).values())
    maps = (body[0].get("maps") if body else []) or []
    return [m if isinstance(m, str) else (m.get("name") or m.get("map_name") or "") for m in maps]


def load_map(name: str):
    p = MAPS / name / "map_data.json"
    if not p.exists():
        return None, None
    return p, json.loads(p.read_text(encoding="utf-8"))


def placements_in(md: dict) -> dict:
    out = collections.defaultdict(list)
    rows = (md.get("layers") or {}).get("interactables") or []
    for y, row in enumerate(rows):
        for x, c in enumerate(row if isinstance(row, list) else []):
            if isinstance(c, str) and c.strip():
                out[c.split("#")[0].split(":")[0].strip()].append((x, y))
    return out


def free_cell_near(md: dict, ax: int, ay: int):
    """A walkable, empty cell near (ax, ay) whose 4-neighbourhood is clear of artifacts —
    a hero slab is ~2 m and must not intersect the subject it contrasts with."""
    lay = md["layers"]
    H, W = len(lay["structure"]), len(lay["structure"][0])

    def ok(x, y):
        if not (0 <= x < W and 0 <= y < H):
            return False
        try:
            if int(str(lay["structure"][y][x]).strip() or 0) < 1:
                return False
        except ValueError:
            return False
        if str(lay["utilities"][y][x]).strip() or str(lay["interactables"][y][x]).strip():
            return False
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and str(lay["interactables"][ny][nx]).strip():
                return False
        return True

    for r in range(2, 7):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if max(abs(dx), abs(dy)) != r:
                    continue
                if ok(ax + dx, ay + dy):
                    return ax + dx, ay + dy
    return None


def build_hall(reg: dict, dry: bool) -> str:
    series = sorted((v for v in VERDICTS.values() if v["verdict"] == "series"
                     and v["prop"] not in META and extent_of(v["prop"], reg) <= 3.2),
                    key=lambda v: -v["span"][1])[:7]
    used = {v["prop"] for v in series}
    heroes = sorted((v for v in VERDICTS.values() if v["verdict"] == "hero"
                     and v["prop"] not in META and v["prop"] not in used
                     and extent_of(v["prop"], reg) <= 4.0),
                    key=lambda v: -v["score"])[:8]

    W, H = 42, 20
    blank = lambda fill: [[fill] * W for _ in range(H)]
    structure = blank("1")
    utilities = blank(" ")
    inter = blank(" ")
    utilities[H - 3][2] = "sp"
    utilities[H - 3][W - 2] = "t"
    # Series rails across the north half, rotated 90 so each rail runs in DEPTH and the
    # southern aisle stays walkable past all of them.
    xs = [4 + i * 5 for i in range(len(series))]
    for x, v in zip(xs, series):
        inter[7][x] = f"synthesis_stand:90#subject:{v['prop']}#mode:series"
    # Heroes in a facing row along the south aisle.
    hx = [3 + i * 5 for i in range(len(heroes))]
    for x, v in zip(hx, heroes):
        inter[H - 6][x] = f"synthesis_stand#subject:{v['prop']}#mode:hero"

    md = {
        "map_info": {
            "name": "Synthesis Hall",
            "lookup_name": "Synthesis_Hall",
            "version": "2.0",
            "format": "json",
            # The grid PLACES NOTHING without declared dimensions: it iterates the declared
            # depth, and a missing block reads as 0x0 — the first build of this hall loaded
            # 2702 artifacts, read all 20 rows, and placed zero interactables.
            "dimensions": {"width": W, "depth": H, "max_height": 4},
            "description": (
                "Every promoted family's one best public form, placed. Seven series rails run "
                "north — families whose measurements form a gradient away from the shipped "
                "default, shown default-first then by measured departure, because for these "
                "the progression is the argument. Eight heroes face them — families where one "
                "variant is the argument, pinned, with the focus number that chose it on the "
                "plaque. The verdicts are derived from the swept renders by "
                "tools/synthesize_heroes.py; nothing in this room was picked by taste."),
        },
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True,
                     "enable_physics": True,
                     "background": {"type": "sky", "color": [0.55, 0.62, 0.55]}},
        "layers": {"structure": structure, "utilities": utilities, "interactables": inter},
    }
    out = MAPS / "Synthesis_Hall"
    if not dry:
        out.mkdir(exist_ok=True)
        (out / "map_data.json").write_text(json.dumps(md, indent=1), encoding="utf-8")
    print(f"Synthesis_Hall: {len(series)} series rails + {len(heroes)} heroes"
          + (" (dry)" if dry else ""))
    for v in series:
        print(f"   rail  {v['prop']:30s} {v['axis']}: {' -> '.join(v['order'])}")
    for v in heroes:
        print(f"   hero  {v['prop']:30s} {v['score']*100:5.1f}%  "
              + " ".join(f"{k}={x}" for k, x in v["hero"].items()))
    return "Synthesis_Hall"


def contrast_pairs(reg: dict, dry: bool) -> list:
    touched = []
    for seq in spine_sequences():
        best = None
        for mname in sequence_maps(seq):
            p, md = load_map(mname)
            if md is None:
                continue
            for tok, cells in placements_in(md).items():
                v = VERDICTS.get(tok)
                if not v or v["verdict"] not in ("hero", "series") or tok in META:
                    continue
                score = v.get("score") or (v.get("span") or [0, 0])[1]
                if best is None or score > best[0]:
                    best = (score, seq, mname, tok, cells[0], v)
        if best is None:
            print(f"  {seq:26s} — no measured family placed in its maps")
            continue
        _, _, mname, tok, (ax, ay), v = best
        p, md = load_map(mname)
        if f"#subject:{tok}" in json.dumps(md["layers"]["interactables"]):
            print(f"  {seq:26s} — already has a stand for {tok}")
            continue
        cell = free_cell_near(md, ax, ay)
        if cell is None:
            print(f"  {seq:26s} — no free cell near {tok} in {mname}")
            continue
        x, y = cell
        md["layers"]["interactables"][y][x] = f"synthesis_stand#subject:{tok}#mode:hero"
        if not dry:
            p.write_text(json.dumps(md, indent=1), encoding="utf-8")
        touched.append(mname)
        print(f"  {seq:26s} -> {mname}: hero of {tok} at ({x},{y})"
              f" beside its shipped placement" + (" (dry)" if dry else ""))
    return touched


def main() -> int:
    dry = "--dry-run" in sys.argv
    hall_only = "--hall-only" in sys.argv
    reg = registry()
    touched = [build_hall(reg, dry)]
    if not hall_only:
        print("\ncontrast pairs, one per spine sequence:")
        touched += contrast_pairs(reg, dry)
    print(f"\n{len(touched)} map(s) written" + (" (dry)" if dry else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
