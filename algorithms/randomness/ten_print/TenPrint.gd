extends Node3D

var time = 0.0
var grid_size = 20
var cell_size = 0.4
var probability = 0.5
var generation_timer = 0.0
var generation_interval = 0.1
var current_row = 0
var current_col = 0
var maze_lines = []
var grid_nodes = []
var generation_speed = 1.0

func _ready():
	create_grid()
	setup_materials()
	start_generation()

func create_grid():
	var grid_parent = $GridNodes
	
	for x in range(grid_size):
		grid_nodes.append([])
		for y in range(grid_size):
			var grid_node = CSGSphere3D.new()
			grid_node.radius = 0.03
			grid_node.position = Vector3(
				-4 + x * cell_size,
				4 - y * cell_size,
				0
			)
			grid_parent.add_child(grid_node)
			grid_nodes[x].append(grid_node)

func setup_materials():
	# Grid node materials
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.1, 0.1, 0.1, 1.0)
	
	for row in grid_nodes:
		for node in row:
			node.material_override = grid_material
	
	# Probability control material
	var prob_material = StandardMaterial3D.new()
	prob_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	prob_material.emission_enabled = true
	prob_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$ProbabilityControl.material_override = prob_material
	
	# Generation speed material
	var speed_material = StandardMaterial3D.new()
	speed_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	speed_material.emission_enabled = true
	speed_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$GenerationSpeed.material_override = speed_material

func start_generation():
	current_row = 0
	current_col = 0
	
	# Clear existing maze lines
	for line in maze_lines:
		line.queue_free()
	maze_lines.clear()

func _process(delta):
	time += delta
	generation_timer += delta
	
	# Update parameters
	probability = 0.5 + sin(time * 0.3) * 0.3
	generation_speed = 1.0 + sin(time * 0.2) * 2.0
	generation_interval = 0.2 / generation_speed
	
	# Generate maze step by step
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		generate_maze_step()
	
	animate_ten_print()
	animate_indicators()

func generate_maze_step():
	if current_row >= grid_size:
		# Reset and start over
		start_generation()
		return
	
	# Generate line for current cell
	var use_forward_slash = randf() < probability
	create_maze_line(current_col, current_row, use_forward_slash)
	
	# Highlight current position
	highlight_current_position()
	
	# Move to next position
	current_col += 1
	if current_col >= grid_size:
		current_col = 0
		current_row += 1

func create_maze_line(x: int, y: int, forward_slash: bool):
	var line = CSGCylinder3D.new()
	line.top_radius = 0.02
	line.bottom_radius = 0.02
	line.height = cell_size * sqrt(2)  # Diagonal length
	
	# Position at cell center
	var cell_center = Vector3(
		-4 + x * cell_size,
		4 - y * cell_size,
		0.1
	)
	line.position = cell_center
	
	# Rotate based on slash type
	if forward_slash:
		line.rotation_degrees = Vector3(0, 0, 45)  # /
	else:
		line.rotation_degrees = Vector3(0, 0, -45) # \
	
	# Material based on position and type
	var line_material = StandardMaterial3D.new()
	var color_intensity = (x + y) / float(grid_size * 2)
	
	if forward_slash:
		line_material.albedo_color = Color(
			1.0,
			0.3 + color_intensity * 0.7,
			0.3,
			1.0
		)
	else:
		line_material.albedo_color = Color(
			0.3,
			0.3 + color_intensity * 0.7,
			1.0,
			1.0
		)
	
	line_material.emission_enabled = true
	line_material.emission = line_material.albedo_color * 0.4
	line.material_override = line_material
	
	$MazeLines.add_child(line)
	maze_lines.append(line)

func highlight_current_position():
	# Reset all grid nodes
	for row in grid_nodes:
		for node in row:
			node.scale = Vector3.ONE * 0.5
	
	# Highlight current position
	if current_row < grid_size and current_col < grid_size:
		var current_node = grid_nodes[current_col][current_row]
		current_node.scale = Vector3.ONE * 2.0
		
		# Update material
		var highlight_material = StandardMaterial3D.new()
		highlight_material.albedo_color = Color(1.0, 1.0, 0.2, 1.0)
		highlight_material.emission_enabled = true
		highlight_material.emission = Color(0.5, 0.5, 0.1, 1.0)
		current_node.material_override = highlight_material

func animate_ten_print():
	# Animate maze lines with wave effect
	for i in range(maze_lines.size()):
		var line = maze_lines[i]
		var wave_phase = time * 3.0 - i * 0.1
		var wave_intensity = sin(wave_phase) * 0.2 + 1.0
		line.scale = Vector3.ONE * wave_intensity
		
		# Update emission based on wave
		var material = line.material_override as StandardMaterial3D
		if material:
			var base_emission = material.albedo_color * 0.4
			material.emission = base_emission * wave_intensity
	
	# Animate grid nodes
	for x in range(grid_nodes.size()):
		for y in range(grid_nodes[x].size()):
			var node = grid_nodes[x][y]
			if node != grid_nodes[current_col][current_row]:  # Don't animate current position
				var pulse = sin(time * 2.0 + x * 0.3 + y * 0.2) * 0.1 + 0.5
				node.scale = Vector3.ONE * pulse

func animate_indicators():
	# Probability control
	var prob_height = probability * 2.0 + 0.5
	$ProbabilityControl.size.y = prob_height
	$ProbabilityControl.position.y = -4 + prob_height/2
	
	# Generation speed indicator
	var speed_height = (generation_speed / 3.0) * 1.5 + 0.5
	$GenerationSpeed.size.y = speed_height
	$GenerationSpeed.position.y = -4 + speed_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$ProbabilityControl.scale.x = pulse
	$GenerationSpeed.scale.x = pulse
	
	# Color changes based on probability
	var prob_material = $ProbabilityControl.material_override as StandardMaterial3D
	if prob_material:
		prob_material.albedo_color = Color(
			1.0,
			0.3 + probability * 0.7,
			0.3,
			1.0
		)
		prob_material.emission = prob_material.albedo_color * 0.5

func get_maze_pattern_info() -> String:
	var forward_count = 0
	var backward_count = 0
	
	for line in maze_lines:
		if line.rotation_degrees.z == 45:
			forward_count += 1
		else:
			backward_count += 1
	
	return "Forward: %d, Backward: %d" % [forward_count, backward_count]
