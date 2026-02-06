extends GadgetBase

# Paddle Wheel Gadget — Water wheel driven by cross product magnitude
# Uses HingeJoint3D with motor. Spin speed = |a × b|.
# 6 blades on the wheel body.

var axle: StaticBody3D
var wheel: RigidBody3D
var wheel_hinge: HingeJoint3D
var speed_label: Label3D

const WHEEL_RADIUS := 0.06
const BLADE_COUNT := 6
const BLADE_SIZE := Vector3(0.04, 0.002, 0.015)
const AXLE_RADIUS := 0.005
const AXLE_LENGTH := 0.04

var _target_speed: float = 0.0
var _cross_magnitude: float = 0.0

func _ready():
	# --- Axle support (static) ---
	axle = StaticBody3D.new()
	axle.name = "Axle"
	add_child(axle)

	# Support posts
	var post_mat = get_material(COLOR_METAL)
	for z_sign in [-1.0, 1.0]:
		var post = MeshInstance3D.new()
		post.mesh = make_box_mesh(Vector3(0.008, 0.08, 0.008))
		post.material_override = post_mat
		post.position = Vector3(0, 0.04, z_sign * (AXLE_LENGTH / 2.0 + 0.004))
		axle.add_child(post)

	# Axle bar (visual)
	var axle_bar = MeshInstance3D.new()
	axle_bar.mesh = make_cylinder_mesh(AXLE_RADIUS, AXLE_LENGTH + 0.02)
	axle_bar.material_override = post_mat
	axle_bar.position = Vector3(0, 0.08, 0)
	axle_bar.rotation_degrees = Vector3(90, 0, 0)
	axle.add_child(axle_bar)

	# Collision for axle
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.02, 0.08, AXLE_LENGTH + 0.02)
	col.shape = shape
	col.position = Vector3(0, 0.04, 0)
	axle.add_child(col)

	# --- Wheel body (rigid, rotates) ---
	wheel = RigidBody3D.new()
	wheel.name = "Wheel"
	wheel.position = Vector3(0, 0.08, 0)
	wheel.mass = 0.5
	wheel.can_sleep = false
	wheel.angular_damp = 1.5
	wheel.linear_damp = 5.0
	wheel.axis_lock_linear_x = true
	wheel.axis_lock_linear_y = true
	wheel.axis_lock_linear_z = true
	wheel.axis_lock_angular_x = true
	wheel.axis_lock_angular_y = true
	add_child(wheel)

	# Hub
	var hub = MeshInstance3D.new()
	hub.mesh = make_cylinder_mesh(0.01, 0.015)
	hub.material_override = get_material(COLOR_DARK_METAL)
	hub.rotation_degrees = Vector3(90, 0, 0)
	wheel.add_child(hub)

	# Hub collision
	var hub_col = CollisionShape3D.new()
	var hub_shape = CylinderShape3D.new()
	hub_shape.radius = 0.01
	hub_shape.height = 0.015
	hub_col.shape = hub_shape
	hub_col.rotation_degrees = Vector3(90, 0, 0)
	wheel.add_child(hub_col)

	# Blades
	var blade_mat = get_material(COLOR_MAGENTA)
	var blade_edge_mat = get_emissive_material(COLOR_MAGENTA, 0.8)
	for i in range(BLADE_COUNT):
		var angle = TAU * i / BLADE_COUNT
		var blade = MeshInstance3D.new()
		blade.mesh = make_box_mesh(BLADE_SIZE)
		blade.material_override = blade_mat
		blade.position = Vector3(
			cos(angle) * WHEEL_RADIUS * 0.55,
			sin(angle) * WHEEL_RADIUS * 0.55,
			0
		)
		blade.rotation.z = angle
		wheel.add_child(blade)

		# Blade tip (emissive dot)
		var tip = MeshInstance3D.new()
		tip.mesh = make_sphere_mesh(0.003)
		tip.material_override = blade_edge_mat
		tip.position = Vector3(
			cos(angle) * WHEEL_RADIUS * 0.9,
			sin(angle) * WHEEL_RADIUS * 0.9,
			0
		)
		wheel.add_child(tip)

	# Blade collisions (simplified ring)
	for i in range(4):
		var angle = TAU * i / 4.0
		var bcol = CollisionShape3D.new()
		var bshape = BoxShape3D.new()
		bshape.size = Vector3(0.02, 0.01, 0.015)
		bcol.shape = bshape
		bcol.position = Vector3(cos(angle) * WHEEL_RADIUS * 0.6, sin(angle) * WHEEL_RADIUS * 0.6, 0)
		wheel.add_child(bcol)

	# --- Hinge (Z axis rotation) ---
	wheel_hinge = create_hinge_joint(
		axle, wheel,
		Vector3(0, 0.08, 0),
		Vector3(90, 0, 0),  # Rotate to spin around Z axis
		true, 50.0, "WheelHinge"
	)

	# --- Label ---
	speed_label = create_label("|a×b|", Vector3(0.08, 0.08, 0), 14, COLOR_MAGENTA)

func _process(_delta):
	# Motor speed is set in update_from_vectors via physics
	if speed_label:
		speed_label.text = "|a×b| = %.2f" % _cross_magnitude

func update_from_vectors(a: Vector3, b: Vector3) -> void:
	var cross = a.cross(b)
	_cross_magnitude = cross.length()

	# Spin speed proportional to cross product magnitude
	_target_speed = _cross_magnitude * 2.0

	# Determine spin direction from cross product sign (Z component)
	if cross.length() > 0.001:
		var dir = sign(cross.y + cross.z * 0.5)
		if dir == 0:
			dir = 1.0
		_target_speed *= dir

	wheel_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, _target_speed)
