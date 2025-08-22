extends Node3D

var time = 0.0
var grid_width = 40
var grid_height = 30
var current_generation = 0
var generation_timer = 0.0
var generation_interval = 0.3
var rule_number = 30
var rule_timer = 0.0
var rule_interval = 8.0

# Current state and history
var current_state = []
var generation_history = []
var grid_cells = []

# Famous rules to cycle through
var famous_rules = [30, 110, 90, 150, 184, 226]
var current_rule_index = 0

func _ready():
	create_automaton_grid()
	create_rule_table()
	setup_materials()
	initialize_automaton()

func create_automaton_grid():
	var grid_parent = $AutomatonGrid
	
	for y in range(grid_height):
		grid_cells.append([])
		for x in range(grid_width):
			var cell = CSGBox3D.new()
			cell.size = Vector3(0.15, 0.15, 0.15)
			cell.position = Vector3(
				-6 + x * 0.3,
				9 - y * 0.2,
				0
			)
			grid_parent.add_child(cell)
			grid_cells[y].append(cell)

func create_rule_table():
	var rule_parent = $RuleTable
	
	# Create 8 rule combinations (000 to 111)
	for i in range(8):
		var rule_group = Node3D.new()
		rule_parent.add_child(rule_group)
		
		# Input pattern (3 cells)
		for j in range(3):
			var input_cell = CSGBox3D.new()
			input_cell.size = Vector3(0.1, 0.1, 0.1)
			input_cell.position = Vector3(
				-6 + i * 1.5 + j * 0.15,
				4.5,
				0
			)
			rule_group.add_child(input_cell)
		
		# Arrow
		var arrow = CSGCylinder3D.new()
		arrow.radius = 0.05
		arrow.height = 0.2
		arrow.rotation_degrees = Vector3(180, 0, 0)
		arrow.position = Vector3(
			-6 + i * 1.5 + 0.15,
			4.2,
			0
		)
		rule_group.add_child(arrow)
		
		# Output cell
		var output_cell = CSGBox3D.new()
		output_cell.size = Vector3(0.1, 0.1, 0.1)
		output_cell.position = Vector3(
			-6 + i * 1.5 + 0.15,
			3.9,
			0
		)
		rule_group.add_child(output_cell)

func setup_materials():
	# Generation indicator material
	var gen_material = StandardMaterial3D.new()
	gen_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	gen_material.emission_enabled = true
	gen_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$GenerationIndicator.material_override = gen_material
	
	# Rule number material
	var rule_material = StandardMaterial3D.new()
	rule_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	rule_material.emission_enabled = true
	rule_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$RuleNumber.material_override = rule_material

func initialize_automaton():
	# Initialize with single active cell in center
	current_state.clear()
	generation_history.clear()
	
	for i in range(grid_width):
		current_state.append(0)
	
	# Set center cell to 1
	current_state[grid_width / 2] = 1
	generation_history.append(current_state.duplicate())
	
	current_generation = 0
	update_grid_display()
	update_rule_table()

func _process(delta):
	time += delta
	generation_timer += delta
	rule_timer += delta
	
	# Generate next generation
	if generation_timer >= generation_interval and current_generation < grid_height - 1:
		generation_timer = 0.0
		generate_next_generation()
	
	# Switch rules
	if rule_timer >= rule_interval:
		rule_timer = 0.0
		switch_rule()
	
	animate_automaton()
	animate_indicators()

func generate_next_generation():
	var new_state = []
	
	for i in range(grid_width):
		# Get neighborhood (left, center, right)
		var left = current_state[(i - 1 + grid_width) % grid_width]
		var center = current_state[i]
		var right = current_state[(i + 1) % grid_width]
		
		# Apply rule
		var neighborhood = left * 4 + center * 2 + right
		var new_cell = apply_rule(neighborhood)
		new_state.append(new_cell)
	
	current_state = new_state
	generation_history.append(current_state.duplicate())
	current_generation += 1
	
	update_grid_display()

func apply_rule(neighborhood: int) -> int:
	# Apply elementary cellular automaton rule
	# Rule number determines output for each of 8 possible neighborhoods
	return (rule_number >> neighborhood) & 1

func switch_rule():
	current_rule_index = (current_rule_index + 1) % famous_rules.size()
	rule_number = famous_rules[current_rule_index]
	initialize_automaton()
	update_rule_table()

func update_grid_display():
	# Update all visible generations
	for gen in range(min(generation_history.size(), grid_height)):
		var generation = generation_history[gen]
		
		for x in range(grid_width):
			var cell = grid_cells[gen][x]
			var cell_state = generation[x]
			
			# Update material based on state
			var cell_material = StandardMaterial3D.new()
			
			if cell_state == 1:
				# Alive cell
				cell_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
				cell_material.emission_enabled = true
				cell_material.emission = Color(0.8, 0.8, 0.8, 1.0)
			else:
				# Dead cell
				cell_material.albedo_color = Color(0.2, 0.2, 0.2, 0.3)
				cell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				cell_material.emission_enabled = true
				cell_material.emission = Color(0.05, 0.05, 0.05, 1.0)
			
			cell.material_override = cell_material

func update_rule_table():
	# Update rule table display
	var rule_parent = $RuleTable
	
	for i in range(8):
		var rule_group = rule_parent.get_child(i)
		var neighborhood = 7 - i  # Reverse order for conventional display
		var output = apply_rule(neighborhood)
		
		# Update input pattern
		for j in range(3):
			var input_cell = rule_group.get_child(j)
			var bit_value = (neighborhood >> (2 - j)) & 1
			
			var input_material = StandardMaterial3D.new()
			if bit_value == 1:
				input_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
				input_material.emission_enabled = true
				input_material.emission = Color(0.5, 0.5, 0.5, 1.0)
			else:
				input_material.albedo_color = Color(0.3, 0.3, 0.3, 1.0)
				input_material.emission_enabled = true
				input_material.emission = Color(0.1, 0.1, 0.1, 1.0)
			
			input_cell.material_override = input_material
		
		# Update output cell
		var output_cell = rule_group.get_child(4)  # Arrow is at index 3
		var output_material = StandardMaterial3D.new()
		
		if output == 1:
			output_material.albedo_color = Color(0.2, 1.0, 0.2, 1.0)
			output_material.emission_enabled = true
			output_material.emission = Color(0.1, 0.5, 0.1, 1.0)
		else:
			output_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
			output_material.emission_enabled = true
			output_material.emission = Color(0.5, 0.1, 0.1, 1.0)
		
		output_cell.material_override = output_material
		
		# Update arrow
		var arrow = rule_group.get_child(3)
		var arrow_material = StandardMaterial3D.new()
		arrow_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
		arrow_material.emission_enabled = true
		arrow_material.emission = Color(0.3, 0.3, 0.1, 1.0)
		arrow.material_override = arrow_material

func animate_automaton():
	# Animate current generation
	if current_generation < grid_height:
		for x in range(grid_width):
			var cell = grid_cells[current_generation][x]
			var pulse = 1.0 + sin(time * 6.0 + x * 0.2) * 0.2
			cell.scale = Vector3.ONE * pulse
	
	# Animate rule table
	var rule_parent = $RuleTable
	for i in range(rule_parent.get_child_count()):
		var rule_group = rule_parent.get_child(i)
		var wave = sin(time * 4.0 + i * 0.5) * 0.1
		rule_group.position.y = 4.2 + wave

func animate_indicators():
	# Generation indicator
	var gen_height = (current_generation / float(grid_height)) * 2.0 + 0.5
	var generationindicator = get_node_or_null("GenerationIndicator")
	if generationindicator and generationindicator is CSGCylinder3D:
		generationindicator.height = gen_height
		generationindicator.position.y = 3 + gen_height/2
	
	# Rule number indicator
	var rule_height = (rule_number / 255.0) * 2.0 + 0.5
	$RuleNumber.size.y = rule_height
	$RuleNumber.position.y = 3 + rule_height/2
	
	# Update rule number color based on rule
	var rule_material = $RuleNumber.material_override as StandardMaterial3D
	if rule_material:
		match rule_number:
			30:
				rule_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			110:
				rule_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
			90:
				rule_material.albedo_color = Color(1.0, 0.2, 0.8, 1.0)
			150:
				rule_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
			184:
				rule_material.albedo_color = Color(1.0, 0.6, 0.2, 1.0)
			226:
				rule_material.albedo_color = Color(0.6, 1.0, 0.2, 1.0)
			_:
				rule_material.albedo_color = Color(0.5, 0.5, 0.5, 1.0)
		
		rule_material.emission = rule_material.albedo_color * 0.3
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$GenerationIndicator.scale.x = pulse
	$RuleNumber.scale.x = pulse

func get_rule_name() -> String:
	match rule_number:
		30:
			return "Rule 30 (Chaotic)"
		110:
			return "Rule 110 (Turing Complete)"
		90:
			return "Rule 90 (Sierpinski Triangle)"
		150:
			return "Rule 150 (Balanced)"
		184:
			return "Rule 184 (Traffic Flow)"
		226:
			return "Rule 226 (Complex)"
		_:
			return "Rule %d" % rule_number
