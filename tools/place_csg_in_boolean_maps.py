"""tools/place_csg_in_boolean_maps.py — wire CSG artifacts into the 5 boolean maps.

The scaffold maps from tools/scaffold_boolean_maps.py exist but have empty
interactables layers. The CSG artifacts (csg_union_demo, csg_intersection_demo,
csg_difference_demo, csg_compose_workbench, csg_architecture_cavity) exist on
disk and in the registry. This tool wires them up:

  - Place the matching CSG artifact at the centre of each map
  - Keep the spawn at (0,0) + teleporter at (9,9)
  - Remove the _scaffold flag from map_info (these are now real)

Run:
  python tools/place_csg_in_boolean_maps.py            # dry-run
  python tools/place_csg_in_boolean_maps.py --apply    # write changes
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
MAPS_DIR = ROOT / "commons" / "maps"

# (map_name, artifact_lookup_name)
PAIRINGS = [
    ("Boolean_Union",                "csg_union_demo"),
    ("Boolean_Intersection",         "csg_intersection_demo"),
    ("Boolean_Difference",           "csg_difference_demo"),
    ("Boolean_Compose_Workbench",    "csg_compose_workbench"),
    ("Boolean_Architecture_Cavity",  "csg_architecture_cavity"),
]


def update_map(map_name: str, artifact: str, apply: bool) -> str:
    md = MAPS_DIR / map_name / "map_data.json"
    if not md.exists():
        return f"  SKIP {map_name}: map_data.json missing (run scaffold_boolean_maps.py first)"
    try:
        d = json.loads(md.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return f"  SKIP {map_name}: parse error {e}"

    inter = d["layers"]["interactables"]
    rows, cols = len(inter), len(inter[0])
    cr, cc = rows // 2, cols // 2

    changes = []

    # Already placed?
    if inter[cr][cc].strip() == artifact:
        return f"  OK   {map_name}: artifact {artifact!r} already at [{cr},{cc}]"

    # Place
    old = inter[cr][cc]
    inter[cr][cc] = artifact
    changes.append(f"interactables[{cr}][{cc}] {old!r} → {artifact!r}")

    # Clean _scaffold flag now that the map is wired
    if d["map_info"].get("_scaffold"):
        del d["map_info"]["_scaffold"]
        if "_scaffold_origin" in d["map_info"]:
            del d["map_info"]["_scaffold_origin"]
        d["map_info"]["version"] = "0.2"
        changes.append("removed _scaffold flag, version 0.1 → 0.2")

    if apply:
        md.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")

    return f"  {'OK' if apply else 'WOULD'}   {map_name}: " + " · ".join(changes)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true")
    args = p.parse_args()

    print(f"{'WRITING' if args.apply else 'DRY-RUN'} — placing CSG artifacts in 5 boolean maps:")
    for map_name, artifact in PAIRINGS:
        print(update_map(map_name, artifact, args.apply))
    print()
    if not args.apply:
        print("run with --apply to write changes")


if __name__ == "__main__":
    main()
