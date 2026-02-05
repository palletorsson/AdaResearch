extends Node3D

# Ball Dropper - Drops one colorful ball at a time
# Works with LaserTurret to create a shooting gallery

signal ball_spawned(ball: Node3D)
signal ball_destroyed(ball: Node3D)

@export_category("Dropper Settings")
@export var drop_interval: float = 3.0  # Seconds between drops
@export var auto_drop: bool = true
@export var max_balls: int = 5  # Max balls alive at once

@export_category("Ball Settings") 
@export var ball_radius: float = 0.1
@export var ball_mass: float = 0.5
@export var ball_bounce: float = 0.7
@export var emission_strength: float = 0.8

@export_category("Spawn Position")
@export var drop_height: float = 0.0  # Relative to dropper position
@export var spawn_spread: float = 0.3  # Random XZ spread
@export var initial_velocity: Vector3 = Vector3(0, 0, 0)

# Color palette
const BALL_COLORS = [
	Color(1.0, 0.3, 0.2),   # Red
	Color(0.2, 0.8, 1.0),   # Cyan
	Color(1.0, 0.8, 0.1),   # Yellow
	Color(0.4, 1.0, 0.4),   # Green
	Color(1.0, 0.4, 0.8),   # Pink
	Color(0.6, 0.4, 1.0),   # Purple
	Color(1.0, 0.5, 0.1),   # Orange
]

var balls: Array[Node3D] = []
var drop_timer: float = 0.0
var color_index: int = 0
var balls_dropped: int = 0

# Visual elements
var dropper_mesh: MeshInstance3D
var indicator_light: OmniLight3D

func _ready() -> void:
	add_to_group("ball_dropper")
	_build_dropper_visual()
	
	# First drop after short delay
	if auto_drop:
		drop_timer = drop_interval - 0.5

func _build_dropper_visual() -> void:
	# Dropper housing
	dropper_mesh = MeshInstance3D.new()
	dropper_mesh.name = "DropperMesh"
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.15, 0.3)
	dropper_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	mat.metallic = 0.6
	mat.roughness = 0.4
	dropper_mesh.material_override = mat
	add_child(dropper_mesh)
	
	# Funnel shape
	var funnel = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.12
	cone.bottom_radius = 0.06
	cone.height = 0.1
	funnel.mesh = cone
	funnel.position.y = -0.125
	funnel.material_override = mat
	add_child(funnel)
	
	# Status light
	indicator_light = OmniLight3D.new()
	indicator_light.name = "StatusLight"
	indicator_light.light_color = Color(0.2, 1.0, 0.3)
	indicator_light.light_energy = 0.5
	indicator_light.omni_range = 0.3
	indicator_light.position = Vector3(0, 0.1, 0)
	add_child(indicator_light)
	
	var light_bulb = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	light_bulb.mesh = sphere
	light_bulb.position = Vector3(0, 0.1, 0)
	
	var light_mat = StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.2, 1.0, 0.3)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.2, 1.0, 0.3)
	light_mat.emission_energy_multiplier = 2.0
	light_bulb.material_override = light_mat
	add_child(light_bulb)

func _process(delta: float) -> void:
	# Clean up destroyed balls
	_cleanup_invalid_balls()
	
	# Auto drop logic
	if auto_drop:
		drop_timer += delta
		if drop_timer >= drop_interval:
			drop_timer = 0.0
			if get_ball_count() < max_balls:
				drop_ball()
	
	# Pulse light when ready to drop
	var ready_ratio = drop_timer / drop_interval
	if indicator_light:
		indicator_light.light_energy = 0.3 + ready_ratio * 0.7

func _cleanup_invalid_balls() -> void:
	var valid_balls: Array[Node3D] = []
	for ball in balls:
		if is_instance_valid(ball):
			valid_balls.append(ball)
	balls = valid_balls

func get_ball_count() -> int:
	_cleanup_invalid_balls()
	return balls.size()

func drop_ball() -> Node3D:
	"""Drop a single ball and return it"""
	var ball = _create_ball()
	
	# Position with spread
	var spawn_pos = global_position + Vector3(0, drop_height - 0.2, 0)
	spawn_pos.x += randf_range(-spawn_spread, spawn_spread)
	spawn_pos.z += randf_range(-spawn_spread, spawn_spread)
	ball.global_position = spawn_pos
	
	# Add to scene tree (parent to scene root for proper physics)
	get_tree().root.add_child(ball)
	balls.append(ball)
	
	# Apply initial velocity
	await get_tree().process_frame
	var rb = ball.get_node_or_null("RigidBody3D")
	if rb:
		rb.linear_velocity = initial_velocity + Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.5, 0),
			randf_range(-0.3, 0.3)
		)
	
	balls_dropped += 1
	emit_signal("ball_spawned", ball)
	print("[Dropper] Dropped ball #%d" % balls_dropped)
	
	return ball

func _create_ball() -> Node3D:
	"""Create a ball with physics"""
	var root = Node3D.new()
	root.name = "DroppedBall_%d" % balls_dropped
	
	# RigidBody for physics
	var rb = RigidBody3D.new()
	rb.name = "RigidBody3D"
	rb.mass = ball_mass
	rb.gravity_scale = 1.0
	rb.linear_damp = 0.1
	rb.angular_damp = 0.3
	
	# Physics material
	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = ball_bounce
	phys_mat.friction = 0.3
	rb.physics_material_override = phys_mat
	
	# Collision
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = ball_radius
	collision.shape = sphere_shape
	rb.add_child(collision)
	
	# Mesh
	var mesh = MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = ball_radius
	sphere_mesh.height = ball_radius * 2
	sphere_mesh.radial_segments = 24
	sphere_mesh.rings = 12
	mesh.mesh = sphere_mesh
	
	# Color
	var color = BALL_COLORS[color_index % BALL_COLORS.size()]
	color_index += 1
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission_strength
	mat.metallic = 0.1
	mat.roughness = 0.4
	mesh.material_override = mat
	
	rb.add_child(mesh)
	root.add_child(rb)
	
	# Store color for explosion effect
	root.set_meta("ball_color", color)
	
	return root

func remove_ball(ball: Node3D) -> void:
	"""Remove a ball from tracking"""
	var idx = balls.find(ball)
	if idx >= 0:
		balls.remove_at(idx)
	emit_signal("ball_destroyed", ball)

func clear_all() -> void:
	"""Remove all balls"""
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	balls.clear()
	print("[Dropper] Cleared all balls")

func set_auto_drop(enabled: bool) -> void:
	auto_drop = enabled
	drop_timer = 0.0

func force_drop() -> Node3D:
	"""Force an immediate drop regardless of timer"""
	drop_timer = 0.0
	return drop_ball()
