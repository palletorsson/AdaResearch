class_name InventoryHand
extends Node
## The bracelet's PLACE mode: which inventory item the hand produces (or none), each item's knob values, and the
## making of it. Trigger spawns the current item into the hand as a pickable (an InventoryCarrier round the
## artifact, or the artifact itself when it is a pickable, like a roll of tape); let go and it settles (see the
## carrier). Grip takes the last one back. The web page's hand (hand.json: {item, config}) is watched once a
## second, so a choice made in the browser lands here; the panel's ITEMS tab is the same choice made in VR.

const Items = preload("res://commons/player/inventory_items.gd")   # by path: a new class_name is not in the cache until the editor scans
const Carrier = preload("res://commons/player/inventory_carrier.gd")

signal item_changed(id: String)
signal config_changed(id: String, cfg: Dictionary)

var current := ""                 # item id, "" = none
var values: Dictionary = {}       # id -> {knob key: value}, over the item's defaults
var placed: Array[Node3D] = []
var held: Node3D = null
var lab: Node = null              # answers is_sequence_completed; null = all unlocked
var _hand_stamp := -1
var _hand_path := ""
var _since := 0.0

func _process(delta: float) -> void:
	_since += delta
	if _since < 1.0:return
	_since = 0.0
	var path := Items.hand_path();var stamp := FileAccess.get_modified_time(path)
	if path != _hand_path or (stamp != 0 and stamp != _hand_stamp):_read_hand()

## The web page's hand: {item, config: {id: {...}}}; an unknown or locked item is left alone.
func _read_hand() -> void:
	_hand_path = Items.hand_path();_hand_stamp = FileAccess.get_modified_time(_hand_path)
	if not FileAccess.file_exists(_hand_path):return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_hand_path))
	if not data is Dictionary:return
	var cfgs: Variant = data.get("config", {})
	if cfgs is Dictionary:
		for id in cfgs:
			if cfgs[id] is Dictionary:
				values[str(id)] = (cfgs[id] as Dictionary).duplicate()
				config_changed.emit(str(id), config_for(str(id)))
				if is_instance_valid(held) and held.has_method("apply_config") and str(held.get("item").get("id", "")) == str(id):held.apply_config(config_for(str(id)))
	var want := str(data.get("item", current))
	if want != current and (want == "" or (not Items.item(want).is_empty() and Items.unlocked(Items.item(want), lab))):
		current = want;item_changed.emit(current)

## The items as the panel lists them.
func available() -> Array:
	var out := []
	for it in Items.items():
		var id := str(it.get("id", ""))
		out.append({"id": id, "name": str(it.get("name", id)), "unlocked": Items.unlocked(it, lab), "coming": str(it.get("coming", "")), "knobs": it.get("knobs", []), "values": config_for(id)})
	return out

func set_current(id: String) -> void:
	if id != "" and (Items.item(id).is_empty() or not Items.unlocked(Items.item(id), lab)):return
	if id == current:return
	current = id;item_changed.emit(current)

func set_knob(key: String, value: Variant) -> void:
	if current == "":return
	if not values.has(current):values[current] = {}
	values[current][key] = value
	var cfg := config_for(current);config_changed.emit(current, cfg)
	if is_instance_valid(held) and held.has_method("apply_config"):held.apply_config(cfg)

func config_for(id: String) -> Dictionary:
	return Items.config_for(Items.item(id), values.get(id, {}))

## Make the current item at a transform (the hand's, or in front of a desktop camera) and return it, or null.
func spawn_at(xform: Transform3D) -> Node3D:
	if current == "":return null
	var it := Items.item(current)
	if it.is_empty() or str(it.get("coming", "")) != "":return null
	var cfg := config_for(current);var node: Node3D = null
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path):return null
	var probe := load(path);var inst: Node = probe.instantiate()
	if inst is XRToolsPickable:   # a pickable of its own (a roll of tape): held as it is
		for k in cfg:inst.set_meta("config_%s" % str(k), cfg[k])
		if inst.has_method("apply_grid_config"):inst.apply_grid_config(cfg)
		node = inst;node.name = "Held_" + current
	else:
		inst.free()
		var carrier := Carrier.new()
		get_tree().current_scene.add_child(carrier);carrier.global_transform = xform
		if not carrier.build(it, cfg):carrier.queue_free();return null
		node = carrier
	if node.get_parent() == null:get_tree().current_scene.add_child(node)
	node.global_transform = xform
	placed.append(node);return node

## Make the current item in a controller's hand: picked up at once by that hand's pickup function; with no
## pickup (a desktop), left 0.35 m ahead of the hand and settled.
func spawn_in(controller: Node3D) -> Node3D:
	var ahead := controller.global_transform.translated_local(Vector3(0, 0, -.35))
	var node := spawn_at(ahead)
	if node == null:return null
	var pk: Node = XRToolsFunctionPickup.find_instance(controller) if controller is XRController3D else null
	if pk != null and pk.has_method("_pick_up_object"):
		node.set("freeze", true);pk._pick_up_object(node)
		if node.has_method("is_picked_up") and node.is_picked_up():held = node;return node
	if node.has_method("settle"):node.settle()
	return node

func remove_last() -> Node3D:
	while not placed.is_empty():
		var n: Node3D = placed.pop_back()
		if is_instance_valid(n):
			if n.has_method("is_picked_up") and n.is_picked_up() and n.has_method("drop"):n.drop()
			n.queue_free();return n
	return null
