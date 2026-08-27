extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PausedFountain

## @identity
## lineage: a fountain that erupts museum objects instead of water — fire extinguishers,
##   crates, exit signs — every throw FROZEN along its own parabola, the whole family of
##   trajectories standing in the air as one sculpture. Press the button and a single live
##   throw finishes its sentence under real engine gravity.
## essence: a trajectory is not a line, it is a history: p(t) = p0 + v0·t + ½g·t². Freeze
##   copies of one object at equal time steps and the SPACING becomes the speedometer —
##   wide near the mouth where it moves fast, tight at the apex where vertical speed dies —
##   while every arc, whatever its speed, bends on the same g.
## truth: velocity is where you will be next; acceleration is how that promise bends.
##   Pause the fountain and both are visible at once, which no moving fountain allows.
##
## The 2026-08-27 forces brief: "the physics engine as example of thing falling …
## object hanging in mid air, like exploration of object paused … fountains".

# The cast: museum props with measured registry bodies. Path, bead height the frozen
# copies are normalised to, and the launch mass handed to the one live body. Everything
# here is mesh-light — no GPU generators, because the live throw is FREED after landing
# and marching-cubes props segfault on queue_free mid-generation.
const CAST := [
	{"token": "fire_extinguisher", "bead": 0.46, "kg": 5.5},
	# Crate bead shrunk 0.42 -> 0.30 after the first capture: a cube that big on a
	# steep slow arc overlaps itself and reads as a stack, not a throw.
	{"token": "crate", "bead": 0.30, "kg": 8.0},
	{"token": "exit_sign", "bead": 0.40, "kg": 0.6},
	{"token": "control_pendulum", "bead": 0.44, "kg": 1.1},
	{"token": "chladni_plate", "bead": 0.38, "kg": 1.4},
]

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")

@export var seed: int = 4
@export_range(2, 8) var arcs: int = 5
@export_range(3, 12) var per_arc: int = 7
## Launch speed of the slowest arc, m/s. 4.2 m/s tops out around 0.9 m above the mouth;
## the fastest arc (×1.35) reaches ~1.6 m, which still reads under a 3 m hall ceiling.
@export var speed: float = 4.2
@export var gravity: float = 9.8
## Frozen copies get a tumble proportional to flight time, so the sculpture also shows
## angular velocity as a gradient of pose — a fountain of one object is a zoetrope.
@export var tumble: float = 1.6

var _mouth := Vector3(0.0, 0.55, 0.0)
var _arc_params: Array = []            # {dir: Vector3, v0: float, cast: Dictionary}
var _live: Array = []                  # at most 3 flying bodies at once
var _next_arc := 0

func _ready() -> void:
	_rng.seed = seed
	_build_basin()
	_build_arcs()
	_build_button()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "arcs", "per_arc", "speed", "tumble"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- the basin: a low dark pool with a brass mouth ---------------------------------

func _build_basin() -> void:
	var pool := MeshInstance3D.new()
	var pool_mesh := CylinderMesh.new()
	pool_mesh.top_radius = 1.55
	pool_mesh.bottom_radius = 1.65
	pool_mesh.height = 0.16
	pool.mesh = pool_mesh
	pool.position = Vector3(0.0, 0.08, 0.0)
	pool.material_override = _matte_mat(Color(0.09, 0.10, 0.12), 0.9)
	add_child(pool)

	# Still "water": a barely-emissive disc. The fountain is paused, so even the water
	# holds its breath — a glassy sheet, not a shader of ripples.
	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 1.48
	water_mesh.bottom_radius = 1.48
	water_mesh.height = 0.012
	water.mesh = water_mesh
	water.position = Vector3(0.0, 0.165, 0.0)
	var wm := _glow_mat(Color(0.13, 0.20, 0.26), 0.35)
	wm.metallic = 0.6
	wm.roughness = 0.05
	water.material_override = wm
	add_child(water)

	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 1.5
	rim_mesh.outer_radius = 1.66
	rim.mesh = rim_mesh
	rim.position = Vector3(0.0, 0.16, 0.0)
	rim.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(rim)

	var mouth := MeshInstance3D.new()
	var mouth_mesh := CylinderMesh.new()
	mouth_mesh.top_radius = 0.16
	mouth_mesh.bottom_radius = 0.24
	mouth_mesh.height = 0.42
	mouth.mesh = mouth_mesh
	mouth.position = Vector3(0.0, 0.37, 0.0)
	mouth.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(mouth)

# --- the paused throws --------------------------------------------------------------

func _build_arcs() -> void:
	_arc_params.clear()
	for i in range(arcs):
		var cast_row: Dictionary = CAST[i % CAST.size()]
		# Directions fan around the mouth; elevation stays steep (68-80 deg) so the
		# arcs read as a fountain, not as artillery.
		var yaw := TAU * float(i) / float(arcs) + _rng.randf_range(-0.25, 0.25)
		var elev := deg_to_rad(_rng.randf_range(68.0, 80.0))
		var dir := Vector3(cos(yaw) * cos(elev), sin(elev), sin(yaw) * cos(elev))
		var v0 := speed * _rng.randf_range(1.0, 1.35)
		_arc_params.append({"dir": dir, "v0": v0, "cast": cast_row})

		# Freeze per_arc copies at equal TIME steps along p(t). Equal time, not equal
		# distance — the unequal gaps that fall out of that choice ARE the lesson.
		var flight := 2.0 * (dir.y * v0) / gravity
		var dt := flight / float(per_arc + 1)
		var spin_axis := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized()
		for k in range(1, per_arc + 1):
			var t := dt * float(k)
			var pos := _mouth + dir * v0 * t + Vector3(0.0, -0.5 * gravity * t * t, 0.0)
			var bead := _spawn_prop(cast_row, pos)
			bead.rotate(spin_axis, tumble * t)

func _spawn_prop(cast_row: Dictionary, pos: Vector3) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.position = pos
	add_child(wrapper)
	var path := "res://commons/artifacts/%s/%s.tscn" % [cast_row["token"], cast_row["token"]]
	var packed: PackedScene = load(path)
	if packed == null:
		# A missing prop must not blank the fountain: fall back to a matte bead and warn.
		push_warning("paused_fountain: cast prop %s missing, bead substituted" % cast_row["token"])
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * cast_row["bead"] * 0.7
		box.material_override = _matte_mat(Color(0.6, 0.55, 0.5))
		wrapper.add_child(box)
		return wrapper
	var inst: Node3D = packed.instantiate()
	wrapper.add_child(inst)
	# A cast prop may carry its OWN RigidBody3D (pickable props do). Frozen sculpture
	# beads must not shed parts under live gravity - freeze every internal body.
	var pstack: Array = [inst]
	while not pstack.is_empty():
		var pn: Node = pstack.pop_back()
		if pn is RigidBody3D:
			(pn as RigidBody3D).freeze = true
		for pc in pn.get_children():
			pstack.append(pc)
	# Normalise into a bead volume: a 0.83 m extinguisher and a 0.09 m plate must read
	# as beads of one fountain. Procedural props build synchronously in _ready, so the
	# AABB is real by the time we are back here.
	var aabb := _merged_aabb(inst)
	var longest: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	if longest > 0.001:
		var s: float = cast_row["bead"] / longest
		inst.scale = Vector3.ONE * s
		inst.position = -(aabb.get_center() * s)
	return wrapper

func _merged_aabb(root: Node3D) -> AABB:
	# Merge in ROOT-local space — the artifact may already stand rotated on its grid
	# cell when _ready runs, so global boxes would smear under that rotation.
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

# --- the one live throw -------------------------------------------------------------

func _build_button() -> void:
	var btn := BUTTON_SCENE.instantiate()
	btn.position = Vector3(1.85, 0.85, 0.0)
	btn.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	btn.set("pressed_color", Color(0.95, 0.60, 0.15))
	btn.set("released_color", Color(0.30, 0.75, 0.85))
	add_child(btn)
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.07
	stem_mesh.height = 0.8
	stem.mesh = stem_mesh
	stem.position = Vector3(1.85, 0.4, 0.0)
	stem.material_override = _steel_mat(Color(0.35, 0.35, 0.38))
	add_child(stem)
	if btn.has_signal("pressed"):
		btn.connect("pressed", Callable(self, "_on_fire_pressed"))
	else:
		var inner := btn.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_fire_pressed"))

func _on_fire_pressed() -> void:
	if _live.size() >= 3:
		return
	var params: Dictionary = _arc_params[_next_arc]
	_next_arc = (_next_arc + 1) % _arc_params.size()
	var cast_row: Dictionary = params["cast"]
	var body := RigidBody3D.new()
	body.mass = cast_row["kg"]
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = cast_row["bead"] * 0.5
	shape.shape = sphere
	body.add_child(shape)
	body.position = _mouth
	add_child(body)
	var visual := _spawn_prop(cast_row, Vector3.ZERO)
	visual.reparent(body)
	visual.position = Vector3.ZERO
	body.linear_velocity = params["dir"] * params["v0"]
	body.angular_velocity = Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * tumble
	_live.append(body)
	# Freed only after it has landed and slept — never mid-flight, never mid-generation.
	var timer := get_tree().create_timer(6.0)
	timer.timeout.connect(func() -> void: _retire_live(body))

func _retire_live(body: RigidBody3D) -> void:
	if not is_instance_valid(body):
		return
	_live.erase(body)
	var tween := create_tween()
	tween.tween_property(body, "scale", Vector3.ONE * 0.01, 0.6)
	tween.tween_callback(body.queue_free)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "FountainPlate"
	ts.mode = 2                        # PAD — reclined plaque at the rim
	ts.width_m = 0.42
	ts.position = Vector3(-1.5, 0.24, 1.1)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("PAUSED FOUNTAIN",
			"Spacing is speed - wide where it moves fast, tight where the climb dies.\nEvery throw, whatever its speed, bends on the same g.\nPress: one throw finishes its sentence.")
