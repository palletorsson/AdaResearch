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

## Unlocked: no unlock, or the sequence is completed (LabManager / MapProgressionManager answer; neither = unlocked).
## In the Void (`void_game`, its `checkpoint` floor) an item with `floor` is unlocked once that floor is reached; in a
## grid map, once its `unlock` sequence is completed (LabManager); with neither authority, unlocked.
static func unlocked(it: Dictionary, lab: Node, void_game: Node = null) -> bool:
	if void_game != null and int(it.get("floor", 0)) > 0:return int(void_game.get("checkpoint")) >= int(it.get("floor", 0))
	var seq := str(it.get("unlock", ""))
	if seq == "":return true
	if lab != null and lab.has_method("is_sequence_completed"):return bool(lab.is_sequence_completed(seq))
	return true

## The scene a registry token names, scanning the registry files once.
static func scene_for(token: String) -> String:
	if token == "":return ""
	if _scenes.is_empty():
		var dir := DirAccess.open("res://commons/artifacts/registry/")
		if dir:
			dir.list_dir_begin()
			var f := dir.get_next()
			while f != "":
				if not dir.current_is_dir() and f.ends_with(".json"):
					var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry/" + f))
					if d is Dictionary:
						for src in [d, d.get("artifacts", {})]:
							if src is Dictionary:
								for k in src:
									if src[k] is Dictionary and src[k].has("scene"):_scenes[str(k)] = str(src[k].scene)
				f = dir.get_next()
	return str(_scenes.get(token, ""))
