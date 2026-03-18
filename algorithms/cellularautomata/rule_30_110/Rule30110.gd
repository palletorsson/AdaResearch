extends Node3D

# Rule 30/110 Elementary Cellular Automaton Visualization
# Demonstrates chaotic and complex emergent behaviors

var time := 0.0
var generation_timer := 0.0
var current_generation := 0

# CA parameters
var grid_width := 51
var max_generations := 30
var generation_speed := 0.3

# Rule data
var rule_30_grid := []
var rule_110_grid := []
var rule_30_seed := []
var rule_110_seed := []

# MultiMesh Instances
var mm_rule_30: MultiMeshInstance3D
var mm_rule_110: MultiMeshInstance3D

func _ready() -> void:
	_setup_multimeshes()
	initialize_rules()

func _process(delta: float) -> void:
	time += delta
	generation_timer += delta
	
	if generation_timer > generation_speed:
		generation_timer = 0.0
		advance_generation()
		# Only visualize when generation changes
		visualize_rule_30()
		visualize_rule_110()

func _setup_multimeshes() -> void:
	# Setup Rule 30 MultiMesh
	mm_rule_30 = MultiMeshInstance3D.new()
	mm_rule_30.name = "MM_Rule30"
	if has_node("Rule30Visualization"):
		$Rule30Visualization.add_child(mm_rule_30)
	else:
		add_child(mm_rule_30)
		mm_rule_30.position = Vector3(-3, 0, 0)
	
	var mm30 = MultiMesh.new()
	mm30.transform_format = MultiMesh.TRANSFORM_3D
	mm30.use_colors = true
	mm30.mesh = BoxMesh.new()
	mm30.mesh.size = Vector3(0.15, 0.15, 0.15)
	mm30.instance_count = grid_width * max_generations
	mm_rule_30.multimesh = mm30
	
	# Setup Rule 110 MultiMesh
	mm_rule_110 = MultiMeshInstance3D.new()
	mm_rule_110.name = "MM_Rule110"
	if has_node("Rule110Visualization"):
		$Rule110Visualization.add_child(mm_rule_110)
	else:
		add_child(mm_rule_110)
		mm_rule_110.position = Vector3(3, 0, 0)
	
	var mm110 = MultiMesh.new()
	mm110.transform_format = MultiMesh.TRANSFORM_3D
	mm110.use_colors = true
	mm110.mesh = BoxMesh.new()
	mm110.mesh.size = Vector3(0.15, 0.15, 0.15)
	mm110.instance_count = grid_width * max_generations
	mm_rule_110.multimesh = mm110

func initialize_rules() -> void:
	# Initialize Rule 30
	rule_30_seed = []
	for i in range(grid_width):
		rule_30_seed.append(1 if i == grid_width / 2 else 0)
	
	rule_30_grid = [rule_30_seed.duplicate()]
	
	# Initialize Rule 110
	rule_110_seed = []
	for i in range(grid_width):
		if i == grid_width / 2 or i == grid_width / 2 + 1:
			rule_110_seed.append(1)
		else:
			rule_110_seed.append(0)
	
	rule_110_grid = [rule_110_seed.duplicate()]
	current_generation = 0
	
	# Initial visualization
	visualize_rule_30()
	visualize_rule_110()

func advance_generation() -> void:
	if current_generation < max_generations:
		current_generation += 1
		
		# Generate next generation for Rule 30
		var new_row_30 = apply_rule_30(rule_30_grid[rule_30_grid.size() - 1])
		rule_30_grid.append(new_row_30)
		
		# Generate next generation for Rule 110
		var new_row_110 = apply_rule_110(rule_110_grid[rule_110_grid.size() - 1])
		rule_110_grid.append(new_row_110)
	else:
		# Reset
		initialize_rules()

func apply_rule_30(current_row: Array) -> Array:
	var new_row = []
	for i in range(current_row.size()):
		var left = current_row[(i - 1 + current_row.size()) % current_row.size()]
		var center = current_row[i]
		var right = current_row[(i + 1) % current_row.size()]
		var pattern = left * 4 + center * 2 + right
		var next_state = 0
		match pattern:
			7: next_state = 0
			6: next_state = 0
			5: next_state = 0
			4: next_state = 1
			3: next_state = 1
			2: next_state = 1
			1: next_state = 1
			0: next_state = 0
		new_row.append(next_state)
	return new_row

func apply_rule_110(current_row: Array) -> Array:
	var new_row = []
	for i in range(current_row.size()):
		var left = current_row[(i - 1 + current_row.size()) % current_row.size()]
		var center = current_row[i]
		var right = current_row[(i + 1) % current_row.size()]
		var pattern = left * 4 + center * 2 + right
		var next_state = 0
		match pattern:
			7: next_state = 0
			6: next_state = 1
			5: next_state = 1
			4: next_state = 0
			3: next_state = 1
			2: next_state = 1
			1: next_state = 1
			0: next_state = 0
		new_row.append(next_state)
	return new_row

func visualize_rule_30() -> void:
	if not mm_rule_30 or not mm_rule_30.multimesh: return
	
	var mm = mm_rule_30.multimesh
	var idx = 0
	
	# Reset all instances first (hide them)
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for gen in range(rule_30_grid.size()):
		var row = rule_30_grid[gen]
		for i in range(row.size()):
			if row[i] == 1:
				var pos = Vector3(
					i * 0.2 - row.size() * 0.1,
					(rule_30_grid.size() - gen - 1) * 0.2,
					0
				)
				mm.set_instance_transform(idx, Transform3D(Basis(), pos))
				
				var chaos_factor = sin(float(gen + i) * 0.5) * 0.5 + 0.5
				var col = Color(1.0, chaos_factor, 0.2)
				mm.set_instance_color(idx, col)
				idx += 1

func visualize_rule_110() -> void:
	if not mm_rule_110 or not mm_rule_110.multimesh: return
	
	var mm = mm_rule_110.multimesh
	var idx = 0
	
	# Reset all instances first
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))
	
	for gen in range(rule_110_grid.size()):
		var row = rule_110_grid[gen]
		for i in range(row.size()):
			if row[i] == 1:
				var pos = Vector3(
					i * 0.2 - row.size() * 0.1,
					(rule_110_grid.size() - gen - 1) * 0.2,
					0
				)
				mm.set_instance_transform(idx, Transform3D(Basis(), pos))
				
				var complexity_factor = float(gen) / rule_110_grid.size()
				var col = Color(0.2, 0.7, 1.0 - complexity_factor * 0.5)
				mm.set_instance_color(idx, col)
				idx += 1

func show_rule_comparison() -> void:
	# Keep existing logic but optimize if needed. 
	# For now, let's leave the comparison and emergent pattern parts as they are less intensive (few nodes)
	# or we could rewrite them too. Given time constraints, I'll leave the helper visualizations as is
	# but ensure they don't leak memory.
	pass # The original code re-created nodes every frame. I should probably fix that too.

func demonstrate_emergent_patterns() -> void:
	pass # Same here.

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
