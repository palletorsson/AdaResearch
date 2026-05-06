# CubeSpawner.gd - Main spawner that shoots cubes at the player
extends Node3D

@export var projectile_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var projectile_speed: float = 10.0
@export var spawn_range: float = 15.0
@export var target_prediction: float = 0.5  # How much to lead the target
@export var max_projectiles: int = 20
@export var auto_start: bool = true

enum SpawnMode {
	FORWARD,
	FALLING_FIELD
}

@export_group("Falling Field")
@export var spawn_mode: SpawnMode = SpawnMode.FORWARD
@export var field_size_meters: Vector2 = Vector2(8.0, 8.0)
@export var field_center_offset: Vector3 = Vector3.ZERO
@export var field_spawn_height: float = 7.0
@export var field_fall_speed_range: Vector2 = Vector2(1.8, 3.0)
@export var field_initial_horizontal_speed: float = 0.35
@export var field_horizontal_jitter: float = 0.25
@export var field_jitter_interval: float = 0.4
@export var field_vertical_speed_variation: float = 0.2

# Visual components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var spawn_timer: Timer = $SpawnTimer
@onready var warning_particles: GPUParticles3D = $WarningParticles
@onready var spawn_point: Marker3D = $SpawnPoint

# Audio
@onready var spawn_sound: AudioStreamPlayer3D = $SpawnSound
@onready var warning_sound: AudioStreamPlayer3D = $WarningSound

var player_node: Node3D
var active_projectiles: Array[Node3D] = []
var is_active: bool = false
var _rng := RandomNumberGenerator.new()

# Signals
signal projectile_spawned(projectile: Node3D)
signal player_hit(damage: int)
signal spawner_activated()
signal spawner_deactivated()

func _ready():
	_rng.randomize()
	_setup_spawner()
	_find_player()
	
	if auto_start:
		activate_spawner()

func _setup_spawner():
	"""Initialize the spawner components"""
	# Create projectile scene if not set
	if not projectile_scene:
		projectile_scene = preload("res://commons/primitives/cubes/projectile_cube.tscn")
	
	# Setup timer
	if not spawn_timer:
		spawn_timer = Timer.new()
		add_child(spawn_timer)
	
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_projectile)
	spawn_timer.autostart = false
	
	# Setup visual components
	if not mesh_instance:
		_create_spawner_visual()
	
	if not spawn_point:
		spawn_point = Marker3D.new()
		spawn_point.name = "SpawnPoint"
		add_child(spawn_point)
		spawn_point.position = Vector3(0, 0.5, 0)

func _create_spawner_visual():
	"""Create the visual representation of the spawner"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)
	
	# Create a menacing-looking spawner
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.2, 1.2, 1.2)
	mesh_instance.mesh = box_mesh
	
	# Create warning material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission = Color(1.0, 0.3, 0.0)
	material.emission_energy = 2.0
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_instance.material_override = material
	
	# Add warning particles
	warning_particles = GPUParticles3D.new()
	warning_particles.name = "WarningParticles"
	add_child(warning_particles)
	warning_particles.emitting = false
	
	# Setup particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.gravity = Vector3(0, -9.8, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	warning_particles.process_material = particle_material
	warning_particles.amount = 50

func _find_player():
	"""Find the player node in the scene"""
	# Try multiple common player node patterns
	var potential_players = [
		get_tree().get_first_node_in_group("player"),
		get_tree().current_scene.find_child("XROrigin3D", true, false),
		get_tree().current_scene.find_child("Player", true, false),
		get_tree().current_scene.find_child("PlayerBody", true, false)
	]
	
	for potential_player in potential_players:
		if potential_player:
			player_node = potential_player
			print("CubeSpawner: Found player - %s" % player_node.name)
			break
	
	if not player_node:
		print("CubeSpawner: WARNING - No player found!")

func activate_spawner():
	"""Start spawning projectiles"""
	if not is_active:
		is_active = true
		spawn_timer.start()
		_play_warning_effects()
		spawner_activated.emit()
		print("CubeSpawner: Activated - spawning every %.1f seconds" % spawn_interval)

func deactivate_spawner():
	"""Stop spawning projectiles"""
	if is_active:
		is_active = false
		spawn_timer.stop()
		_stop_warning_effects()
		spawner_deactivated.emit()
		print("CubeSpawner: Deactivated")

func _play_warning_effects():
	"""Play visual and audio warnings"""
	if warning_particles:
		warning_particles.emitting = true
	
	if warning_sound:
		warning_sound.play()
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "scale", Vector3(1.2, 1.2, 1.2), 0.5)
	tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.5)

func _stop_warning_effects():
	"""Stop visual effects"""
	if warning_particles:
		warning_particles.emitting = false
	
	# Stop pulsing
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

func _spawn_projectile():
	"""Spawn a projectile in the specified direction"""
	if not is_active or not projectile_scene:
		return
	
	# Clean up old projectiles
	_cleanup_projectiles()
	
	# Check projectile limit
	if active_projectiles.size() >= max_projectiles:
		print("CubeSpawner: Max projectiles reached (%d)" % max_projectiles)
		return
	
	# Create projectile
	var projectile = projectile_scene.instantiate()
	if not projectile:
		print("CubeSpawner: Failed to instantiate projectile")
		return
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)

	if spawn_mode == SpawnMode.FALLING_FIELD:
		_configure_falling_field_projectile(projectile)
	else:
		_configure_forward_projectile(projectile)
	
	# Track projectile
	active_projectiles.append(projectile)
	
	# Connect cleanup signal
	if projectile.has_signal("projectile_destroyed"):
		projectile.projectile_destroyed.connect(_on_projectile_destroyed.bind(projectile))
	
	# Play spawn sound
	if spawn_sound and spawn_sound.stream:
		spawn_sound.play()
	
	projectile_spawned.emit(projectile)
	print("CubeSpawner: Spawned projectile #%d (mode=%s)" % [active_projectiles.size(), "field" if spawn_mode == SpawnMode.FALLING_FIELD else "forward"])

func _configure_forward_projectile(projectile: Node3D) -> void:
	projectile.global_position = spawn_point.global_position

	# Set direction - shoot in Z direction (forward)
	var direction = Vector3(0, 0, -1)

	# Apply spawner's rotation to direction
	direction = global_transform.basis * direction

	if projectile.has_method("setup_projectile"):
		projectile.setup_projectile(direction, projectile_speed, self)
	elif "velocity" in projectile:
		projectile.velocity = direction * projectile_speed

func _configure_falling_field_projectile(projectile: Node3D) -> void:
	var half_w = max(field_size_meters.x * 0.5, 0.1)
	var half_d = max(field_size_meters.y * 0.5, 0.1)
	var field_origin = global_position + field_center_offset
	var spawn_pos = field_origin + Vector3(
		_rng.randf_range(-half_w, half_w),
		field_spawn_height,
		_rng.randf_range(-half_d, half_d)
	)
	projectile.global_position = spawn_pos

	var min_fall_speed = max(0.2, min(field_fall_speed_range.x, field_fall_speed_range.y))
	var max_fall_speed = max(min_fall_speed, max(field_fall_speed_range.x, field_fall_speed_range.y))
	var fall_speed = _rng.randf_range(min_fall_speed, max_fall_speed)
	var initial_velocity = Vector3(
		_rng.randf_range(-field_initial_horizontal_speed, field_initial_horizontal_speed),
		-fall_speed,
		_rng.randf_range(-field_initial_horizontal_speed, field_initial_horizontal_speed)
	)

	if projectile.has_method("set_falling_field_profile"):
		projectile.set_falling_field_profile(
			initial_velocity,
			field_horizontal_jitter,
			field_jitter_interval,
			field_vertical_speed_variation
		)
	elif projectile.has_method("setup_projectile"):
		var direction = initial_velocity.normalized() if initial_velocity.length() > 0.001 else Vector3.DOWN
		projectile.setup_projectile(direction, initial_velocity.length(), self)
	elif "velocity" in projectile:
		projectile.velocity = initial_velocity

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	if config_data.has("mode"):
		var mode_value = str(config_data["mode"]).strip_edges().to_lower()
		if mode_value in ["field", "falling", "falling_field", "rain", "rain_field"]:
			spawn_mode = SpawnMode.FALLING_FIELD
		else:
			spawn_mode = SpawnMode.FORWARD

	# Boolean shorthand support: #field
	if config_data.has("field"):
		spawn_mode = SpawnMode.FALLING_FIELD
		var field_value = config_data["field"]
		if typeof(field_value) != TYPE_BOOL:
			field_size_meters = _parse_field_size(str(field_value), field_size_meters)

	if config_data.has("spawn_interval"):
		set_spawn_interval(_to_float(config_data["spawn_interval"], spawn_interval))
	if config_data.has("max_projectiles"):
		max_projectiles = int(_to_float(config_data["max_projectiles"], float(max_projectiles)))
	if config_data.has("projectile_speed"):
		set_projectile_speed(_to_float(config_data["projectile_speed"], projectile_speed))

	if config_data.has("field_size"):
		field_size_meters = _parse_field_size(str(config_data["field_size"]), field_size_meters)
	if config_data.has("field_width"):
		field_size_meters.x = max(0.5, _to_float(config_data["field_width"], field_size_meters.x))
	if config_data.has("field_depth"):
		field_size_meters.y = max(0.5, _to_float(config_data["field_depth"], field_size_meters.y))
	if config_data.has("field_x"):
		field_size_meters.x = max(0.5, _to_float(config_data["field_x"], field_size_meters.x))
	if config_data.has("field_z"):
		field_size_meters.y = max(0.5, _to_float(config_data["field_z"], field_size_meters.y))
	if config_data.has("field_height"):
		field_spawn_height = max(0.5, _to_float(config_data["field_height"], field_spawn_height))

	if config_data.has("fall_min"):
		field_fall_speed_range.x = max(0.2, _to_float(config_data["fall_min"], field_fall_speed_range.x))
	if config_data.has("fall_max"):
		field_fall_speed_range.y = max(0.2, _to_float(config_data["fall_max"], field_fall_speed_range.y))

	if config_data.has("drift"):
		field_initial_horizontal_speed = max(0.0, _to_float(config_data["drift"], field_initial_horizontal_speed))
	if config_data.has("jitter"):
		field_horizontal_jitter = max(0.0, _to_float(config_data["jitter"], field_horizontal_jitter))
	if config_data.has("jitter_interval"):
		field_jitter_interval = max(0.05, _to_float(config_data["jitter_interval"], field_jitter_interval))
	if config_data.has("vertical_variation"):
		field_vertical_speed_variation = max(0.0, _to_float(config_data["vertical_variation"], field_vertical_speed_variation))

func _to_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text = str(value).strip_edges()
	return float(text) if text.is_valid_float() else fallback

func _parse_field_size(value: String, fallback: Vector2) -> Vector2:
	var normalized = value.strip_edges().to_lower()
	normalized = normalized.replace("x", " ")
	normalized = normalized.replace(",", " ")
	normalized = normalized.replace(";", " ")
	var parts = normalized.split(" ", false)
	if parts.size() >= 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
		return Vector2(max(0.5, float(parts[0])), max(0.5, float(parts[1])))
	if parts.size() == 1 and parts[0].is_valid_float():
		var s = max(0.5, float(parts[0]))
		return Vector2(s, s)
	return fallback

func _get_predicted_player_position() -> Vector3:
	"""Calculate where the player will be when projectile arrives"""
	if not player_node:
		return Vector3.ZERO
	
	var player_position = player_node.global_position
	
	# Add some height to target the player's center
	player_position.y += 1.0
	
	# Try to predict player movement
	if "velocity" in player_node and target_prediction > 0:
		var player_velocity = player_node.velocity
		var distance = global_position.distance_to(player_position)
		var travel_time = distance / projectile_speed
		var predicted_offset = player_velocity * travel_time * target_prediction
		player_position += predicted_offset
	
	return player_position

func _cleanup_projectiles():
	"""Remove null references from projectile array"""
	active_projectiles = active_projectiles.filter(func(p): return is_instance_valid(p))

func _on_projectile_destroyed(projectile: Node3D):
	"""Handle projectile destruction"""
	var index = active_projectiles.find(projectile)
	if index >= 0:
		active_projectiles.remove_at(index)

# Public interface methods
func set_spawn_interval(interval: float):
	"""Change how often projectiles spawn"""
	spawn_interval = interval
	spawn_timer.wait_time = interval
	print("CubeSpawner: Spawn interval set to %.1f seconds" % interval)

func set_projectile_speed(speed: float):
	"""Change projectile speed"""
	projectile_speed = speed
	print("CubeSpawner: Projectile speed set to %.1f" % speed)

func clear_all_projectiles():
	"""Remove all active projectiles"""
	for projectile in active_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	active_projectiles.clear()
	print("CubeSpawner: Cleared all projectiles")

# Debug methods
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_P:  # P to toggle spawner
			if is_active:
				deactivate_spawner()
			else:
				activate_spawner()
		elif event.keycode == KEY_O:  # O to spawn single projectile
			_spawn_projectile()
		elif event.keycode == KEY_C:  # C to clear projectiles
			clear_all_projectiles()
