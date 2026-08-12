#!/usr/bin/env python3
"""Bootstrap a DEFAULT dressing room from resolved spatial knowledge.

`doc/SPATIAL_PIPELINE.md` §4 puts an *auto-generated default dressing room* in
the resolution order, and §5 is explicit about why:

> Use profiles and hints to bootstrap them. Do not replace dressing rooms with
> `spatial_profile`.
>
>     ATLAS/SEQUENCE -> DRESSING ROOM -> COMPOSER/NEGOTIATOR

The dressing room is the canonical staged artifact unit. `tools/spatial_contract.py`
was resolving six stores into its own dataclass and handing that straight to the
negotiator, which skipped the dressing room entirely — the right resolution
logic sitting in the wrong role. This puts it back: the contract becomes a
PROVIDER that writes dressing rooms, and the dressing room stays canonical.

`doc/DRESSING_ROOM_SCHEMA.md` already documents the fallback for an artifact
with no file: a flat `[1,1,1]` on one tile, any rotation. That is a placeholder,
not a staging decision. Every artifact here has a measured body, most have
registry defaults, nine declare `spine_hints()` — enough to derive something
truer than 1x1 without a human typing it.

TWO RULES, both from the doctrine:

  * An AUTHORED dressing room is never overwritten. §3 makes it "the strongest
    reusable static staging solution"; this only fills absences.
  * Every generated file says it was generated, from what, and when, so the
    next reader can tell a derivation from a decision.

    python tools/emit_dressing_room.py --artifact=science_screen --print
    python tools/emit_dressing_room.py --artifacts=a,b,c --write
    python tools/emit_dressing_room.py --all --write --limit=50
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import replace
from datetime import datetime
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from spatial_contract import SpatialContract, registry_index, resolve, room_for

ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"
#: The grid is 1 m (commons/grid/GridSystem.gd `cube_size`). Named because the
#: metre/cell coincidence at this scale hides unit bugs rather than preventing
#: them — two have now been found in fields whose names said which unit they were.
CELL_M = 1.0

#: Compass names the schema uses for approach/exit, by artifact-local side at
#: rotation 0 (which faces south per artifact_spatial_contracts.rotation_semantics).
SIDE_TO_COMPASS = {"front": "south", "back": "north", "left": "west", "right": "east"}
OPPOSITE = {"south": "north", "north": "south", "west": "east", "east": "west"}


def _footing(contract: SpatialContract) -> dict[str, Any]:
    """What is under it. A plinth raises, a flush floor grounds.

    Schema §Footing: tiles are a grid of heights under the footprint — 1 is
    floor, 3 a plinth. The support the contract resolved decides which.
    """
    w, d = contract.footprint_cells
    raised = contract.required_support in ("pedestal", "podium", "table")
    height = 3 if raised else 1
    return {
        "anchor": [0, 0],
        "tiles": [[height for _ in range(w)] for _ in range(d)],
    }


def build(lookup: str) -> dict[str, Any]:
    """A dressing room in the canonical schema, derived not invented."""
    c = resolve(lookup)
    entry = registry_index().get(lookup, {})
    w, d = contract_fp = c.footprint_cells
    # CEIL, matching how width and depth are derived. `round` understates —
    # a 1.42 m cabinet became 1 cell tall, and of the two directions to be
    # wrong, claiming less headroom than the body occupies is the one that
    # puts geometry through a ceiling.
    height_cells = max(1, int(math.ceil(c.body_m[2] / CELL_M - 1e-9)))

    approach = SIDE_TO_COMPASS.get(
        c.required_sides[0] if c.required_sides else "front", "south")

    room: dict[str, Any] = {
        "lookup_name": lookup,
        "footprint": [w, d, height_cells],
        "rotations": [str(r) for r in c.rotations],
        "approach": approach,
        "exit": OPPOSITE.get(approach, "north"),
        "footing": _footing(c),
        "extras": [],
        "artifact_offset": [0.0, c.hint_height_m, 0.0],
        "clearance": [
            w + c.clearance.get("left", 0) + c.clearance.get("right", 0),
            d + c.clearance.get("front", 0) + c.clearance.get("back", 0),
            height_cells + 1,
        ],
        "placement_contract": {
            "allowed_modes": list(c.modes),
            "preferred_mode": c.preferred_mode,
            "required_support": c.required_support,
            "interaction_faces": [SIDE_TO_COMPASS.get(s, s) for s in c.required_sides],
            "front_clearance_m": float(c.clearance.get("front", 0)),
            "rear_clearance_m": float(c.clearance.get("back", 0)),
            "hard_zone_m": [
                float(w + c.clearance.get("left", 0) + c.clearance.get("right", 0)),
                float(d + c.clearance.get("front", 0) + c.clearance.get("back", 0)),
                float(max(1.0, c.body_m[2])),
            ],
            "preferred_zone_m": [
                float(w + 2 * c.visual_radius),
                float(d + 2 * c.visual_radius),
                float(max(1.0, c.body_m[2])),
            ],
            "circulation": "full_orbit" if len(c.preferred_sides) >= 4 else "frontal",
            "circulation_behind": c.preferred_mode != "against_wall",
            "containment": c.containment,
            # The negotiator and the mask builder read thirteen fields between
            # them. Nine are already named in the schema; these four are not,
            # and without them a dressing room cannot be negotiated from —
            # which would mean the room is documentation and the dataclass is
            # canonical, the exact inversion this pass is undoing. Measured
            # facts, so they carry their own provenance in `_generated.from`.
            "body_m": [round(v, 3) for v in c.body_m],
            "visual_radius_m": round(c.visual_radius, 3),
            "importance": c.importance,
            "preferred_venue": c.preferred_venue,
            "centre_offset_m": [round(v, 3) for v in c.centre_offset_m],
            "base_y_m": c.base_y_m,
        },
        # Provenance, so a reader can tell a derivation from a decision. The
        # schema does not require this block; nothing downstream depends on it;
        # its absence would make a generated room indistinguishable from an
        # authored one, which is the failure this whole pass has been about.
        "_generated": {
            "by": "tools/emit_dressing_room.py",
            "at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
            "from": c.provenance,
            "conflicts": c.conflicts,
            "note": ("A DEFAULT, bootstrapped per SPATIAL_PIPELINE.md 4. "
                     "Author over it freely — remove this block when you do, "
                     "and the generator will leave the file alone."),
        },
    }
    if entry.get("name"):
        room["display_name"] = str(entry["name"])
    _ = contract_fp
    return room


COMPASS_TO_SIDE = {v: k for k, v in SIDE_TO_COMPASS.items()}


def from_room(room: dict[str, Any]) -> SpatialContract:
    """Read a dressing room back out as the contract the negotiator consumes.

    This is the direction that matters. `build()` alone would leave the
    dressing room a *report* — written, never read, while the negotiator went
    on taking the dataclass. With this, the dressing room is the thing on the
    path: authored rooms flow to the negotiator as authored, generated ones as
    generated, and no artifact reaches placement except through one.

    A room authored before this pass has no `placement_contract` — 2626 of
    2660 are in exactly that state. Those fall back to the resolver for the
    fields the schema never named, which is a fallback and is marked as one,
    not a silent equivalence.
    """
    lookup = str(room.get("lookup_name", ""))
    pc = room.get("placement_contract") or {}
    base = resolve(lookup)

    footprint = base.footprint_cells
    fp = room.get("footprint") or []
    if len(fp) >= 2:
        # `footprint` CARRIES TWO UNITS. The schema documents cells and 2626
        # rooms honour that; the 33 rooms written alongside a
        # `placement_contract` store METRES (science_screen: [3.14, 0.2, 2.35]).
        # Nothing marks which is which. Read as cells, a 3.14 m panel becomes a
        # 3-cell one and a 0.2 m depth becomes 1 cell that happens to look
        # right — wrong for a reason no test would catch. Fractional values are
        # the tell, and the sibling key corroborates it.
        metres = (any(isinstance(v, float) and abs(v - round(v)) > 1e-9 for v in fp)
                  or bool(pc))
        if metres:
            footprint = [max(1, math.ceil(float(fp[0]) - 1e-9)),
                         max(1, math.ceil(float(fp[1]) - 1e-9))]
        else:
            footprint = [max(1, int(fp[0])), max(1, int(fp[1]))]
    rotations = [int(str(r)) for r in room.get("rotations", [])] or base.rotations
    sides = [COMPASS_TO_SIDE.get(str(s), str(s))
             for s in pc.get("interaction_faces", [])] or base.required_sides

    # `*_clearance_m` is METRES; `contract.clearance` is CELLS. On a 1 m grid
    # the numbers coincide, so `float(...)` round-tripped cleanly and the slice
    # produced a byte-identical map — and then `masks()` died on
    # `range(1, 2.0)` the first time a rotation exercised the other axis. Two
    # units in one field again (cf. `footprint`), caught only because a
    # negative test moved a value that had been sitting at a whole number.
    clearance = dict(base.clearance)
    for field, side in (("front_clearance_m", "front"), ("rear_clearance_m", "back")):
        if field in pc:
            metres = float(pc[field])
            clearance[side] = max(0, int(math.ceil(metres / CELL_M - 1e-9)))

    return replace(
        base,
        footprint_cells=footprint,
        rotations=rotations,
        required_sides=sides,
        clearance=clearance,
        # JSON has no tuple and no float precision beyond what we wrote, so the
        # round trip is exact only if both sides are coerced the same way.
        modes=list(pc.get("allowed_modes", base.modes)),
        preferred_mode=str(pc.get("preferred_mode", base.preferred_mode)),
        required_support=str(pc.get("required_support", base.required_support)),
        containment=str(pc.get("containment", base.containment)),
        importance=str(pc.get("importance", base.importance)),
        preferred_venue=str(pc.get("preferred_venue", base.preferred_venue)),
        # cells, not metres — the field name says otherwise and the 1 m grid
        # makes the lie invisible until something calls range() on it.
        visual_radius=max(0, int(math.ceil(
            float(pc.get("visual_radius_m", base.visual_radius)) / CELL_M - 1e-9))),
        body_m=([float(v) for v in pc["body_m"]]
                if isinstance(pc.get("body_m"), list) and len(pc["body_m"]) == 3
                else [round(float(v), 3) for v in base.body_m]),
    )


def staged(lookup: str) -> tuple[SpatialContract, dict[str, Any]]:
    """The canonical staged unit for one artifact, and the room it came from.

    THE ENTRY POINT. Authored room if there is one, generated default if not —
    the negotiator should not be able to tell the difference, and should not
    have a path that skips the room.
    """
    room = room_for(lookup) or build(lookup)
    return from_room(room), room


def staged_contract(lookup: str) -> SpatialContract:
    """`staged()` when the caller wants the contract and not the room.

    THIS is what the pipeline calls instead of `spatial_contract.resolve()`.
    The difference is not cosmetic: `resolve()` reads six stores and answers
    from its own dataclass, while this answers from the dressing room — so an
    author who edits a room changes what the negotiator does, which is the
    whole claim of SPATIAL_PIPELINE.md §5 and was not true before.
    """
    return staged(lookup)[0]


def is_authored(lookup: str) -> bool:
    """An authored room is one a person made, or edited after generation."""
    existing = room_for(lookup)
    return bool(existing) and "_generated" not in existing


def write(lookup: str, force: bool = False) -> tuple[bool, str]:
    if is_authored(lookup) and not force:
        return False, "authored — left alone"
    path = ROOMS_DIR / f"{lookup}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(build(lookup), indent=2) + "\n", encoding="utf-8")
    return True, f"wrote {path.relative_to(REPO)}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--artifact", default="")
    ap.add_argument("--artifacts", default="")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--force", action="store_true",
                    help="overwrite even an authored room (you will be asked to mean it)")
    ap.add_argument("--print", dest="show", action="store_true")
    args = ap.parse_args()

    if args.artifact:
        names = [args.artifact]
    elif args.artifacts:
        names = [a.strip() for a in args.artifacts.split(",") if a.strip()]
    elif args.all:
        names = sorted(registry_index())
        if args.limit:
            names = names[:args.limit]
    else:
        ap.error("--artifact, --artifacts or --all required")

    if args.show:
        for n in names:
            print(json.dumps(build(n), indent=2))
        return 0

    if not args.write:
        authored = sum(1 for n in names if is_authored(n))
        print(f"{len(names)} artifact(s): {authored} authored (would be left alone), "
              f"{len(names) - authored} would be generated")
        print("pass --write to emit")
        return 0

    made = skipped = 0
    for n in names:
        ok, why = write(n, args.force)
        made += ok
        skipped += (not ok)
        if args.artifact or len(names) <= 12:
            print(f"  {n:34s} {why}")
    print(f"\ngenerated {made}, left alone {skipped}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
