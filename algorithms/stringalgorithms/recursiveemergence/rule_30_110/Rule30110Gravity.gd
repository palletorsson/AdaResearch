extends "res://algorithms/stringalgorithms/recursiveemergence/rule_30_110/Rule30110.gd"

var rigid_bodies_30 = []
var rigid_bodies_110 = []
var rigid_bodies_90 = []
var rigid_bodies_150 = []
var rigid_bodies_pyramid = []

var current_rule_state = 0  # 0: Rule 30, 1: Rule 110, 2: Rule 90, 3: Rule 150, 4: Pyramid
var generation_complete = false
var delay_timer = 0.0

func _ready():
	max_generations = 12
	initialize_rules()

func _process(delta):
	time += delta

	if generation_complete:
		delay_timer += delta
		if delay_timer > 5.0: # 5 second delay
			delay_timer = 0.0
			current_rule_state += 1
			if current_rule_state > 4:
				current_rule_state = 0 # loop
			generation_complete = false
			initialize_rules()
		return

	generation_timer += delta
	if generation_timer > generation_speed:
		generation_timer = 0.0
		advance_generation()

func advance_generation():
	if current_rule_state == 4:
		if not generation_complete:
			visualize_pyramid()
			generation_complete = true
			for body in rigid_bodies_pyramid:
				body.freeze = false
		return

	if current_generation < max_generations:
		current_generation += 1
		
		match current_rule_state:
			0:
				var new_row_30 = apply_rule_30(rule_30_grid[rule_30_grid.size() - 1])
				rule_30_grid.append(new_row_30)
				visualize_rule_30_gravity()
			1:
				var new_row_110 = apply_rule_110(rule_110_grid[rule_110_grid.size() - 1])
				rule_110_grid.append(new_row_110)
				visualize_rule_110_gravity()
			2:
				var new_row_90 = apply_rule_90(rule_90_grid[rule_90_grid.size() - 1])
				rule_90_grid.append(new_row_90)
				visualize_rule_90_gravity()
			3:
				var new_row_150 = apply_rule_150(rule_150_grid[rule_150_grid.size() - 1])
				rule_150_grid.append(new_row_150)
				visualize_rule_150_gravity()
	else:
		generation_complete = true
		match current_rule_state:
			0:
				for body in rigid_bodies_30:
					body.freeze = false
			1:
				for body in rigid_bodies_110:
					body.freeze = false
			2:
				for body in rigid_bodies_90:
					body.freeze = false
			3:
				for body in rigid_bodies_150:
					body.freeze = false

# Placeholder rules
var rule_90_grid := []
var rule_150_grid := []
var rule_90_seed := []
var rule_150_seed := []

func initialize_rules():
	if current_rule_state == 4:
		return
	super.initialize_rules() # call parent
	# Initialize Rule 90
	rule_90_seed = []
	for i in range(grid_width):
		rule_90_seed.append(1 if i == grid_width / 2 else 0)
	rule_90_grid = [rule_90_seed.duplicate()]

	# Initialize Rule 150
	rule_150_seed = []
	for i in range(grid_width):
		rule_150_seed.append(1 if i == grid_width / 2 else 0)
	rule_150_grid = [rule_150_seed.duplicate()]
	
	current_generation = 0

func apply_rule_90(current_row: Array) -> Array:
	var new_row = []
	for i in range(current_row.size()):
		var left = current_row[(i - 1 + current_row.size()) % current_row.size()]
		var center = current_row[i]
		var right = current_row[(i + 1) % current_row.size()]
		# Rule 90: 01011010
		var pattern = left * 4 + center * 2 + right
		var next_state = 0
		match pattern:
			7: next_state = 0
			6: next_state = 1
			5: next_state = 0
			4: next_state = 1
			3: next_state = 1
			2: next_state = 0
			1: next_state = 1
			0: next_state = 0
		new_row.append(next_state)
	return new_row

func apply_rule_150(current_row: Array) -> Array:
	var new_row = []
	for i in range(current_row.size()):
		var left = current_row[(i - 1 + current_row.size()) % current_row.size()]
		var center = current_row[i]
		var right = current_row[(i + 1) % current_row.size()]
		# Rule 150: 10010110
		var pattern = left * 4 + center * 2 + right
		var next_state = 0
		match pattern:
			7: next_state = 1
			6: next_state = 0
			5: next_state = 0
			4: next_state = 1
			3: next_state = 0
			2: next_state = 1
			1: next_state = 1
			0: next_state = 0
		new_row.append(next_state)
	return new_row

func visualize_rule_30_gravity():
	var container = $Rule30Visualization
	for child in container.get_children():
		child.queue_free()
	rigid_bodies_30 = []
	
	for gen in range(rule_30_grid.size()):
		var row = rule_30_grid[gen]
		for i in range(row.size()):
			if row[i] == 1:
				var rigid_body = create_falling_cube(gen, i, row.size(), rule_30_grid.size())
				container.add_child(rigid_body)
				rigid_bodies_30.append(rigid_body)

func visualize_rule_110_gravity():
	var container = $Rule110Visualization
	for child in container.get_children():
		child.queue_free()
	rigid_bodies_110 = []

	for gen in range(rule_110_grid.size()):
		var row = rule_110_grid[gen]
		for i in range(row.size()):
			if row[i] == 1:
				var rigid_body = create_falling_cube(gen, i, row.size(), rule_110_grid.size())
				container.add_child(rigid_body)
				rigid_bodies_110.append(rigid_body)

func visualize_rule_90_gravity():
	var container = get_node("Rule90Visualization")
	if !container:
		container = Node3D.new()
		container.name = "Rule90Visualization"
		add_child(container)
	for child in container.get_children():
		child.queue_free()
	rigid_bodies_90 = []

	for gen in range(rule_90_grid.size()):
		var row = rule_90_grid[gen]
		for i in range(row.size()):
			if row[i] == 1:
				var rigid_body = create_falling_cube(gen, i, row.size(), rule_90_grid.size())
				container.add_child(rigid_body)
				rigid_bodies_90.append(rigid_body)

func visualize_rule_150_gravity():
	var container = get_node("Rule150Visualization")
	if !container:
		container = Node3D.new()
		container.name = "Rule150Visualization"
		add_child(container)
	for child in container.get_children():
		child.queue_free()
	rigid_bodies_150 = []

	for gen in range(rule_150_grid.size()):
		var row = rule_150_grid[gen]
		for i in range(row.size()):
			if row[i] == 1:
				var rigid_body = create_falling_cube(gen, i, row.size(), rule_150_grid.size())
				container.add_child(rigid_body)
				rigid_bodies_150.append(rigid_body)

func visualize_pyramid():
	var container = get_node("PyramidVisualization")
	if !container:
		container = Node3D.new()
		container.name = "PyramidVisualization"
		add_child(container)
	for child in container.get_children():
		child.queue_free()
	rigid_bodies_pyramid = []
	var height = 10
	for y in range(height):
		var num_cubes = height - y
		for x in range(num_cubes):
			var rigid_body = create_pyramid_cube(y, x, num_cubes, height)
			container.add_child(rigid_body)
			rigid_bodies_pyramid.append(rigid_body)

func create_pyramid_cube(y, x, num_cubes, height):
	var cube_size = 0.2
	var y_offset = 0.05 + (cube_size / 2.0) - 0.25
	var rigid_body = RigidBody3D.new()
	rigid_body.position = Vector3(
		x * cube_size - num_cubes * (cube_size/2),
		y * cube_size + y_offset,
		0
	)
	rigid_body.freeze = true
	
	var cell = CSGBox3D.new()
	cell.size = Vector3(cube_size, cube_size, cube_size)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.7, 1.0)
	cell.material_override = material
	
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(cube_size, cube_size, cube_size)
	collision_shape.shape = shape
	
	rigid_body.add_child(cell)
	rigid_body.add_child(collision_shape)
	return rigid_body

func create_falling_cube(gen, i, row_size, grid_size):
	var cube_size = 0.2
	var y_offset = 0.05 + (cube_size / 2.0) - 0.25
	var rigid_body = RigidBody3D.new()
	rigid_body.position = Vector3(
		i * cube_size - row_size * (cube_size/2),
		(grid_size - gen - 1) * cube_size + y_offset,
		0
	)
	rigid_body.freeze = true
	
	var cell = CSGBox3D.new()
	cell.size = Vector3(cube_size, cube_size, cube_size)
	
	var material = StandardMaterial3D.new()
	var chaos_factor = sin(float(gen + i) * 0.5) * 0.5 + 0.5
	material.albedo_color = Color(1.0, chaos_factor, 0.2)
	material.emission_enabled = true
	material.emission = Color(1.0, chaos_factor, 0.2) * 0.4
	cell.material_override = material
	
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(cube_size, cube_size, cube_size)
	collision_shape.shape = shape
	
	rigid_body.add_child(cell)
	rigid_body.add_child(collision_shape)
	return rigid_body
