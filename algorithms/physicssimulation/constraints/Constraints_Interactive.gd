# ===========================================================================
# Interactive Constraints System - VR Physics Playground
# Demonstrates Godot's joint system with grabbable, interactive objects
# ===========================================================================

extends Node3D

# VR interaction
var left_controller: XRController3D
var right_controller: XRController3D
var left_grab_active: bool = false
var right_grab_active: bool = false
var grabbed_body: RigidBody3D = null
var grab_joint: Generic6DOFJoint3D = null
var grab_anchor: StaticBody3D = null

# Demonstration objects
var pendulum_bodies: Array[RigidBody3D] = []
var chain_links: Array[RigidBody3D] = []
var ragdoll_parts: Array[RigidBody3D] = []
var slider_blocks: Array[RigidBody3D] = []
var hinge_doors: Array[RigidBody3D] = []
var spring_objects: Array[RigidBody3D] = []

# Settings
@export var enable_gravity: bool = true
@export var show_joint_visualizations: bool = true
@export var joint_strength: float = 1.0

var time: float = 0.0
var current_demo: int = 0
var demo_names = [
	"Pendulum Chain",
	"Rope Bridge",
	"Ragdoll",
	"Slider Rails",
	"Swinging Doors",
	"Spring Damper"
]

# Colors
var colors = [
	Color(1.0, 0.3, 0.3, 1.0),  # Red
	Color(0.3, 1.0, 0.3, 1.0),  # Green
	Color(0.3, 0.5, 1.0, 1.0),  # Blue
	Color(1.0, 0.8, 0.2, 1.0),  # Gold
	Color(1.0, 0.3, 0.7, 1.0),  # Pink
	Color(0.3, 0.9, 0.9, 1.0),  # Cyan
]

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	setup_vr_controllers()
	create_all_demonstrations()
	create_ui()

	print("Interactive Constraints - Grab and play with physics joints!")

func setup_vr_controllers() -> void:
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if xr_origin:
		left_controller = xr_origin.get_node_or_null("LeftController")
		right_controller = xr_origin.get_node_or_null("RightController")

		if left_controller:
			left_controller.button_pressed.connect(_on_left_button_pressed)
			left_controller.button_released.connect(_on_left_button_released)

		if right_controller:
			right_controller.button_pressed.connect(_on_right_button_pressed)
			right_controller.button_released.connect(_on_right_button_released)

func create_all_demonstrations() -> void:
	create_pendulum_chain()
	create_rope_bridge()
	create_ragdoll()
	create_slider_rails()
	create_swinging_doors()
	create_spring_damper_system()

# ===========================================================================
# 1. PENDULUM CHAIN - Multiple balls connected with PinJoint3D
# ===========================================================================
func create_pendulum_chain() -> void:
	var chain_length = 5
	var start_pos = Vector3(-4, 3, 0)

	# Create fixed anchor
	var anchor = create_static_anchor(start_pos, colors[0])
	$Demonstrations/PendulumChain.add_child(anchor)

	var prev_body = anchor

	for i in range(chain_length):
		# Create ball
		var ball = create_rigid_sphere(
			start_pos + Vector3(0, -(i + 1) * 0.6, 0),
			0.2,
			1.0,
			colors[i % colors.size()]
		)
		$Demonstrations/PendulumChain.add_child(ball)
		pendulum_bodies.append(ball)

		# Create pin joint
		var joint = PinJoint3D.new()
		joint.node_a = prev_body.get_path()
		joint.node_b = ball.get_path()
		joint.set_param(PinJoint3D.PARAM_BIAS, 0.3)
		joint.set_param(PinJoint3D.PARAM_DAMPING, 0.1)
		joint.position = prev_body.position + Vector3(0, -0.3, 0)
		$Demonstrations/PendulumChain.add_child(joint)

		# Visualize joint
		if show_joint_visualizations:
			var joint_viz = create_joint_visualization(joint.position, Color.WHITE)
			$Demonstrations/PendulumChain.add_child(joint_viz)

		prev_body = ball

# ===========================================================================
# 2. ROPE BRIDGE - Hanging bridge with multiple links
# ===========================================================================
func create_rope_bridge() -> void:
	var bridge_length = 8
	var start_pos = Vector3(0, 3, -3)
	var end_pos = Vector3(4, 3, -3)

	# Create anchors
	var anchor1 = create_static_anchor(start_pos, colors[1])
	var anchor2 = create_static_anchor(end_pos, colors[1])
	$Demonstrations/RopeBridge.add_child(anchor1)
	$Demonstrations/RopeBridge.add_child(anchor2)

	var prev_body = anchor1

	for i in range(bridge_length):
		var t = float(i + 1) / (bridge_length + 1)
		var pos = start_pos.lerp(end_pos, t)

		# Create plank
		var plank = create_rigid_box(
			pos,
			Vector3(0.4, 0.1, 0.2),
			0.5,
			colors[(i + 1) % colors.size()]
		)
		$Demonstrations/RopeBridge.add_child(plank)
		chain_links.append(plank)

		# Create joint
		var joint = Generic6DOFJoint3D.new()
		joint.node_a = prev_body.get_path()
		joint.node_b = plank.get_path()

		# Lock position but allow rotation
		joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)

		joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.01)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -0.01)

		joint.position = prev_body.position + (pos - prev_body.position) * 0.5
		$Demonstrations/RopeBridge.add_child(joint)

		prev_body = plank

	# Connect last plank to end anchor
	var final_joint = Generic6DOFJoint3D.new()
	final_joint.node_a = prev_body.get_path()
	final_joint.node_b = anchor2.get_path()
	final_joint.position = (prev_body.position + anchor2.position) * 0.5
	$Demonstrations/RopeBridge.add_child(final_joint)

# ===========================================================================
# 3. RAGDOLL - Simple character with ball and socket joints
# ===========================================================================
func create_ragdoll() -> void:
	var center = Vector3(4, 2, 0)

	# Torso
	var torso = create_rigid_box(center, Vector3(0.4, 0.6, 0.2), 2.0, colors[2])
	$Demonstrations/Ragdoll.add_child(torso)
	ragdoll_parts.append(torso)

	# Head
	var head = create_rigid_sphere(center + Vector3(0, 0.5, 0), 0.2, 0.5, colors[3])
	$Demonstrations/Ragdoll.add_child(head)
	ragdoll_parts.append(head)

	var neck_joint = ConeTwistJoint3D.new()
	neck_joint.node_a = torso.get_path()
	neck_joint.node_b = head.get_path()
	neck_joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(45))
	neck_joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(30))
	neck_joint.position = center + Vector3(0, 0.35, 0)
	$Demonstrations/Ragdoll.add_child(neck_joint)

	# Arms
	for side in [-1, 1]:
		var upper_arm = create_rigid_box(
			center + Vector3(side * 0.4, 0.2, 0),
			Vector3(0.15, 0.4, 0.15),
			0.5,
			colors[4]
		)
		$Demonstrations/Ragdoll.add_child(upper_arm)
		ragdoll_parts.append(upper_arm)

		var shoulder = ConeTwistJoint3D.new()
		shoulder.node_a = torso.get_path()
		shoulder.node_b = upper_arm.get_path()
		shoulder.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(90))
		shoulder.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(45))
		shoulder.position = center + Vector3(side * 0.25, 0.3, 0)
		$Demonstrations/Ragdoll.add_child(shoulder)

	# Legs
	for side in [-1, 1]:
		var upper_leg = create_rigid_box(
			center + Vector3(side * 0.15, -0.6, 0),
			Vector3(0.15, 0.5, 0.15),
			0.7,
			colors[5]
		)
		$Demonstrations/Ragdoll.add_child(upper_leg)
		ragdoll_parts.append(upper_leg)

		var hip = ConeTwistJoint3D.new()
		hip.node_a = torso.get_path()
		hip.node_b = upper_leg.get_path()
		hip.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(60))
		hip.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(30))
		hip.position = center + Vector3(side * 0.15, -0.35, 0)
		$Demonstrations/Ragdoll.add_child(hip)

# ===========================================================================
# 4. SLIDER RAILS - Objects constrained to linear motion
# ===========================================================================
func create_slider_rails() -> void:
	var rail_start = Vector3(-4, 1, 3)
	var rail_end = Vector3(-4, 1, -1)

	# Create rail visualization
	var rail_viz = create_rail_visual(rail_start, rail_end)
	$Demonstrations/SliderRails.add_child(rail_viz)

	# Create anchor
	var anchor = create_static_anchor(rail_start, colors[0])
	$Demonstrations/SliderRails.add_child(anchor)

	# Create sliding blocks
	for i in range(3):
		var pos = rail_start.lerp(rail_end, (i + 1) / 4.0)
		var block = create_rigid_box(pos, Vector3(0.3, 0.3, 0.3), 1.0, colors[i])
		$Demonstrations/SliderRails.add_child(block)
		slider_blocks.append(block)

		# Create slider joint
		var slider = SliderJoint3D.new()
		slider.node_a = anchor.get_path()
		slider.node_b = block.get_path()

		# Set slider limits
		slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 4.0)
		slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, 0.0)
		slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, 0.5)
		slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_DAMPING, 0.3)

		slider.position = rail_start
		slider.rotation = Vector3(0, 0, PI / 2)
		$Demonstrations/SliderRails.add_child(slider)

# ===========================================================================
# 5. SWINGING DOORS - HingeJoint3D demonstration
# ===========================================================================
func create_swinging_doors() -> void:
	var door_pos = Vector3(0, 2, 3)

	# Create door frame
	var frame = create_static_anchor(door_pos, Color.GRAY)
	$Demonstrations/SwingingDoors.add_child(frame)

	# Create doors
	for side in [-1, 1]:
		var door = create_rigid_box(
			door_pos + Vector3(side * 0.5, 0, 0),
			Vector3(0.8, 1.5, 0.1),
			2.0,
			colors[2] if side == -1 else colors[3]
		)
		$Demonstrations/SwingingDoors.add_child(door)
		hinge_doors.append(door)

		# Create hinge
		var hinge = HingeJoint3D.new()
		hinge.node_a = frame.get_path()
		hinge.node_b = door.get_path()

		# Set hinge limits
		hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-90))
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(90))

		hinge.position = door_pos + Vector3(side * 0.1, 0, 0)
		hinge.rotation = Vector3(0, 0, 0)
		$Demonstrations/SwingingDoors.add_child(hinge)

# ===========================================================================
# 6. SPRING DAMPER SYSTEM - Springy connections
# ===========================================================================
func create_spring_damper_system() -> void:
	var center = Vector3(4, 2, 3)

	# Create anchor
	var anchor = create_static_anchor(center, colors[5])
	$Demonstrations/SpringDamper.add_child(anchor)

	# Create spring-connected objects in a star pattern
	for i in range(6):
		var angle = (i / 6.0) * TAU
		var offset = Vector3(cos(angle), sin(angle) * 0.5, sin(angle)) * 1.5

		var obj = create_rigid_sphere(center + offset, 0.2, 0.5, colors[i])
		$Demonstrations/SpringDamper.add_child(obj)
		spring_objects.append(obj)

		# Create spring joint (using Generic6DOF with spring parameters)
		var spring = Generic6DOFJoint3D.new()
		spring.node_a = anchor.get_path()
		spring.node_b = obj.get_path()

		# Enable springs on all axes
		spring.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
		spring.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
		spring.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)

		spring.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 50.0)
		spring.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 50.0)
		spring.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 50.0)

		spring.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 2.0)
		spring.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 2.0)
		spring.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 2.0)

		spring.position = center
		$Demonstrations/SpringDamper.add_child(spring)

# ===========================================================================
# HELPER FUNCTIONS
# ===========================================================================

func create_rigid_sphere(pos: Vector3, radius: float, mass: float, color: Color) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = mass
	body.contact_monitor = true
	body.max_contacts_reported = 4

	var sphere = CSGSphere3D.new()
	sphere.radius = radius

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.emission_energy_multiplier = 1.0
	sphere.material = mat

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = radius
	collision.shape = shape

	body.add_child(sphere)
	body.add_child(collision)

	return body

func create_rigid_box(pos: Vector3, size: Vector3, mass: float, color: Color) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = mass
	body.contact_monitor = true
	body.max_contacts_reported = 4

	var box = CSGBox3D.new()
	box.size = size

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.emission_energy_multiplier = 1.0
	box.material = mat

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape

	body.add_child(box)
	body.add_child(collision)

	return body

func create_static_anchor(pos: Vector3, color: Color) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = pos

	var sphere = CSGSphere3D.new()
	sphere.radius = 0.1

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	sphere.material = mat

	body.add_child(sphere)

	return body

func create_joint_visualization(pos: Vector3, color: Color) -> MeshInstance3D:
	var viz = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	viz.mesh = sphere
	viz.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	viz.material_override = mat

	return viz

func create_rail_visual(start: Vector3, end: Vector3) -> MeshInstance3D:
	var rail = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = start.distance_to(end)
	rail.mesh = cylinder

	rail.position = (start + end) / 2
	rail.look_at(end, Vector3.UP)
	rail.rotate_object_local(Vector3.RIGHT, PI / 2)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GRAY
	mat.metallic = 0.8
	rail.material_override = mat

	return rail

func create_ui() -> void:
	var title = Label3D.new()
	title.text = "INTERACTIVE CONSTRAINTS"
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 32
	title.outline_size = 4
	title.position = Vector3(0, 5, 0)
	add_child(title)

	var instructions = Label3D.new()
	instructions.text = "[Grab] to interact | [R] Reset | [G] Toggle Gravity"
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.font_size = 18
	instructions.outline_size = 3
	instructions.position = Vector3(0, 4.3, 0)
	add_child(instructions)

func _process(_delta: float):
	update_vr_grabbing()

func update_vr_grabbing() -> void:
	if left_grab_active and left_controller and not grabbed_body:
		attempt_grab(to_local(left_controller.global_position))
	elif not left_grab_active and grabbed_body:
		release_grab()

	if right_grab_active and right_controller and not grabbed_body:
		attempt_grab(to_local(right_controller.global_position))
	elif not right_grab_active and grabbed_body:
		release_grab()

	# Update grab position
	if grabbed_body and grab_joint and left_controller and left_grab_active:
		grab_anchor.global_position = left_controller.global_position
	elif grabbed_body and grab_joint and right_controller and right_grab_active:
		grab_anchor.global_position = right_controller.global_position

func attempt_grab(controller_pos: Vector3) -> void:
	var grab_radius = 0.3
	var all_bodies = pendulum_bodies + chain_links + ragdoll_parts + slider_blocks + hinge_doors + spring_objects

	for body in all_bodies:
		if not is_instance_valid(body):
			continue

		var distance = body.global_position.distance_to(to_global(controller_pos))
		if distance < grab_radius:
			grabbed_body = body

			# Create anchor at controller
			grab_anchor = StaticBody3D.new()
			grab_anchor.global_position = to_global(controller_pos)
			add_child(grab_anchor)

			# Create joint
			grab_joint = Generic6DOFJoint3D.new()
			grab_joint.node_a = grab_anchor.get_path()
			grab_joint.node_b = grabbed_body.get_path()

			# Set high spring stiffness for firm grab
			for axis in [Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS]:
				grab_joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				grab_joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				grab_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)

				grab_joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 100.0)
				grab_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 100.0)
				grab_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 100.0)

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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_all_demonstrations()
			KEY_G:
				toggle_gravity()

func reset_all_demonstrations() -> void:
	# Clear and recreate all demos
	for child in $Demonstrations.get_children():
		for subchild in child.get_children():
			subchild.queue_free()

	pendulum_bodies.clear()
	chain_links.clear()
	ragdoll_parts.clear()
	slider_blocks.clear()
	hinge_doors.clear()
	spring_objects.clear()

	await get_tree().create_timer(0.1).timeout
	create_all_demonstrations()

func toggle_gravity() -> void:
	enable_gravity = !enable_gravity
	var gravity_value = Vector3(0, -9.8, 0) if enable_gravity else Vector3.ZERO

	for body in pendulum_bodies + chain_links + ragdoll_parts + slider_blocks + hinge_doors + spring_objects:
		if is_instance_valid(body):
			body.gravity_scale = 1.0 if enable_gravity else 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

