extends RefCounted
class_name ArtifactPalette

## The biome's catalogue of placeable ARTIFACTS — every registered artifact mapped
## to its scene + its curriculum unlock stage. The `object_scatter` layer uses this
## to drop pop-art / prefab / DNA / mesh / debris artifacts into a map, and the
## available palette WIDENS as the spine progresses: an artifact unlocks at the
## spine `order` of its `sequence` (artifacts with no spine sequence are available
## from the start). Scanned once from commons/artifacts/registry/*.json +
## curriculum_spine.json, cached. See doc/PAINT_LAYERS.md § Object scatter.

const REGISTRY_DIR := "res://commons/artifacts/registry/"
const SPINE_PATH := "res://commons/maps/curriculum_spine.json"

static var _scene_by_name: Dictionary = {}   # name -> scene path
static var _order_by_name: Dictionary = {}   # name -> unlock stage_order
static var _cat_by_name: Dictionary = {}     # name -> registry category
static var _loaded: bool = false


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	var seq_order: Dictionary = _load_spine_orders()
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return
	for fname in dir.get_files():
		if not fname.ends_with(".json"):
			continue
		var f := FileAccess.open(REGISTRY_DIR + fname, FileAccess.READ)
		if f == null:
			continue
		var json := JSON.new()
		var ok := json.parse(f.get_as_text()) == OK
		f.close()
		if not ok or not (json.data is Dictionary):
			continue
		var arts = (json.data as Dictionary).get("artifacts", {})
		if not (arts is Dictionary):
			continue
		for name in arts:
			var e = arts[name]
			if not (e is Dictionary):
				continue
			var scene := str(e.get("scene", e.get("scene_path", "")))
			if scene == "":
				continue
			_scene_by_name[name] = scene
			# Unlock = the spine order of the artifact's sequence; no/unknown
			# sequence → 1 (available from the start, e.g. lab props, branches).
			var seq := str(e.get("sequence", ""))
			_order_by_name[name] = int(seq_order.get(seq, 1))
			_cat_by_name[name] = str(e.get("category", "misc")).strip_edges() if str(e.get("category", "")) != "" else "misc"


static func _load_spine_orders() -> Dictionary:
	var out: Dictionary = {}
	if not FileAccess.file_exists(SPINE_PATH):
		return out
	var f := FileAccess.open(SPINE_PATH, FileAccess.READ)
	if f == null:
		return out
	var json := JSON.new()
	var ok := json.parse(f.get_as_text()) == OK
	f.close()
	if ok and json.data is Dictionary:
		var seqs = (json.data as Dictionary).get("spine", {}).get("sequences", [])
		if seqs is Array:
			for s in seqs:
				if s is Dictionary:
					out[str(s.get("name", ""))] = int(round(float(s.get("order", 1))))
	return out


## The PackedScene for an artifact name, or null if unknown/missing.
static func scene_for(name: String) -> PackedScene:
	_ensure()
	var p := str(_scene_by_name.get(name, ""))
	if p == "" or not ResourceLoader.exists(p):
		return null
	var r = ResourceLoader.load(p)
	return r if r is PackedScene else null


## The stage_order at which `name` becomes available (1 = from the start).
static func unlock_order(name: String) -> int:
	_ensure()
	return int(_order_by_name.get(name, 1))


static func has(name: String) -> bool:
	_ensure()
	return _scene_by_name.has(name)


## Every artifact whose unlock_order ≤ `stage_order` — the palette at that point
## in the spine. (Large; for an editor picker, filter by category.)
static func available(stage_order: int) -> Array:
	_ensure()
	var out: Array = []
	for name in _order_by_name:
		if int(_order_by_name[name]) <= stage_order:
			out.append(name)
	return out


static func count() -> int:
	_ensure()
	return _scene_by_name.size()


## The registry category of an artifact ("misc" if untagged).
static func category_of(name: String) -> String:
	_ensure()
	return str(_cat_by_name.get(name, "misc"))


## All categories that have at least one artifact unlocked at `stage_order`, sorted.
## The VR picker browses by these (no keyboard needed).
static func categories(stage_order: int = 9999) -> Array:
	_ensure()
	var seen: Dictionary = {}
	for name in _cat_by_name:
		if int(_order_by_name.get(name, 1)) <= stage_order:
			seen[str(_cat_by_name[name])] = true
	var out: Array = seen.keys()
	out.sort()
	return out


## Artifact names in `cat` unlocked at `stage_order`, sorted (the picker's page set).
static func names_in_category(cat: String, stage_order: int = 9999) -> Array:
	_ensure()
	var out: Array = []
	for name in _cat_by_name:
		if str(_cat_by_name[name]) == cat and int(_order_by_name.get(name, 1)) <= stage_order:
			out.append(name)
	out.sort()
	return out
