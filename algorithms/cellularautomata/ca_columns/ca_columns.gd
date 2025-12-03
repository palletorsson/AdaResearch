@tool
extends Node3D

@export_category("Grid Settings")
@export var grid_size: int = 64
@export var max_height: int = 128
@export var cell_size: float = 0.1
@export var gap: float = 0.0

@export_category("Simulation Settings")
@export var rule_born: Array[int] = [3] # Standard Life: Born with 3 neighbors
@export var rule_survive: Array[int] = [2, 3] # Standard Life: Survive with 2 or 3 neighbors
@export var random_seed: int = 0
@export_range(0.0, 1.0) var initial_density: float = 0.1
@export var auto_generate: bool = true
@export var generation_speed: float = 0.05
@export var continuous_mode: bool = false

@export_category("Rendering")
@export var use_gradient: bool = true
@export var color_start: Color = Color(0.1, 0.3, 0.8, 1)
@export var color_end: Color = Color(0.8, 0.2, 0.8, 1)
@export var gradient: Gradient

var current_generation: int = 0
var grid_2d: Array = [] # 2D array for current state
var history_3d: Array = [] # Array of 2D arrays
var timer: float = 0.0
var is_generating: bool = false

var multi_mesh_instance: MultiMeshInstance3D

func _ready():
	if not gradient:
		_setup_gradient_from_colors()

	# Try to get existing MultiMeshInstance3D node, or create one
	if has_node("MultiMeshInstance3D"):
		multi_mesh_instance = get_node("MultiMeshInstance3D")
	else:
		_setup_multimesh()

	if auto_generate:
		start_generation()

func _setup_gradient_from_colors():
	gradient = Gradient.new()
	gradient.remove_point(0)
	gradient.remove_point(0)
	gradient.add_point(0.0, color_start)
	gradient.add_point(1.0, color_end)

func _process(delta):
	if is_generating:
		timer += delta
		if timer >= generation_speed:
			timer = 0.0
			step()
	else:
		_process_walkers(delta)

func start_generation():
	if random_seed == 0:
		randomize()
	else:
		seed(random_seed)
	current_generation = 0
	history_3d.clear()
	walkers.clear() # Clear old walkers
	_initialize_grid()
	_update_multimesh()
	is_generating = true

func stop_generation():
	is_generating = false

func clear():
	is_generating = false
	current_generation = 0
	history_3d.clear()
	grid_2d.clear()
	walkers.clear()
	if multi_mesh_instance and multi_mesh_instance.multimesh:
		multi_mesh_instance.multimesh.instance_count = 0

func step():
	if history_3d.size() >= max_height:
		if continuous_mode:
			history_3d.pop_front()
		else:
			is_generating = false
			_spawn_walkers() # Start walkers!
			return

	_evolve_grid()
	_update_multimesh()
	
	if not continuous_mode:
		current_generation += 1

func _initialize_grid():
	grid_2d = []
	for x in range(grid_size):
		var col = []
		for y in range(grid_size):
			col.append(1 if randf() < initial_density else 0)
		grid_2d.append(col)
	
	# Store initial state
	history_3d.append(grid_2d.duplicate(true))

func _evolve_grid():
	var new_grid = []
	for x in range(grid_size):
		var col = []
		for y in range(grid_size):
			var neighbors = _count_neighbors(x, y)
			var state = grid_2d[x][y]
			var new_state = 0
			
			if state == 1:
				if neighbors in rule_survive:
					new_state = 1
			else:
				if neighbors in rule_born:
					new_state = 1
			
			col.append(new_state)
		new_grid.append(col)
	
	grid_2d = new_grid
	history_3d.append(grid_2d.duplicate(true))

func _count_neighbors(x, y) -> int:
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue
			
			var nx = (x + i + grid_size) % grid_size # Wrap around
			var ny = (y + j + grid_size) % grid_size # Wrap around
			
			if grid_2d[nx][ny] == 1:
				count += 1
	return count

func _setup_multimesh():
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.name = "MultiMeshInstance3D"
	add_child(multi_mesh_instance)
	
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cell_size, cell_size, cell_size)
	
	# Create material that uses vertex colors
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	
	multimesh.mesh = mesh
	
	# Pre-allocate enough instances for the whole volume (worst case)
	# This might be too much memory if grid is huge, but for 64x64x128 it's ~500k instances.
	# MultiMesh handles this fine usually.
	multimesh.instance_count = 0 # Start empty
	multimesh.use_colors = true
	multi_mesh_instance.multimesh = multimesh

func _update_multimesh():
	if not multi_mesh_instance or not multi_mesh_instance.multimesh:
		return

	# Calculate total active cells
	var total_cells = 0
	for layer in history_3d:
		for x in range(grid_size):
			for y in range(grid_size):
				if layer[x][y] == 1:
					total_cells += 1
	
	var mm = multi_mesh_instance.multimesh
	mm.instance_count = total_cells
	
	var idx = 0
	var offset = grid_size * (cell_size + gap) / 2.0
	
	for z in range(history_3d.size()):
		var layer = history_3d[z]
		var layer_ratio = float(z) / max_height
		var layer_color = gradient.sample(layer_ratio) if use_gradient and gradient else Color.WHITE
		
		for x in range(grid_size):
			for y in range(grid_size):
				if layer[x][y] == 1:
					var pos = Vector3(
						x * (cell_size + gap) - offset,
						z * (cell_size + gap),
						y * (cell_size + gap) - offset
					)
					var t = Transform3D(Basis(), pos)
					mm.set_instance_transform(idx, t)
					mm.set_instance_color(idx, layer_color)
					idx += 1

# ==============================
# WALKER LOGIC
# ==============================

@export_category("Walkers")
@export var enable_walkers: bool = true
@export var walker_count: int = 10
@export var walker_speed: float = 0.1
@export var erosion_chance: float = 0.2
@export var deposition_chance: float = 0.05

var walkers: Array = [] # Array of Vector3i positions
var walker_timer: float = 0.0

func _spawn_walkers():
	walkers.clear()
	if not enable_walkers or history_3d.is_empty():
		return
		
	# Spawn at top
	var top_z = history_3d.size() - 1
	for i in range(walker_count):
		var x = randi() % grid_size
		var y = randi() % grid_size
		walkers.append(Vector3i(x, y, top_z))

func _process_walkers(delta):
	if is_generating or history_3d.is_empty():
		return
		
	walker_timer += delta
	if walker_timer >= walker_speed:
		walker_timer = 0.0
		_step_walkers()
		_update_multimesh() # Re-render changes

func _step_walkers():
	for i in range(walkers.size()):
		var pos = walkers[i]
		
		# 1. Move Randomly
		var move = Vector3i(randi_range(-1, 1), randi_range(-1, 1), randi_range(-1, 1))
		var new_pos = pos + move
		
		# Clamp to bounds
		new_pos.x = posmod(new_pos.x, grid_size) # Wrap X
		new_pos.y = posmod(new_pos.y, grid_size) # Wrap Y
		new_pos.z = clamp(new_pos.z, 0, history_3d.size() - 1) # Clamp Z
		
		walkers[i] = new_pos
		
		# 2. Action
		var current_state = history_3d[new_pos.z][new_pos.x][new_pos.y]
		
		if current_state == 1:
			# Erosion: If standing on block, maybe eat it
			if randf() < erosion_chance:
				history_3d[new_pos.z][new_pos.x][new_pos.y] = 0
		else:
			# Deposition: If standing on empty, maybe place block (if supported)
			if randf() < deposition_chance:
				# Check support (neighbors)
				var neighbors = _count_3d_neighbors(new_pos.x, new_pos.y, new_pos.z)
				if neighbors > 0:
					history_3d[new_pos.z][new_pos.x][new_pos.y] = 1

func _count_3d_neighbors(x, y, z) -> int:
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			for k in range(-1, 2):
				if i == 0 and j == 0 and k == 0: continue
				
				var nx = (x + i + grid_size) % grid_size
				var ny = (y + j + grid_size) % grid_size
				var nz = z + k
				
				if nz >= 0 and nz < history_3d.size():
					if history_3d[nz][nx][ny] == 1:
						count += 1
	return count
