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
    # ORIGIN REACH (2026-08-22): an extent that runs from the world origin out to
    # its own cell is the distance the artifact was carried, not its size. The
    # ledger holds 21 of these. They must be refused BY NAME — the aspect and
    # venue guards already caught them, but both file a real measurement question
    # for the hand, and this is a build fault with nothing to weigh.
    tmp.write_text(json.dumps({"bodies": {tok: {"live_aabb": [3.7, 3.0, 1437.9], "cell": [1, 1437],
                                                "has_collider": True, "walk_inside": False}}}), encoding="utf-8")
    sc._live_cache = None
    c3 = sc.resolve(tok)
    if list(c3.body_m) != base:
        fails.append(f"an origin-reaching extent was adopted as a size: {c3.body_m} vs {base}")
    if "REACHES THE ORIGIN" not in str(c3.provenance.get("body.live_note")):
        fails.append(f"origin reach was refused without saying so: {c3.provenance.get('body.live_note')}")
    # ...and the negative half: a body that is genuinely long and stands where it
    # was dealt keeps the old verdict. A guard that swallowed this would have made
    # the reader quieter, not more honest.
    tmp.write_text(json.dumps({"bodies": {tok: {"live_aabb": [12.0, 3.0, 14.0], "cell": [7, 1437],
                                                "has_collider": True, "walk_inside": False}}}), encoding="utf-8")
    sc._live_cache = None
    c4 = sc.resolve(tok)
    if "REACHES THE ORIGIN" in str(c4.provenance.get("body.live_note")):
        fails.append("a 12x14 m body standing at its own cell was called an origin reach")
    if not (c4.body_m[0] >= 11.9 and c4.body_m[1] >= 13.9):
        fails.append(f"the honest walked body stopped growing the contract: {c4.body_m}")
    sc.LIVE_LEDGER = live_path; sc._live_cache = None
    print(f"  still {base} -> walked {list(c1.body_m)} -> walk_inside {list(c2.body_m)}"
          f" -> origin-reach {list(c3.body_m)} -> long-but-local {list(c4.body_m)}")
    if fails:
        print("LIVE FOOTPRINT: FAIL %d" % len(fails)); [print("  - " + f) for f in fails]; return 1
    print("LIVE FOOTPRINT: PASS — no ledger = still; walked collider grows the contract; "
          "walk_inside leaves it; an origin-reaching extent is refused by name and a long local body is not")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
