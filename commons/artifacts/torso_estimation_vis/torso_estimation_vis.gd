class_name TorsoEstimationVis
extends Node3D
## TorsoEstimationVis — Visual demonstration of 3-point torso estimation
##
## Shows how head + two hand positions can estimate torso orientation.
## Three tracking spheres orbit and a torso wireframe responds in real time.
## "The body is not given — it is composed from inference."

# @identity
# essence: Three animated tracking points (head + two hands) driving real-time torso orientation estimation with visual feedback
# desire: To show that the VR body is inferred, not measured: three points in space produce a torso through computation
# critical_parameter: head_weight — how much head direction vs hand midpoint determines torso facing
# triggers: Hands moving apart widens shoulder markers; head turning reorients forward arrow; asymmetric positions tilt the torso
# emerges: A believable torso from three floating points — the body filling in gaps that sensors never measured
# needs: Animated tracking points [has], shoulder markers [has], forward arrow [has], connection lines [has], VR input [missing — demo]
# relationships: Fourth artifact in bodyprogression. Follows ik_arm_demo, precedes dress_selector. Uses 3-point estimation.
# truth: The body is not given — it is the computation that fills the space between what the sensors actually see.

@export var shoulder_width: float = 0.36
@export var neck_offset: float = 0.15
@export var head_weight: float = 0.7

var _head_marker: MeshInstance3D
var _left_hand_marker: MeshInstance3D
var _right_hand_marker: MeshInstance3D
var _torso_body: MeshInstance3D
var _shoulder_left: MeshInstance3D
var _shoulder_right: MeshInstance3D
var _spine_line: MeshInstance3D
var _forward_arrow: MeshInstance3D
var _time: float = 0.0
var _torso_yaw: float = 0.0

func _ready() -> void:
	# Head marker (camera stand-in) — blue sphere
	_head_marker = _make_sphere(Vector3(0, 1.6, 0), Color.DODGER_BLUE, 0.08)
	_head_marker.name = "HeadMarker"

	# Hand markers — orange spheres
	_left_hand_marker = _make_sphere(Vector3(-0.3, 1.0, -0.2), Color.ORANGE_RED, 0.05)
	_left_hand_marker.name = "LeftHandMarker"
	_right_hand_marker = _make_sphere(Vector3(0.3, 1.0, -0.2), Color.ORANGE, 0.05)
	_right_hand_marker.name = "RightHandMarker"

	# Torso capsule
	_torso_body = MeshInstance3D.new()
	_torso_body.name = "TorsoBody"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.12
	capsule.height = 0.5
	_torso_body.mesh = capsule
	var torso_mat := StandardMaterial3D.new()
	torso_mat.albedo_color = Color(0.6, 0.5, 0.7, 0.6)
	torso_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torso_mat.roughness = 0.5
	_torso_body.material_override = torso_mat
	add_child(_torso_body)

	# Shoulder markers — yellow
	_shoulder_left = _make_sphere(Vector3.ZERO, Color.YELLOW, 0.03)
	_shoulder_left.name = "ShoulderLeft"
	_shoulder_right = _make_sphere(Vector3.ZERO, Color.YELLOW, 0.03)
	_shoulder_right.name = "ShoulderRight"

	# Forward direction arrow
	_forward_arrow = MeshInstance3D.new()
	_forward_arrow.name = "ForwardArrow"
	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = 0.005
	arrow_mesh.bottom_radius = 0.02
	arrow_mesh.height = 0.25
	_forward_arrow.mesh = arrow_mesh
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color.GREEN_YELLOW
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color.GREEN_YELLOW
	arrow_mat.emission_energy_multiplier = 1.5
	_forward_arrow.material_override = arrow_mat
	add_child(_forward_arrow)

	# Connection lines (head-to-hands) — thin cylinders
	_make_connection_line("HeadToLeftHand", Color(0.3, 0.5, 1.0, 0.4))
	_make_connection_line("HeadToRightHand", Color(1.0, 0.5, 0.3, 0.4))
	_make_connection_line("ShoulderSpan", Color(1.0, 1.0, 0.3, 0.5))


func _physics_process(delta: float) -> void:
	_time += delta

	# Animate the three tracking points — head slowly looks around,
	# hands gesture independently
	var head_yaw: float = sin(_time * 0.4) * 0.6
	var head_pos := Vector3(sin(head_yaw) * 0.05, 1.6, cos(head_yaw) * 0.05)
	_head_marker.position = head_pos

	# Hands move in opposing arcs
	var l_swing: float = sin(_time * 0.7) * 0.25
	var r_swing: float = sin(_time * 0.7 + PI * 0.6) * 0.25
	var left_pos := Vector3(-0.3 + l_swing * 0.3, 1.0 + sin(_time * 1.1) * 0.15, -0.2 - abs(l_swing) * 0.2)
	var right_pos := Vector3(0.3 + r_swing * 0.3, 1.0 + cos(_time * 1.1) * 0.15, -0.2 - abs(r_swing) * 0.2)
	_left_hand_marker.position = left_pos
	_right_hand_marker.position = right_pos

	# --- 3-point torso estimation (same algorithm as TorsoEstimator) ---
	var neck_pos := head_pos - Vector3(0, neck_offset, 0)

	# Head forward from yaw
	var head_fwd := Vector3(sin(head_yaw), 0, cos(head_yaw)).normalized()

	# Hand midpoint forward
	var hand_mid := (left_pos + right_pos) * 0.5
	var hand_dir := hand_mid - neck_pos
	var hand_fwd := Vector3(hand_dir.x, 0, hand_dir.z)
	if hand_fwd.length_squared() < 0.001:
		hand_fwd = head_fwd
	else:
		hand_fwd = hand_fwd.normalized()

	# Blended torso forward
	var blended := (head_fwd * head_weight + hand_fwd * (1.0 - head_weight)).normalized()
	var target_yaw := atan2(blended.x, blended.z)
	_torso_yaw = lerp_angle(_torso_yaw, target_yaw, clampf(10.0 * delta, 0.0, 1.0))

	var torso_fwd := Vector3(sin(_torso_yaw), 0, cos(_torso_yaw))
	var torso_right := torso_fwd.cross(Vector3.UP).normalized()

	# Shoulder positions
	var shoulder_half := shoulder_width * 0.5
	var l_shoulder := neck_pos - torso_right * shoulder_half - Vector3(0, 0.1, 0)
	var r_shoulder := neck_pos + torso_right * shoulder_half - Vector3(0, 0.1, 0)
	_shoulder_left.position = l_shoulder
	_shoulder_right.position = r_shoulder

	# Torso body
	var torso_center := neck_pos - Vector3(0, 0.25, 0)
	_torso_body.position = torso_center
	_torso_body.basis = Basis.looking_at(torso_fwd, Vector3.UP) if torso_fwd.length_squared() > 0.001 else Basis.IDENTITY

	# Forward arrow — points where torso is facing
	var arrow_base := torso_center + Vector3(0, 0, 0)
	_forward_arrow.position = arrow_base + torso_fwd * 0.2
	_forward_arrow.basis = Basis.looking_at(torso_fwd, Vector3.UP).rotated(Vector3(1, 0, 0), PI / 2.0) if torso_fwd.length_squared() > 0.001 else Basis.IDENTITY

	# Update connection lines
	_update_line("HeadToLeftHand", head_pos, left_pos)
	_update_line("HeadToRightHand", head_pos, right_pos)
	_update_line("ShoulderSpan", l_shoulder, r_shoulder)


func _make_sphere(pos: Vector3, color: Color, radius: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mesh_inst.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	add_child(mesh_inst)
	return mesh_inst


func _make_connection_line(line_name: String, color: Color) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = line_name
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.005
	cyl.bottom_radius = 0.005
	cyl.height = 1.0
	mesh_inst.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat
	add_child(mesh_inst)


func _update_line(line_name: String, from: Vector3, to: Vector3) -> void:
	var line := get_node_or_null(line_name) as MeshInstance3D
	if not line:
		return
	var mid := (from + to) * 0.5
	var dist := from.distance_to(to)
	line.position = mid
	var cyl := line.mesh as CylinderMesh
	if cyl:
		cyl.height = dist
	# Orient cylinder to connect the two points
	var direction := (to - from).normalized()
	if direction.length_squared() > 0.001:
		var up := Vector3.UP
		if abs(direction.dot(up)) > 0.99:
			up = Vector3.FORWARD
		line.basis = Basis.looking_at(direction, up).rotated(direction.cross(up).normalized(), PI / 2.0) if direction.cross(up).length_squared() > 0.001 else Basis.IDENTITY


func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
