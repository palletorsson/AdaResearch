# complexity_pattern.gd
# QFEP Edge of Chaos Visualization - Emergent Complexity
# Self-organizing pattern at λ ≈ 0.4
# Where structure emerges from the dance of order and chaos

extends Node3D

class_name QFEPComplexityPattern

# @identity
# essence: Conway_GoL(B3/S23) on toroidal grid, density ~40% -> edge-of-chaos automaton
# desire: watch complexity self-organize — gliders, oscillators, structures nobody designed
# critical_parameter: initial density (~0.4) — the lambda value that places this automaton at the edge of chaos
# triggers: cells die out below threshold -> auto-reseed; each generation applies B3/S23 rules
# emerges: gliders, blinkers, and long-lived metastable structures from random initial conditions
# needs: VR speed control [missing], touch-to-toggle cells [missing], density slider [missing]
# relationships: unlocks edge_core concept; depends on cellular automata foundations; contrasts preserved_pattern (frozen) and chaos_particles (dissolved)
# truth: at the edge of chaos, simple local rules generate unbounded computational complexity

## Grid size
@export var grid_size: int = 16

## Cell size
@export var cell_size: float = 0.04

## Update speed
@export var update_interval: float = 0.2

## Edge color
@export var alive_color: Color = Color(0.2, 0.9, 0.4, 1.0)
@export var dead_color: Color = Color(0.1, 0.15, 0.1, 0.5)

# Internal
var _cells: Array[Array] = []
var _meshes: Array[Array] = []
var _materials: Array[Array] = []
var _timer: float = 0.0
var _generation: int = 0

func _ready() -> void:
	_init_grid()
	_build_visuals()
	_randomize_cells()

func _init_grid() -> void:
	for x in range(grid_size):
		var row: Array[bool] = []
		for z in range(grid_size):
			row.append(false)
		_cells.append(row)

func _build_visuals() -> void:
	var offset = -grid_size * cell_size / 2.0
	
	for x in range(grid_size):
		var mesh_row: Array[MeshInstance3D] = []
		var mat_row: Array[StandardMaterial3D] = []
		
		for z in range(grid_size):
			var mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(cell_size * 0.9, cell_size * 0.5, cell_size * 0.9)
			mesh.mesh = box
			
			mesh.position = Vector3(
				x * cell_size + offset,
				0,
				z * cell_size + offset
			)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = dead_color
			mat.emission_enabled = true
			mat.emission = dead_color
			mat.emission_energy_multiplier = 0.2
			mesh.material_override = mat
			
			add_child(mesh)
			mesh_row.append(mesh)
			mat_row.append(mat)
		
		_meshes.append(mesh_row)
		_materials.append(mat_row)

func _randomize_cells() -> void:
	# Initialize with ~40% alive - edge of chaos density
	for x in range(grid_size):
		for z in range(grid_size):
			_cells[x][z] = randf() < 0.4
	_update_visuals()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_simulation()

func _step_simulation() -> void:
	# Game of Life rules (edge of chaos rules)
	var new_cells: Array[Array] = []
	
	for x in range(grid_size):
		var row: Array[bool] = []
		for z in range(grid_size):
			var neighbors = _count_neighbors(x, z)
			var alive = _cells[x][z]
			
			# Standard Conway rules - known to produce edge-of-chaos behavior
			if alive:
				row.append(neighbors == 2 or neighbors == 3)
			else:
				row.append(neighbors == 3)
		new_cells.append(row)
	
	_cells = new_cells
	_generation += 1
	_update_visuals()
	
	# Re-seed if pattern dies out
	var alive_count = 0
	for x in range(grid_size):
		for z in range(grid_size):
			if _cells[x][z]:
				alive_count += 1
	
	if alive_count < grid_size:
		_randomize_cells()

func _count_neighbors(x: int, z: int) -> int:
	var count = 0
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var nx = (x + dx + grid_size) % grid_size
			var nz = (z + dz + grid_size) % grid_size
			if _cells[nx][nz]:
				count += 1
	return count

func _update_visuals() -> void:
	for x in range(grid_size):
		for z in range(grid_size):
			var alive = _cells[x][z]
			var mat = _materials[x][z]
			var mesh = _meshes[x][z]
			
			if alive:
				mat.albedo_color = alive_color
				mat.emission = alive_color
				mat.emission_energy_multiplier = 1.0
				mesh.scale.y = 1.5
			else:
				mat.albedo_color = dead_color
				mat.emission = dead_color
				mat.emission_energy_multiplier = 0.2
				mesh.scale.y = 1.0

## Reset pattern
func reset() -> void:
	_generation = 0
	_randomize_cells()

## Get current generation
func get_generation() -> int:
	return _generation
