extends Node3D

# Fenwick Tree (Binary Indexed Tree) Visualization
# Demonstrates efficient prefix sum queries and updates

var time := 0.0
var update_timer := 0.0
var query_timer := 0.0

# Original array and Fenwick tree
var original_array := [3, 2, -1, 6, 5, 4, -3, 3, 7, 2, 3]
var fenwick_tree := []
var current_query_index := 0
var current_update_index := 0
var update_value := 0

func _ready():
	initialize_fenwick_tree()

func _process(delta):
	time += delta
	update_timer += delta
	query_timer += delta
	
	visualize_binary_indexed_tree()
	show_prefix_sum_calculation()
	demonstrate_update_operation()
	show_binary_representation()

func initialize_fenwick_tree():
	var n = original_array.size()
	fenwick_tree.resize(n + 1)  # 1-indexed
	
	# Initialize all elements to 0
	for i in range(n + 1):
		fenwick_tree[i] = 0
	
	# Build the tree by adding each element
	for i in range(n):
		update_fenwick(i + 1, original_array[i])  # Convert to 1-indexed

func update_fenwick(index: int, delta: int):
	while index < fenwick_tree.size():
		fenwick_tree[index] += delta
		index += index & (-index)  # Add LSB

func query_fenwick(index: int) -> int:
	var sum = 0
	while index > 0:
		sum += fenwick_tree[index]
		index -= index & (-index)  # Remove LSB
	return sum

func range_query(left: int, right: int) -> int:
	if left == 1:
		return query_fenwick(right)
	else:
		return query_fenwick(right) - query_fenwick(left - 1)

func visualize_binary_indexed_tree():
	var container = $BinaryIndexedTree
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize Fenwick tree structure
	for i in range(1, fenwick_tree.size()):
		var height = abs(fenwick_tree[i]) * 0.2 + 0.1
		var element = CSGBox3D.new()
		element.size = Vector3(0.8, height, 0.8)
		element.position = Vector3((i - 1) * 1.0 - fenwick_tree.size() * 0.5, height * 0.5, 0)
		
		var material = StandardMaterial3D.new()
		
		# Color based on responsibility range
		var responsibility_bits = count_trailing_zeros(i & (-i))
		var color_intensity = min(responsibility_bits / 4.0, 1.0)
		
		material.albedo_color = Color(0.3 + color_intensity * 0.7, 0.7, 1.0 - color_intensity * 0.5)
		material.emission_enabled = true
		material.emission = Color(0.3 + color_intensity * 0.7, 0.7, 1.0 - color_intensity * 0.5) * 0.2
		material.metallic = 0.3
		material.roughness = 0.4
		
		element.material_override = material
		container.add_child(element)
		
		# Show connections to what this index is responsible for
		show_responsibility_connections(container, i)

func count_trailing_zeros(n: int) -> int:
	if n == 0:
		return 0
	var count = 0
	while (n & 1) == 0:
		n >>= 1
		count += 1
	return count

func show_responsibility_connections(container: Node3D, index: int):
	var lsb = index & (-index)
	var start = index - lsb + 1
	var end = index
	
	# Show range this index covers
	if start != end:
		var connection = CSGCylinder3D.new()
		connection.radius = 0.02
		#
		connection.height = float(end - start + 1) * 1.0
		
		var start_pos = (start - 1) * 1.0 - fenwick_tree.size() * 0.5
		var end_pos = (end - 1) * 1.0 - fenwick_tree.size() * 0.5
		connection.position = Vector3((start_pos + end_pos) * 0.5, -1.0, 0)
		connection.rotation_degrees = Vector3(0, 0, 90)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.0)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.0) * 0.3
		connection.material_override = material
		
		container.add_child(connection)

func show_prefix_sum_calculation():
	var container = $PrefixSums
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update query index periodically
	if query_timer > 2.0:
		query_timer = 0.0
		current_query_index = (current_query_index + 1) % original_array.size()
	
	# Show original array
	for i in range(original_array.size()):
		var height = abs(original_array[i]) * 0.3 + 0.1
		var element = CSGBox3D.new()
		element.size = Vector3(0.6, height, 0.6)
		element.position = Vector3(i * 0.8 - original_array.size() * 0.4, height * 0.5, 0)
		
		var material = StandardMaterial3D.new()
		
		if i <= current_query_index:
			# Part of current prefix sum
			material.albedo_color = Color(0.2, 1.0, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.2, 1.0, 0.2) * 0.4
		else:
			material.albedo_color = Color(0.5, 0.5, 0.5)
		
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
	
	# Show prefix sum result
	var prefix_sum = query_fenwick(current_query_index + 1)  # Convert to 1-indexed
	var result_sphere = CSGSphere3D.new()
	result_sphere.radius = abs(prefix_sum) * 0.1 + 0.2
	result_sphere.position = Vector3(0, 3, 0)
	
	var result_material = StandardMaterial3D.new()
	result_material.albedo_color = Color(1.0, 1.0, 0.0)
	result_material.emission_enabled = true
	result_material.emission = Color(1.0, 1.0, 0.0) * 0.6
	result_sphere.material_override = result_material
	
	container.add_child(result_sphere)

func demonstrate_update_operation():
	var container = $UpdateVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Perform update periodically
	if update_timer > 3.0:
		update_timer = 0.0
		current_update_index = randi() % original_array.size()
		update_value = randi() % 10 - 5  # Random value between -5 and 4
		
		# Update original array and Fenwick tree
		var old_value = original_array[current_update_index]
		original_array[current_update_index] = update_value
		var delta = update_value - old_value
		update_fenwick(current_update_index + 1, delta)  # Convert to 1-indexed
	
	# Show update propagation
	var update_index_1based = current_update_index + 1
	var affected_indices = []
	
	# Find all indices affected by update
	var index = update_index_1based
	while index < fenwick_tree.size():
		affected_indices.append(index)
		index += index & (-index)
	
	# Visualize affected nodes
	for i in range(1, fenwick_tree.size()):
		var height = abs(fenwick_tree[i]) * 0.2 + 0.1
		var element = CSGCylinder3D.new()
		element.radius = 0.3
		#
		element.height = height
		element.position = Vector3((i - 1) * 1.0 - fenwick_tree.size() * 0.5, height * 0.5, 0)
		
		var material = StandardMaterial3D.new()
		
		if i in affected_indices:
			# Affected by update
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.6
		else:
			material.albedo_color = Color(0.5, 1.0, 0.3)
		
		material.metallic = 0.2
		material.roughness = 0.5
		element.material_override = material
		
		container.add_child(element)

func show_binary_representation():
	var container = $BinaryRepresentation
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show binary representation of indices and their LSB
	var display_indices = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	
	for i in range(display_indices.size()):
		var index = display_indices[i]
		var lsb = index & (-index)
		
		# Create index representation
		var index_box = CSGBox3D.new()
		index_box.size = Vector3(0.6, 0.6, 0.6)
		index_box.position = Vector3(i * 0.8 - display_indices.size() * 0.4, 0, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0)
		index_box.material_override = material
		
		container.add_child(index_box)
		
		# Show LSB value
		var lsb_indicator = CSGSphere3D.new()
		lsb_indicator.radius = lsb * 0.1 + 0.1
		lsb_indicator.position = Vector3(i * 0.8 - display_indices.size() * 0.4, 1.5, 0)
		
		var lsb_material = StandardMaterial3D.new()
		lsb_material.albedo_color = Color(1.0, 0.5, 0.0)
		lsb_material.emission_enabled = true
		lsb_material.emission = Color(1.0, 0.5, 0.0) * 0.4
		lsb_indicator.material_override = lsb_material
		
		container.add_child(lsb_indicator)
		
		# Show binary representation visually
		show_binary_bits(container, index, Vector3(i * 0.8 - display_indices.size() * 0.4, -1.5, 0))

func show_binary_bits(container: Node3D, number: int, position: Vector3):
	var bits = []
	var temp = number
	
	# Extract bits (up to 4 bits for visualization)
	for i in range(4):
		bits.append(temp & 1)
		temp >>= 1
	
	# Display bits
	for i in range(bits.size()):
		var bit_cube = CSGBox3D.new()
		bit_cube.size = Vector3(0.15, 0.15, 0.15)
		bit_cube.position = position + Vector3((i - bits.size() * 0.5) * 0.2, 0, 0)
		
		var material = StandardMaterial3D.new()
		if bits[i] == 1:
			material.albedo_color = Color(1.0, 1.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 0.0) * 0.5
		else:
			material.albedo_color = Color(0.3, 0.3, 0.3)
		
		bit_cube.material_override = material
		container.add_child(bit_cube)
