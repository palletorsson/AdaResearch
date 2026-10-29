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

## Unlocked: no unlock, or the sequence is completed (LabManager / MapProgressionManager answer; neither = unlocked).
static func unlocked(it: Dictionary, lab: Node) -> bool:
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
