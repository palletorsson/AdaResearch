#!/usr/bin/env python3
"""museum_necklace.py — the artifacts of the ACTUAL museum, in the order you meet them.

2026-08-27, Palle: "I also want a version where I can see the artifact in 1 d
like that but for the artifact in the actual museum."

The necklace already scrolls ONE string: commons/data/spine_order_effective.json,
the curriculum's dealing order, 810 tokens in the order the spine first meets
them. This file builds the OTHER string, over the same beads and in the same
shape, so one scene can scroll either: every artifact standing in the long
museum, at the metre mark where you walk past it, from 0 m to the far wall.

    python tools/museum_necklace.py           summary + the first and last beads,
                                              writes nothing
    python tools/museum_necklace.py --apply   writes commons/data/museum_order_effective.json
    python tools/museum_necklace.py --check   gate: the written file vs its sources
    python tools/museum_necklace.py --json    the document on stdout
    python tools/museum_necklace.py --hall X  the beads of one hall

  READ-ONLY, AND THAT IS A DESIGN DECISION, NOT AN OMISSION

The spine string is editable because its order is DERIVED and regenerated, so a
hand edit can live in an op list (commons/data/spine_order_ops.json) replayed
over it. This string has no such layer to write into. The only file an edit here
could touch is commons/maps/<Hall>/map_data.json, layer `interactables` — and
removing a bead means clearing a floor cell, which this repo's own gate cannot
certify: map_pathfinder has ONE error rule, and 8 halls have been walked sealed
while it printed OK. So `candidates` ships EMPTY and there is no add, no remove
and no move. Palle asked to SEE the museum. Seeing it is the whole of version one.

  THE BEAD IS A CELL, NOT A TOKEN

The spine string can key a bead on `lookup` because each of its 810 tokens
appears once. This one cannot: 1,583 placements carry 1,252 distinct tokens,
173 of them more than once — dark_sphere and science_screen 26 times each, and
Point_Lines holds laser_measure five times INSIDE ONE HALL. So the identity is
the map's own address, `at = "Point_Lines@9,12"` (hall, interactables column,
interactables row), which is unique across all 1,583 with zero collisions, and
which is not an index: long_museum crops right and bottom only, so (0,0) never
moves and the address is the one the map file itself stores. Every add / remove /
move / undo path in desktop_necklace.gd keys on `lookup` today; on this string
they must key on `at`.

  WHAT A BEAD IS ALLOWED TO CLAIM

Two thirds of this museum does not exist yet. 154 of the 207 halls are in a
chapter the engine has never built — endless_museum.gd builds a plan row from
its own map only when the row says authored == "map", true of the 53 halls in
the five chapters map_authored.json names — and a string that draws those 1,049
beads the same as the 534 standing ones is claiming a building nobody can walk.
So every bead carries a `state`, and there are five of them, measured and never
assumed:

    placed     a body stands. 191 of the 532 do not stand on the cell their map
               names, for TWO different reasons, and `rings` is what tells them
               apart: 43 were slid outward by the ring search, which leaves
               `rings` 1-7 and a `why` that is the reason the search had to run
               (not a failure - the body is up); the other 148 were simply aimed
               somewhere else by the pack before any search, and carry `slid_to`
               with no `rings` and no `why`. Either way `slid_to` / `slid_x_m` /
               `slid_z_m` are the floor the visitor walks up to
    refused    no body stands, and `why` says what stopped it
    declared   the hall is built and the pack ledger holds no body for this
               planned cell at all — nothing acted, or the map was edited after
               the pack ran. ZERO beads today; when it is non-zero it is news
    unplanned  the hall is built and the plan the museum builds from has never
               seen this cell (the map was edited after the plan was resolved)
    unbuilt    the hall's chapter is a proposal; there is nothing to be placed in

  THE STATE COMES FROM THE PACK LEDGER. THE BAKE CANNOT ANSWER THE QUESTION.

Version one of this tool read `placed` / `refused` out of ada_run/em_bake.json
and got 67 of the 534 built beads wrong — 12.5% — in two ways, both structural:

  * `refused` IN THE BAKE IS A FAILED CANDIDATE CELL, NOT A MISSING ARTIFACT.
    endless_museum.gd:8410 runs a seven-ring outward search; _stamp (:10015)
    appends EVERY failed candidate to _seg_refused and the loop tries the next
    cell, stopping at the first success. So one body that had to slide one metre
    writes one `placed` row and several `refused` rows. Matching a map cell
    against a flat placed+refused list on exact (token, x, z+4) lands on the
    refusal BY CONSTRUCTION, because the map cell IS the ring-0 target and ring 0
    is what failed; the successful placement sits at a cell no map row names and
    goes unclaimed. The rule ran backwards: the more reliably the museum re-homed
    a body, the more certain the string was to call it refused. 32 of the 33
    `refused` beads were standing. Point_Lines declares five laser_measure, the
    pack stood all five, and the string called one of them refused because the
    bake also recorded the ring-0 miss at [11,15].

  * A PRESENT-AND-EMPTY SEGMENT IS NO EVIDENCE, NOT EVIDENCE OF ABSENCE. The
    bake holds "transformation|trans translation" with placed: [] and refused:
    [], while the pack ledger for the same key records 13 bodies with targets and
    finals. Only `seg is None` was routed to the unbaked note; an empty segment
    fell through and manufactured 13 `declared` verdicts. Same for Trans_Rotation
    (9) and Trans_AxisDecomposition (8). Something acted; the bake just did not
    say so. Those three segments are still empty and are now reported as silent.

ada_run/em_pack_report.json is the ledger _transplant_from_map writes, and it
carries the join this string needs, per body, already resolved:

    grid    the MAP CELL, [x, z], verbatim — the address the bead is built on
    target  where the pack aimed it, [x, z + vestibule]
    final   the cell it actually stands on, or null if nothing stood
    rings   how many rings out the search had to go
    why     the reason, when there is one

So the key is (hall's plan key, token, grid) == (hall, lookup, cx, cz), and it is
a BIJECTION on the built halls: 532 of the 534 declared cells find exactly one
body, no cell finds two, and no body is left over. The two that miss are the
head_crab cells added to VFM_08_Arena after the plan was resolved, and they are
`unplanned` for that reason, from the plan check, not this one.

  THE LEDGER KEY IS THE PLAN'S, NOT THE MAP'S — AND THAT IS NOT A DETAIL

Twelve maps are filed in the ledger under TWO pearl names at once, e.g.
Change_Intro as both "change|change intro" and "change|intro". They are not
copies. One is the map-authored transplant, where `target` is `grid` shifted by
the vestibule in every body; the other is a template pack of the same map with
relocated targets, where that holds in ZERO bodies. All twelve pairs disagree,
on every body. Keying the ledger on the MAP NAME and taking last-wins would
therefore hand six of the twelve halls another lane's coordinates — so the key is
the one the authored plan row itself names, `sequence|pearl`, which all 53 built
halls have and all 53 find. `_meta.pack.dual_filed` counts the pairs and
`_report` says so, because the day a thirteenth appears this is the sentence that
will explain the numbers moving.

  THE SOURCE IS THE MAPS, NOT THE SNAPSHOT

This tool imports tools/long_museum.py and derives the strip in memory (0.2 s)
rather than reading commons/data/long_museum.json. That file has no `generated`
stamp of its own, so the spine's two-integer staleness test has nothing to
compare — and it is live: it was rewritten twice during the hour this tool was
written, 1,581 artifacts to 1,583, by another session. The snapshot is still
read, and `_meta.source_check` records whether it agrees, so the page can say
"the file on disk is behind the maps" instead of quietly disagreeing with it.

  FILES

  READ   commons/maps/*/map_data.json        via tools/long_museum.py
         commons/artifacts/registry/*.json   via tools/necklace_order.py
         ada_run/em_plan.json                the plan the museum builds from
         ada_run/em_pack_report.json         WHERE EVERY BODY STANDS - the state
         ada_run/em_bake.json                advisory only: its stamps, and how
                                             many candidate cells each hall burned
         commons/data/spine_order_effective.json   the OTHER string, for cross-links
         commons/data/long_museum.json       only to report agreement

  WRITE  commons/data/museum_order_effective.json    and nothing else, ever.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if os.path.join(ROOT, "tools") not in sys.path:
    sys.path.insert(0, os.path.join(ROOT, "tools"))

try:
    import long_museum as LM
    import necklace_order as NO
except ImportError as exc:  # pragma: no cover - a broken sibling, not a broken us
    raise SystemExit(
        "FATAL: museum_necklace.py derives from tools/long_museum.py and reuses\n"
        "  tools/necklace_order.py's token facts so the two strings can never\n"
        "  disagree about what an artifact IS. One of them will not import: %s\n"
        "  Nothing has been read and nothing has been written." % exc)

OUT = os.path.join(ROOT, "commons", "data", "museum_order_effective.json")
SNAPSHOT = os.path.join(ROOT, "commons", "data", "long_museum.json")
PLAN = os.path.join(ROOT, "ada_run", "em_plan.json")
BAKE = os.path.join(ROOT, "ada_run", "em_bake.json")
PACK = os.path.join(ROOT, "ada_run", "em_pack_report.json")
SPINE_EFFECTIVE = os.path.join(ROOT, "commons", "data", "spine_order_effective.json")
SPINE_GENERATED = os.path.join(ROOT, "commons", "data", "spine_artifact_order.json")

SCHEMA = "museum_order_effective/1"

# The band the 50 curriculum-named artifacts that stand in NO hall are drawn in.
# They are not an appendix and they are not a footnote in _report: they are the
# one thing this string can say that the spine string structurally cannot, so
# they are beads, at the far end, on a band whose name says what it is. You reach
# them by scrolling to End.
ORPHAN_BAND = "- claimed, nowhere built -"

# endless_museum.gd:224 `const VESTIBULE_H := 4`. A segment BEGINS with its
# vestibule, so a cell recorded in segment space is the map's z plus four. The
# pack ledger carries its own `vestibule` per hall and all 271 rows say 4; the
# ledger's value is what is USED, and a row that disagrees with this constant is
# reported rather than silently trusted, because a hall packed against a
# different vestibule would read as slid by exactly the difference in every body.
VESTIBULE_H = LM.VESTIBULE_H

STATES = ("placed", "refused", "declared", "unplanned", "unbuilt", "nowhere")


def _rel(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


def _mtime(path):
    try:
        return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(os.path.getmtime(path)))
    except OSError:
        return ""


# --------------------------------------------------------------------------
# the sources


def strip_from_maps():
    """The long museum, derived in memory from the maps on disk.

    NOT commons/data/long_museum.json. See the module docstring: that file has no
    generated stamp to test for staleness with, and it changed under this tool
    twice in one hour. long_museum.build() is 0.2 s and reads the same 207 maps
    the snapshot was made from, so the drift question simply does not arise.
    """
    doc, probs = LM.build()
    return doc, probs


def snapshot_check(fresh):
    """Does commons/data/long_museum.json still describe the maps?

    Reported, never enforced. The file belongs to another session's work as of
    this morning and this tool may not write it; the only honest thing to do is
    say whether the page reading it would see the same museum this string does.
    """
    have = NO.read_json(SNAPSHOT)
    out = {
        "file": _rel(SNAPSHOT),
        "file_mtime": _mtime(SNAPSHOT),
        "present": isinstance(have, dict),
        "matches": False,
        "file_artifacts": None,
        "derived_artifacts": fresh["totals"]["artifacts"],
        "halls_differing": [],
    }
    if not isinstance(have, dict):
        return out
    out["file_artifacts"] = (have.get("totals") or {}).get("artifacts")
    fa = {s["name"]: s["artifacts"] for s in fresh["segments"] if s["kind"] == "hall"}
    ha = {s["name"]: s.get("artifacts")
          for s in (have.get("segments") or []) if s.get("kind") == "hall"}
    diff = sorted(set(fa) ^ set(ha)) + sorted(n for n in set(fa) & set(ha) if fa[n] != ha[n])
    out["halls_differing"] = diff[:12]
    out["halls_differing_n"] = len(diff)
    out["matches"] = (not diff) and out["file_artifacts"] == out["derived_artifacts"]
    return out


def plan_rows():
    """map name -> the plan row the museum builds that hall from.

    Only the 53 rows carrying `authored`, whose value is "map" in every one of
    them: endless_museum.gd:4858 builds from the hall's own map ONLY on that key,
    and the other 143 rows build a template. Keying on `map` alone would hand a
    template row's placements to a hall that never receives them.
    """
    doc = NO.read_json(PLAN)
    rows = {}
    if not isinstance(doc, dict):
        return rows, ""
    for r in doc.get("plans") or []:
        if not isinstance(r, dict) or "authored" not in r:
            continue
        if str(r.get("authored")) != "map":
            continue
        name = str(r.get("map") or "")
        if name:
            rows[name] = r
    stamp = str(((doc.get("_spine_run") or {}).get("at")) or "")
    return rows, stamp


def bake_segments():
    """(sequence|pearl) -> {placed, refused}, plus the bake's own stamps.

    ADVISORY ONLY since the state moved to the pack ledger. What is still worth
    reading here is the pair of stamps — one `at` for 200 segments, which is why
    a segment survives an edit to the map it describes — and the LENGTH of each
    `refused` list, which counts CANDIDATE CELLS the ring search burned, not
    artifacts that failed to stand. Those two things are reported; nothing in
    this file decides a bead's state any more.
    """
    doc = NO.read_json(BAKE)
    if not isinstance(doc, dict):
        return {}, {}
    meta = {"at": str(doc.get("at") or ""), "plan_at": str(doc.get("plan_at") or ""),
            "schema": str(doc.get("schema") or ""), "segments": len(doc.get("segments") or {})}
    segs = doc.get("segments")
    return (segs if isinstance(segs, dict) else {}), meta


def pack_ledger():
    """(sequence|pearl) -> the transplant's ledger row for that hall.

    KEYED THE WAY THE PLAN KEYS IT, WHICH IS NOT THE WAY THE MAP DOES. Twelve
    maps appear under two pearl names — "change|change intro" and "change|intro"
    — and the two rows are two different packing lanes for the same map, not two
    copies: in the plan's own row `target` is `grid` shifted by the vestibule in
    every body, and in the other it is so in none of them. All twelve pairs
    disagree on every body, so a map-name key with last-wins would hand six halls
    the wrong lane's coordinates. The caller therefore looks the row up by the
    key its authored plan row names, and `dual_filed` counts the pairs so the
    number is on the page rather than in somebody's head.
    """
    doc = NO.read_json(PACK)
    if not isinstance(doc, dict):
        return {}, {}
    halls = doc.get("halls")
    halls = halls if isinstance(halls, dict) else {}
    by_map = {}
    for key, row in halls.items():
        if isinstance(row, dict):
            by_map.setdefault(str(row.get("map") or ""), []).append(key)
    dual = sorted(m for m, ks in by_map.items() if m and len(ks) > 1)
    meta = {
        "file": _rel(PACK),
        "rows": len(halls),
        "bodies": sum(len(r.get("bodies") or []) for r in halls.values()
                      if isinstance(r, dict)),
        "maps": len(by_map),
        "dual_filed": len(dual),
        "dual_filed_maps": dual[:16],
    }
    return halls, meta


def spine_string():
    """The other necklace: lookup -> (index, chapter), and which file said so.

    The effective file is preferred because it is the answer the scene reads and
    it carries the curator's hand. It is being repaired by other agents today, so
    a damaged or absent one falls back to the generated order rather than
    dropping the cross-link — but WHICH was used is recorded, because the two
    differ by exactly the hand and a cross-jump into a row that is not there is
    the kind of silence this project keeps writing memory files about.
    """
    doc, state = NO.read_json_state(SPINE_EFFECTIVE)
    used = _rel(SPINE_EFFECTIVE)
    if state != NO.ST_OK or not isinstance(doc, dict) or not isinstance(doc.get("order"), list):
        doc = NO.read_json(SPINE_GENERATED)
        used = _rel(SPINE_GENERATED)
        state = "ok" if isinstance(doc, dict) else "absent"
    rows = (doc or {}).get("order") or []
    idx, seq = {}, {}
    for i, r in enumerate(rows):
        if not isinstance(r, dict):
            continue
        t = str(r.get("lookup") or "")
        if t and t not in idx:
            idx[t] = i
            seq[t] = str(r.get("sequence") or "")
    return idx, seq, {"file": used, "state": state, "rows": len(rows)}


def raw_cell(hall_name, x, z):
    """The interactables cell EXACTLY as the map stores it, tail and all.

    long_museum.parse_cell returns (token, rot) and drops two things this string
    would otherwise pretend do not exist: the `#config` tail — 10 placements in 5
    halls carry one, `pusher_block#axis:z`, `floating_sphere_field#bounds:4,3,18`
    — and the y_offset, so `folding_past:0:2` reads on the string as if it sat on
    the floor. Rather than write a SECOND cell parser (the first re-implementation
    of one reported six broken halls, all six of them the parser), the raw string
    is carried and the scene can show it.
    """
    try:
        doc = LM.load_map(hall_name)
    except (OSError, ValueError):
        return ""
    rows = ((doc.get("layers") or {}).get("interactables") or [])
    if 0 <= z < len(rows):
        row = rows[z]
        if 0 <= x < len(row):
            return str(row[x])
    return ""


# --------------------------------------------------------------------------
# the bake's account of one hall


def _cell(v):
    """A ledger [x, z] as two ints, or None. JSON hands these back as floats."""
    if not (isinstance(v, list) and len(v) >= 2):
        return None
    try:
        return (int(v[0]), int(v[1]))
    except (TypeError, ValueError):
        return None


def account_for_hall(hall, prow, ledger_row):
    """Where each of this hall's declared cells actually ended up.

    Returns (verdicts, counts) where verdicts is a list parallel to
    hall["artifacts"], each {"state", "why", "slid_to", "rings"}.

    THE JOIN IS THE MAP CELL AND NOTHING ELSE. `grid` in the ledger is the
    interactables cell verbatim, so (token, x, z) addresses one body directly —
    no shift, no fallback, no second guess. On the 53 built halls it is a
    bijection: every planned cell finds exactly one body, no cell finds two, and
    no body is left over. Both halves are counted (`extra`, and `declared`),
    because the day a map is edited after the pack runs is the day one of them
    stops being zero, and that is the honest staleness signal for this file.

    The bake's flat placed+refused list, which this used to read, cannot answer
    the question at all: its `refused` rows are the ring search's failed
    CANDIDATE CELLS, and the map cell IS the ring-0 candidate, so an exact match
    on it finds the miss and never the body. See the module docstring.
    """
    counts = {"planned": 0, "matched": 0, "extra": 0, "slid": 0, "ringed": 0,
              "placed": 0, "refused": 0, "declared": 0, "unplanned": 0,
              "vestibule": VESTIBULE_H}
    arts = hall["artifacts"]
    verdicts = [None] * len(arts)

    # the plan's own account of this hall, as a multiset of (token, cell)
    planned = {}
    for a in (prow.get("artifacts") or []):
        tc = _cell(a.get("tile_cell"))
        if tc is None:
            continue
        key = (str(a.get("token") or ""), tc[0], tc[1])
        planned[key] = planned.get(key, 0) + 1

    # THE LEDGER'S OWN VESTIBULE, not the constant. All 271 rows say 4 today and
    # the constant says 4; a hall that disagreed would read as slid by exactly
    # the difference in every one of its bodies, which is a fault that looks
    # like data. Take the row's number and report the disagreement.
    vest = VESTIBULE_H
    try:
        vest = int(ledger_row.get("vestibule"))
    except (TypeError, ValueError):
        pass
    counts["vestibule"] = vest

    # the ledger's bodies, keyed by map cell; a list per key so a fan-out (one
    # map cell, several bodies) is consumed in order rather than collapsed.
    bodies = {}
    for b in (ledger_row.get("bodies") or []):
        g = _cell(b.get("grid"))
        if g is None:
            continue
        bodies.setdefault((str(b.get("token") or ""), g[0], g[1]), []).append(b)
    taken = {}

    for i, a in enumerate(arts):
        key = (a["token"], a["x"], a["z"])
        if not planned.get(key):
            # THE PLAN HAS NEVER SEEN THIS CELL. Two beads today, both head_crab
            # in VFM_08_Arena, added by commit 26bbed904 after the plan was
            # resolved. The museum will not stand them up until the plan is
            # rebuilt, and a string that drew them as "in a built chapter" would
            # be showing the map's declaration as though it were the building.
            counts["unplanned"] += 1
            verdicts[i] = {"state": "unplanned", "why": "", "slid_to": None, "rings": 0}
            continue
        planned[key] -= 1
        counts["planned"] += 1
        have = bodies.get(key) or []
        n = taken.get(key, 0)
        if n >= len(have):
            # PLANNED, AND THE PACK HOLDS NO BODY FOR IT. Zero beads today. This
            # is the only honest `declared`: the map and the plan both name the
            # cell and the transplant's own ledger has nothing to say about it.
            counts["declared"] += 1
            verdicts[i] = {"state": "declared", "why": "", "slid_to": None, "rings": 0}
            continue
        taken[key] = n + 1
        counts["matched"] += 1
        b = have[n]
        rings = 0
        try:
            rings = int(b.get("rings") or 0)
        except (TypeError, ValueError):
            rings = 0
        why = str(b.get("why") or "")
        final = _cell(b.get("final"))
        if final is None:
            # NOTHING STANDS. Two shapes of this and `why` tells them apart:
            # "sealing would sever the walk route" is a floor that ran out after
            # a full seven-ring search, and "no living scene" is an artifact with
            # no scene on disk, which never reaches _stamp and so has never
            # appeared in the bake at all. Seven beads are the second kind and
            # all seven carry alive: false, so the bead already says which.
            counts["refused"] += 1
            if rings:
                counts["ringed"] += 1
            verdicts[i] = {"state": "refused", "why": why, "slid_to": None, "rings": rings}
            continue
        counts["placed"] += 1
        if rings:
            counts["ringed"] += 1
        # BACK INTO THE MAP'S FRAME. `final` is segment space and a segment opens
        # with its vestibule, so the map-frame row is final.z - vest. Kept only
        # when it differs from the cell the bead is built on: the presence of the
        # key IS the claim that the body is not where the map put it.
        slid = None
        fz = final[1] - vest
        if final[0] != a["x"] or fz != a["z"]:
            slid = [final[0], fz]
            counts["slid"] += 1
        verdicts[i] = {"state": "placed", "why": why, "slid_to": slid, "rings": rings}

    # Ledger bodies no declared cell claims. Zero today, and it is the mirror of
    # `declared`: a body the pack stood up that the map no longer asks for means
    # the map was edited after the pack ran, in the other direction.
    counts["extra"] = sum(max(0, len(v) - taken.get(k, 0)) for k, v in bodies.items())
    return verdicts, counts


# --------------------------------------------------------------------------
# the document


class Report:
    def __init__(self):
        self.applied = []
        self.stale = []
        self.degraded = []
        self.refused = []
        self.notes = []

    def as_dict(self):
        return {"applied": self.applied, "stale": self.stale,
                "degraded": self.degraded, "refused": self.refused,
                "notes": self.notes}


def build(reg=None, live=None):
    """The whole answer. Nothing here writes."""
    rep = Report()
    strip, probs = strip_from_maps()
    halls = [s for s in strip["segments"] if s["kind"] == "hall"]

    if reg is None:
        reg = NO.registry()
    if live is None:
        live = NO.live_index(reg)

    prows, plan_stamp = plan_rows()
    bakes, bake_meta = bake_segments()
    ledger, pack_meta = pack_ledger()
    spine_i, spine_seq, spine_src = spine_string()

    for chapter, name in probs.missing:
        rep.refused.append("%s names %s and there is no map_data.json on disk - the "
                           "hall is not on the string" % (chapter, name))
    for name, dims in probs.layers:
        rep.notes.append("%s's layers disagree in size (%s) - its floor is the "
                         "structure grid and the artifacts outside it are still beads, "
                         "flagged outside_floor"
                         % (name, ", ".join("%s %dx%d" % (k, v[0], v[1])
                                            for k, v in sorted(dims.items()))))

    # -- pass one: the verdicts, hall by hall -----------------------------
    hall_rows, verdicts_by_hall = [], {}
    drifted, unpacked_halls, silent_bake, odd_vest = [], [], [], []
    bake_candidates = 0
    for h in halls:
        name = h["name"]
        if not h.get("built"):
            verdicts_by_hall[name] = [{"state": "unbuilt", "why": "", "slid_to": None,
                                       "rings": 0} for _ in h["artifacts"]]
            continue
        prow = prows.get(name)
        if prow is None:
            # A built hall with no plan row cannot happen today (53 of 53 have
            # one) and would mean the museum builds it from a template instead,
            # so the map's cells are not what stands there. Say so; do not guess.
            verdicts_by_hall[name] = [{"state": "unplanned", "why": "", "slid_to": None,
                                       "rings": 0} for _ in h["artifacts"]]
            rep.stale.append("%s is a built hall with no authored plan row - none of "
                             "its %d declared cells can be attributed"
                             % (name, len(h["artifacts"])))
            continue
        # THE PLAN'S KEY, NOT THE MAP'S NAME. Twelve maps are filed under two
        # pearls and the two rows are different packing lanes; see pack_ledger().
        key = "%s|%s" % (prow.get("sequence"), prow.get("pearl"))
        lrow = ledger.get(key)
        if not isinstance(lrow, dict) or not (lrow.get("bodies") or []):
            # NO EVIDENCE, WHICH IS NOT EVIDENCE OF ABSENCE. This is where an
            # absent OR empty ledger row lands - the branch that used to read an
            # empty BAKE segment as thirty artifacts nobody had touched.
            verdicts_by_hall[name] = [{"state": "declared", "why": "", "slid_to": None,
                                       "rings": 0} for _ in h["artifacts"]]
            unpacked_halls.append(name)
            rep.stale.append(
                "the pack ledger has no bodies under %r - %s's %d cells are declared "
                "and unaccounted, and that is a gap in the EVIDENCE, not a claim that "
                "nothing stands there" % (key, name, len(h["artifacts"])))
            continue
        v, c = account_for_hall(h, prow, lrow)
        verdicts_by_hall[name] = v
        h["_pack"] = dict(c, key=key)
        if c["declared"] or c["extra"]:
            drifted.append((name, c))
        if c["vestibule"] != VESTIBULE_H:
            odd_vest.append((name, c["vestibule"]))
        # The bake, purely as an observer now: how many candidate cells this
        # hall's ring search burned, and whether it recorded anything at all.
        seg = bakes.get(key)
        if isinstance(seg, dict):
            n_ref = len(seg.get("refused") or [])
            bake_candidates += n_ref
            h["_bake_candidates"] = n_ref
            if not (seg.get("placed") or []) and not n_ref:
                silent_bake.append((name, key, len(lrow.get("bodies") or [])))

    for name, c in sorted(drifted, key=lambda kv: -(kv[1]["declared"] + kv[1]["extra"])):
        rep.degraded.append(
            "%s: the pack ledger accounts for %d of %d planned cells; %d planned cells "
            "have no body in it and %d bodies in it no declared cell claims - the map "
            "and the pack are describing different layouts"
            % (name, c["matched"], c["planned"], c["declared"], c["extra"]))
    for name, vest in odd_vest:
        rep.degraded.append(
            "%s was packed against vestibule %d, not %d - every slid_to in that hall "
            "is offset by the difference and should not be believed"
            % (name, vest, VESTIBULE_H))

    # -- pass two: the beads ----------------------------------------------
    order, seen_token = [], {}
    total_token = {}
    for h in halls:
        for a in h["artifacts"]:
            total_token[a["token"]] = total_token.get(a["token"], 0) + 1

    for h in halls:
        name = h["name"]
        v = verdicts_by_hall[name]
        h_i0, h_n = len(order), len(h["artifacts"])
        for k, a in enumerate(h["artifacts"]):
            tok = a["token"]
            seen_token[tok] = seen_token.get(tok, 0) + 1
            facts = NO.token_facts(tok, reg, live)
            ver = v[k]
            row = {
                # IDENTITY. `at` is the key: `lookup` cannot be, because 173
                # tokens repeat and Point_Lines holds five laser_measure.
                "at": "%s@%d,%d" % (name, a["x"], a["z"]),
                "hall": name,
                # CARRIED FOR THE SCENE'S EXISTING DETAIL PANEL, WHICH LABELS IT
                # "first met in". On this string it is the hall you are STANDING
                # in - the same string, a different claim - so the panel must
                # relabel by schema. The value is true either way: all 207 hall
                # names are map directories.
                "map": name,
                "cx": a["x"], "cz": a["z"],
                "cell_raw": raw_cell(name, a["x"], a["z"]),
                "i": len(order),
                # THE METRE MARK, WHICH IS THE POINT OF THIS STRING. z0 is the
                # hall's start along the strip and cz is its own row, so this is
                # the absolute distance from the front door.
                "z_m": h["z0"] + a["z"],
                "x_m": h["x0"] + a["x"],
                "rot": a["rot"],
                "sequence": h["sequence"],
                "chapter": h["chapter"],
                "hall_i": k, "hall_n": h_n,
                "state": ver["state"],
                "built": bool(h.get("built")),
                # `origin` IS NOT "spine" HERE AND THE SCENE MUST BE TOLD.
                # _style_bead colours on `origin != "spine"`; emitting "spine"
                # would keep it quiet with a word that is a lie, and emitting
                # "map" without _meta.neutral_origin paints all 1,583 as
                # hand-edited. Both halves ship.
                "origin": "map",
                "lookup": tok,
                "nth": seen_token[tok], "of": total_token[tok],
                "in_spine": tok in spine_i,
            }
            if ver["why"]:
                row["why"] = ver["why"]
            # WHERE THE BODY ACTUALLY STANDS, WHEN THAT IS NOT WHERE THE MAP PUT
            # IT. 191 of the 532 packed beads. Carrying it is what makes the
            # drift VISIBLE rather than merely corrected: cx/cz stay the map's
            # declaration and the bead's identity, slid_to is the floor the
            # visitor walks up to, and slid_z_m is that in metres so the scene
            # can draw the offset on the same axis as everything else.
            if ver.get("slid_to"):
                row["slid_to"] = list(ver["slid_to"])
                row["slid_x_m"] = h["x0"] + ver["slid_to"][0]
                row["slid_z_m"] = h["z0"] + ver["slid_to"][1]
            # HOW FAR THE SEARCH HAD TO LOOK. 0 for a body that stood on its own
            # target; up to 7, the outward ring limit, for one that found no
            # floor at all. Omitted when it is 0 so its presence means something.
            if ver.get("rings"):
                row["rings"] = ver["rings"]
            if tok in spine_i:
                row["spine_i"] = spine_i[tok]
                row["spine_sequence"] = spine_seq[tok]
            if a["x"] >= h["w"] or a["z"] >= h["h"]:
                # Outside the hall's own floor. Five cells in
                # Trans_AxisDecomposition, whose interactables layer is 14x22
                # against a 9x16 structure grid. The bead is real and its metre
                # mark is past the hall's back wall.
                row["outside_floor"] = True
            row.update(facts)
            order.append(row)
        hall_rows.append({
            "name": name, "sequence": h["sequence"], "chapter": h["chapter"],
            "i0": h_i0, "n": h_n,
            "z0": h["z0"], "z1": h["z1"], "w": h["w"], "h": h["h"], "x0": h["x0"],
            "built": bool(h.get("built")), "source": h["source"],
            "in_spine_n": sum(1 for a in h["artifacts"] if a["token"] in spine_i),
            "dead_n": sum(1 for a in h["artifacts"] if a["token"] not in live),
            "states": _state_counts(v),
            "pack": h.get("_pack", {}),
            # NOT A REFUSAL COUNT. The number of candidate cells this hall's ring
            # searches tried and rejected before finding floor. Pattern_Foundry's
            # 90 are four bodies looking: 77 of them are pattern_machine_d, which
            # went the full seven rings and never stood, and the other 13 belong
            # to three bodies that then stood. Eleven of its twelve artifacts are
            # standing, which is what this hall's `states` says.
            "bake_candidate_fails": h.get("_bake_candidates", 0),
        })

    placements = len(order)

    # -- the orphan band ---------------------------------------------------
    here = {r["lookup"] for r in order}
    orphans = sorted(t for t in spine_i if t not in here)
    orph_i0 = len(order)
    for k, tok in enumerate(sorted(orphans, key=lambda t: spine_i[t])):
        facts = NO.token_facts(tok, reg, live)
        row = {
            "at": "orphan@%s" % tok, "hall": "", "map": "", "cx": None, "cz": None,
            "cell_raw": "", "i": len(order),
            # NO METRE MARK, AND null RATHER THAN 0. A zero here would put fifty
            # beads on the front step of a museum that does not hold them.
            "z_m": None, "x_m": None, "rot": 0,
            "sequence": ORPHAN_BAND, "chapter": None,
            "hall_i": k, "hall_n": len(orphans),
            "state": "nowhere", "built": False,
            "origin": "spine_only",
            "lookup": tok, "nth": 1, "of": 1,
            "in_spine": True, "spine_i": spine_i[tok], "spine_sequence": spine_seq[tok],
        }
        row.update(facts)
        order.append(row)

    # seq_i / seq_n over the bands as they stand ON THE STRING. The scene
    # recomputes both in _reindex; they are written anyway so a reader of the
    # file alone sees the same numbers the scene will draw.
    chapters = _chapters_of(order, halls, orphans, orph_i0)
    counts = {}
    for r in order:
        counts[r["sequence"]] = counts.get(r["sequence"], 0) + 1
    seen = {}
    for r in order:
        s = r["sequence"]
        seen[s] = seen.get(s, 0) + 1
        r["seq_i"] = seen[s] - 1
        r["seq_n"] = counts[s]

    if orphans:
        hall_rows.append({
            "name": ORPHAN_BAND, "sequence": ORPHAN_BAND, "chapter": None,
            "i0": orph_i0, "n": len(orphans),
            "z0": None, "z1": None, "w": 0, "h": 0, "x0": 0,
            "built": False, "source": "spine",
            "in_spine_n": len(orphans),
            "dead_n": sum(1 for t in orphans if t not in live),
            "states": {"nowhere": len(orphans)}, "pack": {},
            "bake_candidate_fails": 0,
        })

    # -- the totals and the sentences -------------------------------------
    states = _state_counts([{"state": r["state"]} for r in order])
    in_spine_n = sum(1 for r in order[:placements] if r["in_spine"])
    off_n = placements - in_spine_n
    built_n = sum(1 for r in order[:placements] if r["built"])
    slid_n = sum(1 for r in order[:placements] if r.get("slid_to"))
    ringed_n = sum(1 for r in order[:placements] if r.get("rings"))
    matched_n = sum(int((hr.get("pack") or {}).get("matched") or 0) for hr in hall_rows)
    declared_n = sum(int((hr.get("pack") or {}).get("declared") or 0) for hr in hall_rows)
    extra_n = sum(int((hr.get("pack") or {}).get("extra") or 0) for hr in hall_rows)
    empty_halls = [hr["name"] for hr in hall_rows[:len(halls)]
                   if hr["n"] and hr["in_spine_n"] == 0]

    rep.notes.append(
        "%d of %d placements (%.0f%%) carry a token the 810-row spine order names; "
        "%d do not, and %d halls hold nothing the curriculum has ever heard of"
        % (in_spine_n, placements, 100.0 * in_spine_n / max(1, placements),
           off_n, len(empty_halls)))
    rep.notes.append(
        "%d of %d placements (%.0f%%) stand in a chapter the museum builds today; "
        "the other %d are a proposal - 154 of the 207 halls"
        % (built_n, placements, 100.0 * built_n / max(1, placements),
           placements - built_n))
    if orphans:
        rep.notes.append(
            "%d artifacts the curriculum names stand in NO hall - they are the last "
            "band of the string, %r, and they have no metre mark"
            % (len(orphans), ORPHAN_BAND))
    if pack_meta:
        rep.notes.append(
            "the state of every built bead comes from %s - %d ledger rows over %d "
            "maps, %d bodies, each carrying the map cell it was dealt from. The join "
            "is a bijection here: %d of the %d planned cells find exactly one body, "
            "%d find none and %d bodies are unclaimed"
            % (pack_meta.get("file", "?"), pack_meta.get("rows", 0),
               pack_meta.get("maps", 0), pack_meta.get("bodies", 0),
               matched_n, matched_n + declared_n, declared_n, extra_n))
        if pack_meta.get("dual_filed"):
            rep.notes.append(
                "%d maps are filed in the pack ledger under TWO pearl names at once "
                "(%s...) and the pairs disagree on every body - one row is the "
                "map-authored transplant and the other a template pack of the same "
                "map. The row read here is the one the hall's own authored plan row "
                "names, never last-wins on the map name"
                % (pack_meta["dual_filed"],
                   ", ".join(pack_meta.get("dual_filed_maps", [])[:3])))
    else:
        rep.stale.append("%s could not be read - every built bead is unattributed"
                         % _rel(PACK))
    if slid_n:
        rep.notes.append(
            "%d of the %d packed beads stand somewhere OTHER than the cell their map "
            "names, %d of them after an outward ring search - `slid_to` and `slid_z_m` "
            "carry the floor the visitor actually walks up to, and cx/cz stay the "
            "map's declaration" % (slid_n, matched_n, ringed_n))
    if bake_meta:
        rep.stale.append(
            "%s is ADVISORY here and its `refused` rows are failed CANDIDATE CELLS, "
            "not failed artifacts: %d of them across the built halls, against %d "
            "bodies that stand. It was taken %s against a plan stamped %s and carries "
            "ONE stamp for %d segments, replaying a decision rather than retaking it, "
            "so a segment survives an edit to the map it describes"
            % (_rel(BAKE), bake_candidates, matched_n, bake_meta.get("at", "?"),
               bake_meta.get("plan_at", "?"), bake_meta.get("segments", 0)))
    for name, key, nb in silent_bake:
        rep.stale.append(
            "the bake's segment %r is present and EMPTY while the pack ledger records "
            "%d bodies for %s - the bake is silent about that hall, which is not the "
            "same as the hall being empty" % (key, nb, name))

    # THE REFUSED BLOCK IS ABOUT ARTIFACTS THAT DO NOT STAND, and nothing else.
    # It used to be seeded from the bake, where a `refused` row is a candidate
    # cell, so it counted one body's ring search as twenty missing artifacts.
    whys = {}
    for r in order:
        if r["state"] == "refused":
            whys[r.get("why", "")] = whys.get(r.get("why", ""), 0) + 1
    for why, n in sorted(whys.items(), key=lambda kv: -kv[1]):
        rep.refused.append("%d artifact(s) do not stand: %s" % (n, why or "no reason given"))
    dead_ref = sum(1 for r in order if r["state"] == "refused" and not r["alive"])
    if dead_ref:
        rep.refused.append(
            "%d of those are refused because the token has no living scene on disk - "
            "that refusal happens before the placer runs, so it has never appeared in "
            "the bake at all, and the bead carries alive: false as well" % dead_ref)

    snap = snapshot_check(strip)
    # THE SENTENCE LIVES IN _meta.source_check, NOT IN _report. It is the one
    # finding in this document that is about a file this tool does not derive
    # from and another session owns, and --check strips the whole subtree before
    # comparing: a gate that fails because somebody else re-ran their own --apply
    # is a gate people learn to ignore. Show it in the HUD from here instead.
    snap["note"] = ("%s matches the maps" % _rel(SNAPSHOT)) if snap["matches"] else (
        "%s does not match the maps: it holds %s artifacts, the maps hold %d%s. "
        "This string was derived from the MAPS. Re-run "
        "`python tools/long_museum.py --apply` to bring the page's copy level."
        % (_rel(SNAPSHOT), snap["file_artifacts"], snap["derived_artifacts"],
           (" (%d hall(s) differ, first: %s)"
            % (snap.get("halls_differing_n", 0), ", ".join(snap["halls_differing"][:4])))
           if snap["halls_differing"] else ""))

    mis = sum(1 for r in order[:placements]
              if r.get("spine_sequence") and r["spine_sequence"] != r["sequence"])
    if mis:
        rep.notes.append(
            "%d placements stand in a museum chapter the curriculum files them under "
            "a DIFFERENT one - `sequence` is the hall's chapter, `spine_sequence` is "
            "the curriculum's, and they are both true" % mis)

    doc = {
        "schema": SCHEMA,
        "_readme": (
            "THE MUSEUM'S ORDER - every artifact standing in the long museum, in the "
            "order you meet it walking from 0 m. DERIVED from the maps (via "
            "tools/long_museum.py), the plan and the bake; never hand-edit it. Same "
            "shape as commons/data/spine_order_effective.json wherever the meaning is "
            "the same, so one scene scrolls either. FOUR DIFFERENCES THE SCENE MUST "
            "WIRE: (1) the bead's identity is `at`, not `lookup` - 173 tokens repeat "
            "and one hall holds five of one. (2) `origin` is \"map\", not \"spine\" - "
            "read _meta.neutral_origin before colouring on it. (3) `map` is the hall "
            "you are STANDING in, not where the spine first meets the artifact - "
            "relabel the detail panel by schema. (4) `candidates` is empty on purpose: "
            "this string is read-only, because the only file an edit could touch is a "
            "map's interactables layer. (5) A BEAD'S CELL IS NOT ALWAYS WHERE THE BODY "
            "STANDS: cx/cz are the map's declaration and the bead's identity, and where "
            "the pack re-homed it `slid_to` / `slid_x_m` / `slid_z_m` carry the floor "
            "the visitor walks up to, with `rings` for how far the search looked. SHOW "
            "_meta.source_check.note AND _report VERBATIM. STATE COMES FROM "
            "ada_run/em_pack_report.json, never from em_bake.json, whose `refused` rows "
            "are failed CANDIDATE CELLS and not failed artifacts. Build: python "
            "tools/museum_necklace.py --apply"
        ),
        "_meta": {
            "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
            "generator": "tools/museum_necklace.py",
            "source": "commons/maps/*/map_data.json via tools/long_museum.py",
            "axis": "z", "unit_m": 1.0,
            "metres": strip["totals"]["cells_z"],
            "vestibule_h": VESTIBULE_H,
            "halls": len(halls),
            "chapters": sum(1 for c in chapters if c["in_spine"]),
            # `artifacts` is rows in `order`, the same meaning the spine file
            # gives it - the necklace's LENGTH. It is not the placement count,
            # because the last band has no cells.
            "artifacts": len(order),
            "placements": placements,
            "orphans_n": len(orphans),
            "distinct": len(total_token),
            "repeats": sum(1 for t, n in total_token.items() if n > 1),
            "alive": sum(1 for r in order if r["alive"]),
            "dead": sum(1 for r in order if not r["alive"]),
            "non_body_roots": sorted({r["lookup"] for r in order
                                      if r["alive"] and not r["body"]}),
            "states": states,
            "built_artifacts": built_n,
            "proposed_artifacts": placements - built_n,
            "in_spine_artifacts": in_spine_n,
            "off_curriculum_artifacts": off_n,
            "off_curriculum_halls": len(empty_halls),
            # THE JOIN, IN NUMBERS. matched + declared = the planned cells of the
            # built halls; extra = bodies the pack stood that no declared cell
            # claims. declared and extra are both 0 today and either going
            # non-zero means a map was edited after the pack ran.
            "pack_matched": matched_n,
            "pack_unmatched": declared_n,
            "pack_unclaimed_bodies": extra_n,
            "slid_artifacts": slid_n,
            "ring_searched_artifacts": ringed_n,
            "pack": pack_meta,
            # NOT REFUSALS. Candidate cells the ring search burned across the
            # built halls before finding floor. Kept because it is the number
            # this file used to publish AS refusals.
            "bake_candidate_fails": bake_candidates,
            "bake_silent_halls": [n for n, _k, _b in silent_bake],
            "bake": bake_meta,
            "plan_stamp": plan_stamp,
            "spine_source": spine_src,
            "source_check": snap,
            # ADVISORY, AND EXCLUDED FROM --check ON PURPOSE. A checkout touches
            # a file without changing it, and a gate that fires on that teaches
            # people to ignore the gate. The CONTENT tests above are what gates.
            "source_mtimes": {
                "plan": _mtime(PLAN), "bake": _mtime(BAKE),
                "long_museum": _mtime(SNAPSHOT),
                "spine": _mtime(SPINE_EFFECTIVE),
            },
            "neutral_origin": "map",
            "map_field": ("the hall you are standing in - NOT the spine's "
                          "\"first met in\". Relabel the detail panel by schema."),
            "identity_field": "at",
            "read_only": True,
            "plan_note": ("154 of the 207 halls are in a chapter the museum has never "
                          "built (endless_museum.gd builds from a map only where the "
                          "plan row says authored == \"map\"), so two thirds of this "
                          "string is a proposal and every bead says which it is"),
        },
        "_report": rep.as_dict(),
        "chapters": chapters,
        "halls": hall_rows,
        "order": order,
        # EMPTY, DELIBERATELY. See the module docstring: there is no honest add
        # to a string whose beads are floor cells. The key ships so the scene's
        # reader finds the shape it expects.
        "candidates": [],
    }
    return doc, rep


def _state_counts(rows):
    out = {}
    for r in rows:
        s = r["state"] if isinstance(r, dict) else r
        out[s] = out.get(s, 0) + 1
    return {k: out[k] for k in STATES if k in out}


def _chapters_of(order, halls, orphans, orph_i0):
    """The bands as they stand ON THE STRING, by consecutive run of `sequence`.

    The scene groups the same way in _reindex, so a band listed in any other
    order would be drawn somewhere the beads are not. The orphan band is the only
    one with in_spine false: it is not a chapter of the curriculum, it is what
    the curriculum claims and the building does not hold.
    """
    zs = {}
    for h in halls:
        d = zs.setdefault(h["sequence"], {"z0": h["z0"], "z1": h["z1"],
                                          "halls": 0, "built": bool(h.get("built")),
                                          "srcs": set(), "order": h["chapter"]})
        d["z0"] = min(d["z0"], h["z0"])
        d["z1"] = max(d["z1"], h["z1"])
        d["halls"] += 1
        d["srcs"].add(h["source"])
    out = []
    i = 0
    while i < len(order):
        seq = order[i]["sequence"]
        j = i
        while j < len(order) and order[j]["sequence"] == seq:
            j += 1
        d = zs.get(seq)
        row = {"sequence": seq, "i0": i, "n": j - i, "in_spine": d is not None}
        if d:
            row.update({"order": d["order"], "z0": d["z0"], "z1": d["z1"],
                        "halls": d["halls"], "built": d["built"],
                        "source": ("authored+ribbon" if len(d["srcs"]) > 1
                                   else next(iter(d["srcs"])))})
        else:
            row.update({"order": None, "z0": None, "z1": None,
                        "halls": 0, "built": False, "source": "spine"})
        out.append(row)
        i = j
    return out


# --------------------------------------------------------------------------
# the gate


def contract_faults(doc):
    """The invariants the file promises, checked ON THE FILE.

    This is what makes --check a gate for a hand edit too, and every one of these
    is a failure that has happened to a sibling string: an index that stopped
    agreeing with its position, a band drawn where its beads are not, a total
    that does not add up.
    """
    bad = []
    order = doc.get("order") or []
    if not order:
        return ["no beads"]
    seen_at = set()
    prev_z = -1
    for i, r in enumerate(order):
        if r.get("i") != i:
            bad.append("bead %d carries i %r" % (i, r.get("i")))
        at = r.get("at")
        if at in seen_at:
            bad.append("duplicate identity %r at bead %d" % (at, i))
        seen_at.add(at)
        if r.get("state") not in STATES:
            bad.append("bead %s has state %r" % (at, r.get("state")))
        z = r.get("z_m")
        if z is None:
            prev_z = None
        elif prev_z is None:
            # A metre mark AFTER the orphan band means the bands are interleaved
            # and the string does not walk anywhere.
            bad.append("bead %s has a metre mark after a bead that has none" % at)
        elif z < prev_z:
            bad.append("bead %s goes backwards: %s m after %s m" % (at, z, prev_z))
        else:
            prev_z = z
    m = doc.get("_meta") or {}
    if m.get("artifacts") != len(order):
        bad.append("_meta.artifacts %r but %d beads" % (m.get("artifacts"), len(order)))
    st = m.get("states") or {}
    if sum(st.values()) != len(order):
        bad.append("the states sum to %d, not %d" % (sum(st.values()), len(order)))
    if m.get("placements", 0) + m.get("orphans_n", 0) != len(order):
        bad.append("placements %r + orphans %r != %d beads"
                   % (m.get("placements"), m.get("orphans_n"), len(order)))
    # the bands must tile the string exactly
    pos = 0
    for c in doc.get("chapters") or []:
        if c.get("i0") != pos:
            bad.append("chapter %s starts at %r, expected %d"
                       % (c.get("sequence"), c.get("i0"), pos))
        pos += int(c.get("n") or 0)
    if pos != len(order):
        bad.append("the chapter bands cover %d beads of %d" % (pos, len(order)))
    pos = 0
    for h in doc.get("halls") or []:
        if h.get("i0") != pos:
            bad.append("hall %s starts at %r, expected %d" % (h.get("name"), h.get("i0"), pos))
        pos += int(h.get("n") or 0)
    if pos != len(order):
        bad.append("the hall bands cover %d beads of %d" % (pos, len(order)))
    if doc.get("candidates"):
        bad.append("candidates is not empty - this string is read-only")
    # slid_to only ever means "not where the map put it", and it must agree with
    # the metre marks it ships beside. A bead claiming a drift to its own cell
    # would draw an offset of zero and read as noise; one whose slid_z_m does not
    # follow from slid_to has had one of the two edited by hand.
    for r in order:
        s = r.get("slid_to")
        if s is None:
            if "slid_x_m" in r or "slid_z_m" in r:
                bad.append("bead %s carries a slid metre mark with no slid_to" % r.get("at"))
            continue
        if not (isinstance(s, list) and len(s) == 2):
            bad.append("bead %s has slid_to %r" % (r.get("at"), s))
            continue
        if s[0] == r.get("cx") and s[1] == r.get("cz"):
            bad.append("bead %s slid to its own cell" % r.get("at"))
        if r.get("state") != "placed":
            bad.append("bead %s is %r and carries slid_to - only a standing body has "
                       "somewhere to have slid to" % (r.get("at"), r.get("state")))
        if r.get("z_m") is not None and r.get("slid_z_m") != r["z_m"] - r["cz"] + s[1]:
            bad.append("bead %s: slid_z_m %r does not follow from slid_to %r"
                       % (r.get("at"), r.get("slid_z_m"), s))
        if "rings" in r and not r["rings"]:
            bad.append("bead %s carries rings 0 - the key is omitted when the body "
                       "stood on its own target, so its presence must mean something"
                       % r.get("at"))
    for r in order:
        if "rings" in r and r.get("state") in ("unbuilt", "nowhere", "unplanned", "declared"):
            bad.append("bead %s is %r and carries rings - nothing searched for it"
                       % (r.get("at"), r.get("state")))
        # ON A STANDING BODY `why` IS THE REASON IT MOVED, NOT A FAILURE, and the
        # two always arrive together: 43 beads, the same 43 either way. A placed
        # bead carrying one without the other would mean `why` had drifted into
        # meaning something else, which is exactly how this file got the last
        # verdict wrong.
        if r.get("state") == "placed" and ("why" in r) != ("rings" in r):
            bad.append("bead %s is placed and carries %s without the other - on a "
                       "standing body those two are the same event"
                       % (r.get("at"), "why" if "why" in r else "rings"))
        if "slid_to" in r and "rings" not in r and r.get("why"):
            bad.append("bead %s was aimed elsewhere rather than slid, and carries a "
                       "why - no search ran to produce one" % r.get("at"))
    return bad


def _strip_advisory(d):
    """A copy without the wall-clock stamps, so --check compares CONTENT."""
    out = json.loads(json.dumps(d))
    meta = out.get("_meta") or {}
    meta.pop("generated", None)
    meta.pop("source_mtimes", None)
    # source_check describes commons/data/long_museum.json, which this tool does
    # not derive from and may not write, and which another session re-applied
    # twice in the hour this file was written. Comparing it would fail the gate
    # on somebody else's work.
    meta.pop("source_check", None)
    return out


def diff_docs(fresh, have, limit=15):
    """Where the written file and a fresh derivation disagree, most load-bearing
    first: the counts, then the bands, then the bead."""
    out = []
    a, b = _strip_advisory(fresh), _strip_advisory(have)
    if a.get("schema") != b.get("schema"):
        out.append("schema: file %r, sources %r" % (b.get("schema"), a.get("schema")))
    for k in sorted(set(a.get("_meta", {})) | set(b.get("_meta", {}))):
        if a["_meta"].get(k) != b.get("_meta", {}).get(k):
            out.append("_meta.%s: file %r, sources %r"
                       % (k, b.get("_meta", {}).get(k), a["_meta"].get(k)))
    for band in ("chapters", "halls"):
        ab, bb = a.get(band) or [], b.get(band) or []
        if len(ab) != len(bb):
            out.append("%s: file %d, sources %d" % (band, len(bb), len(ab)))
        for x, y in zip(bb, ab):
            if x != y:
                out.append("%s %s: file %r, sources %r"
                           % (band[:-1], y.get("name", y.get("sequence")), x, y))
    ao, bo = a.get("order") or [], b.get("order") or []
    if len(ao) != len(bo):
        out.append("beads: file %d, sources %d" % (len(bo), len(ao)))
    for x, y in zip(bo, ao):
        if x.get("at") != y.get("at"):
            out.append("bead %d: file %s, sources %s" % (y.get("i"), x.get("at"), y.get("at")))
        elif x != y:
            for k in sorted(set(x) | set(y)):
                if x.get(k) != y.get(k):
                    out.append("bead %s .%s: file %r, sources %r"
                               % (y.get("at"), k, x.get(k), y.get(k)))
    return out[:limit], len(out)


# --------------------------------------------------------------------------
# the command line


def _bead_line(r):
    z = "   -  " if r.get("z_m") is None else "%5d m" % r["z_m"]
    marks = []
    if not r["in_spine"]:
        marks.append("OFF-CURRICULUM")
    if not r["alive"]:
        marks.append("DEAD")
    if r["alive"] and not r["body"]:
        marks.append("NOT A BODY")
    if r.get("slid_to"):
        marks.append("stands at %d,%d" % (r["slid_to"][0], r["slid_to"][1]))
    if r.get("rings"):
        marks.append("%d ring(s)" % r["rings"])
    if r.get("outside_floor"):
        marks.append("outside the floor")
    nth = "" if r["of"] == 1 else "  %d/%d" % (r["nth"], r["of"])
    return "  %4d %s  %-34s %-26s %-9s%s%s" % (
        r["i"], z, r["at"][:34], r["lookup"][:26], r["state"], nth,
        ("  " + " ".join(marks)) if marks else "")


def summary(doc, rep, beads=10, hall=None):
    m = doc["_meta"]
    order = doc["order"]
    if hall:
        rows = [r for r in order if r["hall"] == hall or r["sequence"] == hall]
        if not rows:
            print("  no hall or chapter named %r on the string" % hall)
            return
        print()
        for r in rows:
            print(_bead_line(r))
        print()
        return

    print()
    print("  #  chapter                 halls  beads     z0     z1  built  in spine")
    for n, c in enumerate(doc["chapters"], 1):
        z0 = "" if c["z0"] is None else "%6d" % c["z0"]
        z1 = "" if c["z1"] is None else "%6d" % c["z1"]
        print("  %2d  %-22s %5d %6d %6s %6s  %-5s  %d"
              % (n, c["sequence"][:22], c["halls"], c["n"], z0, z1,
                 "yes" if c["built"] else "no",
                 sum(1 for r in order[c["i0"]:c["i0"] + c["n"]] if r["in_spine"])))
    print("      %-22s %5d %6d %6d %6d  %-5s  %d"
          % ("TOTAL", m["halls"], m["artifacts"], 0, m["metres"],
             "", m["in_spine_artifacts"]))
    print()
    print("  FIRST %d BEADS" % beads)
    for r in order[:beads]:
        print(_bead_line(r))
    # THE FAR END OF THE BUILDING AND THE END OF THE STRING ARE NOT THE SAME
    # PLACE, and printing only the second hides the first: the last 50 beads have
    # no metre mark at all. Both ends get shown.
    walked = [r for r in order if r["z_m"] is not None]
    print("  LAST %d BEADS THAT STAND SOMEWHERE (the far wall, %d m)"
          % (beads, walked[-1]["z_m"] if walked else 0))
    for r in walked[-beads:]:
        print(_bead_line(r))
    tail = [r for r in order if r["z_m"] is None]
    if tail:
        print("  LAST %d BEADS OF THE STRING (%s)" % (beads, ORPHAN_BAND))
        for r in tail[-beads:]:
            print(_bead_line(r))
    print()
    st = m["states"]
    print("  STATE                 beads")
    for k in STATES:
        if k in st:
            print("    %-18s %6d" % (k, st[k]))
    print("    %-18s %6d   (= %d placements + %d claimed and nowhere built)"
          % ("TOTAL", sum(st.values()), m["placements"], m["orphans_n"]))
    print()
    print("  %d placements, %d distinct tokens, %d of them more than once"
          % (m["placements"], m["distinct"], m["repeats"]))
    print("  %d of %d in a built chapter (%.0f%%), %d in the spine order (%.0f%%), "
          "%d off the curriculum"
          % (m["built_artifacts"], m["placements"],
             100.0 * m["built_artifacts"] / max(1, m["placements"]),
             m["in_spine_artifacts"],
             100.0 * m["in_spine_artifacts"] / max(1, m["placements"]),
             m["off_curriculum_artifacts"]))
    print("  the pack ledger accounts for %d planned cells, %d unaccounted, %d bodies "
          "unclaimed" % (m["pack_matched"], m["pack_unmatched"],
                         m["pack_unclaimed_bodies"]))
    print("  %d of those stand somewhere other than the cell their map names (%d after "
          "a ring search); %d alive, %d dead"
          % (m["slid_artifacts"], m["ring_searched_artifacts"], m["alive"], m["dead"]))
    print("  the bake burned %d CANDIDATE CELLS in those halls - candidate cells, not "
          "artifacts" % m["bake_candidate_fails"])
    print()
    print("  %-8s %s" % ("SOURCE", m["source_check"]["note"]))
    for label, lines in (("NOTE", rep.notes), ("STALE", rep.stale),
                         ("DEGRADED", rep.degraded), ("REFUSED", rep.refused)):
        for line in lines[:8]:
            print("  %-8s %s" % (label, line))
        if len(lines) > 8:
            print("  %-8s ... and %d more" % (label, len(lines) - 8))
    print()
    print("  %s" % m["plan_note"])


def main():
    ap = argparse.ArgumentParser(
        description="the artifacts of the actual museum, in the order you meet them")
    ap.add_argument("--apply", action="store_true",
                    help="write commons/data/museum_order_effective.json")
    ap.add_argument("--check", action="store_true",
                    help="verify the written file against its sources; non-zero on any "
                         "disagreement")
    ap.add_argument("--json", action="store_true", help="print the document to stdout")
    ap.add_argument("--beads", type=int, default=10,
                    help="how many beads to print at each end (default 10)")
    ap.add_argument("--hall", default="", help="print one hall's or one chapter's beads")
    args = ap.parse_args()

    doc, rep = build()

    faults = contract_faults(doc)
    if faults:
        # The builder disagreeing with its own contract means the STRING is
        # wrong, not the file. Refuse before anything is written.
        for f in faults:
            print("CONTRACT: %s" % f, file=sys.stderr)
        return 1

    if args.json:
        # THROUGH THE BYTE STREAM, NOT sys.stdout. A Windows console is cp1252
        # and 1,252 registry descriptions carry characters that are not in it,
        # so json.dump(..., sys.stdout) DIED 92,615 bytes into a 1.1 MB document
        # with a UnicodeEncodeError - and a caller redirecting stderr sees only a
        # truncated file and a JSONDecodeError about column 92,616. Encoding here
        # makes the pipe independent of the console's codepage.
        sys.stdout.flush()
        payload = json.dumps(doc, ensure_ascii=False, separators=(",", ":"))
        sys.stdout.buffer.write(payload.encode("utf-8"))
        sys.stdout.buffer.write(b"\n")
        sys.stdout.buffer.flush()
        return 0

    if args.check:
        have, state = NO.read_json_state(OUT)
        if state == NO.ST_ABSENT:
            print("MISSING: %s - run `python tools/museum_necklace.py --apply`" % _rel(OUT),
                  file=sys.stderr)
            return 2
        if state != NO.ST_OK:
            # EMPTY AND UNPARSEABLE ARE DIFFERENT ANSWERS AND BOTH ARE REAL. A
            # zero-byte file is the residue of a killed write, and this repo
            # wraps runs in godot_watchdog.py, which kills the process tree.
            print("DAMAGED: %s is %s - re-derive it with "
                  "`python tools/museum_necklace.py --apply`" % (_rel(OUT), state),
                  file=sys.stderr)
            return 2
        stale = contract_faults(have)
        for f in stale:
            print("CONTRACT (file): %s" % f, file=sys.stderr)
        shown, total = diff_docs(doc, have)
        for line in shown:
            print("DIFF: %s" % line, file=sys.stderr)
        if total > len(shown):
            print("DIFF: ... and %d more" % (total - len(shown)), file=sys.stderr)
        if total or stale:
            print("check FAILED: %d disagreement(s) with the sources, %d contract fault(s)"
                  % (total, len(stale)), file=sys.stderr)
            return 1
        hm = have["_meta"]
        print("check OK: %s matches its sources - %d beads (%d placements + %d claimed "
              "and nowhere built), %d halls, %d m"
              % (_rel(OUT), hm["artifacts"], hm["placements"], hm["orphans_n"],
                 hm["halls"], hm["metres"]))
        return 0

    if args.apply:
        # Compact: 1,633 beads at indent 1 is megabytes of whitespace for a file
        # only a machine opens. Atomic, via .tmp + os.replace, because
        # open(path, "w") truncates BEFORE it writes and a kill in that window
        # leaves a zero-byte file where the answer was - the exact loss a sibling
        # tool was audited for this morning.
        NO.write_json_atomic(OUT, doc, indent=None)
        print("wrote %s" % _rel(OUT))
        summary(doc, rep, beads=args.beads, hall=args.hall or None)
        return 0

    summary(doc, rep, beads=args.beads, hall=args.hall or None)
    print()
    print("  nothing was written. `--apply` writes %s" % _rel(OUT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
