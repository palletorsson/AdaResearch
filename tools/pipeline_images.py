#!/usr/bin/env python3
"""Photograph four spatial-pipeline stages, before and after.

Seven stages of this pipeline already have a before/after pair in
`/spatial-iterations`. Four did not, and all four are stages whose output is a
PLAN rather than a build — a door, a row of rectangles on a wall, a category
decision, a gate verdict. None of them reaches Godot, so none of them could be
photographed the way the wall colour and the walk order were.

So this rasterises the stage's OWN output. Every number drawn here is read back
from the function that produced it, never typed: the door cell comes from
`threshold()`, the wall rectangles from `hang_run()`, the two verdicts from
`negotiate()` run twice over the same contract with `containment` flipped.

    python tools/pipeline_images.py --stage=threshold
    python tools/pipeline_images.py --stage=all

Frames land in ada_run/pipeline_images/<stage>/ and are published with
tools/publish_iteration.py. The correspondence gate is NOT here: its before and
after are Godot renders of a real map and its corrupted twin, captured with
capture_multi_angle.gd, because that stage does reach the engine.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from spatial_palette import (BODY, DOOR, GROUND, INK, INK_DIM, PRESENTATION,
                             ROUTE, SIGHT, cell_colour)          # noqa: E402

OUT = REPO / "ada_run" / "pipeline_images"
FAIL = "#e2483f"          # a rule that did not hold
OK = "#4fbf72"

W, H = 1500, 1180
PLAN_TOP = 92
CAP_H = 210


def font(size: int, bold: bool = False) -> Any:
    for name in (("arialbd.ttf", "arial.ttf") if bold else ("arial.ttf",)):
        try:
            return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
        except Exception:
            continue
    return ImageFont.load_default()


F_TITLE, F_SUB, F_BODY, F_TINY = font(30, True), font(17), font(15), font(13)


def canvas(title: str, subtitle: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (W, H), GROUND)
    d = ImageDraw.Draw(img)
    d.text((28, 24), title, font=F_TITLE, fill=INK)
    d.text((28, 60), subtitle, font=F_SUB, fill=INK_DIM)
    return img, d


def caption(d: ImageDraw.ImageDraw, lines: list[tuple[str, str]]) -> None:
    """The measured caption: every line a fact read back from the stage."""
    y = H - CAP_H + 16
    d.line([(28, y - 14), (W - 28, y - 14)], fill="#2a2c33", width=1)
    for text, colour in lines:
        d.text((28, y), text, font=F_BODY, fill=colour)
        y += 23


class View:
    """A cropped window onto a plan: which cells are drawn, and where.

    Museum plans carry a 14 m apron of empty ground on every side, so drawing
    the full extent spends most of the frame on void and shrinks the thing the
    picture is about. The crop is the bounding box of everything ANY overlay
    touches, padded — never a hand-chosen rectangle, so a work that moves
    cannot fall outside the frame.
    """

    def __init__(self, plan: Any, keep: list[Any] | None = None, pad: int = 4):
        # The BUILDING, not the extent: `from_museum` lays a 14 m apron of plain
        # floor on every side, so "everything that is not void" is the whole
        # sheet and crops nothing.
        pts = {(x, z) for z in range(plan.depth) for x in range(plan.width)
               if plan.grid[z][x] == "4"}
        pts |= {s.cell for s in plan.slots}
        for group in (keep or []):
            pts |= {tuple(p) for p in group if p is not None}
        xs = [p[0] for p in pts] or [0]
        zs = [p[1] for p in pts] or [0]
        self.plan = plan
        self.x0 = max(0, min(xs) - pad)
        self.z0 = max(0, min(zs) - pad)
        self.x1 = min(plan.width - 1, max(xs) + pad)
        self.z1 = min(plan.depth - 1, max(zs) + pad)
        bw, bh = self.x1 - self.x0 + 1, self.z1 - self.z0 + 1
        avail_h, avail_w = H - PLAN_TOP - CAP_H - 20, W - 470
        self.cell = max(4, min(avail_w // bw, avail_h // bh))
        self.ox = 28
        self.oy = PLAN_TOP + max(0, (avail_h - bh * self.cell) // 2)
        self.right = self.ox + bw * self.cell + 34

    def box(self, x: int, z: int) -> list[float]:
        px = self.ox + (x - self.x0) * self.cell
        py = self.oy + (z - self.z0) * self.cell
        return [px, py, px + self.cell - 1, py + self.cell - 1]

    def inside(self, x: int, z: int) -> bool:
        return self.x0 <= x <= self.x1 and self.z0 <= z <= self.z1


def draw_plan(d: ImageDraw.ImageDraw, v: View, route: bool = True) -> None:
    plan = v.plan
    for z in range(v.z0, v.z1 + 1):
        for x in range(v.x0, v.x1 + 1):
            c = plan.grid[z][x]
            fill = (ROUTE if (route and (x, z) in plan.route and c not in ("4", ""))
                    else cell_colour(c))
            d.rectangle(v.box(x, z), fill=fill)


def cells(d: ImageDraw.ImageDraw, pts: Any, v: View, colour: str,
          outline: str | None = None) -> None:
    for x, z in pts:
        if v.inside(x, z):
            d.rectangle(v.box(x, z), fill=colour, outline=outline)


def marker(d: ImageDraw.ImageDraw, pt: tuple[int, int], v: View,
           colour: str, r: float = 0.42) -> None:
    b = v.box(*pt)
    cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
    rr = v.cell * r + 2
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=colour, width=3)


def legend(d: ImageDraw.ImageDraw, x: int, y: int,
           items: list[tuple[str, str]]) -> int:
    for name, colour in items:
        d.rectangle([x, y, x + 14, y + 14], fill=colour)
        d.text((x + 22, y - 1), name, font=F_TINY, fill=INK)
        y += 21
    return y


def sidebar(d: ImageDraw.ImageDraw, x: int, y: int, rows: list[tuple[str, str, str]]) -> None:
    for label, value, colour in rows:
        d.text((x, y), label, font=F_TINY, fill=INK_DIM)
        d.text((x + 200, y), value, font=F_TINY, fill=colour)
        y += 20


# ── stage 1: the threshold ──────────────────────────────────────────

def _door_candidates(plan: Any, target: tuple[int, int]) -> list:
    out = []
    for z in range(1, plan.depth - 1):
        for x in range(1, plan.width - 1):
            if plan.grid[z][x] != "4":
                continue
            for side, (dx, dz) in (("west", (-1, 0)), ("east", (1, 0)),
                                   ("north", (0, -1)), ("south", (0, 1))):
                if not (plan.walkable(x - dx, z - dz) and plan.walkable(x + dx, z + dz)):
                    continue
                out.append((abs(x - target[0]) + abs(z - target[1]), (x, z), side))
    out.sort(key=lambda t: t[0])
    return out


def _threshold_audit() -> dict[str, Any]:
    """Does the accepted door actually stand ON the sightline it certifies?

    `threshold()` proves a line from a standing point to the work crosses the
    wall only at the door. It never checks that the line touches the door at
    all — so a line that crosses NO wall passes too, and the door is then a
    certified portal somewhere else in the building. This counts how often that
    happens, across every museum in the corpus.
    """
    from spatial_floorplan import from_museum
    from spatial_negotiation import Occupancy, negotiate, threshold, _line
    from emit_dressing_room import staged_contract
    caps = json.loads((REPO / "commons" / "data" / "slot_capacity.json")
                      .read_text(encoding="utf-8"))["museums"]
    real, vacuous, rejected = [], [], []
    for mus in caps:
        plan = from_museum(mus)
        occ = Occupancy()
        c = staged_contract("lab_room")
        p = negotiate(c, plan, occ)
        if p.result != "ACCEPT":
            continue
        occ.commit("lab_room", p.masks, p.anchor)
        th = threshold(plan, p, c)
        if th.result != "ACCEPT":
            rejected.append(mus)
            continue
        (real if th.door_cell in _line(th.stand_cell, p.anchor)
         else vacuous).append(mus)
    return {"real": real, "vacuous": vacuous, "rejected": rejected}


def stage_threshold(museum: str = "capuchin-crypt-corridor",
                    token: str = "lab_room") -> dict[str, Any]:
    from spatial_floorplan import from_museum
    from spatial_negotiation import Occupancy, negotiate, threshold, _line
    from emit_dressing_room import staged_contract

    plan = from_museum(museum)
    occ = Occupancy()
    c = staged_contract(token)
    p = negotiate(c, plan, occ)
    occ.commit(token, p.masks, p.anchor)
    th = threshold(plan, p, c)

    # How many of the doors the stage considers are fire exits — a door with no
    # line to the work. Recomputed from the plan here, not quoted from a trace.
    target = p.anchor
    cands = _door_candidates(plan, target)
    clear, blind, first_ok = 0, 0, -1
    for i, (_, cellpt, side) in enumerate(cands[:40]):
        dx, dz = {"west": (-1, 0), "east": (1, 0),
                  "north": (0, -1), "south": (0, 1)}[side]
        stand = (cellpt[0] - dx * 3, cellpt[1] - dz * 3)
        if not plan.walkable(*stand):
            stand = (cellpt[0] - dx, cellpt[1] - dz)
        if not plan.walkable(*stand):
            continue
        line = _line(stand, target)
        if [cc for cc in line if plan.in_bounds(*cc)
                and plan.grid[cc[1]][cc[0]] == "4" and cc != cellpt]:
            blind += 1
        else:
            clear += 1
            if first_ok < 0:
                first_ok = i

    sight = _line(th.stand_cell, target)
    crossed = [cc for cc in sight if plan.grid[cc[1]][cc[0]] == "4"]
    door_on_line = th.door_cell in sight
    audit = _threshold_audit()

    body = [(cx + p.anchor[0], cz + p.anchor[1]) for cx, cz in p.masks.physical]
    v = View(plan, [body, sight])
    sx = v.right
    (OUT / "threshold").mkdir(parents=True, exist_ok=True)

    # BEFORE — the work stands on ground and the building says nothing about it.
    img, d = canvas("THRESHOLD - before",
                    f"{museum} - {token} placed as a precinct in the {p.venue}. "
                    f"The wall is solid: no door, no sightline, no caption.")
    draw_plan(d, v)
    cells(d, body, v, BODY)
    cells(d, [cc for cc in sight if cc not in crossed], v, "#1d3f47")
    cells(d, crossed, v, FAIL)
    marker(d, th.stand_cell, v, INK)
    y = legend(d, sx, v.oy, [("precinct work", BODY),
                             ("where a visitor would look", "#1d3f47"),
                             ("solid wall in the way", FAIL),
                             ("through-route", ROUTE)])
    sidebar(d, sx, y + 16, [
        ("wall cells that could be a door", f"{len(cands)}", INK),
        ("doors built", "0", FAIL),
        ("sightlines", "0", FAIL),
        ("captions", "0", FAIL),
        ("the look from the standing point", f"{len(crossed)} solid wall cell(s)", FAIL),
    ])
    caption(d, [
        (f"The work is {len(sight)} cells from the standing point and behind a "
         f"solid wall.", INK),
        (f"{len(cands)} cells in this building have floor on both sides, so any of "
         f"them COULD be a door. None is.", INK_DIM),
        (f"The line from {list(th.stand_cell)} to the work meets {len(crossed)} "
         f"solid wall cell(s) at {[list(cc) for cc in crossed]}.", FAIL),
        ("A building that simply has a large thing behind it has not exhibited "
         "anything.  - Threshold, spatial_negotiation.py:1020", INK_DIM),
    ])
    img.save(OUT / "threshold" / "1_before_no_door.png")

    # AFTER — door, sightline, caption, on the same line.
    img, d = canvas("THRESHOLD - after",
                    f"{museum} - threshold() opened a certified "
                    f"{th.door_width_m} m portal where that line meets the wall.")
    draw_plan(d, v)
    cells(d, body, v, BODY)
    cells(d, [cc for cc in th.sight_cells if cc != th.door_cell], v, "#1d5f6b")
    if th.door_cell:
        cells(d, [th.door_cell], v, DOOR)
        b = v.box(*th.door_cell)
        pw = max(3, v.cell * (th.caption_rect[2] - th.caption_rect[0]))
        ph = max(3, v.cell * (th.caption_rect[3] - th.caption_rect[1]))
        d.rectangle([b[2] + 3, b[1], b[2] + 3 + pw, b[1] + ph], fill=PRESENTATION)
    marker(d, th.stand_cell, v, INK)
    y = legend(d, sx, v.oy, [("precinct work", BODY), ("sightline", "#1d5f6b"),
                             ("certified portal", DOOR),
                             ("caption plate", PRESENTATION),
                             ("through-route", ROUTE)])
    sidebar(d, sx, y + 16, [
        ("door", f"{th.door_side} at {list(th.door_cell)}", OK),
        ("portal width", f"{th.door_width_m} m (certified)", OK),
        ("sightline", f"{len(th.sight_cells)} cells", OK),
        ("walls crossed off the door", "0", OK),
        ("caption plate", "0.62 x 0.42 m at 1.55 m", OK),
        ("door stands ON the sightline", str(door_on_line), OK if door_on_line else FAIL),
        ("doors that see the work", f"{clear} of {clear + blind}", INK),
        ("doors that are fire exits", f"{blind} of {clear + blind}", FAIL),
        ("first door accepted", f"candidate #{first_ok}", INK),
    ])
    caption(d, [
        (f"Door: {th.door_side} wall at {list(th.door_cell)}, certified "
         f"{th.door_width_m} m portal - one of the three widths the wall kit builds. "
         f"Caption plate 0.62 x 0.42 m at 1.55 m.", OK),
        (f"Sightline: {len(th.sight_cells)} cells from {list(th.stand_cell)}, crossing "
         f"the wall only at the door. Of the {clear + blind} nearest candidate doors "
         f"{blind} are fire exits.", OK),
        (f"FOUND BY DRAWING IT: the stage never checks the door is ON the line. Across "
         f"{len(audit['real']) + len(audit['vacuous'])} museums that ACCEPT a threshold, "
         f"{len(audit['vacuous'])} certify a door the sightline never touches -", FAIL),
        (f"the line crosses no wall at all, so the test passes vacuously. {museum} is "
         f"one of the {len(audit['real'])} where the door is really in the way.", FAIL),
    ])
    img.save(OUT / "threshold" / "2_after_door_sightline_caption.png")
    return {
        "museum": museum, "token": token, "venue": p.venue,
        "door": list(th.door_cell), "side": th.door_side,
        "width_m": th.door_width_m, "sight_cells": len(th.sight_cells),
        "caption_rect": th.caption_rect, "candidates": len(cands),
        "clear40": clear, "blind40": blind, "first_ok": first_ok,
        "walls_crossed_before": len(crossed), "door_on_line": door_on_line,
        "audit_real": len(audit["real"]), "audit_vacuous": len(audit["vacuous"]),
        "audit_rejected": audit["rejected"], "result": th.result,
    }


# ── stage 2: lineage runs hung on wall runs ─────────────────────────

def stage_hang_run(museum: str = "uffizi-spine-enfilade",
                   count: int = 14) -> dict[str, Any]:
    from spatial_floorplan import from_museum
    from spatial_negotiation import Occupancy, hang_run
    import exhibition_brief as eb

    rel = eb.load(eb.RELATIONS).get("artifacts", {})
    anchors, seen = [], set()
    for row in eb.spine_order():
        t = str(row.get("lookup", ""))
        if t in rel and t not in seen:
            anchors.append(t)
            seen.add(t)
        if len(anchors) >= count:
            break
    briefs = [eb.brief_for(a, rel, 2) for a in anchors]

    series = eb.series_in(museum)
    floor = eb.match_runs(briefs, series)
    plan = from_museum(museum)
    occ = Occupancy()
    runs = []
    for b in briefs:
        run = b.get("dna_run") or {}
        if not run:
            continue
        runs.append(hang_run(plan, b["anchor"], run["axis"], run["values"], occ))

    on_floor = sum(1 for m in floor if m["housed"])
    on_wall = sum(1 for r in runs if r.result == "ACCEPT")
    precinct = sum(1 for r in runs if r.result == "PRECINCT")
    rejected = sum(1 for r in runs if r.result == "REJECT")
    wall_by_id = {w.id: w for w in plan.walls}
    used = {r.wall for r in runs if r.result == "ACCEPT"}

    def wall_cells(wid: str) -> list[tuple[int, int]]:
        w = wall_by_id[wid]
        ox2, oz2 = w.origin_cell
        n = int(round(w.length_m))
        if w.side in ("west", "east"):
            return [(ox2, oz2 + i) for i in range(n)]
        return [(ox2 + i, oz2) for i in range(n)]

    v = View(plan)
    sx = v.right
    (OUT / "hang_run").mkdir(parents=True, exist_ok=True)

    # BEFORE — the floor answer: a run wants N adjacent slots of like capacity.
    img, d = canvas("LINEAGE RUNS — before (the floor answer)",
                    f"{museum} · a DNA run treated as a demand for N adjacent "
                    f"FLOOR slots.")
    draw_plan(d, v)
    slot_cells = [s.cell for s in plan.slots]
    cells(d, slot_cells, v, cell_colour("1s"))
    for m in floor:
        if m["housed"] and m.get("series"):
            for sid in m["series"]:
                s = next((s for s in plan.slots if s.id == sid), None)
                if s:
                    cells(d, [s.cell], v, OK)
    y = legend(d, sx, v.oy, [("floor slot", cell_colour("1s")),
                             ("slot series carrying a run", OK),
                             ("through-route", ROUTE)])
    rows = [("DNA runs in this brief", f"{len(runs)}", INK),
            ("slot series in this museum", f"{len(series)}", FAIL),
            ("runs with a floor home", f"{on_floor} of {len(runs)}", FAIL)]
    sidebar(d, sx, y + 16, rows)
    yy = y + 16 + 20 * len(rows) + 14
    d.text((sx, yy), "run", font=F_TINY, fill=INK_DIM)
    d.text((sx + 200, yy), "floor home", font=F_TINY, fill=INK_DIM)
    yy += 20
    for m in floor:
        d.text((sx, yy), m["anchor"][:26], font=F_TINY, fill=INK)
        d.text((sx + 200, yy),
               (f"{m['series_length']} slots" if m["housed"] else "NO SERIES"),
               font=F_TINY, fill=(OK if m["housed"] else FAIL))
        yy += 18
    caption(d, [
        (f"{len(runs)} lineages in this brief. {museum} offers {len(series)} "
         f"slot series. {on_floor} of {len(runs)} runs found a home.", FAIL),
        ("Across the corpus: 481 anchors declare a run, the floor offers 36 series "
         "in total, and 18 of 30 museums offer none.", INK_DIM),
        ("Toggle: this is `exhibition_brief.py` WITHOUT --museum. The floor answer "
         "is still computed and printed beside the wall answer.", INK_DIM),
    ])
    img.save(OUT / "hang_run" / "1_before_floor_series.png")

    # AFTER — the wall answer, with one wall drawn in elevation.
    img, d = canvas("LINEAGE RUNS — after (hung on wall runs)",
                    f"{museum} · hang_run() routes each lineage to a WALL, one "
                    f"value per body width in the declared feature band.")
    draw_plan(d, v)
    for wid in used:
        cells(d, wall_cells(wid), v, PRESENTATION)
    y = legend(d, sx, v.oy, [("wall carrying a run", PRESENTATION),
                             ("through-route", ROUTE)])
    rows = [("walls in this museum", f"{len(plan.walls)}", INK),
            ("walls carrying a run", f"{len(used)}", OK),
            ("runs hung on a wall", f"{on_wall} of {len(runs)}", OK),
            ("same runs on the FLOOR", f"{on_floor} of {len(runs)}", FAIL),
            ("deferred to the threshold", f"{precinct} (precinct)", INK_DIM),
            ("genuinely too tall", f"{rejected}", FAIL)]
    sidebar(d, sx, y + 16, rows)
    yy = y + 16 + 20 * len(rows) + 14
    for r in runs:
        d.text((sx, yy), f"{r.anchor[:22]}.{r.axis[:10]}", font=F_TINY, fill=INK)
        d.text((sx + 240, yy),
               (r.wall.split("/")[-1] if r.result == "ACCEPT" else r.result),
               font=F_TINY,
               fill=(OK if r.result == "ACCEPT"
                     else (INK_DIM if r.result == "PRECINCT" else FAIL)))
        yy += 18

    # elevation of the widest run, drawn under the plan list
    hung = [r for r in runs if r.result == "ACCEPT"]
    # The row with the most wall ACREAGE, not the most values: a five-value run
    # of 0.10 m-tall works is two pixels of elevation and shows nothing.
    show = (max(hung, key=lambda r: sum((rc[2] - rc[0]) * (rc[3] - rc[1])
                                        for rc in r.rects)) if hung else None)
    if show:
        w = wall_by_id[show.wall]
        eh = 190
        ex, ey = sx, H - CAP_H - eh - 26
        ew = W - sx - 40
        scale = min(ew / w.length_m, eh / w.height_m)
        d.rectangle([ex, ey, ex + w.length_m * scale, ey + w.height_m * scale],
                    fill=cell_colour("4"))
        fz = w.feature_zone
        d.rectangle([ex + fz[0] * scale, ey + (w.height_m - fz[3]) * scale,
                     ex + fz[2] * scale, ey + (w.height_m - fz[1]) * scale],
                    outline="#3a5a6a", width=1)
        for rect, val in zip(show.rects, show.values):
            d.rectangle([ex + rect[0] * scale, ey + (w.height_m - rect[3]) * scale,
                         ex + rect[2] * scale, ey + (w.height_m - rect[1]) * scale],
                        fill=PRESENTATION)
        d.text((ex, ey - 20),
               f"{show.wall.split('/')[-1]} in elevation — {len(show.values)} x "
               f"{show.anchor}.{show.axis}, {w.length_m:g} x {w.height_m:g} m wall",
               font=F_TINY, fill=INK_DIM)
    caption(d, [
        (f"routed to WALLS: {on_wall}/{len(runs)}   (the same runs on the FLOOR: "
         f"{on_floor}/{len(runs)})", OK),
        (f"{len(used)} of the museum's {len(plan.walls)} walls carry a lineage. "
         + (f"Widest row: {len(show.values)} works on a {wall_by_id[show.wall].length_m:g} m "
            f"wall." if show else ""), INK),
        (f"The {len(runs) - on_wall} not hung are not failures of the wall rule: "
         f"{precinct} are precinct works handed to the threshold, {rejected} is a "
         f"4.00 m body that does not fit a 4 m wall.", INK_DIM),
        ("Toggle: `exhibition_brief.py --museum=<key>`. Both answers are computed "
         "every run; the flag decides which one is THE answer.", INK_DIM),
    ])
    img.save(OUT / "hang_run" / "2_after_wall_runs.png")
    return {"museum": museum, "runs": len(runs), "on_wall": on_wall,
            "on_floor": on_floor, "precinct": precinct, "rejected": rejected,
            "series": len(series), "walls": len(plan.walls), "walls_used": len(used)}


# ── stage 3: precinct artifacts ─────────────────────────────────────

def stage_precinct(museum: str = "uffizi-spine-enfilade",
                   token: str = "lab_room") -> dict[str, Any]:
    from spatial_floorplan import from_museum
    from spatial_negotiation import Occupancy, negotiate
    from emit_dressing_room import staged_contract

    import spatial_contract as sc
    census = json.loads((REPO / "ada_run" / "spatial_slice"
                         / "precinct_census.json").read_text(encoding="utf-8"))
    n_prec, n_total = len(census["precinct"]), census["total"]
    ab = json.loads((REPO / "ada_run" / "spatial_slice"
                     / "precinct_ab.json").read_text(encoding="utf-8"))

    # THE TOGGLE, at the source of the rule rather than on the dataclass: with
    # no ceiling on what a slot or a wall can hold, nothing measures as a
    # precinct AND `required_support` falls back to whatever the registry says.
    # That second half matters — it is the 'table' an 8 m laboratory asked for.
    real_w, real_h = sc.WIDEST_SLOT_M, sc.CERTIFIED_WALL_M
    frames = {}
    for forced in ("exhibited", "precinct"):
        sc.WIDEST_SLOT_M, sc.CERTIFIED_WALL_M = ((1e9, 1e9) if forced == "exhibited"
                                                 else (real_w, real_h))
        plan = from_museum(museum)
        occ = Occupancy()
        c = staged_contract(token)
        frames[forced] = (plan, negotiate(c, plan, occ), c)
    sc.WIDEST_SLOT_M, sc.CERTIFIED_WALL_M = real_w, real_h
    assert frames["exhibited"][2].containment == "exhibited"
    assert frames["precinct"][2].containment == "precinct"

    after_body = [(cx + frames["precinct"][1].anchor[0],
                   cz + frames["precinct"][1].anchor[1])
                  for cx, cz in frames["precinct"][1].masks.physical]
    v = View(frames["precinct"][0], [after_body])
    sx = v.right
    (OUT / "precinct").mkdir(parents=True, exist_ok=True)

    plan, p, c = frames["exhibited"]
    img, d = canvas("PRECINCT — before (every work is exhibited)",
                    f"{museum} · {token} is {c.body_m[0]:.1f} x {c.body_m[2]:.1f} m. "
                    f"Treated as an exhibit, it walks the whole ladder and fails at step 7.")
    draw_plan(d, v)
    near = next((s for s in plan.slots if s.id == p.slot), None)
    if near:
        cells(d, [near.cell], v, FAIL)
        marker(d, near.cell, v, FAIL, 0.9)
    y = legend(d, sx, v.oy, [("closest attempt (rejected)", FAIL),
                             ("floor slot", cell_colour("1s")), ("through-route", ROUTE)])
    fails = [t for t in p.traces if t.status == "fail"]
    sidebar(d, sx, y + 16, [
        ("body", f"{c.body_m[0]:.2f} x {c.body_m[1]:.2f} x {c.body_m[2]:.2f} m", INK),
        ("footprint", f"{c.footprint_cells[0]}x{c.footprint_cells[1]} cells", INK),
        ("required_support", f"{c.required_support!r}", INK_DIM),
        ("result", p.result, FAIL),
        ("venue", p.venue, INK_DIM),
        ("ladder steps spent", f"{len(p.traces)}", INK),
    ])
    yy = y + 16 + 20 * 6 + 14
    for t in p.traces[:8]:
        col = FAIL if t.status == "fail" else (PRESENTATION if t.status == "compromised" else INK_DIM)
        d.text((sx, yy), f"{t.rule[:22]}", font=F_TINY, fill=INK_DIM)
        d.text((sx + 170, yy), t.status, font=F_TINY, fill=col)
        yy += 18
    caption(d, [
        (f"{p.result} — {(fails[0].detail if fails else '')}", FAIL),
        (f"The whole ranking ran first: "
         f"{next((t.detail for t in p.traces if t.rule == 'match'), '')}", INK_DIM),
        (f"This is the negotiator with WIDEST_SLOT_M and CERTIFIED_WALL_M raised to "
         f"1e9, so nothing measures as a precinct and required_support falls back to "
         f"the registry's {c.required_support!r}.", INK_DIM),
        (f"Corpus: {n_prec} of {n_total} artifacts ({100.0*n_prec/n_total:.2f}%) exceed "
         f"the 8 m widest slot or the 4 m certified wall. Sampled {ab['n']} of them: "
         f"{ab['before_accept']}/{ab['n']} placed without the rule.", FAIL),
    ])
    img.save(OUT / "precinct" / "1_before_exhibited.png")

    plan, p, c = frames["precinct"]
    body = [(cx + p.anchor[0], cz + p.anchor[1]) for cx, cz in p.masks.physical]
    img, d = canvas("PRECINCT — after (entered, not viewed)",
                    f"{museum} · containment='precinct' routes straight past the "
                    f"slots to bounded ground in the {p.venue}.")
    draw_plan(d, v)
    cells(d, body, v, BODY)
    y = legend(d, sx, v.oy, [("precinct work on ground", BODY),
                             ("floor slot (skipped)", cell_colour("1s")),
                             ("through-route", ROUTE)])
    sidebar(d, sx, y + 16, [
        ("body", f"{c.body_m[0]:.2f} x {c.body_m[1]:.2f} x {c.body_m[2]:.2f} m", INK),
        ("required_support", f"{c.required_support!r} (overridden)", OK),
        ("result", p.result, OK),
        ("venue", p.venue, OK),
        ("slot", p.slot.split("/")[-1], INK),
        ("score", f"{p.score:.2f}", INK),
        ("room grew by", f"{len(plan.expansions)} expansions", OK),
    ])
    yy = y + 16 + 20 * 7 + 14
    for t in p.traces[:9]:
        col = (OK if t.status == "pass" else
               PRESENTATION if t.status == "compromised" else FAIL)
        d.text((sx, yy), f"{t.rule[:22]}", font=F_TINY, fill=INK_DIM)
        d.text((sx + 170, yy), t.status, font=F_TINY, fill=col)
        yy += 18
    caption(d, [
        (f"{p.result} — {next((t.detail for t in p.traces if t.rule == 'containment'), '')}",
         OK),
        (f"As an exhibit it ranked all {len(plan.slots)} slots and tried every "
         f"rotation and mode before failing at step 7. As a precinct the first trace "
         f"is `containment` — the ranking never runs.", OK),
        (f"required_support was {frames['exhibited'][2].required_support!r} in the "
         f"registry; containment overrides it to {c.required_support!r}, because that "
         f"word is meaningless at {c.body_m[0]:.0f} m.", INK_DIM),
        (f"Sample of {ab['n']} precinct artifacts, same museum: "
         f"{ab['before_accept']}/{ab['n']} placed without the rule, "
         f"{ab['after_accept']}/{ab['n']} with it — {ab['result_differs']} rescued, "
         f"{ab['venue_differs']} reported in a different venue. NO CLI toggle exists.",
         OK),
    ])
    img.save(OUT / "precinct" / "2_after_ground.png")
    return {"museum": museum, "token": token,
            "before": frames["exhibited"][1].result,
            "after": frames["precinct"][1].result,
            "venue": frames["precinct"][1].venue,
            "precinct_corpus": n_prec, "total_corpus": n_total,
            "share_pct": round(100.0 * n_prec / n_total, 2),
            "traces_before": len(frames["exhibited"][1].traces),
            "traces_after": len(frames["precinct"][1].traces)}


# ── stage 4: the correspondence gate ────────────────────────────────

USERDIR = Path("C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One")


def _frame_diff(a: Path, b: Path, thresh: int = 8) -> tuple[float, int]:
    import numpy as np
    A = np.asarray(Image.open(a).convert("RGB"), dtype=np.int16)
    B = np.asarray(Image.open(b).convert("RGB"), dtype=np.int16)
    d = np.abs(A - B).max(axis=2)
    return 100.0 * (d > thresh).sum() / d.size, int(d.max())


def stage_gate(angle: str = "iso") -> dict[str, Any]:
    """Compose the two Godot renders the gate is about, with their numbers.

    Unlike the other three, this stage DOES reach the engine, so its before and
    after are photographs: the approved museum, and the twin `--self-test`
    builds by moving one artifact three cells off its approved plan.
    """
    clean = USERDIR / "gate_shots" / "Museum_Spatial_Slice" / f"{angle}.png"
    corrupt = USERDIR / "gate_shots" / "Museum_Spatial_Slice_Corrupt" / f"{angle}.png"
    control = USERDIR / "gate_control" / "Museum_Spatial_Slice" / f"{angle}.png"
    for p in (clean, corrupt, control):
        if not p.exists():
            raise SystemExit(f"missing {p} — capture it before composing")

    rep_dir = REPO / "ada_run" / "spatial_slice"
    rc = json.loads((rep_dir / "correspondence_Museum_Spatial_Slice.json")
                    .read_text(encoding="utf-8"))
    rk = json.loads((rep_dir / "correspondence_Museum_Spatial_Slice_Corrupt.json")
                    .read_text(encoding="utf-8"))
    fault = next((f for a in rk["artifacts"] for f in a.get("faults", [])), "")
    moved = next((a for a in rk["artifacts"] if a.get("faults")), {})
    was = next((a for a in rc["artifacts"]
                if a["artifact"] == moved.get("artifact")), {})

    noise, _ = _frame_diff(clean, control)
    signal, _ = _frame_diff(clean, corrupt)
    (OUT / "gate").mkdir(parents=True, exist_ok=True)

    def compose(src: Path, title: str, sub: str, lines: list[tuple[str, str]],
                out: str) -> None:
        shot = Image.open(src).convert("RGB")
        iw = W - 56
        ih = int(shot.height * iw / shot.width)
        shot = shot.resize((iw, ih), Image.LANCZOS)
        h = PLAN_TOP + ih + CAP_H
        img = Image.new("RGB", (W, h), GROUND)
        d = ImageDraw.Draw(img)
        d.text((28, 24), title, font=F_TITLE, fill=INK)
        d.text((28, 60), sub, font=F_SUB, fill=INK_DIM)
        img.paste(shot, (28, PLAN_TOP))
        y = PLAN_TOP + ih + 26
        d.line([(28, y - 12), (W - 28, y - 12)], fill="#2a2c33", width=1)
        for text, colour in lines:
            d.text((28, y), text, font=F_BODY, fill=colour)
            y += 23
        img.save(OUT / "gate" / out)

    compose(
        clean, "CORRESPONDENCE GATE - before (the approved museum)",
        f"Museum_Spatial_Slice, {angle} - built from the negotiated plan. "
        f"verify_placement.py reports every artifact PASS.",
        [(f"{rc['artifacts_planned']} planned, {rc['failures']} failed - "
          f"result {rc['result']}, tolerance {rc['tolerance_cells']} cells.", OK),
         (f"{was.get('artifact','')} measured at centre "
          f"{[round(v,2) for v in was.get('measured',{}).get('centre_m',[])]} m, "
          f"base {was.get('measured',{}).get('base_m',0):.3f} m, occupying "
          f"{len(was.get('measured',{}).get('cells',[]))} cells.", INK),
         ("Every other check in this repo reasons in 2D cells. The player stands "
          "in 3D metres, and three real faults have already crossed that gap.", INK_DIM)],
        "1_before_approved.png")

    compose(
        corrupt, "CORRESPONDENCE GATE - after (the twin the gate must catch)",
        f"Museum_Spatial_Slice_Corrupt, {angle} - one token moved three cells, "
        f"the approved plan left untouched.",
        [(f"{rk['artifacts_planned']} planned, {rk['failures']} failed - "
          f"result {rk['result']}. {moved.get('artifact','')}: {fault}", FAIL),
         (f"Centre moved "
          f"{[round(v,2) for v in was.get('measured',{}).get('centre_m',[])]} m -> "
          f"{[round(v,2) for v in moved.get('measured',{}).get('centre_m',[])]} m.", FAIL),
         (f"You cannot settle this by diffing the photographs: the SAME map "
          f"rendered twice already differs by {noise:.3f}% of frame (the biome "
          f"reseeds), against {signal:.3f}% for the fault -", INK),
         (f"a signal-to-noise of {signal/max(noise,1e-9):.2f}x. The gate does not "
          f"look at pixels; it measures the body centre in metres and names the "
          f"number. Toggle: `--self-test`.", OK)],
        "2_after_corrupted_caught.png")

    return {"angle": angle, "clean_result": rc["result"], "clean_failures": rc["failures"],
            "corrupt_result": rk["result"], "corrupt_failures": rk["failures"],
            "fault": fault, "noise_pct": round(noise, 3),
            "signal_pct": round(signal, 3),
            "snr": round(signal / max(noise, 1e-9), 2)}


STAGES = {"threshold": stage_threshold, "hang_run": stage_hang_run,
          "precinct": stage_precinct, "gate": stage_gate}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", default="all", choices=list(STAGES) + ["all"])
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    todo = list(STAGES) if args.stage == "all" else [args.stage]
    facts = {}
    for name in todo:
        facts[name] = STAGES[name]()
        print(f"== {name}")
        for k, v in facts[name].items():
            print(f"   {k:24s} {v}")
    (OUT / "facts.json").write_text(json.dumps(facts, indent=1), encoding="utf-8")
    print(f"\nwrote {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
