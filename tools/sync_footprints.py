"""Sync measured AABB → spatial_needs.footprint_cells.

The registry already has `measurements.grid_cells` (measured AABB in cells,
written by `tools/measure_artifact_aabbs.py` from `commons/testing/measure_artifacts.gd`).
But `spatial_needs.footprint_cells` is still the bootstrapped inference from
`tools/bootstrap_spatial_needs.py`. The two disagree 75% of the time.

This tool connects the wire:
  - reads each artifact's measurements.grid_cells [w, d]
  - computes measured_area = ceil(w) * ceil(d)
  - sets spatial_needs.footprint_cells = min(measured_area, FOOTPRINT_CAP)
  - records the raw measurement in spatial_needs.measured_footprint_cells
  - flags artifacts where measured_area > 16 (swarms / effects) for review

Why the cap: the placement engine treats footprint_cells as a square's
side-length-squared. A FlowFieldMain measured at 50×50 = 2500 isn't an
actual 2500-cell solid — it's a procedural swarm whose AABB captures
the swarm extent. The placement engine should reserve the spawner cell,
not 2500 cells. The cap lets us use the measured data where it's sensible
and fall back to the swarm-default where it isn't.

Run:
  python tools/sync_footprints.py --dry-run       # preview the diff
  python tools/sync_footprints.py --apply         # write changes
  python tools/sync_footprints.py --cap=16        # change cap from default 9
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
REPORT_PATH = ROOT / "doc" / "placement_research" / "footprint_sync_report.json"

DEFAULT_CAP = 9   # 3×3 max for placement reasoning
SWARM_FLAG_THRESHOLD = 16   # measured area above this = flag as swarm/effect


def walk_for_artifacts(node, out: list[dict]) -> None:
    """Recursively find every dict that has a lookup_name."""
    if isinstance(node, dict):
        if "lookup_name" in node and isinstance(node["lookup_name"], str):
            out.append(node)
        for v in node.values():
            walk_for_artifacts(v, out)
    elif isinstance(node, list):
        for v in node:
            walk_for_artifacts(v, out)


def measured_area_of(art: dict) -> tuple[int, list[float]] | None:
    """Return (measured_area, raw_grid_cells) or None if no measurement."""
    m = art.get("measurements")
    if not m:
        return None
    gc = m.get("grid_cells")
    if not gc or len(gc) < 2:
        return None
    w = max(1, int(math.ceil(gc[0])))
    d = max(1, int(math.ceil(gc[1])))
    return w * d, gc


def sync_one_file(path: Path, cap: int, apply: bool) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    artifacts: list[dict] = []
    walk_for_artifacts(data, artifacts)

    changes = []
    swarm_flags = []
    no_measurement = 0
    no_spatial_needs = 0
    already_synced = 0

    for art in artifacts:
        m_area = measured_area_of(art)
        if m_area is None:
            no_measurement += 1
            continue
        measured_area, raw = m_area
        sn = art.get("spatial_needs")
        if not sn:
            no_spatial_needs += 1
            continue
        old = sn.get("footprint_cells")
        new = min(measured_area, cap)
        if old == new and sn.get("measured_footprint_cells") == measured_area:
            already_synced += 1
            continue
        changes.append({
            "lookup_name":    art["lookup_name"],
            "old":            old,
            "new":            new,
            "measured_area":  measured_area,
            "grid_cells":     raw,
            "capped":         measured_area > cap,
        })
        if measured_area > SWARM_FLAG_THRESHOLD:
            swarm_flags.append(art["lookup_name"])
        if apply:
            sn["footprint_cells"] = new
            sn["measured_footprint_cells"] = measured_area
            sn["footprint_source"] = "measured" if measured_area <= cap else "measured_capped"

    if apply and changes:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent="\t")

    return {
        "file":              path.name,
        "total_artifacts":   len(artifacts),
        "no_measurement":    no_measurement,
        "no_spatial_needs":  no_spatial_needs,
        "already_synced":    already_synced,
        "changes":           changes,
        "swarm_flags":       swarm_flags,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true",
                   help="write changes to registry files (default: dry run)")
    p.add_argument("--cap", type=int, default=DEFAULT_CAP,
                   help=f"max footprint_cells (default {DEFAULT_CAP})")
    args = p.parse_args()

    apply = args.apply
    cap = args.cap

    print(f"{'APPLY' if apply else 'DRY-RUN'} — sync measurements → spatial_needs.footprint_cells (cap={cap})")
    print()

    all_changes = []
    all_swarm_flags = []
    total_files = 0
    total_changes = 0
    total_caps = 0
    total_synced = 0

    for f in sorted(REGISTRY_DIR.glob("*.json")):
        try:
            result = sync_one_file(f, cap, apply)
        except Exception as e:
            print(f"  ERROR {f.name}: {e}")
            continue
        total_files += 1
        total_changes += len(result["changes"])
        total_caps += sum(1 for c in result["changes"] if c["capped"])
        total_synced += result["already_synced"]
        all_changes.extend(result["changes"])
        all_swarm_flags.extend(result["swarm_flags"])
        if result["changes"]:
            print(f"  {f.name:30}  {len(result['changes']):4} changes  "
                  f"({sum(1 for c in result['changes'] if c['capped'])} capped)")

    print()
    print(f"summary across {total_files} files:")
    print(f"  artifacts changed:         {total_changes}")
    print(f"  artifacts already synced:  {total_synced}")
    print(f"  cap-clipped at {cap}:           {total_caps}")
    print(f"  swarm/effect flagged (>{SWARM_FLAG_THRESHOLD}): {len(all_swarm_flags)}")
    print()

    # Histogram of measured areas
    if all_changes:
        from collections import Counter
        buckets = Counter()
        for c in all_changes:
            a = c["measured_area"]
            if a <= 1: bucket = "1"
            elif a <= 4: bucket = "2-4"
            elif a <= 9: bucket = "5-9"
            elif a <= 16: bucket = "10-16"
            elif a <= 64: bucket = "17-64"
            elif a <= 256: bucket = "65-256"
            else: bucket = ">256"
            buckets[bucket] += 1
        print("measured-area distribution (raw, pre-cap):")
        order = ["1", "2-4", "5-9", "10-16", "17-64", "65-256", ">256"]
        for k in order:
            n = buckets.get(k, 0)
            bar = "█" * (n * 50 // max(1, max(buckets.values())))
            print(f"  {k:>8}  {n:5}  {bar}")
        print()

    # Top swarm flags (raw_area, name)
    if all_swarm_flags:
        names_by_area = sorted(
            [c for c in all_changes if c["measured_area"] > SWARM_FLAG_THRESHOLD],
            key=lambda c: -c["measured_area"]
        )[:15]
        print(f"top swarms/effects (raw area, name, capped at {cap}):")
        for c in names_by_area:
            print(f"  {c['measured_area']:6}  {c['lookup_name']:35}  capped→{c['new']}")
        print()

    # Write report
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        json.dump({
            "applied":            apply,
            "cap":                cap,
            "total_changes":      total_changes,
            "total_capped":       total_caps,
            "swarm_flags":        all_swarm_flags,
            "changes":            all_changes,
        }, f, indent=2)
    print(f"wrote {REPORT_PATH}")

    if not apply and total_changes:
        print()
        print(f"to apply: python tools/sync_footprints.py --apply --cap={cap}")


if __name__ == "__main__":
    main()
