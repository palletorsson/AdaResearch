# FireballProjectile.gd
# Dangerous fireball projectile that decreases player health on hit
extends RigidBody3D
class_name FireballProjectile

# Visual and physics properties
@export var speed: float = 15.0
@export var damage: float = 25.0
@export var lifetime: float = 8.0
@export var fire_particle_count: int = 100
@export var explosion_radius: float = 2.0

# Sound effects
@export var fire_sound: AudioStream
@export var explosion_sound: AudioStream

# Internal tracking
var time_alive: float = 0.0
var has_exploded: bool = false
var fire_particles: GPUParticles3D
var explosion_particles: GPUParticles3D
var audio_player: AudioStreamPlayer3D
var explosion_audio: AudioStreamPlayer3D

signal fireball_hit(target, damage_amount)
signal fireball_exploded(position)

func _ready():
	# Setup collision detection
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_body_entered)
	
	# Create fireball visual
	_create_fireball_visual()
	
	# Setup audio
	_setup_audio()
	
	# Set initial velocity
	var direction = -global_transform.basis.z  # Forward direction
	linear_velocity = direction * speed
	
	# Setup collision layers
	collision_layer = 16  # Hazard layer
	collision_mask = 1 | 2  # World and player layers
	
	print("Fireball launched with speed: ", speed)

func _create_fireball_visual():
	# Create fireball mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	sphere_mesh.height = 0.6
	mesh_instance.mesh = sphere_mesh
	
	# Create glowing fire material
	var fire_material = StandardMaterial3D.new()
	fire_material.albedo_color = Color(1.0, 0.4, 0.0, 1.0)  # Orange
	fire_material.emission_enabled = true
	fire_material.emission = Color(1.0, 0.2, 0.0, 1.0)
	fire_material.emission_energy = 3.0
	fire_material.metallic = 0.0
	fire_material.roughness = 0.8
	mesh_instance.material_override = fire_material
	add_child(mesh_instance)
	
	# Create fire particles
	fire_particles = GPUParticles3D.new()
	fire_particles.emitting = true
	fire_particles.amount = fire_particle_count
	fire_particles.lifetime = 1.0
	
	# Configure fire particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.gravity = Vector3(0, -2.0, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	
	# Fire colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 0.0, 1.0))  # Yellow
	gradient.add_point(0.5, Color(1.0, 0.3, 0.0, 0.8))  # Orange
	gradient.add_point(1.0, Color(0.3, 0.0, 0.0, 0.0))  # Dark red, transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particle_material.color_ramp = gradient_texture
	
	fire_particles.process_material = particle_material
	fire_particles.draw_pass_1 = QuadMesh.new()
	add_child(fire_particles)
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.4
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

func _setup_audio():
	# Fire sound (continuous)
	audio_player = AudioStreamPlayer3D.new()
	if fire_sound:
		audio_player.stream = fire_sound
	audio_player.playing = true
	audio_player.autoplay = true
	add_child(audio_player)
	
	# Explosion sound (for later)
	explosion_audio = AudioStreamPlayer3D.new()
	if explosion_sound:
		explosion_audio.stream = explosion_sound
	add_child(explosion_audio)

func _physics_process(delta):
	time_alive += delta
	
	# Auto-destroy after lifetime
	if time_alive >= lifetime and not has_exploded:
		_explode()
	
	# Add some wobble to the trajectory
	var wobble_force = Vector3(
		sin(time_alive * 10.0) * 0.5,
		cos(time_alive * 8.0) * 0.3,
		0
	)
	apply_central_force(wobble_force)

func _on_body_entered(body):
	if has_exploded:
		return
	
	print("Fireball hit: ", body.name)
	
	# Check if it's the player or a damageable object
	if body.has_method("take_damage"):
		body.take_damage(damage)
		emit_signal("fireball_hit", body, damage)
		print("Dealt ", damage, " damage to ", body.name)
	elif body.has_method("apply_health_damage"):
		body.apply_health_damage(damage)
		emit_signal("fireball_hit", body, damage)
		print("Applied health damage to ", body.name)
	elif "player" in body.name.to_lower() or body.is_in_group("player"):
		# Try multiple ways to deal damage to player
		if body.has_signal("health_changed"):
			body.emit_signal("health_changed", -damage)
		elif body.has_method("damage_player"):
			body.damage_player(damage)
		
		emit_signal("fireball_hit", body, damage)
		print("Hit player: ", body.name)
	
	_explode()

func _explode():
	if has_exploded:
		return
	
	has_exploded = true
	emit_signal("fireball_exploded", global_position)
	
	# Stop fire particles
	if fire_particles:
		fire_particles.emitting = false
	
	# Create explosion particles
	_create_explosion_effect()
	
	# Play explosion sound
	if explosion_audio and explosion_sound:
		explosion_audio.play()
	
	# Damage nearby objects
	_damage_nearby_objects()
	
	# Hide the mesh but keep particles
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = false
	
	# Clean up after explosion animation
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 3.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _create_explosion_effect():
	explosion_particles = GPUParticles3D.new()
	explosion_particles.emitting = true
	explosion_particles.amount = 200
	explosion_particles.lifetime = 2.0
	explosion_particles.one_shot = true
	
	# Configure explosion material
	var explosion_material = ParticleProcessMaterial.new()
	explosion_material.direction = Vector3(0, 1, 0)
	explosion_material.spread = 45.0
	explosion_material.initial_velocity_min = 8.0
	explosion_material.initial_velocity_max = 15.0
	explosion_material.gravity = Vector3(0, -5.0, 0)
	explosion_material.scale_min = 0.2
	explosion_material.scale_max = 0.8
	
	# Explosion colors
	var explosion_gradient = Gradient.new()
	explosion_gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 1.0))  # White
	explosion_gradient.add_point(0.3, Color(1.0, 0.8, 0.0, 0.9))  # Yellow
	explosion_gradient.add_point(0.7, Color(1.0, 0.2, 0.0, 0.5))  # Orange
	explosion_gradient.add_point(1.0, Color(0.2, 0.0, 0.0, 0.0))  # Dark, transparent
	
	var explosion_texture = GradientTexture1D.new()
	explosion_texture.gradient = explosion_gradient
	explosion_material.color_ramp = explosion_texture
	
	explosion_particles.process_material = explosion_material
	explosion_particles.draw_pass_1 = QuadMesh.new()
	add_child(explosion_particles)

func _damage_nearby_objects():
	# Find objects within explosion radius
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = explosion_radius
	query.shape = sphere_shape
	query.transform = global_transform
	query.collision_mask = 1 | 2  # World and player layers
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result["collider"]
		var distance = global_position.distance_to(body.global_position)
		var damage_multiplier = 1.0 - (distance / explosion_radius)
		var explosion_damage = damage * 0.5 * damage_multiplier  # Reduced explosion damage
		
		if body.has_method("take_damage"):
			body.take_damage(explosion_damage)
		elif body.has_method("apply_health_damage"):
			body.apply_health_damage(explosion_damage)

# Public methods for spawning/configuration
func set_target_direction(direction: Vector3):
	linear_velocity = direction.normalized() * speed

func set_damage(new_damage: float):
	damage = new_damage

func set_speed(new_speed: float):
	speed = new_speed
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * speed
