"""read_concept_selections.py — Palle's gallery clicks, as facts the swap can obey.

The /forces-concepts page (and its future siblings) persists map-membership verdicts
to <encyclopedia>/public/<seq>-concepts/evals.json via the gallery-evals API:
  retire  - remove from the sequence's maps
  corpus  - keep the artifact, place it nowhere
  maps    - part of the sequence's maps
  hero    - the concept's one surreal representative (implies maps)

This reads them back on the AdaResearch side and reports them against the CURRENT
placement census, so the retire swap works from a click, not a guess:
  - RETIRE & PLACED     -> the swap's actual work list
  - MAPS/HERO & UNPLACED -> placement work list (goes into a map)
  - undecided placed tokens are COUNTED loudly, because a swap that runs while most
    of the census is unclicked is a decision nobody made.

Run:  python tools/read_concept_selections.py forces [--json]
Exit: 0 always for reporting; --check exits 1 when any RETIRE-clicked token is still
placed (so it can gate "did the swap actually happen").
"""
from __future__ import annotations
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public"))

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_concept_gallery import placed_census  # same census, one implementation


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 2
    seq_id = args[0]
    as_json = "--json" in sys.argv
    check = "--check" in sys.argv

    evf = os.path.join(ENC, f"{seq_id}-concepts", "evals.json")
    if not os.path.exists(evf):
        print(f"no selections yet - nothing clicked at /{seq_id}-concepts (missing {evf})")
        return 0
    raw = json.load(open(evf, encoding="utf-8"))
    # evals.json shape: {id: {verdict, ...}} or {id: "verdict"} - accept both
    verdicts: dict[str, str] = {}
    for k, v in raw.items():
        if isinstance(v, str):
            verdicts[k] = v
        elif isinstance(v, dict) and v.get("verdict"):
            verdicts[k] = str(v["verdict"])

    placed = placed_census(seq_id)
    swap_out = sorted(t for t, v in verdicts.items() if v == "retire" and t in placed)
    place_in = sorted(t for t, v in verdicts.items() if v in ("maps", "hero") and t not in placed)
    heroes = sorted(t for t, v in verdicts.items() if v == "hero")
    unclicked_placed = sorted(t for t in placed if t not in verdicts)

    report = {
        "sequence": seq_id,
        "clicked": len(verdicts),
        "swap_out": swap_out,          # retire-clicked AND currently placed
        "place_in": place_in,          # maps/hero-clicked AND currently unplaced
        "heroes": heroes,
        "unclicked_placed": len(unclicked_placed),
    }
    if as_json:
        print(json.dumps(report, ensure_ascii=False, indent=1))
    else:
        print(f"{seq_id}: {len(verdicts)} clicked")
        print(f"  swap OUT (retire & placed):   {len(swap_out)}" + (f"  {', '.join(swap_out[:8])}" + (" ..." if len(swap_out) > 8 else "") if swap_out else ""))
        print(f"  place IN (maps/hero, unplaced): {len(place_in)}" + (f"  {', '.join(place_in[:8])}" + (" ..." if len(place_in) > 8 else "") if place_in else ""))
        print(f"  heroes: {len(heroes)}" + (f"  {', '.join(heroes)}" if heroes else ""))
        print(f"  placed but UNCLICKED: {len(unclicked_placed)} - a swap over these is a decision nobody made")
    if check and swap_out:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
