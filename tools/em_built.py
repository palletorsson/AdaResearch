#!/usr/bin/env python3
"""Read the AS-BUILT plan — what the museum actually made — without Godot.

    python tools/em_built.py                 # every segment: a text floor plan + its bodies
    python tools/em_built.py --seg 0         # one segment
    python tools/em_built.py --diff a.json b.json   # two runs (vr vs desktop): same rooms?

ada_run/em_built.json is written by endless_museum.gd as each segment
finishes: every cell's role, every body's final world pose and inventory
number, every card, courts, rooms, the gate, the mode. This is the answer to
"what is the floor plan?" — read, not re-derived.
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
BUILT = REPO / "ada_run" / "em_built.json"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def show(seg: dict, bodies: bool = True) -> None:
    print(f"\n== segment {seg['segment']} · {seg['chapter']} · {seg.get('pearl') or '-'} · {seg['museum']} · z {seg['z0']}..{seg['z1']} · {seg['w']}x{seg['h']} · {seg['mode']}"
          + (f" · GATE {'sealed' if seg['gate'].get('sealed') else 'open'}" if seg.get('gate') else ""))
    x0 = int(seg.get("cell_x0", -1))
    marks: dict[tuple[int, int], str] = {}
    for b in seg.get("bodies", []):
        if b.get("kind") in ("artifact", ""):
            wx, wz = int(b["world"][0] // 1), int(b["world"][2] // 1)
            marks[(wx, wz)] = "A"
        elif b.get("kind") == "plinth":
            marks[(int(b["world"][0] // 1), int(b["world"][2] // 1))] = "P"
    for i, row in enumerate(seg.get("cells", [])):
        z = seg["z0"] + i
        line = list(row)
        for (mx, mz), ch in marks.items():
            if mz == z and 0 <= mx - x0 < len(line):
                line[mx - x0] = ch
        tag = ""
        if i == 0: tag = "  <- vestibule"
        elif i == seg["vestibule"]: tag = "  <- tile"
        elif i == seg["vestibule"] + seg["h"] and seg.get("porch_depth"): tag = "  <- after-porch"
        elif i == seg["vestibule"] + seg["h"] + seg.get("porch_depth", 0) and seg.get("court_depth"): tag = "  <- courts"
        print(f"  {z:4d} {''.join(line)}{tag}")
    print(f"  legend: . floor  # not floor  s sealed  b bench  p prop  A artifact  P plinth")
    if bodies:
        arts = [b for b in seg.get("bodies", []) if b.get("kind") in ("artifact", "")]
        print(f"  {len(arts)} bodies, {len(seg.get('cards', []))} cards, {len(seg.get('courts', []))} courts, {len(seg.get('side_rooms', []))} side rooms")
        for b in sorted(arts, key=lambda b: str(b.get("inv", ""))):
            print(f"    {b.get('inv', ''):18s} {b['token']:30s} cell {str(b.get('tile_cell')):10s} world ({b['world'][0]:.1f}, {b['world'][1]:.1f}, {b['world'][2]:.1f}) rot {b['rot']:.0f}"
                  + (f"  {b['walk_kind']}/{b['walk_space']}" if b.get("walk_kind") else ""))


def diff(a: dict, b: dict) -> int:
    sa = {s["segment"]: s for s in a["segments"]}
    sb = {s["segment"]: s for s in b["segments"]}
    bad = 0
    for k in sorted(set(sa) | set(sb)):
        if k not in sa or k not in sb:
            print(f"segment {k}: only in {'A' if k in sa else 'B'}"); bad += 1; continue
        A, B = sa[k], sb[k]
        if A["cells"] != B["cells"]:
            print(f"segment {k}: cells differ ({sum(1 for x, y in zip(A['cells'], B['cells']) if x != y)} rows)"); bad += 1
        ba = {(x["token"], tuple(x.get("tile_cell") or [])): x for x in A["bodies"]}
        bb = {(x["token"], tuple(x.get("tile_cell") or [])): x for x in B["bodies"]}
        for key in sorted(set(ba) | set(bb)):
            if key not in ba or key not in bb:
                print(f"segment {k}: body {key} only in {'A' if key in ba else 'B'}"); bad += 1; continue
            x, y = ba[key], bb[key]
            dxz = abs(x["world"][0] - y["world"][0]) + abs(x["world"][2] - y["world"][2])
            if dxz > 0.05 or abs(x["rot"] - y["rot"]) > 0.5 or x.get("inv") != y.get("inv"):
                print(f"segment {k}: {key[0]} differs — A {x['world']} rot {x['rot']} {x.get('inv')} · B {y['world']} rot {y['rot']} {y.get('inv')}"); bad += 1
    print(f"AS-BUILT DIFF: {'SAME' if bad == 0 else str(bad) + ' difference(s)'} across {len(set(sa) | set(sb))} segment(s) ({a['segments'][0]['mode'] if a['segments'] else '?'} vs {b['segments'][0]['mode'] if b['segments'] else '?'})")
    return 0 if bad == 0 else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seg", type=int, default=None)
    ap.add_argument("--diff", nargs=2, metavar=("A", "B"))
    ap.add_argument("--no-bodies", action="store_true")
    a = ap.parse_args()
    if a.diff:
        return diff(json.loads(Path(a.diff[0]).read_text(encoding="utf-8")), json.loads(Path(a.diff[1]).read_text(encoding="utf-8")))
    d = json.loads(BUILT.read_text(encoding="utf-8"))
    print(f"as-built: {len(d['segments'])} segment(s), plan {d['plan']}, at {d['at']}")
    for s in d["segments"]:
        if a.seg is None or s["segment"] == a.seg:
            show(s, not a.no_bodies)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
