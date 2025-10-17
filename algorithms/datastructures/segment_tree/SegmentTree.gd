extends Node3D

# Segment Tree Visualization
# Demonstrates range query optimization with segment trees

var time := 0.0
var query_timer := 0.0
var update_timer := 0.0

# Segment tree data
var array_data := [3, 2, 8, 6, 1, 4, 9, 5]
var segment_tree := []
var tree_size := 0

# Query and update state
var query_left := 0
var query_right := 3
var update_index := 0
var update_value := 0

func _ready():
	# Create necessary containers if they don't exist
	ensure_containers_exist()
	build_segment_tree()
	tree_size = segment_tree.size()

func _process(delta):
	time += delta
	query_timer += delta
	update_timer += delta
	
	animate_tree_structure()
	show_array_representation()
	demonstrate_range_queries()
	show_update_operations()

func ensure_containers_exist():
	"""Ensure all required containers exist in the scene"""
	var containers = ["TreeStructure", "ArrayRepresentation", "RangeQueries", "UpdateOperations"]
	
	for container_name in containers:
		if not get_node_or_null(container_name):
			var container = Node3D.new()
			container.name = container_name
			add_child(container)

func build_segment_tree():
	var n = array_data.size()
	segment_tree.resize(4 * n)  # Segment tree needs 4n space
	build_tree(0, 0, n - 1)

func build_tree(node: int, start: int, end: int):
	if start == end:
		# Leaf node
		segment_tree[node] = array_data[start]
	else:
		var mid = (start + end) / 2
		var left_child = 2 * node + 1
		var right_child = 2 * node + 2
		
		build_tree(left_child, start, mid)
		build_tree(right_child, mid + 1, end)
		
		# Internal node stores sum of children
		segment_tree[node] = segment_tree[left_child] + segment_tree[right_child]

func range_query(node: int, start: int, end: int, left: int, right: int) -> int:
	if right < start or end < left:
		return 0  # No overlap
	
	if left <= start and end <= right:
		return segment_tree[node]  # Complete overlap
	
	# Partial overlap
	var mid = (start + end) / 2
	var left_child = 2 * node + 1
	var right_child = 2 * node + 2
	
	var left_sum = range_query(left_child, start, mid, left, right)
	var right_sum = range_query(right_child, mid + 1, end, left, right)
	
	return left_sum + right_sum

func update_tree(node: int, start: int, end: int, index: int, value: int):
	if start == end:
		# Leaf node
		array_data[index] = value
		segment_tree[node] = value
	else:
		var mid = (start + end) / 2
		var left_child = 2 * node + 1
		var right_child = 2 * node + 2
		
		if index <= mid:
			update_tree(left_child, start, mid, index, value)
		else:
			update_tree(right_child, mid + 1, end, index, value)
		
		# Update internal node
		segment_tree[node] = segment_tree[left_child] + segment_tree[right_child]

func animate_tree_structure():
	var container = get_node_or_null("TreeStructure")
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Calculate tree layout
	var levels = get_tree_height()
	var max_width = 1 << (levels - 1)  # 2^(levels-1)
	
	create_tree_nodes(container, 0, 0, 0, levels, max_width * 2.0)

func get_tree_height() -> int:
	var n = array_data.size()
	var height = 0
	while (1 << height) < n:
		height += 1
	return height + 1

func create_tree_nodes(container: Node3D, node_index: int, level: int, position_index: int, max_levels: int, total_width: float):
	if node_index >= segment_tree.size() or segment_tree[node_index] == 0:
		return
	
	var level_width = total_width / (1 << level)
	var x_pos = -total_width / 2 + position_index * level_width + level_width / 2
	var y_pos = (max_levels - level - 1) * 2.0
	
	# Create node
	var node = CSGSphere3D.new()
	node.radius = 0.4
	node.position = Vector3(x_pos, y_pos, 0)
	
	var material = StandardMaterial3D.new()
	if level == max_levels - 1:
		# Leaf nodes (original array elements)
		material.albedo_color = Color(0.2, 1.0, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.06, 0.3, 0.06)
		material.emission_energy = 1.0
	else:
		# Internal nodes (aggregate values)
		# FIXED: Ensure max_levels is not zero to avoid division by zero
		var depth_ratio = 0.0
		if max_levels > 0:
			depth_ratio = float(level) / float(max_levels)
		
		material.albedo_color = Color(1.0 - depth_ratio, 0.5, depth_ratio)
		material.emission_enabled = true
		material.emission = Color(1.0 - depth_ratio, 0.5, depth_ratio)
		material.emission_energy = 0.2
	
	material.metallic = 0.3
	material.roughness = 0.4
	node.material_override = material
	
	container.add_child(node)
	
	# Add value label (small cube above node)
	var label = CSGBox3D.new()
	label.size = Vector3(0.3, 0.3, 0.3)
	label.position = Vector3(x_pos, y_pos + 0.8, 0)
	
	var label_material = StandardMaterial3D.new()
	# FIXED: Ensure proper float casting and range checking
	var value_ratio = 0.0
	if segment_tree[node_index] != null and segment_tree[node_index] > 0:
		value_ratio = clamp(float(segment_tree[node_index]) / 40.0, 0.0, 1.0)
	
	label_material.albedo_color = Color(value_ratio, 1.0 - value_ratio, 0.5)
	label_material.emission_enabled = true
	label_material.emission = Color(value_ratio, 1.0 - value_ratio, 0.5)
	label_material.emission_energy = 0.4
	label.material_override = label_material
	
	container.add_child(label)
	
	# Create children
	var left_child = 2 * node_index + 1
	var right_child = 2 * node_index + 2
	
	if left_child < segment_tree.size() and segment_tree[left_child] != null and segment_tree[left_child] != 0:
		# Create connection to left child
		var left_child_x = -total_width / 2 + (position_index * 2) * (level_width / 2) + (level_width / 4)
		var left_child_y = y_pos - 2.0
		create_tree_connection(container, Vector3(x_pos, y_pos, 0), Vector3(left_child_x, left_child_y, 0))
		
		create_tree_nodes(container, left_child, level + 1, position_index * 2, max_levels, total_width)
	
	if right_child < segment_tree.size() and segment_tree[right_child] != null and segment_tree[right_child] != 0:
		# Create connection to right child
		var right_child_x = -total_width / 2 + (position_index * 2 + 1) * (level_width / 2) + (level_width / 4)
		var right_child_y = y_pos - 2.0
		create_tree_connection(container, Vector3(x_pos, y_pos, 0), Vector3(right_child_x, right_child_y, 0))
		
		create_tree_nodes(container, right_child, level + 1, position_index * 2 + 1, max_levels, total_width)

func create_tree_connection(container: Node3D, from: Vector3, to: Vector3):
	var distance = from.distance_to(to)
	var connection = CSGCylinder3D.new()
	# FIXED: Use proper Godot 4 CSGCylinder3D properties
	connection.radius = 0.05
	connection.height = distance
	
	connection.position = (from + to) * 0.5
	connection.look_at_from_position(connection.position, to, Vector3.UP)
	connection.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7)
	connection.material_override = material
	
	container.add_child(connection)

func show_array_representation():
	var container = get_node_or_null("ArrayRepresentation")
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show original array
	for i in range(array_data.size()):
		var element = CSGBox3D.new()
		element.size = Vector3(0.8, array_data[i] * 0.3, 0.8)
		element.position = Vector3(i * 1.0 - array_data.size() * 0.5, array_data[i] * 0.15, 0)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0)
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
		
		# Add index label
		var index_label = CSGSphere3D.new()
		index_label.radius = 0.1
		index_label.position = Vector3(i * 1.0 - array_data.size() * 0.5, -1.0, 0)
		
		var index_material = StandardMaterial3D.new()
		index_material.albedo_color = Color(1.0, 1.0, 0.0)
		index_material.emission_enabled = true
		index_material.emission = Color(0.4, 0.4, 0.0)
		index_material.emission_energy = 1.0
		index_label.material_override = index_material
		
		container.add_child(index_label)

func demonstrate_range_queries():
	var container = get_node_or_null("RangeQueries")
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update query range periodically
	if query_timer > 2.0:
		query_timer = 0.0
		query_left = randi() % array_data.size()
		query_right = query_left + randi() % (array_data.size() - query_left)
	
	# Visualize query range
	for i in range(array_data.size()):
		var element = CSGBox3D.new()
		element.size = Vector3(0.6, 0.6, 0.6)
		element.position = Vector3(i * 0.8 - array_data.size() * 0.4, 0, 0)
		
		var material = StandardMaterial3D.new()
		
		if i >= query_left and i <= query_right:
			# In query range
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(0.5, 0.1, 0.1)
			material.emission_energy = 1.0
		else:
			# Outside query range
			material.albedo_color = Color(0.5, 0.5, 0.5)
		
		material.metallic = 0.3
		material.roughness = 0.4
		element.material_override = material
		
		container.add_child(element)
	
	# Show query result
	var query_result = range_query(0, 0, array_data.size() - 1, query_left, query_right)
	
	var result_display = CSGSphere3D.new()
	result_display.radius = max(0.1, query_result * 0.1)  # Ensure minimum radius
	result_display.position = Vector3(0, 3, 0)
	
	var result_material = StandardMaterial3D.new()
	result_material.albedo_color = Color(0.0, 1.0, 0.0)
	result_material.emission_enabled = true
	result_material.emission = Color(0.0, 0.6, 0.0)
	result_material.emission_energy = 1.0
	result_display.material_override = result_material
	
	container.add_child(result_display)

func show_update_operations():
	var container = get_node_or_null("UpdateOperations")
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update element periodically
	if update_timer > 3.0:
		update_timer = 0.0
		update_index = randi() % array_data.size()
		update_value = randi() % 10 + 1
		
		# Perform update
		update_tree(0, 0, array_data.size() - 1, update_index, update_value)
	
	# Visualize update operation
	for i in range(array_data.size()):
		var element = CSGCylinder3D.new()
		element.radius = 0.3
		element.height = array_data[i] * 0.3
		element.position = Vector3(i * 0.8 - array_data.size() * 0.4, array_data[i] * 0.15, 0)
		
		var material = StandardMaterial3D.new()
		
		if i == update_index:
			# Element being updated
			material.albedo_color = Color(1.0, 1.0, 0.0)
			material.emission_enabled = true
			material.emission = Color(0.6, 0.6, 0.0)
			material.emission_energy = 1.0
		else:
			material.albedo_color = Color(0.5, 1.0, 0.3)
		
		material.metallic = 0.2
		material.roughness = 0.5
		element.material_override = material
		
		container.add_child(element)
	
	# Show update propagation effect
	var propagation_effect = CSGSphere3D.new()
	propagation_effect.radius = 0.5 + sin(time * 4) * 0.2
	propagation_effect.position = Vector3(update_index * 0.8 - array_data.size() * 0.4, 2, 0)
	
	var effect_material = StandardMaterial3D.new()
	effect_material.albedo_color = Color(1.0, 0.0, 1.0, 0.6)
	# FIXED: Use proper Godot 4 transparency system
	effect_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect_material.emission_enabled = true
	effect_material.emission = Color(0.4, 0.0, 0.4)
	effect_material.emission_energy = 1.0
	propagation_effect.material_override = effect_material
	
	container.add_child(propagation_effect)
