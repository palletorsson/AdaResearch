#!/usr/bin/env python3
"""
museum_match.py — the tournament match: museum tiles vs bred rooms.

The composition canon breeds rooms (pearl_factory recipes, judged by
map_tournament's experience score). The museum extraction inherited fourteen
principal spatial programs from real architecture. They share one grammar and
one judge, but have never been played against each other. This is the match.

For a sequence, the museum candidates deal the IDENTICAL cast the bred
champion dealt (read from the surviving Trial_<recipe>_<seq> map), into the
museum tile's own slots:

  - hero token (largest by size oracle) -> the tile's 3s hero slot
  - remaining cast, in champion order   -> remaining slots in walk (row) order
  - overflow beyond the slot count      -> hung along walls, enfilade-style
    (the full cast must be dealt: a museum that showed fewer works would be
    judged on an easier ride)

Structure: walls "4" stand as height-4 columns (vistas and detours are real),
floors are height 1, voids height 0. All artifacts sit at floor height so the
pathfinder judges reachability on the same terms as the bred rooms. Spawn at
the entry gap, exit token (copied from the champion) at the exit gap.

Same hard gate (map_pathfinder), same judge (map_tournament.experience_score).
Baseline scores come from doc/reports/map_tournament_<seq>.json. Results land
in doc/reports/museum_match_<seq>.json. Verdicts PROPOSE — the register
rulings still bind.

  python tools/museum_match.py --seq=randomness
  python tools/museum_match.py --seq=color --museums=castelvecchio-endstopped-enfilade
"""
from __future__ import annotations
import argparse
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
sys.path.insert(0, os.path.join(ROOT, "tools"))
from map_tournament import experience_score, cast_of, run  # noqa: E402
from script_compose import base_of, size_of  # noqa: E402

PATTERNS = os.path.join(ROOT, "commons", "data", "template_patterns.json")
DEFAULT_MUSEUMS = [
    "uffizi-spine-enfilade",
    "grande-galerie-axial",
    "castelvecchio-endstopped-enfilade",
    "kanazawa-room-matrix",
    "sainsbury-false-perspective-enfilade",
]
SLOT_CELLS = {"1s": 2, "2s": 1, "3s": 0}   # cell -> rank (hero first)


def champion_of(seq: str) -> tuple[str, list[dict]]:
    p = os.path.join(ROOT, "doc", "reports", f"map_tournament_{seq}.json")
    d = json.load(open(p, encoding="utf-8"))
    ok = [r for r in d["rows"] if r.get("status") == "ok"]
    ok.sort(key=lambda r: -r["score"])
    if not ok:
        raise SystemExit(f"no bred baseline for {seq}")
    champ = f"Trial_{ok[0]['recipe']}_{seq}"
    if not os.path.isfile(os.path.join(MAPS_DIR, champ, "map_data.json")):
        raise SystemExit(f"champion map {champ} not on disk — rerun map_tournament --seq={seq} --keep-losers")
    return champ, ok


def stamp(museum_key: str, pat: dict, champ: str, name: str) -> dict:
    src = json.load(open(os.path.join(MAPS_DIR, champ, "map_data.json"), encoding="utf-8"))
    cast = cast_of(champ)
    w, h, tile = int(pat["w"]), int(pat["h"]), pat["tile"]
    grid = [[str(c) for c in row] for row in tile]

    structure = [["0"] * w for _ in range(h)]
    utils = [[" "] * w for _ in range(h)]
    inter = [[" "] * w for _ in range(h)]
    slots: list[tuple[int, int, int]] = []          # (rank, y, x)
    for y in range(h):
        for x in range(w):
            c = grid[y][x]
            if c == "4":
                structure[y][x] = "4"
            elif c in ("1", "1s", "2", "2s", "3s"):
                structure[y][x] = "1"
            if c in SLOT_CELLS:
                slots.append((SLOT_CELLS[c], y, x))

    # spawn at the entry gap, exit token (champion's) at the exit gap
    entry = [x for x in range(w) if grid[0][x] in ("1", "1s")]
    exit_ = [x for x in range(w) if grid[h - 1][x] in ("1", "1s")]
    exit_tok = "t"
    for row in src["layers"]["utilities"]:
        for c in row:
            if str(c).strip().startswith("t"):
                exit_tok = str(c).strip()
    utils[0][entry[len(entry) // 2]] = "s"
    utils[h - 1][exit_[len(exit_) // 2]] = exit_tok

    # deal: hero token to the 3s, the rest in champion order into walk-order
    # slots, overflow hung along walls
    hero_i = max(range(len(cast)), key=lambda i: size_of(cast[i]))
    rest = [t for i, t in enumerate(cast) if i != hero_i]
    hero_slots = sorted([s for s in slots if s[0] == 0], key=lambda s: (s[1], s[2]))
    other_slots = sorted([s for s in slots if s[0] != 0], key=lambda s: (s[1], s[2]))
    if hero_slots:
        _, y, x = hero_slots[0]
        inter[y][x] = cast[hero_i]
        other_slots += hero_slots[1:]
        other_slots.sort(key=lambda s: (s[1], s[2]))
    dealt = 0
    for _, y, x in other_slots:
        if dealt >= len(rest):
            break
        inter[y][x] = rest[dealt]
        dealt += 1
    overflow = rest[dealt:]
    overflow_total = len(overflow)
    if overflow:
        occupied = {(y, x) for y in range(h) for x in range(w) if inter[y][x].strip()}
        oi = 0
        for y in range(1, h - 1):
            for x in range(w):
                if oi >= len(overflow):
                    break
                if grid[y][x] != "1" or utils[y][x].strip():
                    continue
                near_wall = any(0 <= yy < h and 0 <= xx < w and grid[yy][xx] == "4"
                                for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)))
                crowded = any((yy, xx) in occupied
                              for yy in range(y - 1, y + 2) for xx in range(x - 2, x + 3))
                if near_wall and not crowded:
                    inter[y][x] = overflow[oi]
                    occupied.add((y, x))
                    oi += 1
            if oi >= len(overflow):
                break
        overflow = overflow[oi:]

    data = {
        "documentation": {
            "composer": {
                "tool": "museum_match.py",
                "museum": pat.get("museum", museum_key),
                "template": museum_key,
                "cast_source": champ,
                "undealt": [base_of(t) for t in overflow],
            },
            "authored_by": "museum extraction (inherited template) + champion cast",
        },
        "layers": {"structure": structure, "utilities": utils, "interactables": inter},
        "lighting": src.get("lighting", {}),
        "map_info": {
            "dimensions": {"width": float(w), "depth": float(h), "max_height": 4.0},
            "lookup_name": name,
            "name": name,
            "format": "json",
        },
        "settings": src.get("settings", {}),
        "utility_definitions": src.get("utility_definitions", {}),
    }
    os.makedirs(os.path.join(MAPS_DIR, name), exist_ok=True)
    with open(os.path.join(MAPS_DIR, name, "map_data.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)
    return {"slots_used": dealt + (1 if hero_slots else 0),
            "overflow_hung": overflow_total - len(overflow),
            "undealt": len(overflow)}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", required=True)
    ap.add_argument("--museums", default=",".join(DEFAULT_MUSEUMS))
    ap.add_argument("--keep-losers", action="store_true")
    args = ap.parse_args()

    pats = json.loads(open(PATTERNS, encoding="utf-8").read())["patterns"]
    champ, baseline = champion_of(args.seq)
    print(f"cast source: {champ} (bred champion, score {baseline[0]['score']})")

    rows = []
    for mk in args.museums.split(","):
        mk = mk.strip()
        pat = pats.get(mk)
        if not (isinstance(pat, dict) and pat.get("museum")):
            print(f"{mk:40} NOT A MUSEUM TEMPLATE")
            continue
        # full key in the name: an edited tile (kanazawa-matrix-vista) must not
        # clobber its ancestor's trial (Trial_kanazawa_<seq>)
        name = f"Trial_{mk.replace('-', '_')}_{args.seq}"
        shutil.rmtree(os.path.join(MAPS_DIR, name), ignore_errors=True)
        deal = stamp(mk, pat, champ, name)
        rc, pf = run([sys.executable, "tools/map_pathfinder.py", "check", name])
        if rc != 0 or "0 FAIL" not in pf:
            rows.append({"museum": mk, "status": "PATHFINDER FAIL"})
            print(f"{mk:40} PATHFINDER FAIL")
            continue
        s, detail = experience_score(name)
        if s is None:
            rows.append({"museum": mk, "status": f"SCORE FAIL: {detail}"})
            print(f"{mk:40} SCORE FAIL {detail}")
            continue
        rows.append({"museum": mk, "status": "ok", "map": name, **deal, **detail})
        print(f"{mk:40} {s:5.2f}  {detail}")

    ok = [x for x in rows if x["status"] == "ok"]
    ok.sort(key=lambda x: -x["score"])
    print(f"\n=== THE MATCH: {args.seq} — museums vs bred ===")
    merged = [{"lineage": "bred", "name": r["recipe"], "score": r["score"]} for r in baseline]
    merged += [{"lineage": "MUSEUM", "name": x["museum"], "score": x["score"]} for x in ok]
    merged.sort(key=lambda x: -x["score"])
    for i, x in enumerate(merged[:12], 1):
        print(f"{i:2}. {x['lineage']:6} {x['name']:40} {x['score']:5.2f}")
    out_p = os.path.join(ROOT, "doc", "reports", f"museum_match_{args.seq}.json")
    json.dump({"seq": args.seq, "cast_source": champ,
               "bred_baseline": baseline, "museum_rows": rows,
               "merged_leaderboard": merged},
              open(out_p, "w", encoding="utf-8"), indent=1)
    print(f"report -> {out_p}")
    if not args.keep_losers:
        for x in ok[1:]:
            shutil.rmtree(os.path.join(MAPS_DIR, x["map"]), ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
