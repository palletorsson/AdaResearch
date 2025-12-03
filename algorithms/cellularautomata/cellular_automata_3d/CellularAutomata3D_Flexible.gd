@tool
extends Node3D

# Configurable 3D Cellular Automata
# Supports "Generations" type rules: Survive/Born/States/Neighborhood
# Notation example: "6-8/6-8/3/M"
# S: Survive counts (e.g. 6-8 means 6,7,8)
# B: Born counts (e.g. 6-8 means 6,7,8)
# C: Count of states (e.g. 3 means 0=Dead, 1=Alive, 2=Refractory)
# N: Neighborhood (M=Moore 26, VN=Von Neumann 6)

@export_group("Grid Settings")
@export var grid_size: Vector3i = Vector3i(30, 30, 30)
@export var cell_size: float = 0.2
@export var generation_interval: float = 0.1
@export var paused: bool = false
@export var randomize_on_start: bool = false
@export var center_seed_on_start: bool = true

@export_group("Rule Settings")
@export var rule_string: String = "4-5/5/5/M": # Default to a builder-like rule
	set(value):
		rule_string = value
		_parse_rule(value)

@export_group("Visuals")
@export var mesh_instance: MultiMeshInstance3D
@export var color_alive: Color = Color.WHITE
@export var color_dying: Color = Color.DARK_GRAY
@export var use_gradient: bool = false
@export var gradient: Gradient

# Internal state
var current_state: Array = [] # 3D array [x][y][z]
var next_state: Array = []
var time_accumulator: float = 0.0
var generation: int = 0

# Parsed rule
var rule_survive: Array[bool] = [] # Index is neighbor count
var rule_born: Array[bool] = []
var rule_states: int = 2
var rule_neighborhood: String = "M"

func _ready():
	# robustly find or create mesh instance
	if not mesh_instance:
		# First, try to find an existing child
		for child in get_children():
			if child is MultiMeshInstance3D:
				mesh_instance = child
				break
		
		# If still not found, create one
		if not mesh_instance:
			mesh_instance = MultiMeshInstance3D.new()
			mesh_instance.name = "AutomataMesh"
			add_child(mesh_instance)
			
			# Important: Set owner if in editor so it saves with the scene
			if Engine.is_editor_hint():
				var root = get_tree().edited_scene_root
				if root:
					mesh_instance.owner = root
	
	# Setup MultiMesh if needed
	if not mesh_instance.multimesh:
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = BoxMesh.new()
		multimesh.mesh.size = Vector3(cell_size, cell_size, cell_size) * 0.9
		mesh_instance.multimesh = multimesh
	
	_parse_rule(rule_string)
	_initialize_grid()
	_update_visuals()

func _process(delta):
	if Engine.is_editor_hint():
		return
		
	if paused:
		return
		
	time_accumulator += delta
	if time_accumulator >= generation_interval:
		time_accumulator = 0.0
		_step()

func _parse_rule(rule: String):
	# Format: S/B/C/N
	# Example: 6-8/6-8/3/M
	var parts = rule.split("/")
	if parts.size() < 2:
		push_error("Invalid rule format. Expected S/B/C/N or S/B")
		return
	
	# Reset arrays (max neighbors is 26 for Moore)
	rule_survive = []
	rule_born = []
	rule_survive.resize(27)
	rule_born.resize(27)
	rule_survive.fill(false)
	rule_born.fill(false)
	
	# Parse Survive
	_parse_range_string(parts[0], rule_survive)
	
	# Parse Born
	_parse_range_string(parts[1], rule_born)
	
	# Parse States (Optional, default 2)
	if parts.size() > 2:
		rule_states = int(parts[2])
	else:
		rule_states = 2
		
	# Parse Neighborhood (Optional, default M)
	if parts.size() > 3:
		rule_neighborhood = parts[3]
	else:
		rule_neighborhood = "M"

func _parse_range_string(s: String, target_array: Array[bool]):
	var groups = s.split(",")
	for group in groups:
		if "-" in group:
			var range_parts = group.split("-")
			var start = int(range_parts[0])
			var end = int(range_parts[1])
			for i in range(start, end + 1):
				if i < target_array.size():
					target_array[i] = true
		else:
			var val = int(group)
			if val < target_array.size():
				target_array[val] = true

func _initialize_grid():
	current_state.clear()
	next_state.clear()
	
	# Initialize 3D arrays
	for x in range(grid_size.x):
		var plane = []
		var next_plane = []
		for y in range(grid_size.y):
			var row = []
			var next_row = []
			for z in range(grid_size.z):
				row.append(0)
				next_row.append(0)
			plane.append(row)
			next_plane.append(next_row)
		current_state.append(plane)
		next_state.append(next_plane)
	
	# Seed
	if center_seed_on_start:
		var cx = grid_size.x / 2
		var cy = grid_size.y / 2
		var cz = grid_size.z / 2
		
		# Create a random cluster in the center (6x6x6)
		# This chaos is needed to kickstart "Builder" rules like 6-8/6-8
		var range_ext = 3
		for x in range(cx - range_ext, cx + range_ext + 1):
			for y in range(cy - range_ext, cy + range_ext + 1):
				for z in range(cz - range_ext, cz + range_ext + 1):
					if x < grid_size.x and y < grid_size.y and z < grid_size.z:
						if randf() > 0.5:
							current_state[x][y][z] = 1
	
	if randomize_on_start:
		for x in range(grid_size.x):
			for y in range(grid_size.y):
				for z in range(grid_size.z):
					if randf() < 0.1: # 10% density
						current_state[x][y][z] = 1

	# Setup MultiMesh
	var total_cells = grid_size.x * grid_size.y * grid_size.z
	mesh_instance.multimesh.instance_count = total_cells
	
	# Set initial positions (hidden by scaling to 0 or moving away?)
	# Actually, we just update transforms in _update_visuals.
	# But we need to set them at least once.
	_update_visuals()

func _step():
	# Calculate next state
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var state = current_state[x][y][z]
				var neighbors = _count_neighbors(x, y, z)
				
				if state == 0:
					# Dead -> Alive?
					if rule_born[neighbors]:
						next_state[x][y][z] = 1
					else:
						next_state[x][y][z] = 0
				elif state == 1:
					# Alive -> Alive or Dying?
					if rule_survive[neighbors]:
						next_state[x][y][z] = 1
					else:
						# If states > 2, go to 2. Else die (0).
						if rule_states > 2:
							next_state[x][y][z] = 2
						else:
							next_state[x][y][z] = 0
				else:
					# Dying -> Next State or Dead
					if state < rule_states - 1:
						next_state[x][y][z] = state + 1
					else:
						next_state[x][y][z] = 0
	
	# Swap buffers
	var temp = current_state
	current_state = next_state
	next_state = temp
	
	generation += 1
	_update_visuals()

func _count_neighbors(x: int, y: int, z: int) -> int:
	var count = 0
	
	# Moore Neighborhood (26)
	# Optimized loops?
	var x_min = max(0, x - 1)
	var x_max = min(grid_size.x - 1, x + 1)
	var y_min = max(0, y - 1)
	var y_max = min(grid_size.y - 1, y + 1)
	var z_min = max(0, z - 1)
	var z_max = min(grid_size.z - 1, z + 1)
	
	for nx in range(x_min, x_max + 1):
		for ny in range(y_min, y_max + 1):
			for nz in range(z_min, z_max + 1):
				if nx == x and ny == y and nz == z:
					continue
				if current_state[nx][ny][nz] == 1: # Only count fully ALIVE cells as neighbors usually
					count += 1
	
	return count

func _update_visuals():
	var idx = 0
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var state = current_state[x][y][z]
				var t = Transform3D()
				
				if state > 0:
					t.origin = Vector3(x, y, z) * cell_size
					# Scale based on state?
					t.basis = Basis().scaled(Vector3.ONE)
					
					var color = color_alive
					if state > 1:
						# Dying gradient
						var t_life = float(state - 1) / float(rule_states - 2) if rule_states > 2 else 0.0
						color = color_alive.lerp(color_dying, t_life)
					
					mesh_instance.multimesh.set_instance_transform(idx, t)
					mesh_instance.multimesh.set_instance_color(idx, color)
				else:
					# Hide dead cells by scaling to 0
					t.origin = Vector3(x, y, z) * cell_size
					t.basis = Basis().scaled(Vector3.ZERO)
					mesh_instance.multimesh.set_instance_transform(idx, t)
				
				idx += 1
