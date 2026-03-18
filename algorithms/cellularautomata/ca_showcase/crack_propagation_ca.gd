# CrackPropagationCA.gd
# Material crack propagation simulation
extends BaseCA

const CRACK_THRESHOLD = 0.4
const STRESS_POINTS = 3

var stress_points: Array = []

func initialize_grid() -> void:
	# Configure MultiMesh
	var step = 3
	var cube_size = CUBE_SIZE * step
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cube_size, cube_size, cube_size)
	
	var max_instances = (GRID_SIZE / step) * (GRID_SIZE / step) * (GRID_SIZE / step)
	configure_multimesh(mesh, max_instances)
	
	grid = create_3d_grid()
	
	# Add initial stress concentrators
	for i in range(STRESS_POINTS):
		var stress_point = Vector3i(
			randi() % GRID_SIZE,
			GRID_SIZE - 1,
			randi() % GRID_SIZE
		)
		stress_points.append(stress_point)
		grid[stress_point.x][stress_point.y][stress_point.z] = 1  # Stress point

func update_simulation(_delta) -> void:
	# Propagate cracks from stress concentrators
	propagate_cracks()
	update_visualization()

func propagate_cracks() -> void:
	for stress_point in stress_points:
		var neighbors = get_3d_neighbors(stress_point)
		for neighbor in neighbors:
			if is_valid_3d_position(neighbor) and randf() < 0.05:
				if grid[neighbor.x][neighbor.y][neighbor.z] == 0:
					grid[neighbor.x][neighbor.y][neighbor.z] = 2  # Cracked state

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
				if state == 1 or state == 2:
					var world_pos = Vector3(
						(x - GRID_SIZE/2) * CUBE_SIZE,
						(y - GRID_SIZE/2) * CUBE_SIZE,
						(z - GRID_SIZE/2) * CUBE_SIZE
					)
					
					mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
					
					# Color logic
					if state == 1:
						mm.set_instance_color(idx, Color.RED) # Stress point
					else:
						mm.set_instance_color(idx, Color.GRAY) # Crack
					
					idx += 1

func get_crack_count() -> int:
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 2:
					count += 1
	return count

func reset_simulation() -> void:
	grid = create_3d_grid()
	stress_points.clear()
	initialize_grid()
	iteration_count = 0

func apply_grid_config(config: Dictionary) -> void:
	pass
