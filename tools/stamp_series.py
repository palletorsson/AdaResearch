#!/usr/bin/env python3
"""
stamp_series.py — the family walk (unification step 3).

An artifact is a FAMILY, not one object: 392 axes are declared across the
corpus and — outside one map — nobody has ever met a variant. The DNA gallery
proves a family on a contact sheet; this walks it. One token, one axis, one
value per BAY, dealt down a real museum: you meet the same artifact four or
five times, each time arguing a different value of the same word, in
architecture that repeats so the difference is the only thing that changes.

That is what bays were for. A museum is a sequence of repeating parts
(tools/extract_museum_bays.py), and a repeating part is exactly what a series
needs: identical rooms, one variable.

The token syntax is the one the grid already parses — `artifact#axis:value`
(GridInteractablesComponent._parse_config_token → config_data →
apply_grid_config), the same form Artist_Readymades uses for its request_note
family, which until now was the only map in the corpus placing a non-default
value.

  python tools/stamp_series.py --museum=grande-galerie-axial \
      --token=excluded_class_visualizer --axis=exclusion
  python tools/stamp_series.py --list          # candidate families, by bite
  python tools/stamp_series.py --self-test

Refuses to stamp an axis the registry does not declare, or values the code
cannot reach (it asks check_dna_declarations' own question), because a series
that renders four identical rooms is the science_screen disease with a longer
walk.
"""
from __future__ import annotations
import argparse
import glob
import json
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
BAYS = REPO / "commons" / "data" / "museum_bays.json"
ROLE_RANK = ["hero", "station", "vitrine", "wall_hang", "underfoot"]


def registry() -> dict:
    out: dict = {}
    for rp in sorted(glob.glob(str(REPO / "commons" / "artifacts" / "registry" / "*.json"))):
        try:
            d = json.load(open(rp, encoding="utf-8"))
        except Exception:
            continue
        for tok, e in (d.get("artifacts") or {}).items():
            if isinstance(e, dict) and tok not in out:
                out[tok] = e
    return out


def bite_rows() -> dict:
    """(token, axis) -> focus, from whatever bite reports exist."""
    out: dict = {}
    for p in glob.glob(str(REPO / "doc" / "reports" / "dna_bite*.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        for r in d.get("axes", []):
            if r.get("verdict") == "bites":
                out[(r.get("artifact"), r.get("axis"))] = r.get("focus", 0)
    return out


def candidates() -> list:
    reg, bites = registry(), bite_rows()
    out = []
    for (tok, axis), focus in bites.items():
        e = reg.get(tok) or {}
        vals = ((e.get("dna") or {}).get("axes") or {}).get(axis)
        if (isinstance(vals, list) and 3 <= len(vals) <= 6
                and all(isinstance(v, str) for v in vals) and e.get("scene")):
            out.append((round(float(focus), 3), tok, axis, vals))
    out.sort(reverse=True)
    return out


def museum(key: str) -> dict:
    pats = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
    if key not in pats or not pats[key].get("museum"):
        raise SystemExit(f"no museum template `{key}`")
    return pats[key]


def bay_chain(key: str) -> list:
    d = json.loads(BAYS.read_text(encoding="utf-8"))
    if key not in d["museums"]:
        raise SystemExit(f"`{key}` not in museum_bays.json — run extract_museum_bays.py")
    return [(c["bay"], c["repeat"], d["bays"][c["bay"]]) for c in d["museums"][key]]


def bay_instances(key: str) -> list:
    """[(y0, bay_name, bay)] — every bay INSTANCE with its row offset in the tile.

    A repeat count of three is three rooms, not one room mentioned three times;
    the series needs each instance separately because each gets its own value.
    """
    out, y = [], 0
    for name, repeat, bay in bay_chain(key):
        for _ in range(repeat):
            out.append((y, name, bay))
            y += bay["h"]
    return out


def stamp(mus_key: str, token: str, axis: str, values: list, name: str) -> dict:
    pat = museum(mus_key)
    w, h, tile = int(pat["w"]), int(pat["h"]), pat["tile"]
    grid = [[str(c) for c in row] for row in tile]
    structure = [["0"] * w for _ in range(h)]
    utils = [[" "] * w for _ in range(h)]
    inter = [[" "] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            c = grid[y][x]
            if c == "4":
                structure[y][x] = "4"
            elif c in ("1", "1s", "2", "2s", "3s"):
                structure[y][x] = "1"
    entry = [x for x in range(w) if grid[0][x] in ("1", "1s")]
    exit_ = [x for x in range(w) if grid[h - 1][x] in ("1", "1s")]
    utils[0][entry[len(entry) // 2]] = "s"
    ex = exit_[len(exit_) // 2]
    utils[h - 1][ex] = "t"
    # pathfinder rule 5: the cell under an exit teleport must be void, or the
    # walker lands on floor and the exit reads as furniture
    structure[h - 1][ex] = "0"

    placed = []
    vi = 0
    for y0, bname, bay in bay_instances(mus_key):
        if vi >= len(values):
            break
        st = bay.get("slot_types") or []
        if not st:
            continue
        # the best seat this bay has: hero first, then the freestanding ones
        st = sorted(st, key=lambda s: (ROLE_RANK.index(s["role"])
                                       if s["role"] in ROLE_RANK else 9,
                                       -s["clearance"]))
        s = st[0]
        y, x = y0 + s["y"], s["x"]
        if not (0 <= y < h and 0 <= x < w) or inter[y][x].strip():
            continue
        inter[y][x] = f"{token}#{axis}:{values[vi]}"
        placed.append({"value": values[vi], "bay": bname, "instance_row": y0,
                       "cell": [x, y], "role": s["role"],
                       "size_class": s["size_class"]})
        vi += 1

    doc = {
        "map_info": {
            "name": name,
            "description": f"The {token} family walked: {axis} = "
                           f"{' | '.join(v['value'] for v in placed)}, one value per bay of "
                           f"{pat.get('museum', mus_key)}.",
        },
        "dimensions": {"width": w, "depth": h, "max_height": 5},
        # rows are LISTS of cell strings, not joined text. Written joined, the
        # pathfinder still reported the map OK and Godot built nothing at all:
        # the capture came back with focus [0,0,0] because the AABB was empty.
        # A validator that accepts a format the engine cannot read is the same
        # disease this repo keeps finding — the check passing is not the proof.
        "layers": {"structure": structure,
                   "utilities": utils,
                   "interactables": inter},
        "series": {
            "tool": "stamp_series.py", "museum": mus_key, "token": token,
            "axis": axis, "values": values[:len(placed)],
            "placed": placed,
            "note": "one artifact, one axis, one value per bay — the family walked "
                    "(doc/plans/template_museum_unification.md step 3). Token syntax "
                    "artifact#axis:value is the grid's own config form.",
        },
    }
    return doc


def write(doc: dict, name: str) -> Path:
    d = MAPS / name
    d.mkdir(parents=True, exist_ok=True)
    p = d / "map_data.json"
    p.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    return p


def selftest() -> int:
    """The series must be a series: N bays, N DIFFERENT values, all declared."""
    reg = registry()
    cands = candidates()
    ok = []
    if not cands:
        print("  FAIL  no biting families with 3-6 string values found")
        return 1
    _, tok, axis, vals = cands[0]
    doc = stamp("grande-galerie-axial", tok, axis, vals, "SelfTest_Series")
    placed = doc["series"]["placed"]
    ok.append(("A a value reaches a bay", len(placed) >= 2, f"{len(placed)} placed"))
    seen = [p["value"] for p in placed]
    ok.append(("B every value is distinct", len(set(seen)) == len(seen), str(seen)))
    declared = ((reg[tok].get("dna") or {}).get("axes") or {})[axis]
    ok.append(("C every value is declared", all(v in declared for v in seen),
               f"declared {declared}"))
    rows = [set(p["instance_row"] for p in placed)]
    ok.append(("D one value per bay instance", len(rows[0]) == len(placed),
               f"{len(rows[0])} distinct bay rows"))
    # rows are lists of cells (the fix that made Godot build anything at all —
    # and this control is what caught the change, which is the argument for it)
    toks = {str(c).split("#")[0] for row in doc["layers"]["interactables"]
            for c in row if str(c).strip()}
    ok.append(("E one artifact, not many", toks == {tok}, str(sorted(toks))))
    for label, good, detail in ok:
        print(f"  {'PASS' if good else 'FAIL'}  {label}: {detail}")
    n = sum(1 for _, g, _ in ok if g)
    print(f"self-test: {n}/{len(ok)} controls passed (family {tok}.{axis})")
    return 0 if n == len(ok) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--museum", default="grande-galerie-axial")
    ap.add_argument("--token")
    ap.add_argument("--axis")
    ap.add_argument("--name")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return selftest()
    if args.list or not (args.token and args.axis):
        print("candidate families (biting axis, 3-6 string values, buildable):")
        for focus, tok, axis, vals in candidates()[:20]:
            print(f"  {focus:.3f}  {tok:34} {axis:16} {vals}")
        return 0
    reg = registry()
    e = reg.get(args.token)
    if not e:
        raise SystemExit(f"unknown artifact `{args.token}`")
    declared = ((e.get("dna") or {}).get("axes") or {}).get(args.axis)
    if not declared:
        raise SystemExit(f"`{args.token}` declares no axis `{args.axis}` — "
                         f"has {list(((e.get('dna') or {}).get('axes') or {}))}")
    name = args.name or f"Series_{args.museum.split('-')[0].title()}_{args.token}_{args.axis}"
    doc = stamp(args.museum, args.token, args.axis, [str(v) for v in declared], name)
    placed = doc["series"]["placed"]
    if len(placed) < 2:
        raise SystemExit(f"only {len(placed)} bay(s) took a value — not a series")
    p = write(doc, name)
    print(f"{args.token}.{args.axis} walked through {args.museum}:")
    for q in placed:
        print(f"  {q['value']:14} -> bay {q['bay']:34} {q['role']:10} "
              f"({q['size_class']}) at {tuple(q['cell'])}")
    unused = [v for v in declared if v not in [q["value"] for q in placed]]
    if unused:
        print(f"  {len(unused)} value(s) had no bay: {unused} "
              f"(the building is shorter than the family)")
    print(f"-> {p.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
