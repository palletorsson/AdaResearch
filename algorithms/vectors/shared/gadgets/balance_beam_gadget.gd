extends GadgetBase

# Balance Beam Gadget — Seesaw for vector subtraction
# Uses HingeJoint3D. Two weights on beam ends.
# Weight sizes proportional to |a| and |b|.
# Beam tilts naturally via gravity (physics-driven).

var fulcrum: StaticBody3D
var beam: RigidBody3D
var weight_a: RigidBody3D
var weight_b: RigidBody3D
var beam_hinge: HingeJoint3D
var pin_a: PinJoint3D
var pin_b: PinJoint3D
var diff_label: Label3D

const BEAM_LENGTH := 0.18
const BEAM_SIZE := Vector3(0.18, 0.006, 0.02)
const FULCRUM_HEIGHT := 0.04
const WEIGHT_BASE_SIZE := 0.015

var _target_mass_a: float = 1.0
var _target_mass_b: float = 1.0

func _ready() -> void:
	# --- Fulcrum (triangle base) ---
	fulcrum = create_static_body(
		Vector3(0, 0, 0),
		make_cylinder_mesh(0.015, FULCRUM_HEIGHT),
		COLOR_METAL,
		"Fulcrum"
	)
	# Small base plate
	add_mesh_child(
		fulcrum,
		make_box_mesh(Vector3(0.05, 0.005, 0.03)),
		get_material(COLOR_DARK_METAL),
		Vector3(0, -FULCRUM_HEIGHT / 2.0, 0)
	)

	# --- Beam ---
	beam = create_rigid_body(
		Vector3(0, FULCRUM_HEIGHT / 2.0 + 0.003, 0),
		make_box_mesh(BEAM_SIZE),
		COLOR_FRAME,
		0.3,
		"Beam"
	)
	beam.angular_damp = 2.0
	beam.linear_damp = 2.0
	beam.axis_lock_linear_x = true
	beam.axis_lock_linear_y = true
	beam.axis_lock_angular_x = true
	beam.axis_lock_angular_y = true

	# --- Beam hinge (Z axis rotation for tilt) ---
	beam_hinge = create_hinge_joint(
		fulcrum, beam,
		Vector3(0, FULCRUM_HEIGHT / 2.0, 0),
		Vector3(0, 0, 0),  # Default Y-axis hinge
		false, 0.0, "BeamHinge"
	)
	# Rotate hinge to tilt around Z
	beam_hinge.rotation_degrees = Vector3(0, 0, 90)
	beam_hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	beam_hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-35))
	beam_hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(35))

	# --- Weight A (left side, orange) ---
	weight_a = create_rigid_body(
		Vector3(-BEAM_LENGTH / 2.0, FULCRUM_HEIGHT / 2.0 + BEAM_SIZE.y + WEIGHT_BASE_SIZE, 0),
		make_box_mesh(Vector3(WEIGHT_BASE_SIZE, WEIGHT_BASE_SIZE, WEIGHT_BASE_SIZE)),
		COLOR_ORANGE,
		1.0,
		"WeightA"
	)
	weight_a.angular_damp = 5.0

	# Pin weight A to beam
	pin_a = PinJoint3D.new()
	pin_a.name = "PinA"
	pin_a.position = Vector3(-BEAM_LENGTH / 2.0, FULCRUM_HEIGHT / 2.0 + BEAM_SIZE.y / 2.0, 0)
	pin_a.node_a = beam.get_path()
	pin_a.node_b = weight_a.get_path()
	pin_a.set_exclude_nodes_from_collision(true)
	add_child(pin_a)

	# --- Weight B (right side, cyan) ---
	weight_b = create_rigid_body(
		Vector3(BEAM_LENGTH / 2.0, FULCRUM_HEIGHT / 2.0 + BEAM_SIZE.y + WEIGHT_BASE_SIZE, 0),
		make_box_mesh(Vector3(WEIGHT_BASE_SIZE, WEIGHT_BASE_SIZE, WEIGHT_BASE_SIZE)),
		COLOR_CYAN,
		1.0,
		"WeightB"
	)
	weight_b.angular_damp = 5.0

	# Pin weight B to beam
	pin_b = PinJoint3D.new()
	pin_b.name = "PinB"
	pin_b.position = Vector3(BEAM_LENGTH / 2.0, FULCRUM_HEIGHT / 2.0 + BEAM_SIZE.y / 2.0, 0)
	pin_b.node_a = beam.get_path()
	pin_b.node_b = weight_b.get_path()
	pin_b.set_exclude_nodes_from_collision(true)
	add_child(pin_b)

	# --- Label ---
	diff_label = create_label("|a|-|b|", Vector3(0, FULCRUM_HEIGHT + 0.06, 0), 14)

func _process(_delta):
	# Smoothly adjust weight masses toward target
	if weight_a:
		weight_a.mass = lerp(weight_a.mass, _target_mass_a, 0.1)
		# Scale visual to reflect mass
		var s = WEIGHT_BASE_SIZE * (0.5 + weight_a.mass * 0.5)
		var mi = weight_a.get_child(0) as MeshInstance3D
		if mi:
			mi.scale = Vector3.ONE * (weight_a.mass * 0.8 + 0.4)

	if weight_b:
		weight_b.mass = lerp(weight_b.mass, _target_mass_b, 0.1)
		var mi = weight_b.get_child(0) as MeshInstance3D
		if mi:
			mi.scale = Vector3.ONE * (weight_b.mass * 0.8 + 0.4)

	if diff_label:
		diff_label.text = "|a|-|b| = %.2f" % (_target_mass_a - _target_mass_b)

func update_from_vectors(a: Vector3, b: Vector3) -> void:
	_target_mass_a = clamp(a.length(), 0.1, 5.0)
	_target_mass_b = clamp(b.length(), 0.1, 5.0)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
