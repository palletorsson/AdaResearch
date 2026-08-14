#!/usr/bin/env python3
"""The one spatial contract — resolve any artifact into a single spatial record.

The repo holds SIX overlapping descriptions of how much space an artifact needs
(see doc/SPATIAL_CONTRACT_AUDIT.md for the census and the disagreements). This
module does not add a seventh. It READS all of them, in a fixed precedence, and
returns one contract per artifact with per-field provenance, so every layer
downstream — floorplan, negotiator, wall system, museum assembler — argues from
the same numbers.

Following the grid_substrate_runner precedent, this operates on the substrate
that already exists: it writes nothing back to the registry or the dressing
rooms. It is a read layer.

Precedence, highest first:

    1. dressing_rooms/<x>.json -> placement_contract   hand-authored intent
    2. commons/data/museum_contract_pilot.json         hand-authored, 12 seeds
    3. registry.spatial_needs                          broad, part-manual
    4. registry.spatial_profile                        auto-derived
    5. registry.measurements                           measured truth (geometry)
    6. schema defaults

Two questions the old systems conflated, separated here:

    BODY SIZE is a measurement. Godot's AABB wins over any hand-typed number.
    INTENT   (modes, faces, directional clearance) is authorship. Hand-authored
             values win over anything derived.

Axis convention: every length triple in this module is [width, depth, height]
in metres — the convention placement_negotiator.py already uses. Registry
`measurements.aabb_size` is [w, h, d] (Godot order) and is transposed on read.

Usage:
    python tools/spatial_contract.py --artifact=bias_visualizer
    python tools/spatial_contract.py --artifact=science_screen --masks
    python tools/spatial_contract.py --conflicts          # corpus-wide report
"""
from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Any, Iterable

REPO = Path(__file__).resolve().parent.parent
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"
PILOT_PATH = REPO / "commons" / "data" / "museum_contract_pilot.json"
#: spine_hints() as CALLED by commons/testing/dump_spine_hints.gd. The doctrine
#: (doc/SPATIAL_PIPELINE.md §3) makes it "a provider into the spatial contract"
#: and §4 places it AFTER the registry defaults in the resolution order, so it
#: REFINES the measured AABB rather than being corrected by it.
SPINE_HINTS_PATH = REPO / "ada_run" / "spine_hints.json"

SIDES = ("front", "back", "left", "right")
#: Where a work wants to stand. `interior` is the museum proper; the rest are
#: the venues a building offers when a body wants sky, or belongs on a
#: threshold. A preference, not a rule — the negotiator honours it first and
#: records a compromise when it cannot, exactly as it does for placement mode.
VENUES = ("interior", "courtyard", "balcony", "bridge", "porch", "outside")

#: How the museum can hold a work at all.
#:
#:   exhibited  the building contains it. It stands on a floor slot or hangs on
#:              a wall, and a visitor stops in FRONT of it.
#:   precinct   the building cannot contain it, and was never going to. The
#:              visitor does not stand in front of a 300 m cave, they walk into
#:              it. A precinct work gets bounded ground of its own beyond the
#:              walls, and what the museum owes it is a THRESHOLD — a door, a
#:              sightline, a caption — not a plinth.
#:
#: Deliberately NOT a size word: `size_group` already says room_scale,
#: world_scale and environment, and this project's problem has never been too
#: few vocabularies. Size is the symptom; containment is the fact. 536 of 2485
#: measured artifacts (22%) exceed the widest slot or the wall height, and
#: rejecting them one at a time — as this negotiator did three times, from
#: three different directions — was mistaking a category for a failure.
CONTAINMENT = ("exhibited", "precinct")

#: What architecture can actually OFFER. `tools/spatial_floorplan.py` SLOT_RANKS
#: builds exactly two kinds of tile — floor and podium — and a wall is offered by
#: any slot that backs onto one. Three words. Every contract has to land on one.
SUPPORTS = ("floor", "podium", "wall")

#: Three vocabularies were authored into this one field and never reconciled.
#: `required_support` is resolved below as
#:     placement_contract.required_support or room.posture or spatial_needs.platform
#: and each of those three was written by a different hand:
#:
#:   placement_contract  82 rooms, hand-authored: floor/wall/table/pedestal/
#:                       platform/plinth/none
#:   room.posture        2538 rooms, machine-authored by tools/classify_postures.py,
#:                       whose POSTURES list is EIGHT words wide: floor/pedestal/
#:                       table/platform/float/pit/wall/monument
#:   spatial_needs.platform  the registry bootstrap: none/table/pedestal/sunken
#:
#: The negotiator was taught the first list and never the second, so 94% of the
#: corpus arrived speaking a language its support rule could not read. Measured
#: on the 24-chapter spine run: 198 of 1156 offered bodies (17.1%) declared a
#: support no slot in any of 30 museums could satisfy, and
#: `support_matches_contract` became the single largest refusal reason — 205 of
#: 478 rejections. Not a shortage of podium tiles. A vocabulary that was never
#: taught.
#:
#: What each word actually BUILDS is not a matter of opinion:
#: `classify_postures.build_footing()` writes the footing recipe per posture, and
#: reading it settles every case ---
#:
#:   platform  7x7 pad, raised 5x5 at 1.0 m — "a stage you step onto". The same
#:             lift as `table`, which the rule already accepted. RAISED.
#:   plinth    a hand-authored synonym of `pedestal` (prism_block). RAISED.
#:             `tools/build_uffizi_footprint_cohort.py` independently agrees:
#:             `raised_supports = {"table", "pedestal", "plinth", "platform"}`.
#:   pit       5x5 pad, raised RIM at 1.5 m, artifact DOWN at floor centre. The
#:             body stands on the FLOOR; the rim is furniture the dressing room
#:             builds, exactly like the plinth precedent below.
#:   sunken    what `PLATFORM_MAP` already maps to `pit`. Same answer.
#:   float     a plain floor pad with artifact_offset.y = 1.5. It hovers OVER
#:             floor; the lift is an offset in the room, not a tile.
#:   monument  a placeholder pad, artifact seated FLUSH AT y=0. Ground.
#:   none      NOT a demand. `tools/bootstrap_spatial_needs.py` writes
#:             `"platform": "none"` as its DEFAULT — 1773 of 2721 registry
#:             entries carry it — meaning "no hint given". `classify_postures`
#:             knows this and leaves it out of PLATFORM_MAP so it falls through
#:             to the size logic; the `or`-chain below had no such guard and
#:             took the absence of a demand as a demand for absence.
#:
#: So pit, sunken, float and monument are not architecture the museums lack.
#: They are furniture the dressing room already draws, standing on floor.
SUPPORT_ALIASES = {
    # raised surfaces — the assembler supplies the riser (see `lift_for`)
    "pedestal": "podium", "table": "podium", "podium": "podium",
    "platform": "podium", "plinth": "podium", "dais": "podium",
    "step": "podium", "high_podium": "podium",
    # the ground, whatever furniture the room stands on it
    "floor": "floor", "": "floor", "any": "floor", "none": "floor",
    "ground": "floor", "pit": "floor", "sunken": "floor", "float": "floor",
    "monument": "floor", "environment": "floor", "immersive_field": "floor",
    # a wall to back onto
    "wall": "wall", "backdrop": "wall", "wall_mounted": "wall",
    # galton_board's footing is [[4,4,4,4,4],[1,1,1,1,1],...] — the `wall`
    # recipe with floor in front. It wants the wall; the floor comes with it.
    "wall_floor": "wall",
}


def normalise_support(raw: object) -> tuple[str, str]:
    """One of `SUPPORTS`, plus a note when the authored word was not already one.

    Returns (canonical, note). The note is empty when nothing was translated, so
    a caller can record the rename in provenance without inventing an entry for
    every contract that already spoke the offered language.
    """
    word = str(raw or "").strip().lower()
    canon = SUPPORT_ALIASES.get(word)
    if canon is None:
        # An unknown word is a real defect, but refusing every slot is the worst
        # possible way to report it: that is precisely how `platform` cost the
        # corpus a tenth of its bodies while looking like a shortage of podiums.
        # Stand it on the floor and SAY the word was not understood.
        return "floor", (f"required_support={word!r} is not one of "
                         f"{sorted(set(SUPPORT_ALIASES))}; stood on the floor")
    if word == canon:
        return canon, ""
    return canon, f"required_support {word!r} resolved to {canon!r}"


#: The widest body any authored slot in the corpus can hold, and the certified
#: wall height. Beyond either, no exhibiting posture exists.
WIDEST_SLOT_M = 8.0
CERTIFIED_WALL_M = 4.0
#: THE canonical rotation convention, declared in
#: commons/artifacts/artifact_spatial_contracts.json ("Matches map token
#: convention used by interactables"): rotation 0 faces SOUTH (+z), 90 west
#: (-x), 180 north (-z), 270 east (+x). Everything here follows it; guessing a
#: different zero silently mirrors every wall placement.
ROTATION_FACING = {0: (0, 1), 90: (-1, 0), 180: (0, -1), 270: (1, 0)}
#: Degrees to add to the artifact's facing to get each of its sides. Standing
#: facing south (rotation 0), your right hand points west — so right is +90.
SIDE_TURN = {"front": 0, "right": 90, "back": 180, "left": 270}


#: The eye band, read from the module that owns it rather than copied.
#: `commons/scenes/em/em_plinths.gd` decides every lift in the museum; a second
#: copy of 1.15 in Python would be one edit away from disagreeing with the
#: building, and this pass has already paid for that mistake three times in
#: fields whose two copies were only equal by coincidence. Same technique as
#: `spatial_palette.py`, which reads its colours out of the encyclopedia.
PLINTHS_GD = REPO / "commons" / "scenes" / "em" / "em_plinths.gd"


@lru_cache(maxsize=1)
def plinth_band() -> dict[str, float]:
    """The viewing band, from its OWNERS in order.

    1. commons/data/standing_rules.json — the HAND's band, written at the
       reference wall. em_plinths.band() reads the same file at build time,
       so the two languages cannot disagree about a hand ruling.
    2. em_plinths.gd's const declarations — the code's band.
    3. The literals below — the doc's values, if both files are unreadable.
    """
    out = {"target_centre": 1.15, "min_lift": 0.25, "max_lift": 1.20}
    try:
        src = PLINTHS_GD.read_text(encoding="utf-8")
    except OSError:
        src = ""
    for key, name in (("target_centre", "TARGET_CENTRE"), ("min_lift", "MIN_LIFT"),
                      ("max_lift", "MAX_LIFT")):
        m = re.search(rf"^const {name} *:= *([0-9.]+)", src, re.M)
        if m:
            out[key] = float(m.group(1))
    rules_path = REPO / "commons" / "data" / "standing_rules.json"
    try:
        band = json.loads(rules_path.read_text(encoding="utf-8")).get("band", {})
        for key in ("target_centre", "min_lift", "max_lift"):
            if isinstance(band.get(key), (int, float)):
                out[key] = float(band[key])
    except (OSError, ValueError):
        pass                            # no hand rules — the code's band stands
    return out


def lift_for(body_h_m: float, slot_top_m: float) -> float:
    """The plinth em_plinths would build here, or 0.0 for none.

    em_plinths.gd step 8: `want = TARGET_CENTRE - h * 0.5 - top`. The riser the
    template already built is SUBTRACTED, which is the whole reason a floor slot
    can host an artifact that asks to be raised — it just needs a taller plinth.
    """
    band = plinth_band()
    want = band["target_centre"] - body_h_m * 0.5 - slot_top_m
    if want < band["min_lift"]:
        return 0.0                      # already in band; a lift would overshoot
    return min(want, band["max_lift"])


def side_dir(side: str, rotation: int = 0) -> tuple[int, int]:
    """The world direction an artifact-local side points at a given rotation."""
    return ROTATION_FACING[(int(rotation) + SIDE_TURN.get(side, 0)) % 360]
#: `spatial_needs.footprint_source` values that mean a HUMAN chose the number.
#: Everything else in the corpus — measured, measured_capped, derived,
#: estimated, computed_from_geometry, probe_artifact_elements — is a machine
#: mirror, and `measured_capped` in particular is a ceiling (sync_footprints
#: --cap=9), not a measurement. Only these two outrank a fresh AABB.
HAND_AUTHORED_FOOTPRINT = {"designed", "declared"}
#: Local compass -> local side. Dressing-room `interaction_faces` are written in
#: compass terms for an unrotated artifact, where south is the approach side.
COMPASS_TO_SIDE = {"south": "front", "north": "back", "west": "left", "east": "right"}
SIDE_ORDER = ("front", "right", "back", "left")   # clockwise, for rotation


# ── Sources ─────────────────────────────────────────────────────────

@lru_cache(maxsize=1)
def registry_index() -> dict[str, dict[str, Any]]:
    """lookup_name -> registry entry, across every registry file."""
    out: dict[str, dict[str, Any]] = {}
    for path in sorted(REGISTRY_DIR.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts")
        if isinstance(arts, dict):
            pairs: Iterable[tuple[str, Any]] = arts.items()
        elif isinstance(arts, list):
            pairs = ((str(e.get("lookup_name", "")), e) for e in arts
                     if isinstance(e, dict))
        else:
            continue
        for key, entry in pairs:
            if not isinstance(entry, dict):
                continue
            entry = dict(entry)
            entry.setdefault("_registry_file", path.name)
            out[str(entry.get("lookup_name") or key)] = entry
    return out


@lru_cache(maxsize=1)
def declared_index() -> tuple[dict[str, dict[str, Any]], dict[str, Any]]:
    """commons/artifacts/artifact_spatial_contracts.json — 14 hand-authored
    contracts plus the project's `default_contract`. This is the only store
    that already writes footprint_cells as an ORIENTED [w, d] pair rather than
    a scalar area, so it outranks anything derived."""
    path = REPO / "commons" / "artifacts" / "artifact_spatial_contracts.json"
    if not path.exists():
        return {}, {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}, {}
    return data.get("artifact_contracts", {}) or {}, data.get("default_contract", {}) or {}


@lru_cache(maxsize=1)
def spine_hints_index() -> dict[str, dict[str, Any]]:
    """lookup_name -> the artifact's own spine_hints(), as returned at runtime.

    Regenerate with:
        godot --path . --xr-mode off --no-window \
          --script res://commons/testing/dump_spine_hints.gd

    Absent file = no hints, which is the correct reading: 9 of 2653 artifacts
    implement the method, and the other 2644 are not withholding anything.
    """
    if not SPINE_HINTS_PATH.exists():
        return {}
    try:
        return json.loads(SPINE_HINTS_PATH.read_text(encoding="utf-8")).get("hints", {})
    except Exception:
        return {}


@lru_cache(maxsize=1)
def pilot_index() -> dict[str, dict[str, Any]]:
    """lookup_name -> museum_contract_pilot record (12 hand-authored seeds)."""
    if not PILOT_PATH.exists():
        return {}
    try:
        data = json.loads(PILOT_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return {str(a.get("lookup_name")): a for a in data.get("artifacts", [])
            if isinstance(a, dict)}


def room_for(lookup: str) -> dict[str, Any]:
    """The dressing room JSON for an artifact, or {} when it has none."""
    path = ROOMS_DIR / f"{lookup}.json"
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return data if isinstance(data, dict) else {}


# ── The contract ────────────────────────────────────────────────────

@dataclass
class SpatialContract:
    """One artifact's spatial needs, resolved from every available source.

    `provenance` maps a dotted field path to the source that supplied it, so a
    reviewer can always ask a number where it came from. `conflicts` records
    places where two sources disagreed materially and one had to lose.
    """
    lookup: str
    body_m: list[float]                      # [w, d, h] metres
    footprint_cells: list[int]               # [w, d] cells, 1 m grid
    modes: list[str]
    preferred_mode: str
    rotations: list[int]
    clearance: dict[str, int]                # cells, per side, artifact-local
    required_sides: list[str]
    preferred_sides: list[str]
    wall_allowed: bool
    wall_flush_m: float
    importance: str
    visual_radius: int
    preferred_context: str
    required_support: str
    #: Where the geometry sits relative to the scene's node origin, [dx, dz] in
    #: metres. Non-zero for artifacts built off-origin. The plan reasons about
    #: the BODY; a map token positions the NODE; this is the difference, and
    #: ignoring it puts the artifact somewhere the negotiator never checked.
    centre_offset_m: list[float] = field(default_factory=lambda: [0.0, 0.0])
    #: Local y of the artifact's LOWEST point, relative to its node origin. A
    #: wall mounting height is only meaningful against this: to hang a body's
    #: base at 0.73 m you offset the node by 0.73 minus this.
    base_y_m: float = 0.0
    #: The volume the artifact MOVES through, [w, d, h] metres. A measured AABB
    #: is one frozen pose: rotating_cube's body is 1x1x1 and its sweep 3x3x2.
    #: Reserving the body alone lets a spinning artifact swing into its
    #: neighbour, so the physical mask uses whichever is larger.
    sweep_m: list[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    #: full_circle | half_circle | cone | corridor | ambient — how the artifact
    #: wants to be approached (artifact_spatial_contracts.json).
    directional_profile: str = ""
    #: The rotation the author actually wrote, when a dressing room named
    #: exactly ONE. It leads `rotations` and every other facing is a recorded
    #: compromise — a single declared value is a preference, not a constraint.
    #: Two or more is an enumerated set and stays binding: an author who lists
    #: three has considered the fourth and excluded it.
    authored_rotation: int | None = None
    #: y-offset the artifact asks for via spine_hints().height — the mount the
    #: artifact knows about and the measurement cannot see.
    hint_height_m: float = 0.0
    #: primary | supporting | reflection | ambient, from spine_hints().role.
    hint_role: str = ""
    #: One of CONTAINMENT. Whether the museum can hold this at all.
    containment: str = "exhibited"
    #: One of VENUES. Which kind of place this work wants. Curatorial intent the
    #: geometry cannot supply: a negotiator can prove a body will not fit
    #: indoors, but only a person can say a piece BELONGS in the courtyard.
    preferred_venue: str = "interior"
    provenance: dict[str, str] = field(default_factory=dict)
    conflicts: list[str] = field(default_factory=list)

    def as_dict(self) -> dict[str, Any]:
        """The brief's illustrative schema, filled from resolved values."""
        return {
            "lookup_name": self.lookup,
            "body": {
                "size_m": [round(v, 3) for v in self.body_m],
                "footprint_cells": list(self.footprint_cells),
            },
            "placement": {
                "modes": list(self.modes),
                "preferred_mode": self.preferred_mode,
                "rotation": "cardinal",
                "rotations": list(self.rotations),
                "required_support": self.required_support,
            },
            "clearance": dict(self.clearance),
            "access": {
                "required_sides": list(self.required_sides),
                "preferred_sides": list(self.preferred_sides),
            },
            "wall": {
                "allowed": self.wall_allowed,
                "flush_distance": self.wall_flush_m,
            },
            "presentation": {
                "importance": self.importance,
                "visual_radius": self.visual_radius,
                "preferred_context": self.preferred_context,
                "preferred_venue": self.preferred_venue,
                "containment": self.containment,
                "hint_role": self.hint_role,
                "hint_height_m": self.hint_height_m,
            },
            "provenance": dict(self.provenance),
            "conflicts": list(self.conflicts),
        }


# ── Resolution ──────────────────────────────────────────────────────

def _num(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def resolve(lookup: str) -> SpatialContract:
    """Merge every source into one contract. Never raises for a missing
    source — an artifact with nothing but a name still gets a valid contract
    built from defaults, and says so in its provenance."""
    entry = registry_index().get(lookup, {})
    room = room_for(lookup)
    contract = room.get("placement_contract") or {}
    pilot = pilot_index().get(lookup, {})
    declared_all, _declared_default = declared_index()
    declared = declared_all.get(lookup, {})
    hints = spine_hints_index().get(lookup, {})
    needs = entry.get("spatial_needs") or {}
    profile = entry.get("spatial_profile") or {}
    measured = entry.get("measurements") or {}

    prov: dict[str, str] = {}
    conflicts: list[str] = []

    # ── body: a measurement question. Godot wins. ───────────────────
    aabb = measured.get("aabb_size")
    if isinstance(aabb, list) and len(aabb) == 3 and any(_num(v) > 0 for v in aabb):
        # Godot reports [w, h, d]; the contract speaks [w, d, h].
        body = [_num(aabb[0]), _num(aabb[2]), _num(aabb[1])]
        prov["body.size_m"] = "measurements.aabb_size"
    elif isinstance(pilot.get("body_envelope_m"), list):
        body = [_num(v) for v in pilot["body_envelope_m"]]
        prov["body.size_m"] = "museum_contract_pilot.body_envelope_m"
    elif isinstance(contract.get("hard_zone_m"), list):
        body = [_num(v) for v in contract["hard_zone_m"]]
        prov["body.size_m"] = "placement_contract.hard_zone_m (no measurement)"
    else:
        body = [1.0, 1.0, 1.0]
        prov["body.size_m"] = "default"

    # Godot reports aabb_center as [x, y, z]; the plan only cares about the
    # horizontal pair. An artifact built off-origin declares it here rather
    # than surprising the assembler later.
    ac = measured.get("aabb_center")
    if isinstance(ac, list) and len(ac) == 3:
        centre_offset = [_num(ac[0]), _num(ac[2])]
        base_y = _num(ac[1]) - body[2] / 2.0
        if abs(centre_offset[0]) >= 0.5 or abs(centre_offset[1]) >= 0.5:
            prov["body.centre_offset_m"] = "measurements.aabb_center"
    else:
        centre_offset = [0.0, 0.0]
        base_y = 0.0

    # ── footprint: measured cells, unless a HAND footprint says otherwise.
    # spatial_needs.footprint_cells is only authoritative when its own
    # footprint_source says a human set it; when it says "measured" it is a
    # derived mirror, and one that sync_footprints caps at 9 (see the audit).
    cells = measured.get("grid_cells")
    fp: list[int] | None = None
    if isinstance(cells, list) and len(cells) >= 2 and all(_num(c) > 0 for c in cells[:2]):
        fp = [max(1, int(math.ceil(_num(cells[0])))), max(1, int(math.ceil(_num(cells[1]))))]
        prov["body.footprint_cells"] = "measurements.grid_cells"
    hand_fp = needs.get("footprint_cells")
    hand_src = str(needs.get("footprint_source", ""))
    if isinstance(hand_fp, (int, float)) and hand_src in HAND_AUTHORED_FOOTPRINT:
        side = max(1, int(math.ceil(math.sqrt(_num(hand_fp)))))
        if fp and fp[0] * fp[1] > _num(hand_fp) * 1.5 + 1:
            conflicts.append(
                f"spatial_needs.footprint_cells={hand_fp:g} (source={hand_src!r}) is "
                f"smaller than the measured {fp[0]}x{fp[1]}; kept the hand value"
            )
        fp = [side, side]
        prov["body.footprint_cells"] = f"spatial_needs.footprint_cells ({hand_src})"
    elif fp and isinstance(hand_fp, (int, float)):
        # Two distinct faults, worth naming apart.
        side = max(1, int(math.ceil(math.sqrt(_num(hand_fp)))))
        if fp[0] * fp[1] > _num(hand_fp) * 1.5 + 1:
            conflicts.append(
                f"spatial_needs.footprint_cells={hand_fp:g} understates the measured "
                f"{fp[0]}x{fp[1]}={fp[0] * fp[1]} cells "
                f"(source={hand_src!r}); used the measurement"
            )
        elif max(fp) > min(fp) * 2 and max(fp) > side + 1:
            conflicts.append(
                f"spatial_needs.footprint_cells={hand_fp:g} is a scalar area and cannot "
                f"express the measured {fp[0]}x{fp[1]} shape (it would read as "
                f"{side}x{side}); used the measurement"
            )
    # artifact_spatial_contracts.json is the ONE store that already writes an
    # oriented [w, d] pair instead of a scalar area, and it is hand-authored,
    # so for its 14 artifacts it outranks the derived mirrors.
    dfp = declared.get("footprint_cells")
    if isinstance(dfp, list) and len(dfp) == 2 and all(_num(v) > 0 for v in dfp):
        pair = [max(1, int(_num(dfp[0]))), max(1, int(_num(dfp[1])))]
        if fp and (pair[0] * pair[1]) * 1.5 + 1 < fp[0] * fp[1]:
            conflicts.append(
                f"artifact_spatial_contracts footprint_cells={pair} is smaller "
                f"than the measured {fp}; kept the authored pair")
        fp = pair
        prov["body.footprint_cells"] = "artifact_spatial_contracts.footprint_cells"
    if fp is None:
        fp = [max(1, int(math.ceil(body[0]))), max(1, int(math.ceil(body[1])))]
        prov["body.footprint_cells"] = "ceil(body.size_m)"


    # ── sweep: the volume the artifact MOVES through ────────────────
    sweep = [0.0, 0.0, 0.0]
    sw = pilot.get("sweep_envelope_m") or contract.get("sweep_envelope_m")
    if isinstance(sw, list) and len(sw) == 3:
        sweep = [_num(v) for v in sw]
        prov["body.sweep_m"] = ("museum_contract_pilot.sweep_envelope_m"
                                if pilot.get("sweep_envelope_m")
                                else "placement_contract.sweep_envelope_m")
        if sweep[0] > body[0] + 0.01 or sweep[1] > body[1] + 0.01:
            fp = [max(fp[0], int(math.ceil(sweep[0]))),
                  max(fp[1], int(math.ceil(sweep[1])))]
            prov["body.footprint_cells"] = (
                prov.get("body.footprint_cells", "") + " + sweep_envelope")

    # spine_hints() REFINES the measurement — §4 puts it after the registry
    # defaults — but it does NOT outrank a dressing room a person authored.
    # The order is: hints -> auto-generated default room -> human-refined room.
    # science_screen is the case that shows the difference: it measures 4x1,
    # its scene declares 2x1, and its authored room says 3x1. The authored 3x1
    # wins, because someone staged it and that is the last word in §4.
    hint_fp = hints.get("footprint")
    room_fp = room.get("footprint")
    room_speaks_fp = isinstance(room_fp, list) and len(room_fp) >= 2
    if isinstance(hint_fp, list) and len(hint_fp) == 2 and all(
            isinstance(v, (int, float)) and v > 0 for v in hint_fp):
        pair = [max(1, int(hint_fp[0])), max(1, int(hint_fp[1]))]
        if room_speaks_fp and pair != fp:
            conflicts.append(
                f"spine_hints() declares footprint {pair}; the authored dressing "
                f"room says {fp} and wins (SPATIAL_PIPELINE.md 4)")
        elif fp and pair != fp:
            conflicts.append(
                f"spine_hints() declares footprint {pair} where the measured "
                f"body gives {fp}; the hint wins (SPATIAL_PIPELINE.md 4)")
        if not room_speaks_fp:
            fp = pair
            prov["body.footprint_cells"] = "spine_hints().footprint"
        # A hint that follows a sweep must still respect it: a moving body
        # sweeps whether or not the artifact declares a tidier claim.


    # ── modes: an authorship question. Hand-authored wins. ──────────
    modes: list[str] = []
    if contract.get("allowed_modes"):
        modes = [str(m) for m in contract["allowed_modes"]]
        prov["placement.modes"] = "placement_contract.allowed_modes"
    elif pilot.get("placements"):
        modes = [k for k, v in pilot["placements"].items()
                 if isinstance(v, dict) and v.get("allowed")]
        modes = ["against_wall" if m == "wall" else
                 "freestanding" if m == "island" else m for m in modes]
        prov["placement.modes"] = "museum_contract_pilot.placements"
    else:
        wall_backing = bool(needs.get("wall_backing"))
        dir_group = str(profile.get("dir_group", ""))
        if wall_backing or dir_group == "panel":
            modes = ["against_wall", "freestanding"]
            prov["placement.modes"] = ("spatial_needs.wall_backing" if wall_backing
                                       else "spatial_profile.dir_group=panel")
        else:
            modes = ["freestanding"]
            prov["placement.modes"] = "default (freestanding)"
    if str(needs.get("platform", "none")) not in ("none", "", "floor") and \
            "host_mounted" not in modes:
        modes.append("host_mounted")

    preferred = str(contract.get("preferred_mode") or pilot.get("preferred_posture") or "")
    preferred = {"island": "freestanding", "wall": "against_wall"}.get(preferred, preferred)
    if preferred not in modes:
        preferred = modes[0]
        prov["placement.preferred_mode"] = "first allowed mode"
    else:
        prov["placement.preferred_mode"] = (
            "placement_contract.preferred_mode" if contract.get("preferred_mode")
            else "museum_contract_pilot.preferred_posture")

    authored_rots = [int(str(r)) for r in room.get("rotations", [])]
    authored_rotation = authored_rots[0] if len(authored_rots) == 1 else None
    if authored_rotation is not None:
        # ONE declared rotation is a PREFERENCE. The escalation ladder lists
        # rotation as its second step and could never take it here: the
        # Uffizi's largest slot holds 42 cells at rotation 90 and 6 at
        # rotation 0, so a room naming only 0 sent the work to the grounds
        # past a slot that would have held it. Eleven museums were losing a
        # resident that way. The authored value still LEADS; any other is
        # recorded as a compromise rather than taken silently.
        authored_rots = [authored_rotation] + [
            r for r in (0, 90, 180, 270) if r != authored_rotation]
        prov["placement.rotations"] = "dressing room (1 declared -> preference)"
    rotations = authored_rots or \
                [int(r) for r in pilot.get("rotations", [])] or [0, 90, 180, 270]
    # A declared rotation is a preference, not a restriction: the hint says
    # which way the artifact wants to face, so it LEADS the list the negotiator
    # walks. It may not EXTEND it. science_screen's authored room allows only
    # rotation 0 and its scene asks for 180; leading with 180 would hand the
    # negotiator a facing the author had excluded, and it would look correct —
    # the artifact did ask for it — while quietly overruling the staging.
    hint_rot = hints.get("rotation_y")
    if isinstance(hint_rot, (int, float)) and int(hint_rot) >= 0:
        r = int(hint_rot) % 360
        if authored_rotation is not None and r != authored_rotation:
            # The author's single value is now a PREFERENCE, so `r` is legal —
            # but legal is not preferred. The authored facing keeps the lead and
            # the hint takes second place, ahead of the rest.
            rotations = [authored_rotation, r] + [
                x for x in rotations if x not in (authored_rotation, r)]
            conflicts.append(
                f"spine_hints() asks for rotation {r}; the author's {authored_rotation} "
                f"leads and {r} is the first fallback")
        elif r in rotations:
            rotations = [r] + [x for x in rotations if x != r]
            prov["placement.rotations"] = "spine_hints().rotation_y leads"
        else:
            conflicts.append(
                f"spine_hints() asks for rotation {r}, which the authored "
                f"rotations {rotations} exclude; the authored set wins")

    # ── clearance: directional, in cells. ───────────────────────────
    clear: dict[str, int] = {}
    needs_clear = needs.get("clearance")
    if isinstance(needs_clear, dict) and set(needs_clear) >= set(SIDES):
        for s in SIDES:
            clear[s] = max(0, int(_num(needs_clear.get(s), 1)))
        prov["clearance"] = "spatial_needs.clearance"
    else:
        base = int(_num(profile.get("min_clearance"), 1))
        clear = {s: max(0, base) for s in SIDES}
        prov["clearance"] = ("spatial_profile.min_clearance (scalar, spread to all sides)"
                             if profile.get("min_clearance") is not None else "default 1")
    # Hand-authored front/rear in metres override the per-side cells.
    if contract.get("front_clearance_m") is not None:
        clear["front"] = max(0, int(math.ceil(_num(contract["front_clearance_m"]))))
        prov["clearance.front"] = "placement_contract.front_clearance_m"
    if contract.get("rear_clearance_m") is not None:
        clear["back"] = max(0, int(math.ceil(_num(contract["rear_clearance_m"]))))
        prov["clearance.back"] = "placement_contract.rear_clearance_m"
    if isinstance(pilot.get("interaction"), dict):
        pc = pilot["interaction"].get("clearance_m")
        if isinstance(pc, dict) and "clearance" not in prov:
            for s in SIDES:
                if s in pc:
                    clear[s] = max(0, int(math.ceil(_num(pc[s]))))
            prov["clearance"] = "museum_contract_pilot.interaction.clearance_m"

    # ── access sides ────────────────────────────────────────────────
    required: list[str] = []
    if contract.get("interaction_faces"):
        required = [COMPASS_TO_SIDE.get(str(f), str(f))
                    for f in contract["interaction_faces"]]
        prov["access.required_sides"] = "placement_contract.interaction_faces"
    elif isinstance(pilot.get("interaction"), dict) and pilot["interaction"].get("required_sides"):
        required = [str(s) for s in pilot["interaction"]["required_sides"]]
        prov["access.required_sides"] = "museum_contract_pilot.interaction.required_sides"
    elif needs.get("player_position"):
        pos = str(needs["player_position"])
        required = [pos] if pos in SIDES else ["front"]
        prov["access.required_sides"] = "spatial_needs.player_position"
    else:
        required = ["front"]
        prov["access.required_sides"] = "default (front)"

    hint_approach = str(hints.get("approach", "")).strip().lower()
    if hint_approach in ("south", "front") and "placement_contract.interaction_faces" \
            not in prov.get("access.required_sides", ""):
        required = ["front"]
        prov["access.required_sides"] = "spine_hints().approach"

    circulation = str(contract.get("circulation", ""))
    if circulation == "full_orbit":
        preferred_sides = list(SIDES)
    else:
        preferred_sides = [s for s in ("front", "left", "right") if s not in required]
        preferred_sides = required + preferred_sides

    # ── wall ────────────────────────────────────────────────────────
    wall_allowed = "against_wall" in modes
    flush = _num(contract.get("rear_clearance_m"), 0.2) if wall_allowed else 0.0
    if not bool(contract.get("circulation_behind", True)) and wall_allowed:
        flush = min(flush, 0.2)

    # ── presentation ────────────────────────────────────────────────
    density = str(profile.get("density", ""))
    stack = _num(profile.get("stack_priority"), 0.5)
    if stack >= 0.8 or density == "high":
        importance = "feature"
    elif stack <= 0.2 or density == "low":
        importance = "supporting"
    else:
        importance = "related"
    if room.get("production_grade") == "principal":
        importance = "feature"
        prov["presentation.importance"] = "dressing_room.production_grade"
    else:
        prov["presentation.importance"] = ("spatial_profile.stack_priority/density"
                                           if profile else "default")

    # spine_hints().role is the artifact's own statement of what it is FOR in
    # the walk, and it comes later in the resolution order than the derived
    # stack_priority, so it lands last.
    # ...but still under an authored grade. A room marked `principal` was
    # graded by a person; the scene calling itself `ambient` does not demote it.
    hint_role = str(hints.get("role", "")).strip().lower()
    graded = "production_grade" in room
    hint_importance = {"primary": "feature", "supporting": "related",
                       "reflection": "related", "ambient": "supporting"}.get(hint_role)
    if hint_importance and not graded:
        importance = hint_importance
        prov["presentation.importance"] = "spine_hints().role"
    elif hint_importance and hint_importance != importance:
        conflicts.append(
            f"spine_hints() calls this {hint_role!r} ({hint_importance}); the "
            f"authored production_grade gives {importance} and wins")

    visual = int(_num(profile.get("range"), 0)) or max(fp)
    # A preferred zone larger than the hard zone is an explicit ask for
    # breathing room; honour it over the derived range.
    pz, hz = contract.get("preferred_zone_m"), contract.get("hard_zone_m")
    if isinstance(pz, list) and isinstance(hz, list) and len(pz) == 3 and len(hz) == 3:
        extra = max(_num(pz[0]) - _num(hz[0]), _num(pz[1]) - _num(hz[1]))
        visual = max(1, int(math.ceil(extra / 2.0)))
        prov["presentation.visual_radius"] = "placement_contract preferred-minus-hard zone"
    else:
        prov["presentation.visual_radius"] = ("spatial_profile.range" if profile.get("range")
                                              else "max(footprint)")
    visual = max(1, min(visual, 8))       # a museum bay, not a landscape

    context = str(needs.get("preferred_zone", "") or "bay")

    # ── containment: measured, hand-overridable ─────────────────────
    # Derived from the body against what the architecture can actually offer,
    # because this is a fact about geometry, not a matter of taste. A curator
    # may still overrule it: a 9 m work COULD be exhibited if someone builds it
    # a room, and a small work can be a precinct if it is meant to be entered.
    containment = "exhibited"
    widest = max(body[0], body[1])
    if widest > WIDEST_SLOT_M or body[2] > CERTIFIED_WALL_M:
        containment = "precinct"
        prov["containment"] = (
            f"measured: {widest:.1f} m across, {body[2]:.1f} m tall — beyond the "
            f"{WIDEST_SLOT_M:g} m widest slot / {CERTIFIED_WALL_M:g} m wall")
    declared_containment = contract.get("containment") or needs.get("containment")
    if declared_containment:
        want = str(declared_containment).strip().lower()
        if want in CONTAINMENT:
            if want != containment:
                conflicts.append(
                    f"containment declared {want!r} but the body measures "
                    f"{widest:.1f} x {body[2]:.1f} m, which reads as "
                    f"{containment!r}; kept the declaration")
            containment = want
            prov["containment"] = "placement_contract.containment (hand-authored)"
        else:
            conflicts.append(
                f"containment={declared_containment!r} is not one of "
                f"{list(CONTAINMENT)}; kept the measured verdict")

    # ── venue: curatorial intent first, then the precinct ruling ────
    # For an EXHIBITED work, venue stays hand-authored only: an artifact that
    # happens not to fit indoors is a fact about the building; one that WANTS
    # the courtyard is a decision about the work, and inferring one from the
    # other would put words in the curator's mouth.
    #
    # For a PRECINCT work, that reasoning inverts. The building was never going
    # to contain it, so "interior" is not a preference — it is a wish the
    # architecture cannot grant, and routing it to untyped `outside` was the
    # dumping ground spike 08 was ruled against. Palle, 2026-08-13: precinct
    # bodies get courtyards between segments, or hang in space above a balcony.
    # Derived HERE because this file already owns containment and still sees the
    # RAW posture — normalise_support erases `float` into "floor" a few lines
    # down, so no later layer can tell a floating body from a grounded one. A
    # hand-authored preferred_venue still wins, exactly as containment's
    # override does.
    venue = "interior"
    raw_venue = contract.get("preferred_venue") or needs.get("preferred_venue")
    if not raw_venue and containment == "precinct":
        floats = str(room.get("posture", "")).strip().lower() == "float"
        venue = "balcony" if floats else "courtyard"
        prov["presentation.preferred_venue"] = (
            f"derived: containment=precinct + posture "
            f"{'float -> balcony void' if floats else 'grounded -> courtyard'}"
            " (spike 08 ruling; hand-authored preferred_venue overrides)")
    if raw_venue:
        candidate_venue = str(raw_venue).strip().lower()
        if candidate_venue in VENUES:
            venue = candidate_venue
            prov["presentation.preferred_venue"] = (
                "placement_contract.preferred_venue" if contract.get("preferred_venue")
                else "spatial_needs.preferred_venue")
        else:
            conflicts.append(
                f"preferred_venue={raw_venue!r} is not one of {list(VENUES)}; "
                f"kept 'interior'")

    # ── support: three vocabularies into one offered word ───────────
    # See SUPPORT_ALIASES. The `or`-chain picks the most specific SOURCE; this
    # translates whatever it found into something a slot can actually offer, and
    # records the translation rather than performing it silently.
    if contract.get("required_support"):
        raw_support, support_src = (contract["required_support"],
                                    "placement_contract.required_support")
    elif room.get("posture"):
        raw_support, support_src = room["posture"], "room.posture"
    else:
        raw_support, support_src = (needs.get("platform", "floor") or "floor",
                                    "spatial_needs.platform")
    support, support_note = normalise_support(raw_support)
    if containment == "precinct":
        # A precinct stands on GROUND, whatever the registry says. `platform`
        # and `posture` were authored for objects the building displays — an
        # 8 m laboratory asked for a "table" and was refused open ground
        # because of it. The field is meaningless at this scale, so containment
        # overrides it rather than the negotiator quietly ignoring it.
        support, support_note = "floor", "containment=precinct overrides it"
        support_src = "containment"
    prov["placement.required_support"] = (
        f"{support_src}{': ' + support_note if support_note else ''}")
    if "not one of" in support_note:
        conflicts.append(support_note)

    return SpatialContract(
        lookup=lookup,
        body_m=body,
        footprint_cells=fp,
        modes=modes,
        preferred_mode=preferred,
        rotations=rotations or [0],
        clearance=clear,
        required_sides=required or ["front"],
        preferred_sides=preferred_sides,
        wall_allowed=wall_allowed,
        wall_flush_m=round(flush, 3),
        importance=importance,
        visual_radius=visual,
        preferred_context=context,
        required_support=support,
        authored_rotation=authored_rotation,
        centre_offset_m=centre_offset,
        base_y_m=round(base_y, 3),
        hint_height_m=(float(hints["height"])
                       if isinstance(hints.get("height"), (int, float)) else 0.0),
        hint_role=str(hints.get("role", "")),
        sweep_m=[round(v, 3) for v in sweep],
        directional_profile=str(declared.get("directional_profile", "")),
        preferred_venue=venue,
        containment=containment,
        provenance=prov,
        conflicts=conflicts,
    )


# ── The three masks ─────────────────────────────────────────────────

def rotate_side(side: str, rotation: int) -> str:
    """Rotate an artifact-local side by a cardinal rotation (degrees)."""
    if side not in SIDE_ORDER:
        return side
    steps = (int(rotation) // 90) % 4
    return SIDE_ORDER[(SIDE_ORDER.index(side) + steps) % 4]


def rotate_offset(dx: int, dz: int, rotation: int) -> tuple[int, int]:
    """Rotate a cell offset by a cardinal rotation, same handedness as masks."""
    steps = (int(rotation) // 90) % 4
    for _ in range(steps):
        dx, dz = -dz, dx
    return dx, dz


#: Kept as the internal name the mask code already uses.
_rot_cell = rotate_offset


@dataclass
class Masks:
    """The three kinds of occupied space, as sets of (dx, dz) cell offsets
    relative to the artifact's anchor cell, already rotated.

    physical      — cells the geometry occupies. Overlap is INVALID.
    circulation   — cells that must stay walkable/reachable. Overlap is INVALID.
    presentation  — cells that should ideally stay visually free. Overlap is
                    ALLOWED, with a penalty.

    They are disjoint: a cell appears in exactly one mask, the most severe.
    """
    physical: set[tuple[int, int]]
    circulation: set[tuple[int, int]]
    presentation: set[tuple[int, int]]
    exceptions: list[str] = field(default_factory=list)

    def all_cells(self) -> set[tuple[int, int]]:
        return self.physical | self.circulation | self.presentation


def masks(contract: SpatialContract, rotation: int = 0,
          mode: str | None = None) -> Masks:
    """Rasterise a contract into the three masks.

    `mode` defaults to the contract's preferred mode. In `against_wall` the
    rear clearance collapses to zero — a deliberate, recorded exception, not a
    scoring trick (the brief's section 5 requirement).
    """
    mode = mode or contract.preferred_mode
    w, d = contract.footprint_cells
    exceptions: list[str] = []

    # Physical: the footprint, CENTRED on the anchor cell — because a
    # map_data interactables token names one cell and the artifact stands on
    # it. An artifact whose mask hung off the corner would sit half a body
    # away from the cell the map says it is in.
    bx, bz = -(w // 2), -(d // 2)
    physical = {(bx + i, bz + j) for i in range(w) for j in range(d)}

    clear = dict(contract.clearance)
    if mode == "against_wall":
        if clear.get("back", 0) > 0:
            exceptions.append(
                f"rear clearance collapsed {clear['back']} -> 0 because "
                f"against_wall mode permits it")
        clear["back"] = 0
    if mode == "host_mounted":
        # The artifact stands on furniture; the host owns the floor beneath it.
        exceptions.append("clearance measured from the host surface, not the floor")

    # Circulation: directional bands outside the footprint. At rotation 0 the
    # artifact faces SOUTH (+z) per ROTATION_FACING, so front is +z, back -z,
    # left -x, right +x.
    circulation: set[tuple[int, int]] = set()
    for side in SIDES:
        n = clear.get(side, 0)
        if n <= 0:
            continue
        dx, dz = side_dir(side)          # local space: rotation applied later
        for step in range(1, n + 1):
            if dz > 0:
                for i in range(w):
                    circulation.add((bx + i, bz + d - 1 + step))
            elif dz < 0:
                for i in range(w):
                    circulation.add((bx + i, bz - step))
            elif dx > 0:
                for j in range(d):
                    circulation.add((bx + w - 1 + step, bz + j))
            else:
                for j in range(d):
                    circulation.add((bx - step, bz + j))
    circulation -= physical

    # Presentation: a ring beyond the circulation band, on the sides the
    # artifact wants seen from. Never behind an against_wall artifact.
    r = contract.visual_radius
    x0 = bx - clear.get("left", 0) - r
    x1 = bx + w + clear.get("right", 0) + r
    z0 = bz - clear.get("back", 0) - (0 if mode == "against_wall" else r)
    z1 = bz + d + clear.get("front", 0) + r
    presentation = {(dx, dz) for dx in range(x0, x1) for dz in range(z0, z1)}
    presentation -= physical | circulation

    if rotation % 360:
        physical = {_rot_cell(x, z, rotation) for x, z in physical}
        circulation = {_rot_cell(x, z, rotation) for x, z in circulation}
        presentation = {_rot_cell(x, z, rotation) for x, z in presentation}

    return Masks(physical, circulation, presentation, exceptions)


def ascii_masks(m: Masks) -> str:
    """The brief's O / c / p diagram, for a diagnostic report."""
    cells = m.all_cells()
    if not cells:
        return "(empty)"
    xs = [c[0] for c in cells]; zs = [c[1] for c in cells]
    rows = []
    for z in range(min(zs), max(zs) + 1):
        row = []
        for x in range(min(xs), max(xs) + 1):
            if (x, z) in m.physical:        row.append("O")
            elif (x, z) in m.circulation:   row.append("c")
            elif (x, z) in m.presentation:  row.append("p")
            else:                            row.append(".")
        rows.append(" ".join(row))
    return "\n".join(rows)


# ── CLI ─────────────────────────────────────────────────────────────

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--artifact", default="", help="lookup_name to resolve")
    p.add_argument("--masks", action="store_true", help="print the three masks")
    p.add_argument("--rotation", type=int, default=0)
    p.add_argument("--mode", default="")
    p.add_argument("--conflicts", action="store_true",
                   help="corpus-wide report of source disagreements")
    args = p.parse_args()

    if args.conflicts:
        total = 0
        rows: list[tuple[str, str]] = []
        for lookup in sorted(registry_index()):
            c = resolve(lookup)
            for msg in c.conflicts:
                rows.append((lookup, msg)); total += 1
        for lookup, msg in rows[:40]:
            print(f"  {lookup:34s} {msg}")
        if total > 40:
            print(f"  ... (+{total - 40} more)")
        print(f"\n{total} artifacts have sources that disagree materially.")
        return 0

    if not args.artifact:
        p.error("--artifact or --conflicts required")

    c = resolve(args.artifact)
    print(json.dumps(c.as_dict(), indent=2))
    if args.masks:
        m = masks(c, args.rotation, args.mode or None)
        print()
        print(f"masks  mode={args.mode or c.preferred_mode}  rotation={args.rotation}")
        print(ascii_masks(m))
        print(f"physical={len(m.physical)}  circulation={len(m.circulation)}  "
              f"presentation={len(m.presentation)}")
        for e in m.exceptions:
            print(f"  exception: {e}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
