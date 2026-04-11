extends GadgetBase

# Hinge Panel Gadget — Two panels on a shared hinge
# Angle between panels = angle between vectors (dot product angle).
# Uses HingeJoint3D with motor to drive panels to target angle.

var anchor: StaticBody3D
var panel_a: RigidBody3D
var panel_b: RigidBody3D
var hinge_a: HingeJoint3D
var hinge_b: HingeJoint3D
var angle_label: Label3D

const PANEL_SIZE := Vector3(0.08, 0.06, 0.004)
const HINGE_HEIGHT := 0.03

var _target_angle: float = PI / 4.0  # radians
var _current_angle: float = PI / 4.0

func _ready() -> void:
	# --- Central hinge post ---
	anchor = create_static_body(
		Vector3(0, 0, 0),
		make_cylinder_mesh(0.008, HINGE_HEIGHT * 2),
		COLOR_METAL,
		"HingePost"
	)

	# --- Panel A (orange, left side) ---
	panel_a = create_rigid_body(
		Vector3(-PANEL_SIZE.x / 2.0, 0, 0),
		make_box_mesh(PANEL_SIZE),
		COLOR_ORANGE,
		0.2,
		"PanelA"
	)
	panel_a.gravity_scale = 0.0
	panel_a.linear_damp = 5.0
	panel_a.angular_damp = 3.0
	panel_a.axis_lock_linear_x = true
	panel_a.axis_lock_linear_y = true
	panel_a.axis_lock_linear_z = true

	# Hinge A: rotates panel A around Y axis
	hinge_a = create_hinge_joint(
		anchor, panel_a,
		Vector3(0, 0, 0),
		Vector3.ZERO,
		true, 30.0, "HingeA"
	)
	hinge_a.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge_a.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-170))
	hinge_a.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(0))

	# --- Panel B (cyan, right side) ---
	panel_b = create_rigid_body(
		Vector3(PANEL_SIZE.x / 2.0, 0, 0),
		make_box_mesh(PANEL_SIZE),
		COLOR_CYAN,
		0.2,
		"PanelB"
	)
	panel_b.gravity_scale = 0.0
	panel_b.linear_damp = 5.0
	panel_b.angular_damp = 3.0
	panel_b.axis_lock_linear_x = true
	panel_b.axis_lock_linear_y = true
	panel_b.axis_lock_linear_z = true

	# Hinge B: rotates panel B around Y axis
	hinge_b = create_hinge_joint(
		anchor, panel_b,
		Vector3(0, 0, 0),
		Vector3.ZERO,
		true, 30.0, "HingeB"
	)
	hinge_b.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge_b.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(0))
	hinge_b.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(170))

	# --- Angle label ---
	angle_label = create_label("0°", Vector3(0, 0.06, 0), 16, Color.WHITE)

func _process(delta: float) -> void:
	_current_angle = lerp(_current_angle, _target_angle, delta * 6.0)

	# Drive panels to half the angle each (symmetric opening)
	var half_angle = _current_angle / 2.0

	# Panel A goes to negative angle, Panel B goes to positive
	# Motor velocity drives toward target
	var panel_a_target = -half_angle
	var panel_b_target = half_angle

	# Estimate current angles from body rotations
	var vel_a = (panel_a_target - panel_a.rotation.y) * 4.0
	var vel_b = (panel_b_target - panel_b.rotation.y) * 4.0

	hinge_a.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel_a)
	hinge_b.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, vel_b)

	if angle_label:
		angle_label.text = "%.1f°" % rad_to_deg(_current_angle)

func update_from_vectors(a: Vector3, b: Vector3) -> void:
	var mag_a = a.length()
	var mag_b = b.length()
	if mag_a > 0.001 and mag_b > 0.001:
		var cos_theta = clamp(a.dot(b) / (mag_a * mag_b), -1.0, 1.0)
		_target_angle = acos(cos_theta)
	else:
		_target_angle = 0.0

func apply_grid_config(config: Dictionary) -> void:
	pass
