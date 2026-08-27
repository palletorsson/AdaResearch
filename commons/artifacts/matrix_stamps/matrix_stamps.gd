extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MatrixStamps

## @identity
## lineage: the Matrix/homogeneous hero — a passport office for geometry. Four brass
##   rubber stamps stand in a desk rack, each with its 4×4 engraved on the face:
##   TRANSLATE, ROTATE, SCALE, SHEAR. Before the desk, a plain crate; behind it, the
##   same crate STAMPED — slid, turned, shrunk and slanted, ink still wet — with its
##   visa (the composed matrix) displayed beside the exit.
## essence: every transform is a matrix, and homogeneous coordinates are what let
##   translation join the rubber-stamp rack at all — the fourth row is the office's
##   legal fiction, and it works. Stamping in sequence multiplies; the passport
##   remembers the order.
## truth: a matrix is bureaucracy for space: four rows of rules, applied with one
##   thump. The fiction in row four is what makes the office universal.
##
## The 2026-08-27 category-heroes pass, transformation.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const STAMPS := [
	{"label": "TRANSLATE", "col": Color(0.13, 0.30, 0.62), "rows": "1 0 0 tx"},
	{"label": "ROTATE", "col": Color(0.78, 0.16, 0.12), "rows": "c -s 0 0"},
	{"label": "SCALE", "col": Color(0.92, 0.75, 0.14), "rows": "s 0 0 0"},
	{"label": "SHEAR", "col": Color(0.20, 0.42, 0.17), "rows": "1 k 0 0"},
]

@export var seed: int = 44
@export var desk_w: float = 2.2

func _ready() -> void:
	_rng.seed = seed
	_build_desk()
	_build_stamps()
	_build_applicant_and_stamped()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "desk_w"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_desk() -> void:
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(desk_w, 0.07, 0.9)
	top.mesh = top_mesh
	top.position = Vector3(0.0, 0.86, 0.0)
	top.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
	add_child(top)
	for sx in [-desk_w * 0.5 + 0.08, desk_w * 0.5 - 0.08]:
		var panel := MeshInstance3D.new()
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(0.07, 0.82, 0.84)
		panel.mesh = panel_mesh
		panel.position = Vector3(sx, 0.41, 0.0)
		panel.material_override = _matte_mat(Color(0.25, 0.16, 0.09), 0.85)
		add_child(panel)
	# the ink pad: one shared red pad — every transform signs in the same ink
	var pad := MeshInstance3D.new()
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(0.26, 0.05, 0.2)
	pad.mesh = pad_mesh
	pad.position = Vector3(0.0, 0.92, 0.28)
	pad.material_override = _glow_mat(Color(0.6, 0.1, 0.1), 0.4)
	add_child(pad)

func _build_stamps() -> void:
	var n := STAMPS.size()
	for i in range(n):
		var s: Dictionary = STAMPS[i]
		var x := (float(i) - float(n - 1) * 0.5) * (desk_w / float(n))
		var handle := MeshInstance3D.new()
		var handle_mesh := CylinderMesh.new()
		handle_mesh.top_radius = 0.035
		handle_mesh.bottom_radius = 0.05
		handle_mesh.height = 0.2
		handle.mesh = handle_mesh
		handle.position = Vector3(x, 1.12, -0.12)
		handle.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
		add_child(handle)
		var knob := MeshInstance3D.new()
		var knob_mesh := SphereMesh.new()
		knob_mesh.radius = 0.05
		knob_mesh.height = 0.1
		knob.mesh = knob_mesh
		knob.position = Vector3(x, 1.25, -0.12)
		knob.material_override = _matte_mat(s["col"], 0.7)
		add_child(knob)
		var face := MeshInstance3D.new()
		var face_mesh := BoxMesh.new()
		face_mesh.size = Vector3(0.2, 0.05, 0.2)
		face.mesh = face_mesh
		face.position = Vector3(x, 0.995, -0.12)
		face.material_override = _matte_mat(Color(0.10, 0.10, 0.11), 0.6)
		add_child(face)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.24
		tag.position = Vector3(x, 0.9, -0.42)
		tag.rotation.y = PI
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(s["label"], "| %s |  row 4: 0 0 0 1" % s["rows"])

func _build_applicant_and_stamped() -> void:
	# the applicant: a plain crate on the IN tray
	var applicant := _spawn_prop("crate", 0.34)
	add_child(applicant)
	applicant.position = Vector3(-desk_w * 0.5 - 0.5, 0.17, 0.35)
	var in_tag := TextScreenScript.new()
	in_tag.mode = 2
	in_tag.width_m = 0.2
	in_tag.position = Vector3(-desk_w * 0.5 - 0.5, 0.02, 0.75)
	add_child(in_tag)
	if in_tag.has_method("set_text"):
		in_tag.set_text("APPLICANT", "untransformed")
	# the stamped: the same crate after T*R*S*shear — slid, turned, shrunk, slanted,
	# and inked. The pose IS the product matrix, applied honestly.
	var stamped := _spawn_prop("crate", 0.34)
	add_child(stamped)
	stamped.position = Vector3(desk_w * 0.5 + 0.62, 0.13, 0.28)
	stamped.rotation.y = deg_to_rad(35.0)
	stamped.scale = Vector3(0.75, 0.75, 0.75)
	# shear, as the one component a Node3D transform must be HANDED explicitly
	var b := stamped.transform.basis
	b.x.y += 0.28
	stamped.transform.basis = b
	var ink := MeshInstance3D.new()
	var ink_mesh := CylinderMesh.new()
	ink_mesh.top_radius = 0.09
	ink_mesh.bottom_radius = 0.09
	ink_mesh.height = 0.012
	ink.mesh = ink_mesh
	ink.position = stamped.position + Vector3(0.0, 0.26, 0.0)
	ink.rotation.z = 0.2
	ink.material_override = _glow_mat(Color(0.6, 0.1, 0.1), 0.7)
	add_child(ink)
	var out_tag := TextScreenScript.new()
	out_tag.mode = 2
	out_tag.width_m = 0.24
	out_tag.position = Vector3(desk_w * 0.5 + 0.62, 0.02, 0.75)
	add_child(out_tag)
	if out_tag.has_method("set_text"):
		out_tag.set_text("STAMPED", "T*R*S*shear - one matrix now, the passport remembers the order")

func _spawn_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("matrix_stamps: cast prop %s missing, bead substituted" % token)
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
	ts.name = "StampsPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(0.0, 0.24, 0.95)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("MATRIX STAMPS - the passport office",
			"Every transform is a matrix: four rows of rules, applied with one thump.\nRow four is the office's legal fiction - homogeneous coordinates - and it is\nwhat lets TRANSLATE join the rack at all. The passport remembers the order.")
