
# ProjectileCube.gd - The cube projectiles that are shot at the player
extends RigidBody3D

@export var damage: int = 10
@export var lifetime: float = 10.0
@export var explosion_particles: bool = true
@export var my_knockback_force: float = 0.01

# Components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hit_area: Area3D = $HitArea
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var trail_particles: GPUParticles3D = $TrailParticles
@onready var hit_sound: AudioStreamPlayer3D = $HitSound

# State
var velocity: Vector3 = Vector3.ZERO
var spawner: Node3D
var has_hit_player: bool = false

# Signals
signal projectile_destroyed()
signal player_hit(damage: int, position: Vector3)

func _ready():
	_setup_projectile()
	_setup_collision()
	_setup_visuals()

func _setup_projectile():
	"""Initialize the projectile"""
	# Set physics properties
	mass = 1.0
	gravity_scale = 0.1  # Slight gravity for natural arc
	continuous_cd = true  # Better collision detection
	
	# Setup lifetime timer
	if not lifetime_timer:
		lifetime_timer = Timer.new()
		add_child(lifetime_timer)
	
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(_on_lifetime_expired)
	lifetime_timer.start()
	
	# Set collision layers
	collision_layer = 4  # Pickable Objects layer
	collision_mask = 1 + 1048576  # Static World + Player Body

func _setup_collision():
	"""Setup collision detection"""
	# Create collision shape if needed
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
		
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.5, 0.5, 0.5)
		collision_shape.shape = box_shape
	
	# Setup hit detection area
	if not hit_area:
		hit_area = Area3D.new()
		hit_area.name = "HitArea"
		add_child(hit_area)
		
		var area_collision = CollisionShape3D.new()
		hit_area.add_child(area_collision)
		
		var area_shape = BoxShape3D.new()
		area_shape.size = Vector3(0.6, 0.6, 0.6)  # Slightly larger than main collision
		area_collision.shape = area_shape
	
	# Set area detection
	hit_area.collision_mask = 1048576  # Player Body layer only
	
	# Connect signals properly - avoid duplicate connections
	if not hit_area.body_entered.is_connected(_on_hit_area_body_entered):
		hit_area.body_entered.connect(_on_hit_area_body_entered)
	
	# Connect RigidBody collision - check if signal exists
	if has_signal("body_entered") and not body_entered.is_connected(_on_body_collision):
		body_entered.connect(_on_body_collision)

func _setup_visuals():
	"""Create the visual representation"""
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
	
	# Create cube mesh
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.5, 0.5, 0.5)
	mesh_instance.mesh = cube_mesh
	
	# Create dangerous-looking material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.0)  # Bright red
	material.emission = Color(1.0, 0.5, 0.0)
	material.emission_energy = 1.5
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material
	
	# Add trail particles
	if not trail_particles:
		trail_particles = GPUParticles3D.new()
		trail_particles.name = "TrailParticles"
		add_child(trail_particles)
		
		var trail_material = ParticleProcessMaterial.new()
		trail_material.direction = Vector3(0, 0, 1)  # Behind the cube
		trail_material.initial_velocity_min = 1.0
		trail_material.initial_velocity_max = 3.0
		trail_material.gravity = Vector3.ZERO
		trail_material.scale_min = 0.05
		trail_material.scale_max = 0.15
		trail_particles.process_material = trail_material
		trail_particles.amount = 20
		trail_particles.emitting = true

func setup_projectile(direction: Vector3, speed: float, source_spawner: Node3D = null):
	"""Configure the projectile with direction and speed"""
	velocity = direction * speed
	spawner = source_spawner
	
	# Apply initial velocity
	linear_velocity = velocity
	
	# Face movement direction
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)
	
	print("ProjectileCube: Setup with velocity %s, speed %.1f" % [direction, speed])

func _integrate_forces(state):
	"""Apply continuous movement force"""
	if velocity != Vector3.ZERO:
		state.linear_velocity = velocity

func _on_hit_area_body_entered(body: Node3D):
	"""Handle hitting the player"""
	if has_hit_player:
		return
	
	# Check if it's the player
	if body.is_in_group("player") or body.name.contains("Player") or body.name.contains("XROrigin"):
		_hit_player(body)

func _on_body_collision(body: Node3D):
	"""Handle collision with environment"""
	if body.is_in_group("player"):
		_hit_player(body)
	else:
		# Hit environment - explode
		_explode_on_impact()

func _hit_player(player_body: Node3D):
	"""Handle successful hit on player"""
	if has_hit_player:
		return
	
	has_hit_player = true
	
	# Apply physical knockback force
	_apply_knockback_force(player_body)
	
	# Deal damage through GameManager
	if GameManager and GameManager.has_method("add_points"):
		GameManager.add_points(-damage)  # Negative points for getting hit
	
	# Play hit sound
	if hit_sound:
		hit_sound.play()
	
	# Emit signals
	player_hit.emit(damage, global_position)
	
	# Create hit effect
	_create_hit_effect()
	
	print("ProjectileCube: Hit player for %d damage with knockback!" % damage)
	
	# Destroy projectile
	call_deferred("_destroy_projectile")

func _apply_knockback_force(player_body: Node3D):
	"""Apply physical force to push the player"""
	var knockback_force = my_knockback_force  # Use the exported variable
	var max_knockback_velocity = 8.0  # Maximum velocity from knockback
	var knockback_direction = velocity.normalized()
	
	# Try different ways to apply force to player
	if player_body.has_method("apply_central_impulse"):
		# RigidBody player
		player_body.apply_central_impulse(knockback_direction * knockback_force)
		_limit_player_velocity(player_body, max_knockback_velocity)
		print("ProjectileCube: Applied RigidBody impulse")
	
	elif player_body.has_method("apply_impulse"):
		# CharacterBody3D or similar
		player_body.apply_impulse(knockback_direction * knockback_force)
		_limit_player_velocity(player_body, max_knockback_velocity)
		print("ProjectileCube: Applied impulse")
	
	elif "velocity" in player_body:
		# CharacterBody3D with velocity
		var current_velocity = player_body.velocity
		var new_velocity = current_velocity + (knockback_direction * knockback_force)
		
		# Clamp the knockback component
		var knockback_component = knockback_direction.dot(new_velocity) * knockback_direction
		if knockback_component.length() > max_knockback_velocity:
			knockback_component = knockback_component.normalized() * max_knockback_velocity
			new_velocity = current_velocity + knockback_component
		
		player_body.velocity = new_velocity
		_start_velocity_decay(player_body)
		print("ProjectileCube: Modified velocity with limits")
	
	else:
		# Find CharacterBody3D in player hierarchy
		var character_body = _find_character_body(player_body)
		if character_body and "velocity" in character_body:
			var current_velocity = character_body.velocity
			var new_velocity = current_velocity + (knockback_direction * knockback_force)
			
			# Clamp the knockback component
			var knockback_component = knockback_direction.dot(new_velocity) * knockback_direction
			if knockback_component.length() > max_knockback_velocity:
				knockback_component = knockback_component.normalized() * max_knockback_velocity
				new_velocity = current_velocity + knockback_component
			
			character_body.velocity = new_velocity
			_start_velocity_decay(character_body)
			print("ProjectileCube: Applied limited knockback to CharacterBody3D")
		else:
			print("ProjectileCube: Could not apply knockback - no compatible physics body found")

func _limit_player_velocity(player_body: Node3D, max_velocity: float):
	"""Limit the player's velocity to prevent excessive movement"""
	if "linear_velocity" in player_body:
		var current_velocity = player_body.linear_velocity
		if current_velocity.length() > max_velocity:
			player_body.linear_velocity = current_velocity.normalized() * max_velocity

func _start_velocity_decay(player_body: Node3D):
	"""Start a decay process to gradually reduce knockback velocity"""
	var decay_timer = Timer.new()
	get_tree().current_scene.add_child(decay_timer)
	decay_timer.wait_time = 0.1  # Update every 0.1 seconds
	decay_timer.timeout.connect(_decay_velocity.bind(player_body, decay_timer, 0))
	decay_timer.start()

func _decay_velocity(player_body: Node3D, timer: Timer, iterations: int):
	"""Gradually reduce the player's velocity from knockback"""
	if not is_instance_valid(player_body) or iterations > 20:  # Stop after 2 seconds
		timer.queue_free()
		return
	
	if "velocity" in player_body:
		var current_velocity = player_body.velocity
		# Reduce velocity by 10% each iteration (exponential decay)
		var decay_factor = 0.9
		player_body.velocity = current_velocity * decay_factor
		
		# Stop decay when velocity is very low
		if current_velocity.length() < 0.5:
			timer.queue_free()
			return
	
	# Continue decay
	timer.timeout.connect(_decay_velocity.bind(player_body, timer, iterations + 1))
	timer.start()

func _find_character_body(node: Node3D) -> Node3D:
	"""Find CharacterBody3D in player hierarchy"""
	# Check if node itself is CharacterBody3D
	if node is CharacterBody3D:
		return node
	
	# Search children
	for child in node.get_children():
		if child is CharacterBody3D:
			return child
		elif child is Node3D:
			var result = _find_character_body(child)
			if result:
				return result
	
	return null

func _explode_on_impact():
	"""Create explosion effect when hitting environment"""
	if explosion_particles:
		_create_explosion_effect()
	
	print("ProjectileCube: Exploded on impact")
	call_deferred("_destroy_projectile")

func _create_hit_effect():
	"""Create visual effect when hitting player"""
	var hit_particles = GPUParticles3D.new()
	get_parent().add_child(hit_particles)
	hit_particles.global_position = global_position
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 5.0
	particle_material.initial_velocity_max = 10.0
	particle_material.gravity = Vector3(0, -9.8, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	hit_particles.process_material = particle_material
	hit_particles.amount = 30
	hit_particles.emitting = true
	
	# Auto-cleanup
	var cleanup_timer = Timer.new()
	hit_particles.add_child(cleanup_timer)
	cleanup_timer.wait_time = 2.0
	cleanup_timer.timeout.connect(hit_particles.queue_free)
	cleanup_timer.start()

func _create_explosion_effect():
	"""Create explosion effect for environment hits"""
	var explosion_particles = GPUParticles3D.new()
	get_parent().add_child(explosion_particles)
	explosion_particles.global_position = global_position
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 3.0
	particle_material.initial_velocity_max = 8.0
	particle_material.gravity = Vector3(0, -9.8, 0)
	particle_material.scale_min = 0.05
	particle_material.scale_max = 0.2
	explosion_particles.process_material = particle_material
	explosion_particles.amount = 50
	explosion_particles.emitting = true
	
	# Auto-cleanup
	var cleanup_timer = Timer.new()
	explosion_particles.add_child(cleanup_timer)
	cleanup_timer.wait_time = 3.0
	cleanup_timer.timeout.connect(explosion_particles.queue_free)
	cleanup_timer.start()

func _on_lifetime_expired():
	"""Handle projectile lifetime expiration"""
	print("ProjectileCube: Lifetime expired")
	_destroy_projectile()

func _destroy_projectile():
	"""Clean up and remove the projectile"""
	projectile_destroyed.emit()
	queue_free()

# Public methods
func set_damage(new_damage: int):
	"""Change the damage this projectile deals"""
	damage = new_damage

func set_lifetime(new_lifetime: float):
	"""Change how long the projectile lasts"""
	lifetime = new_lifetime
	if lifetime_timer:
		lifetime_timer.wait_time = lifetime
