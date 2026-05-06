# ordered_grid.gd
# QFEP F Term Visualization - Perfectly Ordered Grid
# Represents λ=0: pure order, perfect pattern, no entropy
# Visual metaphor for crystalline structure, predictability, rigidity

extends Node3D

class_name QFEPOrderedGrid

# @identity
# essence: grid(x,y,z) * spacing + synchronized_breathe(sin(t)) -> perfect lattice
# desire: stand inside pure order — every cube in its place, breathing as one
# critical_parameter: spacing — the regularity that makes the grid legible as a crystal
# triggers: breathe_enabled creates synchronized vertical oscillation; add_disorder() breaks the pattern
# emerges: the uncanny valley of perfect order — too regular to feel alive, yet it breathes
# needs: VR disorder control [missing], touch-to-displace [missing]
# relationships: represents F term (free energy = pure order); contrasts random_cubes (E term) and complexity_pattern (edge); depends on grid concept
# truth: at lambda=0, prediction error is zero — the crystal has no surprises, no freedom, and no life

## Grid dimensions
@export var grid_x: int = 4
@export var grid_y: int = 2
@export var grid_z: int = 4

## Cube size
@export var cube_size: float = 0.08

## Spacing between cubes
@export var spacing: float = 0.12

## Order color (blue = F term)
@export var order_color: Color = Color(0.2, 0.4, 0.9, 0.9)

## Subtle breathing animation
@export var breathe_enabled: bool = true
@export var breathe_speed: float = 0.5
@export var breathe_amount: float = 0.02

# Internal
var _cubes: Array[MeshInstance3D] = []
var _base_positions: Array[Vector3] = []
var _time: float = 0.0

func _ready() -> void:
	_build_grid()

func _build_grid() -> void:
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	# Shared material for efficiency
	var mat = StandardMaterial3D.new()
	mat.albedo_color = order_color
	mat.emission_enabled = true
	mat.emission = order_color
	mat.emission_energy_multiplier = 0.4
	mat.metallic = 0.5
	mat.roughness = 0.3
	
	# Calculate offset to center the grid
	var offset = Vector3(
		-(grid_x - 1) * spacing / 2.0,
		0,
		-(grid_z - 1) * spacing / 2.0
	)
	
	for x in range(grid_x):
		for y in range(grid_y):
			for z in range(grid_z):
				var cube = MeshInstance3D.new()
				cube.mesh = cube_mesh
				cube.material_override = mat
				
				var pos = Vector3(
					x * spacing,
					y * spacing,
					z * spacing
				) + offset
				
				cube.position = pos
				
				add_child(cube)
				_cubes.append(cube)
				_base_positions.append(pos)

func _process(delta: float) -> void:
	if not breathe_enabled:
		return
	
	_time += delta * breathe_speed
	
	# Subtle synchronized breathing - all cubes move together (order!)
	var breathe_offset = sin(_time * TAU) * breathe_amount
	
	for i in range(_cubes.size()):
		var cube = _cubes[i]
		var base_pos = _base_positions[i]
		cube.position.y = base_pos.y + breathe_offset

## Introduce disorder (for transitions)
func add_disorder(amount: float) -> void:
	for i in range(_cubes.size()):
		var cube = _cubes[i]
		var base_pos = _base_positions[i]
		var noise = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * amount * spacing * 0.5
		cube.position = base_pos + noise
		cube.rotation = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * amount * 0.5

## Reset to perfect order
func reset_order() -> void:
	for i in range(_cubes.size()):
		_cubes[i].position = _base_positions[i]
		_cubes[i].rotation = Vector3.ZERO
