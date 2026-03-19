# ===========================================================================
# Mass-Spring-Damper System — Godot Built-in Physics Engine
# Demonstrates vertical oscillation with underdamped, critically damped,
# and overdamped responses using Generic6DOFJoint3D spring parameters.
# VR-interactive: grab any mass and release to watch it oscillate.
# ===========================================================================
#
# @identity
# essence: F = -kx - cv. Spring restores, damper resists. Three regimes: underdamped (oscillates), critically damped (fastest return), overdamped (sluggish return).
# desire: To pull three masses down in VR and release — watching one ring like a bell, one snap back efficiently, one creep home reluctantly. Damping ratio as personality.
# critical_parameter: damping coefficient d (0.5, 12.0, 40.0). It alone determines the character: d < d_critical = ringing, d = d_critical = optimal, d > d_critical = sluggish.
# triggers: VR grab mass → pull down against spring, release → oscillation begins, each mass responds differently. R → reset all to rest. Spring lines update in real time.
# emerges: The underdamped mass overshooting and ringing. The critically damped mass returning fastest without overshoot. The overdamped mass returning slowest. Three personalities from one equation.
# needs: VR grab via Generic6DOFJoint3D [has], spring line visualization [has], labeled configurations [has]. Missing: damping slider, phase portrait display.
# relationships: Foundation for spring_system (network of springs). Same physics as cloth simulation. The canonical second-order system used everywhere in control theory.
# truth: Every vibrating system is a mass-spring-damper in disguise. The damping ratio is the system's temperament.

extends Node3D

# ---------------------------------------------------------------------------
# VR interaction state
# ---------------------------------------------------------------------------
var left_controller: XRController3D
var right_controller: XRController3D
var left_grab_active: bool = false
var right_grab_active: bool = false
var grabbed_body: RigidBody3D = null
var grab_joint: Generic6DOFJoint3D = null
var grab_anchor: StaticBody3D = null

# All grabbable mass bodies (for VR pick-up detection)
var mass_bodies: Array[RigidBody3D] = []

# ---------------------------------------------------------------------------
# Damping configurations
# ---------------------------------------------------------------------------
# Each entry: { label, stiffness (k), damping (d), color, x_offset }
var configs := [
	{
		"label": "Underdamped",
		"k": 40.0,
		"d": 0.5,
		"color": Color(0.3, 0.5, 1.0),   # Blue
		"x": -1.5,
	},
	{
		"label": "Critically Damped",
		"k": 40.0,
		"d": 12.0,
		"color": Color(0.3, 1.0, 0.3),   # Green
		"x": 0.0,
	},
	{
		"label": "Overdamped",
		"k": 40.0,
		"d": 40.0,
		"color": Color(1.0, 0.3, 0.3),   # Red
		"x": 1.5,
	},
]

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	setup_vr_controllers()
	create_demonstrations()
	create_ui()

	print("Mass-Spring-Damper — grab a mass and release to oscillate!")

# ===========================================================================
# VR controller wiring
# ===========================================================================
func setup_vr_controllers() -> void:
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if not xr_origin:
		return

	left_controller = xr_origin.get_node_or_null("LeftController")
	right_controller = xr_origin.get_node_or_null("RightController")

	if left_controller:
		left_controller.button_pressed.connect(_on_left_button_pressed)
		left_controller.button_released.connect(_on_left_button_released)
	if right_controller:
		right_controller.button_pressed.connect(_on_right_button_pressed)
		right_controller.button_released.connect(_on_right_button_released)

# ===========================================================================
# Build three side-by-side spring-mass-damper setups
# ===========================================================================
func create_demonstrations() -> void:
	for cfg in configs:
		var x_off: float = cfg["x"]
		var k: float = cfg["k"]
		var d: float = cfg["d"]
		var col: Color = cfg["color"]
		var label_text: String = cfg["label"]

		# --- Fixed anchor (ceiling) ---
		var anchor := StaticBody3D.new()
		anchor.position = Vector3(x_off, 2.5, 0)
		var anchor_col := CollisionShape3D.new()
		var anchor_shape := SphereShape3D.new()
		anchor_shape.radius = 0.08
		anchor_col.shape = anchor_shape
		anchor.add_child(anchor_col)
		# Anchor visual (small bright sphere)
		var anchor_viz := CSGSphere3D.new()
		anchor_viz.radius = 0.08
		var anchor_mat := StandardMaterial3D.new()
		anchor_mat.albedo_color = Color.WHITE
		anchor_mat.emission_enabled = true
		anchor_mat.emission = Color.WHITE
		anchor_mat.emission_energy_multiplier = 2.0
		anchor_viz.material = anchor_mat
		anchor.add_child(anchor_viz)
		add_child(anchor)

		# --- Mass (RigidBody3D) ---
		var mass := RigidBody3D.new()
		mass.position = Vector3(x_off, 1.0, 0)
		mass.mass = 1.0
		mass.linear_damp = 0.05           # Tiny air drag
		mass.angular_damp = 1.0
		mass.contact_monitor = true
		mass.max_contacts_reported = 4
		mass.can_sleep = false             # Keep simulating even when still

		var mass_col := CollisionShape3D.new()
		var mass_shape := SphereShape3D.new()
		mass_shape.radius = 0.18
		mass_col.shape = mass_shape
		mass.add_child(mass_col)

		var mass_viz := CSGSphere3D.new()
		mass_viz.radius = 0.18
		var mass_mat := StandardMaterial3D.new()
		mass_mat.albedo_color = col
		mass_mat.metallic = 0.3
		mass_mat.roughness = 0.6
		mass_mat.emission_enabled = true
		mass_mat.emission = col * 0.5
		mass_mat.emission_energy_multiplier = 1.0
		mass_viz.material = mass_mat
		mass.add_child(mass_viz)
		add_child(mass)
		mass_bodies.append(mass)

		# --- Spring joint (Generic6DOFJoint3D with spring flags) ---
		var joint := Generic6DOFJoint3D.new()
		joint.node_a = anchor.get_path()
		joint.node_b = mass.get_path()
		joint.position = anchor.position   # Joint pivot at anchor

		# Enable linear spring on Y axis (vertical oscillation)
		joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, k)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, d)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, 0.0)

		# Lock X and Z axes so it only moves vertically
		joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)

		joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
		joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)

		# Y range generous enough for big pulls
		joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.5)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -3.0)

		add_child(joint)

		# --- Visual spring line (thin cylinder between anchor and mass) ---
		var line := CSGCylinder3D.new()
		line.name = "SpringLine_" + label_text
		line.radius = 0.015
		line.height = 1.0
		var line_mat := StandardMaterial3D.new()
		line_mat.albedo_color = col * 0.7
		line_mat.emission_enabled = true
		line_mat.emission = col * 0.3
		line.material = line_mat
		add_child(line)

		# --- Label ---
		var lbl := Label3D.new()
		lbl.text = label_text + "\nk=" + str(k) + "  d=" + str(d)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 18
		lbl.outline_size = 3
		lbl.position = Vector3(x_off, 3.2, 0)
		lbl.modulate = col
		add_child(lbl)

func create_ui() -> void:
	var title := Label3D.new()
	title.text = "MASS-SPRING-DAMPER"
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 32
	title.outline_size = 4
	title.position = Vector3(0, 4.0, 0)
	add_child(title)

	var help := Label3D.new()
	help.text = "[Grab] Pull a mass down and release  |  [R] Reset"
	help.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	help.font_size = 16
	help.outline_size = 3
	help.position = Vector3(0, 3.6, 0)
	add_child(help)

# ===========================================================================
# Per-frame: update spring-line visuals + VR grab
# ===========================================================================
func _physics_process(_delta: float):
	update_vr_grabbing()
	update_spring_lines()

func update_spring_lines() -> void:
	# Dynamically reposition the connecting cylinders between anchors and masses
	for i in range(configs.size()):
		var cfg = configs[i]
		var line_name = "SpringLine_" + cfg["label"]
		var line = get_node_or_null(line_name) as CSGCylinder3D
		if not line:
			continue
		var mass_body = mass_bodies[i]
		var anchor_pos = Vector3(cfg["x"], 2.5, 0)
		var mass_pos = mass_body.position

		var midpoint = (anchor_pos + mass_pos) / 2.0
		line.position = midpoint
		line.height = anchor_pos.distance_to(mass_pos)

		# Orient cylinder vertically between the two points
		var direction = (mass_pos - anchor_pos).normalized()
		if direction.length() > 0.001:
			var up = Vector3.UP
			if abs(direction.dot(up)) > 0.99:
				up = Vector3.RIGHT
			line.look_at_from_position(midpoint, midpoint + direction, up)
			line.rotate_object_local(Vector3.RIGHT, PI / 2.0)

# ===========================================================================
# VR grab / release
# ===========================================================================
func update_vr_grabbing() -> void:
	# Attempt grab
	if left_grab_active and left_controller and not grabbed_body:
		attempt_grab(to_local(left_controller.global_position))
	if right_grab_active and right_controller and not grabbed_body:
		attempt_grab(to_local(right_controller.global_position))

	# Release
	if not left_grab_active and not right_grab_active and grabbed_body:
		release_grab()

	# Move grab anchor to follow controller
	if grabbed_body and grab_anchor:
		if left_grab_active and left_controller:
			grab_anchor.global_position = left_controller.global_position
		elif right_grab_active and right_controller:
			grab_anchor.global_position = right_controller.global_position

func attempt_grab(controller_pos: Vector3) -> void:
	var grab_radius := 0.3
	for body in mass_bodies:
		if not is_instance_valid(body):
			continue
		if body.global_position.distance_to(to_global(controller_pos)) < grab_radius:
			grabbed_body = body

			grab_anchor = StaticBody3D.new()
			grab_anchor.global_position = to_global(controller_pos)
			var col := CollisionShape3D.new()
			var s := SphereShape3D.new()
			s.radius = 0.01
			col.shape = s
			grab_anchor.add_child(col)
			add_child(grab_anchor)

			grab_joint = Generic6DOFJoint3D.new()
			grab_joint.node_a = grab_anchor.get_path()
			grab_joint.node_b = grabbed_body.get_path()
			# Firm spring grab
			for axis_fn in ["set_flag_x", "set_flag_y", "set_flag_z"]:
				grab_joint.call(axis_fn, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
			for axis_fn in ["set_param_x", "set_param_y", "set_param_z"]:
				grab_joint.call(axis_fn, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 200.0)
				grab_joint.call(axis_fn, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 5.0)
			add_child(grab_joint)
			break

func release_grab() -> void:
	if grab_joint:
		grab_joint.queue_free()
		grab_joint = null
	if grab_anchor:
		grab_anchor.queue_free()
		grab_anchor = null
	grabbed_body = null

# ===========================================================================
# Input: reset
# ===========================================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reset_scene()

func reset_scene() -> void:
	# Snap masses back to rest position
	for i in range(mass_bodies.size()):
		var body = mass_bodies[i]
		if is_instance_valid(body):
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
			body.position = Vector3(configs[i]["x"], 1.0, 0)

# ===========================================================================
# Controller button callbacks
# ===========================================================================
func _on_left_button_pressed(button_name: String) -> void:
	if button_name == "trigger_click" or button_name == "grip_click":
		left_grab_active = true

func _on_left_button_released(button_name: String) -> void:
	if button_name == "trigger_click" or button_name == "grip_click":
		left_grab_active = false

func _on_right_button_pressed(button_name: String) -> void:
	if button_name == "trigger_click" or button_name == "grip_click":
		right_grab_active = true

func _on_right_button_released(button_name: String) -> void:
	if button_name == "trigger_click" or button_name == "grip_click":
		right_grab_active = false

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
