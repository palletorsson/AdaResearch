# HazardousMaterial.gd
# Toxic/radioactive materials that continuously damage the player's health
extends Area3D
class_name HazardousMaterial

# Damage settings
@export var damage_per_second: float = 5.0
@export var initial_damage: float = 10.0  # Burst damage when first entering
@export var damage_interval: float = 0.5  # How often to apply damage
@export var lingering_damage_duration: float = 3.0  # Damage continues after leaving
@export var lingering_damage_per_second: float = 2.0

# Material type
enum MaterialType {
	TOXIC_GAS,
	RADIOACTIVE,
	ACID,
	LAVA,
	ELECTRICITY,
	FREEZING
}

@export var material_type: MaterialType = MaterialType.TOXIC_GAS
@export var hazard_radius: float = 3.0
@export var intensity: float = 1.0  # Multiplier for all damage

# Visual effects
@export var particle_count: int = 200
@export var show_warning_signs: bool = true
@export var danger_zone_color: Color = Color(1, 0, 0, 0.3)
@export var particle_color: Color = Color(0, 1, 0, 0.8)

# Audio
@export var ambient_sound: AudioStream
@export var enter_sound: AudioStream
@export var damage_sound: AudioStream
@export var warning_sound: AudioStream

# Environmental effects
@export var reduces_visibility: bool = false
@export var slows_movement: bool = false
@export var movement_speed_multiplier: float = 0.5

# Internal state
var players_in_hazard: Dictionary = {}  # Player -> exposure data
var damage_timer: float = 0.0
var particles: GPUParticles3D
var warning_indicator: MeshInstance3D
var ambient_audio: AudioStreamPlayer3D
var damage_audio: AudioStreamPlayer3D
var collision_shape: CollisionShape3D

# Exposure tracking
class ExposureData:
	var exposure_time: float = 0.0
	var last_damage_time: float = 0.0
	var initial_damage_dealt: bool = false
	var lingering_timer: float = 0.0
	var is_in_area: bool = true
	
	func _init():
		exposure_time = 0.0
		last_damage_time = 0.0
		initial_damage_dealt = false
		lingering_timer = 0.0
		is_in_area = true

signal player_entered_hazard(player, material_type)
signal player_damaged(player, damage_amount, material_type)
signal player_left_hazard(player, total_exposure_time)

func _ready():
	# Setup collision detection
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Setup collision shape
	_setup_collision_shape()
	
	# Create visual effects
	_create_visual_effects()
	
	# Setup audio
	_setup_audio()
	
	# Set collision layers
	collision_layer = 0    # Don't collide with anything
	collision_mask = 2     # Detect player layer
	
	print("HazardousMaterial: Initialized - Type: ", MaterialType.keys()[material_type])

func _setup_collision_shape():
	collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = hazard_radius
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

func _create_visual_effects():
	# Create danger zone indicator
	if show_warning_signs:
		_create_warning_indicator()
	
	# Create particle effects based on material type
	_create_particles()

func _create_warning_indicator():
	warning_indicator = MeshInstance3D.new()
	
	# Create warning zone mesh (flat cylinder)
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = hazard_radius
	cylinder_mesh.bottom_radius = hazard_radius
	cylinder_mesh.height = 0.1
	warning_indicator.mesh = cylinder_mesh
	
	# Create warning material
	var warning_material = StandardMaterial3D.new()
	warning_material.albedo_color = danger_zone_color
	warning_material.emission_enabled = true
	warning_material.emission = danger_zone_color * 0.5
	warning_material.emission_energy = 1.0
	warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	warning_material.no_depth_test = true
	warning_indicator.material_override = warning_material
	
	warning_indicator.position.y = -0.05  # Slightly below ground
	add_child(warning_indicator)

func _create_particles():
	particles = GPUParticles3D.new()
	particles.emitting = true
	particles.amount = particle_count
	particles.lifetime = 3.0
	
	# Configure particle material based on hazard type
	var particle_material = ParticleProcessMaterial.new()
	_configure_particles_for_material_type(particle_material)
	
	particles.process_material = particle_material
	particles.draw_pass_1 = QuadMesh.new()
	add_child(particles)

func _configure_particles_for_material_type(material: ParticleProcessMaterial):
	match material_type:
		MaterialType.TOXIC_GAS:
			_setup_gas_particles(material)
		MaterialType.RADIOACTIVE:
			_setup_radioactive_particles(material)
		MaterialType.ACID:
			_setup_acid_particles(material)
		MaterialType.LAVA:
			_setup_lava_particles(material)
		MaterialType.ELECTRICITY:
			_setup_electric_particles(material)
		MaterialType.FREEZING:
			_setup_freezing_particles(material)

func _setup_gas_particles(material: ParticleProcessMaterial):
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 2.0
	material.gravity = Vector3(0, -0.5, 0)
	material.scale_min = 0.3
	material.scale_max = 1.2
	
	# Green toxic gas gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0, 1, 0, 0.8))  # Bright green
	gradient.add_point(0.5, Color(0, 0.8, 0, 0.6))  # Medium green
	gradient.add_point(1.0, Color(0, 0.3, 0, 0.0))  # Dark green, transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

func _setup_radioactive_particles(material: ParticleProcessMaterial):
	material.direction = Vector3(0, 1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0
	material.gravity = Vector3(0, 0, 0)  # Floating particles
	material.scale_min = 0.1
	material.scale_max = 0.4
	
	# Yellow radioactive gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0, 1.0))  # Bright yellow
	gradient.add_point(0.5, Color(1, 0.5, 0, 0.8))  # Orange
	gradient.add_point(1.0, Color(0.5, 0, 0, 0.0))  # Dark red, transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

func _setup_acid_particles(material: ParticleProcessMaterial):
	material.direction = Vector3(0, -1, 0)
	material.spread = 20.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, -9.8, 0)
	material.scale_min = 0.2
	material.scale_max = 0.6
	
	# Acid green gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.5, 1, 0, 1.0))  # Acid green
	gradient.add_point(0.7, Color(0, 0.8, 0.2, 0.7))
	gradient.add_point(1.0, Color(0, 0.3, 0.1, 0.0))
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

func _setup_lava_particles(material: ParticleProcessMaterial):
	material.direction = Vector3(0, 1, 0)
	material.spread = 35.0
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 8.0
	material.gravity = Vector3(0, -5.0, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8
	
	# Fire/lava gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0.5, 1.0))  # White hot
	gradient.add_point(0.3, Color(1, 0.5, 0, 0.9))  # Orange
	gradient.add_point(0.7, Color(1, 0, 0, 0.7))    # Red
	gradient.add_point(1.0, Color(0.3, 0, 0, 0.0))  # Dark red, transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

func _setup_electric_particles(material: ParticleProcessMaterial):
	material.direction = Vector3(0, 0, 1)
	material.spread = 60.0
	material.initial_velocity_min = 4.0
	material.initial_velocity_max = 10.0
	material.gravity = Vector3(0, 0, 0)  # No gravity for electricity
	material.scale_min = 0.1
	material.scale_max = 0.3
	
	# Electric blue gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1.0))    # White spark
	gradient.add_point(0.3, Color(0, 0.8, 1, 0.9))  # Cyan
	gradient.add_point(0.7, Color(0, 0.3, 1, 0.6))  # Blue
	gradient.add_point(1.0, Color(0, 0, 0.5, 0.0))  # Dark blue, transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

func _setup_freezing_particles(material: ParticleProcessMaterial):
	material.direction = Vector3(0, -1, 0)
	material.spread = 25.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 2.0
	material.gravity = Vector3(0, -2.0, 0)  # Slow falling like snow
	material.scale_min = 0.2
	material.scale_max = 0.5
	
	# Ice/frost gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.9, 1, 1.0))  # Light blue
	gradient.add_point(0.5, Color(0.6, 0.8, 1, 0.8))  # Medium blue
	gradient.add_point(1.0, Color(0.3, 0.5, 0.8, 0.0))  # Dark blue, transparent
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

func _setup_audio():
	# Ambient sound
	ambient_audio = AudioStreamPlayer3D.new()
	if ambient_sound:
		ambient_audio.stream = ambient_sound
		ambient_audio.autoplay = true
		ambient_audio.playing = true
	add_child(ambient_audio)
	
	# Damage sound
	damage_audio = AudioStreamPlayer3D.new()
	add_child(damage_audio)

func _process(delta):
	damage_timer += delta
	
	# Update particles animation
	_animate_particles(delta)
	
	# Process players in hazard
	_update_players_in_hazard(delta)
	
	# Apply damage at intervals
	if damage_timer >= damage_interval:
		_apply_damage_to_players()
		damage_timer = 0.0

func _animate_particles(delta):
	if not particles:
		return
	
	# Animate warning indicator
	if warning_indicator:
		var pulse = 0.5 + 0.5 * sin(Time.get_time_dict_from_system().second * 3.0)
		var material = warning_indicator.get_surface_override_material(0)
		if material:
			material.emission_energy = 0.5 + pulse * 1.0

func _update_players_in_hazard(delta):
	var players_to_remove = []
	
	for player in players_in_hazard.keys():
		var exposure_data = players_in_hazard[player]
		
		if exposure_data.is_in_area:
			exposure_data.exposure_time += delta
		else:
			# Handle lingering damage
			exposure_data.lingering_timer -= delta
			if exposure_data.lingering_timer <= 0:
				players_to_remove.append(player)
	
	# Remove players with expired lingering effects
	for player in players_to_remove:
		players_in_hazard.erase(player)

func _apply_damage_to_players():
	for player in players_in_hazard.keys():
		var exposure_data = players_in_hazard[player]
		
		if exposure_data.is_in_area:
			# Apply regular damage
			_damage_player(player, damage_per_second * damage_interval * intensity)
		else:
			# Apply lingering damage
			if exposure_data.lingering_timer > 0:
				_damage_player(player, lingering_damage_per_second * damage_interval * intensity)

func _on_body_entered(body):
	if _is_player(body):
		print("Player entered hazardous material: ", body.name, " (", MaterialType.keys()[material_type], ")")
		
		# Create exposure data
		var exposure_data = ExposureData.new()
		players_in_hazard[body] = exposure_data
		
		# Apply initial damage
		if initial_damage > 0:
			_damage_player(body, initial_damage * intensity)
			exposure_data.initial_damage_dealt = true
		
		# Apply movement effects
		if slows_movement:
			_apply_movement_effect(body, true)
		
		# Play enter sound
		if enter_sound:
			damage_audio.stream = enter_sound
			damage_audio.play()
		
		# Play warning sound
		if warning_sound and not ambient_audio.playing:
			damage_audio.stream = warning_sound
			damage_audio.play()
		
		emit_signal("player_entered_hazard", body, material_type)

func _on_body_exited(body):
	if _is_player(body) and body in players_in_hazard:
		var exposure_data = players_in_hazard[body]
		exposure_data.is_in_area = false
		exposure_data.lingering_timer = lingering_damage_duration
		
		print("Player left hazardous material: ", body.name, " (exposed for ", exposure_data.exposure_time, "s)")
		
		# Remove movement effects
		if slows_movement:
			_apply_movement_effect(body, false)
		
		emit_signal("player_left_hazard", body, exposure_data.exposure_time)

func _damage_player(player, damage_amount: float):
	# Try different damage methods
	if player.has_method("take_damage"):
		player.take_damage(damage_amount)
	elif player.has_method("apply_health_damage"):
		player.apply_health_damage(damage_amount)
	elif player.has_method("damage_player"):
		player.damage_player(damage_amount)
	elif player.has_signal("health_changed"):
		player.emit_signal("health_changed", -damage_amount)
	
	# Play damage sound
	if damage_sound:
		damage_audio.stream = damage_sound
		damage_audio.play()
	
	# Create damage effect
	_create_damage_effect(player.global_position)
	
	emit_signal("player_damaged", player, damage_amount, material_type)

func _create_damage_effect(position: Vector3):
	# Create damage indicator particles
	var damage_particles = GPUParticles3D.new()
	damage_particles.global_position = position
	damage_particles.emitting = true
	damage_particles.amount = 20
	damage_particles.lifetime = 1.0
	damage_particles.one_shot = true
	
	var damage_material = ParticleProcessMaterial.new()
	damage_material.direction = Vector3(0, 1, 0)
	damage_material.spread = 45.0
	damage_material.initial_velocity_min = 2.0
	damage_material.initial_velocity_max = 5.0
	damage_material.gravity = Vector3(0, -3.0, 0)
	damage_material.scale_min = 0.1
	damage_material.scale_max = 0.3
	
	# Damage color based on material type
	var damage_color = _get_damage_color()
	var damage_gradient = Gradient.new()
	damage_gradient.add_point(0.0, damage_color)
	damage_gradient.add_point(1.0, Color(damage_color.r, damage_color.g, damage_color.b, 0))
	
	var damage_texture = GradientTexture1D.new()
	damage_texture.gradient = damage_gradient
	damage_material.color_ramp = damage_texture
	
	damage_particles.process_material = damage_material
	damage_particles.draw_pass_1 = QuadMesh.new()
	add_child(damage_particles)
	
	# Clean up
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 2.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(damage_particles.queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _get_damage_color() -> Color:
	match material_type:
		MaterialType.TOXIC_GAS:
			return Color.GREEN
		MaterialType.RADIOACTIVE:
			return Color.YELLOW
		MaterialType.ACID:
			return Color(0.5, 1, 0, 1)  # Acid green
		MaterialType.LAVA:
			return Color.RED
		MaterialType.ELECTRICITY:
			return Color.CYAN
		MaterialType.FREEZING:
			return Color(0.7, 0.9, 1, 1)  # Light blue
		_:
			return Color.WHITE

func _apply_movement_effect(player, apply: bool):
	if player.has_method("set_movement_speed_multiplier"):
		var multiplier = movement_speed_multiplier if apply else 1.0
		player.set_movement_speed_multiplier(multiplier)
	elif player.has_property("movement_speed_multiplier"):
		player.movement_speed_multiplier = movement_speed_multiplier if apply else 1.0

func _is_player(body) -> bool:
	return ("player" in body.name.to_lower() or 
			body.is_in_group("player") or
			body.has_method("take_damage"))

# Public API
func set_material_type(new_type: MaterialType):
	material_type = new_type
	if particles:
		_configure_particles_for_material_type(particles.process_material)

func set_damage_rate(new_damage_per_second: float):
	damage_per_second = new_damage_per_second

func set_intensity(new_intensity: float):
	intensity = new_intensity

func activate_hazard():
	set_process(true)
	if particles:
		particles.emitting = true
	if ambient_audio and ambient_sound:
		ambient_audio.playing = true

func deactivate_hazard():
	set_process(false)
	if particles:
		particles.emitting = false
	if ambient_audio:
		ambient_audio.playing = false
	
	# Remove all players and clear effects
	for player in players_in_hazard.keys():
		if slows_movement:
			_apply_movement_effect(player, false)
	players_in_hazard.clear()

func get_players_in_hazard() -> Array:
	return players_in_hazard.keys()

func get_exposure_time(player) -> float:
	if player in players_in_hazard:
		return players_in_hazard[player].exposure_time
	return 0.0

func is_hazard_active() -> bool:
	return is_processing()
