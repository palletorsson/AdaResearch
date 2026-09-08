"""Does the museum still move bodies off the cells their maps name?

2026-09-08, Palle: "can we remove the seal function so I can place it freely so I
also free other artifact that have the same problem?" — ruled: STOP THE SLIDE,
KEEP THE SEAL. The map is the placement authority; a seal that cuts the hall is
reported, not enforced by relocating somebody's composition.

Before that ruling, measured off ada_run/em_pack_report.json:

    2410 bodies across 308 halls
      slid off their map cell : 329   (209 of them "sealing would sever...")
      left behind entirely    : 147   ( 23 of them the same reason)
      halls affected          : 202 of 308

This is the gate on that. It reads the two DERIVED files the museum writes as it
builds and answers one question: is any body still displaced for a seal reason?

  python tools/check_seal_displacement.py            # report
  python tools/check_seal_displacement.py --gate     # exit 1 if any seal displacement remains

WHAT A PASS MEANS, exactly: zero bodies slid or dropped because sealing would
sever. It does NOT mean nothing moved — a body can still slide because its cell
was taken, and can still be dropped for "no living scene" (112 placements) or
"instantiate returned non-Node3D" (12). Those are different bugs and this gate
deliberately does not hide them; it prints them separately.

BOTH FILES ARE DERIVED and only cover the halls a run actually built. A hall
nobody walked has no row, so a clean report over four halls proves very little —
the row count is printed for that reason. Compare against the source, never
trust a cache's silence (the standing rule that em_plan's date taught).
"""
from __future__ import annotations

import argparse
import io
import json
import re
import sys
from collections import Counter
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "ada_run" / "em_pack_report.json"
BUILT = ROOT / "ada_run" / "em_built.json"

# the museum re-prefixes a replayed refusal every time it is re-baked, so the
# reason arrives as "baked: baked: baked: sealing would sever the walk route"
BAKED = re.compile(r"^(baked:\s*)+")
SEAL = ("seal", "sever")


def load(p: Path):
    try:
        return json.loads(io.open(p, encoding="utf-8").read())
    except Exception as e:
        print("  cannot read %s — %s" % (p.name, e))
        return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--gate", action="store_true", help="exit 1 while any seal displacement remains")
    a = ap.parse_args()

    print("THE MAP IS THE PLACEMENT AUTHORITY — is any body still moved for a seal?")
    print()

    pack = load(PACK)
    slid_seal = Counter()
    drop_seal = Counter()
    slid_other = 0
    drop_other = Counter()
    halls = 0
    bodies = 0
    if isinstance(pack, dict):
        rows = pack.get("halls") or {}
        halls = len(rows)
        for _, row in rows.items():
            for b in (row.get("bodies") or []):
                bodies += 1
                why = BAKED.sub("", str(b.get("why") or "")).strip()
                is_seal = any(s in why for s in SEAL)
                if b.get("final") is None:
                    (drop_seal if is_seal else drop_other)[why or "(no reason given)"] += 1
                elif int(b.get("rings") or 0) > 0:
                    if is_seal:
                        slid_seal[str(b.get("token"))] += 1
                    else:
                        slid_other += 1
    print("  em_pack_report.json : %d bodies across %d halls" % (bodies, halls))
    print("    slid for a SEAL reason    : %d   <- must be 0" % sum(slid_seal.values()))
    print("    dropped for a SEAL reason : %d   <- must be 0" % sum(drop_seal.values()))
    print("    slid for another reason   : %d   (a taken cell — not this gate's business)" % slid_other)
    for w, n in drop_other.most_common(4):
        print("    dropped: %-46s %d" % (w[:46], n))
    for t, n in slid_seal.most_common(10):
        print("      still slid: %-40s %d" % (t, n))

    built = load(BUILT)
    sev_halls = 0
    sev_bodies = 0
    if isinstance(built, dict):
        for seg in (built.get("segments") or []):
            sev = seg.get("severed")
            if sev is None:
                continue                      # a segment built before this key existed
            if sev:
                sev_halls += 1
                sev_bodies += len(sev)
                for s in sev[:4]:
                    print("      severed: %s seals %s" % (s.get("token"), s.get("cells")))
    print()
    print("  em_built.json : %d hall(s) report a severing seal, %d body/ies" % (sev_halls, sev_bodies))
    if isinstance(built, dict) and not any("severed" in (s or {}) for s in (built.get("segments") or [])):
        print("    (no `severed` key in any segment — this run predates the ruling; rebuild to populate it)")

    # THE LEDGER ACCUMULATES AND CANNOT DATE ITSELF. em_pack_report.json keeps a
    # row per hall across every run ever (308 of them) and carries no timestamp,
    # so a hall not rebuilt since the ruling still shows its old displacement.
    # em_built.json holds only the segments THIS run built. So the gate judges
    # the halls we can actually date, and the accumulated figure is history.
    # JOIN ON THE PEARL, NOT ON chapter|pearl. em_built's segments carry
    # chapter: "" — the first version of this gate built "|point lines", matched
    # nothing against the pack report's "primitives|point lines", and passed
    # because it had judged zero rows. A gate that passes for want of a match is
    # worse than no gate (the --check-compared-the-strip-to-its-own-input rule).
    # A pearl can repeat across chapters ("noise|point" and "primitives|point"),
    # so this can judge one hall too many — which is the safe direction.
    fresh: set[str] = set()
    if isinstance(built, dict):
        for seg in (built.get("segments") or []):
            pearl = str(seg.get("pearl", "")).strip()
            if pearl:
                fresh.add(pearl)
    bad = 0
    judged = 0
    if isinstance(pack, dict):
        for hall, row in (pack.get("halls") or {}).items():
            if str(hall).split("|", 1)[-1] not in fresh:
                continue
            judged += 1
            for b in (row.get("bodies") or []):
                why = BAKED.sub("", str(b.get("why") or "")).strip()
                if not any(s in why for s in SEAL):
                    continue
                if b.get("final") is None or int(b.get("rings") or 0) > 0:
                    bad += 1
                    print("      STILL DISPLACED in %s: %s (%s)" % (hall, b.get("token"), why[:40]))
    print()
    print("  history (all 308 halls, undated): %d displaced by a seal"
          % (sum(slid_seal.values()) + sum(drop_seal.values())))
    print("  this run rebuilt %d hall(s): %s" % (len(fresh), ", ".join(sorted(fresh)) or "none"))
    print("  matched %d row(s) in the ledger for them" % judged)
    if not judged:
        print("  nothing to judge — no hall in em_built.json. Walk the museum, then run this again.")
    elif bad:
        print("  %d placement(s) in those halls are STILL displaced by a seal." % bad)
    else:
        print("  no body was moved for a seal reason in the halls this run rebuilt.")
    return 1 if (a.gate and bad) else 0


if __name__ == "__main__":
    sys.exit(main())
