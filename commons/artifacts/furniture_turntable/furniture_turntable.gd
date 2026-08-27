extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FurnitureTurntable

## @identity
## lineage: the Rotation hero — a record player scaled up to furniture, playing a crate
##   at 33⅓ rpm. The tonearm rests its needle on the spinning cargo and holds a fixed
##   RADIUS, so the needle traces the circle hidden in the motion; the groove-rings
##   scribed on the platter are all the circles it could have chosen.
## essence: rotation turns without resizing — every point keeps its distance from the
##   spindle and trades only angle. The needle proves it: touching a turning body at
##   constant radius forever, drawing the one invariant a rotation owns.
## truth: rotation is the transform that promises you'll come back. 33⅓ promises a
##   minute has about 33 homecomings.
##
## The 2026-08-27 category-heroes pass, transformation.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 33
@export var platter_r: float = 1.05
@export var rpm: float = 33.333
@export var needle_r: float = 0.62     # the traced circle's radius — the invariant

var _platter: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_deck()
	_build_record()
	_build_tonearm()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "platter_r", "rpm", "needle_r"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	if _platter:
		_platter.rotation.y += rpm * TAU / 60.0 * delta

func _build_deck() -> void:
	var plinth := MeshInstance3D.new()
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(platter_r * 2.0 + 0.9, 0.28, platter_r * 2.0 + 0.6)
	plinth.mesh = plinth_mesh
	plinth.position = Vector3(0.1, 0.14, 0.0)
	plinth.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
	add_child(plinth)
	# the speed selector: two brass buttons, 33 lit, 45 not — a promise, not a knob
	for i in range(2):
		var btn := MeshInstance3D.new()
		var btn_mesh := CylinderMesh.new()
		btn_mesh.top_radius = 0.05
		btn_mesh.bottom_radius = 0.05
		btn_mesh.height = 0.03
		btn.mesh = btn_mesh
		btn.position = Vector3(-platter_r - 0.25, 0.3, -0.25 + 0.5 * float(i))
		btn.material_override = _glow_mat(Color(0.92, 0.75, 0.14), 1.2) if i == 0 else _steel_mat(Color(0.4, 0.4, 0.42))
		add_child(btn)

func _build_record() -> void:
	_platter = Node3D.new()
	_platter.position = Vector3(0.0, 0.28, 0.0)
	add_child(_platter)
	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = platter_r
	disc_mesh.bottom_radius = platter_r
	disc_mesh.height = 0.03
	disc.mesh = disc_mesh
	disc.position = Vector3(0.0, 0.015, 0.0)
	disc.material_override = _matte_mat(Color(0.07, 0.07, 0.08), 0.35, 0.1)
	_platter.add_child(disc)
	# groove rings: the family of circles rotation preserves
	for k in range(5):
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		var r := 0.3 + 0.16 * float(k)
		ring_mesh.inner_radius = r - 0.004
		ring_mesh.outer_radius = r + 0.004
		ring.mesh = ring_mesh
		ring.position = Vector3(0.0, 0.032, 0.0)
		ring.material_override = _matte_mat(Color(0.16, 0.16, 0.18), 0.5)
		_platter.add_child(ring)
	# the label: a red centre with the spindle through it
	var lab := MeshInstance3D.new()
	var lab_mesh := CylinderMesh.new()
	lab_mesh.top_radius = 0.22
	lab_mesh.bottom_radius = 0.22
	lab_mesh.height = 0.034
	lab.mesh = lab_mesh
	lab.position = Vector3(0.0, 0.016, 0.0)
	lab.material_override = _matte_mat(Color(0.78, 0.16, 0.12), 0.7)
	_platter.add_child(lab)
	var spindle := MeshInstance3D.new()
	var spindle_mesh := CylinderMesh.new()
	spindle_mesh.top_radius = 0.015
	spindle_mesh.bottom_radius = 0.015
	spindle_mesh.height = 0.12
	spindle.mesh = spindle_mesh
	spindle.position = Vector3(0.0, 0.06, 0.0)
	spindle.material_override = _steel_mat(Color(0.7, 0.7, 0.72))
	_platter.add_child(spindle)
	# THE RECORD IS A CRATE — cargo pressed as vinyl, spinning at needle_r's mercy
	var cargo := _spawn_prop("crate", 0.36)
	_platter.add_child(cargo)
	cargo.position = Vector3(needle_r, 0.21, 0.0)

func _build_tonearm() -> void:
	# pivot post outside the platter; the arm reaches IN to needle_r and stays there
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.045
	post_mesh.bottom_radius = 0.055
	post_mesh.height = 0.5
	post.mesh = post_mesh
	post.position = Vector3(platter_r + 0.28, 0.53, -0.45)
	post.material_override = _steel_mat(Color(0.7, 0.7, 0.72))
	add_child(post)
	var arm_from := Vector3(platter_r + 0.28, 0.78, -0.45)
	var arm_to := Vector3(needle_r, 0.62, 0.0)
	var arm := MeshInstance3D.new()
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.02
	arm_mesh.bottom_radius = 0.02
	arm_mesh.height = arm_from.distance_to(arm_to)
	arm.mesh = arm_mesh
	arm.position = (arm_from + arm_to) * 0.5
	arm.look_at_from_position(arm.position, arm_to, Vector3.UP)
	arm.rotation.x += PI * 0.5
	arm.material_override = _steel_mat(Color(0.7, 0.7, 0.72))
	add_child(arm)
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.09, 0.05, 0.14)
	head.mesh = head_mesh
	head.position = arm_to + Vector3(0.0, 0.03, 0.0)
	head.material_override = _matte_mat(Color(0.10, 0.10, 0.11), 0.6)
	add_child(head)
	var needle := MeshInstance3D.new()
	var needle_mesh := CylinderMesh.new()
	needle_mesh.top_radius = 0.002
	needle_mesh.bottom_radius = 0.012
	needle_mesh.height = 0.1
	needle.mesh = needle_mesh
	needle.position = arm_to + Vector3(0.0, -0.05, 0.0)
	needle.material_override = _glow_mat(Color(0.95, 0.85, 0.40), 1.2)
	add_child(needle)
	# the traced circle, faint on the platter at exactly needle_r: rotation's invariant
	var traced := MeshInstance3D.new()
	var traced_mesh := TorusMesh.new()
	traced_mesh.inner_radius = needle_r - 0.006
	traced_mesh.outer_radius = needle_r + 0.006
	traced.mesh = traced_mesh
	traced.position = Vector3(0.0, 0.315, 0.0)
	var tm := _glow_mat(Color(0.95, 0.85, 0.40), 0.7)
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.albedo_color.a = 0.4
	traced.material_override = tm
	add_child(traced)

func _spawn_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("furniture_turntable: cast prop %s missing, bead substituted" % token)
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
	ts.name = "TurntablePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(platter_r + 0.8), 0.24, platter_r * 0.7)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("FURNITURE TURNTABLE - 33 1/3",
			"Rotation turns without resizing: the cargo keeps its distance from the\nspindle and trades only angle. The needle holds one radius forever -\nthe circle hidden in the motion. About 33 homecomings a minute.")
