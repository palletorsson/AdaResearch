class_name LineNetworkCA
extends BaseCA

# Visualizes CA growth as a branching network of lines.
# When a cell is born, it connects to a neighbor that was already alive.

var connections: Array = [] # Array of [Vector3(start), Vector3(end), color]
var immediate_mesh: ImmediateMesh
var mesh_instance_lines: MeshInstance3D
var cell_birth_times: Dictionary = {} # Vector3i -> float
var cell_parents: Dictionary = {} # Vector3i -> Vector3i

@export var line_width: float = 0.02
@export var color_start: Color = Color(0.2, 0.8, 1.0)
@export var color_end: Color = Color(0.8, 0.2, 1.0)

@export var demo_mode: bool = true
@export var growth_probability: float = 0.1
@export var max_generations: int = 20

var frontier: Array = [] # Array of Vector3i

func _ready() -> void:
	super._ready()
	# Hide the default blocky mesh
	if mesh_instance: mesh_instance.visible = false
	if multi_mesh_instance: multi_mesh_instance.visible = false
	
	setup_line_renderer()

func initialize_grid() -> void:
	grid = create_3d_grid()
	frontier.clear()
	
	if demo_mode:
		# Random walk for demo purposes to ensure connectivity
		var cx = GRID_SIZE / 2
		var cy = GRID_SIZE / 2
		var cz = GRID_SIZE / 2
		var walker = Vector3i(cx, cy, cz)
		grid[cx][cy][cz] = 1
		cell_birth_times[walker] = 0.0 # Seed the first one
		frontier.append(walker)
		
		for i in range(100):
			var dir = Vector3i(randi() % 3 - 1, randi() % 3 - 1, randi() % 3 - 1)
			if dir == Vector3i.ZERO: continue
			
			walker += dir
			if is_valid_3d_position(walker):
				if grid[walker.x][walker.y][walker.z] == 0:
					grid[walker.x][walker.y][walker.z] = 1
					frontier.append(walker)

func update_simulation(_delta) -> void:
	if iteration_count >= max_generations:
		return

	# Generic growth simulation
	var new_cells = []
	
	# Grow from frontier
	for pos in frontier:
		if randf() < growth_probability:
			# Try to grow in a random direction
			var dir = Vector3i(randi() % 3 - 1, randi() % 3 - 1, randi() % 3 - 1)
			if dir == Vector3i.ZERO: continue
			
			var new_pos = pos + dir
			if is_valid_3d_position(new_pos):
				if grid[new_pos.x][new_pos.y][new_pos.z] == 0:
					grid[new_pos.x][new_pos.y][new_pos.z] = 1
					new_cells.append(new_pos)
	
	# Add new cells to frontier
	for cell in new_cells:
		frontier.append(cell)
		
	# Optional: Remove "dead" frontier cells? 
	# For now, keep them all to allow branching from old segments.

func setup_line_renderer() -> void:
	immediate_mesh = ImmediateMesh.new()
	mesh_instance_lines = MeshInstance3D.new()
	mesh_instance_lines.mesh = immediate_mesh
	mesh_instance_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance_lines.material_override = mat
	
	add_child(mesh_instance_lines)

func update_visualization() -> void:
	# We override this to track births and build connections
	# But BaseCA calls this *after* update_simulation.
	# We need to know what changed.
	# BaseCA doesn't give us the diff.
	# So we have to scan the grid and compare with known state or just rebuild.
	
	# Actually, let's just scan the grid.
	# For every active cell, if we haven't seen it before, find a parent.
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] > 0:
					var pos = Vector3i(x, y, z)
					if not cell_birth_times.has(pos):
						# New cell!
						cell_birth_times[pos] = current_time
						_find_parent_and_connect(pos)

	_draw_lines()

func _find_parent_and_connect(pos: Vector3i) -> void:
	# Find a neighbor that is ALREADY in cell_birth_times (older than me)
	var neighbors = get_3d_neighbors(pos)
	var best_parent = Vector3i(-1, -1, -1)
	var min_dist_sq = 9999.0
	
	# Prefer neighbors that are actually adjacent (distance 1)
	# get_3d_neighbors returns 26 neighbors.
	
	var candidates = []
	for n in neighbors:
		if is_valid_3d_position(n) and cell_birth_times.has(n):
			candidates.append(n)
	
	if candidates.size() > 0:
		# Pick a random one for variety, or the oldest?
		# Random looks more organic.
		var parent = candidates.pick_random()
		cell_parents[pos] = parent
		
		var p1 = _grid_to_world(pos)
		var p2 = _grid_to_world(parent)
		
		# Calculate color based on height or generation
		var t = float(pos.y) / GRID_SIZE
		var col = color_start.lerp(color_end, t)
		
		connections.append([p1, p2, col])

func _grid_to_world(pos: Vector3i) -> Vector3:
	return Vector3(
		(pos.x - GRID_SIZE/2) * CUBE_SIZE * VISUALIZATION_STEP,
		(pos.y - GRID_SIZE/2) * CUBE_SIZE * VISUALIZATION_STEP,
		(pos.z - GRID_SIZE/2) * CUBE_SIZE * VISUALIZATION_STEP
	)

func _draw_lines() -> void:
	if connections.is_empty():
		return
		
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for conn in connections:
		var p1 = conn[0]
		var p2 = conn[1]
		var col = conn[2]
		
		immediate_mesh.surface_set_color(col)
		immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_set_color(col)
		immediate_mesh.surface_add_vertex(p2)
	
	immediate_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

