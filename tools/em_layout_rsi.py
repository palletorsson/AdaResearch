#!/usr/bin/env python3
"""em_layout_rsi.py — score the museum's layout, hall by hall, and draw it for the eye.

Palle (2026-09-19): "can we use RSI like strategy to improve the museum layout. Now wall items
are not all wall aligned, sometimes they hang on each other, sometimes in the air from old
walls ... I still want to be able to edit the positions. I want halls to be locked and an
unlocked switch between manual and automatic."

THE ONE RULE THIS TOOL OBEYS: it never re-derives where the museum puts a body. Positions come
only from the museum's OWN record, `ada_run/em_layout_walk.json`, which Godot writes as it
builds. A second implementation of one placement rule is how `long_museum.py` came to report a
strip 16 % longer than the museum with its own check green. So: the engine places and dumps,
this reads. Anything that would need the world -> cell mapping is NOT measured here; it is
listed under `deferred_to_engine` in the score, with what the engine would have to report.

MODES — nothing is automatic unless it is opted in.
`commons/data/em_layout_modes.json` is authored and keyed "chapter|pearl":

    {"array_tutorial|array": {"mode": "auto", "pinned": ["pick_up_cube"], "note": "why"}}

  manual (THE DEFAULT, and the default for any hall not in the file)
      measured and reported, never touched. An automatic pass must skip it.
  auto
      measured, reported, and a pass may move its bodies — except any token in `pinned`,
      which you placed by hand and which stays put.

Locking hides nothing: every hall is scored and drawn whatever its mode. The mode governs
what may be CHANGED, never what may be SEEN.

    python tools/em_layout_rsi.py check           # score every hall the engine has walked
    python tools/em_layout_rsi.py check --verbose # and list every offending body
    python tools/em_layout_rsi.py draw            # top-down SVG per hall + an index page
    python tools/em_layout_rsi.py modes           # show the lock table

Output: ada_run/em_layout_rsi/score.json, ada_run/em_layout_rsi/*.svg
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
WALK = REPO / "ada_run" / "em_layout_walk.json"          # the engine's own record — the ONLY source of positions
MODES = REPO / "commons" / "data" / "em_layout_modes.json"   # authored; absent hall == manual
REGISTRY = REPO / "commons" / "artifacts" / "registry"
OUT = REPO / "ada_run" / "em_layout_rsi"

# a body whose yaw is more than this far from a right angle is not square to any wall of a
# square grid. 1.0 deg leaves room for float noise and catches a deliberate 20 deg turn.
SQUARE_TOL_DEG = 1.0
# two footprints closer than (r1 + r2) - this are standing in each other. The slack absorbs
# footprint_cells being a whole number of cells rather than a measured metre radius.
OVERLAP_SLACK_M = 0.35
CELL_M = 1.0


def load_json(p: Path, what: str):
    if not p.exists():
        print("missing %s: %s" % (what, p), file=sys.stderr)
        return None
    return json.loads(p.read_text(encoding="utf-8"))


def footprints() -> dict:
    """token -> footprint radius in metres, from the registry's MEASURED footprint_cells."""
    out = {}
    for f in sorted(REGISTRY.glob("*.json")):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        if not isinstance(d, dict):
            continue
        # registry files wrap their tokens under "artifacts". Reading the outer dict finds
        # nothing and says nothing, which is how this measure first shipped seeing 0 of 164.
        d = d.get("artifacts", d)
        if not isinstance(d, dict):
            continue
        for token, entry in d.items():
            if not isinstance(entry, dict):
                continue
            sn = entry.get("spatial_needs")
            cells = (sn or {}).get("footprint_cells") if isinstance(sn, dict) else None
            if cells is None:
                cells = entry.get("footprint_cells")
            if isinstance(cells, (int, float)) and cells > 0:
                # a footprint of n cells, taken as a square: half-diagonal is the honest radius
                side = math.sqrt(float(cells)) * CELL_M
                out[token] = side * 0.5
    return out


def modes() -> dict:
    d = load_json(MODES, "modes file") if MODES.exists() else {}
    if not isinstance(d, dict):
        return {}
    inner = d.get("halls")
    return inner if isinstance(inner, dict) else d


def mode_of(table: dict, key: str) -> tuple[str, list]:
    row = table.get(key)
    if not isinstance(row, dict):
        return "manual", []          # THE DEFAULT: absent means locked
    m = str(row.get("mode", "manual")).lower()
    if m not in ("manual", "auto"):
        m = "manual"
    pinned = row.get("pinned") or []
    return m, [str(t) for t in pinned] if isinstance(pinned, list) else []


def off_square(rot: float) -> float:
    """degrees away from the nearest right angle."""
    r = abs(float(rot)) % 90.0
    return min(r, 90.0 - r)


def score_hall(key: str, hall: dict, fp: dict, table: dict) -> dict:
    bodies = [b for b in (hall.get("bodies") or []) if isinstance(b, dict) and b.get("world")]
    mode, pinned = mode_of(table, key)
    askew, stacked = [], []
    unsized: set = set()
    for b in bodies:
        d = off_square(b.get("rot", 0.0))
        if d > SQUARE_TOL_DEG:
            askew.append({"token": b.get("token", "?"), "rot": round(float(b.get("rot", 0.0)), 2),
                          "off_deg": round(d, 2), "world": b.get("world"),
                          "pinned": b.get("token") in pinned})
    for i in range(len(bodies)):
        for j in range(i + 1, len(bodies)):
            a, c = bodies[i], bodies[j]
            wa, wc = a["world"], c["world"]
            if abs(float(wa[1]) - float(wc[1])) > 1.2:
                continue      # different heights: a wall work over a bench is not a collision
            dx, dz = float(wa[0]) - float(wc[0]), float(wa[2]) - float(wc[2])
            gap = math.hypot(dx, dz)
            if a.get("token") not in fp or c.get("token") not in fp:
                unsized.add(a.get("token") if a.get("token") not in fp else c.get("token"))
                continue      # no measured footprint: this pair is NOT tested, and says so
            ra = fp[a.get("token")] * float(a.get("scale", 1.0) or 1.0)
            rc = fp[c.get("token")] * float(c.get("scale", 1.0) or 1.0)
            need = ra + rc - OVERLAP_SLACK_M
            if gap < need:
                stacked.append({"a": a.get("token", "?"), "b": c.get("token", "?"),
                                "gap_m": round(gap, 2), "need_m": round(need, 2),
                                "overlap_m": round(need - gap, 2),
                                "pinned": bool({a.get("token"), c.get("token")} & set(pinned))})
    return {"key": key, "chapter": hall.get("chapter"), "pearl": hall.get("pearl"),
            "map": hall.get("map"), "mode": mode, "pinned": pinned,
            "bodies": len(bodies), "askew": askew, "stacked": stacked,
            "untested_for_overlap": sorted(t for t in unsized if t),
            "defects": len(askew) + len(stacked)}


def check(verbose: bool) -> int:
    walk = load_json(WALK, "the museum's own record")
    if walk is None:
        return 1
    halls = walk.get("halls") or {}
    fp, table = footprints(), modes()
    rows = [score_hall(k, h, fp, table) for k, h in sorted(halls.items())]
    OUT.mkdir(parents=True, exist_ok=True)
    payload = {"schema": 1, "source": "ada_run/em_layout_walk.json",
               "halls_with_an_engine_row": len(rows),
               "note": ("Positions are the engine's own. Nothing here is re-derived. A hall the museum "
                        "has never built has no row and cannot be scored."),
               "deferred_to_engine": [
                   {"defect": "a wall work with no wall behind it",
                    "why": "needs the world -> cell mapping, which only the museum owns",
                    "asked_of_the_engine": "one `backing` field per body in em_layout_walk.json: the "
                                           "character of the cell the body backs onto, and its distance"}],
               "tolerances": {"square_deg": SQUARE_TOL_DEG, "overlap_slack_m": OVERLAP_SLACK_M},
               "halls": rows}
    (OUT / "score.json").write_text(json.dumps(payload, indent=1), encoding="utf-8")

    n_askew = sum(len(r["askew"]) for r in rows)
    n_stack = sum(len(r["stacked"]) for r in rows)
    n_bodies = sum(r["bodies"] for r in rows)
    bad = [r for r in rows if r["defects"] > 0]
    print("%-34s %-7s %-7s %-7s %s" % ("hall", "mode", "bodies", "askew", "stacked"))
    for r in sorted(rows, key=lambda r: -r["defects"]):
        if r["defects"] == 0 and not verbose:
            continue
        print("%-34s %-7s %-7d %-7d %d" % (r["key"][:34], r["mode"], r["bodies"],
                                           len(r["askew"]), len(r["stacked"])))
        if verbose:
            for a in r["askew"]:
                print("      askew   %-26s %6.1f deg off square%s" % (a["token"][:26], a["off_deg"],
                                                                      "  [pinned]" if a["pinned"] else ""))
            for s in r["stacked"]:
                print("      stacked %-14s + %-14s overlap %.2f m%s" % (s["a"][:14], s["b"][:14],
                                                                        s["overlap_m"],
                                                                        "  [pinned]" if s["pinned"] else ""))
    auto = sum(1 for r in rows if r["mode"] == "auto")
    print()
    print("%d halls have an engine row, %d bodies. %d halls carry a defect." % (len(rows), n_bodies, len(bad)))
    print("askew %d, stacked %d." % (n_askew, n_stack))
    untested = sorted({t for r in rows for t in r["untested_for_overlap"]})
    if untested:
        print("OVERLAP NOT TESTED for %d token(s) with no measured footprint_cells: %s"
              % (len(untested), ", ".join(untested[:8]) + (" ..." if len(untested) > 8 else "")))
        print("  A pair involving one of these was SKIPPED, not passed. Run tools/sync_footprints.py,")
        print("  or accept that the overlap score covers only part of the museum and say which part.")
    print("%d of %d halls are unlocked (auto); the rest are manual and an automatic pass must not touch them."
          % (auto, len(rows)))
    print("score -> %s" % (OUT / "score.json"))
    return 0


def draw() -> int:
    """A top-down page per hall, in WORLD metres, coloured by defect. No cell mapping is used."""
    walk = load_json(WALK, "the museum's own record")
    if walk is None:
        return 1
    halls = walk.get("halls") or {}
    fp, table = footprints(), modes()
    OUT.mkdir(parents=True, exist_ok=True)
    index = []
    for key, hall in sorted(halls.items()):
        r = score_hall(key, hall, fp, table)
        bodies = [b for b in (hall.get("bodies") or []) if isinstance(b, dict) and b.get("world")]
        if not bodies:
            continue
        askew_tokens = {a["token"] for a in r["askew"]}
        stacked_tokens = {s["a"] for s in r["stacked"]} | {s["b"] for s in r["stacked"]}
        xs = [float(b["world"][0]) for b in bodies]
        zs = [float(b["world"][2]) for b in bodies]
        pad = 2.0
        x0, x1 = min(xs) - pad, max(xs) + pad
        z0, z1 = min(zs) - pad, max(zs) + pad
        sc = 26.0
        w, h = max(1.0, (x1 - x0)) * sc, max(1.0, (z1 - z0)) * sc
        parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.0f %.0f" width="%.0f" height="%.0f">'
                 % (w, h + 34, w, h + 34),
                 '<rect width="100%%" height="100%%" fill="#14161c"/>',
                 '<text x="8" y="20" fill="#d8dbe4" font-family="monospace" font-size="13">%s &#183; %s &#183; %d bodies &#183; %d askew &#183; %d stacked</text>'
                 % (key, r["mode"], r["bodies"], len(r["askew"]), len(r["stacked"]))]
        for b in bodies:
            bx = (float(b["world"][0]) - x0) * sc
            bz = (float(b["world"][2]) - z0) * sc + 34
            rad = max(4.0, fp.get(b.get("token"), 0.5) * float(b.get("scale", 1.0) or 1.0) * sc)
            tok = b.get("token", "?")
            if tok in stacked_tokens:
                col, edge = "#e2603c", "#ff9a72"      # standing in something
            elif tok in askew_tokens:
                col, edge = "#d8b33c", "#ffe08a"      # not square to any wall
            else:
                col, edge = "#3f6d8e", "#7fb3d5"
            if tok in r["pinned"]:
                edge = "#ffffff"
            parts.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" fill-opacity="0.45" stroke="%s" stroke-width="1.2"/>'
                         % (bx, bz, rad, col, edge))
            ang = math.radians(float(b.get("rot", 0.0)))
            parts.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1.6"/>'
                         % (bx, bz, bx + math.sin(ang) * rad, bz - math.cos(ang) * rad, edge))
        parts.append("</svg>")
        name = key.replace("|", "__").replace("/", "_") + ".svg"
        (OUT / name).write_text("\n".join(parts), encoding="utf-8")
        index.append((key, name, r))
    rows = "\n".join(
        '<li><a href="%s">%s</a> &#183; %s &#183; %d bodies, <b>%d askew</b>, <b>%d stacked</b></li>'
        % (n, k, s["mode"], s["bodies"], len(s["askew"]), len(s["stacked"])) for k, n, s in index)
    (OUT / "index.html").write_text(
        '<html><head><meta charset="utf-8"><title>museum layout</title>'
        '<style>body{background:#14161c;color:#d8dbe4;font-family:monospace;padding:24px}'
        'a{color:#7fb3d5}li{margin:3px 0}</style></head><body>'
        '<h2>Museum layout, top down</h2>'
        '<p>Blue square to a wall. Yellow not square. Orange standing in another body. '
        'A white outline is a pinned body you placed by hand. The tick is the facing.</p>'
        '<ul>%s</ul></body></html>' % rows, encoding="utf-8")
    print("drew %d halls -> %s" % (len(index), OUT / "index.html"))
    return 0


def show_modes() -> int:
    walk = load_json(WALK, "the museum's own record") or {"halls": {}}
    table = modes()
    keys = sorted(set(walk.get("halls", {}).keys()) | set(table.keys()))
    auto = 0
    print("%-40s %-8s %s" % ("hall", "mode", "pinned"))
    for k in keys:
        m, pinned = mode_of(table, k)
        auto += m == "auto"
        print("%-40s %-8s %s" % (k[:40], m, ", ".join(pinned) if pinned else "-"))
    print()
    print("%d of %d unlocked. A hall absent from %s is MANUAL." % (auto, len(keys), MODES.name))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["check", "draw", "modes"])
    ap.add_argument("--verbose", action="store_true")
    a = ap.parse_args()
    if a.cmd == "check":
        return check(a.verbose)
    if a.cmd == "draw":
        return draw()
    return show_modes()


if __name__ == "__main__":
    sys.exit(main())
