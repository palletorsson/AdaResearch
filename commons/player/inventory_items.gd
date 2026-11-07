class_name InventoryItems
extends RefCounted
## The inventory's items: commons/data/inventory/items.json, the file the encyclopedia's /catalyst-inventory
## prism reads too (tools/inventory_check.py gates it against the code). A copy at user://inventory/items.json is
## read first, where a headset's copy will land. hand.json beside it is the web page's hand: {item, config},
## written by the page, watched by InventoryHand once a second.

const ITEMS_RES := "res://commons/data/inventory/items.json"
const ITEMS_USER := "user://inventory/items.json"
const HAND_RES := "res://commons/data/inventory/hand.json"
const HAND_USER := "user://inventory/hand.json"

static var _items: Array = []
static var _items_path := ""
static var _items_stamp := -1
static var _scenes: Dictionary = {}   # token -> scene path, from commons/artifacts/registry/*.json

static func items_path() -> String:
	return ITEMS_USER if FileAccess.file_exists(ITEMS_USER) else ITEMS_RES

static func hand_path() -> String:
	return HAND_USER if FileAccess.file_exists(HAND_USER) else HAND_RES

## The items, re-read when the file changes.
static func items() -> Array:
	var path := items_path()
	var stamp := FileAccess.get_modified_time(path)
	if path == _items_path and stamp == _items_stamp and not _items.is_empty():
		return _items
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if data is Dictionary and data.get("items") is Array:
		_items = data.items;_items_path = path;_items_stamp = stamp
	return _items

static func item(id: String) -> Dictionary:
	for it in items():
		if str(it.get("id", "")) == id:return it
	return {}

## An item's config as the artifact receives it: the item's own defaults under the hand's values, each value
## in the shape its knob declares - a true/false choice as a bool (bool("false") is TRUE in GDScript, so a
## string here would turn a knob on in silence), a range as a float, a choice or text as a string.
static var _costs: Dictionary = {}

## The hall's budget for placed things (items.json "budget"); empty = no budget.
static func budget() -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(items_path()))
	return (d.get("budget", {}) as Dictionary).duplicate() if d is Dictionary and d.get("budget") is Dictionary else {}

## What one of an item costs (commons/data/inventory/costs.json, measured by probe_inventory_cost.gd), by id.
static func cost_of(id: String) -> Dictionary:
	if _costs.is_empty():
		var path := items_path().get_base_dir().path_join("costs.json")
		if FileAccess.file_exists(path):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if d is Dictionary:
				for row in d.get("items", []):
					if row is Dictionary and row.has("id"):_costs[str(row.id)] = row
	var c: Dictionary = _costs.get(id, {})
	return {"draws": int(c.get("draws", 1)), "triangles": int(c.get("triangles", 0)), "lights": int(c.get("lights", 0)), "viewports": int(c.get("viewports", 0))}

static func config_for(it: Dictionary, values: Dictionary) -> Dictionary:
	var cfg: Dictionary = (it.get("defaults", {}) as Dictionary).duplicate()
	var knobs: Dictionary = {}
	for k in it.get("knobs", []):knobs[str(k.get("key", ""))] = k
	for k in values:
		var v: Variant = values[k];var knob: Dictionary = knobs.get(str(k), {})
		if knob.has("choices") and (knob.choices as Array).all(func(c):return str(c) in ["true", "false"]):v = str(v) == "true"
		elif knob.has("range"):v = float(v)
		elif knob.has("choices") or knob.has("text"):v = str(v)
		cfg[k] = v
	return cfg

static var _bench: Dictionary = {}
static var _bench_stamp := -1

## THE BENCH'S STAGE (commons/data/inventory/workbench.json): in the Void, the stage with the highest from_floor at or
## under the checkpoint floor; outside it, `default`. {name, snap: grid|contact, grid, grid_y}. Empty if the file is gone.
static func stage(void_game: Node = null) -> Dictionary:
	var path := items_path().get_base_dir().path_join("workbench.json")
	var stamp := FileAccess.get_modified_time(path)
	if _bench.is_empty() or stamp != _bench_stamp:
		_bench_stamp = stamp
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_bench = d if d is Dictionary else {}
	if _bench.is_empty():return {}
	var out: Dictionary = (_bench.get("default", {}) as Dictionary).duplicate()
	if void_game != null:
		var floor_now := int(void_game.get("checkpoint"))
		var best := -1
		for st in _bench.get("stages", []):
			var from := int(st.get("from_floor", 0))
			if from <= floor_now and from > best:best = from;out = (st as Dictionary).duplicate()
	return out

## THE COLLECTED (Palle, 2026-11-04: "when we pick up the object it should be added to the inventory"): the ids of the
## items whose example the person has picked up, in the order taken - the hand's belt, which the left thumbstick click
## steps through. Kept in user://, so a game started again still holds them. A probe points `collected_path` elsewhere.
const COLLECTED_USER := "user://inventory/collected.json"
static var collected_path := COLLECTED_USER
static var _collected: Array = []
static var _collected_read := ""

static func collected() -> Array:
	if _collected_read != collected_path:
		_collected_read = collected_path;_collected = []
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(collected_path)) if FileAccess.file_exists(collected_path) else null
		if d is Dictionary and d.get("collected") is Array:
			for id in d.collected:
				if not item(str(id)).is_empty() and not _collected.has(str(id)):_collected.append(str(id))
	return _collected

static func is_collected(id: String) -> bool:
	return collected().has(id)

## Add an item to the collected; true if it was new. Written at once (tmp + rename): a crash must not lose a pick-up.
static func collect(id: String) -> bool:
	if item(id).is_empty() or is_collected(id):return false
	_collected.append(id)
	var abs_path := ProjectSettings.globalize_path(collected_path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var f := FileAccess.open(abs_path + ".tmp", FileAccess.WRITE)
	if f == null:push_warning("inventory: could not write " + abs_path);return true
	f.store_string(JSON.stringify({"version": 1, "collected": _collected}, "  ") + "\n");f.close()
	if FileAccess.file_exists(abs_path):DirAccess.remove_absolute(abs_path)
	DirAccess.rename_absolute(abs_path + ".tmp", abs_path)
	return true

## Unlocked: no unlock, or the sequence is completed (LabManager / MapProgressionManager answer; neither = unlocked).
## In the Void (`void_game`, its `checkpoint` floor) an item with `floor` is unlocked once that floor is reached; in a
## grid map, once its `unlock` sequence is completed (LabManager); with neither authority, unlocked.
## An item marked "collect" is unlocked by picking up its example (an association_plinth), wherever it is.
static func unlocked(it: Dictionary, lab: Node, void_game: Node = null) -> bool:
	if bool(it.get("collect", false)):return is_collected(str(it.get("id", "")))
	if void_game != null and int(it.get("floor", 0)) > 0:return int(void_game.get("checkpoint")) >= int(it.get("floor", 0))
	var seq := str(it.get("unlock", ""))
	if seq == "":return true
	if lab != null and lab.has_method("is_sequence_completed"):return bool(lab.is_sequence_completed(seq))
	return true

## The scene a registry token names, scanning the registry files once.
static func scene_for(token: String) -> String:
	if token == "":return ""
	if _scenes_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_scenes_task)   # a worker task must be waited to be released
		_scenes_task = -1
	if _scenes.is_empty():_scenes = _read_scenes()
	return str(_scenes.get(token, ""))

## The token -> scene table (2026-11-07, the arrival stutter: the first scene_for of a session parsed every registry
## file, ~500 ms, on the main thread - a vending machine's first _ready). The Void's registry index reads those files
## once on a worker thread (floor_content._build_registry_index) and offers the table here; warm_scenes is for a game
## without it. scene_for waits for a running warm; without an offer or a warm it reads the files itself.
static var _scenes_task := -1

static func warm_scenes() -> void:
	if _scenes_task < 0 and _scenes.is_empty():
		_scenes_task = WorkerThreadPool.add_task(func(): _scenes = _read_scenes(), false, "inventory scene table")

static func offer_scenes(table: Dictionary) -> void:
	if _scenes.is_empty() and _scenes_task < 0: _scenes = table

## One registry file's tokens with a scene, into `out` (both layouts: top-level tokens and an "artifacts" dict).
static func collect_scenes(d: Dictionary, out: Dictionary) -> void:
	for src in [d, d.get("artifacts", {})]:
		if src is Dictionary:
			for k in src:
				if src[k] is Dictionary and src[k].has("scene"):out[str(k)] = str(src[k].scene)

static func _read_scenes() -> Dictionary:
	var out := {}
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if not dir.current_is_dir() and f.ends_with(".json"):
				var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry/" + f))
				if d is Dictionary:collect_scenes(d, out)
			f = dir.get_next()
	return out
