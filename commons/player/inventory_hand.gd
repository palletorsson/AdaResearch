class_name InventoryHand
extends Node
## The bracelet's PLACE mode: which inventory item the hand produces (or none), each item's knob values, and the
## making of it. Trigger spawns the current item into the hand as a pickable (an InventoryCarrier round the
## artifact, or the artifact itself when it is a pickable); let go and it settles (see the carrier). Grip takes
## the last one back. An item that mounts "worn" (the tape) is not made: it is WORN, a bangle on the bracelet's
## controller (sync_worn), and the trigger and grip go to it: tape is laid from the hand without holding a roll. The web page's hand (hand.json: {item, config}) is watched once a
## second, so a choice made in the browser lands here; the panel's ITEMS tab is the same choice made in VR.

const Items = preload("res://commons/player/inventory_items.gd")   # by path: a new class_name is not in the cache until the editor scans
const Carrier = preload("res://commons/player/inventory_carrier.gd")

signal item_changed(id: String)
signal config_changed(id: String, cfg: Dictionary)

var current := ""                 # item id, "" = none
var values: Dictionary = {}       # id -> {knob key: value}, over the item's defaults
var placed: Array[Node3D] = []
var held: Node3D = null
var _worn: Dictionary = {}        # item id -> the node worn on the controller (mount "worn": the tape), made once
var _mini: Node3D = null          # the current item as a MINIATURE over the hand (Palle: "the current object must be a small version of the original")
var _mini_id := ""
const MINI := 0.10                # the miniature's longest side - the clock came out at 3 cm with its own scale folded in
var lab: Node = null              # answers is_sequence_completed; null = all unlocked
var _hand_stamp := -1
var _born: int = int(Time.get_unix_time_from_system()) - 1   # a hand.json older than this game is not applied unasked
var _hand_path := ""
var _since := 0.0

func _process(delta: float) -> void:
	_since += delta
	if _since < 1.0:return
	_since = 0.0
	var path := Items.hand_path();var stamp := FileAccess.get_modified_time(path)
	# first sight of a file written BEFORE this game started: its stamp is noted, its content is old news
	# (the choice made in VR stands); one written since - the page's SEND TO VR, the headset's copy - lands,
	# as does any change from here on
	if _hand_path == "" and stamp != 0 and stamp < _born:_hand_path = path;_hand_stamp = stamp;return
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
				_apply_worn(str(id))
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
	_apply_worn(current)

## A knob of an item that is not the one in the hand (the prism's TAPE face dresses the roll whatever is held).
func set_knob_for(id: String, key: String, value: Variant) -> void:
	if Items.item(id).is_empty():return
	if not values.has(id):values[id] = {}
	values[id][key] = value
	config_changed.emit(id, config_for(id))
	if id == current and is_instance_valid(held) and held.has_method("apply_config"):held.apply_config(config_for(id))
	_apply_worn(id)

## The node worn for an item whether or not it is the current one (the tape's roll keeps its strips and metres).
func worn_of(id: String) -> Node:
	var n: Node = _worn.get(id)
	return n if is_instance_valid(n) else null

func _apply_worn(id: String) -> void:
	var w: Node = _worn.get(id)
	if is_instance_valid(w) and w.has_method("apply_config"):w.apply_config(config_for(id))
	if id == _mini_id and is_instance_valid(_mini):   # a knob turned: the miniature is remade with it
		var ctrl: Node3D = _mini.get_parent();_mini.get_parent().remove_child(_mini);_mini.queue_free();_mini = null;_mini_id = ""
		_sync_mini(ctrl)

## What the hand WEARS for the current item: a worn item (mount "worn" - the tape) is the real thing as a
## bangle on the controller, made once per item and shown while it is current; any other item is shown as a
## MINIATURE of itself over the back of the hand (Palle, 2026-10-29: "the current object must be a small
## version of the original") - the trigger makes the full-size one. Everything else is put away. `controller`
## null puts all away (the bracelet out of PLACE, or dropped). Returns the node now worn, or null.
func sync_worn(controller: Node3D) -> Node3D:
	var it := Items.item(current)
	var want: bool = controller != null and not it.is_empty() and str(it.get("mount", "")) == "worn" and str(it.get("coming", "")) == ""
	_sync_mini(controller if not want else null)
	for id in _worn:
		var n: Node = _worn[id]
		if is_instance_valid(n) and not (want and str(id) == current) and n.has_method("put_away"):n.put_away()
	if not want:return null
	var n: Node = _worn.get(current)
	if not is_instance_valid(n):
		var path := Items.scene_for(str(it.get("token", "")))
		if path == "" or not ResourceLoader.exists(path):return null
		n = (load(path) as PackedScene).instantiate()
		if not n.has_method("wear"):n.free();return null
		var cfg := config_for(current)
		for k in cfg:n.set_meta("config_%s" % str(k), cfg[k])
		if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
		n.name = "Worn_" + current;_worn[current] = n
	n.wear(controller, float(it.get("scale", 0.4)))   # wear() parents it under the controller
	return n

## The miniature over the hand: made from the item's own scene, scaled to MINI on its longest side, its physics and pickup off, out of every group (a tiny ball must not join the support graph).
func _sync_mini(controller: Node3D) -> void:
	var it := Items.item(current)
	var want: bool = controller != null and not it.is_empty() and str(it.get("coming", "")) == "" and str(it.get("mount", "")) != "worn"
	if not want or current != _mini_id or not is_instance_valid(_mini) or _mini.get_parent() != controller:
		if is_instance_valid(_mini):_mini.get_parent().remove_child(_mini);_mini.queue_free()
		_mini = null;_mini_id = ""
	if not want:return
	if _mini != null:return
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path):return
	var n: Node = (load(path) as PackedScene).instantiate()
	if not n is Node3D:n.free();return
	var cfg := config_for(current)
	for k in cfg:n.set_meta("config_%s" % str(k), cfg[k])
	if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
	n.name = "Mini_" + current
	controller.add_child(n)
	_make_inert(n)
	var size: Array = it.get("size", [0.1, 0.1, 0.1]);var longest: float = maxf(maxf(float(size[0]), float(size[1])), float(size[2]))
	var k: float = MINI / maxf(longest, .01)   # the item's own scale is for the real thing, not the miniature
	(n as Node3D).transform = Transform3D(Basis().scaled(Vector3.ONE * k), Vector3(0, .05, .09))
	_mini = n;_mini_id = current

static func _make_inert(n: Node) -> void:
	var stack: Array = [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():stack.append(c)
		for g in x.get_groups():x.remove_from_group(g)
		if x is CollisionShape3D:(x as CollisionShape3D).disabled = true
		if x is CollisionObject3D:(x as CollisionObject3D).collision_layer = 0;(x as CollisionObject3D).collision_mask = 0
		if x is RigidBody3D:(x as RigidBody3D).freeze = true;(x as RigidBody3D).gravity_scale = 0
		if "enabled" in x and x.has_method("pick_up"):x.set("enabled", false)
		x.set_physics_process(false)

func mini_node() -> Node3D:
	return _mini if is_instance_valid(_mini) else null

## The node worn and in use now, or null: the bracelet's trigger and grip go to it instead of making things.
func worn_node() -> Node3D:
	var n: Node = _worn.get(current)
	return n if is_instance_valid(n) and n.get("worn_on") != null and bool(n.get("worn_active")) else null

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
