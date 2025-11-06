# gravity_gun_test_scene.gd
# Test scene with 10 shootable spheres for gravity gun testing
extends Node3D

const SHOOTABLE_SPHERE = preload("res://algorithms/vectors/08_vector_throwing/destructibles/shootable_sphere.tscn")

@export_group("Sphere Spawning")
@export var spawn_count: int = 10
@export var spawn_pattern: String = "grid"  # "grid", "circle", "pyramid"
@export var spawn_spacing: float = 0.3
@export var spawn_height: float = 0.0

@export_group("Sphere Colors")
@export var randomize_colors: bool = true
@export var color_palette: Array[Color] = [
	Color(1.0, 0.3, 0.3),  # Red
	Color(1.0, 0.7, 0.3),  # Orange
	Color(1.0, 1.0, 0.3),  # Yellow
	Color(0.3, 1.0, 0.3),  # Green
	Color(0.3, 0.7, 1.0),  # Blue
	Color(0.7, 0.3, 1.0),  # Purple
]

var spawned_spheres: Array[RigidBody3D] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	spawn_spheres()

func spawn_spheres() -> void:
	"""Spawn spheres in selected pattern"""
	clear_spheres()

	match spawn_pattern:
		"grid":
			spawn_grid_pattern()
		"circle":
			spawn_circle_pattern()
		"pyramid":
			spawn_pyramid_pattern()
		_:
			spawn_grid_pattern()

	print("[GravityGunTest] Spawned ", spawned_spheres.size(), " spheres in ", spawn_pattern, " pattern")

func spawn_grid_pattern() -> void:
	"""Spawn spheres in a grid (2x5)"""
	var rows = 2
	var cols = 5

	for row in range(rows):
		for col in range(cols):
			var pos = Vector3(
				(col - cols / 2.0 + 0.5) * spawn_spacing,
				spawn_height + row * spawn_spacing,
				0
			)
			spawn_sphere_at(pos)

func spawn_circle_pattern() -> void:
	"""Spawn spheres in a circle"""
	for i in range(spawn_count):
		var angle = (float(i) / float(spawn_count)) * TAU
		var radius = spawn_spacing * 2.0
		var pos = Vector3(
			cos(angle) * radius,
			spawn_height,
			sin(angle) * radius
		)
		spawn_sphere_at(pos)

func spawn_pyramid_pattern() -> void:
	"""Spawn spheres in a pyramid (4+3+2+1 = 10)"""
	var levels = [
		{"count": 4, "radius": spawn_spacing * 1.5},
		{"count": 3, "radius": spawn_spacing * 1.0},
		{"count": 2, "radius": spawn_spacing * 0.5},
		{"count": 1, "radius": 0.0}
	]

	var sphere_index = 0
	for level_idx in range(levels.size()):
		var level = levels[level_idx]
		var count = level["count"]
		var radius = level["radius"]
		var height = spawn_height + level_idx * spawn_spacing * 0.8

		if count == 1:
			# Single sphere at top
			spawn_sphere_at(Vector3(0, height, 0))
		else:
			# Ring of spheres
			for i in range(count):
				var angle = (float(i) / float(count)) * TAU
				var pos = Vector3(
					cos(angle) * radius,
					height,
					sin(angle) * radius
				)
				spawn_sphere_at(pos)

		sphere_index += count
		if sphere_index >= spawn_count:
			break

func spawn_sphere_at(position: Vector3) -> void:
	"""Spawn a single sphere at the given position"""
	var sphere = SHOOTABLE_SPHERE.instantiate()
	sphere.position = position

	# Randomize color if enabled
	if randomize_colors and not color_palette.is_empty():
		var color = color_palette[rng.randi() % color_palette.size()]
		# Set color before adding to tree
		sphere.sphere_color = color

	add_child(sphere)
	spawned_spheres.append(sphere)

func clear_spheres() -> void:
	"""Remove all spawned spheres"""
	for sphere in spawned_spheres:
		if is_instance_valid(sphere):
			sphere.queue_free()
	spawned_spheres.clear()

func reset_spheres() -> void:
	"""Respawn all spheres"""
	spawn_spheres()

# Public API for testing
func set_pattern(pattern: String) -> void:
	"""Change spawn pattern and respawn"""
	spawn_pattern = pattern
	spawn_spheres()

func get_sphere_count() -> int:
	return spawned_spheres.size()
