"""Build a bounded reading snapshot. Never modifies museum, Void or web sources."""
from pathlib import Path
import datetime, hashlib, json, re, shutil, sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
WEB = ROOT.parent / "ada_encyclopedia"
MAPS = ["Random_Definition", "Random_Noise_Types", "Noise_Columns", "Noise_One"]
SOURCES = OUT / "sources"
sys.stdout.reconfigure(encoding="utf-8")

def read(p):
    return json.loads((ROOT / p).read_text(encoding="utf-8-sig"))

registry = {}
for p in sorted((ROOT / "commons/artifacts/registry").glob("*.json")):
    try:
        for key, entry in json.loads(p.read_text(encoding="utf-8-sig")).get("artifacts", {}).items():
            for token in {key, entry.get("lookup_name", key)}:
                registry.setdefault(token, (p.relative_to(ROOT).as_posix(), entry))
    except (ValueError, TypeError):
        continue

selected = {
    "commons/maps/curriculum_spine.json",
    "commons/maps/sequences/randomness.json", "commons/maps/sequences/noise.json",
    "commons/void/layout.json", "commons/void/rooms.schema.json",
    "commons/void/floor_content.gd", "commons/void/lines_area.gd",
    "commons/void/primitive_hall.gd", "commons/void/trace_area.gd",
    "commons/void/architecture.gd", "commons/void/cliff_landings.gd",
    "commons/void/trials/briefs.json", "commons/void/trials/playable.json",
    "commons/void/trials/transformation/trial.tscn",
    "commons/void/trials/transformation/rooms.json",
    "commons/void/trials/transformation/layout.json",
    "commons/void/README.md", "commons/void/trials/README.md",
    "commons/artifacts/randomness_space/hall_seed.gd",
    "algorithms/randomness/seed_replay/editor_parts.gd",
    "tools/void_sequence_trials.py", "tools/export_void_trial.py",
    "tools/void_trial_runtime.py", "tools/test_void_trial.py",
    "tools/test_random_definition_lesson.py", "tools/test_noise_opening.py",
    "tools/test_noise_columns.py",
}
inventory = []
for name in MAPS:
    data = read(f"commons/maps/{name}/map_data.json")
    for fn in ["map_data.json", "tutorial.md", "final.md"]:
        selected.add(f"commons/maps/{name}/{fn}")
    entries = {}
    for layer in ["interactables", "utilities"]:
        for z, row in enumerate(data.get("layers", {}).get(layer, [])):
            for x, raw in enumerate(row):
                if not isinstance(raw, str):
                    continue
                token = raw.split("#")[0].split(":")[0].strip()
                if token not in registry:
                    continue
                reg_path, entry = registry[token]
                scene = str(entry.get("scene", "")).removeprefix("res://")
                if token not in entries:
                    scripts = []
                    if scene and (ROOT / scene).is_file():
                        scripts = re.findall(r'path="res://([^"]+\.gd)"', (ROOT / scene).read_text(encoding="utf-8-sig"))
                        selected.add(scene)
                        selected.update(scripts)
                    entries[token] = {
                        "id": token, "scene": scene, "scripts": scripts,
                        "registry_path": reg_path, "registry_entry": entry, "placements": [],
                    }
                entries[token]["placements"].append({"layer": layer, "grid_cell": [x,z], "raw_token": raw})
    inventory.append({"map": name, "map_info": data["map_info"], "artifacts": list(entries.values())})

# One textual dependency hop captures important parent scripts and local helpers;
# this is deliberately not a runnable dependency closure.
for relative in list(selected):
    p = ROOT / relative
    if p.suffix not in {".gd", ".tscn"} or not p.is_file():
        continue
    text = p.read_text(encoding="utf-8-sig")
    for ref in re.findall(r'"(res://[^"]+\.(?:gd|tscn|gdshader|json))"', text):
        selected.add(ref.removeprefix("res://"))
    for ref in re.findall(r'(?:preload|load)\("([^":]+\.(?:gd|tscn|gdshader|json))"\)', text):
        resolved = (p.parent / ref).resolve()
        if resolved.is_relative_to(ROOT):
            selected.add(resolved.relative_to(ROOT).as_posix())

manifest, missing = [], []
for relative in sorted(selected):
    p = ROOT / relative
    if not p.is_file():
        missing.append(relative)
        continue
    target = SOURCES / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(p, target)
    blob = p.read_bytes()
    manifest.append({"path": relative, "sha256": hashlib.sha256(blob).hexdigest(), "bytes": len(blob)})

# Registry entries are included individually in the inventory; don't copy the huge catalogue.
catalog = read("commons/void/catalog.json")
(OUT / "inventory.json").write_text(json.dumps({
    "captured_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "notice": "Source snapshot only; no runtime or headset verification.",
    "godot_root": str(ROOT), "web_root": str(WEB),
    "maps": inventory, "stations": catalog["stations"],
    "catalogue_note": "Exact registry entries are embedded per artifact; Void loader falls back to the modular registry.",
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(OUT / "source-manifest.json").write_text(json.dumps({
    "files": manifest, "missing_requested": missing,
    "scope": "Selected reading snapshot plus one dependency hop, not complete executable closure.",
}, indent=2) + "\n", encoding="utf-8")
index = ["# Source index", "", "All paths below are relative to `sources/`. Read the four tutorial/final pairs, then the actual scene scripts and configuration. Snapshot hashes are in source-manifest.json.", ""]
for m in inventory:
    index += [f"## {m['map']}", f"- commons/maps/{m['map']}/tutorial.md", f"- commons/maps/{m['map']}/final.md"]
    for a in m["artifacts"]:
        index.append(f"- `{a['id']}` → `{a['scene']}`; scripts: " + ", ".join(f"`{p}`" for p in a["scripts"]))
index += ["", "## Integration", "- commons/void/floor_content.gd", "- commons/void/rooms.schema.json", "- commons/void/trials/transformation/rooms.json", "- commons/artifacts/randomness_space/hall_seed.gd", "- algorithms/randomness/seed_replay/editor_parts.gd", "", "## Missing requested files", *[f"- {p}" for p in missing]]
(OUT / "source-index.md").write_text("\n".join(index) + "\n", encoding="utf-8")
(OUT / ".gdignore").touch()
(OUT / "runs").mkdir(exist_ok=True)
print(json.dumps({"maps": len(inventory), "artifacts": sum(len(m["artifacts"]) for m in inventory), "files":len(manifest), "bytes":sum(f["bytes"] for f in manifest), "missing":missing}, indent=2))
