extends GadgetBase

# Catapult Gadget — Mini launcher driven by force vectors
# Uses HingeJoint3D with motor and angle limits.
# Arm angle = force direction, arm pull-back = force magnitude.

var base_body: StaticBody3D
var arm: RigidBody3D
var arm_hinge: HingeJoint3D
var force_label: Label3D

const BASE_SIZE := Vector3(0.06, 0.02, 0.04)
const ARM_SIZE := Vector3(0.008, 0.12, 0.008)
const UPRIGHT_SIZE := Vector3(0.008, 0.04, 0.04)

var _target_angle: float = 0.0
var _target_strength: float = 0.0

func _ready():
	# --- Base ---
	base_body = create_static_body(
		Vector3.ZERO,
		make_box_mesh(BASE_SIZE),
		COLOR_DARK_METAL,
		"Base"
	)

	# Upright posts (visual frame)
	var post_mat = get_material(COLOR_METAL)
	for z_sign in [-1.0, 1.0]:
		add_mesh_child(
			base_body,
			make_box_mesh(UPRIGHT_SIZE),
			post_mat,
			Vector3(0, UPRIGHT_SIZE.y / 2.0 + BASE_SIZE.y / 2.0, z_sign * 0.015)
		)

	# --- Arm (the lever) ---
	arm = create_rigid_body(
		Vector3(0, UPRIGHT_SIZE.y + BASE_SIZE.y / 2.0, 0),
		make_box_mesh(ARM_SIZE),
		COLOR_ORANGE,
		0.4,
		"Arm"
	)
	arm.angular_damp = 3.0
	arm.linear_damp = 2.0
	arm.axis_lock_linear_x = true
	arm.axis_lock_linear_y = true
	arm.axis_lock_linear_z = true
	arm.axis_lock_angular_x = true
	arm.axis_lock_angular_y = true

	# Bucket at arm tip
	add_mesh_child(
		arm,
		make_box_mesh(Vector3(0.02, 0.005, 0.02)),
		get_material(COLOR_YELLOW),
		Vector3(0, ARM_SIZE.y / 2.0, 0)
	)

	# Counterweight at arm base
	add_mesh_child(
		arm,
		make_sphere_mesh(0.01),
		get_material(COLOR_CYAN),
		Vector3(0, -ARM_SIZE.y / 2.0 + 0.01, 0)
	)

	# --- Hinge (Z axis, for arm swing) ---
	arm_hinge = create_hinge_joint(
		base_body, arm,
		Vector3(0, UPRIGHT_SIZE.y + BASE_SIZE.y / 2.0, 0),
		Vector3(0, 0, 0),
		true, 50.0, "ArmHinge"
	)
	arm_hinge.rotation_degrees = Vector3(0, 0, 90)
	arm_hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	arm_hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-80))
	arm_hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(80))

	# --- Label ---
	force_label = create_label("|F|", Vector3(0.06, 0.06, 0), 14, COLOR_ORANGE)

func _process(delta):
	# Drive arm toward target angle
	var current_angle = arm.rotation.z
	var angle_error = _target_angle - current_angle
	var velocity = angle_error * 5.0

	arm_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, velocity)

	if force_label:
		force_label.text = "|F| = %.1f" % _target_strength

func update_from_vectors(a: Vector3, b: Vector3) -> void:
	# a = thrust force, b = gravity force
	var net = a + b
	_target_strength = net.length()

	# Map net force direction to arm angle
	# Y component determines pull-back angle
	if net.length() > 0.01:
		# Use atan2 of vertical vs horizontal for tilt
		_target_angle = clamp(atan2(net.y, net.x), deg_to_rad(-80), deg_to_rad(80))
	else:
		_target_angle = 0.0
