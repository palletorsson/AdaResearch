# ===========================================================================
# Rigid Body Dynamics - VR Physics Playground
# Uses Godot's built-in RigidBody3D physics engine for all collision
# detection and resolution. Demonstrates stacking, mass variation,
# and restitution (bounciness) with VR grab-and-throw interaction.
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

# All spawned blocks for management
var blocks: Array[RigidBody3D] = []
var block_counter: int = 0

# Queer color palette
var colors = [
	Color(1.0, 0.3, 0.3, 1.0),   # Red
	Color(0.3, 1.0, 0.3, 1.0),   # Green
	Color(0.3, 0.5, 1.0, 1.0),   # Blue
	Color(1.0, 0.8, 0.2, 1.0),   # Gold
	Color(1.0, 0.3, 0.7, 1.0),   # Pink
	Color(0.3, 0.9, 0.9, 1.0),   # Cyan
	Color(0.8, 0.3, 1.0, 1.0),   # Purple
	Color(1.0, 0.5, 0.3, 1.0),   # Coral
]

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)
	
	setup_vr_controllers()
	create_environment()
	create_stacking_demo()
	create_mass_variation_demo()
	create_restitution_demo()
	create_ui()
	
	print("Rigid Body Dynamics - Grab blocks and throw them in VR!")

# ===========================================================================
# VR CONTROLLER SETUP
# ===========================================================================
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

# ===========================================================================
# ENVIRONMENT - StaticBody3D walls and floor
# ===========================================================================
func create_environment() -> void:
	var env = Node3D.new()
	env.name = "Environment"
	add_child(env)
	
	# Floor
	var floor_body = StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector3(0, 0, 0)
	
	var floor_shape = CollisionShape3D.new()
	var floor_box = BoxShape3D.new()
	floor_box.size = Vector3(20, 0.2, 20)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(20, 0.2, 20)
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.15, 0.15, 0.2, 1.0)
	floor_mat.metallic = 0.1
	floor_mat.roughness = 0.9
	floor_mesh.material = floor_mat
	floor_body.add_child(floor_mesh)
	
	# Set floor physics material (low bounce, some friction)
	var floor_phys = PhysicsMaterial.new()
	floor_phys.bounce = 0.1
	floor_phys.friction = 0.8
	floor_body.physics_material_override = floor_phys
	
	env.add_child(floor_body)
	
	# Invisible walls to keep blocks in the play area
	_create_wall(env, Vector3(0, 2, 10), Vector3(20, 5, 0.2))   # North
	_create_wall(env, Vector3(0, 2, -10), Vector3(20, 5, 0.2))  # South
	_create_wall(env, Vector3(10, 2, 0), Vector3(0.2, 5, 20))   # East
	_create_wall(env, Vector3(-10, 2, 0), Vector3(0.2, 5, 20))  # West

func _create_wall(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var wall = StaticBody3D.new()
	wall.position = pos
	
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	wall.add_child(shape)
	
	# Transparent wall mesh (barely visible boundary)
	var mesh = CSGBox3D.new()
	mesh.size = size
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.4, 0.1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	wall.add_child(mesh)
	
	parent.add_child(wall)

# ===========================================================================
# DEMO 1: STACKING - Blocks piled up, let Godot physics resolve
# ===========================================================================
func create_stacking_demo() -> void:
	var demos = Node3D.new()
	demos.name = "Demonstrations"
	add_child(demos)
	
	var stack_group = Node3D.new()
	stack_group.name = "StackingDemo"
	demos.add_child(stack_group)
	
	# Build a pyramid stack at left side
	var base_pos = Vector3(-4, 0.1, 0)
	var block_size = Vector3(0.6, 0.6, 0.6)
	
	# 3-2-1 pyramid
	var rows = [3, 2, 1]
	for row_idx in range(rows.size()):
		var count = rows[row_idx]
		var y = base_pos.y + (row_idx + 0.5) * block_size.y
		var start_x = base_pos.x - (count - 1) * block_size.x * 0.5
		
		for i in range(count):
			var pos = Vector3(start_x + i * block_size.x, y, base_pos.z)
			var block = _create_physics_block(
				pos, block_size, 2.0,
				colors[(row_idx * 3 + i) % colors.size()],
				0.2  # Low bounce for stable stacking
			)
			stack_group.add_child(block)
			blocks.append(block)
			block_counter += 1
	
	# Label
	var label = Label3D.new()
	label.text = "STACKING"
	label.font_size = 20
	label.outline_size = 3
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(-4, 3, 0)
	stack_group.add_child(label)

# ===========================================================================
# DEMO 2: MASS VARIATION - Different sized/massed blocks
# ===========================================================================
func create_mass_variation_demo() -> void:
	var mass_group = Node3D.new()
	mass_group.name = "MassDemo"
	$Demonstrations.add_child(mass_group)
	
	# Small light block
	var small = _create_physics_block(
		Vector3(0, 2, -2), Vector3(0.3, 0.3, 0.3), 0.5,
		colors[0], 0.3
	)
	mass_group.add_child(small)
	blocks.append(small)
	
	# Medium block
	var medium = _create_physics_block(
		Vector3(0, 2, 0), Vector3(0.6, 0.6, 0.6), 3.0,
		colors[2], 0.3
	)
	mass_group.add_child(medium)
	blocks.append(medium)
	
	# Large heavy block
	var large = _create_physics_block(
		Vector3(0, 2, 2), Vector3(1.0, 1.0, 1.0), 10.0,
		colors[4], 0.3
	)
	mass_group.add_child(large)
	blocks.append(large)
	
	# Extra heavy small block (dense material)
	var dense = _create_physics_block(
		Vector3(0, 3, 0), Vector3(0.4, 0.4, 0.4), 15.0,
		colors[6], 0.1
	)
	mass_group.add_child(dense)
	blocks.append(dense)
	
	# Labels showing mass
	for data in [
		[Vector3(0, 1.5, -2), "0.5 kg"],
		[Vector3(0, 1.5, 0), "3 kg"],
		[Vector3(0, 1.5, 2), "10 kg"],
		[Vector3(0, 2.5, 0), "15 kg (dense!)"],
	]:
		var lbl = Label3D.new()
		lbl.text = data[1]
		lbl.font_size = 14
		lbl.outline_size = 2
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = data[0]
		mass_group.add_child(lbl)
	
	var title = Label3D.new()
	title.text = "MASS VARIATION"
	title.font_size = 20
	title.outline_size = 3
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0, 4, 0)
	mass_group.add_child(title)

# ===========================================================================
# DEMO 3: RESTITUTION - Bouncy vs dead blocks
# ===========================================================================
func create_restitution_demo() -> void:
	var bounce_group = Node3D.new()
	bounce_group.name = "RestitutionDemo"
	$Demonstrations.add_child(bounce_group)
	
	var base_pos = Vector3(4, 3, 0)
	var bounces = [0.0, 0.3, 0.6, 0.9]
	var labels_text = ["Dead (0.0)", "Low (0.3)", "Medium (0.6)", "Bouncy (0.9)"]
	
	for i in range(bounces.size()):
		var z_offset = (i - 1.5) * 1.5
		var block = _create_physics_block(
			Vector3(base_pos.x, base_pos.y, base_pos.z + z_offset),
			Vector3(0.5, 0.5, 0.5), 2.0,
			colors[i * 2 % colors.size()],
			bounces[i]
		)
		bounce_group.add_child(block)
		blocks.append(block)
		
		# Label per block
		var lbl = Label3D.new()
		lbl.text = labels_text[i]
		lbl.font_size = 12
		lbl.outline_size = 2
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(base_pos.x, 1.5, base_pos.z + z_offset)
		bounce_group.add_child(lbl)
	
	var title = Label3D.new()
	title.text = "RESTITUTION (BOUNCE)"
	title.font_size = 20
	title.outline_size = 3
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(4, 5, 0)
	bounce_group.add_child(title)

# ===========================================================================
# BLOCK FACTORY - Creates a RigidBody3D block with CollisionShape3D
# ===========================================================================
func _create_physics_block(pos: Vector3, size: Vector3, mass: float, color: Color, bounce: float) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.name = "Block_" + str(block_counter)
	body.position = pos
	body.mass = mass
	body.contact_monitor = true
	body.max_contacts_reported = 4
	
	# Physics material controls bounce and friction
	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = bounce
	phys_mat.friction = 0.6
	body.physics_material_override = phys_mat
	
	# Collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	
	# Visual mesh
	var mesh = CSGBox3D.new()
	mesh.size = size
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = 0.8
	mesh.material = mat
	body.add_child(mesh)
	
	# Wireframe edge overlay for depth
	var edge_mesh = CSGBox3D.new()
	edge_mesh.size = size * 1.01  # Slightly larger
	var edge_mat = StandardMaterial3D.new()
	edge_mat.albedo_color = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.3)
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_mesh.material = edge_mat
	body.add_child(edge_mesh)
	
	block_counter += 1
	return body

# ===========================================================================
# UI
# ===========================================================================
func create_ui() -> void:
	var title = Label3D.new()
	title.text = "RIGID BODY DYNAMICS"
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 32
	title.outline_size = 4
	title.position = Vector3(0, 6, 0)
	add_child(title)
	
	var instructions = Label3D.new()
	instructions.text = "[Grab] to pick up blocks | [R] Reset | [A] Add block"
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.font_size = 18
	instructions.outline_size = 3
	instructions.position = Vector3(0, 5.3, 0)
	add_child(instructions)

# ===========================================================================
# VR GRAB SYSTEM (same pattern as Constraints_Interactive.gd)
# ===========================================================================
func _process(_delta: float):
	update_vr_grabbing()

func update_vr_grabbing() -> void:
	if left_grab_active and left_controller and not grabbed_body:
		attempt_grab(left_controller.global_position)
	elif not left_grab_active and grabbed_body:
		release_grab()
	
	if right_grab_active and right_controller and not grabbed_body:
		attempt_grab(right_controller.global_position)
	elif not right_grab_active and grabbed_body:
		release_grab()
	
	# Move grab anchor to follow controller
	if grabbed_body and grab_joint:
		if left_grab_active and left_controller:
			grab_anchor.global_position = left_controller.global_position
		elif right_grab_active and right_controller:
			grab_anchor.global_position = right_controller.global_position

func attempt_grab(controller_global_pos: Vector3) -> void:
	var grab_radius = 0.4
	
	for body in blocks:
		if not is_instance_valid(body):
			continue
		var distance = body.global_position.distance_to(controller_global_pos)
		if distance < grab_radius:
			grabbed_body = body
			
			# Create kinematic anchor at controller position
			grab_anchor = StaticBody3D.new()
			grab_anchor.global_position = controller_global_pos
			add_child(grab_anchor)
			
			# Create spring joint for firm but smooth grab
			grab_joint = Generic6DOFJoint3D.new()
			grab_joint.node_a = grab_anchor.get_path()
			grab_joint.node_b = grabbed_body.get_path()
			
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

# ===========================================================================
# VR BUTTON HANDLERS
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

# ===========================================================================
# KEYBOARD INPUT
# ===========================================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_all()
			KEY_A:
				add_random_block()

func reset_all() -> void:
	# Remove all blocks and recreate
	for block in blocks:
		if is_instance_valid(block):
			block.queue_free()
	blocks.clear()
	block_counter = 0
	
	# Remove demos node and recreate
	if has_node("Demonstrations"):
		$Demonstrations.queue_free()
	
	await get_tree().create_timer(0.1).timeout
	create_stacking_demo()
	create_mass_variation_demo()
	create_restitution_demo()

func add_random_block() -> void:
	var parent = $Demonstrations if has_node("Demonstrations") else self
	
	var size = Vector3(
		randf_range(0.3, 0.8),
		randf_range(0.3, 0.8),
		randf_range(0.3, 0.8)
	)
	var mass = randf_range(0.5, 8.0)
	var bounce = randf_range(0.0, 0.9)
	var color = colors[randi() % colors.size()]
	var pos = Vector3(
		randf_range(-3, 3),
		randf_range(3, 6),
		randf_range(-3, 3)
	)
	
	var block = _create_physics_block(pos, size, mass, color, bounce)
	parent.add_child(block)
	blocks.append(block)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
