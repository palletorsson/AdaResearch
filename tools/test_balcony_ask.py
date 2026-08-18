#!/usr/bin/env python3
"""Balconies-by-ask. GATE: no ask -> a small body negotiates interior as
before. BITE: the same body with venue_asks {token: balcony} negotiates as a
hanging balcony body (venue balcony, court dims) and the trace names the hand."""
from __future__ import annotations
import sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from spatial_negotiation import run
from spatial_floorplan import from_museum

def main() -> int:
    tok = "grabbable_line"
    plan = from_museum("sainsbury-false-perspective-enfilade", apron=14)
    _, p0, _ = run([tok], plan=plan)
    plan = from_museum("sainsbury-false-perspective-enfilade", apron=14)
    _, p1, _ = run([tok], plan=plan, venue_asks={tok: "balcony"})
    a, b = p0[0], p1[0]
    fails = []
    if a.venue != "interior" or a.result != "ACCEPT":
        fails.append(f"GATE: without an ask {tok} is {a.venue}/{a.result}, expected interior/ACCEPT")
    if b.venue != "balcony" or b.result != "ACCEPT":
        fails.append(f"BITE: with the ask {tok} is {b.venue}/{b.result} — {[t.detail for t in b.traces if t.status=='fail'][:2]}")
    if not getattr(b, "court_m", None):
        fails.append("BITE: no balcony void dims on the placement")
    print(f"  no ask: {a.venue} at {a.anchor} · ask balcony: {b.venue} {getattr(b, 'court_m', None)}")
    if fails:
        print("BALCONY ASK: FAIL %d" % len(fails)); [print("  - " + f) for f in fails]; return 1
    print("BALCONY ASK: PASS — no ask = interior; ask = balcony void, hanging")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
