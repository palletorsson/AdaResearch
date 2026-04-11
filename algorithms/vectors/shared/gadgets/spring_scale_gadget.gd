extends GadgetBase

# Spring Scale Gadget — Vector magnitude stretches a spring
# Uses Generic6DOFJoint3D with linear spring on Y axis.
# Visual spring coils (torus rings) redistribute with platform position.

var base_body: StaticBody3D
var platform: RigidBody3D
var spring_joint: Generic6DOFJoint3D
var coil_meshes: Array[MeshInstance3D] = []
var magnitude_label: Label3D

const NUM_COILS := 8
const BASE_HEIGHT := 0.02
const PLATFORM_SIZE := Vector3(0.06, 0.015, 0.06)
const COLUMN_RADIUS := 0.005
const COIL_INNER := 0.015
const COIL_OUTER := 0.025
const REST_HEIGHT := 0.15  # Natural spring length
const SPRING_STIFFNESS := 20.0
const SPRING_DAMPING := 4.0

var _target_magnitude: float = 0.0
var _current_magnitude: float = 0.0

func _ready() -> void:
	# --- Base plate ---
	base_body = create_static_body(
		Vector3.ZERO,
		make_box_mesh(Vector3(0.08, BASE_HEIGHT, 0.08)),
		COLOR_DARK_METAL,
		"Base"
	)

	# Guide columns (visual only)
	var col_mat = get_material(COLOR_METAL)
	for x_sign in [-1.0, 1.0]:
		var col = MeshInstance3D.new()
		col.mesh = make_cylinder_mesh(COLUMN_RADIUS, REST_HEIGHT * 2.5)
		col.material_override = col_mat
		col.position = Vector3(x_sign * 0.03, REST_HEIGHT * 1.25 + BASE_HEIGHT / 2.0, 0)
		add_child(col)

	# --- Platform (moves on spring) ---
	platform = create_rigid_body(
		Vector3(0, REST_HEIGHT + BASE_HEIGHT, 0),
		make_box_mesh(PLATFORM_SIZE),
		COLOR_YELLOW,
		0.5,
		"Platform"
	)
	platform.gravity_scale = 0.0  # We control position via spring + force
	platform.linear_damp = 3.0
	platform.angular_damp = 10.0
	# Lock rotation and X/Z movement
	platform.axis_lock_angular_x = true
	platform.axis_lock_angular_y = true
	platform.axis_lock_angular_z = true
	platform.axis_lock_linear_x = true
	platform.axis_lock_linear_z = true

	# --- Spring joint ---
	spring_joint = create_spring_joint(
		base_body, platform,
		Vector3(0, BASE_HEIGHT / 2.0, 0),
		"y", SPRING_STIFFNESS, SPRING_DAMPING,
		0.0, REST_HEIGHT * 2.0,
		"SpringJoint"
	)

	# --- Visual spring coils ---
	var coil_mat = get_emissive_material(COLOR_CYAN, 0.8)
	for i in range(NUM_COILS):
		var coil = MeshInstance3D.new()
		coil.mesh = make_torus_mesh(COIL_INNER, COIL_OUTER)
		coil.material_override = coil_mat
		coil.rotation_degrees = Vector3(90, 0, 0)  # Lay flat (horizontal)
		add_child(coil)
		coil_meshes.append(coil)

	# --- Indicator sphere on platform ---
	var indicator = MeshInstance3D.new()
	indicator.mesh = make_sphere_mesh(0.012)
	indicator.material_override = get_emissive_material(COLOR_ORANGE, 1.5)
	indicator.position = Vector3(0, PLATFORM_SIZE.y / 2.0 + 0.012, 0)
	platform.add_child(indicator)

	# --- Label ---
	magnitude_label = create_label("|v|", Vector3(0.06, REST_HEIGHT, 0))

func _process(delta: float) -> void:
	_current_magnitude = lerp(_current_magnitude, _target_magnitude, delta * 8.0)

	# Redistribute coils between base top and platform bottom
	var base_top = base_body.position.y + BASE_HEIGHT / 2.0
	var platform_bottom = platform.position.y - PLATFORM_SIZE.y / 2.0
	var span = max(platform_bottom - base_top, 0.01)

	for i in range(NUM_COILS):
		var t = (float(i) + 0.5) / float(NUM_COILS)
		var y = base_top + span * t
		coil_meshes[i].position = Vector3(0, y, 0)
		# Scale coils: compressed = wider, stretched = narrower
		var stretch_factor = clamp(span / REST_HEIGHT, 0.3, 2.0)
		var coil_scale = 1.0 / sqrt(stretch_factor)  # Inverse relationship
		coil_meshes[i].scale = Vector3(coil_scale, 1.0, coil_scale)

	if magnitude_label:
		magnitude_label.text = "|v| = %.2f" % _current_magnitude

func update_from_vectors(a: Vector3, _b: Vector3) -> void:
	_target_magnitude = a.length()

	# Apply upward force proportional to magnitude
	# This pushes the platform up against the spring
	var force_strength = _target_magnitude * 8.0
	platform.apply_central_force(Vector3(0, force_strength, 0))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
