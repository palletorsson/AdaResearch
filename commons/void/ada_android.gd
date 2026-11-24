extends Node3D
## Ada's visible armor follows the player rig. The walker still owns collision.

const SEGMENTS := 24
const HIP_Y := 0.887
const SHOULDER_Y := 1.385
const HAND_REST_ROLL := Basis(Vector3.UP, PI)
const KnitShell := preload("res://commons/void/ada_knit_shell.gd")
const Look := preload("res://commons/void/ada_look.gd")
const PROFILE_LIMITS := {
	"shoulders": Vector2(0.80, 1.30),
	"waist": Vector2(0.80, 1.25),
	"hips": Vector2(0.82, 1.28),
	"step_length": Vector2(0.65, 1.30),
}
var head: Node3D
var headwear_mount: Node3D
var profile := {"shoulders": 1.0, "waist": 1.0, "hips": 1.0, "step_length": 1.0}
var look := Look.DEFAULT.duplicate(true)
var _armor := _finish(Color("37333f"), 0.58, 0.26)
var _helmet_finish := _finish(Color("37333f"), 0.58, 0.26)
var _body_coat: ShaderMaterial
var _head_coat: ShaderMaterial
var _dark := _finish(Color("19171f"), 0.35, 0.40)
var _chrome := _finish(Color("9a889c"), 0.76, 0.22)
var _visor := _finish(Color("211729"), 0.49, 0.15)
var _pink := _finish(Color("e14c90"), 0.28, 0.31)
var _legs: Array[Dictionary] = []
var _arms: Array[Dictionary] = []
var _knit: KnitShell
var _armor_pieces: Array[Node3D] = []
var _phase := 0.0
var _stride := 0.0
var _step_direction := Vector3.FORWARD
var dance_mode: String = ""
var dance_beat: float = 0.0


func assemble(head_layers: int, tracked_hands: bool, add_knit := true) -> void:
	_pink.emission_enabled = true
	_pink.emission = Color("fb4394")
	_pink.emission_energy_multiplier = 0.38
	_build_torso()
	_build_head(head_layers)
	for side in [-1.0, 1.0]:
		_legs.append(_build_leg(side))
		_arms.append(_build_arm(side, tracked_hands))
	pose(0.0, Vector3.ZERO, true, Basis.IDENTITY, [])
	if add_knit:
		# Sample the neutral pose once so the spray travels with the plates.
		_body_coat = Look.material(false, true, 0.26, 0.58)
		_head_coat = Look.material(false, true, 0.26, 0.58)
		_prepare_armor_coats(self)
		_build_knit(head_layers)
		set_look(look)


## A descendant's transform in an ancestor's space, composed from the local transforms between them. In the
## tree it equals ancestor.global_transform.affine_inverse() * node.global_transform; unlike that it is also
## true BEFORE the body is in the tree. The roof crate assembles its three copies first and adds them after:
## the global transforms printed "!is_inside_tree()" 456 times, returned identity (hands and coat shading of
## the copies sampled in the wrong space) and failed floor 0's model export.
func _relative_to(node: Node, ancestor: Node) -> Transform3D:
	var out := Transform3D.IDENTITY
	var step := node
	while step != null and step != ancestor:
		if step is Node3D: out = (step as Node3D).transform * out
		step = step.get_parent()
	return out


func _prepare_armor_coats(parent: Node3D) -> void:
	for child in parent.get_children():
		if not child is Node3D or child == _arms[0].end or child == _arms[1].end:
			continue
		if child is MeshInstance3D and child.material_override in [_armor, _helmet_finish]:
			var helmet: bool = child.material_override == _helmet_finish
			var local_to_body: Transform3D = _relative_to(child, self)
			var mesh := ArrayMesh.new()
			for index in child.mesh.get_surface_count():
				var arrays: Array = child.mesh.surface_get_arrays(index)
				var heights := PackedColorArray()
				for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
					var height := (local_to_body * point).y
					var unit := clampf(inverse_lerp(1.532, 1.785, height) if helmet else inverse_lerp(0.05, 1.45, height), 0.0, 1.0)
					heights.append(Color(unit, 0.0, 0.0, 1.0))
				arrays[Mesh.ARRAY_COLOR] = heights
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			child.mesh = mesh
			child.material_override = _head_coat if helmet else _body_coat
		_prepare_armor_coats(child)


func _build_knit(head_layers: int) -> void:
	for piece in get_children():
		if piece != head and piece != _arms[0].end and piece != _arms[1].end:
			_armor_pieces.append(piece as Node3D)
	for piece in head.get_children():
		if piece != headwear_mount:
			_armor_pieces.append(piece as Node3D)
	var anchors := {
		"Thorax": get_node("Thorax"),
		"WaistBellows": get_node("WaistBellows"),
		"PelvicShell": get_node("PelvicShell"),
	}
	for index in 2:
		var side := "L" if index == 0 else "R"
		anchors["Arm" + side + "Upper"] = _arms[index].upper
		anchors["Arm" + side + "Lower"] = _arms[index].lower
		anchors["Leg" + side + "Upper"] = _legs[index].upper
		anchors["Leg" + side + "Lower"] = _legs[index].lower
		anchors["Leg" + side + "End"] = _legs[index].end
	_knit = KnitShell.new()
	_knit.name = "KnitShell"
	add_child(_knit)
	_knit.attach(anchors, head, head_layers)


func set_look(appearance: Dictionary) -> void:
	look = appearance.duplicate(true)
	var knit: bool = is_instance_valid(_knit) and look.shell == "Knit"
	for piece in _armor_pieces:
		piece.visible = not knit
	_armor.albedo_color = Color(look.body.base)
	_helmet_finish.albedo_color = Color(look.face.base)
	if _body_coat != null:
		Look.apply(_body_coat, look.body)
		Look.apply(_head_coat, look.face)
	if is_instance_valid(_knit):
		_knit.set_look(look)
		_knit.follow_rig()


func set_proportions(values: Dictionary) -> void:
	for key in PROFILE_LIMITS:
		var value := float(values.get(key, profile[key]))
		if is_finite(value):
			profile[key] = clampf(value, PROFILE_LIMITS[key].x, PROFILE_LIMITS[key].y)
	get_node("Thorax").scale.x = profile.shoulders
	get_node("PelvicShell").scale.x = profile.hips
	get_node("WaistBellows").scale.x = profile.waist
	for child in get_children():
		if child.name.begins_with("AbdominalPlate"):
			child.scale.x = profile.waist
	if is_instance_valid(_knit):
		_knit.follow_rig()


func _build_torso() -> void:
	_loft(self, "Thorax", [
		[1.105, 0.108, 0.076, 0.063], [1.14, 0.117, 0.099, 0.071],
		[1.20, 0.144, 0.126, 0.080], [1.27, 0.157, 0.136, 0.083],
		[1.35, 0.162, 0.113, 0.087], [1.406, 0.154, 0.077, 0.076],
		[1.463, 0.073, 0.048, 0.045], [1.47, 0.059, 0.043, 0.040],
	], _armor)
	_loft(self, "WaistBellows", [
		[0.916, 0.129, 0.069, 0.082], [0.971, 0.106, 0.071, 0.070],
		[1.03, 0.099, 0.071, 0.065], [1.105, 0.111, 0.078, 0.065],
		[1.165, 0.120, 0.074, 0.067],
	], _dark)
	for y in [0.979, 1.025, 1.071]:
		_loft(self, "AbdominalPlate", [
			[y - 0.015, 0.097, 0.068, 0.065], [y, 0.105, 0.083, 0.072],
			[y + 0.016, 0.105, 0.078, 0.068],
		], _armor)
	_loft(self, "PelvicShell", [
		[0.770, 0.065, 0.058, 0.059], [0.825, 0.122, 0.078, 0.089],
		[0.88, 0.162, 0.091, 0.101], [0.926, 0.151, 0.081, 0.096],
		[0.966, 0.117, 0.065, 0.073],
	], _armor)
	_ball(self, "CoreBezel", Vector3(0, 1.323, -0.125), Vector3(0.026, 0.035, 0.014), _chrome)
	_ball(self, "CoreLight", Vector3(0, 1.323, -0.134), Vector3(0.012, 0.021, 0.007), _pink)
	for i in 5:
		_ball(self, "SpineHinge", Vector3(0, 1.065 + i * 0.073, 0.074 + i * 0.003),
			Vector3(0.031, 0.013, 0.013), _chrome)


func _build_head(layers: int) -> void:
	_loft(self, "NeckActuator", [
		[1.445, 0.043, 0.037, 0.036], [1.475, 0.038, 0.036, 0.035],
		[1.481, 0.039, 0.037, 0.036], [1.506, 0.034, 0.031, 0.032],
		[1.541, 0.044, 0.038, 0.040], [1.56, 0.040, 0.037, 0.037],
	], _chrome).layers = layers
	head = Node3D.new()
	head.name = "AdaHelmet"
	head.position = Vector3(0, 1.65, -0.022)
	add_child(head)
	_loft(head, "HelmetShell", [
		[-0.118, 0.039, 0.068, 0.036], [-0.101, 0.062, 0.087, 0.057],
		[-0.063, 0.083, 0.102, 0.082], [-0.013, 0.097, 0.110, 0.097],
		[0.047, 0.104, 0.102, 0.100], [0.084, 0.096, 0.088, 0.093],
		[0.120, 0.066, 0.060, 0.068], [0.135, 0.032, 0.034, 0.034],
	], _helmet_finish)
	_loft(head, "VisorGasket", [
		[-0.031, 0.099, 0.112, 0.100], [-0.018, 0.105, 0.116, 0.100],
		[0.020, 0.109, 0.114, 0.100], [0.048, 0.108, 0.107, 0.100],
	], _dark, PI * 1.09, PI * 1.91)
	_loft(head, "VisorGlass", [
		[-0.018, 0.107, 0.117, 0.100], [-0.005, 0.110, 0.121, 0.100],
		[0.026, 0.111, 0.117, 0.100], [0.043, 0.109, 0.111, 0.100],
	], _visor, PI * 1.12, PI * 1.88)
	_loft(head, "PinkSightline", [
		[0.004, 0.111, 0.123, 0.100], [0.010, 0.111, 0.123, 0.100],
	], _pink, PI * 1.18, PI * 1.82)
	for side in [-1.0, 1.0]:
		_pivot(head, "TempleSocket", Vector3(side * 0.101, 0.033, 0.008), 0.032, 0.025, _chrome)
		_pivot(head, "TempleInset", Vector3(side * 0.114, 0.033, 0.008), 0.016, 0.005, _pink)
	for piece in head.get_children():
		piece.layers = layers
	headwear_mount = Node3D.new()
	headwear_mount.name = "HeadwearMount"
	headwear_mount.position.y = 0.10
	head.add_child(headwear_mount)


func _build_leg(side: float) -> Dictionary:
	var bearing := _ball(self, "HipBearing", Vector3(side * 0.110, HIP_Y - 0.015, 0.0),
		Vector3(0.050, 0.047, 0.049), _dark)
	var thigh := _loft(self, "ThighArmor", [
		[0.05, 0.041, 0.044, 0.042], [0.15, 0.056, 0.059, 0.051],
		[0.62, 0.069, 0.073, 0.065], [0.82, 0.070, 0.071, 0.065],
		[0.93, 0.053, 0.054, 0.050],
	], _armor)
	var shin := _loft(self, "ShinArmor", [
		[0.05, 0.031, 0.039, 0.030], [0.20, 0.036, 0.046, 0.036],
		[0.57, 0.048, 0.057, 0.052], [0.79, 0.049, 0.051, 0.049],
		[0.90, 0.036, 0.040, 0.037],
	], _armor)
	var knee := Node3D.new()
	knee.name = "KneeJoint"
	add_child(knee)
	_ball(knee, "JointHousing", Vector3.ZERO, Vector3(0.049, 0.046, 0.047), _dark)
	_pivot(knee, "Axle", Vector3(side * 0.039, 0, 0), 0.026, 0.023, _chrome)
	_ball(knee, "Kneecap", Vector3(0, 0.005, -0.040), Vector3(0.033, 0.040, 0.020), _armor)
	var boot := _loft(self, "Boot", [
		[-0.066, 0.045, 0.122, 0.043], [-0.055, 0.052, 0.132, 0.048],
		[-0.026, 0.049, 0.122, 0.044], [0.001, 0.041, 0.077, 0.043],
		[0.026, 0.032, 0.037, 0.034],
	], _armor)
	return {"side": side, "bearing": bearing, "upper": thigh, "joint": knee, "lower": shin, "end": boot}


func _build_arm(side: float, tracked_hand: bool) -> Dictionary:
	var shoulder := Vector3(side * 0.178, SHOULDER_Y, 0.007)
	var bearing := _ball(self, "ShoulderBearing", shoulder, Vector3(0.061, 0.057, 0.059), _dark)
	var upper := _loft(self, "UpperArmArmor", [
		[0.07, 0.027, 0.031, 0.026], [0.24, 0.040, 0.038, 0.037],
		[0.63, 0.048, 0.047, 0.044], [0.85, 0.063, 0.062, 0.059],
		[1.08, 0.054, 0.052, 0.055], [1.18, 0.031, 0.034, 0.037],
	], _armor)
	var forearm := _loft(self, "ForearmArmor", [
		[0.055, 0.020, 0.022, 0.020], [0.17, 0.024, 0.028, 0.024],
		[0.66, 0.036, 0.040, 0.033], [0.86, 0.034, 0.036, 0.031],
		[0.93, 0.027, 0.028, 0.025],
	], _armor)
	_loft(forearm, "WristCoupler", [
		[-0.022, 0.014, 0.014, 0.014], [0.028, 0.018, 0.017, 0.017],
		[0.09, 0.020, 0.020, 0.020],
	], _chrome)
	var elbow := Node3D.new()
	elbow.name = "ElbowJoint"
	add_child(elbow)
	_ball(elbow, "JointHousing", Vector3.ZERO, Vector3(0.033, 0.034, 0.034), _dark)
	_pivot(elbow, "Axle", Vector3(side * 0.029, 0, 0), 0.018, 0.016, _chrome)
	var hand: Node3D = null if tracked_hand else _desktop_hand_model(side)
	return {"side": side, "start": shoulder, "bearing": bearing, "upper": upper, "joint": elbow, "lower": forearm, "end": hand}


func _desktop_hand_model(side: float) -> Node3D:
	# Keep the actual skinned hand, with its wrist as the mount. Desktop pose
	# comes from the mouse hand, so there is no second XR input driver here.
	var path := "res://commons/body/hands/left_hand.tscn" if side < 0.0 else "res://commons/body/hands/right_hand.tscn"
	var source := (load(path) as PackedScene).instantiate()
	var model := source.get_node("Hand_L_Nails" if side < 0.0 else "Hand_R_Nails") as Node3D
	source.remove_child(model)
	source.free()
	var frame := Node3D.new()
	frame.name = "PlayerHand"
	add_child(frame, true)
	frame.add_child(model)
	var skeleton := model.get_node("Armature/Skeleton3D") as Skeleton3D
	var wrist := skeleton.find_bone("Wrist_L" if side < 0.0 else "Wrist_R")
	var local_wrist := _relative_to(skeleton, frame) * skeleton.get_bone_global_pose(wrist)
	model.transform = local_wrist.affine_inverse() * model.transform
	return frame


func pose(delta: float, velocity: Vector3, grounded: bool, gaze: Basis, tracked: Array,
		floor_ik: bool = false, body_rid: RID = RID()) -> void:
	var dancing: bool = not dance_mode.is_empty() and grounded
	var beat: float = dance_beat
	var groove_head := Basis.IDENTITY
	if dancing:
		var nod := sin(beat * TAU) * 0.11
		var tilt := sin(beat * PI) * 0.12
		if dance_mode == "robot":
			nod = roundf(sin(beat * TAU) * 2.0) * 0.06
			tilt = roundf(sin(beat * PI) * 2.0) * 0.08
		groove_head = Basis.from_euler(Vector3(nod, sin(beat * PI * 0.5) * 0.10, tilt))
	head.basis = gaze * groove_head
	var speed := velocity.length()
	if speed > 0.12:
		_step_direction = velocity / speed
	var step_length: float = profile.step_length
	_stride = lerpf(_stride, minf(0.23, speed * 0.075) * step_length if grounded else 0.0, 1.0 - exp(-10.0 * delta))
	_phase = fposmod(_phase + speed * TAU * delta / (1.5 * step_length), TAU)
	var hip_sway := sin(beat * PI) * 0.055 if dancing else 0.0
	var knee_dip := (0.5 - 0.5 * cos(beat * TAU)) * 0.065 if dancing else 0.0
	for i in 2:
		var leg := _legs[i]
		var side: float = leg.side
		var phase := _phase + i * PI
		var hip := Vector3(side * 0.110 * profile.hips + hip_sway, HIP_Y - knee_dip, 0)
		leg.bearing.position = hip - Vector3.UP * 0.015
		var ankle := Vector3(side * 0.104 * profile.hips, 0.067, 0) + _step_direction * (_stride * sin(phase))
		ankle.y += _stride * 0.43 * maxf(0.0, cos(phase))
		if dancing and speed < 0.25:
			var step_wave := sin(beat * PI + i * PI)
			ankle.x += side * 0.055 + hip_sway * 0.35
			ankle.z += step_wave * 0.09
			ankle.y += maxf(0.0, cos(beat * PI + i * PI)) * 0.075
		if floor_ik and not (dancing and speed < 0.25):
			ankle = _foot_target(leg, ankle, grounded, _stride > 0.018 and cos(phase) > 0.0, body_rid)
		var knee := _joint_position(hip, ankle, 0.417, 0.409, Vector3.FORWARD)
		_pose_links(leg, hip, knee, ankle)
		leg.end.position = ankle
		var arm := _arms[i]
		var shoulder: Vector3 = arm.start
		shoulder.x *= profile.shoulders
		shoulder.x += hip_sway * 0.65
		shoulder.y -= knee_dip * 0.65
		arm.bearing.position = shoulder
		var wrist := Vector3(side * 0.239, 0.826, -0.027) - _step_direction * (_stride * sin(phase) * 0.55)
		wrist.x += shoulder.x - arm.start.x
		var elbow_bend := Vector3(side * 0.65, -0.35, 0.60)
		if dancing:
			var dp := _dance_arm_target(dance_mode, side, beat, shoulder)
			wrist = dp[0]
			elbow_bend = dp[1]
		if i < tracked.size() and tracked[i] is Vector3:
			wrist = tracked[i]
		var elbow := _joint_position(shoulder, wrist, 0.295, 0.278, elbow_bend)
		_pose_links(arm, shoulder, elbow, wrist)
		if arm.end != null:
			arm.end.position = wrist
			# The imported hand's +Z thumb edge points forward at rest.
			arm.end.basis = _limb_basis((wrist - elbow).normalized()) * HAND_REST_ROLL
	if is_instance_valid(_knit):
		_knit.follow_rig()


func _dance_arm_target(mode: String, side: float, beat: float, shoulder: Vector3) -> Array:
	match mode:
		"fever":
			# Classic Saturday Night Fever: right arm sky-point <-> cross-hip sweep; left hand sassy on hip!
			if side > 0.0:
				var up_t := 0.5 + 0.5 * sin(beat * PI)
				var high_pt := Vector3(0.46, 1.86, -0.24)
				var low_pt := Vector3(-0.14, 0.96, -0.30)
				return [low_pt.lerp(high_pt, up_t), Vector3(0.55, -0.25, 0.35)]
			else:
				var hip_pop := sin(beat * TAU) * 0.04
				return [Vector3(-0.30, 0.96 + hip_pop, -0.06), Vector3(-0.95, 0.05, 0.25)]
		"hustle":
			# High alternating double-arm disco pumps + groovy sway
			var wave := sin(beat * PI + (0.0 if side > 0.0 else PI))
			var lift := 1.48 + wave * 0.34
			var reach_x := side * (0.34 + 0.12 * cos(beat * PI))
			var reach_z := -0.24 - 0.12 * absf(wave)
			return [Vector3(reach_x, lift, reach_z), Vector3(side * 0.70, -0.45, 0.30)]
		"vogue":
			# Runway Vogue geometric framing around head/visor
			var step_idx: int = int(floorf(beat * 0.5)) % 4
			if side > 0.0:
				var poses: Array[Vector3] = [
					Vector3(0.18, 1.82, -0.22),
					Vector3(0.46, 1.56, -0.24),
					Vector3(-0.08, 1.66, -0.32),
					Vector3(0.36, 1.18, -0.28),
				]
				return [poses[step_idx], Vector3(0.85, 0.20, 0.15)]
			else:
				var poses: Array[Vector3] = [
					Vector3(-0.42, 1.46, -0.22),
					Vector3(-0.18, 1.82, -0.22),
					Vector3(-0.36, 1.12, -0.24),
					Vector3(0.08, 1.66, -0.32),
				]
				return [poses[step_idx], Vector3(-0.85, 0.20, 0.15)]
		"robot":
			# Quantized beat-locked mechanical electric boogie!
			var q: float = floorf(beat * 2.0) * 0.5
			var s: float = signf(sin(q * PI + (0.0 if side > 0.0 else PI * 0.5)))
			var y: float = 1.38 + s * 0.36
			var x: float = side * (0.36 if int(floorf(beat)) % 2 == 0 else 0.18)
			return [Vector3(x, y, -0.32), Vector3(side * 0.75, -0.40, 0.25)]
		_:
			return [Vector3(shoulder.x + side * 0.06, 0.84, -0.04), Vector3(side * 0.65, -0.35, 0.60)]


func _foot_target(leg: Dictionary, ankle: Vector3, grounded: bool, swinging: bool, body_rid: RID) -> Vector3:
	leg.end.basis = Basis.IDENTITY
	if not grounded:
		leg.erase("support")
		return ankle
	var vertical_scale := global_basis.y.length()
	var level := to_global(Vector3(ankle.x, 0.0, ankle.z))
	var support: Node3D = leg.get("support")
	var point: Vector3
	var normal: Vector3
	if not swinging and is_instance_valid(support):
		point = support.to_global(leg.contact)
		if point.distance_to(level) <= 0.27 * vertical_scale:
			normal = support.global_basis.orthonormalized() * leg.normal
		else:
			support = null
	if swinging or not is_instance_valid(support):
		leg.erase("support")
		var margin := Vector3.UP * 0.32 * vertical_scale
		var query := PhysicsRayQueryParameters3D.create(level + margin, level - margin, 1, [body_rid])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.normal.dot(Vector3.UP) < 0.67:
			return ankle
		point = hit.position
		normal = hit.normal
		support = hit.collider as Node3D
		if not swinging and is_instance_valid(support):
			leg.support = support
			leg.contact = support.to_local(point)
			leg.normal = support.global_basis.orthonormalized().inverse() * normal
	var local_up := (global_basis.orthonormalized().inverse() * normal).normalized()
	leg.end.basis = _limb_basis(local_up)
	return to_local(point + normal * 0.067 * vertical_scale) + Vector3.UP * maxf(0.0, ankle.y - 0.067)


func _pose_links(limb: Dictionary, start: Vector3, joint: Vector3, end: Vector3) -> void:
	_link(limb.upper, joint, start)
	_link(limb.lower, end, joint)
	limb.joint.position = joint


func _link(link: Node3D, base: Vector3, tip: Vector3) -> void:
	var direction := tip - base
	var frame := _limb_basis(direction.normalized())
	frame.y = direction
	link.transform = Transform3D(frame, base)


func _limb_basis(up: Vector3) -> Basis:
	var cross_axis := Vector3.BACK if absf(up.dot(Vector3.BACK)) < 0.98 else Vector3.RIGHT
	var right := up.cross(cross_axis).normalized()
	return Basis(right, up, right.cross(up))


func _joint_position(start: Vector3, end: Vector3, upper: float, lower: float, bend: Vector3) -> Vector3:
	var offset := end - start
	# Reach the tracked end without a gap. A fully extended rig straightens
	# first, then shares any extra reach between the two armor segments.
	var stretch := maxf(1.0, (offset.length() + 0.001) / (upper + lower))
	upper *= stretch
	lower *= stretch
	var distance := clampf(offset.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var forward := offset.normalized() if offset.length_squared() > 0.000001 else Vector3.DOWN
	var along := (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var outward := bend.slide(forward).normalized()
	if outward.is_zero_approx():
		outward = _limb_basis(forward).x
	return start + forward * along + outward * sqrt(maxf(0.0, upper * upper - along * along))


static func _finish(color: Color, metal: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = roughness
	return material


func _loft(parent: Node3D, title: String, rings: Array, finish: Material,
		start: float = 0.0, end: float = TAU) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var closed := is_equal_approx(end - start, TAU)
	var columns := SEGMENTS if closed else SEGMENTS + 1
	for ring in rings:
		for j in columns:
			var angle := lerpf(start, end, float(j) / SEGMENTS)
			var depth: float = ring[2] if sin(angle) < 0.0 else ring[3]
			surface.add_vertex(Vector3(cos(angle) * ring[1], ring[0], sin(angle) * depth))
	for i in rings.size() - 1:
		for j in SEGMENTS:
			var a := i * columns + j
			var b := i * columns + (j + 1) % columns
			for index in [a, b, b + columns, a, b + columns, a + columns]:
				surface.add_index(index)
	if closed:
		var bottom := rings.size() * columns
		var top := bottom + 1
		surface.add_vertex(Vector3(0, rings.front()[0], 0))
		surface.add_vertex(Vector3(0, rings.back()[0], 0))
		for j in SEGMENTS:
			var next := (j + 1) % columns
			for index in [bottom, next, j, top, bottom - columns + j, bottom - columns + next]:
				surface.add_index(index)
	surface.generate_normals()
	return _mesh(parent, title, surface.commit(), Vector3.ZERO, finish)


func _ball(parent: Node3D, title: String, at: Vector3, radii: Vector3, finish: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	shape.radial_segments = 16
	shape.rings = 8
	var mesh := _mesh(parent, title, shape, at, finish)
	mesh.scale = radii
	return mesh


func _pivot(parent: Node3D, title: String, at: Vector3, radius: float, width: float, finish: Material) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = width
	shape.radial_segments = 20
	_mesh(parent, title, shape, at, finish).rotation.z = PI * 0.5


func _mesh(parent: Node3D, title: String, shape: Mesh, at: Vector3, finish: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.mesh = shape
	mesh.material_override = finish
	mesh.position = at
	parent.add_child(mesh, true)
	return mesh
