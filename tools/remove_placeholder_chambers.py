"""tools/remove_placeholder_chambers.py — strip placeholder chamber endings.

Rationale: nearly every spine sequence ends with a placeholder map of the form
Chamber_<seq>. These were scaffolded as endings; the curriculum's actual
synthesis should be integrated into one of the existing content maps. The
chamber concept survives as a BEAT (in *.beats.json), but the placeholder MAP
gets removed from the sequence's maps[] list.

Affected (placeholder is the LAST map of the sequence):
  array_tutorial, cellularautomata, change, color, forces,
  foundationscrisis, fractals, lsystems, machinelearning, noise,
  proceduralgeneration, qfeplaboratory, randomness, swarmintelligence,
  transformation, wavefunctions, boolean_surfaces, isosurfaces,
  postfoundationscrisis  (where Chamber_* exists at the end)

Special:
  primitives — Chamber_Primitives at pos 12, trailed only by Grown_primitives_w*
              WFC orphan outputs. We remove ALL of: Chamber_Primitives + the 3
              orphans → primitives ends at Catalyst_01_Primitives.
  softbodies — Chamber_SoftBodies at pos 9 with 24 maps trailing. Skipped here;
              needs a separate restructure decision.

For each affected sequence, also updates the beats file (if it exists):
  - Finds the CHAMBER beat and clears its maps[] field (becomes []).
  - Leaves the beat in place — it's now a transparent placeholder waiting
    for a proper integration point.

Run:
  python tools/remove_placeholder_chambers.py                 # dry-run report
  python tools/remove_placeholder_chambers.py --apply         # write changes

Always writes a JSON report at doc/placement_research/chamber_removal.json.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
REPORT = ROOT / "doc" / "placement_research" / "chamber_removal.json"

# Sequences explicitly skipped (mid-list chamber, needs hand decision)
SKIP = {"softbodies"}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true", help="write changes (default = dry-run)")
    args = p.parse_args()

    plan: list[dict] = []

    for sf in sorted(SEQ_DIR.glob("*.json")):
        if sf.name.endswith(".beats.json"):
            continue
        if sf.stem in SKIP:
            continue

        try:
            data = json.loads(sf.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue

        seqs = data.get("sequences", data)
        if not isinstance(seqs, dict):
            continue

        for seq_id, inner in seqs.items():
            if not isinstance(inner, dict):
                continue
            maps = inner.get("maps", [])
            if not maps:
                continue

            removed: list[str] = []

            # Special case: primitives orphans
            if seq_id == "primitives":
                orphans = [m for m in maps if m.startswith("Grown_primitives_")]
                for o in orphans:
                    maps.remove(o)
                    removed.append(o)

            # Common: trailing Chamber_<*>
            while maps and maps[-1].lower().startswith("chamber_"):
                removed.append(maps[-1])
                maps.pop()

            if not removed:
                continue

            # Also update the beats file if present
            bf = SEQ_DIR / f"{seq_id}.beats.json"
            beat_changes: list[str] = []
            if bf.exists():
                try:
                    bd = json.loads(bf.read_text(encoding="utf-8"))
                except json.JSONDecodeError:
                    bd = None
                if bd:
                    for b in bd.get("beats", []):
                        if b.get("role") == "CHAMBER":
                            ms = b.get("maps") or []
                            new_ms = [m for m in ms if m not in removed]
                            if new_ms != ms:
                                b["maps"] = new_ms
                                beat_changes.append(b.get("id", "?"))

            plan.append({
                "sequence": seq_id,
                "file":     str(sf.relative_to(ROOT)),
                "removed":  removed,
                "remaining_maps": len(maps),
                "beats_file_chamber_beats_cleared": beat_changes,
            })

            if args.apply:
                # Set maps back into the file structure
                inner["maps"] = maps
                sf.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
                if bf.exists() and bd and beat_changes:
                    bf.write_text(json.dumps(bd, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Print summary
    if not plan:
        print("no sequences match the placeholder pattern; nothing to do.")
        return

    print(f"{'WROTE' if args.apply else 'DRY-RUN'} — {len(plan)} sequences affected:")
    print()
    for p in plan:
        print(f"  {p['sequence']}:")
        for r in p["removed"]:
            print(f"    - {r}")
        if p["beats_file_chamber_beats_cleared"]:
            print(f"    (beats file: CHAMBER beat(s) cleared: {', '.join(p['beats_file_chamber_beats_cleared'])})")
        print(f"    → {p['remaining_maps']} maps remain")
        print()

    # Write report
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps({
        "applied": args.apply,
        "plan":    plan,
        "skipped": sorted(SKIP),
    }, indent=2), encoding="utf-8")
    print(f"report → {REPORT.relative_to(ROOT)}")

    if not args.apply:
        print()
        print("run with --apply to write changes.")


if __name__ == "__main__":
    main()
