#!/usr/bin/env python3
"""Negotiate one or more museum templates and write a plan the museum can deal.

The last unwired stage. `endless_museum.gd` has always dealt artifacts from a
pool into whatever slots a template offered — a good dealer, but it decides
placement itself, so nothing the negotiator concluded ever reached a walkable
room. Every 3D image in this pass came from a bench probe using the museum's
parts rather than the museum.

This writes `ada_run/em_plan.json`:

    {"schema": ..., "museums": {"<key>": {"artifacts": [
        {"token","cell":[x,z],"rotation","mode","support_height_m","venue"}
    ]}}}

`endless_museum.gd` reads it ONLY if the file exists (`--em-plan`), and a
museum key absent from the plan deals exactly as before. That is the additive
rule from CLAUDE.md: a building without the new layer must be untouched.

WHY A FILE AND NOT A REWRITE. The museum is a dealer and should stay one.
Teaching it to negotiate would put a second placement algorithm in the
assembler — the thing the doctrine names as a failure mode. It consumes
resolved cells; it does not solve.

THE CAST IS NOT A PREFIX. Until 2026-08-13 this offered `spine_order()[:limit]`
— a flat slice of the curriculum walk, each artifact arriving alone with no
argument about why it stands where it stands. `tools/museum_wizard.py` builds
its cast from `exhibition_brief`: each spine anchor brings its best TYPED
relations (`named` sightline, `sibling` row, `axis_kin` adjacency, ...), and
`dna_variant` entries are withheld from the floor because five values of one
scene are one object five times and would eat five slots. Measured on
`uffizi-spine-enfilade`, same building, same limit: the prefix placed 8 (7
interior), the brief-derived cast placed 15 (13 interior).

`--limit` still works and still means "how much of the spine to offer" — it now
counts ANCHORS, which is what `museum_wizard --count` counts, so the two tools
can be compared without arithmetic. `--flat-cast` restores the old prefix, which
is how the before/after above was measured rather than asserted.

    python tools/export_museum_plan.py --museums=uffizi_bay --limit=12
    python tools/export_museum_plan.py --all --limit=8
    python tools/export_museum_plan.py --all --limit=8 --flat-cast   # the old way
    python tools/export_museum_plan.py --all --sequence=symmetry     # one chapter
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import replace
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from emit_dressing_room import staged_contract
from exhibition_brief import spine_order
from spatial_floorplan import PATTERNS, from_museum
from spatial_negotiation import hang_run, run

OUT = REPO / "ada_run" / "em_plan.json"
RELATIONS = REPO / "commons" / "data" / "artifact_relations.json"
GRAPH = REPO / "commons" / "data" / "museum_relational_graph.json"
DNA_ENVELOPES = REPO / "commons" / "data" / "museum_dna_wall_envelopes.json"


APRON = 14


def _graph_nodes() -> dict[str, Any]:
    try:
        return json.loads(GRAPH.read_text(encoding="utf-8")).get("nodes", {})
    except (OSError, json.JSONDecodeError):
        return {}


def _graph_artifacts() -> dict[str, Any]:
    try:
        return json.loads(GRAPH.read_text(encoding="utf-8")).get("artifacts", {})
    except (OSError, json.JSONDecodeError):
        return {}


def _dna_envelopes() -> dict[str, Any]:
    """Configured Godot bodies, keyed by ``anchor|axis``.

    Absence means the family has not been preflighted and preserves the former
    spatial-contract path.  Presence plus ``complete=false`` is different: the
    preflight found a scene fault, so falling back would knowingly recreate a
    wall run the assembler cannot seat.
    """
    try:
        return json.loads(DNA_ENVELOPES.read_text(encoding="utf-8")).get(
            "families", {})
    except (OSError, json.JSONDecodeError):
        return {}


def _dna_space_demand(anchor: str, axis: str, values: list[str],
                      sizes: dict[str, list[float]], envelope: list[float],
                      why: str) -> dict[str, Any]:
    """Name the architecture a measured family asks for after a wall refusal."""
    width, depth, height = (list(envelope) + [0.0, 0.0, 0.0])[:3]
    run_width = sum(float((sizes.get(v) or [width])[0]) for v in values)
    run_width += max(0, len(values) - 1) * 0.4
    largest = max(width, depth, height, run_width)
    if largest > 12.0 or height > 6.0:
        space = "dedicated_room"
        footprint = [math.ceil(max(width + 4.0, 8.0)),
                     math.ceil(max(depth + 4.0, 8.0))]
    elif depth > 2.5 or run_width > 8.0:
        space = "courtyard"
        footprint = [math.ceil(max(run_width + 3.0, width + 4.0)),
                     math.ceil(max(depth + 4.0, 6.0))]
    else:
        space = "side_gallery"
        footprint = [math.ceil(max(run_width + 2.0, 5.0)),
                     math.ceil(max(depth + 2.5, 4.0))]
    return {
        "id": f"dna:{anchor}:{axis}", "anchor": anchor, "axis": axis,
        "values": list(values), "space": space,
        "footprint_xz": footprint,
        "envelope_wdh": [round(float(v), 3) for v in [width, depth, height]],
        "why": why, "auto_place": False,
    }


def spine_anchors(limit: int, sequence: str = "") -> list[str]:
    """The spine positions this run is about, filtered to what has a brief.

    Same rule as `museum_wizard.stage_brief`: walk `spine_artifact_order.json`
    and keep the tokens `artifact_relations.json` knows, because an anchor with
    no relations contributes exactly itself and the brief stage has nothing to
    say about it. `sequence` narrows the walk to one chapter; `limit <= 0` takes
    the whole of it.
    """
    rel = json.loads(RELATIONS.read_text(encoding="utf-8")).get("artifacts", {}) \
        if RELATIONS.exists() else {}
    out: list[str] = []
    seen: set[str] = set()
    for row in spine_order():
        if sequence and str(row.get("sequence", "")) != sequence:
            continue
        tok = str(row.get("lookup", ""))
        if tok and tok in rel and tok not in seen:
            out.append(tok)
            seen.add(tok)
        if limit > 0 and len(out) >= limit:
            break
    return out


def brief_cast(anchors: list[str], relations: int = 2) -> list[str]:
    """The cast a brief produces from those anchors — the wizard's rule, called.

    Deliberately NOT re-implemented here. `museum_wizard.stage_brief` owns the
    one decision (features and their relations go to the floor; dna_variants go
    to a wall), and two copies of that rule would drift the day somebody changes
    which kinds earn a place. The import is late because the wizard reaches back
    into this module for `plan_museum`.
    """
    return list(brief_stage(anchors, relations)["cast"])


def brief_stage(anchors: list[str], relations: int = 2) -> dict[str, Any]:
    """The shared meaning-stage result, including contextual edge metadata."""
    from museum_wizard import stage_brief
    return stage_brief({"anchors": list(anchors), "count": len(anchors),
                        "relations": relations})


def brief_context(brief: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """One contextual edge per body that actually entered this floor cast."""
    out: dict[str, dict[str, Any]] = {}
    for row in brief.get("entries", []):
        token = str(row.get("lookup", ""))
        if not token or not row.get("on_floor") or token in out:
            continue
        out[token] = {
            "anchor": str(row.get("anchor", "")),
            "role": str(row.get("role", "")),
            "kind": str(row.get("kind") or ""),
            "rule": str(row.get("rule", "")),
            "why": str(row.get("why", "")),
        }
    return out


def plan_museum(key: str, tokens: list[str],
                branch_anchors: list[str] | None = None,
                placement_context: dict[str, dict[str, Any]] | None = None,
                rooms: int | None = None, reading: bool = False,
                fixed: dict[str, tuple[int, int]] | None = None) -> dict[str, Any]:
    """Negotiate `tokens` into museum `key`. Reports what did NOT fit, too.
    `rooms` crops the tile to that many rooms (tools/em_rooms.py); the cropped
    tile is written into the row so the runtime builds exactly this hall."""
    plan = from_museum(key, apron=APRON, rooms=rooms)
    # balconies-by-ask: a plan row whose walk_space is "balcony" asks the
    # negotiator for a hanging balcony body (see spatial_negotiation.run)
    venue_asks = {t: "balcony" for t, c in (placement_context or {}).items()
                  if str((c or {}).get("walk_space", "")) == "balcony"}
    _, placements, occupancy = run(tokens, plan=plan, venue_asks=venue_asks or None, reading=reading, fixed=fixed)

    placed: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    graph_nodes = _graph_nodes()
    graph_artifacts = _graph_artifacts()
    for p in placements:
        if p.result != "ACCEPT":
            rejected.append({
                "token": p.artifact,
                # the last FAILING rule is the one that stopped it — not the
                # last trace, which is often a pass recorded after the refusal.
                "why": next((f"{t.rule}: {t.detail}" for t in reversed(p.traces)
                             if t.status == "fail"),
                            (p.traces[-1].rule if p.traces else "no trace")),
            })
            continue
        node_meta = graph_nodes.get(p.artifact) or {}
        edge_meta = (placement_context or {}).get(p.artifact) or {}
        placed.append({
            "token": p.artifact,
            "cell": [int(p.anchor[0]), int(p.anchor[1])],
            # TILE coordinates — what endless_museum.gd indexes its own tile by.
            # The apron offset is arithmetic only this side knows, so it is
            # applied HERE. Handing the museum a plan-space cell plus an apron
            # constant would put the same number in two places, which is how
            # every unit bug in this pass started.
            "tile_cell": [int(p.anchor[0]) - APRON, int(p.anchor[1]) - APRON],
            "rotation": int(p.rotation),
            "mode": p.mode,
            "venue": p.venue,
            # the book may ask for a plinth (support_m on the line): the hand's height wins
            # over the slot's surface (tools/book.py -> hero_walk -> cast_context)
            "support_height_m": round(float(edge_meta.get("support_m") or p.support_height_m), 3),
            **({"hand": True, "ruled": {"by": "book: locked", "cell": list(edge_meta["lock"])}} if edge_meta.get("lock") else {}),
            **({"config": dict(edge_meta["config"])} if edge_meta.get("config") else {}),
            "slot": p.slot,
            "wall": p.wall,
            # court dims ride the row only when the negotiator granted a court;
            # absent otherwise, so v1 rows are byte-identical.
            **({"court": list(p.court_m)} if getattr(p, "court_m", None) else {}),
            # Rung 3: a broad court can preserve the spine with a protected
            # bridge. The negotiator names that topology; the assembler only
            # renders it. Absent for every original centred court.
            **({"court_access": p.court_access}
               if getattr(p, "court_access", None) else {}),
            # SPIKE 09 rung 1: the bay the tile must open for this row, in TILE
            # coordinates (apron subtracted HERE, same law as tile_cell). Absent
            # on every row the bay rung did not touch — v1 rows byte-identical.
            **({"bay": [[int(c[0]) - APRON, int(c[1]) - APRON] for c in p.bay_cells]}
               if getattr(p, "bay_cells", None) else {}),
            **({"relational_kind": str(node_meta.get("kind", ""))}
               if node_meta.get("kind") else {}),
            **({"config": dict(node_meta.get("config") or {})}
               if node_meta.get("config") else {}),
            **({"relation": dict(edge_meta)} if edge_meta else {}),
        })
    # DNA is not another set of floor objects. Reserve a measured wall run in
    # the same occupancy model after the bodies have negotiated, so a plan can
    # say both where the lineage belongs and when the received building cannot
    # house it. Accepted rows are compact assembly instructions consumed by
    # endless_museum.gd; rejected rows stay in the file as visible demand.
    wall_runs: list[dict[str, Any]] = []
    dna_spatial_demand: list[dict[str, Any]] = []
    pending_synthesis: list[dict[str, Any]] = []
    measured_families = _dna_envelopes()
    seen_anchors: set[str] = set()
    # A related artifact may itself occur later on the canonical spine. It is a
    # guest HERE, not a second branch root: expanding it now creates branches of
    # branches and duplicates its DNA/synthesis demand in several chapters.
    # Callers that know the brief therefore pass its actual anchors.
    for token in (branch_anchors if branch_anchors is not None else tokens):
        if token in seen_anchors or token not in graph_artifacts:
            continue
        seen_anchors.add(token)
        branch = graph_artifacts[token]
        for demand in branch.get("dna_runs", []):
            values = list(demand.get("values") or [])
            if len(values) < 2:
                continue
            axis = str(demand.get("axis", ""))
            measured = measured_families.get(f"{token}|{axis}")
            contract = staged_contract(token)
            if measured is not None and not measured.get("complete"):
                invalid = list(measured.get("invalid") or [])
                missing = list(measured.get("missing") or [])
                why = ("configured geometry does not travel with its artifact root"
                       if invalid else "configured measurement is incomplete")
                wall_runs.append({
                    "anchor": token, "axis": axis, "values": values,
                    "wall": None, "wall_side": "", "wall_normal": [],
                    "rects_uv": [], "world": [],
                    "body_m": [round(float(v), 3) for v in contract.body_m],
                    "body_source": "godot_preflight_refusal",
                    "housed": False, "reserved": False, "assemble": False,
                    "why": why,
                    "contract_repair": {"invalid": invalid, "missing": missing},
                })
                continue
            if measured is not None:
                envelope = [float(v) for v in measured.get("envelope_wdh", [])]
                if len(envelope) == 3:
                    contract = replace(contract, body_m=envelope,
                                       footprint_cells=[max(1, math.ceil(envelope[0])),
                                                        max(1, math.ceil(envelope[1]))])
            result = hang_run(plan, token, axis, values, occupancy, contract)
            wall = next((w for w in plan.walls if w.id == result.wall), None)
            why = next((t.detail for t in reversed(result.traces)
                        if t.status == "fail"),
                       (result.traces[-1].detail if result.traces else ""))
            if measured is not None and result.result != "ACCEPT":
                dna_spatial_demand.append(_dna_space_demand(
                    token, axis, values,
                    dict(measured.get("values") or {}),
                    list(measured.get("envelope_wdh") or contract.body_m), why))
            wall_runs.append({
                "anchor": token,
                "axis": axis,
                "values": values,
                "wall": result.wall,
                "wall_side": wall.side if wall else "",
                "wall_normal": list(wall.normal) if wall else [],
                "rects_uv": result.rects,
                "world": result.world,
                "body_m": [round(float(v), 3) for v in contract.body_m],
                "body_source": ("godot_configured_variants"
                                if measured is not None else "spatial_contract"),
                "housed": result.result == "ACCEPT",
                "reserved": result.result == "ACCEPT",
                "assemble": result.result == "ACCEPT",
                "why": why,
            })
        for demand in branch.get("synthesis", []):
            if demand.get("type") != "measured_synthesis":
                continue
            node = graph_nodes.get(str(demand.get("to", ""))) or {}
            pending_synthesis.append({
                "anchor": token,
                "node": str(demand.get("to", "")),
                "verdict": str(demand.get("verdict", "")),
                "footprint_xz": node.get("footprint_xz", [6.0, 2.0]),
                "space": str(demand.get("space", "culmination_bay")),
                "auto_place": False,
            })

    if rooms:
        # the cropped tile travels WITH the row: endless_museum builds this, not the template
        from em_rooms import crop_tile
        _pats = json.loads((REPO / "commons" / "data" / "template_patterns.json").read_text(encoding="utf-8"))["patterns"]
        _tile = crop_tile([list(map(str, r)) for r in _pats[key]["tile"]], rooms)
        out_extra = {"rooms": int(rooms), "tile": _tile, "h": len(_tile)}
    else:
        out_extra = {}
    return {
        **out_extra,
        "artifacts": placed,
        "rejected": rejected,
        "wall_runs": wall_runs,
        "dna_spatial_demand": dna_spatial_demand,
        "pending_synthesis": pending_synthesis,
        "relational": {
            "anchors": len(seen_anchors),
            "wall_runs_requested": len(wall_runs),
            "wall_runs_housed": sum(1 for r in wall_runs if r["housed"]),
            "dna_spatial_demand": len(dna_spatial_demand),
            "dna_contract_repairs": sum(1 for r in wall_runs
                                        if r.get("contract_repair")),
            "measured_synthesis_pending": len(pending_synthesis),
        },
        "room": {"w": plan.width, "h": plan.depth},
        "apron": APRON,
        # What the museum can actually stamp today: it has no apron, so a
        # porch/outside placement has nowhere to go inside the building.
        "interior_count": sum(1 for a in placed if a["venue"] == "interior"),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--museums", default="", help="comma-separated template keys")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--limit", type=int, default=10,
                    help="spine ANCHORS offered per museum (each brings its "
                         "typed relations); <=0 means the whole spine")
    ap.add_argument("--sequence", default="",
                    help="restrict the anchors to one spine sequence")
    ap.add_argument("--relations", type=int, default=2,
                    help="how many typed relations each anchor may bring")
    ap.add_argument("--flat-cast", action="store_true",
                    help="the pre-2026-08-13 behaviour: a flat spine_order() "
                         "prefix, no relations. Kept so the improvement stays "
                         "measurable instead of remembered")
    ap.add_argument("--out", default=str(OUT))
    args = ap.parse_args()

    keys = [k.strip() for k in args.museums.split(",") if k.strip()]
    if not keys and args.all:
        pats = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
        # FILTER ON `museum`, as endless_museum.gd:548 and
        # validate_museum_templates.py already do. This was the only consumer in
        # the chain that did not, and planning all 182 keys DOUBLE-COUNTED:
        # `bay:<name>#bN` tiles PARTITION their parent's tile — altes-rotunda-hub
        # has 15 slot tokens and its two bays have 13 + 2 = the same 15. The
        # rest are `lattice:`/`beat:` floor courses, which are pattern swatches.
        #
        # Planning brushes as buildings is what produced "179 interior of 1456"
        # and sent 1031 works to a porch: from_museum() gives a fragment a plan
        # with zero slots, silently, because slot_capacity.json only covers the
        # 30 real museums.
        keys = sorted(k for k, v in pats.items() if v.get("museum"))
        skipped = len(pats) - len(keys)
        if skipped:
            print(f"  ({skipped} of {len(pats)} patterns are brushes — bay: "
                  f"sub-tiles and lattice:/beat: floor courses — not planned)")
    if not keys:
        ap.error("--museums=<key,...> or --all")

    if args.flat_cast:
        rows = [r for r in spine_order()
                if not args.sequence or r.get("sequence") == args.sequence]
        order = [r["lookup"] for r in rows]
        if args.limit > 0:
            order = order[:args.limit]
        anchors = list(order)
        context: dict[str, dict[str, Any]] = {}
    else:
        anchors = spine_anchors(args.limit, args.sequence)
        brief = brief_stage(anchors, args.relations)
        order = list(brief["cast"])
        context = brief_context(brief)
    if not order:
        print("no spine order available — nothing to place", file=sys.stderr)
        return 2
    print(f"  cast: {len(anchors)} anchor(s) -> {len(order)} bodies"
          + (f" (sequence {args.sequence})" if args.sequence else "")
          + ("  [flat prefix — the old cast]" if args.flat_cast else ""))

    museums: dict[str, Any] = {}
    for key in keys:
        try:
            museums[key] = plan_museum(key, list(order), list(anchors), context)
        except Exception as exc:                      # one bad template must not
            museums[key] = {"artifacts": [], "rejected": [],  # sink the batch
                            "error": f"{type(exc).__name__}: {exc}"}
        m = museums[key]
        print(f"  {key:34s} placed {len(m['artifacts']):2d}  "
              f"interior {m.get('interior_count', 0):2d}  "
              f"rejected {len(m['rejected']):2d}"
              + (f"  ERROR {m['error']}" if m.get("error") else ""))

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({
        "schema": "adaresearch.em_plan.v1",
        "_readme": ("Placements resolved by tools/spatial_negotiation.py. Read by "
                    "commons/scenes/endless_museum.gd under --em-plan. A museum "
                    "key absent here deals exactly as it did before."),
        "cast": {"anchors": anchors, "bodies": len(order),
                 "sequence": args.sequence,
                 "source": "flat prefix" if args.flat_cast else "exhibition brief"},
        "offered": order,
        "museums": museums,
    }, indent=2) + "\n", encoding="utf-8")
    total = sum(len(m["artifacts"]) for m in museums.values())
    inter = sum(m.get("interior_count", 0) for m in museums.values())
    print(f"\n{total} placements ({inter} interior) across {len(keys)} "
          f"museum(s) -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
