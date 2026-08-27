extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BaggageGrammar

## @identity
## lineage: the Three-rigid-motions hero — the grammar of motion staged as baggage
##   claim. One crate rides a belt loop forever: the straights TRANSLATE it, the corners
##   ROTATE it, and the customs arch SCALES it (shrunk on entry, restored on exit,
##   nothing declared). Three verbs, one suitcase, no destination.
## essence: translation, rotation, scale — every rigid journey is spelled with these
##   letters. The belt is the sentence: slide, turn, slide, shrink-through, turn, slide,
##   grow-back. The suitcase is unchanged in everything but pose and size, which is the
##   grammar's whole vocabulary.
## truth: motion has a grammar of three verbs. An airport is a sentence machine that
##   reads your luggage aloud.
##
## The 2026-08-27 category-heroes pass, transformation: surreal fun beautiful applied.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 6
@export var belt_w: float = 2.6        # loop width  (x)
@export var belt_d: float = 1.6        # loop depth  (z)
@export var lap_time: float = 12.0
## Scale through customs: the arch stamps the suitcase to 55% and the far straight
## restores it — scale, demonstrated and then confessed reversible.
@export var customs_scale: float = 0.55

var _case: Node3D
var _label: Node3D
var _t := 0.0

func _ready() -> void:
	_rng.seed = seed
	_build_belt()
	_build_case()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "belt_w", "belt_d", "lap_time", "customs_scale"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	if _case == null:
		return
	_t = fmod(_t + delta / lap_time, 1.0)
	var pose := _pose_at(_t)
	_case.position = pose[0]
	_case.rotation.y = pose[1]
	_case.scale = Vector3.ONE * pose[2]
	if _label and _label.has_method("set_text"):
		_label.set_text(pose[3], "the grammar of motion, spoken by luggage")

## The loop, parameterised 0..1: four straights and four quarter-turn corners around
## a rounded rectangle. Returns [position, yaw, scale, current-verb].
func _pose_at(u: float) -> Array:
	var hw := belt_w * 0.5
	var hd := belt_d * 0.5
	var straight := 2.0 * (hw + hd)
	var corner := TAU * 0.25 * 0.35 * 4.0
	var total := straight * 2.0 + corner        # x-straights twice, z-straights twice folded in
	var d := u * (2.0 * belt_w + 2.0 * belt_d)
	var y := 0.62
	# side 1: front straight, +x — TRANSLATION (and customs at its middle)
	if d < belt_w:
		var x := -hw + d
		var s := 1.0
		var verb := "TRANSLATING"
		if absf(x) < 0.35:
			s = customs_scale
			verb = "SCALED - customs"
		return [Vector3(x, y, hd), 0.0, s, verb]
	d -= belt_w
	# corner 1 — ROTATION
	if d < belt_d:
		var z := hd - d
		return [Vector3(hw, y, z), -PI * 0.5 * clampf(d / (belt_d * 0.4), 0.0, 1.0), customs_scale if d < belt_d * 0.5 else 1.0, "ROTATING" if d < belt_d * 0.4 else "TRANSLATING"]
	d -= belt_d
	# side 3: back straight, -x — restored size
	if d < belt_w:
		return [Vector3(hw - d, y, -hd), -PI, 1.0, "TRANSLATING"]
	d -= belt_w
	# corner 2 back to start — ROTATION
	return [Vector3(-hw, y, -hd + d), -PI - PI * 0.5 * clampf(d / (belt_d * 0.4), 0.0, 1.0), 1.0, "ROTATING" if d < belt_d * 0.4 else "TRANSLATING"]

func _build_belt() -> void:
	var hw := belt_w * 0.5
	var hd := belt_d * 0.5
	# the belt: four dark rubber straights with steel skirts
	for side in range(4):
		var seg := MeshInstance3D.new()
		var seg_mesh := BoxMesh.new()
		var along_x := side % 2 == 0
		seg_mesh.size = Vector3(belt_w + 0.5, 0.08, 0.55) if along_x else Vector3(0.55, 0.08, belt_d + 0.5)
		seg.mesh = seg_mesh
		var off := hd if side == 0 else (-hd if side == 2 else 0.0)
		var offx := hw if side == 1 else (-hw if side == 3 else 0.0)
		seg.position = Vector3(offx, 0.5, off)
		seg.material_override = _matte_mat(Color(0.10, 0.10, 0.12), 0.9)
		add_child(seg)
		var skirt := MeshInstance3D.new()
		var skirt_mesh := BoxMesh.new()
		skirt_mesh.size = Vector3(seg_mesh.size.x, 0.5, seg_mesh.size.z)
		skirt.mesh = skirt_mesh
		skirt.position = Vector3(offx, 0.25, off)
		skirt.material_override = _steel_mat(Color(0.42, 0.44, 0.48))
		add_child(skirt)
	# customs: a brass arch over the front straight's middle
	var arch := MeshInstance3D.new()
	var arch_mesh := TorusMesh.new()
	arch_mesh.inner_radius = 0.46
	arch_mesh.outer_radius = 0.56
	arch.mesh = arch_mesh
	arch.position = Vector3(0.0, 0.62, hd)
	arch.rotation.x = PI * 0.5
	arch.rotation.y = 0.0
	arch.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(arch)
	var sign := TextScreenScript.new()
	sign.mode = 2
	sign.width_m = 0.3
	sign.position = Vector3(0.0, 1.35, hd)
	add_child(sign)
	if sign.has_method("set_text"):
		sign.set_text("CUSTOMS", "x%.2f - nothing to declare" % customs_scale)

func _build_case() -> void:
	_case = Node3D.new()
	add_child(_case)
	var packed: PackedScene = load("res://commons/artifacts/crate/crate.tscn")
	if packed != null:
		var inst: Node3D = packed.instantiate()
		_case.add_child(inst)
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
			var k: float = 0.42 / longest
			inst.scale = Vector3.ONE * k
			inst.position = -(aabb.get_center() * k)
	else:
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * 0.3
		box.material_override = _matte_mat(Color(0.5, 0.35, 0.2))
		_case.add_child(box)
	# a luggage strap and tag, so the crate reads as a suitcase on tour
	var strap := MeshInstance3D.new()
	var strap_mesh := BoxMesh.new()
	strap_mesh.size = Vector3(0.44, 0.05, 0.44)
	strap.mesh = strap_mesh
	strap.material_override = _matte_mat(Color(0.78, 0.16, 0.12), 0.7)
	_case.add_child(strap)
	_label = TextScreenScript.new()
	_label.mode = 2
	_label.width_m = 0.26
	_label.position = Vector3(0.0, 0.35, 0.0)
	_case.add_child(_label)

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
	ts.name = "BaggagePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(belt_w * 0.5 + 0.6), 0.24, belt_d * 0.5 + 0.5)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("BAGGAGE GRAMMAR",
			"Motion has three verbs: translate on the straights, rotate at the corners,\nscale through customs (restored on the far side - nothing to declare).\nAn airport is a sentence machine that reads your luggage aloud.")
