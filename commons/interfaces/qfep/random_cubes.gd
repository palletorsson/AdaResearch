# random_cubes.gd
# QFEP E(S) Term Visualization - Chaotic Cube Arrangement
# Represents high entropy: random positions, rotations, scales
# Visual metaphor for possibility space and freedom from pattern

extends Node3D

class_name QFEPRandomCubes

# @identity
# essence: for i in N: cube(random_pos, random_rot, random_size, random_color) + drift(random_velocity)
# desire: be surrounded by cubes that have forgotten how to form a grid — pure possibility space
# critical_parameter: drift_speed — at zero, chaos is frozen; above zero, entropy is visibly restless
# triggers: regenerate() re-rolls every position, velocity, and color; boundary bouncing prevents escape
# emerges: temporary alignments and clusters that the eye reads as structure — meaning projected onto noise
# needs: VR regenerate button [missing], drift speed control [missing]
# relationships: represents E(S) entropy term; contrasts ordered_grid (F term); paired with particle_chaos; feeds lambda spectrum
# truth: randomness is not the absence of information but the presence of all possible configurations simultaneously

## Number of cubes to spawn
@export var cube_count: int = 20

## Spawn radius
@export var spawn_radius: float = 1.0

## Cube size range
@export var size_min: float = 0.05
@export var size_max: float = 0.15

## Animation speed (0 = static)
@export var drift_speed: float = 0.1

## Color variation
@export var base_color: Color = Color(0.9, 0.3, 0.3, 0.8)  # Red - entropy color

# Internal
var _cubes: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _angular_velocities: Array[Vector3] = []
var _time: float = 0.0

func _ready() -> void:
	_spawn_cubes()

func _spawn_cubes() -> void:
	var cube_mesh = BoxMesh.new()
	
	for i in range(cube_count):
		var cube = MeshInstance3D.new()
		
		# Random size
		var size = randf_range(size_min, size_max)
		cube_mesh = BoxMesh.new()
		cube_mesh.size = Vector3(size, size, size)
		cube.mesh = cube_mesh
		
		# Random position within radius
		var pos = Vector3(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(0, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		cube.position = pos
		
		# Random rotation
		cube.rotation = Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		)
		
		# Random color variation
		var mat = StandardMaterial3D.new()
		var color_variation = base_color
		color_variation.h += randf_range(-0.1, 0.1)
		color_variation.s = clamp(color_variation.s + randf_range(-0.2, 0.2), 0.3, 1.0)
		mat.albedo_color = color_variation
		mat.emission_enabled = true
		mat.emission = color_variation
		mat.emission_energy_multiplier = 0.3
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cube.material_override = mat
		
		add_child(cube)
		_cubes.append(cube)
		
		# Random velocity for drift
		_velocities.append(Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized() * drift_speed)
		
		_angular_velocities.append(Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * 0.5)

func _process(delta: float) -> void:
	if drift_speed <= 0:
		return
	
	_time += delta
	
	for i in range(_cubes.size()):
		var cube = _cubes[i]
		
		# Drift movement
		cube.position += _velocities[i] * delta
		
		# Rotate
		cube.rotation += _angular_velocities[i] * delta
		
		# Bounce off boundaries
		if abs(cube.position.x) > spawn_radius:
			_velocities[i].x *= -1
		if cube.position.y < 0 or cube.position.y > spawn_radius:
			_velocities[i].y *= -1
		if abs(cube.position.z) > spawn_radius:
			_velocities[i].z *= -1

## Regenerate with new random arrangement
func regenerate() -> void:
	for cube in _cubes:
		cube.queue_free()
	_cubes.clear()
	_velocities.clear()
	_angular_velocities.clear()
	_spawn_cubes()
