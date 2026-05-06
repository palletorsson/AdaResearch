#!/usr/bin/env python
"""Batch-upgrade registry descriptions for artifacts whose existing
description is too thin (under 30 chars, often just the token name).
Writes the new descriptions in-place while preserving key ordering
and JSON formatting style used in the registry files.
"""
import json
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

REPO = Path(__file__).resolve().parent.parent.parent
REGISTRY = REPO / "commons" / "artifacts" / "registry"

UPGRADES = {
    "ca_screen":
        "Screen display that renders live cellular-automata patterns — rule outputs visualised on a flat panel as the simulation runs.",
    "dome":
        "Half-sphere primitive produced by boolean subtraction — used as reference geometry for enclosures and shelters.",
    "double_helix_scene":
        "Oscillation-driven double-helix visualisation — two phase-offset sine waves trace intertwined curves that grow over time.",
    "grab_stick_scanner":
        "Grabbable stick with a UV-based texture-pixel scanner — samples the hit-point colour from any surface the tip touches, displaying the RGB value live.",
    "hand_model":
        "Static hand-model reference for VR scale and positioning — provides a human-proportioned anchor for sizing artifacts in the scene.",
    "health_display":
        "Live health readout panel wired to GameManager.health_updated — shows current hit points on a Label3D and updates every frame the value changes.",
    "hits_reset_display":
        "Counter panel showing hits taken toward map reset — displays N / max, incrementing as the player accumulates damage from hazards.",
    "interactable_demo":
        "Inspection rig laying out one of every VR control type in a single row — buttons, knobs, sliders (smooth/horizontal/snap/zero), lever, and wheel — each labelled for testing and review.",
    "modulor_man_demo":
        "Le Corbusier Modulor-proportioned human figure used as a scale reference in line-builder and proportion-study scenes.",
    "pickup_cube_rotating":
        "Pickup cube that rotates continuously — wraps pick_up_cube.gd and disables internal collision so the player can walk into the pickup area freely.",
    "seismograph":
        "Seismograph-style traveling-pen chart — draws the driving signal over time onto a scrolling paper strip, reading oscillation as a physical trace.",
    "space_colonization_algorithm":
        "Growth algorithm that builds branching structures by attracting tips toward a cloud of auxin-like markers — Runions-style space colonisation producing tree/coral/blood-vessel topologies.",
    "cube_mound_scene":
        "Procedural mound built from stacked cubes — layered cellular logic deposits cubes where conditions permit, producing terrain that is both built and eroded.",
}


def main() -> int:
    applied = 0
    for json_path in sorted(REGISTRY.glob("*.json")):
        try:
            data = json.loads(json_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"skipping {json_path.name}: {e}")
            continue
        changed = False

        def visit(obj, parent_list=False):
            nonlocal changed
            if isinstance(obj, dict):
                key = obj.get("lookup_name") or obj.get("name")
                if key in UPGRADES:
                    current = obj.get("description", "")
                    if not isinstance(current, str) or len(current) < 30:
                        obj["description"] = UPGRADES[key]
                        changed = True
                        print(f"  {json_path.name}: {key}")
                for v in list(obj.values()):
                    if isinstance(v, (dict, list)):
                        visit(v)
            elif isinstance(obj, list):
                for v in obj:
                    if isinstance(v, (dict, list)):
                        visit(v, parent_list=True)

        visit(data)
        if changed:
            json_path.write_text(
                json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            applied += 1
    print(f"\nApplied upgrades to {applied} registry files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
