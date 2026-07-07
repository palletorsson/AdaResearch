"""tools/catalyst_readiness.py — find maps ready to host catalyst integration.

The catalyst mechanic (bracelet pickup; foe creatures that phase-shift to friend)
needs specific scaffolding in the host map. This tool surveys every spine
sequence's maps for the presence of catalyst-relevant content:

  - catalyst_foe / catalyst_vent      → friend-foe mechanic present
  - catalyst_pedestal / bracelet_*    → pickup station present
  - pylon                             → pylon infrastructure present
  - creature / critter / nature       → ecology that could host phase-shift

For each map we read map_data.json (json content + interactables) and look for
these tokens anywhere. Results are grouped by sequence.

Output:
  - stdout report (per sequence, ranked maps)
  - doc/placement_research/catalyst_readiness.json

Use: open the report; for each sequence, the top-ranked map is a candidate for
principal catalyst integration. The CATALYST_GAIN beat is then placed at that
beat's slot in the sequence's beats file.
"""
from __future__ import annotations

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
MAPS_DIR = ROOT / "commons" / "maps"
REPORT = ROOT / "doc" / "placement_research" / "catalyst_readiness.json"

# Token → category, base weight (higher = more catalyst-ready)
SIGNALS: dict[str, tuple[str, int]] = {
    "catalyst_foe":      ("friend_foe",   10),
    "catalyst_vent":     ("friend_foe",   10),
    "catalyst_pedestal": ("pickup",        8),
    "becoming_catalyst": ("pickup",        8),
    "bracelet":          ("pickup",        6),
    "catalyst_orb":      ("pickup",        6),
    "pylon":             ("infrastructure", 5),
    # ecology that COULD be re-tagged as foe/friend
    "creature":          ("ecology",       2),
    "critter":           ("ecology",       2),
    # vents alone (without catalyst_) — possible site for catalyst_vent
    "vent":              ("infrastructure", 1),
}


def load_spine() -> list[str]:
    p = ROOT / "commons" / "maps" / "curriculum_spine.json"
    if not p.exists():
        return []
    d = json.loads(p.read_text(encoding="utf-8"))
    return [s.get("name", "") for s in d.get("spine", {}).get("sequences", [])]


def scan_map(map_name: str) -> tuple[int, dict[str, int]]:
    """Return (total_score, hits_by_token) for the named map."""
    md = MAPS_DIR / map_name / "map_data.json"
    if not md.exists():
        return 0, {}
    try:
        text = md.read_text(encoding="utf-8").lower()
    except (UnicodeDecodeError, OSError):
        return 0, {}
    hits: dict[str, int] = {}
    score = 0
    for tok, (_cat, w) in SIGNALS.items():
        count = text.count(tok)
        if count > 0:
            hits[tok] = count
            score += w * count
    return score, hits


def scan_sequence(seq_id: str) -> dict:
    sf = SEQ_DIR / f"{seq_id}.json"
    if not sf.exists():
        return {"sequence": seq_id, "maps": [], "missing_file": True}
    try:
        d = json.loads(sf.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"sequence": seq_id, "maps": [], "parse_error": True}
    seqs = d.get("sequences", d)
    if not isinstance(seqs, dict) or seq_id not in seqs:
        return {"sequence": seq_id, "maps": [], "no_inner": True}
    inner = seqs[seq_id]
    maps = inner.get("maps", [])

    rows = []
    for i, m in enumerate(maps):
        score, hits = scan_map(m)
        rows.append({
            "position": i,
            "map":      m,
            "score":    score,
            "hits":     hits,
        })
    rows.sort(key=lambda r: -r["score"])
    return {
        "sequence": seq_id,
        "n_maps":   len(maps),
        "ready_maps": rows,
    }


def main():
    spine = load_spine()
    if not spine:
        print("warning: no spine found; scanning all *.json in sequences/")
        spine = sorted(p.stem for p in SEQ_DIR.glob("*.json") if not p.name.endswith(".beats.json"))

    results = {}
    for seq in spine:
        r = scan_sequence(seq)
        results[seq] = r

    # Print human-readable report
    print(f"CATALYST READINESS — {len(spine)} spine sequences")
    print()
    for seq in spine:
        r = results[seq]
        if r.get("missing_file") or r.get("parse_error") or r.get("no_inner"):
            print(f"  {seq}: (no readable sequence file)")
            continue
        rows = r.get("ready_maps") or []
        # Show maps that have ANY catalyst signal
        ready = [row for row in rows if row["score"] > 0]
        if not ready:
            print(f"  {seq:25} — NONE READY (no catalyst signals in any map)")
            continue
        print(f"  {seq:25} {len(ready)} ready / {r['n_maps']} maps")
        for row in ready[:3]:
            tokens = ", ".join(f"{k}×{v}" for k, v in row["hits"].items())
            print(f"    [{row['position']:2d}] {row['map']:42}  score {row['score']:3d}  · {tokens}")
        if len(ready) > 3:
            print(f"    ... +{len(ready) - 3} more")
        print()

    # Save JSON
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"report → {REPORT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
