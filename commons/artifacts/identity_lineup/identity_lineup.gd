extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name IdentityLineup

## @identity
## lineage: the Invariants hero, and the sequence's soul made furniture — a police
##   lineup of ONE object. Six pedestals under a height chart: the same crate straight,
##   slid, turned, shrunk, mirrored and sheared. Same suspect, six disguises. Under
##   each, a brass tag listing what the disguise FAILED to change — and the lineup's
##   verdict is that the unchanged list is the suspect.
## essence: what a transform leaves unchanged names its kind: translation keeps
##   everything but address, rotation keeps lengths, scale keeps ratios, reflection
##   keeps distances but flips hand, shear keeps areas. Identity is the intersection —
##   what NOTHING here could take away.
## truth: what stays the same when everything changes? That is what a thing is. The
##   sequence's whole question, asked by a crate in six poses.
##
## The 2026-08-27 category-heroes pass, transformation. Identity as topology — the
## lineup is the thesis in one room.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# The six disguises: label, tag of invariants kept, and the pose applied.
const LINEUP := [
	{"label": "ITSELF", "kept": "everything - the control"},
	{"label": "SLID", "kept": "size, angles, hand - not address"},
	{"label": "TURNED", "kept": "size, address-distance - not heading"},
	{"label": "SHRUNK", "kept": "ratios, angles - not size"},
	{"label": "MIRRORED", "kept": "size, angles - not handedness"},
	{"label": "SHEARED", "kept": "area, parallels - not right angles"},
]

@export var seed: int = 9
@export var pitch: float = 0.78

func _ready() -> void:
	_rng.seed = seed
	_build_wall()
	_build_lineup()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "pitch"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_wall() -> void:
	var w := pitch * float(LINEUP.size()) + 0.6
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(w, 1.9, 0.08)
	wall.mesh = wall_mesh
	wall.position = Vector3(0.0, 0.95, -0.55)
	wall.material_override = _matte_mat(Color(0.82, 0.80, 0.76), 0.95)
	add_child(wall)
	# height-chart lines: the lineup's ruled backdrop — five dark strata
	for k in range(5):
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(w, 0.014, 0.012)
		line.mesh = line_mesh
		line.position = Vector3(0.0, 0.4 + 0.3 * float(k), -0.505)
		line.material_override = _matte_mat(Color(0.35, 0.35, 0.37), 0.7)
		add_child(line)

func _build_lineup() -> void:
	for i in range(LINEUP.size()):
		var row: Dictionary = LINEUP[i]
		var x := (float(i) - float(LINEUP.size() - 1) * 0.5) * pitch
		var ped := MeshInstance3D.new()
		var ped_mesh := CylinderMesh.new()
		ped_mesh.top_radius = 0.24
		ped_mesh.bottom_radius = 0.27
		ped_mesh.height = 0.3
		ped.mesh = ped_mesh
		ped.position = Vector3(x, 0.15, 0.0)
		ped.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
		add_child(ped)

		var suspect := _spawn_prop("crate", 0.34)
		add_child(suspect)
		suspect.position = Vector3(x, 0.3 + 0.34 * 0.55, 0.0)
		match row["label"]:
			"SLID":
				suspect.position += Vector3(0.14, 0.0, 0.1)
			"TURNED":
				suspect.rotation.y = deg_to_rad(38.0)
			"SHRUNK":
				suspect.scale = Vector3.ONE * 0.62
				suspect.position.y = 0.3 + 0.34 * 0.55 * 0.62
			"MIRRORED":
				suspect.scale = Vector3(-1.0, 1.0, 1.0)
			"SHEARED":
				var b := suspect.transform.basis
				b.x.y += 0.3
				suspect.transform.basis = b
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.26
		tag.position = Vector3(x, 0.02, 0.42)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(row["label"], "kept: %s" % row["kept"])

func _spawn_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("identity_lineup: cast prop %s missing, bead substituted" % token)
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
	ts.name = "LineupPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(0.0, 0.24, 0.95)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("IDENTITY LINEUP",
			"Same suspect, six disguises. Each tag lists what the disguise could not\ntake away; identity is the intersection of the tags. What stays the same\nwhen everything changes - that is what a thing IS.")
