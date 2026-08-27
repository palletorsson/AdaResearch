extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PropSpigot

## @identity
## lineage: Garry's Mod, 2040 — a ceiling duct rains crates into a catch pan, forever.
##   Two heavy steel wedges stand in the fall; shove or carry them and the rain reroutes.
##   The physics engine is the exhibit: falling, piling, sliding, coming to rest.
## essence: one gravity, every fate. Each crate leaves the duct identically and ends
##   somewhere else — deflected, stacked, settled — because force is not a property of the
##   crate but of every meeting it has on the way down. The pile's slope is friction's
##   angle of repose, drawn in cargo.
## truth: F = ma is a sentence about the NEXT moment. Watch one crate long enough and you
##   watch the whole chapter: gravity, normal force, friction, collision, rest.
##
## The 2026-08-27 forces brief: "thing falling, thing we can move, obstacles are good,
## fountains, falling boxes … Gary's mode in 2040".
##
## POOLED, NEVER FREED. The crates are a fixed pool recycled by teleport — queue_free on
## live generated content is the documented segfault class in this repo, and a rain that
## frees a body every second would meet it within minutes.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const CRATE_PATH := "res://commons/artifacts/crate/crate.tscn"
const CRATE_SIZE := 0.34               # bead-normalised crate edge, m
const PARK := Vector3(0.0, -20.0, 0.0) # parked pool bodies wait far below the floor

@export var seed: int = 3
## Seconds between drops. At 0.9 s a 24-crate pool holds ~21 s of rain on the floor
## before the oldest crate is recycled — enough for a pile to form and slump.
@export var rate: float = 0.9
@export_range(8, 40) var pool: int = 24
@export var drop_h: float = 3.1
@export var arena: float = 2.6         # catch-pan half-width, m

var _bodies: Array = []                # the whole pool, in spawn order
var _ages: Dictionary = {}             # body -> spawn tick
var _clock := 0.0
var _tick := 0
var _next_slot := 0

func _ready() -> void:
	_rng.seed = seed
	_build_duct()
	_build_pan()
	_build_obstacles()
	_build_pool()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "rate", "pool", "drop_h", "arena"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_clock += delta
	if _clock < rate:
		return
	_clock = 0.0
	_drop_next()

# --- architecture -------------------------------------------------------------------

func _build_duct() -> void:
	var duct := MeshInstance3D.new()
	var duct_mesh := BoxMesh.new()
	duct_mesh.size = Vector3(0.55, 0.7, 0.55)
	duct.mesh = duct_mesh
	duct.position = Vector3(0.0, drop_h + 0.35, 0.0)
	duct.material_override = _steel_mat(Color(0.30, 0.32, 0.35))
	add_child(duct)
	var mouth := MeshInstance3D.new()
	var mouth_mesh := CylinderMesh.new()
	mouth_mesh.top_radius = 0.30
	mouth_mesh.bottom_radius = 0.36
	mouth_mesh.height = 0.22
	mouth.mesh = mouth_mesh
	mouth.position = Vector3(0.0, drop_h - 0.06, 0.0)
	mouth.material_override = _glow_mat(Color(0.95, 0.60, 0.15), 1.4)
	add_child(mouth)

func _build_pan() -> void:
	# The floor of the exhibit: a shallow steel pan with lips, so the pile stays an
	# exhibit instead of a spill wandering across the hall.
	var pan := StaticBody3D.new()
	add_child(pan)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(arena * 2.0, 0.1, arena * 2.0)
	floor_shape.shape = floor_box
	floor_shape.position = Vector3(0.0, 0.05, 0.0)
	pan.add_child(floor_shape)
	var floor_mesh := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(arena * 2.0, 0.1, arena * 2.0)
	floor_mesh.mesh = fm
	floor_mesh.position = Vector3(0.0, 0.05, 0.0)
	floor_mesh.material_override = _matte_mat(Color(0.13, 0.13, 0.15), 0.95)
	pan.add_child(floor_mesh)
	for i in range(4):
		var lip := CollisionShape3D.new()
		var lip_box := BoxShape3D.new()
		lip_box.size = Vector3(arena * 2.0 + 0.12, 0.34, 0.06)
		lip.shape = lip_box
		var lip_mesh := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = lip_box.size
		lip_mesh.mesh = lm
		lip_mesh.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
		var ang := PI * 0.5 * float(i)
		var offset := Vector3(cos(ang), 0.0, sin(ang)) * arena
		lip.position = offset + Vector3(0.0, 0.17, 0.0)
		lip.rotation.y = -ang + PI * 0.5
		lip_mesh.position = lip.position
		lip_mesh.rotation.y = lip.rotation.y
		pan.add_child(lip)
		pan.add_child(lip_mesh)

func _build_obstacles() -> void:
	# Two heavy wedges and one drum stand in the rain. RigidBody, mass 30: the existing
	# desktop carry-grab and VR grab move rigid bodies, so "thing we can move" costs no
	# new interaction system — and a falling crate can shove them a little, which is the
	# lesson working in both directions.
	var mat := PhysicsMaterial.new()
	mat.friction = 0.9
	mat.bounce = 0.05
	for i in range(2):
		var wedge := RigidBody3D.new()
		wedge.mass = 30.0
		wedge.physics_material_override = mat
		var shape := CollisionShape3D.new()
		var prism := ConvexPolygonShape3D.new()
		var w := 0.65
		prism.points = PackedVector3Array([
			Vector3(-w, 0.0, -w * 0.8), Vector3(w, 0.0, -w * 0.8),
			Vector3(-w, 0.0, w * 0.8), Vector3(w, 0.0, w * 0.8),
			Vector3(-w, 0.72, -w * 0.8), Vector3(-w, 0.72, w * 0.8),
		])
		shape.shape = prism
		wedge.add_child(shape)
		var mesh := MeshInstance3D.new()
		var prism_mesh := PrismMesh.new()
		prism_mesh.size = Vector3(w * 2.0, 0.72, w * 1.6)
		# PrismMesh peaks centre-top; lay it on its back so it presents a slope.
		mesh.mesh = prism_mesh
		mesh.rotation.z = PI * 0.5
		mesh.position = Vector3(0.0, 0.36, 0.0)
		mesh.material_override = _steel_mat(Color(0.72, 0.30, 0.12) if i == 0 else Color(0.16, 0.38, 0.62))
		wedge.add_child(mesh)
		wedge.position = Vector3(-0.7 + 1.4 * float(i), 0.5, 0.45 - 0.9 * float(i))
		wedge.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(wedge)

func _build_pool() -> void:
	var mat := PhysicsMaterial.new()
	mat.friction = 0.85
	mat.bounce = 0.06
	var packed: PackedScene = load(CRATE_PATH)
	for i in range(pool):
		var body := RigidBody3D.new()
		body.mass = 2.2
		body.physics_material_override = mat
		body.can_sleep = true
		body.freeze = true
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3.ONE * CRATE_SIZE
		shape.shape = box
		body.add_child(shape)
		body.position = PARK + Vector3(float(i) * 0.8, 0.0, 0.0)
		# Into the tree BEFORE the prop goes in: a procedural prop builds its meshes in
		# _ready, which only runs on tree entry — measure it earlier and the AABB is
		# empty, the scale is skipped, and a 0.76 m crate wears a 0.34 m collider.
		add_child(body)
		if packed != null:
			var inst: Node3D = packed.instantiate()
			body.add_child(inst)
			var aabb := _merged_aabb(inst)
			var longest: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
			if longest > 0.001:
				var s: float = CRATE_SIZE / longest
				inst.scale = Vector3.ONE * s
				inst.position = -(aabb.get_center() * s)
		else:
			var mesh := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3.ONE * CRATE_SIZE
			mesh.mesh = bm
			mesh.material_override = _matte_mat(Color(0.55, 0.42, 0.25))
			body.add_child(mesh)
		# OUT of the tree until its first drop. Parked-in-tree bodies at y=-20 inflated
		# the measured AABB to 21x24 m (probe, 2026-08-27), which breaks capture framing
		# and placement. remove_child keeps the node alive - _ready has already built the
		# crate, and re-entry does not run it again. Nothing is ever freed.
		remove_child(body)
		_bodies.append(body)

func _drop_next() -> void:
	if _bodies.is_empty():
		return
	_tick += 1
	var body: RigidBody3D = _bodies[_next_slot]
	_next_slot = (_next_slot + 1) % _bodies.size()
	if not body.is_inside_tree():
		add_child(body)
	# Recycle by TELEPORT: once dropped, the body never leaves the tree again, so there
	# is nothing to free.
	body.freeze = true
	body.position = Vector3(_rng.randf_range(-0.14, 0.14), drop_h - 0.3, _rng.randf_range(-0.14, 0.14))
	body.rotation = Vector3(_rng.randf_range(0.0, TAU), _rng.randf_range(0.0, TAU), 0.0)
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3(_rng.randf_range(-2, 2), _rng.randf_range(-2, 2), _rng.randf_range(-2, 2))
	body.freeze = false
	_ages[body] = _tick

func _merged_aabb(root: Node3D) -> AABB:
	# Root-local via global transforms — valid because the pool body is already in the
	# tree when this runs.
	var to_local := root.global_transform.affine_inverse()
	var merged := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			var box: AABB = (to_local * mi.global_transform) * mi.get_aabb()
			if first:
				merged = box
				first = false
			else:
				merged = merged.merge(box)
		for child in node.get_children():
			stack.append(child)
	return merged

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "SpigotPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(arena + 0.25, 0.24, arena * 0.6)
	ts.rotation.y = deg_to_rad(-35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("PROP SPIGOT",
			"One gravity, every fate: each crate leaves the duct identically\nand ends somewhere else. The pile's slope is friction's angle of repose.\nThe wedges are yours - move them, and the rain reroutes.")
