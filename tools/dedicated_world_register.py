#!/usr/bin/env python3
"""Inventory the precincts that rung three hands to dedicated maps.

The endless museum refuses a true world for a precise reason: both planar
sides sever its host corridor and its larger side exceeds the 40 m bridge-
courtyard ceiling.  This tool reads that SAME predicate from
``spatial_negotiation.requires_dedicated_map`` and turns the refusal tail into
a compact site-authoring register.

It does not choose a map formula.  Architecture owns that later decision.
It records the measured envelope, aliases that share one scene, curriculum
chapters, and the minimum body-plus-apron site that an author must honour.

Usage:
  python tools/dedicated_world_register.py
  python tools/dedicated_world_register.py --write
  python tools/dedicated_world_register.py --check
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

import spatial_contract as spatial_contracts
from emit_dressing_room import staged_contract
from export_museum_plan import APRON, brief_cast, spine_anchors
from spatial_floorplan import from_museum
from spatial_negotiation import BRIDGE_COURT_MAX_M, requires_dedicated_map
from spine_run import assign_museums, sequences

DEFAULT_OUT = REPO / "ada_run" / "dedicated_world_register.json"
SITE_APRON_M = 3


def _slug(value: str) -> str:
    text = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return text or "world"


def _site_id(scene: str, members: list[str]) -> str:
    stem = Path(scene).stem if scene.startswith("res://") else members[0]
    witness = scene or "|".join(members)
    digest = hashlib.sha1(witness.encode("utf-8")).hexdigest()[:7]
    return f"world-{_slug(stem)}-{digest}"


def build_register() -> dict[str, Any]:
    """Build a deterministic register from the contract and curriculum cast."""
    seqs = sequences()
    assigned = assign_museums([name for name, _ in seqs])
    registry = spatial_contracts.registry_index()
    found: dict[str, dict[str, Any]] = {}
    occurrence_count = 0

    for sequence, _rows in seqs:
        host = assigned[sequence]["museum"]
        plan = from_museum(host, apron=APRON)
        crossable = plan.width - 2 * plan.apron - 3
        # Relations can mention the same token twice in one stanza. A site
        # register counts one chapter demand, not how many edges named it.
        chapter_tokens = set(brief_cast(spine_anchors(0, sequence), 2))
        for token in sorted(chapter_tokens):
            contract = staged_contract(token)
            if not requires_dedicated_map(contract, plan):
                continue
            occurrence_count += 1
            body = [round(float(v), 3) for v in contract.body_m]
            row = found.setdefault(token, {
                "token": token,
                "scene": str((registry.get(token) or {}).get("scene", "")),
                "body_m": body,
                "site_envelope_m": [
                    int(math.ceil(body[0])) + SITE_APRON_M * 2,
                    int(math.ceil(body[1])) + SITE_APRON_M * 2,
                    int(math.ceil(body[2])),
                ],
                "chapters": [],
                "assigned_hosts": [],
                "host_crossable_m": [],
                "body_source": contract.provenance.get("body.size_m", ""),
            })
            row["chapters"].append(sequence)
            row["assigned_hosts"].append(host)
            row["host_crossable_m"].append(crossable)

    artifacts: list[dict[str, Any]] = []
    for token in sorted(found, key=str.lower):
        row = found[token]
        for key in ("chapters", "assigned_hosts", "host_crossable_m"):
            row[key] = sorted(set(row[key]))
        artifacts.append(row)

    grouped: dict[str, list[dict[str, Any]]] = {}
    for row in artifacts:
        # Scene identity is evidence that aliases can share one authored site.
        # Missing scene identity never causes two tokens to be merged.
        family_key = row["scene"] or f"token:{row['token']}"
        grouped.setdefault(family_key, []).append(row)

    sites: list[dict[str, Any]] = []
    for family_key, members in sorted(grouped.items(), key=lambda kv: kv[0].lower()):
        member_names = sorted((m["token"] for m in members), key=str.lower)
        envelope = [max(m["site_envelope_m"][axis] for m in members)
                    for axis in range(3)]
        sites.append({
            "site_id": _site_id(members[0]["scene"], member_names),
            "scene": members[0]["scene"],
            "members": member_names,
            "site_envelope_m": envelope,
            "chapters": sorted({c for m in members for c in m["chapters"]}),
            "assigned_hosts": sorted({h for m in members for h in m["assigned_hosts"]}),
            "status": "needs_site_authoring",
            "site_contract": {
                "grid_m": 1,
                "apron_m": SITE_APRON_M,
                "body_must_remain_full_scale": True,
                "continuous_player_route_required": True,
                "formula": None,
            },
        })

    largest = max((max(a["body_m"][:2]) for a in artifacts), default=0.0)
    return {
        "schema": "adaresearch.dedicated_world_register.v1",
        "_readme": (
            "Contract-derived handoff from negotiation to site authorship. "
            "A row here is not a museum exception and not an auto-generated map."
        ),
        "rule": {
            "containment": "precinct",
            "venue": "courtyard",
            "host_condition": "both planar sides exceed host crossable width",
            "bridge_court_max_m": BRIDGE_COURT_MAX_M,
            "site_apron_m": SITE_APRON_M,
            "owner": "spatial_negotiation.requires_dedicated_map",
        },
        "summary": {
            "chapter_occurrences": occurrence_count,
            "artifacts": len(artifacts),
            "site_families": len(sites),
            "aliases_collapsed": len(artifacts) - len(sites),
            "largest_planar_span_m": round(largest, 3),
        },
        "artifacts": artifacts,
        "sites": sites,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", default=str(DEFAULT_OUT))
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    result = build_register()
    out = Path(args.json)
    if not out.is_absolute():
        out = REPO / out
    encoded = json.dumps(result, indent=1, ensure_ascii=False) + "\n"

    if args.check:
        if not out.exists() or out.read_text(encoding="utf-8") != encoded:
            print(f"DEDICATED WORLD REGISTER: STALE — run --write ({out})")
            return 1
        print(f"DEDICATED WORLD REGISTER: PASS — {result['summary']}")
        return 0
    if args.write:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(encoded, encoding="utf-8")
        print(f"wrote {out}")
    print(json.dumps(result["summary"], separators=(",", ":")))
    for site in result["sites"]:
        print(f"  {site['site_id']}: {', '.join(site['members'])} "
              f"needs {site['site_envelope_m'][0]} x {site['site_envelope_m'][1]} m")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
