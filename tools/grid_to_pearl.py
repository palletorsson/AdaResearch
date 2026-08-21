#!/usr/bin/env python3
"""grid_to_pearl — the GRID's curated placements, translated into the BOOK.

    python tools/grid_to_pearl.py --dry          # measure all 213 pearls, write the report
    python tools/grid_to_pearl.py --dry --chapter=primitives

Every spine pearl already names its grid map (213/213 measured 2026-08-21), and
the book's line vocabulary already carries everything the museum needs: `lock`
pins a body to a tile cell (spine_run.py:234), `support_m` asks for a plinth
(_stamp honours it via em_plinths), `count`/`spread`/`gap_cells` hold a
COLLECTION — a run of identical artifacts as one line ("I want the collection
of artifact if they are the same in a row"). So the translation is:

    grid interactable at (x,z)      -> line {token, by:"grid", lock:[x,z], rotation}
    structure "2" under a body      -> support_m (the 1 m stand becomes a plinth)
    a same-token run, even spacing  -> ONE line {token, count, spread, gap_cells}
    structure 3..5                  -> stages (raised plateaus)
    structure "0" inside the hull   -> cells holes; walls stay walls
    utilities (sp/t/r/m/...)        -> NOT translated — the museum has its own doors

--dry translates nothing: it reads every pearl's map, measures extent against
the plan's own room, finds the collections, counts the plinths, and writes
doc/reports/grid_to_pearl_dry.md. The write mode comes after the report is read.
"""
import argparse, json, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BOOK = REPO / "commons" / "data" / "book"
MAPS = REPO / "commons" / "maps"
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"
PLAN = REPO / "ada_run" / "em_plan.json"
OUT = REPO / "doc" / "reports" / "grid_to_pearl_dry.md"


def spine_chapters():
    spine = json.loads(SPINE.read_text(encoding="utf-8"))
    return [s["name"] for s in spine["spine"]["sequences"]]


def load_map(name):
    p = MAPS / name / "map_data.json"
    if not p.exists():
        return None
    return json.loads(p.read_text(encoding="utf-8"))


def parse_token(cell):
    """'token[:rot[:y]]' with optional '#config' attachment; leading '#' flags."""
    cell = cell.strip()
    if not cell:
        return None
    flagged = cell.startswith("#")
    if flagged:
        cell = cell[1:]
    head = cell.split("#", 1)[0]
    parts = head.split(":")
    token = parts[0]
    rot = parts[1] if len(parts) > 1 else ""
    y = parts[2] if len(parts) > 2 else ""
    return {"token": token, "rot": rot, "y": y, "flagged": flagged,
            "config": "#" in cell}


def measure(mapdoc):
    """One map's translation ledger — nothing is written anywhere."""
    L = mapdoc.get("layers", {})
    structure = L.get("structure", [])
    inter = L.get("interactables", [])
    utils = L.get("utilities", [])

    # the hull: bounding box of standing ground (structure != "0")
    xs, zs = [], []
    plinth_cells = set()
    stage_cells = 0
    hole_cells = 0
    for z, row in enumerate(structure):
        for x, c in enumerate(row):
            c = str(c).strip()
            if c and c != "0":
                xs.append(x)
                zs.append(z)
                try:
                    h = int(c)
                except ValueError:
                    h = 1
                if h == 2:
                    plinth_cells.add((x, z))
                elif h >= 3:
                    stage_cells += 1
            elif c == "0":
                hole_cells += 1
    extent = (max(xs) - min(xs) + 1, max(zs) - min(zs) + 1) if xs else (0, 0)

    # the bodies
    bodies = []           # {token, x, z, plinth, flagged, config}
    for z, row in enumerate(inter):
        for x, c in enumerate(row):
            t = parse_token(str(c))
            if t is None:
                continue
            t["x"], t["z"] = x, z
            t["plinth"] = (x, z) in plinth_cells
            bodies.append(t)

    # THE COLLECTIONS: same token, straight line (along x or z), even spacing.
    # Greedy: sort by token, sweep rows then columns; a run of >= 2 becomes one
    # collection line {token, count, spread, gap_cells}.
    taken = set()
    collections = []
    by_token = {}
    for i, b in enumerate(bodies):
        by_token.setdefault(b["token"], []).append(i)
    for tok, idxs in by_token.items():
        if len(idxs) < 2:
            continue
        for axis, other in (("x", "z"), ("z", "x")):
            lanes = {}
            for i in idxs:
                if i in taken:
                    continue
                lanes.setdefault(bodies[i][other], []).append(i)
            for lane, lane_is in lanes.items():
                if len(lane_is) < 2:
                    continue
                lane_is.sort(key=lambda i: bodies[i][axis])
                run = [lane_is[0]]
                for i in lane_is[1:]:
                    gap = bodies[i][axis] - bodies[run[-1]][axis]
                    prev_gap = (bodies[run[1]][axis] - bodies[run[0]][axis]) if len(run) > 1 else gap
                    if gap == prev_gap:
                        run.append(i)
                    else:
                        if len(run) >= 2:
                            collections.append(_run_row(bodies, run, axis))
                            taken.update(run)
                        run = [run[-1], i] if False else [i]
                if len(run) >= 2:
                    collections.append(_run_row(bodies, run, axis))
                    taken.update(run)

    singles = [b for i, b in enumerate(bodies) if i not in taken]
    util_kinds = {}
    for row in utils:
        for c in row:
            c = str(c).strip()
            if not c:
                continue
            kind = c.lstrip("#@").split(":")[0]
            util_kinds[kind] = util_kinds.get(kind, 0) + 1

    return {"extent": extent, "bodies": len(bodies), "singles": len(singles),
            "collections": collections, "plinths": sum(1 for b in bodies if b["plinth"]),
            "stage_cells": stage_cells, "holes": hole_cells,
            "flagged": sum(1 for b in bodies if b["flagged"]),
            "configs": sum(1 for b in bodies if b["config"]),
            "utils": util_kinds}


def _run_row(bodies, run, axis):
    gap = bodies[run[1]][axis] - bodies[run[0]][axis] if len(run) > 1 else 1
    return {"token": bodies[run[0]]["token"], "count": len(run),
            "spread": axis, "gap_cells": gap,
            "at": (bodies[run[0]]["x"], bodies[run[0]]["z"])}


def plan_rooms():
    """chapter|pearl -> room dims from the museum's own plan."""
    if not PLAN.exists():
        return {}
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    out = {}
    for row in plan.get("plans", []):
        room = row.get("room")
        dims = None
        if isinstance(room, dict):
            w = room.get("w", room.get("width"))
            d = room.get("d", room.get("depth", room.get("h")))
            if w and d:
                dims = (int(w), int(d))
        elif isinstance(room, (list, tuple)) and len(room) >= 2:
            dims = (int(room[0]), int(room[1]))
        out["%s|%s" % (row.get("sequence", ""), row.get("pearl", ""))] = {
            "dims": dims, "apron": row.get("apron")}
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--chapter", default="")
    args = ap.parse_args()
    if not args.dry:
        print("only --dry exists so far — the write mode comes after the report is read")
        return 2

    rooms = plan_rooms()
    lines = ["# grid_to_pearl — the dry run",
             "",
             "One row per pearl: the grid map measured against the museum's own room.",
             "`bodies a->b` = raw artifact cells -> lines after collections fold runs.",
             "", "| # | chapter · pearl | map | extent | room | bodies | collections | plinths | stages | utils |",
             "|---|---|---|---|---|---|---|---|---|---|"]
    n = 0
    tot = {"bodies": 0, "after": 0, "coll": 0, "plinth": 0, "missing": [], "overflow": [],
           "flagged": 0, "configs": 0}
    coll_examples = []
    for ch in spine_chapters():
        if args.chapter and ch != args.chapter:
            continue
        bp = BOOK / ("%s.json" % ch)
        if not bp.exists():
            continue
        book = json.loads(bp.read_text(encoding="utf-8"))
        for pl in book.get("pearls", []):
            if pl.get("drop"):
                continue
            n += 1
            mp = pl.get("map", "")
            doc = load_map(mp) if mp else None
            if doc is None:
                tot["missing"].append("%s · %s -> %s" % (ch, pl.get("pearl"), mp or "(no map)"))
                lines.append("| %d | %s · %s | %s | MISSING | | | | | | |" % (n, ch, pl.get("pearl"), mp))
                continue
            m = measure(doc)
            after = m["singles"] + len(m["collections"])
            room = rooms.get("%s|%s" % (ch, pl.get("pearl", "")), {})
            dims = room.get("dims")
            fit = ""
            if dims:
                if m["extent"][0] > dims[0] or m["extent"][1] > dims[1]:
                    fit = " **OVER**"
                    tot["overflow"].append("%s · %s: map %dx%d vs room %dx%d" % (
                        ch, pl.get("pearl"), m["extent"][0], m["extent"][1], dims[0], dims[1]))
            tot["bodies"] += m["bodies"]
            tot["after"] += after
            tot["coll"] += len(m["collections"])
            tot["plinth"] += m["plinths"]
            tot["flagged"] += m["flagged"]
            tot["configs"] += m["configs"]
            for cRow in m["collections"][:2]:
                if len(coll_examples) < 20:
                    coll_examples.append("%s · %s: %d× %s along %s every %d cell(s)" % (
                        ch, pl.get("pearl"), cRow["count"], cRow["token"], cRow["spread"], cRow["gap_cells"]))
            lines.append("| %d | %s · %s | %s | %dx%d%s | %s | %d->%d | %d | %d | %d | %s |" % (
                n, ch, pl.get("pearl"), mp, m["extent"][0], m["extent"][1], fit,
                ("%dx%d" % dims) if dims else "?", m["bodies"], after,
                len(m["collections"]), m["plinths"], m["stage_cells"],
                " ".join("%s:%d" % kv for kv in sorted(m["utils"].items())) or "—"))

    lines += ["", "## totals",
              "- pearls measured: %d" % n,
              "- bodies: %d raw -> %d lines after %d collections fold their runs" % (
                  tot["bodies"], tot["after"], tot["coll"]),
              "- plinths (structure 2 under a body): %d" % tot["plinth"],
              "- bodies with a #config attachment: %d · #-flagged cells: %d" % (tot["configs"], tot["flagged"]),
              "- maps missing: %d" % len(tot["missing"]),
              "- maps larger than their museum room: %d" % len(tot["overflow"]), ""]
    if tot["overflow"]:
        lines += ["### the overflows (the bed must grow, or the constellation must breathe)", ""]
        lines += ["- " + s for s in tot["overflow"]]
        lines.append("")
    if coll_examples:
        lines += ["### collections found (first 20)", ""]
        lines += ["- " + s for s in coll_examples]
        lines.append("")
    if tot["missing"]:
        lines += ["### pearls whose map is missing", ""]
        lines += ["- " + s for s in tot["missing"]]
        lines.append("")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print("DRY: %d pearls · %d bodies -> %d lines (%d collections) · %d plinths · %d overflow · %d missing" % (
        n, tot["bodies"], tot["after"], tot["coll"], tot["plinth"], len(tot["overflow"]), len(tot["missing"])))
    print("report -> %s" % OUT.relative_to(REPO))
    return 0


if __name__ == "__main__":
    sys.exit(main())
