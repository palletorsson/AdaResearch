#!/usr/bin/env python3
"""The whole curriculum through the spatial chain — all 24 spine sequences.

Everything before this ran the chain on a SAMPLE: 8 artifacts, or 16 bodies,
into one museum or into thirty copies of the same eight. That answers "does the
pipeline run". It does not answer "can this building hold the book", which is
the only question the endless museum exists to ask.

So this runs every chapter, with its real cast, into the building the museum
itself would deal it into:

    chapter        commons/data/spine_artifact_order.json, grouped by sequence
    brief          tools/exhibition_brief.py       anchors + their typed relations
    dressing room  tools/emit_dressing_room.py     measured body, footprint, support
    floorplan      tools/spatial_floorplan.py      one of 30 AUTHORED museums
    negotiation    tools/spatial_negotiation.py    slot/rotation/mode, or a refusal
    lineage        spatial_negotiation.hang_run    DNA runs as rows on walls
    plan           tools/export_museum_plan.py     ada_run/em_plan.json
    assembly       commons/scenes/endless_museum.gd --em-plan

NOTHING HERE RE-IMPLEMENTS A STAGE — same rule as tools/museum_wizard.py. The
only logic this file adds is (a) which museum each chapter goes to, which is
read from the museum's own crown file and rotation, and (b) counting.

THE SECOND MODE, `sorts`, is a controlled before/after for two commits that
landed without one. d1adfb394 made `em_sets._slot_before` sort depth-first and
38b6ca2e2 made `_build_segment` agree with it; the second says in its own
message "I have no controlled BEFORE number for this configuration". This
constructs the missing arms by reading the pre-fix comparators out of git and
running the REAL engine in a detached worktree, so the only difference between
arms is the two sorts.

    python tools/spine_run.py                        # the whole spine, read-only
    python tools/spine_run.py --sequence=symmetry
    python tools/spine_run.py --json=ada_run/spine_run.json --write-plan
    python tools/spine_run.py sorts --worktree=<dir> --segments=6
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from emit_dressing_room import ROOMS_DIR, is_authored, staged
from exhibition_brief import spine_order
from export_museum_plan import (APRON, brief_context, brief_stage, plan_museum,
                                spine_anchors)
from hero_walk import hero_walk, pearl_walks
from spatial_floorplan import PATTERNS, from_museum
from spatial_negotiation import Occupancy, hang_run, run as negotiate_run

RELATIONS = REPO / "commons" / "data" / "artifact_relations.json"
CROWNS = REPO / "commons" / "data" / "museum_crowns.json"
EM_PLAN = REPO / "ada_run" / "em_plan.json"
GODOT = Path(os.environ.get("GODOT_EXE",
                            "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"))
USERDIR = Path("C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One")


# ── who goes where ──────────────────────────────────────────────────

def sequences() -> list[tuple[str, int]]:
    """The 24 chapters in curriculum order, with how many rows each holds."""
    out: list[str] = []
    n: dict[str, int] = {}
    for row in spine_order():
        s = str(row.get("sequence", ""))
        if not s:
            continue
        if s not in n:
            out.append(s)
        n[s] = n.get(s, 0) + 1
    return [(s, n[s]) for s in out]


def museum_rotation() -> list[str]:
    """The museums in `em_order` — the rotation an UNCROWNED chapter walks."""
    pats = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
    keys = [k for k, v in pats.items() if v.get("museum")]
    return sorted(keys, key=lambda k: (int(pats[k].get("em_order", 9999)), k))


def crowns() -> dict[str, str]:
    if not CROWNS.exists():
        return {}
    data = json.loads(CROWNS.read_text(encoding="utf-8")).get("crowns", {})
    return {str(k): str(v.get("template", "")) for k, v in data.items()}


def assign_museums(seqs: list[str]) -> dict[str, dict[str, Any]]:
    """Reproduce `endless_museum.gd::_build_segment`'s choice of building.

    A crowned chapter is dealt into its crowned building and the rotation cursor
    does NOT advance (`use_crown` skips `_rot_i += 1`, lines 1052-1070); an
    uncrowned chapter takes the next museum in `em_order`. Read from the same
    two files the scene reads, so this is the museum's own answer rather than a
    convenient one.
    """
    crown = crowns()
    rot = museum_rotation()
    out: dict[str, dict[str, Any]] = {}
    i = 0
    for s in seqs:
        c = crown.get(s, "")
        if c and c in rot:
            out[s] = {"museum": c, "why": "crowned"}
        else:
            out[s] = {"museum": rot[i % len(rot)], "why": "em_order rotation"}
            i += 1
    return out


# ── one chapter through the chain ───────────────────────────────────

def _reason(placement: Any) -> str:
    """The last FAILING rule — the one that stopped it."""
    return next((f"{t.rule}: {t.detail}" for t in reversed(placement.traces)
                 if t.status == "fail"),
                (placement.traces[-1].rule if placement.traces else "no trace"))


def _reason_key(why: str) -> str:
    """Collapse a reason to its rule so refusals can be counted, not listed."""
    return why.split(":", 1)[0].strip() or "unknown"


def run_sequence(seq: str, museum: str, rows: int, relations: int = 2,
                 cast_cap: int = 0) -> dict[str, Any]:
    anchors = spine_anchors(0, seq)
    brief = brief_stage(anchors, relations)
    cast = list(brief["cast"])
    cast_context = brief_context(brief)
    # THE HERO'S WALK (2026-08-17). If the trunk names a hero for this chapter
    # AND the hand has authored at least one branch on it, the cast is the
    # hero + its branches in kind order — thesis, field, context, edge,
    # antithesis, the queer possibility, synthesis — each body carrying its
    # walk_kind into the plan. No hand branch: the chapter builds from the
    # spine list exactly as before. The reading is the switch, on purpose.
    # THE PEARLS (2026-08-18). A node is a STRING of heroes — its maps in book
    # order, each with a hero and siblings (build_trunk_pearls.py). When the
    # trunk carries pearls for this chapter, the chapter is negotiated ONE
    # PEARL AT A TIME into the same building, and write_plan emits one plan
    # row per pearl (`pearl`, `pearl_index`) so the museum builds one segment
    # per pearl. No pearls: the chapter runs as before (hero walk or spine).
    pearls = pearl_walks(seq)
    if pearls:
        parts: list[dict[str, Any]] = []
        for pw in pearls:
            ctx: dict[str, Any] = {k: dict(v) for k, v in cast_context.items()}
            pcast = _apply_walk(pw, ctx)
            if pw.get("ordered"):
                # the poem is the cast: the chapter's relations are not added to it
                ctx = {t: c for t, c in ctx.items() if t in set(pcast)}
            if pw.get("exclude"):
                # the hand took these out of the pearl (/speak, /pearls): not offered,
                # however the relations or branches would have brought them back
                ex = set(pw["exclude"])
                pcast = [t for t in pcast if t not in ex]
            if cast_cap > 0:
                pcast = pcast[:cast_cap]
            r = _run_cast(seq, museum, rows, anchors, pcast, ctx, walk=pw)
            r["pearl"] = pw["pearl"]; r["pearl_index"] = pw["pearl_index"]; r["map"] = pw["map"]
            r["rooms"] = pw.get("rooms")
            r["ordered"] = bool(pw.get("ordered"))
            r["exclude"] = list(pw.get("exclude") or [])
            r["pages"] = list(pw.get("pages") or [])
            r["stages"] = list(pw.get("stages") or [])
            r["gaps"] = list(pw.get("gaps") or [])
            r["hero_walk"] = {"hero": pw["hero"], "hand_branches": pw["hand_branches"], "pearl": pw["pearl"]}
            parts.append(r)
            print(f"  {seq:24s} PEARL {pw['pearl_index'] + 1:2d}/{len(pearls)} {pw['pearl']:16s} offered {r['offered']:3d} placed {r['placed']:3d} interior {r['interior']:3d}")
        agg = _run_cast(seq, museum, rows, anchors, [], cast_context, walk=None, skip=True)
        for k in ("offered", "placed", "interior", "rejected", "lineages", "lineages_walled", "rooms_on_disk", "rooms_authored"):
            agg[k] = sum(int(x.get(k, 0)) for x in parts)
        agg["venues"] = {}
        for x in parts:
            for v, n in x["venues"].items():
                agg["venues"][v] = agg["venues"].get(v, 0) + n
        agg["reasons"] = {}
        for x in parts:
            for k, n in x["reasons"].items():
                agg["reasons"][k] = agg["reasons"].get(k, 0) + n
        agg["cast"] = [t for x in parts for t in x["cast"]]
        agg["cast_context"] = {}
        for x in parts:
            agg["cast_context"].update(x["cast_context"])
        agg["pearls"] = parts
        agg["hero_walk"] = {"pearls": len(parts), "heroes": [x["hero_walk"]["hero"] for x in parts]}
        agg["interior_share"] = round(agg["interior"] / max(1, agg["offered"]), 4)
        agg["housed"] = agg["interior"] == agg["offered"]
        agg["shortfall"] = agg["offered"] - agg["interior"]
        return agg

    walk = hero_walk(seq)
    if walk:
        cast = _apply_walk(walk, cast_context)
        print(f"  {seq:24s} HERO WALK — {walk['why']}")
    if cast_cap > 0:
        cast = cast[:cast_cap]
    return _run_cast(seq, museum, rows, anchors, cast, cast_context, walk=walk)


def _apply_walk(walk: dict[str, Any], cast_context: dict[str, Any]) -> list[str]:
    """Write a walk's roles into cast_context; return its cast."""
    walk_kind_of: dict[str, str] = {}
    for r in walk["rows"]:
        tok = r["lookup"]
        cast_context.setdefault(tok, {})
        if tok in walk_kind_of:
            # a second role for the same body (the hero can be its own
            # antithesis): the first kind stands, the rest ride as `also`
            cast_context[tok].setdefault("walk_also", []).append(
                {"kind": r["walk_kind"], "why": r.get("why", "")})
            continue
        walk_kind_of[tok] = r["walk_kind"]
        cast_context[tok]["walk_kind"] = r["walk_kind"]
        cast_context[tok]["walk_why"] = r.get("why", "")
        cast_context[tok]["walk_space"] = r.get("space", "wall")   # wall | alcove | room
        if r.get("support_m"):
            cast_context[tok]["support_m"] = float(r["support_m"])  # the book asked for a plinth under this body
        if r.get("lock"):
            cast_context[tok]["lock"] = [int(r["lock"][0]), int(r["lock"][1])]   # the book locks this body to a tile cell
        if r.get("config"):
            cast_context[tok]["config"] = dict(r["config"])     # the book's apply_grid_config for this body
        if r.get("pose"):
            cast_context[tok]["pose"] = dict(r["pose"])         # the book's rotation / offset / scale for this body
        if r.get("footprint"):
            cast_context[tok]["footprint"] = [int(r["footprint"][0]), int(r["footprint"][1])]   # the BODY, not the reach
        if r.get("reach"):
            cast_context[tok]["reach"] = dict(r["reach"])       # the beam: a sightline, not floor
        if r.get("count"):
            cast_context[tok]["count"] = dict(r["count"])       # a group: N bodies, one block
        if walk.get("pearl"):
            cast_context[tok]["pearl"] = walk["pearl"]
    return list(walk["cast"])


def _run_cast(seq: str, museum: str, rows: int, anchors: list[str], cast: list[str],
              cast_context: dict[str, Any], walk: dict[str, Any] | None, skip: bool = False) -> dict[str, Any]:
    """Negotiate one cast into `museum` and report — the body of run_sequence."""
    walk_kind_of: dict[str, str] = {t: str(c.get("walk_kind")) for t, c in cast_context.items() if c.get("walk_kind")}

    # dressing rooms — read-only. A body with no file still negotiates (the
    # contract falls back to the measured AABB), but it negotiates from a guess,
    # and a chapter that is mostly guesses is a different claim from one that is
    # mostly authored.
    on_disk = authored = 0
    for tok in cast:
        if (ROOMS_DIR / f"{tok}.json").exists():
            on_disk += 1
        if is_authored(tok):
            authored += 1

    plan = from_museum(museum, apron=APRON, rooms=(walk or {}).get("rooms"))
    if skip:
        placements, occ = [], None
    else:
        fixed_now = _fixed_cells(seq, museum, (walk or {}).get("pearl", ""), plan.apron, only=set(cast) if (walk or {}).get("ordered") else None)
        fixed_now.update(_book_locks(cast_context, plan.apron))      # the book's locks win over a plan-editor ruling
        _, placements, occ = negotiate_run(list(cast), plan=plan, reading=bool((walk or {}).get("ordered")), fixed=fixed_now)

    acc = [p for p in placements if p.result == "ACCEPT"]
    interior = [p for p in acc if p.venue == "interior"]
    rej = [p for p in placements if p.result != "ACCEPT"]
    venues: dict[str, int] = {}
    for p in acc:
        venues[p.venue] = venues.get(p.venue, 0) + 1
    why: dict[str, int] = {}
    for p in rej:
        why[_reason_key(_reason(p))] = why.get(_reason_key(_reason(p)), 0) + 1

    # lineage: every anchor that declares an axis wants a wall, not a slot.
    rel = json.loads(RELATIONS.read_text(encoding="utf-8")).get("artifacts", {}) \
        if RELATIONS.exists() else {}
    runs: list[dict[str, Any]] = []
    for a in (anchors if not skip else []):
        axes = (rel.get(a) or {}).get("axes") or {}
        if not axes:
            continue
        axis, values = max(axes.items(), key=lambda kv: len(kv[1]))
        values = list(values)[:6]
        if len(values) < 2:
            continue
        r = hang_run(plan, a, axis, values, occ)
        runs.append({"anchor": a, "axis": axis, "values": len(values),
                     "housed": r.result == "ACCEPT", "wall": r.wall})

    return {
        "sequence": seq,
        "museum": museum,
        "rows": rows,
        "anchors": len(anchors),
        "anchor_tokens": anchors,
        "no_brief": rows - len(anchors),
        "offered": len(cast),
        "hero_walk": {"hero": walk["hero"], "hand_branches": walk["hand_branches"],
                      "kinds": walk_kind_of} if walk else None,
        "placed": len(acc),
        "interior": len(interior),
        "rejected": len(rej),
        "venues": venues,
        "reasons": dict(sorted(why.items(), key=lambda kv: -kv[1])),
        "reason_examples": [{"token": p.artifact, "why": _reason(p)}
                            for p in rej[:4]],
        "slots": len(plan.slots),
        "walls": len(plan.walls),
        "rooms_on_disk": on_disk,
        "rooms_authored": authored,
        "lineages": len(runs),
        "lineages_walled": sum(1 for r in runs if r["housed"]),
        "cast": cast,
        "cast_context": cast_context,
        "interior_share": round(len(interior) / max(1, len(cast)), 4),
        # HOUSED means the building actually contains the chapter. A porch is
        # not a room: `endless_museum.gd` has no apron, so an exterior placement
        # has nowhere to stand once the plan reaches the scene.
        "housed": len(interior) == len(cast),
        "shortfall": len(cast) - len(interior),
    }


# ── the corpus run ──────────────────────────────────────────────────

def spine_run(only: str = "", relations: int = 2,
              cast_cap: int = 0) -> dict[str, Any]:
    seqs = sequences()
    if only:
        seqs = [(s, n) for s, n in seqs if s == only]
    assign = assign_museums([s for s, _ in sequences()])
    rows: list[dict[str, Any]] = []
    for s, n in seqs:
        m = assign[s]["museum"]
        t0 = datetime.now()
        r = run_sequence(s, m, n, relations, cast_cap)
        r["why_museum"] = assign[s]["why"]
        r["seconds"] = round((datetime.now() - t0).total_seconds(), 1)
        rows.append(r)
        print(f"  {s:24s} {m:36s} offered {r['offered']:4d}  "
              f"placed {r['placed']:4d}  interior {r['interior']:3d}  "
              f"rejected {r['rejected']:4d}  ({r['seconds']}s)", flush=True)
    tot = {
        "sequences": len(rows),
        "rows": sum(r["rows"] for r in rows),
        "anchors": sum(r["anchors"] for r in rows),
        "offered": sum(r["offered"] for r in rows),
        "placed": sum(r["placed"] for r in rows),
        "interior": sum(r["interior"] for r in rows),
        "rejected": sum(r["rejected"] for r in rows),
        "housed_sequences": sum(1 for r in rows if r["housed"]),
        "lineages": sum(r["lineages"] for r in rows),
        "lineages_walled": sum(r["lineages_walled"] for r in rows),
    }
    tot["interior_share"] = round(tot["interior"] / max(1, tot["offered"]), 4)
    exterior: dict[str, int] = {}
    for r in rows:
        for v, n in r["venues"].items():
            if v != "interior":
                exterior[v] = exterior.get(v, 0) + n
    tot["exterior_venues"] = dict(sorted(exterior.items(), key=lambda kv: -kv[1]))
    reasons: dict[str, int] = {}
    for r in rows:
        for k, n in r["reasons"].items():
            reasons[k] = reasons.get(k, 0) + n
    tot["reasons"] = dict(sorted(reasons.items(), key=lambda kv: -kv[1]))
    return {"schema": "adaresearch.spine_run.v1",
            "at": datetime.now().isoformat(timespec="seconds"),
            "totals": tot, "sequences": rows}


def _book_locks(cast_context: dict[str, Any], apron: int) -> dict[str, tuple[int, int]]:
    """The book's locked cells (tools/book.py `lock`), as plan cells."""
    return {t: (int(c["lock"][0]) + apron, int(c["lock"][1]) + apron) for t, c in (cast_context or {}).items() if c.get("lock")}


def _fixed_cells(seq: str, museum: str, pearl: str, apron: int, only: set | None = None) -> dict[str, tuple[int, int]]:
    """The hand's rows of this pearl in the CURRENT plan, as plan cells — handed to
    the negotiator so its occupancy and reading order know where the hand put them.
    only: for an ORDERED pearl (the poem is the cast) a hand row bites only when its
    token is a line of the poem — the studio moves a line, it does not add one."""
    try:
        prev = json.loads((REPO / "ada_run" / "em_plan.json").read_text(encoding="utf-8"))
    except Exception:
        return {}
    row = next((p for p in prev.get("plans", []) if p.get("museum") == museum and p.get("sequence") == seq and p.get("pearl") == pearl), None)
    if not row:
        return {}
    out: dict[str, tuple[int, int]] = {}
    for a in row.get("artifacts", []):
        if a.get("hand") and a.get("venue") == "interior" and a.get("tile_cell"):
            if only is not None and a["token"] not in only:
                continue
            out[a["token"]] = (int(a["tile_cell"][0]) + apron, int(a["tile_cell"][1]) + apron)
    return out


def _carry_hand_rows(m: dict[str, Any], prev: dict[str, Any], key: str, seq: str, pearl: str, exclude: set | None = None, only: set | None = None) -> None:
    """THE HAND WINS A REGENERATION. A row the hand ruled (hand: true — the plan
    editor, or a ruling written into the plan) keeps its cell, rotation, offset,
    scale and config when the negotiator writes the pearl again; a hand row whose
    token the negotiator did not place this time is appended. Printed, so the
    regeneration says what it kept."""
    prev_row = next((p for p in prev.get("plans", []) if p.get("museum") == key
                     and p.get("sequence") == seq and p.get("pearl") == pearl), None)
    if not prev_row:
        return
    # a hand row for a token the hand has since taken OUT of the pearl is not carried:
    # the newer ruling is the exclusion (Palle: "in point remove the large point artifact…")
    hand = [a for a in prev_row.get("artifacts", []) if a.get("hand") and a.get("token") not in (exclude or set())
            and (only is None or a.get("token") in only)]
    if not hand:
        return
    apron = int(m.get("apron", 14))
    kept = 0
    for h in hand:
        cur = next((a for a in m.get("artifacts", []) if a.get("token") == h.get("token")), None)
        if cur is not None and str((cur.get("ruled") or {}).get("by", "")).startswith("book: locked"):
            continue                       # the book's lock is the newer ruling: the carried cell yields to it
        fields = {k: h[k] for k in ("tile_cell", "rotation", "offset", "scale", "config", "hand", "ruled", "mode", "venue", "support_height_m") if k in h}
        if cur is None:
            m.setdefault("artifacts", []).append(dict(h))
        else:
            cur.update(fields)
            cur["cell"] = [int(h["tile_cell"][0]) + apron, int(h["tile_cell"][1]) + apron] if h.get("tile_cell") else cur.get("cell")
        kept += 1
    print(f"  {seq:24s} PEARL {pearl:16s} carried {kept} hand row(s) through the regeneration")


def write_plan(result: dict[str, Any], out: Path) -> dict[str, Any]:
    """Every chapter's plan, keyed by (museum, sequence) — plus the v1 dict.

    v1 kept `museums: {building: ...}`, first-wins. That key threw away a
    decision the pipeline had already made: seven chapters were displaced by
    whichever chapter reached their building first in curriculum order, their
    casts were never planned at all, and the assembler stamped the winner's
    cast into the loser's room — `change` received symmetry's thirteen bodies.
    See doc/spatial/spikes/04_one_building_two_chapters.md.

    v2 adds `plans: [{museum, sequence, ...}]` with one row per CHAPTER,
    displaced chapters included — a building shared by four chapters carries
    four plans, and the reader picks by the chapter it is about to deal. The
    v1 `museums` dict is still written, first-wins as before, so an older
    reader (or a plan written for a building with no chapter, like
    export_museum_plan --all) resolves exactly as it always did. Additive and
    gated: the compound key is the only fix that ADDS the information the
    pipeline already computes instead of deleting a ruling (one building per
    chapter) or a rule (one museum, one sequence) to make a flat dict adequate.
    """
    prev: dict[str, Any] = {}
    if out.exists():
        try:
            prev = json.loads(out.read_text(encoding="utf-8"))
        except Exception:
            prev = {}
    museums: dict[str, Any] = {}
    plans: list[dict[str, Any]] = []
    owner: dict[str, str] = {}
    displaced: list[dict[str, str]] = []
    for r in result["sequences"]:
        key = r["museum"]
        # EVERY chapter is planned, displaced or not. The v1 loop `continue`d
        # here before plan_museum ever ran, so a displaced chapter's cast was
        # not merely unfindable — it was never negotiated into its building.
        #
        # THE PEARLS: a chapter that ran as a string of pearls gets ONE ROW PER
        # PEARL (`pearl`, `pearl_index`, `map`), each its own negotiation into
        # the same building — the museum builds one segment per row, in order.
        # The first pearl also stands as the chapter's whole-row for readers
        # that key by (museum, sequence) alone, so nothing older goes blank.
        if r.get("pearls"):
            first: dict[str, Any] | None = None
            for pr in r["pearls"]:
                fx = _fixed_cells(r["sequence"], key, pr["pearl"], APRON, only=set(pr["cast"]) if pr.get("ordered") else None)
                fx.update(_book_locks(pr.get("cast_context", {}), APRON))
                m = plan_museum(key, list(pr["cast"]), list(r.get("anchor_tokens", [])),
                                dict(pr.get("cast_context", {})), rooms=pr.get("rooms"), reading=bool(pr.get("ordered")), fixed=fx,
                                gaps=list(pr.get("gaps") or []))
                m["ordered"] = bool(pr.get("ordered"))
                if pr.get("pages"):
                    m["pages"] = list(pr["pages"])     # the pearls sharing this hall, in reading order
                if pr.get("stages"):
                    m["stages"] = list(pr["stages"])   # raised platforms the museum builds, with their ramps
                if pr.get("gaps"):
                    m["gaps"] = list(pr["gaps"])       # hollow space + the crossing that carries you over
                m["sequence"] = r["sequence"]
                m["pearl"] = pr["pearl"]; m["pearl_index"] = pr["pearl_index"]; m["map"] = pr.get("map", "")
                if not pr.get("ordered"):
                    _carry_hand_rows(m, prev, key, r["sequence"], pr["pearl"], set(pr.get("exclude") or []))
                else:
                    # an ORDERED pearl: the poem is the cast, so a hand row is carried only
                    # for a LINE of the poem — the studio moves a line (and its cell wins,
                    # even where the negotiator sent that body to a court: CoordinateSystem3M
                    # is a precinct to the negotiator and "to the right when we enter" to the
                    # hand); a row for a token the poem dropped is not carried
                    _carry_hand_rows(m, prev, key, r["sequence"], pr["pearl"], set(pr.get("exclude") or []), only=set(pr["cast"]))
                m["pearls_total"] = len(r["pearls"]); m["hero"] = pr.get("hero_walk", {}).get("hero", "")
                plans.append({"museum": key, **m})
                if first is None:
                    first = m
            m = first or {"sequence": r["sequence"]}
        else:
            m = plan_museum(key, list(r["cast"]), list(r.get("anchor_tokens", [])),
                            dict(r.get("cast_context", {})))
            m["sequence"] = r["sequence"]
            plans.append({"museum": key, **m})
        if key in owner:
            displaced.append({"sequence": r["sequence"], "museum": key,
                              "held_by": owner[key]})
            continue
        owner[key] = r["sequence"]
        museums[key] = m
    # A CHAPTER-ONLY RUN KEEPS THE OTHER CHAPTERS (2026-08-18). --sequence=X
    # --write-plan used to write a plan with one chapter in it — every other
    # chapter gone from the file. The rows of chapters this run did not
    # negotiate are carried from the previous plan unchanged.
    ran = {r["sequence"] for r in result["sequences"]}
    kept = [p for p in prev.get("plans", []) if p.get("sequence") not in ran]
    if kept:
        plans = kept + plans
        for k2, v2 in (prev.get("museums") or {}).items():
            if k2 not in museums and str(v2.get("sequence", "")) not in ran:
                museums[k2] = v2
        print(f"  write_plan: kept {len(kept)} row(s) of {len({p['sequence'] for p in kept})} chapter(s) this run did not negotiate")
    out.parent.mkdir(parents=True, exist_ok=True)
    # The note is DERIVED, not typed. The v1 note said "six chapters share
    # three crowned buildings" while the code two lines above it had written 7
    # over 4 — a hand-typed count beside the loop that computes the real one is
    # the endemic bug wearing prose (spike 04, F2).
    shared = sorted({d["museum"] for d in displaced})
    note = ("chapter-keyed: every chapter has a row in `plans`, displaced "
            "included; `museums` is the v1 first-wins view"
            + (f"; {len(displaced)} chapter(s) displaced across "
               f"{len(shared)} shared building(s)" if displaced else ""))
    out.write_text(json.dumps({
        "schema": "adaresearch.em_plan.v2",
        "_readme": prev.get("_readme", "Placements resolved by "
                            "tools/spatial_negotiation.py. Read by "
                            "commons/scenes/endless_museum.gd under --em-plan."),
        "_spine_run": {"at": result["at"], "owner": owner,
                       "displaced": displaced,
                       "note": note},
        "plans": plans,
        "offered": sorted({t for r in result["sequences"] for t in r["cast"]}),
        "museums": museums,
    }, indent=2) + "\n", encoding="utf-8")
    return {"museums": len(museums), "displaced": displaced, "path": str(out)}


# ── mode 2: the two sort fixes, measured ────────────────────────────
#
# d1adfb394  em_sets._slot_before      rank,y,x  ->  y,rank,x
# 38b6ca2e2  _build_segment slot sort  rank      ->  y,rank,x
#
# Both are pure comparators. Reverting them in a DETACHED WORKTREE at HEAD (not
# in the working tree, and not at an older commit, which would drag a37b26a73's
# wall-run rewrite in as a confound) isolates exactly the two lines. Three arms:
# neither fix, fix 1 only, both.

SORT_ARMS = {
    "neither": ("em_sets rank-first AND _build_segment rank-only "
                "— the code as it stood before d1adfb394"),
    "fix1":    ("em_sets depth-first, _build_segment still rank-only "
                "— the state 38b6ca2e2 was written against"),
    "both":    "HEAD — the shipped pair",
}

#: The post-fix `_build_segment` comparator, verbatim from 38b6ca2e2, and the
#: rank-only one it replaced. Matched as text so a drift in the file is a loud
#: failure rather than a silent no-op arm.
BUILD_SORT_NEW = """	slots.sort_custom(func(a, b):
		if int(a["y"]) != int(b["y"]):
			return int(a["y"]) < int(b["y"])
		if int(a["rank"]) != int(b["rank"]):
			return int(a["rank"]) < int(b["rank"])
		return int(a["x"]) < int(b["x"]))"""
BUILD_SORT_OLD = """	slots.sort_custom(func(a, b): return int(a["rank"]) < int(b["rank"]))"""

#: Ten buildings, one segment forced into each. Nine of them are on
#: order_to_walk.md's list of templates whose first-dealt slot is the single
#: deepest cell in the building — the population the fix is about — plus
#: Sainsbury, which is where both commits took their numbers.
BUILDINGS = [
    "sainsbury-false-perspective-enfilade",
    "chichu-buried-cells",
    "uffizi-spine-enfilade",
    "grande-galerie-axial",
    "guggenheim-serpentine",
    "kanazawa-room-matrix",
    "louisiana-pavilion-chain",
    "labrouste-stack-hall",
    "soane-cabinet-vista",
    "castelvecchio-pinch-v2",
]


def ensure_worktree(wt: Path) -> None:
    """A detached worktree at HEAD, with the import cache copied in.

    The copy is the whole point: a fresh Godot project directory reimports
    32,000 files, and the arms are supposed to differ by two comparators, not by
    whether the assets were freshly baked. With `.godot` in place a boot costs
    ~20 s instead of a coffee.
    """
    if (wt / "project.godot").exists():
        return
    print(f"creating measurement worktree at {wt} ...", flush=True)
    subprocess.run(["git", "worktree", "add", "--detach", str(wt), "HEAD"],
                   cwd=str(REPO), check=True)
    src, dst = REPO / ".godot", wt / ".godot"
    if src.is_dir() and not dst.exists():
        print("copying the import cache (~500 MB, once) ...", flush=True)
        # robocopy's exit codes are a bitfield: <8 is success, and 1 means
        # "files were copied", so `check=True` would fail on a good run.
        subprocess.run(["robocopy", str(src), str(dst), "/E", "/NFL", "/NDL",
                        "/NJH", "/NJS", "/NP", "/MT:16"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for probe in ("ada_sort_probe.gd", "ada_sort_probe2.gd"):
        p = REPO / "tools" / "probes" / probe
        if p.exists():
            (wt / probe).write_text(p.read_text(encoding="utf-8"), encoding="utf-8")


def _patch_arm(wt: Path, arm: str) -> list[str]:
    """Put the worktree into one arm. Returns what was changed, for the record."""
    changed: list[str] = []
    em = wt / "commons" / "scenes" / "endless_museum.gd"
    sets = wt / "commons" / "scenes" / "em" / "em_sets.gd"
    subprocess.run(["git", "checkout", "--", "commons/scenes/endless_museum.gd",
                    "commons/scenes/em/em_sets.gd"], cwd=str(wt), check=True)

    if arm in ("neither", "fix1"):
        t = em.read_text(encoding="utf-8")
        if BUILD_SORT_NEW not in t:
            raise SystemExit("endless_museum.gd no longer holds the 38b6ca2e2 "
                             "sort verbatim — the arm would be a no-op")
        em.write_text(t.replace(BUILD_SORT_NEW, BUILD_SORT_OLD), encoding="utf-8")
        changed.append("_build_segment sort -> rank only")

    if arm == "neither":
        # `_slot_before` from the parent of d1adfb394 — read from git, never
        # retyped, so the BEFORE arm is the code that actually shipped.
        old = subprocess.run(["git", "show", "d1adfb394^:commons/scenes/em/em_sets.gd"],
                             cwd=str(wt), capture_output=True, text=True, check=True).stdout
        body = _slot_before_body(old)
        cur = sets.read_text(encoding="utf-8")
        new_body = _slot_before_body(cur)
        if body == new_body:
            raise SystemExit("_slot_before is unchanged since d1adfb394^ — "
                             "the arm would be a no-op")
        sets.write_text(cur.replace(new_body, body), encoding="utf-8")
        changed.append("_slot_before -> rank before depth")
    return changed


def _slot_before_body(src: str) -> str:
    """The body of `static func _slot_before(...)`, whichever version it is."""
    m = re.search(r"static func _slot_before\(.*?\n(?=\n\n|\nstatic func |\nfunc )",
                  src, re.S)
    if not m:
        raise SystemExit("could not find _slot_before")
    return m.group(0)


#: NOT `\(([^)]*)\)` for the museum's label. `castelvecchio-pinch-v2` prints
#: "(Museo di Castelvecchio, Verona (edited v2))" — nested brackets — so a
#: first-`)`-wins group stops mid-label and the whole line fails to match. That
#: read as `placed 0/0` for one of the ten buildings in every arm, which looks
#: exactly like a museum with no slots rather than a broken reader.
SEG_RE = re.compile(
    r"seg (\d+) = (\S+) .*?chapter=(\S+) placed (\d+)/(\d+) "
    r"\((\d+) leads, (\d+) relatives, (\d+) repeats, (\d+) guests\)")
DEAL_RE = re.compile(
    r"deal: (\d+) objects across (\d+) segments \(([\d.]+) per segment")


STAMP_RE = re.compile(
    r"\[em-plan\] (\S+): stamped (\d+) interior"
    r"(?: \+ (\d+) DNA wall variants in (\d+) runs)?"
    r", (\d+) exterior not hostable"
    r"(?:, (\d+) off-tile)?(?:, (\d+) not in pool)?"
    r"(?:, \d+ to courtyard)?(?:, (\d+) wall refusals)?")


def capture(museums: list[str], out: Path, root: Path | None = None) -> dict[str, Any]:
    """One frame per museum, stamped from the plan. Serialized, one Godot at a time.

    `--em-plan` makes the museum a consumer of `ada_run/em_plan.json` instead of
    a dealer, so these frames are the spine run's own arithmetic standing in a
    room. `_deal_from_plan` prints what it could and could not stamp, and that
    line is the only place the corpus's dead artifacts become visible: a token
    the pool does not carry is reported as `N not in pool`.
    """
    root = root or REPO
    out.mkdir(parents=True, exist_ok=True)
    rows: list[dict[str, Any]] = []
    for key in museums:
        shot = out / f"{key}.png"
        log = out / f"{key}.log"
        if shot.exists():
            shot.unlink()
        args = [str(GODOT), "--path", str(root), "--xr-mode", "off", "--no-window",
                "--log-file", str(log),
                "res://commons/scenes/endless_museum.tscn", "--",
                f"--em-first={key}", f"--em-shot={shot.as_posix()}",
                "--em-segments=1", "--em-plan"]
        cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
               f"--expect={shot}", "--grace=200", "--stall=40", "--"] + args
        t0 = datetime.now()
        proc = subprocess.run(cmd, cwd=str(root), capture_output=True, text=True,
                              timeout=1200)
        text = log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""
        m = STAMP_RE.search(text)
        shotline = next((l.split("]", 1)[-1].strip() for l in text.splitlines()
                         if "shot composed at" in l), "")
        row = {"museum": key, "ok": shot.exists(), "rc": proc.returncode,
               "seconds": round((datetime.now() - t0).total_seconds(), 1),
               "bytes": shot.stat().st_size if shot.exists() else 0,
               "stamped": int(m.group(2)) if m else None,
               "dna_variants": int(m.group(3) or 0) if m else None,
               "dna_runs": int(m.group(4) or 0) if m else None,
               "exterior": int(m.group(5)) if m else None,
               "off_tile": int(m.group(6) or 0) if m else None,
               "not_in_pool": int(m.group(7) or 0) if m else None,
               "wall_refusals": int(m.group(8) or 0) if m else None,
               "standpoint": shotline}
        rows.append(row)
        print(f"  {key:38s} stamped {row['stamped']}  exterior {row['exterior']}"
              f"  not_in_pool {row['not_in_pool']}  ({row['seconds']}s)", flush=True)
    return {"dir": str(out), "shots": rows}


def _boot(root: Path, shot: Path, segments: int, first: str = "",
          log: Path | None = None) -> dict[str, Any]:
    """One headless museum run under the watchdog. Never two at a time.

    `--no-window`, never `--headless`: this one renders. `--em-segments` is
    inert without `--em-shot`, so the shot flag is what makes the segment count
    real (order_to_walk.md §1).
    """
    shot.parent.mkdir(parents=True, exist_ok=True)
    if shot.exists():
        shot.unlink()
    log = log or (shot.parent / (shot.stem + ".log"))
    if log.exists():
        log.unlink()
    args = [str(GODOT), "--path", str(root), "--xr-mode", "off", "--no-window",
            "--log-file", str(log),
            "res://commons/scenes/endless_museum.tscn", "--",
            f"--em-shot={shot.as_posix()}", f"--em-segments={max(1, segments)}"]
    if first:
        args.append(f"--em-first={first}")
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={shot}", "--grace=200", "--stall=40", "--"] + args
    t0 = datetime.now()
    proc = subprocess.run(cmd, cwd=str(root), capture_output=True, text=True,
                          timeout=1200)
    text = log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""
    return {"ok": shot.exists(), "rc": proc.returncode,
            "seconds": round((datetime.now() - t0).total_seconds(), 1),
            "log": str(log), "text": text,
            "bytes": shot.stat().st_size if shot.exists() else 0}


def _probe(root: Path, out: Path, script: str = "ada_sort_probe.gd") -> dict[str, Any]:
    """The walk-order probe: real `EmSets.build_set` over all 30 templates.

    `--headless` is correct HERE and only here — the probe renders nothing, so
    the never-headless-when-rendering rule does not apply to it.
    """
    if out.exists():
        out.unlink()
    args = [str(GODOT), "--headless", "--path", str(root), "--xr-mode", "off",
            "--script", f"res://{script}", "--",
            f"--out={out.as_posix()}"]
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={out}", "--grace=120", "--stall=30", "--"] + args
    proc = subprocess.run(cmd, cwd=str(root), capture_output=True, text=True,
                          timeout=600)
    data = json.loads(out.read_text(encoding="utf-8")) if out.exists() else {}
    return {"ok": out.exists(), "rc": proc.returncode, "data": data,
            "tail": (proc.stdout or "")[-500:] + (proc.stderr or "")[-500:]}


def _read_segments(text: str) -> list[dict[str, Any]]:
    """Placements per segment, off the scene's own stdout.

    `_build_segment` prints `placed n/budget (leads, relatives, repeats,
    guests)` at endless_museum.gd:1299. Nothing is instrumented — this reads the
    log the shipped code already writes, which is what makes the arms
    comparable to anything anyone else runs.
    """
    segs: list[dict[str, Any]] = []
    for line in text.splitlines():
        m = SEG_RE.search(line)
        if m:
            segs.append({
                "seg": int(m.group(1)), "museum": m.group(2),
                "chapter": m.group(3), "placed": int(m.group(4)),
                "budget": int(m.group(5)), "leads": int(m.group(6)),
                "relatives": int(m.group(7)), "repeats": int(m.group(8)),
                "guests": int(m.group(9))})
    return segs


def reparse(out: Path) -> dict[str, Any]:
    """Re-read the saved arm logs with the current parser.

    The logs are the evidence, not the summary, so a reader bug is repairable
    without re-booting Godot thirty times.
    """
    shots = REPO / "ada_run" / "spine_run" / "sorts"
    res = json.loads(out.read_text(encoding="utf-8"))
    for arm, a in res["arms"].items():
        corridor = shots / f"{arm}.log"
        if corridor.exists():
            a["segments"] = _read_segments(
                corridor.read_text(encoding="utf-8", errors="replace"))
            a["placements"] = sum(s["placed"] for s in a["segments"])
            a["budget"] = sum(s["budget"] for s in a["segments"])
            a["leads"] = sum(s["leads"] for s in a["segments"])
            a["guests"] = sum(s["guests"] for s in a["segments"])
            a["per_segment"] = round(a["placements"] / max(1, len(a["segments"])), 3)
        for key in list(a.get("by_museum", {})):
            lg = shots / f"{arm}__{key}.log"
            if not lg.exists():
                continue
            ss = _read_segments(lg.read_text(encoding="utf-8", errors="replace"))
            s0 = ss[0] if ss else {}
            a["by_museum"][key].update({
                "placed": s0.get("placed", 0), "budget": s0.get("budget", 0),
                "leads": s0.get("leads", 0), "relatives": s0.get("relatives", 0),
                "guests": s0.get("guests", 0), "chapter": s0.get("chapter", "")})
        a["museum_placed"] = sum(v["placed"] for v in a.get("by_museum", {}).values())
        a["museum_budget"] = sum(v["budget"] for v in a.get("by_museum", {}).values())
    out.write_text(json.dumps(res, indent=1), encoding="utf-8")
    return res


def tau(depths: list[int]) -> dict[str, Any]:
    """`1 - 2*inversions/pairs` — the formula order_to_walk.md used, so these
    numbers are directly comparable to it. A tie (two cells at one depth, met at
    the same moment) is not an inversion."""
    n = len(depths)
    pairs = n * (n - 1) // 2
    inv = sum(1 for i in range(n) for j in range(i + 1, n)
              if depths[i] > depths[j])
    return {"n": n, "pairs": pairs, "inversions": inv,
            "tau": round(1 - 2 * inv / pairs, 4) if pairs else None}


def probe_only(worktree: Path, arms: list[str], script: str,
               out: Path) -> dict[str, Any]:
    """Just the walk-order probe, per arm. Three boots, no rendering.

    Split out because the engine boots cost ~30 s each and the probe costs ~20,
    so re-measuring walk order after changing the probe's own budget must not
    mean re-running thirty museum renders.
    """
    shots = REPO / "ada_run" / "spine_run" / "sorts"
    shots.mkdir(parents=True, exist_ok=True)
    res: dict[str, Any] = {"schema": "adaresearch.spine_run.probe.v1",
                           "at": datetime.now().isoformat(timespec="seconds"),
                           "script": script, "arms": {}}
    for arm in arms:
        changed = _patch_arm(worktree, arm)
        pr = _probe(worktree, shots / f"{Path(script).stem}_{arm}.json", script)
        museums = (pr["data"].get("museums") or {})
        per: dict[str, Any] = {}
        for k, m in museums.items():
            per[k] = {
                "placed": m["placed"], "leads": len(m["lead_depths"]),
                "all": tau(m["depths"]), "lead_tau": tau(m["lead_depths"]),
                "first_depth": (m["depths"] or [None])[0],
                "deepest_slot": m["deepest_slot"],
                "opens_at_back": bool(m["depths"]
                                      and m["depths"][0] == m["deepest_slot"]),
                "mean_lead_rank": (round(sum(m["ranks"]) / len(m["ranks"]), 3)
                                   if m["ranks"] else None),
                "hero_leads": sum(1 for r in m["ranks"] if r == 0),
            }
        a = [v["all"]["tau"] for v in per.values() if v["all"]["tau"] is not None]
        l = [v["lead_tau"]["tau"] for v in per.values()
             if v["lead_tau"]["tau"] is not None]
        mr = [v["mean_lead_rank"] for v in per.values()
              if v["mean_lead_rank"] is not None]
        res["arms"][arm] = {
            "why": SORT_ARMS[arm], "patched": changed, "ok": pr["ok"],
            "museums": per,
            "placed": sum(v["placed"] for v in per.values()),
            "leads": sum(v["leads"] for v in per.values()),
            "tau_mean": round(sum(a) / len(a), 4) if a else None,
            "tau_leads_mean": round(sum(l) / len(l), 4) if l else None,
            "tau_leads_measurable": len(l),
            "inversions_leads": sum(v["lead_tau"]["inversions"] for v in per.values()),
            "pairs_leads": sum(v["lead_tau"]["pairs"] for v in per.values()),
            "opens_at_back": sum(1 for v in per.values() if v["opens_at_back"]),
            "mean_lead_rank": round(sum(mr) / len(mr), 3) if mr else None,
            "hero_leads": sum(v["hero_leads"] for v in per.values()),
        }
        r = res["arms"][arm]
        print(f"  {arm:8s} placed {r['placed']:4d} leads {r['leads']:4d} · "
              f"tau {r['tau_mean']} · leads tau {r['tau_leads_mean']} "
              f"({r['inversions_leads']}/{r['pairs_leads']} inv) · "
              f"opens at back {r['opens_at_back']}/30 · "
              f"mean lead rank {r['mean_lead_rank']} · heroes {r['hero_leads']}",
              flush=True)
    subprocess.run(["git", "checkout", "--", "commons/scenes/endless_museum.gd",
                    "commons/scenes/em/em_sets.gd"], cwd=str(worktree))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(res, indent=1), encoding="utf-8")
    print(f"\nwrote {out}")
    return res


def sorts_mode(worktree: Path, segments: int, arms: list[str],
               out: Path) -> dict[str, Any]:
    """Three arms, one binary, one import cache, one directory.

    EVERY arm runs in the worktree — including `both`, which is the worktree
    unpatched at HEAD. Running the shipped arm from the repo instead would make
    the build directory a second variable, and the repo's working tree is dirty.
    """
    shots = REPO / "ada_run" / "spine_run" / "sorts"
    shots.mkdir(parents=True, exist_ok=True)
    result: dict[str, Any] = {"schema": "adaresearch.spine_run.sorts.v1",
                              "at": datetime.now().isoformat(timespec="seconds"),
                              "segments": segments, "worktree": str(worktree),
                              "arms": {}}
    for arm in arms:
        changed = _patch_arm(worktree, arm)
        print(f"\n=== arm {arm}: {SORT_ARMS[arm]}", flush=True)
        for c in changed:
            print(f"    patched: {c}", flush=True)

        # (a) the whole engine, N segments — placements per segment along one
        #     real corridor, which is what a walker actually gets
        b = _boot(worktree, shots / f"{arm}.png", segments)
        segs = _read_segments(b["text"])
        deal = DEAL_RE.search(b["text"])

        # (a2) one segment forced into each of N buildings. The corridor above
        #      is nearly all Sainsbury (a crowned chapter repeats its building
        #      — order_to_walk.md §3), so it cannot see a defect whose size
        #      depends on slot geometry. This can.
        by_museum: dict[str, Any] = {}
        for key in BUILDINGS:
            bb = _boot(worktree, shots / f"{arm}__{key}.png", 1, first=key)
            ss = _read_segments(bb["text"])
            s0 = ss[0] if ss else {}
            by_museum[key] = {"placed": s0.get("placed", 0),
                              "budget": s0.get("budget", 0),
                              "leads": s0.get("leads", 0),
                              "relatives": s0.get("relatives", 0),
                              "guests": s0.get("guests", 0),
                              "chapter": s0.get("chapter", ""),
                              "ok": bb["ok"], "seconds": bb["seconds"]}
            print(f"      {key:38s} placed {by_museum[key]['placed']:2d}"
                  f"/{by_museum[key]['budget']:2d}", flush=True)

        # (b) the real build_set over all 30 templates — walk order
        pr = _probe(worktree, shots / f"probe_{arm}.json")
        museums = (pr["data"].get("museums") or {})
        per_museum: dict[str, Any] = {}
        for k, m in museums.items():
            per_museum[k] = {
                "placed": m["placed"], "slots": m["slots"],
                "all": tau(m["depths"]), "leads": tau(m["lead_depths"]),
                "first_depth": (m["depths"] or [None])[0],
                "deepest_slot": m["deepest_slot"],
                "opens_at_back": bool(m["depths"]
                                      and m["depths"][0] == m["deepest_slot"]),
                "mean_lead_rank": round(
                    sum(r for r, ro in zip(m["ranks"], m["roles"])
                        if ro == "lead")
                    / max(1, sum(1 for ro in m["roles"] if ro == "lead")), 3),
            }
        got = [v["all"]["tau"] for v in per_museum.values()
               if v["all"]["tau"] is not None]
        gotl = [v["leads"]["tau"] for v in per_museum.values()
                if v["leads"]["tau"] is not None]

        result["arms"][arm] = {
            "why": SORT_ARMS[arm], "patched": changed,
            "ok": b["ok"], "rc": b["rc"], "seconds": b["seconds"],
            "segments": segs,
            "placements": sum(s["placed"] for s in segs),
            "budget": sum(s["budget"] for s in segs),
            "leads": sum(s["leads"] for s in segs),
            "relatives": sum(s["relatives"] for s in segs),
            "guests": sum(s["guests"] for s in segs),
            "per_segment": round(sum(s["placed"] for s in segs) / max(1, len(segs)), 3),
            "deal_line": deal.group(0) if deal else "",
            "by_museum": by_museum,
            "museum_placed": sum(v["placed"] for v in by_museum.values()),
            "museum_budget": sum(v["budget"] for v in by_museum.values()),
            "probe_ok": pr["ok"], "probe_museums": len(per_museum),
            "probe": per_museum,
            "tau_mean": round(sum(got) / len(got), 4) if got else None,
            "tau_leads_mean": round(sum(gotl) / len(gotl), 4) if gotl else None,
            "probe_placed": sum(v["placed"] for v in per_museum.values()),
            "opens_at_back": sum(1 for v in per_museum.values() if v["opens_at_back"]),
            "log": b["log"],
        }
        r = result["arms"][arm]
        print(f"    engine: {len(segs)} segments · placed {r['placements']}"
              f"/{r['budget']} ({r['per_segment']}/seg) · "
              f"{len(by_museum)} buildings {r['museum_placed']}"
              f"/{r['museum_budget']}", flush=True)
        print(f"    probe : {r['probe_museums']} museums · placed "
              f"{r['probe_placed']} · tau {r['tau_mean']} (leads "
              f"{r['tau_leads_mean']}) · opens at back wall in "
              f"{r['opens_at_back']}", flush=True)

    if arms and worktree.exists():
        subprocess.run(["git", "checkout", "--", "commons/scenes/endless_museum.gd",
                        "commons/scenes/em/em_sets.gd"], cwd=str(worktree))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=1), encoding="utf-8")
    print(f"\nwrote {out}")
    return result


# ── driver ──────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", nargs="?", default="spine",
                    choices=["spine", "sorts", "probe", "reparse", "capture"])
    ap.add_argument("--sequence", default="")
    ap.add_argument("--relations", type=int, default=2)
    ap.add_argument("--cast-cap", type=int, default=0,
                    help="truncate each chapter's cast (0 = the whole chapter)")
    ap.add_argument("--json", default="ada_run/spine_run.json")
    ap.add_argument("--write-plan", action="store_true",
                    help="also rewrite ada_run/em_plan.json from this run")
    ap.add_argument("--worktree", default="C:/Users/palle/Documents/GitHub/_ada46_sortprobe")
    ap.add_argument("--segments", type=int, default=6)
    ap.add_argument("--arms", default="neither,fix1,both")
    ap.add_argument("--probe-script", default="ada_sort_probe2.gd")
    ap.add_argument("--museums", default=(
        "sainsbury-false-perspective-enfilade,louisiana-pavilion-chain,"
        "teshima-droplet,grande-galerie-axial"),
        help="capture mode: which buildings to stamp from the plan")
    args = ap.parse_args()

    if args.mode == "capture":
        keys = [k.strip() for k in args.museums.split(",") if k.strip()]
        r = capture(keys, REPO / "ada_run" / "spine_run" / "capture")
        (REPO / "ada_run" / "spine_run_capture.json").write_text(
            json.dumps(r, indent=1), encoding="utf-8")
        print(f"\n  {r['dir']}")
        return 0

    if args.mode == "reparse":
        r = reparse(REPO / "ada_run" / "spine_run_sorts.json")
        for arm, a in r["arms"].items():
            print(f"  {arm:8s} corridor {a['placements']}/{a['budget']} "
                  f"({a['per_segment']}/seg) · buildings "
                  f"{a['museum_placed']}/{a['museum_budget']}")
        return 0

    if args.mode == "probe":
        probe_only(Path(args.worktree),
                   [a.strip() for a in args.arms.split(",") if a.strip()],
                   args.probe_script,
                   REPO / "ada_run" / "spine_run_probe.json")
        return 0

    if args.mode == "sorts":
        sorts_mode(Path(args.worktree), args.segments,
                   [a.strip() for a in args.arms.split(",") if a.strip()],
                   REPO / "ada_run" / "spine_run_sorts.json")
        return 0

    print("THE SPINE RUN — every chapter through the spatial chain\n")
    result = spine_run(args.sequence, args.relations, args.cast_cap)
    t = result["totals"]
    print(f"\n  {t['sequences']} chapters · {t['rows']} curriculum rows · "
          f"{t['anchors']} with a brief")
    print(f"  offered {t['offered']} · placed {t['placed']} · "
          f"interior {t['interior']} ({t['interior_share']:.1%} of offered) · "
          f"rejected {t['rejected']}")
    print(f"  chapters fully housed: {t['housed_sequences']}/{t['sequences']}")
    print(f"  exterior venues: {t['exterior_venues']}")
    print(f"  refusals: {t['reasons']}")

    if args.write_plan:
        info = write_plan(result, EM_PLAN)
        result["plan"] = info
        print(f"\n  plan -> {info['path']} ({info['museums']} museums, "
              f"{len(info['displaced'])} chapters displaced)")

    if args.json:
        p = REPO / args.json
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(result, indent=1) + "\n", encoding="utf-8")
        print(f"  wrote {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
