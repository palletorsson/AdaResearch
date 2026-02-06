extends Node3D

# Ball Dropper - Drops colorful balls one at a time, reuses them
# Works with LaserTurret for targeting demo

signal ball_spawned(ball: Node3D)
signal ball_destroyed(ball: Node3D)

@export_category("Dropper Settings")
@export var drop_interval_min: float = 0.8
@export var drop_interval_max: float = 1.5
@export var auto_drop: bool = true
@export var total_balls: int = 30
var max_balls: int:  # Alias for TurretTargeting compatibility
	get: return total_balls
	set(v): total_balls = v

@export_category("Ball Settings") 
@export var ball_radius: float = 0.1
@export var ball_mass: float = 0.5
@export var ball_bounce: float = 0.7
@export var emission_strength: float = 0.8
@export var ball_health: float = 80.0  # Health per ball (~1 sec at 80 dps)

@export_category("Spawn Position")
@export var drop_height: float = 0.0
@export var spawn_spread: float = 1.5  # Wider spread
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

# Ball pool
var ball_pool: Array[Node3D] = []
var active_balls: Array[Node3D] = []
var available_balls: Array[Node3D] = []

var drop_timer: float = 0.0
var next_drop_interval: float = 3.0
var color_index: int = 0
var balls_dropped: int = 0

# Visual elements
var dropper_mesh: MeshInstance3D
var indicator_light: OmniLight3D

func _ready() -> void:
	add_to_group("ball_dropper")
	_build_dropper_visual()
	_create_ball_pool()
	_set_next_interval()
	
	# Start with first drop soon
	if auto_drop:
		drop_timer = next_drop_interval - 0.5

func _build_dropper_visual() -> void:
	# Dropper housing
	dropper_mesh = MeshInstance3D.new()
	dropper_mesh.name = "DropperMesh"
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.15, 0.3)
	dropper_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.52, 0.55)
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

func _create_ball_pool() -> void:
	"""Pre-create all balls"""
	for i in range(total_balls):
		var ball = _create_ball(i)
		ball_pool.append(ball)
		available_balls.append(ball)
		# Add to scene but hide
		get_tree().root.add_child(ball)
		_hide_ball(ball)

func _create_ball(index: int) -> Node3D:
	"""Create a ball with physics"""
	var root = Node3D.new()
	root.name = "PoolBall_%d" % index
	
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
	
	# Initial material (will be updated on spawn)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = BALL_COLORS[index % BALL_COLORS.size()]
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = emission_strength
	mat.metallic = 0.1
	mat.roughness = 0.4
	mesh.material_override = mat
	
	rb.add_child(mesh)
	root.add_child(rb)
	
	return root

func _hide_ball(ball: Node3D) -> void:
	"""Hide and disable a ball"""
	ball.visible = false
	var rb = ball.get_node_or_null("RigidBody3D")
	if rb:
		rb.freeze = true
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO

func _show_ball(ball: Node3D) -> void:
	"""Show and enable a ball"""
	ball.visible = true
	var rb = ball.get_node_or_null("RigidBody3D")
	if rb:
		# Unfreeze deferred so position change takes effect first
		rb.set_deferred("freeze", false)

func _set_next_interval() -> void:
	"""Randomize next drop interval"""
	next_drop_interval = randf_range(drop_interval_min, drop_interval_max)

func _process(delta: float) -> void:
	# Auto drop logic
	if auto_drop:
		drop_timer += delta
		if drop_timer >= next_drop_interval:
			drop_timer = 0.0
			_set_next_interval()
			drop_ball()
	
	# Pulse light when ready to drop
	var ready_ratio = drop_timer / next_drop_interval
	if indicator_light:
		indicator_light.light_energy = 0.3 + ready_ratio * 0.7

func get_ball_count() -> int:
	"""Return number of active balls"""
	return active_balls.size()

func drop_ball() -> Node3D:
	"""Drop a ball from the pool"""
	var ball: Node3D = null
	
	if available_balls.size() > 0:
		# Reuse from pool
		ball = available_balls.pop_back()
	else:
		# All balls in use, recycle oldest active
		if active_balls.size() > 0:
			ball = active_balls.pop_front()
			# Must freeze before repositioning - active RigidBody ignores position changes
			_hide_ball(ball)
	
	if ball == null:
		return null
	
	# New color
	var color = BALL_COLORS[color_index % BALL_COLORS.size()]
	color_index += 1
	_set_ball_color(ball, color)
	ball.set_meta("ball_color", color)
	
	# Set health
	ball.set_meta("health", ball_health)
	ball.set_meta("max_health", ball_health)
	
	# Position with spread
	var spawn_pos = global_position + Vector3(0, drop_height - 0.2, 0)
	spawn_pos.x += randf_range(-spawn_spread, spawn_spread)
	spawn_pos.z += randf_range(-spawn_spread, spawn_spread)
	
	# Set position on both root and RigidBody to ensure physics sync
	ball.global_position = spawn_pos
	var rb = ball.get_node_or_null("RigidBody3D")
	if rb:
		rb.global_position = spawn_pos
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO
	
	# Show and enable physics
	_show_ball(ball)
	active_balls.append(ball)
	
	# Apply velocity
	var vel = initial_velocity + Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.5, 0),
		randf_range(-0.3, 0.3)
	)
	_apply_velocity_deferred.call_deferred(ball, vel)
	
	balls_dropped += 1
	emit_signal("ball_spawned", ball)
	
	return ball

func _apply_velocity_deferred(ball: Node3D, vel: Vector3) -> void:
	if not is_instance_valid(ball):
		return
	var rb = ball.get_node_or_null("RigidBody3D")
	if rb:
		rb.linear_velocity = vel

func _set_ball_color(ball: Node3D, color: Color) -> void:
	var rb = ball.get_node_or_null("RigidBody3D")
	if rb:
		var mesh = rb.get_node_or_null("MeshInstance3D")
		if mesh and mesh.material_override:
			var mat = mesh.material_override as StandardMaterial3D
			mat.albedo_color = color
			mat.emission = color
			mat.emission_energy_multiplier = emission_strength  # Reset burn effect

func remove_ball(ball: Node3D) -> void:
	"""Return a ball to the pool"""
	var idx = active_balls.find(ball)
	if idx >= 0:
		active_balls.remove_at(idx)
	
	_hide_ball(ball)
	
	if ball in ball_pool and ball not in available_balls:
		available_balls.append(ball)
	
	emit_signal("ball_destroyed", ball)

func clear_all() -> void:
	"""Return all balls to pool"""
	for ball in active_balls.duplicate():
		remove_ball(ball)
	active_balls.clear()

func set_auto_drop(enabled: bool) -> void:
	auto_drop = enabled
	drop_timer = 0.0

func force_drop() -> void:
	"""Force an immediate drop"""
	drop_timer = 0.0
	drop_ball()

# For turret compatibility
var balls: Array[Node3D]:
	get:
		return active_balls

# Static method to apply damage to a ball (call from turret)
static func apply_damage_to_ball(ball: Node3D, damage: float) -> bool:
	"""Apply damage to a ball, returns true if ball was destroyed"""
	if not is_instance_valid(ball):
		return false
	
	if not ball.has_meta("health"):
		ball.set_meta("health", 80.0)
		ball.set_meta("max_health", 80.0)
	
	var health = ball.get_meta("health") - damage
	ball.set_meta("health", health)
	
	return health <= 0
