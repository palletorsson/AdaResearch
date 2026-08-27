extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ThreeGravities

## @identity
## lineage: three glass columns on one plinth row, and inside each the SAME museum fire
##   extinguisher is falling, forever — crawling on the Moon, ordinary on Earth, hammered
##   down on Jupiter. When a fall completes it begins again at the top, so the exhibit is
##   never between states: it is always falling, three ways at once.
## essence: g is the one term that changes. Each column's body runs the real engine fall
##   with gravity_scale = g/9.8 (0.17, 1.00, 2.53), so the three drop times you watch —
##   1.7 s, 0.70 s, 0.44 s over 2.4 m — are physics, not choreography.
## truth: weight is a relationship, not a property. The extinguisher never changes;
##   the planet under it does.
##
## The 2026-08-27 forces brief: props instead of ball examples, the force under breath —
## no arrows here at all, just three speeds of the same fall.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# g in m/s², and the label etched at each column's base.
const COLUMNS := [
	{"label": "MOON", "g": 1.62},
	{"label": "EARTH", "g": 9.81},
	{"label": "JUPITER", "g": 24.79},
]
const PROP := {"token": "fire_extinguisher", "bead": 0.40, "kg": 5.5}

@export var seed: int = 5
@export var column_h: float = 2.6
@export var column_r: float = 0.34
@export var spacing: float = 1.05

var _fallers: Array = []               # {body: RigidBody3D, top: Vector3, floor_y: float}

func _ready() -> void:
	_rng.seed = seed
	_build_plinth()
	for i in range(COLUMNS.size()):
		_build_column(i)
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "column_h", "spacing"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(_delta: float) -> void:
	# The loop: a completed fall restarts at the top with zero velocity — each cycle is
	# a fresh drop, so the spacing-per-frame you see is always the honest v(t).
	for f in _fallers:
		var body: RigidBody3D = f["body"]
		if body.position.y <= f["floor_y"]:
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
			body.position = f["top"]

# --- build --------------------------------------------------------------------------

func _build_plinth() -> void:
	var slab := MeshInstance3D.new()
	var slab_mesh := BoxMesh.new()
	slab_mesh.size = Vector3(spacing * float(COLUMNS.size()) + 0.7, 0.14, column_r * 2.0 + 0.5)
	slab.mesh = slab_mesh
	slab.position = Vector3(0.0, 0.07, 0.0)
	slab.material_override = _matte_mat(Color(0.11, 0.11, 0.13), 0.9)
	add_child(slab)

func _build_column(i: int) -> void:
	var col: Dictionary = COLUMNS[i]
	var x := (float(i) - float(COLUMNS.size() - 1) * 0.5) * spacing
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.60, 0.78, 0.82, 0.14)
	glass.roughness = 0.04
	var tube := MeshInstance3D.new()
	var tube_mesh := CylinderMesh.new()
	tube_mesh.top_radius = column_r
	tube_mesh.bottom_radius = column_r
	tube_mesh.height = column_h
	tube.mesh = tube_mesh
	tube.position = Vector3(x, 0.14 + column_h * 0.5, 0.0)
	tube.material_override = glass
	add_child(tube)
	for y in [0.14, 0.14 + column_h]:
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = column_r - 0.015
		ring_mesh.outer_radius = column_r + 0.035
		ring.mesh = ring_mesh
		ring.position = Vector3(x, y, 0.0)
		ring.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
		add_child(ring)

	# The faller: real engine gravity, scaled to the planet. The column is display
	# only — the body needs no collider walls because it only ever moves straight down.
	var body := RigidBody3D.new()
	body.gravity_scale = col["g"] / 9.81
	body.mass = PROP["kg"]
	# Collides with NOTHING (mask 0): the fall must reach floor_y and loop, not land on
	# whatever floor the host map puts under the plinth. The shape only silences the
	# no-shape warning.
	body.collision_layer = 0
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PROP["bead"] * 0.4
	shape.shape = sphere
	body.add_child(shape)
	var top := Vector3(x, 0.14 + column_h - PROP["bead"] * 0.6, 0.0)
	body.position = top
	add_child(body)
	var inst := _spawn_prop_into(body)
	if inst == null:
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * PROP["bead"] * 0.6
		box.material_override = _matte_mat(Color(0.7, 0.25, 0.2))
		body.add_child(box)
	_fallers.append({"body": body, "top": top, "floor_y": 0.14 + PROP["bead"] * 0.55})

	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.26
	tag.position = Vector3(x, 0.16, column_r + 0.22)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(col["label"], "g = %.2f m/s2" % col["g"])

## Instance the cast prop under the body, bead-normalised, internal rigids frozen.
## Returns null when the scene is missing so the caller can substitute.
func _spawn_prop_into(body: RigidBody3D) -> Node3D:
	var path := "res://commons/artifacts/%s/%s.tscn" % [PROP["token"], PROP["token"]]
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("three_gravities: cast prop %s missing" % PROP["token"])
		return null
	var inst: Node3D = packed.instantiate()
	body.add_child(inst)
	var pstack: Array = [inst]
	while not pstack.is_empty():
		var pn: Node = pstack.pop_back()
		if pn is RigidBody3D and pn != body:
			(pn as RigidBody3D).freeze = true
		for pc in pn.get_children():
			pstack.append(pc)
	var aabb := _merged_aabb(inst)
	var longest: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	if longest > 0.001:
		var s: float = PROP["bead"] / longest
		inst.scale = Vector3.ONE * s
		inst.position = -(aabb.get_center() * s)
	return inst

func _merged_aabb(root: Node3D) -> AABB:
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
	ts.name = "GravityPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(spacing * float(COLUMNS.size()) * 0.5 + 0.15), 0.24, 0.75)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THREE GRAVITIES",
			"The same object, falling forever on three planets: 1.7 s, 0.70 s, 0.44 s\nover the same 2.4 m. The extinguisher never changes; the planet under it does.\nWeight is a relationship, not a property.")
