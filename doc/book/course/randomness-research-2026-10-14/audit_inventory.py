"""Snapshot the current hall/registry/scene chain. Static evidence, not a runtime test."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SEQUENCES = ("randomness", "noise", "particles")
CANDIDATES = (
    "blue_noise", "blue_noise_toy", "blue_noise_bench", "blue_noise_planter",
    "lyapunov_bench", "lyapunov_exponents", "edge_of_chaos_bench",
    "percolation_ca", "markov_chains", "markov_melody",
    "living_paper_brownian", "living_paper_levy", "grammar_bench",
    "grammar_provenance", "graph_grammar_station", "markov_blanket_room",
    "entropy_bellows", "particle_chaos", "entropy_morphogenesis",
)
receipts = {}


def read(path):
    path = Path(path)
    raw = path.read_bytes()
    receipts[path.relative_to(ROOT).as_posix()] = hashlib.sha256(raw).hexdigest()
    return raw.decode("utf-8-sig")


def data(path):
    return json.loads(read(path))


def keys_for(m):
    result = {}
    for z, row in enumerate(m.get("layers", {}).get("interactables", [])):
        for x, value in enumerate(row):
            if not isinstance(value, str) or value.strip() in ("", "0"):
                continue
            key = value.split("#", 1)[0].split(":", 1)[0]
            result.setdefault(key, []).append({"x": x, "z": z, "cell": value})
    return result


def scene_evidence(scene):
    if not scene or not scene.startswith("res://"):
        return {"scene": scene, "exists": False}
    p = ROOT / scene[6:]
    found = {"scene": scene, "exists": p.is_file(), "direct_scripts": []}
    if not p.is_file():
        return found
    text = read(p)
    for script in sorted(set(re.findall(r'path="(res://[^"\n]+\.gd)"', text))):
        sp = ROOT / script[6:]
        item = {"path": script, "exists": sp.is_file()}
        if sp.is_file():
            source = read(sp)
            item.update({
                "lines": len(source.splitlines()),
                "functions": re.findall(r"^func ([A-Za-z0-9_]+)", source, re.M),
                "uses_global_draws": bool(re.search(r"(?<![.\w])rand[fi](?:_range)?\(", source)),
                "has_local_rng": "RandomNumberGenerator" in source,
                "uses_frame_process": "func _process(" in source,
                "uses_physics_process": "func _physics_process(" in source,
                "uses_wall_clock": "Time.get_ticks" in source,
                "inspection": "Static markers only; not a semantic or runtime verdict",
            })
        found["direct_scripts"].append(item)
    return found


def main():
    registry = {}
    for p in sorted((ROOT / "commons/artifacts/registry").glob("*.json")):
        for key, value in data(p).get("artifacts", {}).items():
            if isinstance(value, dict):
                registry.setdefault(key, []).append({
                    "registry": p.relative_to(ROOT).as_posix(),
                    "name": value.get("name", key),
                    "description": value.get("description", ""),
                    **scene_evidence(value.get("scene", ""))
                })
    # Placement lookup is descriptive, including off-spine halls. It is not route reachability.
    placements = {}
    for p in sorted((ROOT / "commons/maps").glob("*/map_data.json")):
        try:
            m = json.loads(p.read_text(encoding="utf-8-sig"))
        except (ValueError, UnicodeError):
            continue
        for key in keys_for(m):
            placements.setdefault(key, []).append(p.parent.name)
    declaration = data(ROOT / "commons/data/map_authored.json")
    live_plan = data(ROOT / "commons/data/museum/em_plan.json")
    museum_routes = {}
    halls = []
    orders = {}
    for seq in SEQUENCES:
        s = data(ROOT / f"commons/maps/sequences/{seq}.json")["sequences"][seq]
        orders[seq] = s["maps"]
        live_rows = [x for x in live_plan["plans"] if x.get("sequence") == seq]
        declared_maps = declaration.get(seq, [])
        museum_routes[seq] = {"declared_maps": declared_maps,
                              "live_maps": [x.get("map") for x in live_rows],
                              "sequence_only": [x for x in s["maps"] if x not in declared_maps],
                              "museum_only": [x for x in declared_maps if x not in s["maps"]],
                              "artifact_key_differences": []}
        inspected_maps = s["maps"] + [x for x in declared_maps if x not in s["maps"]]
        for index, name in enumerate(inspected_maps, 1):
            folder = ROOT / "commons/maps" / name
            m = data(folder / "map_data.json")
            texts = {}
            for filename in ("final.md", "tutorial.md", "intent.md", "summary.md", "blurb.md"):
                if (folder / filename).exists():
                    body = read(folder / filename)
                    texts[filename] = {"words": len(body.split()), "opening": body[:450]}
            map_keys = set(keys_for(m))
            for row in [x for x in live_rows if x.get("map") == name]:
                live_keys = {x["token"].split("#", 1)[0].split(":", 1)[0] for x in row.get("artifacts", [])}
                if live_keys != map_keys:
                    museum_routes[seq]["artifact_key_differences"].append({"map": name,
                        "only_in_map": sorted(map_keys-live_keys), "only_in_live_plan": sorted(live_keys-map_keys)})
            halls.append({"map": name, "sequence": seq, "order": index,
                          "in_sequence": name in s["maps"],
                          "museum_order": declared_maps.index(name)+1 if name in declared_maps else None,
                          "dimensions": m.get("map_info", {}).get("dimensions"),
                          "texts": texts,
                          "artifacts": [{"key": k, "placements": v,
                                         "registrations": registry.get(k, [])}
                                        for k, v in sorted(keys_for(m).items())]})
    selected_keys = {a["key"] for h in halls for a in h["artifacts"]}
    candidates = [{"key": k, "registrations": registry.get(k, []),
                   "map_placements": placements.get(k, [])} for k in CANDIDATES]
    for relative in ("project.godot", "commons/maps/curriculum_spine.json",
                     "commons/managers/GridArtifactRegistry.gd", "core/particle.gd",
                     "core/particle_emitter.gd", "core/particle_body.gd",
                     "core/confetti_particle.gd", "doc/tasks/_schema.md",
                     "doc/book/course/functional_text/RECONSTRUCTION.md",
                     "doc/book/course/uncertainty-plan/PLAN.md",
                     "doc/book/course/randomness-revision/PLAN.md",
                     "commons/maps/PG_Genetic_Evolution/tutorial.md",
                     "commons/maps/QFEP_Sandbox/tutorial.md"):
        read(ROOT / relative)
    # Keep receipts scoped to inspected halls, their registrations/scenes/scripts and selected references.
    relevant = {"commons/maps/sequences/" + s + ".json" for s in SEQUENCES}
    for h in halls:
        relevant.update(p for p in receipts if p.startswith("commons/maps/" + h["map"] + "/"))
    selected = [r for k in selected_keys.union(CANDIDATES) for r in registry.get(k, [])]
    for r in selected:
        relevant.add(r["registry"])
        relevant.add(r["scene"].removeprefix("res://"))
        relevant.update(x["path"].removeprefix("res://") for x in r["direct_scripts"])
    relevant.update(p for p in receipts if p in ("project.godot", "commons/maps/curriculum_spine.json",
                    "commons/managers/GridArtifactRegistry.gd") or p.startswith(("core/particle", "core/confetti", "doc/")))
    relevant.update(("commons/maps/PG_Genetic_Evolution/tutorial.md", "commons/maps/QFEP_Sandbox/tutorial.md",
                     "commons/data/map_authored.json", "commons/data/museum/em_plan.json"))
    missing = sorted(k for k in selected_keys if not registry.get(k))
    absent_scenes = sorted({r["scene"] for r in selected if not r["exists"]})
    report = {
        "date": "2026-10-14", "method": "Static current-working-tree inventory; no Godot, headset, or learner test",
        "git_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "working_tree": "Contains pre-existing edits; HEAD alone does not identify inspected content",
        "coverage": {"halls": len(halls), "distinct_placed_artifacts": len(selected_keys),
                     "hall_artifact_pairs": sum(len(h["artifacts"]) for h in halls),
                     "missing_registry_keys": missing, "missing_selected_scenes": absent_scenes},
        "orders": orders, "museum_routes": museum_routes, "halls": halls, "additional_candidates": candidates,
        "duplicate_registration_keys": {k: [r["registry"] for r in registry[k]]
                                        for k in sorted(selected_keys) if len(registry.get(k, [])) > 1},
        "source_sha256": {p: receipts[p] for p in sorted(relevant) if p in receipts},
    }
    (HERE / "inventory.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    md = ["# Current inventory", "", "14 October 2026. Generated from the working tree by `audit_inventory.py`.", "",
          "Static coverage of every artifact cell in the 14 randomness, 11 noise and 5 particle sequence halls, plus the museum-only Biome Cage interlude. "
          "A resolving scene is evidence of availability, not tested behaviour. Direct script markers are only search aids. "
          "Shared support artifacts are included; blank cells and `0` placeholders are excluded. "
          "Registry duplicates are retained rather than silently choosing a winner. "
          "The JSON stores exact placement/configuration cells, direct scripts and source hashes.", "",
          f"**{len(halls)} halls · {len(selected_keys)} distinct placed artifacts · {report['coverage']['hall_artifact_pairs']} hall/artifact pairs.**", "",
          f"Missing registry keys: {missing or 'none'}. Missing selected scene files: {absent_scenes or 'none'}.", "",
          "## Sequence versus Endless Museum", "",
          "The current museum declaration/plan has 15 randomness spaces (including Biome_Cage), 10 noise spaces (Lab_Path is absent), "
          "and no particle chapter. Particle scenes/maps exist as a branch, but are not currently a live Endless Museum chapter. "
          "The proposal must explicitly integrate that route. This is a comparison of configuration files, not a walk through the running museum.", ""]
    for seq, route in museum_routes.items():
        md.append(f"- {seq}: sequence-only {route['sequence_only']}; museum-only {route['museum_only']}; map/live artifact-key differences: {route['artifact_key_differences'] or 'none'}.")
    md.append("")
    for seq in SEQUENCES:
        md.extend([f"## {seq.capitalize()}", ""])
        for h in [x for x in halls if x["sequence"] == seq]:
            md.extend([f"### {h['order']:02}. {h['map']}", "",
                       f"Sequence member: {h['in_sequence']}; museum declaration position: {h['museum_order'] or 'absent'}.", "",
                       "Texts: " + ", ".join(f"{k} ({v['words']} words)" for k,v in h["texts"].items()) + ".", "",
                       "| Artifact | Scene / evidence |", "| --- | --- |"])
            for a in h["artifacts"]:
                rows = a["registrations"]
                evidence = "; ".join(f"`{r['scene']}` ({'exists' if r['exists'] else 'MISSING'})" for r in rows) or "UNRESOLVED"
                md.append(f"| `{a['key']}` | {evidence} |")
            md.append("")
    md.extend(["## Further reuse candidates", "", "These are outside the selected hall inventory, or alternative implementations. Placement is not evidence of readiness.", "",
               "| Candidate | Existing placements | Scene |", "| --- | --- | --- |"])
    for c in candidates:
        names = ", ".join(c["map_placements"]) or "No map_data placement found"
        scenes = "; ".join("`" + r["scene"] + "`" for r in c["registrations"]) or "UNRESOLVED"
        md.append(f"| `{c['key']}` | {names} | {scenes} |")
    (HERE / "INVENTORY.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(json.dumps(report["coverage"], ensure_ascii=False))


if __name__ == "__main__":
    main()
