extends RefCounted
class_name ArtifactQueue

## Builds a flat, ordered review queue of artifact lookup_names — NO map_data.json.
##
## Source: the ten concept-map docs (doc/*_concept_map.json), flattened in
## curriculum order → concept order → tier order (small→medium→large→applied).
## Each entry is { name, section } where section = "<map> · <concept>" so the
## runner can show a header per chunk.
##
## This is just a name list; the runner resolves name → scene from the registries.

# Ten concept maps, curriculum order. Doc files live at res://doc/<x>_concept_map.json.
const MAPS := [
	["vector_forces", "Vectors"],
	["randomness", "Randomness"],
	["ca", "Cellular Automata"],
	["lsystem", "L-systems"],
	["fractal", "Fractals"],
	["softbody", "Soft bodies"],
	["procgen", "Procgen"],
	["foundations", "Foundations"],
	["qfep", "QFEP"],
	["postcrisis", "Post-Crisis"],
]
const TIERS := ["small", "medium", "large", "applied"]


static func _read_doc(stub: String) -> Dictionary:
	var path := "res://doc/%s_concept_map.json" % stub
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


## Returns Array of { "name": String, "section": String }, in review order.
## only_maps: if non-empty, restrict to those map stubs (e.g. ["foundations","qfep"]).
## shuffle: if true, shuffle within each map (keeps map grouping, varies order).
static func build(only_maps: Array = [], shuffle: bool = false) -> Array:
	var out: Array = []
	var seen := {}
	for pair in MAPS:
		var stub: String = pair[0]
		var label: String = pair[1]
		if not only_maps.is_empty() and not (stub in only_maps):
			continue
		var doc := _read_doc(stub)
		if doc.is_empty():
			continue
		var concepts: Array = doc.get("concepts", [])
		var meta: Dictionary = doc.get("concept_meta", {})
		var map_entries: Array = []
		for concept in concepts:
			var cm: Dictionary = meta.get(concept, {})
			var tiers: Dictionary = cm.get("tiers", {})
			for tier in TIERS:
				for name in tiers.get(tier, []):
					var n := str(name)
					if seen.has(n):
						continue
					seen[n] = true
					map_entries.append({"name": n, "tier": tier, "section": "%s · %s" % [label, str(concept)]})
		if shuffle:
			map_entries.shuffle()
		out.append_array(map_entries)
	return out


## All registry artifacts (fallback): every lookup_name with a scene, by registry.
static func build_all_registry() -> Array:
	var out: Array = []
	var seen := {}
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return out
	for fn in dir.get_files():
		if not fn.ends_with(".json"):
			continue
		var f := FileAccess.open("res://commons/artifacts/registry/" + fn, FileAccess.READ)
		if f == null:
			continue
		var data = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		var arts: Dictionary = data.get("artifacts", {})
		for k in arts.keys():
			var v = arts[k]
			if not (v is Dictionary) or not v.has("scene"):
				continue
			var n := str(v.get("lookup_name", k))
			if seen.has(n):
				continue
			seen[n] = true
			out.append({"name": n, "section": fn.replace(".json", "")})
	return out
