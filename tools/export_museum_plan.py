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
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from emit_dressing_room import staged_contract
from exhibition_brief import spine_order
from spatial_floorplan import PATTERNS, from_museum
from spatial_negotiation import run

OUT = REPO / "ada_run" / "em_plan.json"
RELATIONS = REPO / "commons" / "data" / "artifact_relations.json"


APRON = 14


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
    from museum_wizard import stage_brief
    return list(stage_brief({"anchors": list(anchors), "count": len(anchors),
                             "relations": relations})["cast"])


def plan_museum(key: str, tokens: list[str]) -> dict[str, Any]:
    """Negotiate `tokens` into museum `key`. Reports what did NOT fit, too."""
    plan = from_museum(key, apron=APRON)
    _, placements, _ = run(tokens, plan=plan)

    placed: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
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
            "support_height_m": round(float(p.support_height_m), 3),
            "slot": p.slot,
            "wall": p.wall,
        })
    return {
        "artifacts": placed,
        "rejected": rejected,
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
    else:
        anchors = spine_anchors(args.limit, args.sequence)
        order = brief_cast(anchors, args.relations)
    if not order:
        print("no spine order available — nothing to place", file=sys.stderr)
        return 2
    print(f"  cast: {len(anchors)} anchor(s) -> {len(order)} bodies"
          + (f" (sequence {args.sequence})" if args.sequence else "")
          + ("  [flat prefix — the old cast]" if args.flat_cast else ""))

    museums: dict[str, Any] = {}
    for key in keys:
        try:
            museums[key] = plan_museum(key, list(order))
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
