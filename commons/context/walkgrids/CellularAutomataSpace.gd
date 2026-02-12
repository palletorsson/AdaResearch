# CellularAutomataSpace.gd - Emergent terrain from simple rules
# Conway's Game of Life and custom rulesets generate terrain where
# alive cells are elevated, dead cells are valleys. Watch civilization
# emerge from randomness, then walk through its fossil record.
#
# "Simple rules. Complex worlds. The city that built itself."

extends TopologySpace
class_name CellularAutomataSpace

@export var initial_density: float = 0.4  # % of cells alive at start
@export var generations: int = 50         # How many steps to simulate
@export var rule_set: RuleSet = RuleSet.GAME_OF_LIFE
@export var seed_value: int = 42
@export var smooth_passes: int = 2        # Gaussian smooth after simulation
@export var alive_height: float = 1.0     # Height of alive cells
@export var dead_height: float = 0.0      # Height of dead cells
@export var accumulate_history: bool = true  # Stack generations for geological layers

# Animation
@export var enable_animation: bool = false
@export var generation_speed: float = 5.0  # Generations per second

enum RuleSet {
	GAME_OF_LIFE,     # B3/S23 — classic
	HIGHLIFE,         # B36/S23 — replicators
	DAY_AND_NIGHT,    # B3678/S34678 — symmetric
	DIAMOEBA,         # B35678/S5678 — amoeba-like blobs
	MAZE,             # B3/S12345 — maze generation
	CAVE,             # B5678/S45678 — cave-like structures
	CUSTOM
}

# Custom rules (only used if rule_set == CUSTOM)
@export var birth_counts: Array[int] = [3]
@export var survive_counts: Array[int] = [2, 3]

var grid: Array = []
var grid_size: int = 0
var rng: RandomNumberGenerator
var base_heights: Array = []
var history_heights: Array = []  # Accumulated height from all generations
var current_generation: int = 0
var animation_timer: float = 0.0

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_apply_ruleset()
	super._ready()

func _apply_ruleset():
	match rule_set:
		RuleSet.GAME_OF_LIFE:
			birth_counts = [3]; survive_counts = [2, 3]
		RuleSet.HIGHLIFE:
			birth_counts = [3, 6]; survive_counts = [2, 3]
		RuleSet.DAY_AND_NIGHT:
			birth_counts = [3, 6, 7, 8]; survive_counts = [3, 4, 6, 7, 8]
		RuleSet.DIAMOEBA:
			birth_counts = [3, 5, 6, 7, 8]; survive_counts = [5, 6, 7, 8]
		RuleSet.MAZE:
			birth_counts = [3]; survive_counts = [1, 2, 3, 4, 5]
		RuleSet.CAVE:
			birth_counts = [5, 6, 7, 8]; survive_counts = [4, 5, 6, 7, 8]
		RuleSet.CUSTOM:
			pass

func generate_space():
	grid_size = resolution + 1
	_initialize_grid()

	# Reset history accumulator
	history_heights.clear()
	history_heights.resize(grid_size * grid_size)
	for i in range(history_heights.size()):
		history_heights[i] = 0.0

	# Run simulation
	for gen in range(generations):
		if accumulate_history:
			_accumulate_to_history(gen)
		_step_generation()
		current_generation = gen

	# Final accumulation
	if accumulate_history:
		_accumulate_to_history(generations)

	_build_mesh()

func _initialize_grid():
	grid.clear()
	grid.resize(grid_size * grid_size)
	for i in range(grid.size()):
		grid[i] = 1 if rng.randf() < initial_density else 0

func _count_neighbors(x: int, z: int) -> int:
	var count = 0
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var nx = (x + dx + grid_size) % grid_size  # Wrap around (toroidal)
			var nz = (z + dz + grid_size) % grid_size
			count += grid[nz * grid_size + nx]
	return count

func _step_generation():
	var new_grid = grid.duplicate()
	for z in range(grid_size):
		for x in range(grid_size):
			var idx = z * grid_size + x
			var neighbors = _count_neighbors(x, z)
			var alive = grid[idx] == 1

			if alive:
				new_grid[idx] = 1 if neighbors in survive_counts else 0
			else:
				new_grid[idx] = 1 if neighbors in birth_counts else 0
	grid = new_grid

func _accumulate_to_history(gen: int):
	"""Stack alive cells into height — geological layering"""
	var layer_weight = 1.0 / float(generations)
	for i in range(grid.size()):
		if grid[i] == 1:
			history_heights[i] += alive_height * layer_weight

func _build_mesh():
	var heights: Array = []

	if accumulate_history:
		heights = history_heights.duplicate()
	else:
		# Just use final state
		for i in range(grid.size()):
			heights.append(alive_height if grid[i] == 1 else dead_height)

	# Smooth passes for walkability
	for _pass in range(smooth_passes):
		heights = _smooth_heights(heights)

	# Scale
	for i in range(heights.size()):
		heights[i] *= height_scale

	base_heights = heights.duplicate()

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _smooth_heights(heights: Array) -> Array:
	"""Simple box blur for walkability"""
	var smoothed = heights.duplicate()
	for z in range(1, grid_size - 1):
		for x in range(1, grid_size - 1):
			var idx = z * grid_size + x
			var avg = (
				heights[idx] +
				heights[idx - 1] + heights[idx + 1] +
				heights[idx - grid_size] + heights[idx + grid_size]
			) / 5.0
			smoothed[idx] = avg
	return smoothed

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.3, 0.25)  # Dark organic green
	material.roughness = 0.85
	material.metallic = 0.05
	material.emission_enabled = true
	material.emission = Color(0.1, 0.2, 0.15) * 0.2
	mesh_instance.material_override = material

func _process(delta):
	if not enable_animation:
		return
	animation_timer += delta
	if animation_timer >= 1.0 / generation_speed:
		animation_timer = 0.0
		_step_generation()
		current_generation += 1
		if accumulate_history:
			_accumulate_to_history(current_generation)
		_build_mesh()

# Public API
func set_rule(new_rule: RuleSet):
	rule_set = new_rule
	_apply_ruleset()
	generate_space()

func regenerate():
	rng.seed = randi()
	generate_space()

func get_current_generation() -> int:
	return current_generation
