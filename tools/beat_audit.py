"""tools/beat_audit.py — cross-reference beats with maps; surface gaps.

For each sequence that has a beats.json file:
  - Confirm every beat's `maps[]` references real existing maps
  - Find ORPHAN maps (in sequence's maps[] but no beat lists them)
  - Find UNFILLED beats (intent declared, no map yet)
  - Find MULTI-PURPOSE maps (appear in multiple beats — note, not error)
  - Find BLEED ASYMMETRIES (P bleed_from X but X has no bleed_to P)
  - Compute coverage statistics

Run:
  python tools/beat_audit.py                       # all sequences with beats files
  python tools/beat_audit.py --sequence=primitives # detail for one

Output: stdout report + doc/placement_research/beat_audit.json
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
MAPS_DIR = ROOT / "commons" / "maps"
OUT = ROOT / "doc" / "placement_research" / "beat_audit.json"


# ─────────────────────────────────────────────────────────────────────
# Load
# ─────────────────────────────────────────────────────────────────────

def load_beats_files() -> dict[str, dict]:
    """Find every *.beats.json file under sequences/."""
    out: dict[str, dict] = {}
    for bf in SEQ_DIR.glob("*.beats.json"):
        try:
            with open(bf, "r", encoding="utf-8") as f:
                data = json.load(f)
            seq = data.get("_meta", {}).get("sequence") or bf.stem.replace(".beats", "")
            out[seq] = data
        except (json.JSONDecodeError, OSError) as e:
            print(f"  WARN: {bf.name}: {e}")
    return out


def load_sequence_maps(seq_id: str) -> list[str]:
    """Load the maps list from <seq>.json."""
    p = SEQ_DIR / f"{seq_id}.json"
    if not p.exists():
        return []
    try:
        with open(p, "r", encoding="utf-8") as f:
            data = json.load(f)
        seqs = data.get("sequences", {})
        if isinstance(seqs, dict) and seq_id in seqs:
            return list(seqs[seq_id].get("maps") or [])
    except (json.JSONDecodeError, OSError):
        pass
    return []


def map_exists(map_name: str) -> bool:
    return (MAPS_DIR / map_name / "map_data.json").exists()


# ─────────────────────────────────────────────────────────────────────
# Audit one sequence
# ─────────────────────────────────────────────────────────────────────

def audit_sequence(seq_id: str, beats_data: dict, sequence_maps: list[str],
                    all_beats: dict[str, dict]) -> dict:
    beats = beats_data.get("beats", [])
    declared_orphan = beats_data.get("_orphan_candidates", [])
    sequence_maps_set = set(sequence_maps)

    # Maps each beat references
    maps_in_beats: list[str] = []
    map_to_beats: dict[str, list[str]] = defaultdict(list)
    missing_maps: list[tuple[str, str]] = []   # (beat_id, map_name)
    for b in beats:
        bid = b.get("id", "?")
        for m in (b.get("maps") or []):
            maps_in_beats.append(m)
            map_to_beats[m].append(bid)
            if not map_exists(m):
                missing_maps.append((bid, m))

    # Orphans: in the sequence's maps[] but not in any beat
    orphan_maps = [m for m in sequence_maps if m not in map_to_beats]

    # Multi-purpose: maps in >1 beat
    multi_purpose = {m: bids for m, bids in map_to_beats.items() if len(bids) > 1}

    # Unfilled beats: beats with empty maps[] (and not an explicit PAUSE/GATEWAY/META)
    unfilled = []
    for b in beats:
        if not (b.get("maps") or []):
            role = b.get("role", "")
            # PAUSE and some structural roles can be legitimately empty
            if role not in ("PAUSE", "META"):
                unfilled.append({"id": b.get("id"), "role": role,
                                 "concept": b.get("concept", "")[:80]})

    # Bleeds: check symmetry against other sequences
    bleed_issues = []
    for b in beats:
        bid = b.get("id", "?")
        for other_seq in (b.get("bleed_from") or []):
            other_beats = all_beats.get(other_seq, {}).get("beats", [])
            # Is there at least one beat in `other_seq` with `bleed_to` mentioning `seq_id`?
            symmetric = any(
                seq_id in (ob.get("bleed_to") or []) for ob in other_beats
            )
            if not symmetric:
                if other_seq in all_beats:
                    bleed_issues.append(
                        f"{bid}: bleed_from {other_seq} not reciprocated by any {other_seq}.bleed_to"
                    )
                else:
                    bleed_issues.append(
                        f"{bid}: bleed_from {other_seq} (sequence has no beats file yet)"
                    )

    # Maps the beats reference that aren't in the sequence's official maps[]
    not_in_seq_list = [m for m in maps_in_beats if m not in sequence_maps_set]

    # Stats
    role_counts: dict[str, int] = defaultdict(int)
    register_counts: dict[str, int] = defaultdict(int)
    for b in beats:
        role_counts[b.get("role", "")] += 1
        register_counts[b.get("register", "")] += 1

    return {
        "sequence":          seq_id,
        "n_beats":           len(beats),
        "n_maps_in_seq":     len(sequence_maps),
        "n_maps_referenced": len(set(maps_in_beats)),
        "missing_maps":      missing_maps,
        "orphan_maps":       orphan_maps,
        "multi_purpose":     multi_purpose,
        "unfilled_beats":    unfilled,
        "bleed_issues":      bleed_issues,
        "not_in_seq_list":   not_in_seq_list,
        "role_counts":       dict(role_counts),
        "register_counts":   dict(register_counts),
    }


# ─────────────────────────────────────────────────────────────────────
# Reporting
# ─────────────────────────────────────────────────────────────────────

def print_report(report: dict) -> None:
    seq = report["sequence"]
    print(f"=== {seq} ===")
    print(f"  beats:           {report['n_beats']}")
    print(f"  maps in seq:     {report['n_maps_in_seq']}")
    print(f"  maps in beats:   {report['n_maps_referenced']}")
    if report["missing_maps"]:
        print(f"  MISSING MAPS ({len(report['missing_maps'])}):")
        for bid, m in report["missing_maps"]:
            print(f"    [{bid}] {m}  (not found at commons/maps/{m}/map_data.json)")
    if report["orphan_maps"]:
        print(f"  ORPHAN MAPS ({len(report['orphan_maps'])}) — in sequence list, no beat:")
        for m in report["orphan_maps"]:
            print(f"    {m}")
    if report["multi_purpose"]:
        print(f"  MULTI-PURPOSE ({len(report['multi_purpose'])}) — map in >1 beat:")
        for m, bids in report["multi_purpose"].items():
            print(f"    {m} → {', '.join(bids)}")
    if report["unfilled_beats"]:
        print(f"  UNFILLED BEATS ({len(report['unfilled_beats'])}) — declared intent, no map:")
        for b in report["unfilled_beats"]:
            print(f"    [{b['id']}] {b['role']:14}  {b['concept']}")
    if report["bleed_issues"]:
        print(f"  BLEED ASYMMETRIES ({len(report['bleed_issues'])}):")
        for msg in report["bleed_issues"]:
            print(f"    {msg}")
    if report["not_in_seq_list"]:
        print(f"  REFERENCED OUTSIDE SEQ ({len(report['not_in_seq_list'])}):")
        print(f"    {', '.join(report['not_in_seq_list'])}")
        print(f"    (beats reference these but the sequence's maps[] does not)")
    # Role / register distribution
    if report["role_counts"]:
        print(f"  role distribution:")
        for r, n in sorted(report["role_counts"].items(), key=lambda x: -x[1]):
            print(f"    {r:14} {n}")
    if report["register_counts"]:
        print(f"  register distribution:")
        for r, n in sorted(report["register_counts"].items(), key=lambda x: -x[1]):
            print(f"    {r:14} {n}")
    print()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--sequence", type=str, help="single sequence to audit")
    args = p.parse_args()

    print("loading beats files...")
    all_beats = load_beats_files()
    print(f"  {len(all_beats)} sequences with beats files")

    if not all_beats:
        print(f"  no *.beats.json files found in {SEQ_DIR}")
        print(f"  create one to get started (see doc/beats/schema.md)")
        return

    targets = [args.sequence] if args.sequence else sorted(all_beats.keys())

    reports = {}
    for seq in targets:
        if seq not in all_beats:
            print(f"  no beats file for {seq}")
            continue
        sequence_maps = load_sequence_maps(seq)
        report = audit_sequence(seq, all_beats[seq], sequence_maps, all_beats)
        reports[seq] = report
        print_report(report)

    # Save JSON
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(reports, f, indent=2)
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
