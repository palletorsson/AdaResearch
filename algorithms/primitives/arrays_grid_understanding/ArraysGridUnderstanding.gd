extends Node3D

# Arrays and Grid Understanding Visualization
# Demonstrates fundamental data structure concepts in 3D space

var time := 0.0
var array_1d := []
var grid_2d := []
var grid_3d := []
var current_operation := ""
var operation_timer := 0.0

# Array visualization nodes
var one_d_elements := []
var two_d_elements := []
var three_d_elements := []

# Demo states
var insertion_index := 0
var deletion_index := 0
var search_target := 0
var search_index := 0

func _ready():
	initialize_arrays()
	create_array_visualizations()

func _process(delta):
	time += delta
	operation_timer += delta
	
	animate_arrays()
	demonstrate_operations(delta)
	update_indexing_visualization()
	show_access_patterns()

func initialize_arrays():
	# 1D Array (10 elements)
	array_1d = []
	for i in range(10):
		array_1d.append(randi() % 100)
	
	# 2D Grid (5x5)
	grid_2d = []
	for i in range(5):
		var row = []
		for j in range(5):
			row.append(randi() % 50)
		grid_2d.append(row)
	
	# 3D Grid (3x3x3)
	grid_3d = []
	for i in range(3):
		var plane = []
		for j in range(3):
			var row = []
			for k in range(3):
				row.append(randi() % 25)
			plane.append(row)
		grid_3d.append(plane)

func create_array_visualizations():
	create_1d_array_visualization()
	create_2d_grid_visualization()
	create_3d_grid_visualization()

func create_1d_array_visualization():
	var container = $ArrayVisualization/OneDimensionalArray
	
	for i in range(array_1d.size()):
		var element = CSGBox3D.new()
		element.size = Vector3(0.8, 0.8, 0.8)
		element.position = Vector3(i * 1.0, 0, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0, 0.8)
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
		one_d_elements.append(element)
		
		# Index labels (using small cubes as markers)
		var index_marker = CSGBox3D.new()
		index_marker.size = Vector3(0.2, 0.2, 0.2)
		index_marker.position = Vector3(i * 1.0, -1.5, 0)
		
		var index_material = StandardMaterial3D.new()
		index_material.albedo_color = Color(1.0, 1.0, 0.0)
		index_material.emission_enabled = true
		index_material.emission = Color(1.0, 1.0, 0.0) * 0.3
		index_marker.material_override = index_material
		
		container.add_child(index_marker)

func create_2d_grid_visualization():
	var container = $ArrayVisualization/TwoDimensionalGrid
	
	for i in range(grid_2d.size()):
		var row_elements = []
		for j in range(grid_2d[i].size()):
			var element = CSGBox3D.new()
			element.size = Vector3(0.8, 0.8, 0.8)
			element.position = Vector3(j * 1.0, 0, i * 1.0)
			
			var material = StandardMaterial3D.new()
			var value_ratio = float(grid_2d[i][j]) / 50.0
			material.albedo_color = Color(1.0 - value_ratio, value_ratio, 0.5, 0.8)
			material.metallic = 0.4
			material.roughness = 0.3
			element.material_override = material
			
			container.add_child(element)
			row_elements.append(element)
		
		two_d_elements.append(row_elements)

func create_3d_grid_visualization():
	var container = $ArrayVisualization/ThreeDimensionalGrid
	
	for i in range(grid_3d.size()):
		var plane_elements = []
		for j in range(grid_3d[i].size()):
			var row_elements = []
			for k in range(grid_3d[i][j].size()):
				var element = CSGBox3D.new()
				element.size = Vector3(0.6, 0.6, 0.6)
				element.position = Vector3(k * 0.8, j * 0.8, i * 0.8)
				
				var material = StandardMaterial3D.new()
				var value_ratio = float(grid_3d[i][j][k]) / 25.0
				material.albedo_color = Color(value_ratio, 0.5, 1.0 - value_ratio, 0.7)
				material.metallic = 0.2
				material.roughness = 0.5
				element.material_override = material
				
				container.add_child(element)
				row_elements.append(element)
			
			plane_elements.append(row_elements)
		
		three_d_elements.append(plane_elements)

func animate_arrays():
	# Animate 1D array elements
	for i in range(one_d_elements.size()):
		var element = one_d_elements[i]
		var height_offset = sin(time * 2.0 + i * 0.5) * 0.3
		element.position.y = height_offset
	
	# Animate 2D grid with wave pattern
	for i in range(two_d_elements.size()):
		for j in range(two_d_elements[i].size()):
			var element = two_d_elements[i][j]
			var wave_height = sin(time + i * 0.3 + j * 0.3) * 0.4
			element.position.y = wave_height

func demonstrate_operations(delta):
	# Cycle through different operations
	if operation_timer > 3.0:
		operation_timer = 0.0
		
		match current_operation:
			"insertion":
				current_operation = "deletion"
			"deletion":
				current_operation = "search"
			"search":
				current_operation = "insertion"
			_:
				current_operation = "insertion"
	
	# Highlight current operation
	match current_operation:
		"insertion":
			demonstrate_insertion()
		"deletion":
			demonstrate_deletion()
		"search":
			demonstrate_search()

func demonstrate_insertion():
	var container = $DataManipulation/InsertionDemo
	
	# Clear previous demonstration
	for child in container.get_children():
		child.queue_free()
	
	# Create insertion visualization
	for i in range(8):
		var element = CSGBox3D.new()
		element.size = Vector3(0.6, 0.6, 0.6)
		element.position = Vector3(i * 0.8, 0, 0)
		
		var material = StandardMaterial3D.new()
		if i == insertion_index:
			# Highlight insertion point
			material.albedo_color = Color(1.0, 0.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.0, 0.0) * 0.5
		else:
			material.albedo_color = Color(0.5, 0.8, 0.9)
		
		element.material_override = material
		container.add_child(element)
	
	# Update insertion index
	insertion_index = (insertion_index + 1) % 8

func demonstrate_deletion():
	var container = $DataManipulation/DeletionDemo
	
	# Clear previous demonstration
	for child in container.get_children():
		child.queue_free()
	
	# Create deletion visualization
	for i in range(8):
		if i == deletion_index:
			continue  # Skip deleted element
		
		var element = CSGBox3D.new()
		element.size = Vector3(0.6, 0.6, 0.6)
		element.position = Vector3(i * 0.8, 0, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.5, 0.9)
		element.material_override = material
		container.add_child(element)
	
	# Update deletion index
	deletion_index = (deletion_index + 1) % 8

func demonstrate_search():
	var container = $DataManipulation/SearchDemo
	
	# Clear previous demonstration
	for child in container.get_children():
		child.queue_free()
	
	# Create search visualization
	for i in range(8):
		var element = CSGBox3D.new()
		element.size = Vector3(0.6, 0.6, 0.6)
		element.position = Vector3(i * 0.8, 0, 0)
		
		var material = StandardMaterial3D.new()
		if i == search_index:
			# Highlight current search position
			material.albedo_color = Color(1.0, 1.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 0.0) * 0.4
		elif i == search_target:
			# Highlight target
			material.albedo_color = Color(0.0, 1.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(0.0, 1.0, 0.0) * 0.4
		else:
			material.albedo_color = Color(0.7, 0.7, 0.7)
		
		element.material_override = material
		container.add_child(element)
	
	# Update search progress
	search_index = (search_index + 1) % 8
	if search_index == 0:
		search_target = randi() % 8

func update_indexing_visualization():
	var container = $IndexingVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show array indexing concept
	var index_count = 6
	for i in range(index_count):
		# Array element
		var element = CSGBox3D.new()
		element.size = Vector3(0.8, 0.8, 0.8)
		element.position = Vector3(i * 1.2, 0, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.6, 0.8, 1.0)
		element.material_override = material
		
		container.add_child(element)
		
		# Index pointer
		var pointer = CSGCone3D.new()
		pointer.radius_top = 0.0
		pointer.radius_bottom = 0.2
		pointer.height = 0.6
		pointer.position = Vector3(i * 1.2, -1.0, 0)
		
		var pointer_material = StandardMaterial3D.new()
		pointer_material.albedo_color = Color(1.0, 0.5, 0.0)
		pointer.material_override = pointer_material
		
		container.add_child(pointer)

func show_access_patterns():
	var container = $AccessPatterns
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show different access patterns
	var patterns = ["Sequential", "Random", "Binary Search"]
	
	for p in range(patterns.size()):
		for i in range(5):
			var element = CSGBox3D.new()
			element.size = Vector3(0.6, 0.6, 0.6)
			element.position = Vector3(i * 0.8, 0, p * 1.5)
			
			var material = StandardMaterial3D.new()
			
			# Different highlighting based on access pattern
			match patterns[p]:
				"Sequential":
					var highlight = int(time * 2) % 5
					if i == highlight:
						material.albedo_color = Color(1.0, 0.0, 0.0)
						material.emission_enabled = true
						material.emission = Color(1.0, 0.0, 0.0) * 0.3
					else:
						material.albedo_color = Color(0.5, 0.5, 0.5)
				
				"Random":
					var highlight = int(time * 3) % 5
					if i == highlight:
						material.albedo_color = Color(0.0, 1.0, 0.0)
						material.emission_enabled = true
						material.emission = Color(0.0, 1.0, 0.0) * 0.3
					else:
						material.albedo_color = Color(0.5, 0.5, 0.5)
				
				"Binary Search":
					var mid = 2
					var search_step = int(time * 1.5) % 3
					if (search_step == 0 and i == mid) or (search_step == 1 and i < mid) or (search_step == 2 and i > mid):
						material.albedo_color = Color(0.0, 0.0, 1.0)
						material.emission_enabled = true
						material.emission = Color(0.0, 0.0, 1.0) * 0.3
					else:
						material.albedo_color = Color(0.5, 0.5, 0.5)
			
			element.material_override = material
			container.add_child(element)
		
		# Add pattern label (small cube as marker)
		var label = CSGBox3D.new()
		label.size = Vector3(0.3, 0.3, 0.3)
		label.position = Vector3(-1, 0, p * 1.5)
		
		var label_material = StandardMaterial3D.new()
		label_material.albedo_color = Color(1.0, 1.0, 1.0)
		label.material_override = label_material
		
		container.add_child(label)

