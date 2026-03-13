extends GadgetBase

# Piston Gadget â€” Two pistons at 90Â° pushing a platform
# Uses SliderJoint3D for each piston axis.
# Piston A extends = |a|, Piston B extends = |b|.

var frame: StaticBody3D
var piston_a: RigidBody3D
var piston_b: RigidBody3D
var platform_marker: MeshInstance3D
var slider_a: SliderJoint3D
var slider_b: SliderJoint3D
var label_a: Label3D
var label_b: Label3D

const FRAME_SIZE := Vector3(0.01, 0.12, 0.01)
const PISTON_SIZE := Vector3(0.025, 0.02, 0.02)
const MAX_EXTENSION := 0.15

var _target_a: float = 0.0
var _target_b: float = 0.0

func _ready() -> void:
	# --- Frame (L-shaped anchor) ---
	frame = StaticBody3D.new()
	frame.name = "Frame"
	add_child(frame)

	# Vertical bar
	var vert_mi = add_mesh_child(
		frame,
		make_box_mesh(Vector3(0.01, 0.16, 0.01)),
		get_material(COLOR_FRAME),
		Vector3(0, 0.08, 0)
	)
	var vert_col = CollisionShape3D.new()
	var vert_shape = BoxShape3D.new()
	vert_shape.size = Vector3(0.01, 0.16, 0.01)
	vert_col.shape = vert_shape
	vert_col.position = Vector3(0, 0.08, 0)
	frame.add_child(vert_col)

	# Horizontal bar
	add_mesh_child(
		frame,
		make_box_mesh(Vector3(0.16, 0.01, 0.01)),
		get_material(COLOR_FRAME),
		Vector3(0.08, 0, 0)
	)
	var hor_col = CollisionShape3D.new()
	var hor_shape = BoxShape3D.new()
	hor_shape.size = Vector3(0.16, 0.01, 0.01)
	hor_col.shape = hor_shape
	hor_col.position = Vector3(0.08, 0, 0)
	frame.add_child(hor_col)

	# --- Piston A (horizontal, driven by |a|) ---
	piston_a = create_rigid_body(
		Vector3(0.05, 0, 0),
		make_box_mesh(PISTON_SIZE),
		COLOR_ORANGE,
		0.3,
		"PistonA"
	)
	piston_a.gravity_scale = 0.0
	piston_a.linear_damp = 5.0
	piston_a.angular_damp = 10.0
	piston_a.axis_lock_angular_x = true
	piston_a.axis_lock_angular_y = true
	piston_a.axis_lock_angular_z = true
	piston_a.axis_lock_linear_y = true
	piston_a.axis_lock_linear_z = true

	slider_a = create_slider_joint(
		frame, piston_a,
		Vector3(0.08, 0, 0),
		0.0, MAX_EXTENSION,
		"SliderA"
	)

	# --- Piston B (vertical, driven by |b|) ---
	piston_b = create_rigid_body(
		Vector3(0, 0.05, 0),
		make_box_mesh(Vector3(0.02, 0.025, 0.02)),
		COLOR_CYAN,
		0.3,
		"PistonB"
	)
	piston_b.gravity_scale = 0.0
	piston_b.linear_damp = 5.0
	piston_b.angular_damp = 10.0
	piston_b.axis_lock_angular_x = true
	piston_b.axis_lock_angular_y = true
	piston_b.axis_lock_angular_z = true
	piston_b.axis_lock_linear_x = true
	piston_b.axis_lock_linear_z = true

	slider_b = create_slider_joint(
		frame, piston_b,
		Vector3(0, 0.08, 0),
		0.0, MAX_EXTENSION,
		"SliderB"
	)
	slider_b.rotation_degrees = Vector3(0, 0, 90)  # Rotate slider axis to Y

	# --- Platform marker (shows combined output position) ---
	platform_marker = MeshInstance3D.new()
	platform_marker.mesh = make_sphere_mesh(0.012)
	platform_marker.material_override = get_emissive_material(COLOR_YELLOW, 1.5)
	add_child(platform_marker)

	# --- Labels ---
	label_a = create_label("|a|", Vector3(0.1, -0.03, 0), 14, COLOR_ORANGE)
	label_b = create_label("|b|", Vector3(-0.03, 0.1, 0), 14, COLOR_CYAN)

func _process(_delta):
	# Platform marker follows the combined piston positions
	if piston_a and piston_b:
		platform_marker.position = Vector3(
			piston_a.position.x,
			piston_b.position.y,
			0
		)

	if label_a:
		label_a.text = "|a| = %.2f" % _target_a
	if label_b:
		label_b.text = "|b| = %.2f" % _target_b

func update_from_vectors(a: Vector3, b: Vector3) -> void:
	_target_a = a.length()
	_target_b = b.length()

	# Drive pistons with forces toward target positions
	var target_pos_a = clamp(_target_a * 0.05, 0, MAX_EXTENSION)
	var target_pos_b = clamp(_target_b * 0.05, 0, MAX_EXTENSION)

	var force_a = (target_pos_a - (piston_a.position.x - 0.05)) * 15.0
	var force_b = (target_pos_b - (piston_b.position.y - 0.05)) * 15.0

	piston_a.apply_central_force(Vector3(force_a, 0, 0))
	piston_b.apply_central_force(Vector3(0, force_b, 0))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

