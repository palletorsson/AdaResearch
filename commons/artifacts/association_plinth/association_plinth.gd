extends Node3D
## THE ASSOCIATION'S PLINTH (Palle, 2026-11-04: "the prefab example based on association should be standing on a
## plinth ... when we pick up the object it should be added to the inventory"). A solid plinth at reach height under
## the example a hall stands where a form is first met (fire_extinguisher = association(config(cylinder)) beside the
## first cylinder). Picking the example up COLLECTS it: its inventory item goes on the hand's belt and into the hand,
## shown as a miniature over it, and the example goes back on its plinth - it stays here for the next look. The
## inventory then places, moves and takes back copies of it without holding anything (inventory_wand.gd).
##   config: item (the inventory item id), holds (the example's artifact id on this floor), top (m, the cap's top),
##           size ([x, z] m, the cap), label (the line on the front; the item's name by default),
##           knobs ({key: value}: settings the collected item takes with it - a black spray can stays black, a tape
##           keeps its note; set on every hand that collects, after the item itself; 2026-11-23)

const Items = preload("res://commons/player/inventory_items.gd")
const BODY := Color("e8e4da")
const CAP := Color("2b2d30")
const INK := Color("1d1d1f")

@export var item := ""
@export var holds := ""
@export var top := 1.0
@export var size := Vector2(0.4, 0.4)
@export var label := ""
@export var knobs := {}

var example: Node3D = null        # the example's body (the composite's grabbable)
var home := Transform3D()         # where the example stands on the cap
var _words: Label3D = null
var _cap_mat: StandardMaterial3D = null
var _glow := 0.0

func apply_grid_config(config: Dictionary) -> void:
	if config.has("item"): item = str(config.item)
	if config.has("holds"): holds = str(config.holds)
	if config.has("top"): top = float(config.top)
	if config.has("size") and config.size is Array and (config.size as Array).size() >= 2: size = Vector2(float(config.size[0]), float(config.size[1]))
	if config.has("label"): label = str(config.label)
	if config.has("knobs") and config.knobs is Dictionary: knobs = config.knobs
	if is_inside_tree() and _words != null: _build()   # a config that arrives after _ready rebuilds (the Void's default order)

func _ready() -> void:
	var cfg := {}
	for key in ["item", "holds", "top", "size", "label", "knobs"]:
		if has_meta("config_" + key): cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	_build()
	# the floor builds its artifacts one by one: the example may stand up after the plinth
	var mount: Node3D = null
	for i in 60:
		await get_tree().process_frame
		if not is_inside_tree(): return
		mount = _find_mount()
		if mount != null and not mount.find_children("*", "MeshInstance3D", true, false).is_empty(): break
	if mount == null:
		push_warning("ASSOCIATION_PLINTH: no example '%s' to hold" % holds);return
	_seat(mount)
	_dress(mount)
	example = _find_example()
	# a term made without a grabbable part (the brick, the pallet, the skateboard: static bodies of the kit) cannot be
	# picked up: an invisible pickable shell fitted round it is what the hand takes - the example itself stays put
	if example == null: example = _shell(mount)
	home = example.global_transform
	if example.has_signal("picked_up"): example.picked_up.connect(_on_picked_up)

## A handed-over setting that shows on the example itself. A spray can paints its body when it is made, before a
## floor's config reaches it: the body takes the pigment the plinth hands over (2026-11-23).
func _dress(mount: Node3D) -> void:
	if not knobs.has("pigment"): return
	var body := mount.find_child("MeshInstance3D", true, false) as MeshInstance3D
	if body == null: return
	var paint: Material = body.material_override
	if paint == null: paint = body.get_surface_override_material(0)
	if paint == null and body.mesh != null: paint = body.mesh.surface_get_material(0)
	if paint is StandardMaterial3D:
		(paint as StandardMaterial3D).albedo_color = Color.from_string(str(knobs.pigment), (paint as StandardMaterial3D).albedo_color)

func _build() -> void:
	for c in get_children(): remove_child(c);c.queue_free()
	var body := StaticBody3D.new();body.name = "Plinth";body.collision_layer = 1;add_child(body)
	var plinth_h: float = maxf(top - 0.04, 0.05)
	var mat := StandardMaterial3D.new();mat.albedo_color = BODY;mat.roughness = .9
	var block := MeshInstance3D.new();var bm := BoxMesh.new();bm.size = Vector3(size.x, plinth_h, size.y);block.mesh = bm;block.material_override = mat
	block.position.y = plinth_h * .5;body.add_child(block)
	_cap_mat = StandardMaterial3D.new();_cap_mat.albedo_color = CAP;_cap_mat.roughness = .6
	var cap := MeshInstance3D.new();var cm := BoxMesh.new();cm.size = Vector3(size.x + .04, .04, size.y + .04);cap.mesh = cm;cap.material_override = _cap_mat
	cap.position.y = top - .02;body.add_child(cap)
	# the collider stops 2 cm under the cap's face: the example's origin is on that face, and the desktop hand's reach
	# ray (force_pull.reachable, eye to origin) ended inside a flush collider - the right click could never take it
	var solid: float = maxf(top - .02, .02)
	var shape := CollisionShape3D.new();var bs := BoxShape3D.new();bs.size = Vector3(size.x + .04, solid, size.y + .04);shape.shape = bs;shape.position.y = solid * .5
	body.add_child(shape)
	_words = Label3D.new();_words.name = "Words";_words.pixel_size = .0012;_words.font_size = 32;_words.outline_size = 0
	_words.modulate = INK;_words.width = 360;_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.position = Vector3(0, minf(top - .12, top * .7), size.y * .5 + .004);add_child(_words)
	_words.text = _text(false)

func _text(taken: bool) -> String:
	var name: String = label if label != "" else str(Items.item(item).get("name", item)).get_slice(" - ", 0)
	var how := "IN YOUR INVENTORY" if taken else "PICK IT UP: INTO YOUR INVENTORY"
	return name.to_upper() + "\n" + how

func _find_mount() -> Node3D:
	var floor_root := get_parent().get_parent() if get_parent() != null else null
	if floor_root == null or holds == "": return null
	return floor_root.get_node_or_null(NodePath(holds)) as Node3D

func _find_example() -> Node3D:
	var mount := _find_mount()
	if mount == null: return null
	for n in mount.find_children("*", "RigidBody3D", true, false):
		if n.has_signal("picked_up"): return n
	return null

## The example's meshes in world space (their merged box), or an empty AABB.
static func _bounds(root: Node3D) -> AABB:
	var box := AABB();var first := true
	for m in root.find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).mesh == null or not (m as Node3D).is_visible_in_tree(): continue
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b);first = false
	return box

## The example seated ON the cap: a term whose origin is its middle (the brick, the pallet) sank half into the plinth.
func _seat(mount: Node3D) -> void:
	var b := _bounds(mount)
	if b.size.length() < .001: return
	var cap_top: float = global_position.y + top
	var lift: float = cap_top - b.position.y
	if absf(lift) > .005: mount.global_position.y += lift

## An invisible pickable round the example: XR Tools' pickable with one box fitted to the example's meshes, frozen on
## the cap like the grabbable examples. Grabbed, it collects; let go, it goes back (the example never moved).
func _shell(mount: Node3D) -> Node3D:
	var b := _bounds(mount)
	var packed: PackedScene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
	var shell: RigidBody3D = packed.instantiate()
	for c in shell.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape == null: c.free()
	shell.name = "PickShell"
	var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = b.size.max(Vector3(.05, .05, .05));shape.shape = box;shell.add_child(shape)
	shell.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;shell.freeze = true
	add_child(shell);shell.global_position = b.get_center()
	return shell

## Picked up: the item is collected by every hand that keeps an inventory (the VR prism's, the desktop's), and the
## example is put back on its plinth once the hand has let it go.
func _on_picked_up(_what: Variant = null) -> void:
	if item == "": return
	var fresh := Items.collect(item)
	for h in get_tree().get_nodes_in_group("inventory_hands"):
		if h.has_method("collect"): h.collect(item)
		if h.has_method("set_knob_for"):
			for key in knobs: h.set_knob_for(item, str(key), knobs[key])
	_glow = 1.0
	if _words: _words.text = _text(true)
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null and game.has_method("_notice"):
		var vr: bool = bool(game.get("vr"))
		var how := "Left stick click: choose\nTrigger: place / hold: move\nGrip: take back" if vr else "Tab: choose\nF: place / hold F: move\nX: take back"
		game._notice(("COLLECTED / " if fresh else "IN THE HAND / ") + str(Items.item(item).get("name", item)) + "\n" + how)
	print("[inventory] collected %s (new %s) from %s" % [item, fresh, holds])
	_return_home.call_deferred()

## The example back on the cap, at rest: dropped from whatever holds it, frozen where it stood.
func _return_home() -> void:
	if not is_instance_valid(example): return
	# whoever holds it lets go: an XR hand drops its object, the desktop's mouse grip has no drop_object and lets go
	if example.has_method("is_picked_up") and example.is_picked_up():
		var by: Node = example.get_picked_up_by() if example.has_method("get_picked_up_by") else null
		if by != null and by.has_method("drop_object"): by.drop_object()
		elif by != null: example.let_go(by, Vector3.ZERO, Vector3.ZERO)
	await get_tree().physics_frame
	if not is_instance_valid(example): return
	var body := example as RigidBody3D
	body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
	body.global_transform = home
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;body.freeze = true

func _process(delta: float) -> void:
	if _glow <= 0.0 or _cap_mat == null: return
	_glow = maxf(_glow - delta * .8, 0.0)
	_cap_mat.emission_enabled = _glow > 0.0
	_cap_mat.emission = Color("f59e0b");_cap_mat.emission_energy_multiplier = _glow * 2.0
