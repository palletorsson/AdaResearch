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
WALK = REPO / "ada_run" / "em_layout_walk.json"
CARDS = REPO / "ada_run" / "em_showing_cards.json"      # the WALL works — position and cell, no facing          # the engine's own record — the ONLY source of positions
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


# ── the wall cards ───────────────────────────────────────────────────────────────
## A wall card records `cell` in its hall's own grid, so asking what is beside it needs no
## arithmetic of ours — we index the engine's grid with the engine's index. The four-neighbour
## test IS ours, though: a card with no not-floor neighbour is a CANDIDATE, not a conviction,
## because the museum may legitimately mount one on something the grid does not mark solid.
## Only the engine can settle that, by recording what each card actually mounted on.
NOT_FLOOR = "#s"


def cards_by_hall() -> dict:
    d = load_json(CARDS, "the wall card record")
    rows = (d or {}).get("cards") or []
    out: dict = {}
    for c in rows:
        out.setdefault("%s|%s" % (c.get("chapter"), c.get("pearl")), []).append(c)
    return out


def grid_at(grid: list, cx: int, cz: int) -> str:
    if 0 <= cz < len(grid) and 0 <= cx < len(grid[cz]):
        return grid[cz][cx]
    return ""


def card_state(grid: list, c: dict) -> str:
    """What the card is mounted on, by the ENGINE's own answer.

    Before 2026-09-19 the museum recorded only a cell, so this asked whether any of four
    neighbours was solid — our guess, not the museum's, and it could never say what a card was
    supposed to hang on. The museum now writes `normal` and `backing_cell`: the cell one step
    back along the card's own outward normal, which IS the wall it is proud of. A card from
    before that change is 'unrecorded' and is NOT guessed at.
    """
    bc = c.get("backing_cell")
    if not bc or len(bc) < 2:
        return "unrecorded"
    ch = grid_at(grid, int(bc[0]), int(bc[1]))
    if not ch:
        return "backing_off_grid"
    return "mounted" if ch in NOT_FLOOR else "on_air"


def backing_char(grid: list, c: dict) -> str:
    bc = c.get("backing_cell") or []
    return grid_at(grid, int(bc[0]), int(bc[1])) if len(bc) >= 2 else ""


def score_cards(key: str, hall: dict, cards: list) -> dict:
    grid = hall.get("cells") or []
    tally = {"mounted": 0, "on_air": 0, "backing_off_grid": 0, "unrecorded": 0}
    flagged, skew = [], []
    for c in cards:
        st = card_state(grid, c)
        tally[st] = tally.get(st, 0) + 1
        if st not in ("mounted", "unrecorded"):
            flagged.append({"id": c.get("id"), "cell": c.get("cell"), "backing_cell": c.get("backing_cell"),
                            "backing": backing_char(grid, c), "world": c.get("world"), "state": st})
        f = c.get("facing_deg")
        if f is not None and off_square(float(f)) > SQUARE_TOL_DEG:
            skew.append({"id": c.get("id"), "facing_deg": f, "off_deg": round(off_square(float(f)), 2)})
    return {"key": key, "cards": len(cards), "flagged": flagged, "skew": skew, **tally}


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
    """A TOP VIEW per hall: the museum's own cell grid, with its wall cards and artifacts on it.

    Every mark is placed by a cell the engine recorded, never by arithmetic of ours, so this
    page cannot drift from the museum the way a re-derived drawing would.
    """
    walk = load_json(WALK, "the museum's own record")
    if walk is None:
        return 1
    halls = walk.get("halls") or {}
    by_hall = cards_by_hall()
    table = modes()
    OUT.mkdir(parents=True, exist_ok=True)
    CS = 15                       # pixels per cell
    FLOOR, SOLID, SEAL = "#2b3040", "#616a80", "#8a6a4a"
    index, totals = [], {"mounted": 0, "on_air": 0, "backing_off_grid": 0, "unrecorded": 0}
    for key, hall in sorted(halls.items()):
        grid = hall.get("cells") or []
        if not grid:
            continue
        cards = by_hall.get(key, [])
        sc = score_cards(key, hall, cards)
        for k in totals:
            totals[k] += sc[k]
        mode, pinned = mode_of(table, key)
        cols = max(len(r) for r in grid)
        w, h = cols * CS, len(grid) * CS
        top = 46
        parts = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">'
                 % (w + 2, h + top + 10, w + 2, h + top + 10),
                 '<rect width="100%%" height="100%%" fill="#14161c"/>',
                 '<text x="6" y="19" fill="#e6e9f2" font-family="monospace" font-size="14">%s</text>' % key,
                 '<text x="6" y="36" fill="#9aa3b8" font-family="monospace" font-size="11">'
                 '%s &#183; %d wall cards: <tspan fill="#6fbf73">%d on a wall</tspan>, '
                 '<tspan fill="#e2603c">%d backed by open floor</tspan>, '
                 '<tspan fill="#9aa3b8">%d off grid, %d not yet re-recorded</tspan></text>'
                 % (mode, sc["cards"], sc["mounted"], sc["on_air"], sc["backing_off_grid"], sc["unrecorded"])]
        for z, row in enumerate(grid):
            for x, ch in enumerate(row):
                col = SOLID if ch == "#" else (SEAL if ch == "s" else FLOOR)
                parts.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" stroke="#1b1f29" stroke-width="0.5"/>'
                             % (x * CS + 1, z * CS + top, CS, CS, col))
                if ch == "p":
                    parts.append('<circle cx="%.1f" cy="%.1f" r="2" fill="#c8b06a"/>'
                                 % (x * CS + 1 + CS / 2, z * CS + top + CS / 2))
        for b in (hall.get("bodies") or []):
            tc = b.get("tile_cell") or []
            if len(tc) < 2:
                continue
            cx, cy = int(tc[0]) * CS + 1 + CS / 2, int(tc[1]) * CS + top + CS / 2
            parts.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="#7fb3d5" stroke-width="1.4"/>'
                         % (cx, cy, CS * 0.34))
        for c in cards:
            cell = c.get("cell") or []
            if len(cell) < 2:
                continue
            st = card_state(grid, c)
            col = {"mounted": "#6fbf73", "on_air": "#e2603c",
                   "backing_off_grid": "#9aa3b8", "unrecorded": "#4a5064"}[st]
            cx, cy = int(cell[0]) * CS + 1, int(cell[1]) * CS + top
            parts.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" fill-opacity="0.85" stroke="#0b0d12" stroke-width="0.6"/>'
                         % (cx + CS * 0.22, cy + CS * 0.22, CS * 0.56, CS * 0.56, col))
        parts.append("</svg>")
        name = key.replace("|", "__").replace("/", "_") + ".svg"
        (OUT / name).write_text("\n".join(parts), encoding="utf-8")
        index.append((key, name, sc, mode))
    rows = "\n".join(
        '<li><a href="%s">%s</a> &#183; %s &#183; %d cards, <b style="color:#6fbf73">%d</b> mounted, '
        '<b style="color:#e2603c">%d</b> backed by open floor, %d off grid, %d not re-recorded</li>'
        % (n, k, m, s["cards"], s["mounted"], s["on_air"], s["backing_off_grid"], s["unrecorded"])
        for k, n, s, m in sorted(index, key=lambda r: -r[2]["on_air"]))
    (OUT / "index.html").write_text(
        '<html><head><meta charset="utf-8"><title>museum top view</title>'
        '<style>body{background:#14161c;color:#d8dbe4;font-family:monospace;padding:24px;max-width:1100px}'
        'a{color:#7fb3d5}li{margin:4px 0}b{font-weight:600}</style></head><body>'
        '<h2>The museum from above</h2>'
        '<p>Each page is one hall as the museum itself recorded it: its own cell grid, its own cell '
        'indices. Nothing here is re-derived.</p>'
        '<p><b>Grey cells</b> are not floor, which is what a card can hang on. <b>Dark cells</b> are '
        'floor. <b>Brown</b> is a cell sealed by a body. <b>Blue rings</b> are floor artifacts. '
        '<b>Squares are the wall cards</b>: green is mounted on a wall, '
        '<span style="color:#e2603c">orange is backed by open floor</span>, grey backs onto a '
        'cell outside the grid, and a dim square is a card written before the museum began '
        'recording its mount.</p>'
        '<p>Since 2026-09-19 the museum records each card&#39;s outward normal and the cell it is '
        'proud of, so an orange square is the engine&#39;s OWN answer and not our guess: one step '
        'back along that card&#39;s own normal is open floor. Cards from before that change are '
        'not guessed at.</p>'
        '<p><b>%d cards over %d halls: %d on a wall, %d backed by open floor, %d off grid, '
        '%d not yet re-recorded.</b></p>'
        '<ul>%s</ul></body></html>'
        % (sum(totals.values()), len(index), totals["mounted"], totals["on_air"],
           totals["backing_off_grid"], totals["unrecorded"], rows),
        encoding="utf-8")
    print("wall cards over %d halls: %d on a wall, %d backed by open floor, %d off grid, %d not re-recorded"
          % (len(index), totals["mounted"], totals["on_air"], totals["backing_off_grid"], totals["unrecorded"]))
    print("top view -> %s" % (OUT / "index.html"))
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
