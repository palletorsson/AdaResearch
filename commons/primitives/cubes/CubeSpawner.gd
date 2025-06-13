# CubeSpawner.gd - Main spawner that shoots cubes at the player
extends Node3D

@export var projectile_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var projectile_speed: float = 10.0
@export var spawn_range: float = 15.0
@export var target_prediction: float = 0.5  # How much to lead the target
@export var max_projectiles: int = 20
@export var auto_start: bool = true

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

# Signals
signal projectile_spawned(projectile: Node3D)
signal player_hit(damage: int)
signal spawner_activated()
signal spawner_deactivated()

func _ready():
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
	projectile.global_position = spawn_point.global_position
	
	# Set direction - shoot in Z direction (forward)
	var direction = Vector3(0, 0, -1)  # Shoot forward in Z direction
	
	# Apply spawner's rotation to direction
	direction = global_transform.basis * direction
	
	# Configure projectile
	if projectile.has_method("setup_projectile"):
		projectile.setup_projectile(direction, projectile_speed, self)
	elif "velocity" in projectile:
		projectile.velocity = direction * projectile_speed
	
	# Track projectile
	active_projectiles.append(projectile)
	
	# Connect cleanup signal
	if projectile.has_signal("projectile_destroyed"):
		projectile.projectile_destroyed.connect(_on_projectile_destroyed.bind(projectile))
	
	# Play spawn sound
	if spawn_sound:
		spawn_sound.play()
	
	projectile_spawned.emit(projectile)
	print("CubeSpawner: Spawned projectile #%d in direction %s" % [active_projectiles.size(), direction])

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
