"""tools/wire_grown_to_sequences.py — wire Grown_<id> maps into sequence files.

Reads ada_run/timeline_grow_log.json (the log of grown maps and their parent
sequence). For each grown map, appends its name to the parent sequence's
maps[] in commons/maps/sequences/<file>.json (skipping if already present).

Each sequence file is backed up to <file>.json.bak on first wire.

Run:
  python tools/wire_grown_to_sequences.py            # wire all logged maps
  python tools/wire_grown_to_sequences.py --dry-run  # preview without writing
  python tools/wire_grown_to_sequences.py --sequence=primitives  # filter
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
LOG_PATH = ROOT / "ada_run" / "timeline_grow_log.json"
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"


def find_sequence_file(sequence_id: str) -> Path | None:
    """Find the sequence JSON that contains the sequence_id."""
    for sf in SEQ_DIR.glob("*.json"):
        try:
            with open(sf, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        seqs = data.get("sequences") or {}
        if isinstance(seqs, dict) and sequence_id in seqs:
            return sf
        if isinstance(seqs, list):
            for s in seqs:
                if isinstance(s, dict) and (s.get("id") == sequence_id or s.get("name") == sequence_id):
                    return sf
    return None


def wire_one(seq_file: Path, sequence_id: str, map_name: str,
             dry_run: bool = False) -> tuple[bool, str]:
    """Append map_name to sequence's maps[] if not present.
    Returns (was_changed, status_string)."""
    with open(seq_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    seqs = data.get("sequences")
    seq = None
    if isinstance(seqs, dict):
        seq = seqs.get(sequence_id)
    elif isinstance(seqs, list):
        for s in seqs:
            if isinstance(s, dict) and (s.get("id") == sequence_id or s.get("name") == sequence_id):
                seq = s; break
    if not isinstance(seq, dict):
        return False, "sequence_not_found"
    maps = seq.get("maps")
    if not isinstance(maps, list):
        seq["maps"] = []
        maps = seq["maps"]
    if map_name in maps:
        return False, "already_wired"
    if dry_run:
        return True, "would_wire"
    # Backup if not already
    backup = seq_file.with_suffix(".json.bak")
    if not backup.exists():
        shutil.copy2(seq_file, backup)
    maps.append(map_name)
    with open(seq_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent="\t")
    return True, "wired"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--sequence", type=str, help="only wire maps belonging to this sequence")
    args = p.parse_args()

    if not LOG_PATH.exists():
        print(f"no timeline_grow_log.json yet — grow some maps first")
        return

    with open(LOG_PATH, "r", encoding="utf-8") as f:
        log = json.load(f)

    # Deduplicate by (sequence, map_path) to avoid wiring same thing twice
    seen: set[tuple[str, str]] = set()
    deduped: list[dict] = []
    for entry in log:
        if not isinstance(entry, dict): continue
        seq = entry.get("sequence")
        wid = entry.get("window_id")
        if not seq or not wid: continue
        map_name = f"Grown_{wid}"
        if args.sequence and seq != args.sequence: continue
        k = (seq, map_name)
        if k in seen: continue
        seen.add(k)
        deduped.append({"sequence": seq, "map_name": map_name, "window_id": wid})

    print(f"{'DRY-RUN' if args.dry_run else 'APPLY'} — {len(deduped)} grown maps to consider")
    print()

    wired = 0
    skipped_existing = 0
    skipped_not_found = 0
    by_sequence: dict[str, int] = {}

    for entry in deduped:
        seq_id = entry["sequence"]
        map_name = entry["map_name"]
        seq_file = find_sequence_file(seq_id)
        if seq_file is None:
            skipped_not_found += 1
            print(f"  ? {seq_id:25} {map_name:30}  no sequence file found")
            continue
        changed, status = wire_one(seq_file, seq_id, map_name, dry_run=args.dry_run)
        if changed:
            wired += 1
            by_sequence[seq_id] = by_sequence.get(seq_id, 0) + 1
            mark = "→" if args.dry_run else "✓"
            print(f"  {mark} {seq_id:25} {map_name:30}  {seq_file.name}")
        else:
            skipped_existing += 1

    print()
    print(f"summary:")
    print(f"  wired (or would wire): {wired}")
    print(f"  already wired:         {skipped_existing}")
    print(f"  sequence not found:    {skipped_not_found}")
    if by_sequence:
        print(f"  by sequence:")
        for s, n in sorted(by_sequence.items(), key=lambda x: -x[1]):
            print(f"    {s:25} {n}")


if __name__ == "__main__":
    main()
