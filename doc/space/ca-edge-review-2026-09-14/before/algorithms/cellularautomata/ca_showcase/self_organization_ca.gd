# SelfOrganizationCA.gd
# The edge of chaos — Langton's lambda, the between-state where complexity lives
#
# @identity
# essence: cell(t+1) = cell(t)*(1-k) + avg(neighbors)*k + noise, where LAMBDA slides k and noise between two deaths — frozen order and pure chaos — and complexity emerges only in the narrow band between them.
# desire: To live at the edge. Not to freeze into one uniform consensus (order's death), not to dissolve into static (chaos's death), but to hover in the critical band where domains form, drift, break, and reform — never settling, never scattering.
# critical_parameter: LAMBDA (0.5) — Langton's λ, the queer between-state. Low λ → strong consensus pull, no noise → the grid freezes solid (order dies still). High λ → no pull, all noise → the grid boils into static (chaos dies loud). The interesting things happen only in the middle.
# triggers: Slide λ toward 0 and watch domains lock into a single frozen field; slide toward 1 and watch structure boil away into noise; hold λ in the CRITICAL_BAND (0.35–0.65) and structure persists AND changes at once.
# emerges: Order and chaos are the two deaths; the edge is the living zone. Maximal pattern diversity, longest-lived boundaries, and the most complex behaviour all peak in the critical band — computation lives where neither order nor chaos wins.
# needs: VR lambda slider [missing — see set_lambda()], diversity readout [has via get_pattern_diversity], critical-band indicator [has via is_at_edge_of_chaos].
# relationships: The CA analogue of the phase transition — between solid and gas, between the frozen and the random, between the closeted-fixed and the noise-erased. Feeds into CA_EdgeOfChaos; the self-organization it demonstrates is precisely what only survives at the edge.
# truth: There are two ways to die — freeze into one thing, or dissolve into everything. Langton's lambda names the narrow band between them, and that band is where organization, memory, and computation live. The edge of chaos is not a compromise between order and noise; it is the only place complexity is possible.

extends BaseCA

# LAMBDA is Langton's λ — the position between the two deaths.
#   0.0 → frozen order (consensus pull maxed, noise off): the grid locks solid.
#   1.0 → pure chaos (no pull, noise maxed): the grid boils into static.
#   The living zone is the narrow CRITICAL_BAND around the middle.
const LAMBDA = 0.5
const CRITICAL_BAND_LOW = 0.35
const CRITICAL_BAND_HIGH = 0.65

# Extremes the effective parameters interpolate between as LAMBDA moves.
# At LAMBDA=0 the cell is pulled hard toward its neighbours and never perturbed;
# at LAMBDA=1 the cell ignores its neighbours and is dominated by noise.
const INTERACTION_STRENGTH_ORDERED = 0.35   # strong consensus pull (frozen end)
const INTERACTION_STRENGTH_CHAOTIC = 0.0    # no pull at all (noise end)
const RANDOMNESS_ORDERED = 0.0              # perfectly quiet (frozen end)
const RANDOMNESS_CHAOTIC = 4.0             # noise swamps structure (chaotic end)

var lambda_value: float = LAMBDA

# Effective per-step parameters, derived from lambda_value each evolution step.
# Kept as named vars so the reading stays legible: consensus falls and noise rises
# as we walk from order (0) toward chaos (1).
func _interaction_strength() -> float:
	return lerp(INTERACTION_STRENGTH_ORDERED, INTERACTION_STRENGTH_CHAOTIC, lambda_value)

func _randomness() -> float:
	return lerp(RANDOMNESS_ORDERED, RANDOMNESS_CHAOTIC, lambda_value)

func initialize_grid() -> void:
	# Configure MultiMesh
	var step = 3
	var cube_size = CUBE_SIZE * step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var cells_per_axis := ceili(float(GRID_SIZE) / step)
	var max_instances = cells_per_axis * cells_per_axis * cells_per_axis
	configure_multimesh(mesh, max_instances)
	
	grid = create_3d_grid()
	
	# Initialize with random values
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				grid[x][y][z] = randi() % 10  # Random state 0-9

func update_simulation(_delta) -> void:
	# Evolve self-organizing patterns
	evolve_self_organization()
	# Note: update_visualization() is called by base_ca._process() after this

func evolve_self_organization() -> void:
	var new_grid = duplicate_3d_grid(grid)

	# Derive the two competing pressures from Langton's lambda once per step.
	# Toward order: strong consensus pull, no noise. Toward chaos: no pull, loud noise.
	var interaction := _interaction_strength()
	var randomness := _randomness()

	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var neighbors = get_3d_neighbors(Vector3i(x, y, z))
				var neighbor_sum = 0
				var valid_neighbors = 0

				for neighbor in neighbors:
					if is_valid_3d_position(neighbor):
						neighbor_sum += grid[neighbor.x][neighbor.y][neighbor.z]
						valid_neighbors += 1

				if valid_neighbors > 0:
					# Self-organization rule: become similar to neighbors
					var avg_neighbor = float(neighbor_sum) / valid_neighbors
					var new_value = grid[x][y][z] * (1.0 - interaction) + avg_neighbor * interaction

					# Add lambda-scaled randomness (the chaos pressure)
					new_value += randf_range(-randomness, randomness)

					# Clamp to valid range
					new_grid[x][y][z] = int(clamp(new_value, 0, 9))

	grid = new_grid

func update_visualization() -> void:
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return
		
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	var step = 3
	
	# Reset remaining instances
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for x in range(0, GRID_SIZE, step):
		for y in range(0, GRID_SIZE, step):
			for z in range(0, GRID_SIZE, step):
				var state = grid[x][y][z]
				if state > 0 and idx < mm.instance_count:  # Only show non-zero states
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Add colors for each vertex
					var color = get_state_color(state)
					mm.set_instance_color(idx, color)
					
					idx += 1

func get_state_color(state: int) -> Color:
	# Color-code different states
	var colors = [
		Color.BLACK,           # 0
		Color.RED,             # 1
		Color.GREEN,           # 2
		Color.BLUE,            # 3
		Color.YELLOW,          # 4
		Color.MAGENTA,         # 5
		Color.CYAN,            # 6
		Color.WHITE,           # 7
		Color(1.0, 0.5, 0.0),  # 8 - Orange
		Color(0.5, 0.0, 1.0)   # 9 - Purple
	]
	
	return colors[state % colors.size()]

func get_pattern_diversity() -> int:
	var unique_states = {}
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var state = grid[x][y][z]
				unique_states[state] = true
	return unique_states.size()

func reset_simulation() -> void:
	grid = create_3d_grid()
	initialize_grid()
	iteration_count = 0

# --- Edge of chaos controls ---

# Move the system along Langton's lambda axis. 0 = frozen order, 1 = pure chaos,
# ~0.5 = the living edge. Clamped so the reading stays honest at the extremes.
func set_lambda(value: float) -> void:
	lambda_value = clamp(value, 0.0, 1.0)

func get_lambda() -> float:
	return lambda_value

# True while lambda sits in the critical band — the narrow zone where structure
# both persists and changes, and complexity is maximal.
func is_at_edge_of_chaos() -> bool:
	return lambda_value >= CRITICAL_BAND_LOW and lambda_value <= CRITICAL_BAND_HIGH

# Names the current regime for readouts: "order" (frozen), "edge" (living), "chaos" (static).
func get_regime() -> String:
	if lambda_value < CRITICAL_BAND_LOW:
		return "order"
	elif lambda_value > CRITICAL_BAND_HIGH:
		return "chaos"
	return "edge"

func apply_grid_config(config: Dictionary) -> void:
	# Optional lambda override from map config, so a map can seat this artifact
	# anywhere on the order↔chaos axis. Additive: absent keys leave the default edge.
	if config.has("lambda"):
		set_lambda(float(config["lambda"]))
