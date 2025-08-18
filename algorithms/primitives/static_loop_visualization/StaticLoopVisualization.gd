extends Node3D

# Static Loop Visualization
# Demonstrates iterator patterns and loop control structures in 3D

var time := 0.0
var loop_timer := 0.0
var animation_speed := 1.0

# Loop states
var for_loop_index := 0
var while_loop_condition := true
var while_loop_counter := 0
var nested_outer_index := 0
var nested_inner_index := 0

# Performance metrics
var iteration_count := 0
var total_operations := 0

func _ready():
	create_loop_visualizations()

func _process(delta):
	time += delta
	loop_timer += delta * animation_speed
	
	animate_for_loop()
	animate_while_loop()
	animate_nested_loops()
	show_iterator_patterns()
	demonstrate_loop_control()
	update_performance_metrics()

func create_loop_visualizations():
	create_for_loop_elements()
	create_while_loop_elements()
	create_nested_loop_elements()

func create_for_loop_elements():
	var container = $ForLoopVisualization
	
	# Create array elements for for-loop
	for i in range(8):
		var element = CSGBox3D.new()
		element.size = Vector3(0.8, 0.8, 0.8)
		element.position = Vector3(0, i * 1.0, 0)
		element.name = "ForElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.4, 0.7, 1.0)
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
	
	# Create iterator pointer
	var pointer = CSGCone3D.new()
	pointer.radius_top = 0.0
	pointer.radius_bottom = 0.3
	pointer.height = 0.8
	pointer.position = Vector3(-1.5, 0, 0)
	pointer.name = "ForLoopPointer"
	
	var pointer_material = StandardMaterial3D.new()
	pointer_material.albedo_color = Color(1.0, 0.2, 0.2)
	pointer_material.emission_enabled = true
	pointer_material.emission = Color(1.0, 0.2, 0.2) * 0.4
	pointer.material_override = pointer_material
	
	container.add_child(pointer)

func create_while_loop_elements():
	var container = $WhileLoopVisualization
	
	# Create condition checker
	var condition_box = CSGBox3D.new()
	condition_box.size = Vector3(1.5, 1.5, 1.5)
	condition_box.position = Vector3(0, 4, 0)
	condition_box.name = "ConditionChecker"
	
	var condition_material = StandardMaterial3D.new()
	condition_material.albedo_color = Color(1.0, 1.0, 0.0)
	condition_material.emission_enabled = true
	condition_material.emission = Color(1.0, 1.0, 0.0) * 0.3
	condition_box.material_override = condition_material
	
	container.add_child(condition_box)
	
	# Create loop body elements
	for i in range(6):
		var element = CSGSphere3D.new()
		element.radius = 0.4
		element.position = Vector3(0, i * 0.8, 0)
		element.name = "WhileElement_" + str(i)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 1.0, 0.4)
		material.metallic = 0.2
		material.roughness = 0.5
		element.material_override = material
		
		container.add_child(element)

func create_nested_loop_elements():
	var container = $NestedLoopVisualization
	
	# Create 2D grid for nested loops
	for i in range(4):
		for j in range(4):
			var element = CSGBox3D.new()
			element.size = Vector3(0.6, 0.6, 0.6)
			element.position = Vector3(i * 0.8, j * 0.8, 0)
			element.name = "NestedElement_" + str(i) + "_" + str(j)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.4, 1.0)
			material.metallic = 0.4
			material.roughness = 0.3
			element.material_override = material
			
			container.add_child(element)

func animate_for_loop():
	var container = $ForLoopVisualization
	var pointer = container.get_node("ForLoopPointer")
	
	# Update for loop index based on timer
	if loop_timer > 0.8:
		for_loop_index = (for_loop_index + 1) % 8
		loop_timer = 0.0
		iteration_count += 1
	
	# Move pointer to current index
	pointer.position.y = for_loop_index * 1.0
	
	# Highlight current element
	for i in range(8):
		var element = container.get_node("ForElement_" + str(i))
		var material = element.material_override as StandardMaterial3D
		
		if i == for_loop_index:
			material.albedo_color = Color(1.0, 0.8, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.8, 0.2) * 0.5
		else:
			material.albedo_color = Color(0.4, 0.7, 1.0)
			material.emission_enabled = false

func animate_while_loop():
	var container = $WhileLoopVisualization
	var condition_checker = container.get_node("ConditionChecker")
	
	# Update while loop counter
	if loop_timer > 1.0:
		while_loop_counter += 1
		if while_loop_counter >= 6:
			while_loop_counter = 0
			while_loop_condition = not while_loop_condition
	
	# Update condition checker color
	var condition_material = condition_checker.material_override as StandardMaterial3D
	if while_loop_condition:
		condition_material.albedo_color = Color(0.2, 1.0, 0.2)
		condition_material.emission = Color(0.2, 1.0, 0.2) * 0.4
	else:
		condition_material.albedo_color = Color(1.0, 0.2, 0.2)
		condition_material.emission = Color(1.0, 0.2, 0.2) * 0.4
	
	# Animate loop body elements
	for i in range(6):
		var element = container.get_node("WhileElement_" + str(i))
		var material = element.material_override as StandardMaterial3D
		
		if while_loop_condition and i <= while_loop_counter:
			material.albedo_color = Color(1.0, 1.0, 0.2)
			element.position.x = sin(time * 3.0 + i) * 0.3
		else:
			material.albedo_color = Color(0.2, 1.0, 0.4)
			element.position.x = 0.0

func animate_nested_loops():
	var container = $NestedLoopVisualization
	
	# Update nested loop indices
	if loop_timer > 0.5:
		nested_inner_index += 1
		if nested_inner_index >= 4:
			nested_inner_index = 0
			nested_outer_index = (nested_outer_index + 1) % 4
		total_operations += 1
	
	# Highlight current position in nested loops
	for i in range(4):
		for j in range(4):
			var element = container.get_node("NestedElement_" + str(i) + "_" + str(j))
			var material = element.material_override as StandardMaterial3D
			
			if i == nested_outer_index and j == nested_inner_index:
				material.albedo_color = Color(1.0, 0.2, 0.2)
				material.emission_enabled = true
				material.emission = Color(1.0, 0.2, 0.2) * 0.6
				element.scale = Vector3(1.2, 1.2, 1.2)
			elif i == nested_outer_index:
				material.albedo_color = Color(1.0, 0.8, 0.2)
				material.emission_enabled = true
				material.emission = Color(1.0, 0.8, 0.2) * 0.3
				element.scale = Vector3(1.0, 1.0, 1.0)
			else:
				material.albedo_color = Color(0.8, 0.4, 1.0)
				material.emission_enabled = false
				element.scale = Vector3(1.0, 1.0, 1.0)

func show_iterator_patterns():
	var container = $IteratorPatterns
	
	# Clear previous elements
	for child in container.get_children():
		child.queue_free()
	
	var patterns = ["Forward", "Backward", "Skip"]
	
	for p in range(patterns.size()):
		for i in range(6):
			var element = CSGCylinder3D.new()
			element.top_radius = 0.3
			element.bottom_radius = 0.3
			element.height = 0.6
			element.position = Vector3(i * 0.8, 0, p * 1.5)
			
			var material = StandardMaterial3D.new()
			
			# Different iterator patterns
			match patterns[p]:
				"Forward":
					var current = int(time * 2) % 6
					if i == current:
						material.albedo_color = Color(1.0, 0.0, 0.0)
						material.emission_enabled = true
						material.emission = Color(1.0, 0.0, 0.0) * 0.4
					else:
						material.albedo_color = Color(0.5, 0.5, 0.5)
				
				"Backward":
					var current = 5 - (int(time * 2) % 6)
					if i == current:
						material.albedo_color = Color(0.0, 1.0, 0.0)
						material.emission_enabled = true
						material.emission = Color(0.0, 1.0, 0.0) * 0.4
					else:
						material.albedo_color = Color(0.5, 0.5, 0.5)
				
				"Skip":
					var current = (int(time * 1.5) * 2) % 6
					if i == current:
						material.albedo_color = Color(0.0, 0.0, 1.0)
						material.emission_enabled = true
						material.emission = Color(0.0, 0.0, 1.0) * 0.4
					else:
						material.albedo_color = Color(0.5, 0.5, 0.5)
			
			element.material_override = material
			container.add_child(element)

func demonstrate_loop_control():
	var container = $LoopControl
	
	# Clear previous elements
	for child in container.get_children():
		child.queue_free()
	
	# Create break and continue demonstration
	var break_point = 3
	var continue_skip = 2
	
	for i in range(8):
		var element = CSGBox3D.new()
		element.size = Vector3(0.5, 0.5, 0.5)
		element.position = Vector3(i * 0.7, 0, 0)
		
		var material = StandardMaterial3D.new()
		
		if i == break_point:
			# Break statement visualization
			material.albedo_color = Color(1.0, 0.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.0, 0.0) * 0.6
		elif i == continue_skip:
			# Continue statement visualization
			material.albedo_color = Color(1.0, 1.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 0.0) * 0.4
		elif i > break_point:
			# Elements after break (not executed)
			material.albedo_color = Color(0.3, 0.3, 0.3)
		else:
			# Normal execution
			material.albedo_color = Color(0.2, 0.8, 0.2)
		
		element.material_override = material
		container.add_child(element)

func update_performance_metrics():
	var container = $PerformanceMetrics
	
	# Clear previous elements
	for child in container.get_children():
		child.queue_free()
	
	# Big O notation visualization
	var complexities = ["O(1)", "O(n)", "O(n²)"]
	var heights = [1.0, float(iteration_count % 10), pow(float(iteration_count % 10), 2) / 10.0]
	
	for i in range(complexities.size()):
		var bar = CSGBox3D.new()
		bar.size = Vector3(0.8, max(heights[i], 0.1), 0.8)
		bar.position = Vector3(i * 1.2, heights[i] / 2.0, 0)
		
		var material = StandardMaterial3D.new()
		match i:
			0:
				material.albedo_color = Color(0.2, 1.0, 0.2)  # Green for O(1)
			1:
				material.albedo_color = Color(1.0, 1.0, 0.2)  # Yellow for O(n)
			2:
				material.albedo_color = Color(1.0, 0.2, 0.2)  # Red for O(n²)
		
		material.metallic = 0.2
		material.roughness = 0.6
		bar.material_override = material
		
		container.add_child(bar)

