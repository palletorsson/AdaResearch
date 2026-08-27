extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SleepwalkingBed

## @identity
## lineage: the Translation hero — a bed that drifts around its bedroom rug in a slow
##   figure, nightstand keeping station beside it, the glass of water unspilled, the
##   fire extinguisher (every bedroom has one here) never leaving its post at the foot.
##   Nothing on the bed changes. Only where the bed IS changes.
## essence: translation preserves everything except position — lengths, angles, the
##   water's level, the argument between pillow and blanket. The room is the proof:
##   the ensemble slides as one rigid sentence and arrives unchanged, elsewhere.
## truth: translation is the loneliest transform: it changes nothing about you, only
##   your address. The sleeper never notices.
##
## The 2026-08-27 category-heroes pass, transformation.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 4
@export var wander_x: float = 1.3      # half-extent of the drift, m
@export var wander_z: float = 0.85
@export var lap_time: float = 18.0

var _ensemble: Node3D
var _t := 0.0

func _ready() -> void:
	_rng.seed = seed
	_build_rug()
	_build_ensemble()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "wander_x", "wander_z", "lap_time"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	if _ensemble == null:
		return
	_t += delta * TAU / lap_time
	# a Lissajous drift: covers the rug, never repeats exactly soon, and NO rotation —
	# the ensemble's yaw is constant by construction, which is the definition at work
	_ensemble.position = Vector3(sin(_t) * wander_x, 0.0, sin(_t * 2.0 + 1.3) * wander_z)

func _build_rug() -> void:
	var rug := MeshInstance3D.new()
	var rug_mesh := BoxMesh.new()
	rug_mesh.size = Vector3(wander_x * 2.0 + 2.4, 0.03, wander_z * 2.0 + 2.0)
	rug.mesh = rug_mesh
	rug.position = Vector3(0.0, 0.015, 0.0)
	rug.material_override = _matte_mat(Color(0.24, 0.20, 0.30), 0.95)
	add_child(rug)
	var border := MeshInstance3D.new()
	var border_mesh := BoxMesh.new()
	border_mesh.size = Vector3(rug_mesh.size.x + 0.16, 0.024, rug_mesh.size.z + 0.16)
	border.mesh = border_mesh
	border.position = Vector3(0.0, 0.012, 0.0)
	border.material_override = _matte_mat(Color(0.75, 0.65, 0.42), 0.9)
	add_child(border)

func _build_ensemble() -> void:
	_ensemble = Node3D.new()
	add_child(_ensemble)
	# THE BED: frame, mattress, pillow, blanket — the sleeper is implied by the dent
	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1.9, 0.22, 1.0)
	frame.mesh = frame_mesh
	frame.position = Vector3(0.0, 0.21, 0.0)
	frame.material_override = _matte_mat(Color(0.35, 0.22, 0.12), 0.85)
	_ensemble.add_child(frame)
	for sx in [-0.88, 0.88]:
		for sz in [-0.42, 0.42]:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.035
			leg_mesh.bottom_radius = 0.03
			leg_mesh.height = 0.2
			leg.mesh = leg_mesh
			leg.position = Vector3(sx, 0.1, sz)
			leg.material_override = _matte_mat(Color(0.25, 0.16, 0.09), 0.85)
			_ensemble.add_child(leg)
	var mattress := MeshInstance3D.new()
	var mattress_mesh := BoxMesh.new()
	mattress_mesh.size = Vector3(1.84, 0.16, 0.94)
	mattress.mesh = mattress_mesh
	mattress.position = Vector3(0.0, 0.4, 0.0)
	mattress.material_override = _matte_mat(Color(0.88, 0.86, 0.82), 0.95)
	_ensemble.add_child(mattress)
	var blanket := MeshInstance3D.new()
	var blanket_mesh := BoxMesh.new()
	blanket_mesh.size = Vector3(1.1, 0.06, 0.96)
	blanket.mesh = blanket_mesh
	blanket.position = Vector3(-0.3, 0.5, 0.0)
	blanket.material_override = _matte_mat(Color(0.13, 0.30, 0.62), 0.9)
	_ensemble.add_child(blanket)
	var pillow := MeshInstance3D.new()
	var pillow_mesh := CapsuleMesh.new()
	pillow_mesh.radius = 0.11
	pillow_mesh.height = 0.5
	pillow.mesh = pillow_mesh
	pillow.rotation.z = PI * 0.5
	pillow.rotation.y = PI * 0.5
	pillow.position = Vector3(0.72, 0.52, 0.0)
	pillow.material_override = _matte_mat(Color(0.92, 0.90, 0.86), 0.95)
	_ensemble.add_child(pillow)

	# THE NIGHTSTAND, keeping station: a glass of water whose stillness is the claim
	var stand := MeshInstance3D.new()
	var stand_mesh := BoxMesh.new()
	stand_mesh.size = Vector3(0.4, 0.5, 0.4)
	stand.mesh = stand_mesh
	stand.position = Vector3(1.35, 0.25, 0.45)
	stand.material_override = _matte_mat(Color(0.35, 0.22, 0.12), 0.85)
	_ensemble.add_child(stand)
	var glass := MeshInstance3D.new()
	var glass_mesh := CylinderMesh.new()
	glass_mesh.top_radius = 0.05
	glass_mesh.bottom_radius = 0.04
	glass_mesh.height = 0.12
	glass.mesh = glass_mesh
	glass.position = Vector3(1.35, 0.56, 0.45)
	var gm := StandardMaterial3D.new()
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color = Color(0.7, 0.85, 0.9, 0.35)
	glass.material_override = gm
	_ensemble.add_child(glass)
	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 0.044
	water_mesh.bottom_radius = 0.038
	water_mesh.height = 0.07
	water.mesh = water_mesh
	water.position = Vector3(1.35, 0.545, 0.45)
	water.material_override = _glow_mat(Color(0.25, 0.5, 0.7), 0.4)
	_ensemble.add_child(water)

	# the household guardian at the foot, cast from the corpus
	var guard := _spawn_prop("fire_extinguisher", 0.3)
	_ensemble.add_child(guard)
	guard.position = Vector3(-1.15, 0.17, 0.35)

func _spawn_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("sleepwalking_bed: cast prop %s missing, bead substituted" % token)
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

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "BedPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(wander_x + 1.4), 0.24, wander_z + 0.9)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("SLEEPWALKING BED",
			"Translation preserves everything except position: the water's level,\nthe pillow's argument with the blanket, the guardian at the foot.\nOnly the address changes. The sleeper never notices.")
