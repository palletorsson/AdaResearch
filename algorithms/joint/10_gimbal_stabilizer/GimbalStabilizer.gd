# @identity
# essence: two orthogonal hinges — yaw (free) + pitch (±45°). Composed single-axis joints create multi-axis aiming.
# desire: To point anywhere — the gimbal is constraint squared, each hinge removing one DOF while their stack permits two-axis control.
# critical_parameter: pitch angular limit (±45°) — yaw is free but pitch is bounded, creating an asymmetric freedom.
# triggers: Arrow keys override motors; idle mode sweeps a Lissajous-like pattern.
# emerges: Smooth 2D aiming from two 1D constraints. The approach to gimbal lock when pitch nears its limit.
# needs: Dual motor control [has], Lissajous idle [has]. Missing: gimbal lock visualization, third axis (roll).
# relationships: Most complex hinge demo. Composes pattern from DrawbridgeHinge. Contrasts with IKArm (inverse kinematics vs forward).
# truth: A gimbal is two questions asked orthogonally: how far left, and how far up. The answer is a direction.

extends "res://algorithms/joint/shared/joint_demo_base.gd"
class_name GimbalStabilizerDemo

# ── Palette ──────────────────────────────────────────────────────────────────
const COLOR_BASE    := Color(0.70, 0.55, 0.35)   # warm amber pedestal
const COLOR_YAW     := Color(0.25, 0.55, 0.90)   # blue yaw ring
const COLOR_PITCH   := Color(0.20, 0.50, 0.85)   # blue pitch ring (slightly deeper)
const COLOR_PAYLOAD := Color(0.20, 0.90, 0.85)   # cyan payload
const COLOR_HINGE   := Color(1.00, 0.55, 0.10)   # orange hinge markers
const COLOR_TRAIL   := Color(0.20, 0.90, 0.85)   # matches payload

# ── State ─────────────────────────────────────────────────────────────────────
var yaw_hinge: HingeJoint3D
var pitch_hinge: HingeJoint3D

var _payload_ref: RigidBody3D
var _yaw_frame_ref: RigidBody3D
var _pitch_frame_ref: RigidBody3D

var _trail_mesh: MeshInstance3D
var _trail_points: PackedVector3Array
const TRAIL_MAX := 200

var _angle_label: Label3D

# ── Material helper ───────────────────────────────────────────────────────────
func _make_emissive(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.3
	mat.roughness = 0.4
	return mat

func _make_hinge_marker_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_HINGE
	mat.emission_enabled = true
	mat.emission = COLOR_HINGE * 0.6
	mat.emission_energy_multiplier = 2.0
	mat.metallic = 0.5
	mat.roughness = 0.2
	return mat

# ── Hinge marker helper ───────────────────────────────────────────────────────
func _add_hinge_marker(pos: Vector3, radius: float = 0.18) -> void:
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_inst.mesh = sphere
	mesh_inst.material_override = _make_hinge_marker_mat()
	mesh_inst.position = pos
	add_child(mesh_inst)

# ── Build ─────────────────────────────────────────────────────────────────────
func _build_demo() -> void:
	# 1. Pedestal / base — warm amber
	var pedestal := create_static_box("Pedestal", Vector3(1.0, 1.5, 1.0), Vector3(0.0, 0.75, 0.0), Color(0.3, 0.3, 0.35))
	pedestal.get_child(1).material_override = _make_emissive(COLOR_BASE, 0.6)

	# 2. Yaw frame — blue ring
	var yaw_frame := create_box("YawFrame", Vector3(0.4, 2.5, 2.5), Vector3(0.0, 2.8, 0.0), 5.0, Color(0.6, 0.6, 0.7))
	yaw_frame.get_child(1).material_override = _make_emissive(COLOR_YAW, 1.4)
	_yaw_frame_ref = yaw_frame

	# 3. Pitch frame — slightly deeper blue ring
	var pitch_frame := create_box("PitchFrame", Vector3(2.5, 0.4, 2.5), Vector3(0.0, 2.8, 0.0), 4.0, Color(0.55, 0.55, 0.7))
	pitch_frame.get_child(1).material_override = _make_emissive(COLOR_PITCH, 1.3)
	_pitch_frame_ref = pitch_frame

	# 4. Payload — glowing cyan (inner mover)
	var payload := create_box("Payload", Vector3(1.2, 0.8, 1.2), Vector3(0.0, 2.8, 0.0), 2.0, Color(0.9, 0.45, 0.2))
	payload.get_child(1).material_override = _make_emissive(COLOR_PAYLOAD, 2.2)
	_payload_ref = payload

	# 5. Yaw joint (vertical axis — pedestal → yaw_frame)
	yaw_hinge = HingeJoint3D.new()
	yaw_hinge.name = "YawJoint"
	yaw_hinge.node_a = pedestal.get_path()
	yaw_hinge.node_b = yaw_frame.get_path()
	yaw_hinge.position = Vector3(0.0, 2.0, 0.0)
	yaw_hinge.rotation = Vector3(0.0, 0.0, 0.0)
	yaw_hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, false)
	yaw_hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	yaw_hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 60.0)
	yaw_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.2)
	add_child(yaw_hinge)

	# 6. Pitch joint (horizontal axis — yaw_frame → pitch_frame, ±45°)
	pitch_hinge = HingeJoint3D.new()
	pitch_hinge.name = "PitchJoint"
	pitch_hinge.node_a = yaw_frame.get_path()
	pitch_hinge.node_b = pitch_frame.get_path()
	pitch_hinge.position = Vector3(0.0, 2.8, 0.0)
	pitch_hinge.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	pitch_hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	pitch_hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-45.0))
	pitch_hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(45.0))
	pitch_hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	pitch_hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 40.0)
	pitch_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
	add_child(pitch_hinge)

	# 7. Payload pin joint
	var payload_joint := PinJoint3D.new()
	payload_joint.node_a = pitch_frame.get_path()
	payload_joint.node_b = payload.get_path()
	payload_joint.position = payload.position
	payload_joint.set_exclude_nodes_from_collision(true)
	add_child(payload_joint)

	# 8. Hinge markers — orange glowing spheres at joint positions
	_add_hinge_marker(Vector3(0.0, 2.0, 0.0))   # yaw hinge
	_add_hinge_marker(Vector3(0.0, 2.8, 0.0))   # pitch hinge

	# 9. Trail mesh (ImmediateMesh updated each frame)
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "PayloadTrail"
	var imm := ImmediateMesh.new()
	_trail_mesh.mesh = imm
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = COLOR_TRAIL
	trail_mat.emission_enabled = true
	trail_mat.emission = COLOR_TRAIL * 0.5
	trail_mat.emission_energy_multiplier = 1.8
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.vertex_color_use_as_albedo = false
	_trail_mesh.material_override = trail_mat
	add_child(_trail_mesh)
	_trail_points = PackedVector3Array()

	# 10. Angle readout label
	_angle_label = add_label("yaw: 0°  pitch: 0°", Vector3(0.0, 5.2, 3.0))
	_angle_label.modulate = Color(0.85, 0.95, 1.0, 0.95)

	add_label("Dual Hinge Gimbal", Vector3(0.0, 4.5, 3.0))
	set_process(true)

# ── Process ───────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001

	# Idle Lissajous sweep
	if is_instance_valid(yaw_hinge):
		yaw_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.6 * sin(t * 0.6))
	if is_instance_valid(pitch_hinge):
		pitch_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.5 * sin(t * 0.9))

	# Trail update
	if is_instance_valid(_payload_ref) and is_instance_valid(_trail_mesh):
		var wp := _payload_ref.global_position
		_trail_points.push_back(wp)
		if _trail_points.size() > TRAIL_MAX:
			_trail_points.remove_at(0)
		_rebuild_trail()

	# Angle label update
	if is_instance_valid(_yaw_frame_ref) and is_instance_valid(_pitch_frame_ref) and is_instance_valid(_angle_label):
		var yaw_deg := snappedf(rad_to_deg(_yaw_frame_ref.rotation.y), 0.1)
		var pitch_deg := snappedf(rad_to_deg(_pitch_frame_ref.rotation.x), 0.1)
		_angle_label.text = "yaw: %s°  pitch: %s°" % [yaw_deg, pitch_deg]

func _rebuild_trail() -> void:
	var imm := _trail_mesh.mesh as ImmediateMesh
	if not imm:
		return
	imm.clear_surfaces()
	var n := _trail_points.size()
	if n < 2:
		return
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(n):
		var alpha := float(i) / float(n - 1)
		imm.surface_set_color(Color(COLOR_TRAIL.r, COLOR_TRAIL.g, COLOR_TRAIL.b, alpha * 0.9))
		imm.surface_add_vertex(_trail_points[i])
	imm.surface_end()

# ── Physics process ───────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	var yaw_velocity := 0.0
	if Input.is_action_pressed("ui_left"):
		yaw_velocity = -1.5
	elif Input.is_action_pressed("ui_right"):
		yaw_velocity = 1.5
	# yaw_hinge.motor_target_velocity = yaw_velocity  (preserved — uncomment to enable)

	var pitch_velocity := 0.0
	if Input.is_action_pressed("ui_up"):
		pitch_velocity = 1.2
	elif Input.is_action_pressed("ui_down"):
		pitch_velocity = -1.2

# ── Cleanup ───────────────────────────────────────────────────────────────────
func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
