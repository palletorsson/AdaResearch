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

func _ready():
	initialize_rules()

func _process(delta):
	time += delta
	generation_timer += delta
	
	if generation_timer > generation_speed:
		generation_timer = 0.0
		advance_generation()
	
	visualize_rule_30()
	visualize_rule_110()
	show_rule_comparison()
	demonstrate_emergent_patterns()

func initialize_rules():
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

func advance_generation():
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
		
		# Rule 30: 111->0, 110->0, 101->0, 100->1, 011->1, 010->1, 001->1, 000->0
		var pattern = left * 4 + center * 2 + right
		var next_state = 0
		
		match pattern:
			7: next_state = 0  # 111
			6: next_state = 0  # 110
			5: next_state = 0  # 101
			4: next_state = 1  # 100
			3: next_state = 1  # 011
			2: next_state = 1  # 010
			1: next_state = 1  # 001
			0: next_state = 0  # 000
		
		new_row.append(next_state)
	
	return new_row

func apply_rule_110(current_row: Array) -> Array:
	var new_row = []
	
	for i in range(current_row.size()):
		var left = current_row[(i - 1 + current_row.size()) % current_row.size()]
		var center = current_row[i]
		var right = current_row[(i + 1) % current_row.size()]
		
		# Rule 110: 111->0, 110->1, 101->1, 100->0, 011->1, 010->1, 001->1, 000->0
		var pattern = left * 4 + center * 2 + right
		var next_state = 0
		
		match pattern:
			7: next_state = 0  # 111
			6: next_state = 1  # 110
			5: next_state = 1  # 101
			4: next_state = 0  # 100
			3: next_state = 1  # 011
			2: next_state = 1  # 010
			1: next_state = 1  # 001
			0: next_state = 0  # 000
		
		new_row.append(next_state)
	
	return new_row

func visualize_rule_30():
	var container = $Rule30Visualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create Rule 30 pattern
	for gen in range(rule_30_grid.size()):
		var row = rule_30_grid[gen]
		
		for i in range(row.size()):
			if row[i] == 1:
				var cell = CSGBox3D.new()
				cell.size = Vector3(0.15, 0.15, 0.15)
				cell.position = Vector3(
					i * 0.2 - row.size() * 0.1,
					(rule_30_grid.size() - gen - 1) * 0.2,
					0
				)
				
				var material = StandardMaterial3D.new()
				# Color based on generation and position for Rule 30 (chaotic)
				var chaos_factor = sin(float(gen + i) * 0.5) * 0.5 + 0.5
				material.albedo_color = Color(1.0, chaos_factor, 0.2)
				material.emission_enabled = true
				material.emission = Color(1.0, chaos_factor, 0.2) * 0.4
				cell.material_override = material
				
				container.add_child(cell)
	
	# Add rule label
	var label = CSGBox3D.new()
	label.size = Vector3(2.0, 0.3, 0.3)
	label.position = Vector3(0, -2, 0)
	
	var label_material = StandardMaterial3D.new()
	label_material.albedo_color = Color(1.0, 0.5, 0.2)
	label.material_override = label_material
	
	container.add_child(label)

func visualize_rule_110():
	var container = $Rule110Visualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create Rule 110 pattern
	for gen in range(rule_110_grid.size()):
		var row = rule_110_grid[gen]
		
		for i in range(row.size()):
			if row[i] == 1:
				var cell = CSGBox3D.new()
				cell.size = Vector3(0.15, 0.15, 0.15)
				cell.position = Vector3(
					i * 0.2 - row.size() * 0.1,
					(rule_110_grid.size() - gen - 1) * 0.2,
					0
				)
				
				var material = StandardMaterial3D.new()
				# Color based on complex patterns for Rule 110
				var complexity_factor = float(gen) / rule_110_grid.size()
				material.albedo_color = Color(0.2, 0.7, 1.0 - complexity_factor * 0.5)
				material.emission_enabled = true
				material.emission = Color(0.2, 0.7, 1.0 - complexity_factor * 0.5) * 0.4
				cell.material_override = material
				
				container.add_child(cell)
	
	# Add rule label
	var label = CSGBox3D.new()
	label.size = Vector3(2.0, 0.3, 0.3)
	label.position = Vector3(0, -2, 0)
	
	var label_material = StandardMaterial3D.new()
	label_material.albedo_color = Color(0.2, 0.7, 1.0)
	label.material_override = label_material
	
	container.add_child(label)

func show_rule_comparison():
	var container = $RuleComparison
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show rule tables side by side
	var rule_30_table = [0, 1, 1, 1, 1, 0, 0, 0]  # Binary of 30
	var rule_110_table = [0, 1, 1, 1, 0, 1, 1, 0]  # Binary of 110
	
	for i in range(8):
		# Input pattern visualization
		var pattern_display = CSGBox3D.new()
		pattern_display.size = Vector3(0.8, 0.3, 0.3)
		pattern_display.position = Vector3(i * 1.0 - 3.5, 2, 0)
		
		var pattern_material = StandardMaterial3D.new()
		pattern_material.albedo_color = Color(0.5, 0.5, 0.5)
		pattern_display.material_override = pattern_material
		
		container.add_child(pattern_display)
		
		# Rule 30 output
		var rule_30_output = CSGSphere3D.new()
		rule_30_output.radius = 0.2
		rule_30_output.position = Vector3(i * 1.0 - 3.5, 0.5, -1)
		
		var r30_material = StandardMaterial3D.new()
		if rule_30_table[7 - i] == 1:
			r30_material.albedo_color = Color(1.0, 0.5, 0.2)
			r30_material.emission_enabled = true
			r30_material.emission = Color(1.0, 0.5, 0.2) * 0.6
		else:
			r30_material.albedo_color = Color(0.3, 0.3, 0.3)
		
		rule_30_output.material_override = r30_material
		container.add_child(rule_30_output)
		
		# Rule 110 output
		var rule_110_output = CSGSphere3D.new()
		rule_110_output.radius = 0.2
		rule_110_output.position = Vector3(i * 1.0 - 3.5, 0.5, 1)
		
		var r110_material = StandardMaterial3D.new()
		if rule_110_table[7 - i] == 1:
			r110_material.albedo_color = Color(0.2, 0.7, 1.0)
			r110_material.emission_enabled = true
			r110_material.emission = Color(0.2, 0.7, 1.0) * 0.6
		else:
			r110_material.albedo_color = Color(0.3, 0.3, 0.3)
		
		rule_110_output.material_override = r110_material
		container.add_child(rule_110_output)

func demonstrate_emergent_patterns():
	var container = $EmergentPatterns
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Analyze patterns in both rules
	analyze_rule_patterns(container, rule_30_grid, "Rule 30 (Chaotic)", Vector3(-3, 0, 0), Color(1.0, 0.5, 0.2))
	analyze_rule_patterns(container, rule_110_grid, "Rule 110 (Complex)", Vector3(3, 0, 0), Color(0.2, 0.7, 1.0))

func analyze_rule_patterns(container: Node3D, grid: Array, rule_name: String, offset: Vector3, color: Color):
	if grid.size() < 10:
		return
	
	# Calculate pattern metrics
	var entropy = calculate_entropy(grid)
	var periodicity = detect_periodicity(grid)
	var complexity = calculate_complexity(grid)
	
	# Visualize metrics
	var metrics = [
		{"name": "Entropy", "value": entropy},
		{"name": "Periodicity", "value": periodicity},
		{"name": "Complexity", "value": complexity}
	]
	
	for i in range(metrics.size()):
		var metric = metrics[i]
		
		var metric_bar = CSGBox3D.new()
		metric_bar.size = Vector3(0.4, metric.value * 3.0 + 0.1, 0.4)
		metric_bar.position = offset + Vector3(i * 0.6 - 0.6, metric_bar.size.y * 0.5, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * metric.value
		metric_bar.material_override = material
		
		container.add_child(metric_bar)
		
		# Metric label
		var label = CSGBox3D.new()
		label.size = Vector3(0.5, 0.1, 0.1)
		label.position = offset + Vector3(i * 0.6 - 0.6, -0.5, 0)
		
		var label_material = StandardMaterial3D.new()
		label_material.albedo_color = Color(1.0, 1.0, 1.0)
		label.material_override = label_material
		
		container.add_child(label)

func calculate_entropy(grid: Array) -> float:
	if grid.size() < 2:
		return 0.0
	
	# Calculate pattern entropy
	var pattern_counts = {}
	var total_patterns = 0
	
	for row in grid:
		for i in range(row.size() - 2):
			var pattern = str(row[i]) + str(row[i + 1]) + str(row[i + 2])
			if pattern in pattern_counts:
				pattern_counts[pattern] += 1
			else:
				pattern_counts[pattern] = 1
			total_patterns += 1
	
	var entropy = 0.0
	for pattern in pattern_counts:
		var probability = float(pattern_counts[pattern]) / total_patterns
		if probability > 0:
			entropy -= probability * log(probability) / log(2)
	
	return entropy / 3.0  # Normalize

func detect_periodicity(grid: Array) -> float:
	if grid.size() < 10:
		return 0.0
	
	# Simple periodicity detection
	var last_row = grid[grid.size() - 1]
	var max_period = min(10, grid.size() / 2)
	
	for period in range(2, max_period):
		var is_periodic = true
		for i in range(period):
			if grid.size() - 1 - i < 0 or grid.size() - 1 - i - period < 0:
				break
			
			var current_row = grid[grid.size() - 1 - i]
			var previous_row = grid[grid.size() - 1 - i - period]
			
			if not arrays_equal(current_row, previous_row):
				is_periodic = false
				break
		
		if is_periodic:
			return 1.0 - float(period) / max_period
	
	return 0.0

func calculate_complexity(grid: Array) -> float:
	if grid.size() < 5:
		return 0.0
	
	# Calculate Kolmogorov-like complexity
	var transitions = 0
	var total_cells = 0
	
	for gen in range(1, grid.size()):
		var current_row = grid[gen]
		var previous_row = grid[gen - 1]
		
		for i in range(current_row.size()):
			if current_row[i] != previous_row[i]:
				transitions += 1
			total_cells += 1
	
	return float(transitions) / total_cells

func arrays_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	
	return true

