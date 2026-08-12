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

    python tools/export_museum_plan.py --museums=uffizi_bay --limit=12
    python tools/export_museum_plan.py --all --limit=8
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


APRON = 14


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
                    help="artifacts offered per museum, in spine order")
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

    order = [row["lookup"] for row in spine_order()][:args.limit]
    if not order:
        print("no spine order available — nothing to place", file=sys.stderr)
        return 2

    museums: dict[str, Any] = {}
    for key in keys:
        try:
            museums[key] = plan_museum(key, list(order))
        except Exception as exc:                      # one bad template must not
            museums[key] = {"artifacts": [], "rejected": [],  # sink the batch
                            "error": f"{type(exc).__name__}: {exc}"}
        m = museums[key]
        print(f"  {key:34s} placed {len(m['artifacts']):2d}  "
              f"rejected {len(m['rejected']):2d}"
              + (f"  ERROR {m['error']}" if m.get("error") else ""))

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({
        "schema": "adaresearch.em_plan.v1",
        "_readme": ("Placements resolved by tools/spatial_negotiation.py. Read by "
                    "commons/scenes/endless_museum.gd under --em-plan. A museum "
                    "key absent here deals exactly as it did before."),
        "offered": order,
        "museums": museums,
    }, indent=2) + "\n", encoding="utf-8")
    total = sum(len(m["artifacts"]) for m in museums.values())
    print(f"\n{total} placements across {len(keys)} museum(s) -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
