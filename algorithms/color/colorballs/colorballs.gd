extends Node3D

# Random Color Rigidbody Balls - Sizes between handballs and golfballs
# Creates physics-enabled balls with random colors from palette system

const DEFAULT_PALETTE_PATH := "res://algorithms/color/color_palettes.tres"

@export_category("Ball Settings")
@export var ball_count: int = 20
@export var min_ball_radius: float = 0.1  # 10cm radius
@export var max_ball_radius: float = 0.1   # 10cm radius
@export var ball_mass: float = 0.1
@export var ball_bounce: float = 0.8
@export var ball_friction: float = 0.3

@export_category("Spawn Settings")
@export var spawn_area_size: Vector3 = Vector3(2.0, 1.0, 2.0)
@export var spawn_height: float = 1.5
@export var initial_velocity_range: float = 2.0
@export var respawn_on_fall: bool = true
@export var fall_threshold: float = -2.0

@export_category("Color Settings")
@export var color_palette_resource: Resource
@export var use_random_colors: bool = true
@export var color_intensity: float = 1.0
@export var emission_strength: float = 0.3
@export var metallic_factor: float = 0.1
@export var roughness_factor: float = 0.4

@export_category("Physics")
@export var gravity_scale: float = 1.0
@export var linear_damp: float = 0.1
@export var angular_damp: float = 0.1

# Internal variables
var palette_keys: Array = []
var current_palette_index: int = 0
var balls: Array = []
var ball_scene: PackedScene

func _ready() -> void:
	_ensure_palette_resource()
	palette_keys = _collect_palette_keys()
	if palette_keys.is_empty():
		push_warning("ColorBalls: No color palettes available")
		return

	var name_hash = name.hash()
	current_palette_index = abs(name_hash) % palette_keys.size()
	
	create_ball_scene()
	spawn_balls()

func _ensure_palette_resource() -> void:
	if color_palette_resource != null:
		return
	if ResourceLoader.exists(DEFAULT_PALETTE_PATH):
		color_palette_resource = ResourceLoader.load(DEFAULT_PALETTE_PATH)
	else:
		push_warning("ColorBalls: Palette resource not found at %s" % DEFAULT_PALETTE_PATH)

func _collect_palette_keys() -> Array:
	var palettes_dict = _get_palettes_dict()
	if palettes_dict.is_empty():
		return []
	return Array(palettes_dict.keys())

func _get_palettes_dict() -> Dictionary:
	if color_palette_resource and "palettes" in color_palette_resource:
		var palettes = color_palette_resource.palettes
		if typeof(palettes) == TYPE_DICTIONARY:
			return palettes
	return {}

func _get_palette_colors(palette_name: String) -> Array:
	var palettes_dict = _get_palettes_dict()
	if palettes_dict.has(palette_name):
		var entry = palettes_dict[palette_name]
		var colors_source = entry.get("colors", [])
		var result: Array = []
		for value in colors_source:
			if value is Color:
				result.append(value)
		return result
	return []

func create_ball_scene() -> void:
	# We'll create balls directly instead of using PackedScene
	# This avoids the packing/instantiation issues
	print("Ball scene creation skipped - using direct creation")

func create_ball_directly(name: String) -> Node3D:
	"""Create a ball directly without using PackedScene"""
	var root = Node3D.new()
	root.name = name
	
	# Create rigid body
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "RigidBody3D"
	rigid_body.mass = ball_mass
	rigid_body.gravity_scale = gravity_scale
	rigid_body.linear_damp = linear_damp
	rigid_body.angular_damp = angular_damp
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.1
	collision_shape.shape = sphere_shape
	
	# Create physics material
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = ball_bounce
	physics_material.friction = ball_friction
	rigid_body.physics_material_override = physics_material
	
	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	
	# Create sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	sphere_mesh.radial_segments = 48
	sphere_mesh.rings = 24
	mesh_instance.mesh = sphere_mesh
	
	# Assemble the scene
	rigid_body.add_child(collision_shape)
	rigid_body.add_child(mesh_instance)
	root.add_child(rigid_body)
	
	print("Created ball directly: %s" % name)
	print("Root children: ", root.get_children())
	print("RigidBody children: ", rigid_body.get_children())
	
	return root

func spawn_balls() -> void:
	# Clear existing balls
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	balls.clear()
	
	# Spawn new balls
	for i in range(ball_count):
		var ball_instance = create_ball_directly("Ball_%d" % i)
		
		print("Created ball %d structure:" % i)
		print("Ball instance children: ", ball_instance.get_children())
		print("Ball instance name: ", ball_instance.name)
		
		# Random position within spawn area
		var random_pos = Vector3(
			randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
			spawn_height + randf_range(0, 0.5),
			randf_range(-spawn_area_size.z/2, spawn_area_size.z/2)
		)
		ball_instance.position = random_pos
		
		# Fixed radius; no scaling needed
		var fixed_radius := 0.1
		
		# Random initial velocity
		var random_vel = Vector3(
			randf_range(-initial_velocity_range, initial_velocity_range),
			randf_range(0, initial_velocity_range * 0.5),
			randf_range(-initial_velocity_range, initial_velocity_range)
		)
		
		# Apply color
		var color = get_random_color()
		set_ball_color(ball_instance, color)
		
		# Add to scene
		add_child(ball_instance)
		balls.append(ball_instance)
		
		# Apply initial velocity after a short delay to ensure physics is ready
		await get_tree().process_frame
		var rigid_body = ball_instance.get_node("RigidBody3D")
		rigid_body.linear_velocity = random_vel
		
		print("Created Ball_%d with radius: %.3f, color: %s" % [i, fixed_radius, color])

func get_random_color() -> Color:
	if palette_keys.is_empty():
		return Color(randf(), randf(), randf())
	
	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	var colors = _get_palette_colors(current_key)
	if colors.is_empty():
		return Color(randf(), randf(), randf())
	
	var random_color = colors[randi() % colors.size()]
	return random_color * color_intensity

func set_ball_color(ball_instance: Node3D, color: Color) -> void:
	var rigid_body = ball_instance.get_node("RigidBody3D")
	var mesh_instance = rigid_body.get_node("MeshInstance3D")
	
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = metallic_factor
		material.roughness = roughness_factor
		material.emission_enabled = true
		material.emission = color * emission_strength
		material.emission_energy_multiplier = 1.0
		mesh_instance.material_override = material

func _process(delta: float) -> void:
	if respawn_on_fall:
		check_and_respawn_fallen_balls()

func check_and_respawn_fallen_balls() -> void:
	for i in range(balls.size()):
		var ball = balls[i]
		if is_instance_valid(ball) and ball.position.y < fall_threshold:
			# Respawn the ball
			var new_pos = Vector3(
				randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
				spawn_height,
				randf_range(-spawn_area_size.z/2, spawn_area_size.z/2)
			)
			ball.position = new_pos
			
			# Reset velocity
			var rigid_body = ball.get_node("RigidBody3D")
			if rigid_body:
				rigid_body.linear_velocity = Vector3.ZERO
				rigid_body.angular_velocity = Vector3.ZERO
			
			# New random color
			var new_color = get_random_color()
			set_ball_color(ball, new_color)
			
			print("Respawned Ball_%d with new color: %s" % [i, new_color])

func regenerate_balls() -> void:
	spawn_balls()

func cycle_to_next_palette() -> void:
	if palette_keys.is_empty():
		return
	
	current_palette_index = (current_palette_index + 1) % palette_keys.size()
	
	# Update all existing balls with new colors
	for i in range(balls.size()):
		var ball = balls[i]
		if is_instance_valid(ball):
			var new_color = get_random_color()
			set_ball_color(ball, new_color)
	
	print("Cycled to palette: %s" % get_current_palette_name())

func get_current_palette_name() -> String:
	if palette_keys.is_empty():
		return "No Palette"
	var current_key = palette_keys[current_palette_index % palette_keys.size()]
	var palettes_dict = _get_palettes_dict()
	if palettes_dict.has(current_key):
		return palettes_dict[current_key].get("title", current_key)
	return current_key

func add_ball() -> void:
	var ball_instance = create_ball_directly("Ball_%d" % balls.size())
	
	var random_pos = Vector3(
		randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
		spawn_height,
		randf_range(-spawn_area_size.z/2, spawn_area_size.z/2)
	)
	ball_instance.position = random_pos
	
	# Fixed radius; no scaling needed
	var fixed_radius := 0.1
	
	var color = get_random_color()
	set_ball_color(ball_instance, color)
	
	add_child(ball_instance)
	balls.append(ball_instance)
	
	await get_tree().process_frame
	var rigid_body = ball_instance.get_node("RigidBody3D")
	rigid_body.linear_velocity = Vector3(
		randf_range(-initial_velocity_range, initial_velocity_range),
		randf_range(0, initial_velocity_range * 0.5),
		randf_range(-initial_velocity_range, initial_velocity_range)
	)
	
	print("Added new ball with radius: %.3f, color: %s" % [fixed_radius, color])

func remove_ball() -> void:
	if balls.size() > 0:
		var last_ball = balls[-1]
		if is_instance_valid(last_ball):
			last_ball.queue_free()
		balls.pop_back()
		print("Removed ball. Remaining: %d" % balls.size())

func clear_all_balls() -> void:
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	balls.clear()
	print("Cleared all balls")

func create_ball_at_y(y_position: float = 7.0) -> void:
	"""Create a single color ball at the specified y position"""
	var ball_instance = create_ball_directly("Ball_Y_%.1f" % y_position)
	
	# Position at y = 7 with random x and z
	var random_pos = Vector3(
		randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
		y_position,
		randf_range(-spawn_area_size.z/2, spawn_area_size.z/2)
	)
	ball_instance.position = random_pos
	
	# Fixed radius; no scaling needed
	var fixed_radius := 0.1
	
	# Random color
	var color = get_random_color()
	set_ball_color(ball_instance, color)
	
	# Add to scene
	add_child(ball_instance)
	balls.append(ball_instance)
	
	# Apply small initial velocity
	await get_tree().process_frame
	var rigid_body = ball_instance.get_node("RigidBody3D")
	rigid_body.linear_velocity = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	)
	
	print("Created ball at y=%.1f with radius: %.3f, color: %s" % [y_position, fixed_radius, color])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space key
		add_ball()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		remove_ball()
	elif event.is_action_pressed("ui_select"):  # Enter key
		cycle_to_next_palette()
	elif event.is_action_pressed("ui_home"):  # Home key
		regenerate_balls()
	elif event.is_action_pressed("ui_end"):  # End key
		clear_all_balls()
	elif event.is_action_pressed("ui_page_up"):  # Page Up key
		create_ball_at_y(7.0)
