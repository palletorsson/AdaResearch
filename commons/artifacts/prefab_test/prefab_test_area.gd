# PrefabTestArea.gd - a marked piece of floor to try the prefab system on
#
# @identity
# essence: a taped rectangle of empty floor with a pile of twenty prefabs stuck into each other in its middle; the pile clears when the visitor steps over the tape
# desire: the learner has room to place, stack and take back the things the hand holds, without a lesson standing in the way
# critical_parameter: count - how many prefabs the pile holds; seed - which ones and how they stick
# triggers: the visitor's eye crossing the tape clears the pile, once, for this visit
# emerges: the pile shows what the catalogue holds at this floor; the cleared ground is what it is for
# relationships: the pile is drawn from the same timeline the belt beside it carries ([[prefab_belt]], commons/data/inventory/items.json); what is placed here is kept by the hand ([[inventory_hand]])
# truth: a test ground is an empty one. The pile is only the invitation.
extends Node3D

## WHERE THIS COMES FROM. Palle, 22 November 2026: "a new map called prefab test that has two marked large areas
## with the prefab conveyor catalog and in the middle 20 randomly stuck prefabs. As you enter the area they
## disappear. The area is for you to test the prefab system."
##
## The pile: `count` things from the prefab timeline as far as this floor gives it (items.json, the belt's own
## stock, tools left out, nothing smaller than 30 cm), full size, made inert the way the belt makes its miniatures
## (no colliders, no bodies, no groups), each turned, tilted and set at a height drawn from `seed`, so that they
## stand in each other. They are built two a frame, so a floor that streams in does not stall on them.
## Origin: the middle of the area, on the floor. `length` runs along x, `depth` along z.

const Items = preload("res://commons/player/inventory_items.gd")
const HandLib = preload("res://commons/player/inventory_hand.gd")
const Vending = preload("res://commons/artifacts/vending_machine/vending_machine.gd")   # TOOLS, _quiet, _bounds
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const TAPE := Color("ff4f8b")
const CHALK := Color("f2ece2")
const SMALLEST := 0.3            # a pile thing's longest side, at least
const LARGEST := 2.2             # and at most: a 4 m canvas or slab is a wall, not a thing in a pile
const PER_FRAME := 2

@export var length := 6.6
@export var depth := 13.6
@export var count := 20
@export var seed_value := 12
@export var title := "TEST AREA"
@export var pile_radius := 1.25
@export var pile_height := 1.1

var pile: Array[Node3D] = []         # what stands in the pile
var chosen: Array[String] = []       # the item ids, in the order they were drawn
var cleared := false
var inside := false
var built := false                   # the whole pile stands
var _queue: Array = []
var _seat: Array = []                # [node, base height, frames to wait]
var _holder: Node3D
var _tick := 0.0


func apply_grid_config(config: Dictionary) -> void:
	for key in ["length", "depth", "count", "title", "pile_radius", "pile_height"]:
		if config.has(key): set(key, config[key])
	if config.has("seed"): seed_value = int(config.seed)
	if is_node_ready():
		for child in get_children(): child.queue_free()
		pile.clear(); chosen.clear(); _queue.clear(); _seat.clear()
		cleared = false; built = false
		_build()


func _ready() -> void:
	for key in ["length", "depth", "count", "title", "pile_radius", "pile_height"]:
		if has_meta("config_" + key): set(key, get_meta("config_" + key))
	if has_meta("config_seed"): seed_value = int(get_meta("config_seed"))
	_build()


## The Void floor this stands on; -1 off the tower (then the pile draws from every prefab).
func given_floor() -> int:
	var n: Node = get_parent()
	while n != null:
		if n.has_meta("void_content_floor"): return int(n.get_meta("void_content_floor"))
		n = n.get_parent()
	return -1


## The prefabs a pile may hold: the belt's stock, as far as this floor gives it, big enough to see.
func candidates() -> Array:
	var here := given_floor()
	var out := []
	for it in Items.items():
		var id := str(it.get("id", ""))
		if id == "" or not bool(it.get("vending", true)) or id in Vending.TOOLS or it.has("tool"): continue
		var f: Variant = it.get("floor", 0)
		if here >= 0 and (int(f) if f != null else 0) > here: continue
		var size: Array = it.get("size", [0.1, 0.1, 0.1])
		var longest := maxf(maxf(float(size[0]), float(size[1])), float(size[2]))
		if longest < SMALLEST or longest > LARGEST: continue
		var path := Items.scene_for(str(it.get("token", "")))
		if path == "" or not ResourceLoader.exists(path): continue
		out.append(it)
	return out


func _build() -> void:
	# the tape round the area, and its corners in chalk
	var hx := length * 0.5
	var hz := depth * 0.5
	for strip in [[Vector3(0, 0.004, -hz), Vector3(length, 0.006, 0.07)], [Vector3(0, 0.004, hz), Vector3(length, 0.006, 0.07)],
			[Vector3(-hx, 0.004, 0), Vector3(0.07, 0.006, depth)], [Vector3(hx, 0.004, 0), Vector3(0.07, 0.006, depth)]]:
		var tape := Kit.block(self, strip[1], strip[0], TAPE, false)
		tape.name = "Tape"
		tape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for arm in [Vector3(0.5, 0.008, 0.11), Vector3(0.11, 0.008, 0.5)]:
				var corner := Kit.block(self, arm, Vector3(sx * (hx - arm.x * 0.5 + 0.055), 0.005, sz * (hz - arm.z * 0.5 + 0.055)), CHALK, false)
				corner.name = "Corner"
				corner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# what it is, written on the ground inside the south edge, read by someone coming from the belt
	var words := Kit.label(self, "%s\nSTEP OVER THE TAPE: THE PILE CLEARS\nTAKE A PREFAB FROM THE BELT AND PLACE IT HERE" % title, Vector3(0, 0.012, hz - 0.75), 0.0026)
	words.name = "Words"
	words.rotation.x = -PI / 2.0
	words.modulate = CHALK
	# the pile: drawn now, built over the next frames
	_holder = Node3D.new()
	_holder.name = "Pile"
	add_child(_holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var stock := candidates()
	if stock.is_empty():
		built = true
		return
	var order := []
	while order.size() < count:
		var bag := stock.duplicate()
		while not bag.is_empty() and order.size() < count:
			order.append(bag.pop_at(rng.randi_range(0, bag.size() - 1)))
	for i in order.size():
		var around := rng.randf() * TAU
		var out := pile_radius * 0.92 * sqrt(rng.randf())
		_queue.append({"id": str(order[i].id), "at": Vector3(cos(around) * out, 0, sin(around) * out), "base": 0.0 if i < 7 else rng.randf() * pile_height,
			"yaw": rng.randf() * TAU, "lean": deg_to_rad(rng.randf_range(-28.0, 28.0)), "about": rng.randf() * TAU})
		chosen.append(str(order[i].id))


## One thing of the pile: the item's own scene with its own config, full size, and inert.
func _make(id: String) -> Node3D:
	var it := Items.item(id)
	if it.is_empty(): return null
	var packed := load(Items.scene_for(str(it.get("token", "")))) as PackedScene
	if packed == null: return null
	var n: Node = packed.instantiate()
	if not n is Node3D:
		n.free()
		return null
	var cfg := Items.config_for(it, {})
	for k in cfg: n.set_meta("config_%s" % str(k), cfg[k])
	if n.has_method("apply_grid_config"): n.apply_grid_config(cfg)
	n.name = "Pile_" + id
	HandLib._make_inert(n)
	n.ready.connect(func(): HandLib._make_inert(n); Vending._quiet(n, false), CONNECT_ONE_SHOT)
	var own: Variant = it.get("scale", 1.0)
	(n as Node3D).scale = Vector3.ONE * (float(own) if own != null else 1.0)
	return n as Node3D


func _process(delta: float) -> void:
	if not cleared:
		for i in mini(PER_FRAME, _queue.size()):
			var row: Dictionary = _queue.pop_front()
			var thing := _make(str(row.id))
			if thing == null: continue
			_holder.add_child(thing)
			var lean_axis := Vector3(cos(float(row.about)), 0, sin(float(row.about)))
			thing.transform = Transform3D(Basis(lean_axis, float(row.lean)) * Basis(Vector3.UP, float(row.yaw)) * thing.basis, row.at)
			pile.append(thing)
			_seat.append([thing, float(row.base), 3])
		# once a thing has built itself: its lowest point at the height it was given
		for i in range(_seat.size() - 1, -1, -1):
			var wait: Array = _seat[i]
			wait[2] = int(wait[2]) - 1
			if int(wait[2]) > 0: continue
			var thing := wait[0] as Node3D
			if is_instance_valid(thing):
				HandLib._make_inert(thing)
				var box: AABB = Vending._bounds(thing)
				if box.size != Vector3.ZERO:
					thing.global_position.y += (global_position.y + float(wait[1])) - box.position.y
			_seat.remove_at(i)
		if _queue.is_empty() and _seat.is_empty(): built = true
	_tick += delta
	if _tick < 0.12: return
	_tick = 0.0
	var eye := get_viewport().get_camera_3d()
	if eye == null: return
	var at := to_local(eye.global_position)
	inside = absf(at.x) <= length * 0.5 and absf(at.z) <= depth * 0.5 and at.y > -0.5 and at.y < 4.5
	if inside and not cleared: clear()
	if cleared and not is_instance_valid(_holder): set_process(false)


## The pile goes, for this visit: the ground is the visitor's.
func clear() -> void:
	if cleared: return
	cleared = true
	_queue.clear()
	_seat.clear()
	var holder := _holder
	var fade := create_tween()
	fade.tween_property(holder, "scale", Vector3.ONE * 0.02, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fade.tween_callback(func():
		if is_instance_valid(holder): holder.queue_free())
	pile.clear()
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null and game.has_method("_notice"): game._notice("%s\nThe pile is cleared. Build here." % title)
