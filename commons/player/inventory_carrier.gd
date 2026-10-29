class_name InventoryCarrier
extends XRToolsPickable
## A thing from the inventory in the hand: a pickable body carrying the item's artifact scene (one that is not a
## pickable itself; a roll of tape is held as it is). Built by InventoryHand. Let go of it and it settles: an item
## that mounts on a wall, released with its back within SNAP_REACH of one, turns to face out of it and freezes
## there; one that stands, released that close above a surface, stands on it; otherwise it is a body, falls, and
## stacks on whatever is under it. Origin: the artifact's own; the clock's face is +Z and its back -Z.

const Items = preload("res://commons/player/inventory_items.gd")

signal settled(carrier: Node3D, how: String)   # "wall" | "floor" | "free"

const SNAP_REACH := 0.35

var item: Dictionary = {}
var config: Dictionary = {}
var work: Node3D = null
var mount := "any"
var extent := AABB()   # the work's merged mesh box, in the carrier's own space
var how := ""          # how it last settled

func _init() -> void:
	# XRTools captures the original collision state before _ready runs; the body is free until it settles
	collision_layer = 1 | 4;collision_mask = 1;freeze = false;gravity_scale = 1.0;mass = 1.0
	release_mode = ReleaseMode.UNFROZEN

func _ready() -> void:
	super._ready()
	dropped.connect(func(_who):call_deferred("settle"))

## Instantiate the item's scene with its config and fit a collider to what it built.
func build(it: Dictionary, cfg: Dictionary) -> bool:
	item = it;config = cfg;mount = str(it.get("mount", "any"));name = "Carrier_" + str(it.get("id", "item"))
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path):return false
	work = load(path).instantiate()
	for k in cfg:work.set_meta("config_%s" % str(k), cfg[k])
	var s := float(it.get("scale", 1.0))
	if s > 0.0 and not is_equal_approx(s, 1.0):work.scale = Vector3.ONE * s   # the item's scale: a wall console becomes a hand-sized one
	add_child(work)
	if work.has_method("apply_grid_config"):work.apply_grid_config(cfg)
	_fit()
	return true

## A new config, applied live to the work in the hand.
func apply_config(cfg: Dictionary) -> void:
	config = cfg
	if work == null:return
	for k in cfg:work.set_meta("config_%s" % str(k), cfg[k])
	if work.has_method("apply_grid_config"):work.apply_grid_config(cfg)
	_fit()

func _fit() -> void:
	for c in get_children():
		if c is CollisionShape3D:c.queue_free()
	var inv := global_transform.affine_inverse() if is_inside_tree() else Transform3D.IDENTITY
	var box := AABB();var first := true
	for m in work.find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null:continue
		var rel: Transform3D = (inv * m.global_transform) if is_inside_tree() else (work.transform * m.transform)
		var a: AABB = m.get_aabb()
		for i in 8:
			var p := rel * a.get_endpoint(i)
			if first:box = AABB(p, Vector3.ZERO);first = false
			else:box = box.expand(p)
	if first:box = AABB(Vector3(-.05, -.05, -.05), Vector3(.1, .1, .1))
	extent = box
	var shape := CollisionShape3D.new();var bs := BoxShape3D.new();bs.size = box.size.max(Vector3(.02, .02, .02));shape.shape = bs
	shape.position = box.get_center();add_child(shape)

## Where the body comes to rest after the hand lets go. Returns how it settled.
## This body and every body the artifact carries (a counter has a collider of its own): what the settling rays look past.
func _own_rids() -> Array[RID]:
	var out: Array[RID] = [get_rid()]
	if work != null:
		for b in work.find_children("*", "CollisionObject3D", true, false):out.append(b.get_rid())
	return out

func settle() -> String:
	how = "free"
	if not is_inside_tree() or is_picked_up():return how
	var space := get_world_3d().direct_space_state;var mine := _own_rids()
	var c := extent.get_center()
	if mount in ["wall", "any"]:
		# cast from the centre out through the back (-Z), as far as the back is from the centre plus the reach
		var back := extent.size.z / 2.0 - c.z   # from the origin to the back face (the counter's body is all behind its origin)
		var from := global_transform * c;var to := from - global_transform.basis.z.normalized() * (back + SNAP_REACH)
		var q := PhysicsRayQueryParameters3D.create(from, to, 1, mine);var hit := space.intersect_ray(q)
		if not hit.is_empty() and absf(hit.normal.y) < .5:
			var n: Vector3 = hit.normal.normalized()
			var basis := Basis.looking_at(-n, Vector3.UP)   # -Z into the wall, +Z out of it
			var pos: Vector3 = hit.position + n * (back + .002) - basis * Vector3(c.x, c.y, 0)
			_freeze_at(Transform3D(basis, pos));how = "wall";settled.emit(self, how);return how
	if mount in ["floor", "any"]:
		var below := extent.size.y / 2.0 - c.y
		var from := global_transform * c;var to := from + Vector3.DOWN * (below + SNAP_REACH)
		var q := PhysicsRayQueryParameters3D.create(from, to, 1, mine);var hit := space.intersect_ray(q)
		if not hit.is_empty() and hit.normal.y > .7:
			var yaw := global_transform.basis.get_euler().y
			var basis := Basis(Vector3.UP, yaw)
			var pos: Vector3 = Vector3(from.x, hit.position.y + below + .002, from.z) - basis * Vector3(c.x, 0, c.z)
			_freeze_at(Transform3D(basis, pos));how = "floor";settled.emit(self, how);return how
	settled.emit(self, how);return how

func _freeze_at(t: Transform3D) -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;freeze = true
	linear_velocity = Vector3.ZERO;angular_velocity = Vector3.ZERO;global_transform = t

## Picked up again: a body once more, so it can be carried and settle elsewhere.
func pick_up(by: Node3D) -> void:
	freeze = false;how = ""
	super.pick_up(by)
