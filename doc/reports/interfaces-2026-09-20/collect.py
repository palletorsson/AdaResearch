"""Snapshot existing interface evidence without changing production content."""
import collections
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import urllib.request

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
spec = importlib.util.spec_from_file_location("ui_audit", ROOT / "tools/ui_audit.py")
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)
rows = audit.scan()
(OUT / "source-inventory.json").write_text(json.dumps(rows, indent=2), encoding="utf-8")
counts = {}
for row in rows:
    counts.setdefault(row["type"], collections.Counter())[row["status"]] += 1

spine = json.loads((ROOT / "commons/maps/curriculum_spine.json").read_text(encoding="utf-8"))
active = set()
for seq in spine["spine"]["sequences"]:
    p = ROOT / "commons/maps/sequences" / (seq["name"] + ".json")
    if p.exists():
        data = json.loads(p.read_text(encoding="utf-8-sig"))
        for entry in data.get("sequences", {}).values():
            active.update(x for x in entry.get("maps", []) if isinstance(x, str))
placements = []
for p in sorted((ROOT / "commons/maps").glob("*/map_data.json")):
    data = json.loads(p.read_text(encoding="utf-8-sig"))
    for layer, grid in data.get("layers", {}).items():
        if not isinstance(grid, list):
            continue
        for z, row in enumerate(grid):
            if not isinstance(row, list):
                continue
            for x, token in enumerate(row):
                if isinstance(token, str) and "interactable_demo" in token:
                    placements.append({"map": p.parent.name, "layer": layer, "x": x, "z": z,
                        "token": token, "in_current_spine_sequence": p.parent.name in active,
                        "direct_token": re.split(r"[:#]", token)[0] == "interactable_demo"})

source_paths = [
    "commons/interactables/InteractableDemo.gd", "commons/interactables/interactable_demo.tscn",
    "commons/ui/control_panel.gd", "commons/ui/control_console.gd",
    "commons/ui/interface_presets.gd", "commons/ui/interface_housing.gd",
    "commons/audio/rack_templates/RackTemplates.gd", "algorithms/forces/forces_rack_panel.gd",
    "tools/ui_audit.py", "tools/check_interaction.py", "tools/artifact_controls.py",
    "commons/testing/capture_interactable_demo_config.gd",
    "commons/testing/capture_interface_presets.gd", "commons/testing/wcn_desktop_driver.gd",
    "commons/testing/test_control_panel.gd", "commons/testing/test_console_allcontrols.gd",
    "doc/INTERFACE_OVERHAUL.md", "doc/startpacks/interaction-controls.md",
]
manifest = []
for path in source_paths:
    p = ROOT / path
    manifest.append({"path": path, "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                     "bytes": p.stat().st_size})

routes = ["interactable-demo", "interactable-layouts-gallery", "interface-presets-gallery",
          "interface-skins-gallery", "interface-overhaul", "interface-composer"]
http = []
for route in routes:
    url = "http://localhost:3003/" + route
    try:
        with urllib.request.urlopen(url, timeout=15) as response:
            http.append({"url": url, "status": response.status,
                         "check": "HTTP only; browser interaction not tested"})
    except Exception as exc:
        http.append({"url": url, "error": str(exc)})

registry = json.loads((ROOT / "commons/artifacts/registry/commons_artifacts.json").read_text(encoding="utf-8"))
facts = {"date": "2026-09-20", "method": "Source signature audit, not a runtime usability verdict",
    "scan_roots": audit.SCAN_ROOTS, "script_matches": len(rows), "counts": counts,
    "demo_registry": registry["artifacts"]["interactable_demo"],
    "placements": placements, "routes": http,
    "demo_json_variants": len(list((ROOT / "commons/interactables/demo_configs/auto").glob("*.json"))),
    "sources": manifest}
(OUT / "snapshot.json").write_text(json.dumps(facts, indent=2), encoding="utf-8")
print(json.dumps({k: facts[k] for k in ["script_matches", "counts", "placements", "routes", "demo_json_variants"]}, indent=2))
