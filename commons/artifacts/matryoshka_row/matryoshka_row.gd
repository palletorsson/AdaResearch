extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MatryoshkaRow

## @identity
## lineage: the Scaling category's hero — its previous best was a retiring NOC port
##   (example_2_3), so the concept gets a body: the SAME museum fire extinguisher at five
##   scales on one brass rail, quarter-size to four-times, a matryoshka family standing
##   in line. The giant's pedestal BOWS, because volume grows as s³ while the pedestal
##   only asked for s.
## essence: a scalar is a volume knob for a direction — same object, new length. But
##   length is the only thing that scales politely: area goes s², weight s³, and the
##   sagging pedestal under the ×4 is that arithmetic made furniture.
## truth: multiply a thing by s and you multiply its lengths by s, its skin by s², its
##   burden by s³. The pedestal knows before you do.
##
## The 2026-08-27 brief: "for each category take the best of that category but make a
## surreal fun beautiful applied example."

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const PROP := {"token": "fire_extinguisher", "bead": 0.42, "kg": 5.5}
const SCALES := [0.25, 0.5, 1.0, 2.0, 4.0]

@export var seed: int = 21
@export var spacing_base: float = 0.55   # rail gap between neighbours, scaled by size

func _ready() -> void:
	_rng.seed = seed
	_build_rail()
	_build_family()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "spacing_base"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_rail() -> void:
	# One brass rail under the whole family: the shared measure that makes the five
	# read as one object at five sizes, not five objects.
	var total := 0.0
	for s in SCALES:
		total += spacing_base + PROP["bead"] * s
	var rail := MeshInstance3D.new()
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(total + 0.6, 0.05, 0.34)
	rail.mesh = rail_mesh
	rail.position = Vector3(total * 0.5 - 0.3, 0.025, 0.0)
	rail.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(rail)

func _build_family() -> void:
	var x := 0.0
	for i in range(SCALES.size()):
		var s: float = SCALES[i]
		var bead: float = PROP["bead"] * s
		x += spacing_base * 0.5 + bead * 0.5
		_build_member(x, s, bead, i)
		x += spacing_base * 0.5 + bead * 0.5

func _build_member(x: float, s: float, bead: float, i: int) -> void:
	# The pedestal: same DESIGN for all five, but its load grows as s³ while its own
	# strength only grew as s² — so it bows, progressively, and at ×4 it is visibly
	# losing. The bow angle is the lesson drawn in furniture: proportional to s.
	var bow: float = clampf((s - 1.0) * 0.055, 0.0, 0.18)
	var ped_h := 0.34 + bead * 0.22
	var ped := MeshInstance3D.new()
	var ped_mesh := CylinderMesh.new()
	ped_mesh.top_radius = 0.10 + bead * 0.16
	ped_mesh.bottom_radius = 0.13 + bead * 0.16
	ped_mesh.height = ped_h
	ped.mesh = ped_mesh
	ped.position = Vector3(x, 0.05 + ped_h * 0.5, 0.0)
	ped.rotation.z = bow
	ped.material_override = _matte_mat(Color(0.85, 0.83, 0.80).lerp(Color(0.6, 0.5, 0.45), clampf(s / 4.0, 0.0, 1.0)), 0.85)
	add_child(ped)

	var wrapper := _spawn_prop(PROP["token"], bead)
	add_child(wrapper)
	var top := Vector3(x, 0.05 + ped_h, 0.0) + Vector3(sin(bow) * ped_h * 0.5, -(1.0 - cos(bow)) * ped_h * 0.5, 0.0)
	wrapper.position = top + Vector3(0.0, bead * 0.55, 0.0)
	wrapper.rotation.z = bow

	# The factor, etched small at each foot: x1/4 ... x4, with its s2 and s3 shadows.
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.20
	tag.position = Vector3(x, 0.06, 0.30)
	add_child(tag)
	if tag.has_method("set_text"):
		var frac := "1/4" if is_equal_approx(s, 0.25) else ("1/2" if is_equal_approx(s, 0.5) else str(int(s)))
		tag.set_text("x" + frac, "skin x%.2f  weight x%.2f" % [s * s, s * s * s])

func _spawn_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("matryoshka_row: cast prop %s missing, bead substituted" % token)
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * bead * 0.7
		box.material_override = _matte_mat(Color(0.7, 0.25, 0.2))
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
	ts.name = "MatryoshkaPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-0.55, 0.24, 0.65)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("MATRYOSHKA ROW",
			"A scalar is a volume knob for a direction - same object, new length.\nBut only length scales politely: skin goes s2, weight goes s3.\nThe pedestal under the giant knew before you did.")
