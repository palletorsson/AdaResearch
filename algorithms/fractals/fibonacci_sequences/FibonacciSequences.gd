extends Node3D

# Fibonacci Sequences Visualization
# Mathematical recursion patterns in nature and computation

var time := 0.0
var sequence_timer := 0.0
var current_index := 0
var fibonacci_numbers := [1, 1]
var golden_ratio := (1 + sqrt(5)) / 2

func _ready():
	generate_fibonacci_sequence(20)

func _process(delta):
	time += delta
	sequence_timer += delta
	
	if sequence_timer > 0.8:
		sequence_timer = 0.0
		current_index = (current_index + 1) % fibonacci_numbers.size()
	
	visualize_number_sequence()
	create_golden_spiral()
	show_natural_patterns()
	demonstrate_recursion()

func generate_fibonacci_sequence(count: int):
	fibonacci_numbers = [1, 1]
	
	for i in range(2, count):
		var next_fib = fibonacci_numbers[i-1] + fibonacci_numbers[i-2]
		fibonacci_numbers.append(next_fib)

func visualize_number_sequence():
	var container = $NumberSequence
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show Fibonacci sequence as growing towers (ordered along Z instead of X)
	for i in range(min(15, fibonacci_numbers.size())):
		var number = fibonacci_numbers[i]
		var height = log(number) * 0.5 + 0.5  # Logarithmic scale
		
		var number_tower = CSGBox3D.new()
		number_tower.size = Vector3(0.6, height, 0.6)
		number_tower.position = Vector3(0, height * 0.5, i * 0.8 - 6)
		
		var material = StandardMaterial3D.new()
		if i == current_index:
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.6
		else:
			var ratio_to_golden = float(fibonacci_numbers[i]) / pow(golden_ratio, i)
			material.albedo_color = Color(0.3 + ratio_to_golden * 0.7, 0.7, 1.0 - ratio_to_golden * 0.5)
		
		number_tower.material_override = material
		container.add_child(number_tower)
		
		# Show the addition relationship
		if i >= 2:
			create_addition_visualization(container, i)

func create_addition_visualization(container: Node3D, index: int):
	# Visualize Fib(n) = Fib(n-1) + Fib(n-2)
	var connection1 = CSGCylinder3D.new()
	connection1.radius = 0.02
	
	connection1.height = 0.8
	# Order connections along Z instead of X
	connection1.position = Vector3(0.3, 2.5, (index - 1) * 0.8 - 6 + 0.4)
	connection1.rotation_degrees = Vector3(0, 0, -45)
	
	var conn_material = StandardMaterial3D.new()
	conn_material.albedo_color = Color(0.8, 0.8, 0.2, 0.7)
	conn_material.flags_transparent = true
	connection1.material_override = conn_material
	
	container.add_child(connection1)
	
	var connection2 = CSGCylinder3D.new()
	connection2.radius = 0.02
	
	connection2.height = 1.6
	connection2.position = Vector3(0.6, 2.5, (index - 2) * 0.8 - 6 + 0.8)
	connection2.rotation_degrees = Vector3(0, 0, -30)
	
	connection2.material_override = conn_material
	container.add_child(connection2)

func create_golden_spiral():
	var container = $GoldenSpiral
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create Fibonacci spiral using golden ratio
	var spiral_points = []
	var radius = 0.1
	var angle = 0.0
	var center = Vector3.ZERO
	
	for i in range(80):
		# Golden spiral equation
		var current_radius = radius * pow(golden_ratio, angle / (2 * PI))
		var x = cos(angle) * current_radius
		var z = sin(angle) * current_radius
		var y = angle * 0.1  # Slight vertical progression
		
		spiral_points.append(Vector3(x, y, z))
		angle += 0.2
		
		# Create spiral segment
		var spiral_segment = CSGSphere3D.new()
		spiral_segment.radius = 0.05 + sin(time + i * 0.1) * 0.02
		spiral_segment.position = Vector3(x, y, z)
		
		var material = StandardMaterial3D.new()
		var color_phase = float(i) / 80.0
		material.albedo_color = Color.from_hsv(color_phase * 0.6 + 0.1, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(color_phase * 0.6 + 0.1, 0.8, 1.0) * 0.4
		spiral_segment.material_override = material
		
		container.add_child(spiral_segment)
	
	# Connect spiral points
	for i in range(spiral_points.size() - 1):
		var connection = CSGCylinder3D.new()
		connection.radius = 0.02
		
		connection.height = spiral_points[i].distance_to(spiral_points[i + 1])
		
		connection.position = (spiral_points[i] + spiral_points[i + 1]) * 0.5
		connection.look_at_from_position(connection.position, spiral_points[i + 1], Vector3.UP)
		connection.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		var conn_material = StandardMaterial3D.new()
		conn_material.albedo_color = Color(0.8, 0.8, 0.8, 0.6)
		conn_material.flags_transparent = true
		connection.material_override = conn_material
		
		container.add_child(connection)

func show_natural_patterns():
	var container = $NaturalPatterns
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create sunflower seed pattern (Fibonacci spirals)
	create_sunflower_pattern(container, Vector3(-3, 0, 0))
	
	# Create pinecone pattern
	create_pinecone_pattern(container, Vector3(0, 0, 0))
	
	# Create nautilus shell pattern
	create_nautilus_pattern(container, Vector3(3, 0, 0))

func create_sunflower_pattern(container: Node3D, center: Vector3):
	var seed_count = 144  # Fibonacci number
	var golden_angle = 2 * PI / (golden_ratio * golden_ratio)
	
	for i in range(seed_count):
		var angle = i * golden_angle
		var radius = sqrt(i) * 0.1
		
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		var seed = CSGSphere3D.new()
		seed.radius = 0.03
		seed.position = center + Vector3(x, 0, z)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.7, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.9, 0.7, 0.2) * 0.3
		seed.material_override = material
		
		container.add_child(seed)

func create_pinecone_pattern(container: Node3D, center: Vector3):
	var spiral_count = 8  # Fibonacci number
	var layers = 13       # Another Fibonacci number
	
	for layer in range(layers):
		var layer_radius = 0.5 + layer * 0.1
		var layer_height = layer * 0.2
		
		for spiral in range(spiral_count):
			var angle = (float(spiral) / spiral_count) * 2 * PI + layer * 0.3
			var x = cos(angle) * layer_radius
			var z = sin(angle) * layer_radius
			
			var scale = CSGBox3D.new()
			scale.size = Vector3(0.1, 0.15, 0.05)
			scale.position = center + Vector3(x, layer_height, z)
			scale.rotation_degrees = Vector3(0, angle * 57.3, 30)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.6, 0.4, 0.2)
			scale.material_override = material
			
			container.add_child(scale)

func create_nautilus_pattern(container: Node3D, center: Vector3):
	var chambers = 8  # Based on Fibonacci growth
	var growth_rate = golden_ratio
	var initial_radius = 0.1
	
	for chamber in range(chambers):
		var chamber_radius = initial_radius * pow(growth_rate, float(chamber) / 4.0)
		var angle = chamber * PI / 2
		
		var x = cos(angle) * chamber_radius * 0.5
		var z = sin(angle) * chamber_radius * 0.5
		
		var chamber_sphere = CSGSphere3D.new()
		chamber_sphere.radius = chamber_radius
		chamber_sphere.position = center + Vector3(x, 0, z)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.7, 0.9, 0.7)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(0.9, 0.7, 0.9) * 0.2
		chamber_sphere.material_override = material
		
		container.add_child(chamber_sphere)

func demonstrate_recursion():
	var container = $RecursionVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize recursive tree structure
	create_recursive_tree(container, Vector3.ZERO, 0, 5)

func create_recursive_tree(container: Node3D, position: Vector3, depth: int, max_depth: int):
	if depth >= max_depth:
		return
	
	# Create node for current recursion level
	var node = CSGSphere3D.new()
	node.radius = 0.3 * (1.0 - float(depth) / max_depth)
	node.position = position
	
	var material = StandardMaterial3D.new()
	var depth_ratio = float(depth) / max_depth
	material.albedo_color = Color.from_hsv(depth_ratio * 0.3, 0.8, 1.0)
	material.emission_enabled = true
	material.emission = Color.from_hsv(depth_ratio * 0.3, 0.8, 1.0) * 0.4
	node.material_override = material
	
	container.add_child(node)
	
	# Create Fibonacci-based branches
	if depth < max_depth - 1:
		var branch_count = fibonacci_numbers[min(depth + 1, fibonacci_numbers.size() - 1)] % 4 + 1
		var branch_length = 2.0 * (1.0 - float(depth) / max_depth)
		
		for branch in range(branch_count):
			var angle = (float(branch) / branch_count) * 2 * PI + depth * golden_ratio
			var branch_pos = position + Vector3(
				cos(angle) * branch_length,
				-1.5,
				sin(angle) * branch_length
			)
			
			# Create connection
			var connection = CSGCylinder3D.new()
			connection.radius = 0.05
			
			connection.height = position.distance_to(branch_pos)
			
			connection.position = (position + branch_pos) * 0.5
			connection.look_at_from_position(connection.position, branch_pos, Vector3.UP)
			connection.rotate_object_local(Vector3.RIGHT, PI / 2)
			
			var conn_material = StandardMaterial3D.new()
			conn_material.albedo_color = Color(0.6, 0.4, 0.2)
			connection.material_override = conn_material
			
			container.add_child(connection)
			
			# Recursive call
			create_recursive_tree(container, branch_pos, depth + 1, max_depth)

