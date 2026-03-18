extends Node3D

var time = 0.0
var grid_size = 12
var current_generation = 0
var generation_timer = 0.0
var generation_interval = 0.5 # Faster interval
var current_state = []
var rule_timer = 0.0
var rule_interval = 10.0
var is_simulation_running = true
var max_generations = 100

# 3D CA rules
enum Rule3D {
	LIFE_3D,
	CRYSTAL_GROWTH,
	EROSION,
	DIFFUSION
}

var current_rule = Rule3D.LIFE_3D
var alive_count = 0

@onready var multi_mesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D

func _ready() -> void:
	_setup_multimesh()
	setup_materials()
	initialize_3d_automaton()

func _setup_multimesh() -> void:
	# Create MultiMesh if not exists
	if not has_node("MultiMeshInstance3D"):
		multi_mesh_instance = MultiMeshInstance3D.new()
		multi_mesh_instance.name = "MultiMeshInstance3D"
		add_child(multi_mesh_instance)
	else:
		multi_mesh_instance = $MultiMeshInstance3D
		
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = SphereMesh.new()
	multimesh.mesh.radius = 0.1
	multimesh.mesh.height = 0.2
	multimesh.mesh.radial_segments = 8 # Low poly for performance
	multimesh.mesh.rings = 4
	
	# Pre-allocate for max possible cells (grid_size^3)
	multimesh.instance_count = grid_size * grid_size * grid_size
	
	# Hide all initially
	for i in range(multimesh.instance_count):
		multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0))) # Move away
		
	multi_mesh_instance.multimesh = multimesh

func setup_materials() -> void:
	# Generation control material
	var gen_material = StandardMaterial3D.new()
	gen_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	gen_material.emission_enabled = true
	gen_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	if has_node("GenerationControl"):
		$GenerationControl.material_override = gen_material
	
	# Density indicator material
	var density_material = StandardMaterial3D.new()
	density_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	density_material.emission_enabled = true
	density_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	if has_node("DensityIndicator"):
		$DensityIndicator.material_override = density_material

func initialize_3d_automaton() -> void:
	current_state = []
	# Initialize grid
	for x in range(grid_size):
		current_state.append([])
		for y in range(grid_size):
			current_state[x].append([])
			for z in range(grid_size):
				current_state[x][y].append(0)
	
	# Add initial pattern based on rule
	match current_rule:
		Rule3D.LIFE_3D:
			# Random sparse initialization
			for i in range(40): # Increased count
				var rx = randi() % grid_size
				var ry = randi() % grid_size
				var rz = randi() % grid_size
				current_state[rx][ry][rz] = 1
		
		Rule3D.CRYSTAL_GROWTH:
			# Central seed
			var center = grid_size / 2
			current_state[center][center][center] = 1
		
		Rule3D.EROSION:
			# Start with many cells
			for x in range(grid_size):
				for y in range(grid_size):
					for z in range(grid_size):
						if randf() < 0.6:
							current_state[x][y][z] = 1
		
		Rule3D.DIFFUSION:
			# Corner initialization
			current_state[0][0][0] = 1
			current_state[grid_size-1][grid_size-1][grid_size-1] = 1
	
	current_generation = 0
	update_cell_display()

func _process(delta: float) -> void:
	if !is_simulation_running:
		return

	time += delta
	generation_timer += delta
	rule_timer += delta
	
	# Generate next generation
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		if current_generation < max_generations:
			generate_next_3d_generation()
	
	# Switch rules
	if rule_timer >= rule_interval:
		rule_timer = 0.0
		switch_3d_rule()
	
	animate_indicators()

func stop_simulation() -> void:
	is_simulation_running = false

func generate_next_3d_generation() -> void:
	if current_generation >= max_generations:
		stop_simulation()
		return

	var next_state = []
	
	# Initialize next state
	for x in range(grid_size):
		next_state.append([])
		for y in range(grid_size):
			next_state[x].append([])
			for z in range(grid_size):
				next_state[x][y].append(0)

	# Calculate the next state
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				var neighbors = count_3d_neighbors(x, y, z)
				var current_cell = current_state[x][y][z]
				next_state[x][y][z] = apply_3d_rule(current_cell, neighbors)

	# Identify dying cells and update current_state
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if current_state[x][y][z] == 1 and next_state[x][y][z] == 0:
					current_state[x][y][z] = 2 # Mark as dying
				else:
					current_state[x][y][z] = next_state[x][y][z]

	current_generation += 1
	update_cell_display()

func count_3d_neighbors(x: int, y: int, z: int) -> int:
	var count = 0
	
	# Check all 26 neighbors (Moore neighborhood)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				if dx == 0 and dy == 0 and dz == 0:
					continue
				
				var nx = (x + dx + grid_size) % grid_size
				var ny = (y + dy + grid_size) % grid_size
				var nz = (z + dz + grid_size) % grid_size
				
				if current_state[nx][ny][nz] == 1:
					count += 1
	
	return count

func apply_3d_rule(current_cell: int, neighbors: int) -> int:
	match current_rule:
		Rule3D.LIFE_3D:
			if current_cell == 1:
				return 1 if neighbors >= 4 and neighbors <= 7 else 0
			else:
				return 1 if neighbors == 6 else 0
		
		Rule3D.CRYSTAL_GROWTH:
			if current_cell == 1:
				return 1
			else:
				return 1 if neighbors >= 1 and neighbors <= 3 else 0
		
		Rule3D.EROSION:
			if current_cell == 1:
				return 0 if neighbors < 2 or neighbors > 8 else 1
			else:
				return 0
		
		Rule3D.DIFFUSION:
			if current_cell == 1:
				return 1 if neighbors >= 2 and neighbors <= 5 else 0
			else:
				return 1 if neighbors >= 3 and neighbors <= 4 else 0
		
		_:
			return current_cell

func switch_3d_rule() -> void:
	current_rule = (current_rule + 1) % Rule3D.size()
	initialize_3d_automaton()

func update_cell_display() -> void:
	alive_count = 0
	if not multi_mesh_instance or not multi_mesh_instance.multimesh: return
	
	var mm = multi_mesh_instance.multimesh
	var idx = 0
	
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				var cell_state = current_state[x][y][z]
				
				if cell_state == 0:
					# Hide (move away)
					mm.set_instance_transform(idx, Transform3D(Basis(), Vector3(0, -1000, 0)))
				else:
					if cell_state == 1:
						alive_count += 1
					
					var pos = Vector3(
						-3 + x * 0.5,
						-3 + y * 0.5,
						-3 + z * 0.5
					)
					mm.set_instance_transform(idx, Transform3D(Basis(), pos))
					
					# Color logic
					var col = Color.WHITE
					if cell_state == 1:
						var color_intensity = float(x + y + z) / (grid_size * 3)
						col = Color(
							1.0 - color_intensity * 0.5,
							0.3 + color_intensity * 0.7,
							0.8,
							1.0
						)
					elif cell_state == 2:
						col = Color(1.0, 0.0, 0.0, 1.0)
					
					mm.set_instance_color(idx, col)
				
				idx += 1

func animate_indicators() -> void:
	# Generation control
	if has_node("GenerationControl"):
		var gen_height = (current_generation % 20) * 0.15 + 0.5
		$GenerationControl.height = gen_height
		$GenerationControl.position.y = -4 + gen_height/2
		
		# Pulsing effects
		var pulse = 1.0 + sin(time * 4.0) * 0.1
		$GenerationControl.scale.x = pulse
	
	# Density indicator
	if has_node("DensityIndicator"):
		var density = float(alive_count) / (grid_size * grid_size * grid_size)
		var density_height = density * 3.0 + 0.5
		$DensityIndicator.height = density_height
		$DensityIndicator.position.y = -4 + density_height/2
		$DensityIndicator.scale.x = 1.0 + sin(time * 4.0) * 0.1
	
	# Update rule-based colors
	var gen_material = $GenerationControl.material_override as StandardMaterial3D if has_node("GenerationControl") else null
	var density_material = $DensityIndicator.material_override as StandardMaterial3D if has_node("DensityIndicator") else null
	
	if gen_material and density_material:
		match current_rule:
			Rule3D.LIFE_3D:
				gen_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
				density_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			Rule3D.CRYSTAL_GROWTH:
				gen_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
				density_material.albedo_color = Color(1.0, 0.2, 0.8, 1.0)
			Rule3D.EROSION:
				gen_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
				density_material.albedo_color = Color(0.8, 0.4, 0.2, 1.0)
			Rule3D.DIFFUSION:
				gen_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
				density_material.albedo_color = Color(0.4, 1.0, 0.6, 1.0)
		
		gen_material.emission = gen_material.albedo_color * 0.3
		density_material.emission = density_material.albedo_color * 0.3

func get_rule_name() -> String:
	match current_rule:
		Rule3D.LIFE_3D:
			return "3D Life"
		Rule3D.CRYSTAL_GROWTH:
			return "Crystal Growth"
		Rule3D.EROSION:
			return "Erosion"
		Rule3D.DIFFUSION:
			return "Diffusion"
		_:
			return "Unknown"

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
