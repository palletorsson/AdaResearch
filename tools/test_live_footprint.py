#!/usr/bin/env python3
"""The live footprint ledger, contract side. GATE: no ledger entry -> the
still measurement rules, byte-identical provenance. BITE: a walked entry
larger than the still -> the contract negotiates from the larger; a
walk_inside entry (no collider) -> the still stays (the seal takes nothing).
Uses a TEMP ledger; the live one is untouched."""
from __future__ import annotations
import json, sys, tempfile
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import spatial_contract as sc

def main() -> int:
    fails = []
    tok = "blockbuilderentity"
    sc._live_cache = None
    live_path = sc.LIVE_LEDGER
    tmp = Path(tempfile.mkdtemp()) / "em_live_footprints.json"
    sc.LIVE_LEDGER = tmp                      # point the reader at a temp ledger
    # GATE: no ledger
    sc._live_cache = None
    c0 = sc.resolve(tok)
    base = list(c0.body_m); prov0 = c0.provenance.get("body.size_m")
    if "live" in str(prov0):
        fails.append(f"no ledger, yet provenance says live: {prov0}")
    # BITE: walked entry, collider
    tmp.write_text(json.dumps({"bodies": {tok: {"live_aabb": [40.0, 3.9, 40.0], "has_collider": True, "walk_inside": False}}}), encoding="utf-8")
    sc._live_cache = None
    c1 = sc.resolve(tok)
    if not (c1.body_m[0] >= 39.9 and c1.body_m[1] >= 39.9):
        fails.append(f"walked 40x40 did not grow the contract: {c1.body_m}")
    if "live ledger" not in str(c1.provenance.get("body.size_m")):
        fails.append(f"provenance does not name the ledger: {c1.provenance.get('body.size_m')}")
    # walk_inside: unchanged
    tmp.write_text(json.dumps({"bodies": {tok: {"live_aabb": [40.0, 3.9, 40.0], "has_collider": False, "walk_inside": True}}}), encoding="utf-8")
    sc._live_cache = None
    c2 = sc.resolve(tok)
    if list(c2.body_m) != base:
        fails.append(f"walk_inside changed the contract: {c2.body_m} vs {base}")
    sc.LIVE_LEDGER = live_path; sc._live_cache = None
    print(f"  still {base} -> walked {list(c1.body_m)} -> walk_inside {list(c2.body_m)}")
    if fails:
        print("LIVE FOOTPRINT: FAIL %d" % len(fails)); [print("  - " + f) for f in fails]; return 1
    print("LIVE FOOTPRINT: PASS — no ledger = still; walked collider grows the contract; walk_inside leaves it")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
