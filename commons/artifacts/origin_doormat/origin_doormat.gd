extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OriginDoormat

## @identity
## lineage: the Coordinate-system hero — and the taxonomy's rung-0 ruling kept: this
##   category is "a threshold the walk crosses, not a room it stops in", so its hero is
##   literally a DOORMAT. WELCOME TO (0,0,0). Three brass tape-measures unroll from the
##   mat's corner along x, y and z — the y tape runs straight up a pole, where one guest
##   (a fire extinguisher) floats at its address — and every prop nearby wears a swing
##   tag stating its true coordinates in the mat's frame, measured from its transform at
##   build, not typed.
## essence: before a vector, a where — three axes, an origin, an agreed order. The mat
##   IS the agreement: everything else in the scene has an address only because the mat
##   was put down first.
## truth: (0,0,0) is not a place, it is a handshake. Wipe your feet.
##
## The 2026-08-27 brief: surreal fun beautiful applied — even the threshold gets one.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const AXIS_COLORS := {"x": Color(0.82, 0.22, 0.18), "y": Color(0.25, 0.70, 0.30), "z": Color(0.20, 0.42, 0.85)}

# Guests, placed in the mat's frame. The floating one is the y-tape's tenant — the
# vertical street has an address too, which is the surreal beat that carries the rung.
const GUESTS := [
	{"token": "crate", "bead": 0.34, "pos": Vector3(1.5, 0.0, 0.7)},
	{"token": "chladni_plate", "bead": 0.28, "pos": Vector3(0.8, 0.0, -1.1)},
	{"token": "exit_sign", "bead": 0.28, "pos": Vector3(-0.9, 0.0, 1.2)},
	{"token": "fire_extinguisher", "bead": 0.32, "pos": Vector3(0.0, 1.7, 0.0)},
]

@export var seed: int = 3
@export var tape_len: float = 2.4
@export var tick_step: float = 0.5

func _ready() -> void:
	_rng.seed = seed
	_build_mat()
	_build_tapes()
	_build_guests()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "tape_len", "tick_step"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- the agreement ------------------------------------------------------------------

func _build_mat() -> void:
	var mat := MeshInstance3D.new()
	var mat_mesh := BoxMesh.new()
	mat_mesh.size = Vector3(1.1, 0.035, 0.7)
	mat.mesh = mat_mesh
	mat.position = Vector3(0.0, 0.018, 0.0)
	mat.material_override = _matte_mat(Color(0.45, 0.30, 0.16), 0.98)
	add_child(mat)
	var border := MeshInstance3D.new()
	var border_mesh := BoxMesh.new()
	border_mesh.size = Vector3(1.18, 0.03, 0.78)
	border.mesh = border_mesh
	border.position = Vector3(0.0, 0.015, 0.0)
	border.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.98)
	add_child(border)
	var word := TextScreenScript.new()
	word.name = "MatWord"
	word.mode = 2
	word.width_m = 0.62
	word.position = Vector3(0.0, 0.045, 0.0)
	add_child(word)
	if word.has_method("set_text"):
		word.set_text("WELCOME", "TO (0, 0, 0)")

func _build_tapes() -> void:
	# Three tape-measures from the mat's corner, in the agreed order. Brass housings,
	# colored blades, a tick every tick_step with the running count etched larger at
	# full metres. The y blade climbs a slender pole: the vertical street.
	for axis in ["x", "y", "z"]:
		var dir := Vector3(1, 0, 0) if axis == "x" else (Vector3(0, 1, 0) if axis == "y" else Vector3(0, 0, 1))
		var col: Color = AXIS_COLORS[axis]
		var housing := MeshInstance3D.new()
		var housing_mesh := BoxMesh.new()
		housing_mesh.size = Vector3(0.12, 0.1, 0.08)
		housing.mesh = housing_mesh
		housing.position = dir * 0.1 + Vector3(0.0, 0.05, 0.0)
		housing.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
		add_child(housing)
		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		if axis == "y":
			blade_mesh.size = Vector3(0.05, tape_len, 0.012)
			blade.position = Vector3(0.0, tape_len * 0.5 + 0.1, 0.0)
		else:
			blade_mesh.size = Vector3(tape_len, 0.012, 0.05) if axis == "x" else Vector3(0.05, 0.012, tape_len)
			blade.position = dir * (tape_len * 0.5 + 0.1) + Vector3(0.0, 0.03, 0.0)
		blade.mesh = blade_mesh
		blade.material_override = _glow_mat(col, 0.55)
		add_child(blade)
		var n := int(tape_len / tick_step)
		for k in range(1, n + 1):
			var tick := MeshInstance3D.new()
			var tick_mesh := BoxMesh.new()
			var major := k % 2 == 0
			tick_mesh.size = Vector3(0.015, 0.05 if major else 0.03, 0.06) if axis != "x" else Vector3(0.015, 0.05 if major else 0.03, 0.06)
			tick.mesh = tick_mesh
			var d := 0.1 + tick_step * float(k)
			if axis == "y":
				tick.position = Vector3(0.0, d, 0.0)
			else:
				tick.position = dir * d + Vector3(0.0, 0.035, 0.0)
			tick.material_override = _matte_mat(Color(0.1, 0.1, 0.11), 0.6)
			add_child(tick)
		# the y tape needs its pole, or the vertical street is a rumour
		if axis == "y":
			var pole := MeshInstance3D.new()
			var pole_mesh := CylinderMesh.new()
			pole_mesh.top_radius = 0.014
			pole_mesh.bottom_radius = 0.02
			pole_mesh.height = tape_len + 0.15
			pole.mesh = pole_mesh
			pole.position = Vector3(-0.06, (tape_len + 0.15) * 0.5, -0.06)
			pole.material_override = _steel_mat(Color(0.35, 0.35, 0.38))
			add_child(pole)

# --- the guests ---------------------------------------------------------------------

func _build_guests() -> void:
	for row in GUESTS:
		var wrapper := _spawn_prop(row["token"], row["bead"])
		add_child(wrapper)
		var pos: Vector3 = row["pos"]
		wrapper.position = pos + Vector3(0.0, row["bead"] * 0.55 if pos.y == 0.0 else 0.0, 0.0)
		# the swing tag: the guest's address, READ FROM THE TRANSFORM — the tag cannot
		# disagree with the scene, because it is computed from it
		var p := wrapper.position
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.22
		tag.position = p + Vector3(0.16, -row["bead"] * 0.35 if pos.y > 0.0 else 0.12, 0.16)
		tag.rotation.y = deg_to_rad(-25.0)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text("(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z], row["token"])

func _spawn_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("origin_doormat: cast prop %s missing, bead substituted" % token)
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * bead * 0.7
		box.material_override = _matte_mat(Color(0.6, 0.55, 0.5))
		wrapper.add_child(box)
		remove_child(wrapper)
		return wrapper
	var inst: Node3D = packed.instantiate()
	wrapper.add_child(inst)
	var pstack: Array = [inst]
	while not pstack.is_empty():
		var pn: Node = pstack.pop_back()
		if pn is RigidBody3D:
			(pn as RigidBody3D).freeze = true
		for pc in pn.get_children():
			pstack.append(pc)
	var aabb := _merged_aabb(inst)
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if longest > 0.001:
		var k: float = bead / longest
		inst.scale = Vector3.ONE * k
		inst.position = -(aabb.get_center() * k)
	remove_child(wrapper)
	return wrapper

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
			merged = box if first else merged.merge(box)
			first = false
		for child in node.get_children():
			stack.append(child)
	return merged

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "DoormatPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.3, 0.24, 0.6)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("ORIGIN DOORMAT",
			"Before a vector, a where: three axes, an origin, an agreed order.\nEvery guest wears its address in the mat's frame - one arrived vertically.\n(0,0,0) is not a place, it is a handshake. Wipe your feet.")
