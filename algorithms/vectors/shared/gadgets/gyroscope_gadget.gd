extends GadgetBase

# Gyroscope Gadget — Three nested gimbal rings (R/G/B for X/Y/Z)
# Uses dual HingeJoint3D with motors for smooth physical rotation.
# Self-animating: no vector input needed (coordinates scene is static).

var pedestal: StaticBody3D
var yaw_ring: RigidBody3D
var pitch_ring: RigidBody3D
var roll_ring: RigidBody3D

var yaw_hinge: HingeJoint3D
var pitch_hinge: HingeJoint3D
var roll_hinge: HingeJoint3D

var _time: float = 0.0

# Ring dimensions
const RING_OUTER := 0.08
const RING_INNER := 0.065
const RING_OUTER_2 := 0.06
const RING_INNER_2 := 0.048
const RING_OUTER_3 := 0.042
const RING_INNER_3 := 0.032

func _ready():
	# Pedestal (anchor point)
	pedestal = create_static_body(
		Vector3(0, -0.05, 0),
		make_cylinder_mesh(0.03, 0.05),
		COLOR_DARK_METAL,
		"Pedestal"
	)

	# --- Outer ring (Yaw - Y axis - GREEN) ---
	yaw_ring = _create_ring_body(
		Vector3.ZERO,
		RING_INNER, RING_OUTER,
		COLOR_GREEN, 0.3, "YawRing"
	)

	# Yaw hinge: rotates around Y axis (default hinge axis)
	yaw_hinge = create_hinge_joint(
		pedestal, yaw_ring,
		Vector3.ZERO,
		Vector3.ZERO,  # Y axis rotation (default)
		true, 40.0, "YawHinge"
	)

	# --- Middle ring (Pitch - X axis - RED) ---
	pitch_ring = _create_ring_body(
		Vector3.ZERO,
		RING_INNER_2, RING_OUTER_2,
		COLOR_RED, 0.2, "PitchRing"
	)

	# Pitch hinge: rotates around Z axis (90° rotation to make X-axis hinge)
	pitch_hinge = create_hinge_joint(
		yaw_ring, pitch_ring,
		Vector3.ZERO,
		Vector3(0, 0, 90),  # Rotate hinge axis to X
		true, 40.0, "PitchHinge"
	)

	# --- Inner ring (Roll - Z axis - BLUE) ---
	roll_ring = _create_ring_body(
		Vector3.ZERO,
		RING_INNER_3, RING_OUTER_3,
		COLOR_BLUE, 0.15, "RollRing"
	)

	# Roll hinge: rotates around Z axis
	roll_hinge = create_hinge_joint(
		pitch_ring, roll_ring,
		Vector3.ZERO,
		Vector3(90, 0, 0),  # Rotate hinge axis to Z
		true, 40.0, "RollHinge"
	)

	# Small center sphere (payload)
	var center_mesh = make_sphere_mesh(0.015)
	var center_mi = MeshInstance3D.new()
	center_mi.mesh = center_mesh
	center_mi.material_override = get_emissive_material(Color(0.9, 0.9, 1.0), 2.0)
	roll_ring.add_child(center_mi)

func _process(delta):
	_time += delta

	# Each ring oscillates at a different frequency for visual interest
	var yaw_vel = 0.8 * sin(_time * 0.7)
	var pitch_vel = 0.6 * sin(_time * 1.1 + 1.0)
	var roll_vel = 1.0 * sin(_time * 0.5 + 2.0)

	yaw_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, yaw_vel)
	pitch_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, pitch_vel)
	roll_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, roll_vel)

# Self-animating - update_from_vectors is a no-op
func update_from_vectors(_a: Vector3, _b: Vector3) -> void:
	pass

func _create_ring_body(pos: Vector3, inner_r: float, outer_r: float, color: Color, mass: float, body_name: String) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.name = body_name
	body.position = pos
	body.mass = mass
	body.can_sleep = false
	body.linear_damp = 0.5
	body.angular_damp = 0.8

	# Visual: torus ring
	var torus = make_torus_mesh(inner_r, outer_r)
	var mi = MeshInstance3D.new()
	mi.mesh = torus
	mi.material_override = get_material(color)
	body.add_child(mi)

	# Collision: approximate with a thin cylinder ring
	# Using a small box approximation for the collision (4 boxes around the ring)
	var ring_r = (inner_r + outer_r) / 2.0
	var tube_r = (outer_r - inner_r) / 2.0
	for i in range(8):
		var angle = TAU * i / 8.0
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(tube_r * 2, tube_r * 2, tube_r * 2)
		col.shape = shape
		col.position = Vector3(cos(angle) * ring_r, 0, sin(angle) * ring_r)
		body.add_child(col)

	add_child(body)
	return body
