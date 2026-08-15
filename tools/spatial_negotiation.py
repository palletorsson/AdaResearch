#!/usr/bin/env python3
"""The negotiation layer — where an artifact's ask meets architecture's offer.

Artifacts describe what they need (tools/spatial_contract.py). Architecture
describes what it offers (tools/spatial_floorplan.py). This module resolves the
relationship explicitly, and every decision it makes can say why.

It reuses the box-level contract rules already proven in
`tools/placement_negotiator.py` (10 passing tests, untouched) and adds the two
things that module could not express:

  * CELL MASKS, so directional clearance survives contact with the grid, and
  * WALL (u, v) RECTANGLES, so a wall-mounted work and the floor space in front
    of it are negotiated together rather than in two unrelated passes.

Conflict severity, per the brief:

    physical overlap        -> invalid
    required-access overlap -> invalid
    presentation overlap    -> allowed, with a penalty

Escalation order. Room expansion is a late fallback, never the first answer:

    1. preferred slot
    2. allowed rotation
    3. alternate placement mode
    4. against-wall / plinth exception
    5. another compatible slot
    6. expand the room
    7. fail explicitly

Usage:
    python tools/spatial_negotiation.py --artifacts=bias_visualizer,science_screen
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))

from spatial_contract import (ROTATION_FACING, SpatialContract, Masks, lift_for,
                              masks, side_dir)
# The negotiator consumes DRESSING ROOMS (SPATIAL_PIPELINE.md §5), not the
# resolver's dataclass. `staged_contract` returns the authored room's contract
# where one exists and a generated default where none does; `resolve` is
# deliberately not imported here, so the bypass cannot come back by habit.
from emit_dressing_room import staged_contract
from spatial_floorplan import FloorPlan, Slot, WallSurface, build_enfilade

#: What a presentation-cell intrusion costs. A neighbour taking the space is a
#: real competition; the room simply ending there is architecture, and costs
#: less. Both are capped so presentation can never outvote a hard rule.
PRESENTATION_PENALTY = 0.02
PRESENTATION_EDGE_PENALTY = 0.005
PRESENTATION_PENALTY_CAP = 0.30

#: Which way a wall faces, into the room. The artifact's back must point the
#: opposite way, which is what fixes its rotation on that wall.
WALL_NORMAL = {"west": (1, 0), "east": (-1, 0), "south": (0, -1), "north": (0, 1)}
#: How many times the room may grow before the answer is simply "no".
MAX_EXPANSIONS = 3


def _pocket_width(plan: FloorPlan, slot: Slot) -> int:
    """How many cells wide the pocket behind a slot actually is."""
    if not slot.free_cells:
        return 0
    xs = {x for x, _ in slot.free_cells}
    return max(xs) - min(xs) + 1


def back_dir(rotation: int) -> tuple[int, int]:
    """Which way an artifact's back faces at a cardinal rotation.

    Follows the project's DECLARED convention (artifact_spatial_contracts.json
    `rotation_semantics`: 0=south, 90=west, 180=north, 270=east), not a locally
    invented one — guessing the zero mirrors every wall placement.
    """
    fx, fz = ROTATION_FACING[int(rotation) % 360]
    return (-fx, -fz)


def origin_for(slot: Slot, m: Masks) -> tuple[int, int]:
    """Where the mask's (0,0) lands in world cells, at the slot's nominal cell.

    Freestanding artifacts centre on the slot cell. An artifact using a wall is
    pushed flush against it, so the gap the contract gave up in `against_wall`
    mode is actually taken up by the wall rather than left as dead floor.
    """
    xs = [c[0] for c in m.physical] or [0]
    zs = [c[1] for c in m.physical] or [0]
    sx, sz = slot.cell
    if slot.wall_side is None:
        return sx, sz
    nx, nz = WALL_NORMAL[slot.wall_side]
    ox = sx - (max(xs) if nx < 0 else min(xs) if nx > 0 else 0) if nx else sx
    oz = sz - (max(zs) if nz < 0 else min(zs) if nz > 0 else 0) if nz else sz
    return ox, oz


def candidate_origins(slot: Slot, m: Masks, plan: FloorPlan,
                      limit: int = 48) -> list[tuple[int, int]]:
    """Every anchor the slot's ZONE can offer, nearest-first.

    A slot is a candidate placement zone, not a single cell. A wall slot may
    slide along its wall but never off it; an island slot may move anywhere in
    its pocket. Without this, a pocket can be wide enough and the artifact
    still 'not fit' because one nominal cell happened to sit near a corner.
    """
    nominal = origin_for(slot, m)
    if not slot.free_cells:
        return [nominal]
    if slot.venue != "interior":
        # The grounds are hundreds of cells; sampling the 48 nearest only ever
        # probes the shallow strip closest to the building, which is exactly
        # where a room-scale body cannot fit.
        limit = max(limit, 400)
    xs = [c[0] for c in m.physical] or [0]
    zs = [c[1] for c in m.physical] or [0]
    pocket_x = sorted({x for x, _ in slot.free_cells})
    pocket_z = sorted({z for _, z in slot.free_cells})

    out: list[tuple[int, int]] = []
    if slot.wall_side is None:
        # The pocket's own cells, NOT the product of its x and z ranges. An
        # L-shaped or BFS-derived pocket has a bounding box far larger than
        # itself, and taking the product let a body drift 58 cells from its
        # slot and still call itself placed there.
        out = list(slot.free_cells)
    else:
        # Flush against the slot's OWN wall. Deriving the wall from the plan
        # border only worked because the enfilade puts its walls there; a
        # template loaded inside an apron has its walls in the middle of the
        # plan, and the border assumption threw science_screen 23 cells west of
        # the slot it was supposedly placed at.
        nx, nz = WALL_NORMAL[slot.wall_side]
        sx, sz = slot.cell
        if nx:                              # a side wall: slide along z
            ox = sx - (min(xs) if nx > 0 else max(xs))
            out = [(ox, z) for z in pocket_z]
        else:                               # an end wall: slide along x
            oz = sz - (min(zs) if nz > 0 else max(zs))
            out = [(x, oz) for x in pocket_x]
    out.sort(key=lambda c: abs(c[0] - nominal[0]) + abs(c[1] - nominal[1]))
    return out[:limit] or [nominal]


def world_footprint(contract: SpatialContract, rotation: int) -> tuple[int, int]:
    """The body's [w, d] in world axes at a cardinal rotation."""
    w, d = contract.footprint_cells
    return (w, d) if rotation % 180 == 0 else (d, w)


def capacity_fits(slot: Slot, contract: SpatialContract,
                  rotation: int) -> tuple[bool, str]:
    """Can this slot hold this body, according to the precomputed table?

    A slot with no declared capacity is not refused — it is simply unknown, and
    falls through to the search. Refusing on missing data would make the
    invented enfilade unplaceable overnight.
    """
    per = (slot.capacity or {}).get("per_rotation") or {}
    rec = per.get(str(rotation % 360))
    if not rec:
        return True, "no declared capacity; falls through to search"
    w, d = world_footprint(contract, rotation)
    if rec["max_w"] >= w and rec["max_d"] >= d:
        slack = rec["max_area"] - (w * d)
        return True, f"offers {rec['max_w']}x{rec['max_d']}, needs {w}x{d} (slack {slack})"
    return False, f"offers {rec['max_w']}x{rec['max_d']}, needs {w}x{d}"


def rank_slots(contract: SpatialContract, plan: FloorPlan) -> list[tuple[Slot, str]]:
    """Order the plan's slots by how well each MATCHES the contract.

    This is the lookup that replaces a search. The 475 authored slots carry
    sightlines and pacing no solver reproduces, and tools/slot_capacity.py has
    already computed what each can hold — so the first question is 'which slot
    was made for this?', not 'where can I squeeze it?'.

    Three tiers, in order:
      matched   an interior slot whose declared capacity holds the body
      searched  an interior slot with no declared capacity, or too small
      exterior  a courtyard, porch, balcony, bridge or the grounds

    Within `matched`, tightest fit first — that is `compactness`, last in the
    project's declared priority, used only to break ties among valid slots.
    """
    rotations = contract.rotations or [0]
    matched: list[tuple[int, int, Slot]] = []
    searched: list[Slot] = []
    exterior: list[Slot] = []

    for slot in _wall_variants(plan.slots):
        if slot.venue != "interior":
            exterior.append(slot)
            continue
        per = (slot.capacity or {}).get("per_rotation") or {}
        if not per:
            searched.append(slot)
            continue
        best: int | None = None
        for rot in rotations:
            ok, _ = capacity_fits(slot, contract, rot)
            if not ok:
                continue
            rec = per.get(str(rot % 360))
            w, d = world_footprint(contract, rot)
            slack = (rec["max_area"] if rec else w * d) - (w * d)
            best = slack if best is None else min(best, slack)
        if best is None:
            searched.append(slot)
        else:
            matched.append((_affinity(contract, slot), best, slot))

    matched.sort(key=lambda t: (t[0], t[1]))
    exterior.sort(key=lambda s: EXTERIOR_ORDER.index(s.venue)
                  if s.venue in EXTERIOR_ORDER else len(EXTERIOR_ORDER))

    want = getattr(contract, "preferred_venue", "interior")
    if want != "interior":
        # A work that ASKS for the courtyard is not a work that failed to fit
        # indoors. Its venue is tried first, and the museum interior becomes
        # the fallback — the same shape as preferred_mode, and for the same
        # reason: stated intent outranks what the solver would have chosen.
        wanted = [s for s in exterior if s.venue == want]
        rest = [s for s in exterior if s.venue != want]
        order: list[tuple[Slot, str]] = [(s, "preferred_venue") for s in wanted]
        order += [(s, "matched") for _, _, s in matched]
        order += [(s, "searched") for s in searched]
        order += [(s, "exterior") for s in rest]
        return order

    order = [(s, "matched") for _, _, s in matched]
    order += [(s, "searched") for s in searched]
    order += [(s, "exterior") for s in exterior]
    return order


def _wall_variants(slots: list[Slot]) -> list[Slot]:
    """One candidate per wall a corner slot backs onto.

    A slot in a corner offers two different placements — back to the west wall,
    or back to the north one — and they admit different rotations. Modelling
    only the first wall silently removed the option that would have fitted.
    """
    from dataclasses import replace
    out: list[Slot] = []
    for s in slots:
        sides = list(getattr(s, "wall_sides", None) or ([s.wall_side] if s.wall_side else []))
        if len(sides) <= 1:
            out.append(s)
            continue
        for side in sides:
            out.append(replace(s, id=f"{s.id}@{side}", wall_side=side))
        out.append(replace(s, id=f"{s.id}@free", wall_side=None))
    return out


#: How far from the museum each exterior venue is. A courtyard is still inside
#: the walls; the grounds are the last resort that is still a real place.
EXTERIOR_ORDER = ("courtyard", "balcony", "bridge", "porch", "outside")


def _affinity(contract: SpatialContract, slot: Slot) -> int:
    """Lower is a better fit of KIND — role and mode, before size."""
    score = 0
    if contract.preferred_mode == "against_wall":
        score += 0 if slot.wall_side else 3
    else:
        score += 2 if slot.wall_side else 0
    if contract.importance == "feature":
        score += 0 if slot.role == "3s" else 1
    elif slot.role == "3s":
        score += 2                       # do not spend the hero position lightly
    if contract.required_support == "podium":
        score += 0 if slot.support == "podium" else 2
    return score


@dataclass
class Trace:
    rule: str
    status: str          # pass | fail | applied | compromised
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"rule": self.rule, "status": self.status, "detail": self.detail}


@dataclass
class Occupancy:
    """Who owns which cell, and at what severity."""
    physical: dict[tuple[int, int], str] = field(default_factory=dict)
    circulation: dict[tuple[int, int], str] = field(default_factory=dict)
    presentation: dict[tuple[int, int], str] = field(default_factory=dict)

    def commit(self, owner: str, m: Masks, anchor: tuple[int, int]) -> None:
        ax, az = anchor
        for c in m.physical:
            self.physical[(c[0] + ax, c[1] + az)] = owner
        for c in m.circulation:
            self.circulation[(c[0] + ax, c[1] + az)] = owner
        for c in m.presentation:
            self.presentation.setdefault((c[0] + ax, c[1] + az), owner)


@dataclass
class Placement:
    artifact: str
    slot: str
    anchor: tuple[int, int]
    rotation: int
    mode: str
    wall: str | None
    wall_rect: list[float] | None
    venue: str
    #: The height of the surface the body stands ON. A plan that forgets its
    #: own podium under-states how tall the result will be, and the 3D gate
    #: then reports a fault that is really the plan's arithmetic.
    support_height_m: float
    score: float
    result: str                       # ACCEPT | REJECT
    traces: list[Trace]
    exceptions: list[str]
    masks: Masks | None = None
    contract: SpatialContract | None = None
    #: Courtyard outer dims [w, d] in whole cells, set only when venue is
    #: "courtyard". The negotiator owns placement SIZES the way it owns slots:
    #: computed once from the body + a 3 m apron each side, so the assembler
    #: never re-derives it from the body — re-deriving is how the two sides
    #: drift (the 4 m vestibule offset was exactly that, spike 03).
    court_m: list[int] | None = None
    #: How a courtyard preserves the endless route. None is the original
    #: centred court. ``bridge`` means the court expands beside a protected
    #: through-bridge, so a broad precinct can be entered without its body
    #: severing the museum. This is a negotiated result: the assembler may
    #: render it, but may not infer it from body size.
    court_access: str | None = None
    #: SPIKE 09 rung 1: interior wall cells (plan-grid coords, apron included)
    #: the tile must open into floor for this placement to exist. Set only by
    #: the bay rung. The assembler subtracts the apron and applies them to the
    #: tile before derivation — the plan is the author of the bay, not the
    #: builder.
    bay_cells: list[tuple[int, int]] | None = None

    def as_dict(self) -> dict[str, Any]:
        return {
            "artifact": self.artifact, "placement_mode": self.mode,
            "rotation": self.rotation, "slot": self.slot,
            "anchor_cell": list(self.anchor), "wall": self.wall,
            "wall_rect_uv": self.wall_rect, "venue": self.venue,
            "support_height_m": self.support_height_m,
            "score": round(self.score, 3), "result": self.result,
            "court_m": self.court_m,
            "court_access": self.court_access,
            "bay_cells": [list(c) for c in self.bay_cells] if self.bay_cells else None,
            "exceptions": self.exceptions,
            "rules": [t.as_dict() for t in self.traces],
        }


# ── Placement test ──────────────────────────────────────────────────

def _side_cells(m: Masks, side: str, rotation: int) -> set[tuple[int, int]]:
    """The circulation cells that belong to one artifact-local side, after
    rotation — the cells that must stay reachable for `required_sides`.

    Derived from the declared facing rather than a hand-written switch, so it
    cannot drift out of step with the mask that produced the cells.
    """
    cells = m.circulation
    if not cells:
        return set()
    xs = [c[0] for c in m.physical] or [0]
    zs = [c[1] for c in m.physical] or [0]
    dx, dz = side_dir(side, rotation)
    if dz > 0:
        return {c for c in cells if c[1] > max(zs)}
    if dz < 0:
        return {c for c in cells if c[1] < min(zs)}
    if dx > 0:
        return {c for c in cells if c[0] > max(xs)}
    return {c for c in cells if c[0] < min(xs)}


def try_place(contract: SpatialContract, slot: Slot, plan: FloorPlan,
              occ: Occupancy, rotation: int, mode: str,
              origin: tuple[int, int] | None = None
              ) -> tuple[bool, float, list[Trace], list[str]]:
    """One concrete attempt. Returns (ok, score, traces, exceptions)."""
    traces: list[Trace] = []
    exceptions: list[str] = []
    # A lone authored rotation is a preference, so turning the work is allowed —
    # but never silently. Every placement that faces a way the author did not
    # write says so, which is what keeps "preference" from meaning "ignored".
    authored = getattr(contract, "authored_rotation", None)
    if authored is not None and rotation != authored:
        exceptions.append(
            f"turned to rotation {rotation}; the dressing room wrote {authored} "
            f"(one declared rotation is a preference, not a constraint)")
    m = masks(contract, rotation, mode)
    # EXTEND. This used to reassign, which silently dropped the rotation
    # compromise recorded above — the record that keeps a preference from
    # meaning "ignored".
    exceptions += list(m.exceptions)
    ax, az = origin if origin is not None else origin_for(slot, m)
    score = 1.0

    # Support the slot actually has.
    # A PLINTH IS FURNITURE, NOT A TILE. This rule used to demand a `podium`
    # slot for anything asking to be raised, and rejected 306 placements across
    # the corpus with "slot offers 'floor', artifact needs 'pedestal'" — read as
    # a shortage of podium tiles in 182 authored museums. It was not. The museum
    # already stands plinths on floor cells: `em_plinths.gd` decides per token
    # and computes its lift as `TARGET_CENTRE - h/2 - cell.top`, SUBTRACTING the
    # riser the template built. A floor slot is not a refusal; it is a taller
    # plinth. Demanding the tile was architecture being asked to pre-declare a
    # staging decision that belongs to the assembler.
    #
    # AND A VOCABULARY IS NOT AN ARCHITECTURAL DEMAND. This rule then spent a
    # second life refusing words it had simply never been taught. It was written
    # against `placement_contract.required_support` (82 rooms) while 2538 rooms
    # carry `room.posture`, whose vocabulary — tools/classify_postures.POSTURES —
    # is eight words wide. Over the 24-chapter spine run, 198 of 1156 offered
    # bodies declared a support no slot in any of 30 museums could satisfy, and
    # this became the largest single refusal reason in the corpus: 205 of 478.
    # `platform` alone was 120 of them, and `classify_postures.build_footing`
    # raises it 1.0 m — the same lift as `table`, which was already accepted.
    #
    # The words are reconciled once, in spatial_contract.SUPPORT_ALIASES, so
    # this rule sees only what a slot can actually offer.
    need_support = contract.required_support
    wants_lift = need_support == "podium"
    plinth_h = (lift_for(contract.body_m[2], slot.surface_height_m)
                if wants_lift and slot.support in ("floor", "podium") else 0.0)
    # AND A ZERO LIFT IS NOT A REFUSAL. `lift_for` returns 0.0 for two different
    # reasons and this test could only read one of them. It means "no riser
    # needed" — the body already stands with its centre in the viewing band, so
    # raising it would push the work over the visitor's head — and it was being
    # read as "a floor slot cannot serve this artifact". With the shipped band
    # (target_centre 1.15, min_lift 0.25) the crossover is exact:
    #
    #     body_h > 2 * (1.15 - 0.25) = 1.80 m
    #
    # so every body taller than 1.80 m asking to be raised was refused from every
    # floor slot in all 30 museums PRECISELY BECAUSE it did not need raising. The
    # plinth ruling ("a floor slot is not a refusal; it is a taller plinth") held
    # all the way up the size range and then inverted at the top. 62 of 799 spine
    # artifacts sit past that line. See doc/spatial/spikes/02_the_overloaded_zero.md.
    no_lift_needed = wants_lift and lift_for(contract.body_m[2], 0.0) <= 0.0
    support_ok = (need_support == "floor"
                  or need_support == slot.support
                  or (need_support == "wall" and slot.wall_side is not None)
                  or (wants_lift and slot.support == "podium")
                  or (wants_lift and slot.support == "floor"
                      and (plinth_h > 0.0 or no_lift_needed)))
    traces.append(Trace("support_matches_contract", "pass" if support_ok else "fail",
                        f"slot offers {slot.support!r}, artifact needs {need_support!r}"
                        + (f"; a {plinth_h:.2f} m plinth supplies it" if plinth_h else "")))
    if not support_ok:
        return False, 0.0, traces, exceptions
    # Reserved so the ceiling check below measures the artifact ON its plinth.
    # An unreserved lift is how a plan clears a 4 m wall on paper and puts a
    # head through it in the room.
    if plinth_h > 0.0:
        exceptions.append(f"plinth {plinth_h:.2f} m supplied by the assembler "
                          f"(em_plinths decides the final form per token)")

    # against_wall must actually have that wall, and must FACE OUT of it.
    if mode == "against_wall":
        if slot.wall_side is None:
            traces.append(Trace("wall_is_available", "fail",
                                f"slot {slot.id} does not back onto a wall"))
            return False, 0.0, traces, exceptions
        normal = WALL_NORMAL[slot.wall_side]
        want = (-normal[0], -normal[1])
        if back_dir(rotation) != want:
            traces.append(Trace("faces_out_of_wall", "fail",
                                f"at {rotation}deg the back points {back_dir(rotation)}, "
                                f"but this wall needs {want}"))
            return False, 0.0, traces, exceptions
        traces.append(Trace("faces_out_of_wall", "pass",
                            f"backs onto the {slot.wall_side} wall at {rotation}deg"))

    # Vertical fit. A room is a box, not a floorplan: an artifact taller than
    # the wall sticks out through the top, which a purely 2D negotiator will
    # happily call a perfect placement. Found by looking at the capture.
    # The plinth counts. A reserved lift the ceiling check ignores is a plan
    # that clears 4 m on paper and puts a head through the soffit in the room.
    stand_h = (slot.surface_height_m if mode == "host_mounted" else 0.0) + plinth_h
    total_h = contract.body_m[2] + stand_h
    open_sky = slot.venue != "interior"
    if open_sky:
        traces.append(Trace("body_fits_under_ceiling", "pass",
                            f"{total_h:.2f} m under open sky in the {slot.venue}"))
    elif total_h > plan.wall_height_m + 0.01:
        traces.append(Trace("body_fits_under_ceiling", "fail",
                            f"body is {total_h:.2f} m tall on a {stand_h:g} m support, "
                            f"the room is {plan.wall_height_m:g} m"))
        return False, 0.0, traces, exceptions
    traces.append(Trace("body_fits_under_ceiling", "pass",
                        f"{total_h:.2f} m under a {plan.wall_height_m:g} m wall"))

    # Physical: inside the room, on walkable floor, not on another body.
    world_phys = {(c[0] + ax, c[1] + az) for c in m.physical}
    for c in world_phys:
        if not plan.walkable(*c):
            traces.append(Trace("body_inside_room", "fail",
                                f"body cell {c} is wall or void"))
            return False, 0.0, traces, exceptions
    clash = world_phys & (set(occ.physical) | set(occ.circulation))
    if clash:
        owner = occ.physical.get(next(iter(clash))) or occ.circulation.get(next(iter(clash)))
        traces.append(Trace("physical_overlap", "fail",
                            f"{len(clash)} body cells collide with {owner}"))
        return False, 0.0, traces, exceptions
    traces.append(Trace("physical_overlap", "pass", "no body collision"))

    # Required access: each side needs somewhere to STAND, not a clear apron.
    access_penalty = 0.0
    for side in contract.required_sides:
        band = {(c[0] + ax, c[1] + az) for c in _side_cells(m, side, rotation)}
        if not band:
            traces.append(Trace(f"required_access.{side}", "fail",
                                "contract requires this side but clearance is zero there"))
            return False, 0.0, traces, exceptions
        blocked = [c for c in band
                   if not plan.walkable(*c) or c in occ.physical]
        open_cells = len(band) - len(blocked)
        # ENOUGH ACCESS, NOT ALL OF IT. This used to refuse the placement if a
        # SINGLE cell of the band was blocked, which is not what the side is
        # for: a visitor needs somewhere to stand and look from, not the whole
        # apron swept. `CoordinateSystem3M` was refused from the Uffizi's only
        # slot large enough to hold it — 3 of 5 back cells blocked, 2 open,
        # which is a person's worth of standing room — and went to the porch.
        #
        # Same over-strict shape as the slot-access rule that once invented 16
        # "unreachable" slots in this corpus. The project's own standard is what
        # a body can actually do, not a clean rectangle.
        #
        # Zero open cells is still a refusal: a side nobody can stand on is not
        # an approach. A partial band places and SAYS SO, and the crowding is
        # priced in the score below rather than hidden.
        if open_cells <= 0:
            traces.append(Trace(f"required_access.{side}", "fail",
                                f"all {len(band)} access cells blocked — "
                                f"nowhere to stand on the {side}"))
            return False, 0.0, traces, exceptions
        if blocked:
            traces.append(Trace(f"required_access.{side}", "compromised",
                                f"{open_cells} of {len(band)} access cells open "
                                f"on the {side}"))
            exceptions.append(
                f"{side} access is crowded: {open_cells} of {len(band)} cells "
                f"open (a visitor can stand, but not step around)")
            access_penalty += len(blocked) / len(band)
        else:
            traces.append(Trace(f"required_access.{side}", "pass",
                                f"{len(band)} cells reachable"))

    # Circulation: must be walkable floor, and must not eat the through-route.
    world_circ = {(c[0] + ax, c[1] + az) for c in m.circulation}
    off_floor = [c for c in world_circ if not plan.walkable(*c)]
    if off_floor:
        traces.append(Trace("circulation_on_floor", "fail",
                            f"{len(off_floor)} clearance cells fall outside the floor"))
        return False, 0.0, traces, exceptions
    # THE BODY IS TESTED FIRST, AND IT IS THE HARD ONE. This rule used to check
    # the CLEARANCE against the through-route and never the body — so a work
    # standing squarely in the corridor passed while one whose standing room
    # merely touched it was refused. doc/reports/interior_bottleneck.json found
    # a case with 4 of 20 BODY cells on the route, unexamined, refused for 6
    # clearance cells.
    #
    # A body on the route blocks the walk: nothing can pass through an object.
    # Clearance on the route does not: the through-route and a viewing apron are
    # allowed to be the same floor, because a visitor standing to look and a
    # visitor walking past are the same person a moment apart. That is a
    # compromise worth pricing, not a refusal.
    body_on_route = world_phys & plan.route
    if body_on_route:
        traces.append(Trace("route_preserved", "fail",
                            f"the body itself would stand on {len(body_on_route)} "
                            f"through-route cells and block the walk"))
        return False, 0.0, traces, exceptions
    route_eaten = world_circ & plan.route
    if route_eaten:
        traces.append(Trace("route_preserved", "compromised",
                            f"clearance shares {len(route_eaten)} cells with the "
                            f"through-route; the walk still passes"))
        exceptions.append(
            f"viewing apron overlaps the through-route by {len(route_eaten)} cells")
        access_penalty += len(route_eaten) / max(1, len(world_circ))
    else:
        traces.append(Trace("route_preserved", "pass", "through-route untouched"))

    circ_clash = world_circ & set(occ.physical)
    if circ_clash:
        traces.append(Trace("circulation_overlap", "fail",
                            f"{len(circ_clash)} clearance cells sit on another body"))
        return False, 0.0, traces, exceptions
    traces.append(Trace("circulation_overlap", "pass", "clearance is clear"))

    # Presentation: soft. Overlap costs score, never validity.
    world_pres = {(c[0] + ax, c[1] + az) for c in m.presentation}
    intruded = world_pres & (set(occ.physical) | set(occ.circulation))
    outside = {c for c in world_pres if not plan.walkable(*c)}
    if intruded or outside:
        penalty = min(PRESENTATION_PENALTY_CAP,
                      PRESENTATION_PENALTY * len(intruded)
                      + PRESENTATION_EDGE_PENALTY * len(outside))
        score -= penalty
        traces.append(Trace("presentation", "compromised",
                            f"{len(intruded)} cells taken by neighbours, "
                            f"{len(outside)} fall outside the room "
                            f"(-{penalty:.2f})"))
    else:
        traces.append(Trace("presentation", "pass", "presentation envelope intact"))

    want_venue = getattr(contract, "preferred_venue", "interior")
    if slot.venue == want_venue:
        traces.append(Trace("preferred_venue", "pass",
                            f"placed in the {slot.venue}, as asked"))
    else:
        score -= 0.15
        traces.append(Trace("preferred_venue", "compromised",
                            f"wants the {want_venue}, placed in the {slot.venue}"))
    if mode == contract.preferred_mode:
        traces.append(Trace("preferred_mode", "pass", f"placed as {mode}"))
    else:
        score -= 0.15
        traces.append(Trace("preferred_mode", "compromised",
                            f"preferred {contract.preferred_mode!r}, placed as {mode!r}"))
    if rotation != contract.rotations[0]:
        score -= 0.05

    # Crowded access is worse than clear access, so it loses to a roomier
    # slot when one exists — priced, not gated. Without this the relaxed
    # rule would treat a 1-of-5 squeeze as equal to an open apron.
    score -= access_penalty
    return True, max(0.0, score), traces, exceptions


# ── Wall domain ─────────────────────────────────────────────────────

def hang_on_wall(contract: SpatialContract, wall: WallSurface,
                 anchor: tuple[int, int]) -> tuple[list[float] | None, Trace]:
    """Place a wall-mounted work as a (u, v) rectangle on its wall.

    The feature work claims the visual centre; everything else takes what is
    left. Mounting is centred on 1.55 m — eye height for the project's 1.65 m
    standing eye, the same figure `endless_museum.gd` uses.
    """
    w_m, _, h_m = contract.body_m
    ax, az = anchor
    ox, oz = wall.origin_cell
    u_centre = float(az - oz) if wall.side in ("west", "east") else float(ax - ox)
    centre_v = 1.55
    if contract.importance == "feature":
        fz = wall.feature_zone
        u_centre = (fz[0] + fz[2]) / 2.0
        centre_v = (fz[1] + fz[3]) / 2.0
    rect = [u_centre - w_m / 2.0, max(0.0, centre_v - h_m / 2.0),
            u_centre + w_m / 2.0, max(0.0, centre_v - h_m / 2.0) + h_m]
    ok, why = wall.rect_free(rect)
    if not ok:
        # Slide along the wall once before giving up.
        for shift in (1.0, -1.0, 2.0, -2.0):
            trial = [rect[0] + shift, rect[1], rect[2] + shift, rect[3]]
            if wall.rect_free(trial)[0]:
                return trial, Trace("wall_rect_placed", "applied",
                                    f"slid {shift:+g} m along {wall.id} to clear an obstruction")
        return None, Trace("wall_rect_placed", "fail", f"{why} on {wall.id}")
    return rect, Trace("wall_rect_placed", "pass",
                       f"[{rect[0]:.2f}, {rect[1]:.2f}] to [{rect[2]:.2f}, {rect[3]:.2f}] on {wall.id}")


# ── The ladder ──────────────────────────────────────────────────────

#: A bay may open at most this many interior wall cells. Above it the "bay"
#: is a demolition — the template's rooms stop being rooms.
BAY_MAX_CELLS = 24

#: Rung 3: a broad precinct up to this size stays in the endless museum, in a
#: courtyard beside a protected bridge. Larger bodies are worlds: giving a
#: 300 m scene a 306 m joint would turn the curriculum walk into empty travel,
#: so those remain explicit dedicated-map work rather than silently scaling
#: down or monopolising the spine.
BRIDGE_COURT_MAX_M = 40.0


def requires_dedicated_map(contract: SpatialContract, plan: FloorPlan) -> bool:
    """True when rung three must hand a precinct to a world-map author.

    This is the shared seam between negotiation and the dedicated-world
    register.  The register may inventory the decision, but it may not invent
    a second size rule.  Long, thin works are deliberately excluded: they can
    turn and leave a walkable column even when their long side exceeds 40 m.
    """
    if contract.containment != "precinct" or contract.preferred_venue != "courtyard":
        return False
    import math as _m
    tile_w = plan.width - 2 * getattr(plan, "apron", 0)
    if tile_w < 6:
        return False
    body_x, body_z = float(contract.body_m[0]), float(contract.body_m[1])
    return (int(_m.ceil(min(body_x, body_z))) > tile_w - 3
            and max(body_x, body_z) > BRIDGE_COURT_MAX_M)


def _try_bay(contract: SpatialContract, plan: FloorPlan, occ: Occupancy,
             ladder: list[Trace]) -> Placement | None:
    """SPIKE 09 rung 1. For a precinct body that would fit the TILE width,
    try each interior slot on a copy of the plan whose interior wall cells
    inside the body's envelope are floor. On success the placement carries
    `bay_cells` — the exact cells opened — and the assembler applies them to
    the tile before derivation. Rules, each named in the trace:

      * the body's max side must fit inside the tile (width - 2*apron - 2:
        the exterior skin is never opened);
      * only INTERIOR wall cells open — never a cell on the tile's border,
        which is the building's skin and the neighbour's wall;
      * at most BAY_MAX_CELLS open, else it is a demolition, not a bay;
      * try_place's own route test still bites — a bay opens walls, it does
        not put a body on the walk.
    Returns None (with a trace saying why) when no bay works.
    """
    import copy as _copy
    tile_w = plan.width - 2 * plan.apron
    tile_h = plan.depth - 2 * plan.apron
    body_w = max(contract.body_m[0], contract.body_m[1])
    body_d = min(contract.body_m[0], contract.body_m[1])
    import math as _m
    if _m.ceil(body_w) > tile_w - 2 or _m.ceil(body_d) > tile_h - 2:
        ladder.append(Trace("bay", "fail",
                            f"body {body_w:.1f} x {body_d:.1f} m exceeds the tile "
                            f"({tile_w} x {tile_h} cells less the skin) — no bay can hold it"))
        return None
    x0, x1 = plan.apron + 1, plan.apron + tile_w - 1     # interior x range
    z0, z1 = plan.apron + 1, plan.apron + tile_h - 1
    best: Placement | None = None
    best_open = 10 ** 6
    for slot in plan.slots:
        if slot.venue != "interior":
            continue
        for rotation in contract.rotations:
            m = masks(contract, rotation, "freestanding")
            for origin in candidate_origins(slot, m, plan):
                ax, az = origin
                body = {(c[0] + ax, c[1] + az) for c in m.physical}
                circ = {(c[0] + ax, c[1] + az) for c in m.circulation}
                # the BODY may not touch the skin; clearance may — a visitor's
                # standing room against an exterior wall is every gallery's
                # normal condition. Circulation cells that fall on wall stay
                # wall and are judged by try_place's own access/circulation
                # rules (compromised, or refused, with a voice).
                if any(plan.in_bounds(*c) and plan.grid[c[1]][c[0]] == "4"
                       and not (x0 <= c[0] < x1 and z0 <= c[1] < z1) for c in body):
                    continue
                to_open = [c for c in (body | circ)
                           if plan.in_bounds(*c) and plan.grid[c[1]][c[0]] == "4"
                           and x0 <= c[0] < x1 and z0 <= c[1] < z1]
                if not to_open or len(to_open) > BAY_MAX_CELLS:
                    continue
                trial = _copy.copy(plan)
                trial.grid = [row[:] for row in plan.grid]
                for (cx, cz) in to_open:
                    trial.grid[cz][cx] = "1"
                ok, score, traces, exc = try_place(
                    contract, slot, trial, occ, rotation, "freestanding", origin)
                if ok and len(to_open) < best_open:
                    best_open = len(to_open)
                    best = Placement(
                        artifact=contract.lookup, slot=slot.id, anchor=origin,
                        rotation=rotation, mode="freestanding",
                        wall=None, wall_rect=None, venue="interior",
                        support_height_m=slot.surface_height_m,
                        score=score * 0.9,   # a bay costs the template something
                        result="ACCEPT",
                        traces=ladder + [Trace(
                            "bay", "applied",
                            f"opened {len(to_open)} interior wall cell(s) around "
                            f"slot {slot.id} for a {body_w:.1f} x {body_d:.1f} m body")]
                        + traces,
                        exceptions=list(exc) + [
                            f"a bay: {len(to_open)} interior wall cells became floor"],
                        masks=m, contract=contract,
                        bay_cells=sorted(to_open))
    if best is None:
        ladder.append(Trace("bay", "fail",
                            f"no interior slot admits a {body_w:.1f} x {body_d:.1f} m "
                            f"body even with up to {BAY_MAX_CELLS} interior wall cells opened"))
    return best


def negotiate(contract: SpatialContract, plan: FloorPlan, occ: Occupancy,
              preferred_slot: Slot | None = None) -> Placement:
    """Walk the escalation ladder for one artifact. Returns a Placement whose
    traces explain every step, whether it ends in ACCEPT or REJECT."""
    ladder: list[Trace] = []
    tried: list[tuple[float, Slot, int, str, list[Trace], list[str]]] = []

    # SPIKE 09 — a genuinely UNMEASURED body must not negotiate: (0,0,0)
    # would pass every "too big" test and then fail "no venue is large
    # enough" because no venue has size zero. Written believing four GPU
    # artifacts hit this; they do not (the contract resolves them at 90-300 m
    # from a better source than artifact_sizes.json — they are WORLDS, and
    # the spike record retracts F3). The guard stays: it costs nothing and
    # names the case honestly the day a zero body arrives.
    if max(contract.body_m) <= 0.0:
        ladder.append(Trace(
            "measurement", "fail",
            "unmeasured: body (0, 0, 0) — this artifact needs the size probe "
            "(tools/audit_spine_bodies.py), not a room; nothing was negotiated"))
        return Placement(
            artifact=contract.lookup, slot="-", anchor=(0, 0), rotation=0,
            mode="freestanding", wall=None, wall_rect=None, venue="unmeasured",
            support_height_m=0.0, score=0.0, result="REJECT",
            traces=ladder, exceptions=[], masks=None, contract=contract)

    # Match first, search second. The table says which slots were made for a
    # body this size; only when none of them work does this become a search.
    if contract.containment == "precinct":
        # Route straight past the slots. A precinct body cannot stand in one,
        # and walking the ladder only to reject at step 7 spends the search and
        # reports a fault where there is a category.
        ladder.append(Trace(
            "containment", "pass",
            f"precinct work ({contract.body_m[0]:.1f} x {contract.body_m[2]:.1f} m) "
            f"— the building was never going to contain it; going straight to "
            f"open ground"))
        # THE COURTYARD RUNG, before the exterior scatter. Palle's ruling
        # (spike 08): precinct bodies get courtyards between segments, or hang
        # above a balcony. The contract derives which; the grounds below remain
        # the fallback for anything hand-routed away from both. The court is
        # UNROOFED, so the 4.0 m certified-wall height that made half these
        # bodies precinct simply does not apply inside it.
        if contract.preferred_venue in ("courtyard", "balcony"):
            import math as _m
            court = [int(_m.ceil(contract.body_m[0])) + 6,
                     int(_m.ceil(contract.body_m[1])) + 6]
            # THE COURT MUST BE CROSSABLE, and the autopilot proved it is not
            # automatic: dome's 26 m body, clamped into a 15-cell corridor,
            # spanned every walkable column — the seal takes 5x5 so the cells
            # LOOKED walkable, the collision said no, and the walker unlearned
            # 26 cells and stalled at z=133. A granted court the corridor
            # cannot honour is worse than a refusal, because it walls the
            # whole museum behind it. The corridor's tile width is
            # plan.width - 2*apron; the walker needs one free column beside a
            # centred body, so the widest crossable body is tile_w - 3.
            tile_w = plan.width - 2 * getattr(plan, "apron", 0)
            # The crossability rule is COURTYARD-only. A balcony body HANGS —
            # its floor claim is zero, the walker keeps the side gallery, and
            # refusing a wide float for severing a floor it never touches is
            # how weather_vector_field (12.4 m of hanging vectors) ended up
            # refused from the one venue built for it.
            # SPIKE 09 RUNG 2 - the court is a RECTANGLE the body can be
            # TURNED in. This rule read body_m[0] alone, at rotation 0, and
            # refused an 18 x 6 m body for its 18 when it is 6 m across turned
            # 90 deg. 63 mid-size bodies escalated on exactly this. Now: the
            # narrower side must cross; if only the turned orientation does,
            # the court is granted turned and its dims swap to match - the
            # assembler stamps the row's rotation, so plan and building agree.
            body_x, body_z = float(contract.body_m[0]), float(contract.body_m[1])
            court_rot = contract.rotations[0]
            if contract.preferred_venue == "courtyard" and tile_w >= 6                     and int(_m.ceil(body_x)) > tile_w - 3                     and int(_m.ceil(body_z)) <= tile_w - 3:
                court_rot = (contract.rotations[0] + 90) % 360
                court = [court[1], court[0]]
                ladder.append(Trace(
                    "escalation", "compromised",
                    f"courtyard granted TURNED: {body_x:.1f} m across would "
                    f"sever a {tile_w}-cell corridor, {body_z:.1f} m across "
                    f"leaves a walkable column"))
            court_access: str | None = None
            if (contract.preferred_venue == "courtyard" and tile_w >= 6
                    and int(_m.ceil(min(body_x, body_z))) > tile_w - 3):
                if requires_dedicated_map(contract, plan):
                    ladder.append(Trace(
                        "escalation", "fail",
                        f"courtyard refused: {body_x:.1f} x {body_z:.1f} m body - "
                        f"even its narrow side leaves no walkable column in a "
                        f"{tile_w}-cell corridor (widest crossable is {tile_w - 3}); "
                        f"over {BRIDGE_COURT_MAX_M:.0f} m is a WORLD, not a bridge "
                        f"court - dedicated map required (Palle's rung 3 ruling)"))
                    court = []
                else:
                    court_access = "bridge"
                    ladder.append(Trace(
                        "escalation", "compromised",
                        f"bridge courtyard granted: {body_x:.1f} x {body_z:.1f} m "
                        f"would sever the {tile_w}-cell spine even turned, so its "
                        f"3 m apron expands beside a protected through-bridge"))
            if court:
                ladder.append(Trace(
                    "escalation", "pass",
                    f"precinct: a {court[0]} x {court[1]} cell "
                    f"{('bridge ' if court_access else '')}{contract.preferred_venue} made to measure "
                    f"(body + 3 m apron each side; no roof, so height is free)"))
                return Placement(
                    artifact=contract.lookup, slot=contract.preferred_venue,
                    anchor=(0, 0), rotation=court_rot,
                    mode="freestanding", wall=None, wall_rect=None,
                    venue=contract.preferred_venue,
                    support_height_m=0.0, score=1.0, result="ACCEPT",
                    traces=ladder,
                    exceptions=["a precinct work: given a court of its own"],
                    # COURT-LOCAL masks, (0,0) at the body centre. The court has
                    # no cell in the building's plan grid, but an ACCEPT without
                    # masks is a silent decision — the suite rightly refuses it,
                    # and the assembler seals from the same envelope.
                    masks=masks(contract, court_rot, "freestanding"),
                    contract=contract, court_m=court,
                    court_access=court_access)
        # ── SPIKE 09 RUNG 1: THE BAY. A precinct body that would fit the tile
        # WIDTH but not any room in it is not homeless — the tile can open a
        # bay: interior wall cells inside the body's envelope become floor.
        # This is a NEGOTIATOR OUTPUT (bay_cells on the placement, written to
        # the plan row) that the assembler applies to the tile BEFORE anything
        # derives, exactly as _widen_doors does — the plan stays the one
        # author. Tried before the exterior scatter because a body inside the
        # building is a body the curriculum walks past; the grounds are exile.
        bay = _try_bay(contract, plan, occ, ladder)
        if bay is not None:
            return bay
        for slot in plan.slots:
            if slot.venue == "interior":
                continue
            m = masks(contract, contract.rotations[0], "freestanding")
            for origin in candidate_origins(slot, m, plan):
                ok, score, traces, exc = try_place(
                    contract, slot, plan, occ, contract.rotations[0],
                    "freestanding", origin)
                if ok:
                    ladder.append(Trace("escalation", "pass",
                                        f"precinct: standing in the {slot.venue}"))
                    return Placement(
                        artifact=contract.lookup, slot=slot.id, anchor=origin,
                        rotation=contract.rotations[0], mode="freestanding",
                        wall=None, wall_rect=None, venue=slot.venue,
                        support_height_m=slot.surface_height_m,
                        score=score, result="ACCEPT",
                        traces=ladder + traces,
                        exceptions=list(exc) + [
                            "a precinct work: given ground rather than a slot"],
                        masks=m, contract=contract)
        ladder.append(Trace("escalation", "fail",
                            "precinct: no exterior venue is large enough either"))
        return Placement(
            artifact=contract.lookup, slot="-", anchor=(0, 0), rotation=0,
            mode="freestanding", wall=None, wall_rect=None, venue="outside",
            support_height_m=0.0, score=0.0, result="REJECT",
            traces=ladder, exceptions=[], masks=None, contract=contract)

    ranked = rank_slots(contract, plan)
    tier_of = {s.id: tier for s, tier in ranked}
    slots = [s for s, _ in ranked]
    if preferred_slot is not None:
        slots = [preferred_slot] + [s for s in slots if s.id != preferred_slot.id]
        tier_of.setdefault(preferred_slot.id, "preferred")
    n_matched = sum(1 for _, t in ranked if t == "matched")
    ladder.append(Trace(
        "match", "pass" if n_matched else "compromised",
        f"{n_matched} of {len(ranked)} slots declare capacity for a "
        f"{contract.footprint_cells[0]}x{contract.footprint_cells[1]} body"
        + ("" if n_matched else " — no interior slot was made for this")))

    modes = [contract.preferred_mode] + [m for m in contract.modes
                                         if m != contract.preferred_mode]
    rotations = list(contract.rotations) or [0]

    for step, slot in enumerate(slots):
        for mode in modes:
            for rot in rotations:
                m = masks(contract, rot, mode)
                best: tuple[float, tuple[int, int], list[Trace], list[str]] | None = None
                for origin in candidate_origins(slot, m, plan):
                    ok, score, traces, exc = try_place(
                        contract, slot, plan, occ, rot, mode, origin)
                    if ok and (best is None or score > best[0]):
                        best = (score, origin, traces, exc)
                        if score >= 1.0:
                            break
                    if not ok:
                        tried.append((score, slot, rot, mode, traces, exc))
                if best is not None:
                    score, origin, traces, exc = best
                    nominal = origin_for(slot, m)
                    tier = tier_of.get(slot.id, "searched")
                    if tier == "preferred_venue":
                        ladder.append(Trace(
                            "escalation", "pass",
                            f"venue: the contract asks for the {slot.venue}, "
                            f"and it was available"))
                    elif tier == "exterior":
                        exc = list(exc) + [
                            f"hosted in the {slot.venue} because no interior slot "
                            f"can hold a {contract.footprint_cells[0]}x"
                            f"{contract.footprint_cells[1]} body"]
                        ladder.append(Trace(
                            "escalation", "applied",
                            f"exterior: no room inside, placed in the {slot.venue}"))
                    elif step == 0 and mode == modes[0] and rot == rotations[0] \
                            and origin == nominal:
                        ladder.append(Trace("escalation", "pass",
                                            f"step 1: {tier} slot accepted as offered"))
                    else:
                        moved = ("" if origin == nominal else
                                 f", slid {abs(origin[0] - nominal[0]) + abs(origin[1] - nominal[1])} "
                                 f"cells inside the slot zone")
                        ladder.append(Trace("escalation", "applied",
                                            f"step {min(step + 1, 5)} ({tier}): "
                                            f"slot {slot.id}, mode {mode!r}, "
                                            f"rotation {rot}{moved}"))
                    return Placement(
                        artifact=contract.lookup, slot=slot.id, anchor=origin,
                        rotation=rot, mode=mode,
                        wall=slot.wall_side if mode == "against_wall" else None,
                        wall_rect=None, venue=slot.venue,
                        support_height_m=slot.surface_height_m,
                        score=score, result="ACCEPT",
                        traces=ladder + traces, exceptions=exc,
                        masks=m, contract=contract)

    # Step 6: expand the room, then retry. Late, sized to the shortfall, and
    # recorded — never a silent nudge until something happens to fit.
    if plan.expandable and len(plan.expansions) < MAX_EXPANSIONS:
        # Grow in whichever dimension actually blocked it, not reflexively wide.
        too_tall = any(t.rule == "body_fits_under_ceiling" and t.status == "fail"
                       for _, _, _, _, ts, _ in tried for t in ts)
        if too_tall and contract.body_m[2] > plan.wall_height_m:
            new_h = float(int(contract.body_m[2] + 0.999))
            ladder.append(Trace("escalation", "applied",
                                f"step 6: nothing could host it because the body is "
                                f"{contract.body_m[2]:.2f} m tall; the room's walls "
                                f"rise from {plan.wall_height_m:g} m to {new_h:g} m"))
            plan.raise_ceiling(new_h)
        else:
            need = max(contract.footprint_cells) + contract.clearance.get("left", 0) \
                + contract.clearance.get("right", 0)
            widest = max((_pocket_width(plan, s) for s in plan.slots), default=0)
            extra = max(2, need - widest + 1)
            ladder.append(Trace("escalation", "applied",
                                f"step 6: no slot could host it; the widest pocket is "
                                f"{widest} cells and the contract needs {need}, so the "
                                f"room grows by {extra} on each side"))
            plan.widen(extra)
        result = negotiate(contract, plan, occ, preferred_slot)
        result.traces = ladder + result.traces
        return result

    if not plan.expandable:
        ladder.append(Trace(
            "escalation", "compromised",
            "step 6 skipped: this museum is authored, so its proportions are not "
            "the negotiator's to change — an exterior venue was tried instead"))

    # Step 7: fail explicitly, quoting the closest attempt.
    best = max(tried, key=lambda t: t[0]) if tried else None
    ladder.append(Trace("escalation", "fail",
                        "step 7: no slot, rotation, mode or expansion satisfies the contract"))
    failing = [t for t in (best[4] if best else []) if t.status == "fail"]
    return Placement(
        artifact=contract.lookup, slot=(best[1].id if best else "-"),
        anchor=(best[1].cell if best else (0, 0)), rotation=0,
        mode=contract.preferred_mode, wall=None, wall_rect=None,
        venue=(best[1].venue if best else "interior"),
        support_height_m=(best[1].surface_height_m if best else 0.0), score=0.0,
        result="REJECT", traces=ladder + failing,
        exceptions=[], masks=None, contract=contract)


def run(artifacts: list[str], plan: FloorPlan | None = None,
        bays: int = 3) -> tuple[FloorPlan, list[Placement], Occupancy]:
    """Negotiate a whole exhibition brief in order."""
    plan = plan or build_enfilade(bays=max(bays, len(artifacts)))
    occ = Occupancy()
    out: list[Placement] = []
    bay_cursor = 0
    for lookup in artifacts:
        contract = staged_contract(lookup)
        # The brief's order picks the bay; the negotiator picks the slot.
        bay = f"bay{bay_cursor % max(1, len({s.bay for s in plan.slots}))}"
        preferred = next((s for s in plan.slots
                          if s.bay == bay and _slot_suits(contract, s)), None)
        p = negotiate(contract, plan, occ, preferred)
        if p.result == "ACCEPT" and p.masks:
            occ.commit(lookup, p.masks, p.anchor)
            if p.mode == "against_wall" and p.wall:
                wall = next((w for w in plan.walls
                             if w.side == p.wall and w.bay == _bay_of(plan, p.slot)), None)
                if wall is not None and contract.body_m[1] <= 0.7:
                    rect, trace = hang_on_wall(contract, wall, p.anchor)
                    p.traces.append(trace)
                    if rect:
                        p.wall_rect = rect
                        wall.occupied.append({"token": lookup, "rect": rect,
                                              "role": contract.importance})
        out.append(p)
        bay_cursor += 1
    return plan, out, occ


# ── lineages go on walls ────────────────────────────────────────────

#: The declared feature field, from tools/wall_bands.py — one reader for every
#: band in the project, so a prop tool and a lineage tool cannot disagree about
#: where eye height is.
def _feature_band() -> tuple[list[float], list[float]]:
    from wall_bands import feature_field
    return feature_field()


@dataclass
class RunPlacement:
    """A DNA run hung as a row of works along one wall."""
    anchor: str
    axis: str
    values: list[str]
    wall: str | None
    rects: list[list[float]]                  # (u0, v0, u1, v1) per value
    world: list[list[float]]                  # world (x, y, z) per value
    result: str
    traces: list[Trace]

    def as_dict(self) -> dict[str, Any]:
        return {
            "anchor": self.anchor, "axis": self.axis, "values": self.values,
            "wall": self.wall, "rects_uv": self.rects, "world": self.world,
            "result": self.result,
            "rules": [t.as_dict() for t in self.traces],
        }


#: Breathing space between two works in a row, metres. Below this a lineage
#: reads as one wide object rather than as a series of related ones.
RUN_GAP_M = 0.4


def _front_is_clear(plan: FloorPlan, wall: WallSurface, u0: float, u1: float,
                    occ: Occupancy, depth: int = 2) -> bool:
    """Is there floor to stand on in front of this stretch of wall?

    A work nobody can stand in front of is not hung, it is stored. This is the
    floor/wall join: the wall owns the rectangle, the floor owns the standing
    room, and both have to agree before the claim is real.
    """
    ox, oz = wall.origin_cell
    nx, nz = wall.normal
    for step in range(1, depth + 1):
        for u in range(int(u0), max(int(u0) + 1, int(u1))):
            cell = ((ox + nx * step, oz + u) if nx else (ox + u, oz + nz * step))
            if not plan.walkable(*cell) or cell in occ.physical:
                return False
    return True


def hang_run(plan: FloorPlan, anchor: str, axis: str, values: list[str],
             occ: Occupancy, contract: SpatialContract | None = None) -> RunPlacement:
    """Route a DNA run to a WALL, not to a floor series.

    Measured across the corpus: 481 artifacts declare a run, the floor offers
    36 slot series and 18 of 30 museums offer none — while the same museums
    carry 345 wall runs of 4 m or more. Treating a lineage as a floor problem
    is what made most of them unplaceable. One value per metre of wall, in the
    declared feature band, is what `em_sets` already calls `sibling -> row`.
    """
    traces: list[Trace] = []
    n = len(values)
    h_pct, v_m = _feature_band()

    # The work's REAL width, not one metre per value. A framed diagram and a
    # 3 m screen do not claim the same wall, and pitching everything at 1 m
    # either wastes the wall or overlaps the works.
    contract = contract or staged_contract(anchor)
    if contract.containment == "precinct":
        # Not a failure. A cave is not a picture, and asking which wall holds
        # it is the wrong question — it wants ground, and a threshold.
        traces.append(Trace("containment", "pass",
                            f"precinct work ({contract.body_m[0]:.1f} x "
                            f"{contract.body_m[2]:.1f} m) — not hung; it wants "
                            f"ground of its own and a threshold into it"))
        return RunPlacement(anchor, axis, values, None, [], [], "PRECINCT", traces)
    body_w = max(0.15, float(contract.body_m[0]))
    body_h = max(0.10, float(contract.body_m[2]))
    band_h = float(v_m[1]) - float(v_m[0])
    need = n * body_w + max(0, n - 1) * RUN_GAP_M
    traces.append(Trace("run_measure", "pass",
                        f"{n} works of {body_w:.2f} m at {RUN_GAP_M:g} m spacing "
                        f"= {need:.2f} m of wall"))

    # Vertical: centre the body on the feature band; a work taller than the
    # band may use the wall above it, but not the wall it does not have.
    v_centre = (float(v_m[0]) + float(v_m[1])) / 2.0
    v_lo = v_centre - body_h / 2.0
    v_hi = v_centre + body_h / 2.0
    if body_h > band_h:
        traces.append(Trace("feature_band", "compromised",
                            f"body is {body_h:.2f} m tall, the declared band is "
                            f"{band_h:.2f} m — it spills beyond the field"))
    if v_hi > plan.wall_height_m or v_lo < 0.0:
        traces.append(Trace("feature_band", "fail",
                            f"a {body_h:.2f} m work centred at {v_centre:g} m does "
                            f"not fit a {plan.wall_height_m:g} m wall"))
        return RunPlacement(anchor, axis, values, None, [], [], "REJECT", traces)

    usable: list[tuple[float, WallSurface]] = []
    for wall in plan.walls:
        taken = sum((r["rect"][2] - r["rect"][0]) for r in wall.occupied)
        free = wall.length_m - taken
        if free + 0.01 < need:
            continue
        # Check the stretch the row WILL occupy, not the first `need` metres.
        # Centring the row and then testing from u=0 only agreed by luck on the
        # tightest wall, and silently lied on any longer one.
        start = (wall.length_m - need) / 2.0
        if not _front_is_clear(plan, wall, start, start + need, occ):
            continue
        usable.append((free, wall))

    if not usable:
        traces.append(Trace("wall_available", "fail",
                            f"no wall offers {need:g} m of clear run with floor "
                            f"to stand on in front of it"))
        return RunPlacement(anchor, axis, values, None, [], [], "REJECT", traces)

    # Tightest wall that still holds the run — compactness, the last of the
    # declared priorities, used only to choose among walls that all qualify.
    # Then WORK DOWN the list: a wall can have room by the metre and still
    # refuse the row, because what is already hung on it sits in the way.
    # Taking only the first candidate turned "this wall is busy" into "this
    # lineage has no home", which is a different and much worse answer.
    usable.sort(key=lambda t: t[0])
    v0, v1 = round(v_lo, 3), round(v_hi, 3)
    blocked: list[str] = []

    for free, wall in usable:
        start = (wall.length_m - need) / 2.0
        rects: list[list[float]] = []
        world: list[list[float]] = []
        clash = ""
        for i, value in enumerate(values):
            u_lo = start + i * (body_w + RUN_GAP_M)
            rect = [round(u_lo, 3), v0, round(u_lo + body_w, 3), v1]
            ok, why = wall.rect_free(rect)
            if not ok:
                clash = f"{wall.id}: {why}"
                break
            rects.append(rect)
            wx, wy, wz = wall.world_of((rect[0] + rect[2]) / 2.0, (v0 + v1) / 2.0)
            world.append([round(wx, 3), round(wy, 3), round(wz, 3)])
        if clash:
            blocked.append(clash)
            continue

        for rect, value in zip(rects, values):
            wall.occupied.append({"token": f"{anchor}.{axis}={value}",
                                  "rect": rect, "role": "dna_variant"})
        traces.append(Trace("wall_available", "pass",
                            f"{wall.id} offers {free:g} m of {wall.length_m:g} m, "
                            f"run needs {need:.2f} m"))
        if blocked:
            traces.append(Trace("wall_search", "applied",
                                f"{len(blocked)} nearer wall(s) had the metres but not "
                                f"the room: {blocked[0]}"))
        traces.append(Trace("row", "pass",
                            f"{n} works of {body_w:.2f} m centred on {wall.id}, "
                            f"hung {v0:g}-{v1:g} m"))
        traces.append(Trace("floor_join", "pass",
                            "two cells of standing room in front, walkable and unclaimed"))
        return RunPlacement(anchor, axis, values, wall.id, rects, world, "ACCEPT", traces)

    traces.append(Trace("wall_available", "fail",
                        f"{len(usable)} wall(s) had {need:.2f} m free but every one "
                        f"was already hung across: {blocked[0] if blocked else ''}"))
    return RunPlacement(anchor, axis, values, None, [], [], "REJECT", traces)


# ── the threshold ───────────────────────────────────────────────────

#: Certified portal widths in the wall kit. A door the museum can actually
#: build, not an arbitrary hole.
PORTAL_WIDTHS = (2, 3, 4)
#: Where a caption hangs beside a door: a small plate at reading height.
CAPTION_W_M, CAPTION_H_M, CAPTION_V_M = 0.62, 0.42, 1.55


@dataclass
class Threshold:
    """What the museum owes a work it cannot contain.

    A precinct is not exhibited, it is ENTERED, and a building that simply has
    a large thing behind it has not exhibited anything. Three things make the
    relation real, and all three are architecture's job, not the artifact's:

        a door       somewhere to cross from inside to the work
        a sightline  the work visible from inside, through that door, so a
                     visitor knows there is something to cross toward
        a caption    a plate at the threshold that names what is out there

    Without the sightline the door is a fire exit. Without the caption the
    work is scenery.
    """
    artifact: str
    door_cell: tuple[int, int] | None
    door_side: str
    door_width_m: int
    stand_cell: tuple[int, int] | None
    sight_cells: list[tuple[int, int]]
    caption_rect: list[float] | None
    result: str
    traces: list[Trace]

    def as_dict(self) -> dict[str, Any]:
        return {
            "artifact": self.artifact,
            "door": {"cell": list(self.door_cell) if self.door_cell else None,
                     "side": self.door_side, "width_m": self.door_width_m},
            "stand_cell": list(self.stand_cell) if self.stand_cell else None,
            "sightline_cells": len(self.sight_cells),
            "caption_rect_uv": self.caption_rect,
            "result": self.result,
            "rules": [t.as_dict() for t in self.traces],
        }


def _line(a: tuple[int, int], b: tuple[int, int]) -> list[tuple[int, int]]:
    """Integer line between two cells — the visitor's line of sight."""
    (x0, z0), (x1, z1) = a, b
    dx, dz = abs(x1 - x0), abs(z1 - z0)
    sx, sz = (1 if x0 < x1 else -1), (1 if z0 < z1 else -1)
    err = dx - dz
    out = [(x0, z0)]
    while (x0, z0) != (x1, z1):
        e2 = 2 * err
        if e2 > -dz:
            err -= dz
            x0 += sx
        if e2 < dx:
            err += dx
            z0 += sz
        out.append((x0, z0))
    return out


def threshold(plan: FloorPlan, placement: Placement,
              contract: SpatialContract | None = None) -> Threshold:
    """Open a door onto a precinct work, and prove you can see it through.

    The door must be a certified portal width, its inside must be standable,
    its outside must reach the work, and the line from a standing point inside
    to the work's centre must cross the wall ONLY at the door. A door you
    cannot see the work through is not a threshold.
    """
    traces: list[Trace] = []
    contract = contract or placement.contract or staged_contract(placement.artifact)
    if contract.containment != "precinct":
        traces.append(Trace("threshold", "pass",
                            "an exhibited work needs no threshold; it is already inside"))
        return Threshold(contract.lookup, None, "", 0, None, [], None, "N/A", traces)

    target = placement.anchor
    # Every wall cell with floor on both sides is a candidate door.
    candidates: list[tuple[int, tuple[int, int], str]] = []
    for z in range(1, plan.depth - 1):
        for x in range(1, plan.width - 1):
            if plan.grid[z][x] != "4":
                continue
            for side, (dx, dz) in (("west", (-1, 0)), ("east", (1, 0)),
                                   ("north", (0, -1)), ("south", (0, 1))):
                inside = (x - dx, z - dz)
                outside = (x + dx, z + dz)
                if not (plan.walkable(*inside) and plan.walkable(*outside)):
                    continue
                d = abs(x - target[0]) + abs(z - target[1])
                candidates.append((d, (x, z), side))
    if not candidates:
        traces.append(Trace("door", "fail",
                            "no wall cell has floor on both sides — nowhere to cross"))
        return Threshold(contract.lookup, None, "", 0, None, [], None, "REJECT", traces)

    candidates.sort(key=lambda t: t[0])
    for _, cell, side in candidates[:40]:
        dx, dz = {"west": (-1, 0), "east": (1, 0),
                  "north": (0, -1), "south": (0, 1)}[side]
        stand = (cell[0] - dx * 3, cell[1] - dz * 3)
        if not plan.walkable(*stand):
            stand = (cell[0] - dx, cell[1] - dz)
        if not plan.walkable(*stand):
            continue
        line = _line(stand, target)
        blocked = [c for c in line
                   if plan.in_bounds(*c) and plan.grid[c[1]][c[0]] == "4" and c != cell]
        if blocked:
            continue

        # The widest certified portal the wall run can carry, capped by the
        # work: a 4 m door onto a 1 m object is a hole, not a threshold.
        want = max(2, min(4, int(round(contract.body_m[0] / 3.0)) + 2))
        width = max(w for w in PORTAL_WIDTHS if w <= want)
        traces.append(Trace("door", "pass",
                            f"{side} wall at {list(cell)}, certified {width} m portal"))
        traces.append(Trace("sightline", "pass",
                            f"{len(line)} cells from {list(stand)} to the work, "
                            f"crossing the wall only at the door"))
        caption = [round(width / 2.0 + 0.35, 3),
                   round(CAPTION_V_M - CAPTION_H_M / 2.0, 3),
                   round(width / 2.0 + 0.35 + CAPTION_W_M, 3),
                   round(CAPTION_V_M + CAPTION_H_M / 2.0, 3)]
        traces.append(Trace("caption", "pass",
                            f"plate beside the door at {CAPTION_V_M:g} m, "
                            f"{CAPTION_W_M:g} x {CAPTION_H_M:g} m"))
        return Threshold(contract.lookup, cell, side, width, stand, line,
                         caption, "ACCEPT", traces)

    traces.append(Trace("sightline", "fail",
                        f"{min(40, len(candidates))} doors tried; from none of them "
                        f"is the work visible without looking through a wall"))
    return Threshold(contract.lookup, None, "", 0, None, [], None, "REJECT", traces)


def _bay_of(plan: FloorPlan, slot_id: str) -> str:
    for s in plan.slots:
        if s.id == slot_id:
            return s.bay
    return ""


def _slot_suits(contract: SpatialContract, slot: Slot) -> bool:
    """A cheap preference filter — the negotiator still verifies everything."""
    if contract.preferred_mode == "against_wall":
        return slot.wall_side is not None
    if contract.required_support == "podium":
        return slot.support == "podium"
    if contract.importance == "feature":
        return slot.role == "3s"
    return slot.wall_side is None


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--artifacts", required=True, help="comma-separated lookup names")
    p.add_argument("--bays", type=int, default=3)
    args = p.parse_args()
    names = [a.strip() for a in args.artifacts.split(",") if a.strip()]
    plan, placements, _ = run(names, bays=args.bays)
    print(plan.ascii())
    print()
    print(json.dumps([p.as_dict() for p in placements], indent=2))
    return 0 if all(p.result == "ACCEPT" for p in placements) else 1


if __name__ == "__main__":
    raise SystemExit(main())
