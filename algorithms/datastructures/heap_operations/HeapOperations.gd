extends Node3D

var time = 0.0
var heap_array = []
var heap_nodes = []
var heap_edges = []
var is_max_heap = true
var operation_timer = 0.0
var operation_interval = 2.5

# Heap operations
enum HeapOperation {
	INSERT,
	EXTRACT_ROOT,
	HEAPIFY_UP,
	HEAPIFY_DOWN,
	BUILD_HEAP,
	SWITCH_TYPE
}

var current_operation = HeapOperation.INSERT

# Heap node visual representation
class HeapNodeVisual:
	var value: int
	var array_index: int
	var visual_object: CSGSphere3D
	var level: int
	var position_in_level: int
	
	func _init(val: int, index: int):
		value = val
		array_index = index

func _ready():
	setup_materials()
	build_initial_heap()

func setup_materials():
	# Heap type indicator material
	var type_material = StandardMaterial3D.new()
	type_material.albedo_color = Color(1.0, 0.6, 0.2, 1.0)
	type_material.emission_enabled = true
	type_material.emission = Color(0.3, 0.15, 0.05, 1.0)
	$HeapTypeIndicator.material_override = type_material
	
	# Operation indicator material
	var op_material = StandardMaterial3D.new()
	op_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	op_material.emission_enabled = true
	op_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$OperationIndicator.material_override = op_material
	
	# Heap size indicator material
	var size_material = StandardMaterial3D.new()
	size_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
	size_material.emission_enabled = true
	size_material.emission = Color(0.2, 0.05, 0.3, 1.0)
	$HeapSizeIndicator.material_override = size_material

func build_initial_heap():
	# Start with some initial values
	var initial_values = [50, 30, 70, 20, 10, 60, 80]
	for value in initial_values:
		heap_array.append(value)
	
	heapify_entire_array()
	rebuild_visual_heap()

func _process(delta):
	time += delta
	operation_timer += delta
	
	if operation_timer >= operation_interval:
		operation_timer = 0.0
		perform_heap_operation()
	
	animate_heap()
	animate_indicators()

func perform_heap_operation():
	current_operation = (current_operation + 1) % HeapOperation.size()
	
	match current_operation:
		HeapOperation.INSERT:
			if heap_array.size() < 15:  # Limit heap size
				var new_value = randi() % 100
				insert_element(new_value)
		
		HeapOperation.EXTRACT_ROOT:
			if heap_array.size() > 3:  # Keep minimum size
				extract_root()
		
		HeapOperation.HEAPIFY_UP:
			if heap_array.size() > 1:
				demonstrate_heapify_up()
		
		HeapOperation.HEAPIFY_DOWN:
			if heap_array.size() > 2:
				demonstrate_heapify_down()
		
		HeapOperation.BUILD_HEAP:
			randomize_and_heapify()
		
		HeapOperation.SWITCH_TYPE:
			switch_heap_type()

func insert_element(value: int):
	heap_array.append(value)
	var index = heap_array.size() - 1
	
	# Create visual node
	var node_visual = HeapNodeVisual.new(value, index)
	create_visual_node(node_visual)
	heap_nodes.append(node_visual)
	
	# Heapify up
	heapify_up(index)
	rebuild_visual_heap()

func extract_root():
	if heap_array.size() == 0:
		return
	
	# Replace root with last element
	heap_array[0] = heap_array[-1]
	heap_array.pop_back()
	
	# Remove visual node
	if heap_nodes.size() > 0:
		heap_nodes[-1].visual_object.queue_free()
		heap_nodes.pop_back()
	
	# Heapify down from root
	if heap_array.size() > 0:
		heapify_down(0)
	
	rebuild_visual_heap()

func heapify_up(index: int):
	while index > 0:
		var parent_index = (index - 1) / 2
		
		var should_swap = false
		if is_max_heap:
			should_swap = heap_array[index] > heap_array[parent_index]
		else:
			should_swap = heap_array[index] < heap_array[parent_index]
		
		if should_swap:
			swap_elements(index, parent_index)
			index = parent_index
		else:
			break

func heapify_down(index: int):
	var size = heap_array.size()
	
	while true:
		var extreme_index = index
		var left_child = 2 * index + 1
		var right_child = 2 * index + 2
		
		# Find the extreme element (max for max-heap, min for min-heap)
		if left_child < size:
			if is_max_heap:
				if heap_array[left_child] > heap_array[extreme_index]:
					extreme_index = left_child
			else:
				if heap_array[left_child] < heap_array[extreme_index]:
					extreme_index = left_child
		
		if right_child < size:
			if is_max_heap:
				if heap_array[right_child] > heap_array[extreme_index]:
					extreme_index = right_child
			else:
				if heap_array[right_child] < heap_array[extreme_index]:
					extreme_index = right_child
		
		if extreme_index != index:
			swap_elements(index, extreme_index)
			index = extreme_index
		else:
			break

func swap_elements(i: int, j: int):
	var temp = heap_array[i]
	heap_array[i] = heap_array[j]
	heap_array[j] = temp

func heapify_entire_array():
	var size = heap_array.size()
	# Start from the last non-leaf node and heapify down
	for i in range(size / 2 - 1, -1, -1):
		heapify_down(i)

func demonstrate_heapify_up():
	# Add element and animate the heapify up process
	if heap_array.size() < 15:
		insert_element(randi() % 100)

func demonstrate_heapify_down():
	# Temporarily mess up the heap property and fix it
	if heap_array.size() > 2:
		# Swap root with a random element
		var random_index = randi() % heap_array.size()
		swap_elements(0, random_index)
		heapify_down(0)
		rebuild_visual_heap()

func randomize_and_heapify():
	# Randomize array and rebuild heap
	for i in range(heap_array.size()):
		heap_array[i] = randi() % 100
	
	heapify_entire_array()
	rebuild_visual_heap()

func switch_heap_type():
	is_max_heap = !is_max_heap
	heapify_entire_array()
	rebuild_visual_heap()

func create_visual_node(node_visual: HeapNodeVisual):
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.25
	
	# Material based on value and heap type
	var node_material = StandardMaterial3D.new()
	var value_intensity = node_visual.value / 100.0
	
	if is_max_heap:
		# Red tones for max heap - brighter for larger values
		node_material.albedo_color = Color(
			0.3 + value_intensity * 0.7,
			0.3,
			0.3,
			1.0
		)
	else:
		# Blue tones for min heap - brighter for smaller values
		node_material.albedo_color = Color(
			0.3,
			0.3,
			0.3 + (1.0 - value_intensity) * 0.7,
			1.0
		)
	
	node_material.emission_enabled = true
	node_material.emission = node_material.albedo_color * 0.4
	sphere.material_override = node_material
	
	$HeapNodes.add_child(sphere)
	node_visual.visual_object = sphere

func rebuild_visual_heap():
	# Update all node values and positions
	for i in range(heap_nodes.size()):
		if i < heap_array.size():
			heap_nodes[i].value = heap_array[i]
			heap_nodes[i].array_index = i
			update_node_material(heap_nodes[i])
	
	calculate_heap_positions()
	update_heap_edges()

func calculate_heap_positions():
	for i in range(heap_nodes.size()):
		var node = heap_nodes[i]
		var level = int(log(i + 1) / log(2))  # Calculate level in binary tree
		var position_in_level = i - (pow(2, level) - 1)  # Position within the level
		var max_positions_in_level = pow(2, level)
		
		# Calculate x position
		var level_width = max_positions_in_level * 1.5
		var x_offset = (position_in_level - (max_positions_in_level - 1) / 2.0) * level_width / max_positions_in_level
		
		# Calculate y position
		var y_position = 2 - level * 1.2
		
		node.visual_object.position = Vector3(x_offset, y_position, 0)
		node.level = level
		node.position_in_level = position_in_level

func update_node_material(node: HeapNodeVisual):
	var sphere = node.visual_object
	var material = sphere.material_override as StandardMaterial3D
	
	if material:
		var value_intensity = node.value / 100.0
		
		if is_max_heap:
			material.albedo_color = Color(
				0.3 + value_intensity * 0.7,
				0.3,
				0.3,
				1.0
			)
		else:
			material.albedo_color = Color(
				0.3,
				0.3,
				0.3 + (1.0 - value_intensity) * 0.7,
				1.0
			)
		
		material.emission = material.albedo_color * 0.4

func update_heap_edges():
	# Clear existing edges
	for edge in heap_edges:
		edge.queue_free()
	heap_edges.clear()
	
	# Create new edges
	for i in range(heap_nodes.size()):
		# Left child
		var left_child_index = 2 * i + 1
		if left_child_index < heap_nodes.size():
			create_heap_edge(i, left_child_index)
		
		# Right child
		var right_child_index = 2 * i + 2
		if right_child_index < heap_nodes.size():
			create_heap_edge(i, right_child_index)

func create_heap_edge(parent_index: int, child_index: int):
	var edge = CSGCylinder3D.new()
	var parent_pos = heap_nodes[parent_index].visual_object.position
	var child_pos = heap_nodes[child_index].visual_object.position
	var distance = parent_pos.distance_to(child_pos)
	
	edge.height = distance
	edge.radius = 0.02
	
	
	# Position and orient edge
	var mid_point = (parent_pos + child_pos) * 0.5
	edge.position = mid_point
	
	# Orient edge
	var direction = (child_pos - parent_pos).normalized()
	if direction != Vector3.UP:
		var axis = Vector3.UP.cross(direction).normalized()
		var angle = acos(Vector3.UP.dot(direction))
		edge.transform.basis = Basis(axis, angle)
	
	# Edge material
	var edge_material = StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
	edge_material.emission_enabled = true
	edge_material.emission = Color(0.2, 0.2, 0.2, 1.0)
	edge.material_override = edge_material
	
	$HeapEdges.add_child(edge)
	heap_edges.append(edge)

func animate_heap():
	match current_operation:
		HeapOperation.INSERT:
			animate_insertion()
		
		HeapOperation.EXTRACT_ROOT:
			animate_extraction()
		
		HeapOperation.HEAPIFY_UP:
			animate_heapify_up_process()
		
		HeapOperation.HEAPIFY_DOWN:
			animate_heapify_down_process()
		
		HeapOperation.BUILD_HEAP:
			animate_heap_building()
		
		HeapOperation.SWITCH_TYPE:
			animate_type_switch()

func animate_insertion():
	# Pulse the last inserted node
	if heap_nodes.size() > 0:
		var last_node = heap_nodes[-1]
		var pulse = 1.0 + sin(time * 8.0) * 0.4
		last_node.visual_object.scale = Vector3.ONE * pulse

func animate_extraction():
	# Pulse the root node
	if heap_nodes.size() > 0:
		var root_node = heap_nodes[0]
		var pulse = 1.0 + sin(time * 6.0) * 0.5
		root_node.visual_object.scale = Vector3.ONE * pulse

func animate_heapify_up_process():
	# Create upward wave effect
	for i in range(heap_nodes.size()):
		var node = heap_nodes[i]
		var level = node.level
		var wave_phase = time * 4.0 - level * 0.5
		var intensity = max(0.0, sin(wave_phase)) * 0.3
		node.visual_object.scale = Vector3.ONE * (1.0 + intensity)

func animate_heapify_down_process():
	# Create downward wave effect
	for i in range(heap_nodes.size()):
		var node = heap_nodes[i]
		var level = node.level
		var wave_phase = time * 4.0 + level * 0.5
		var intensity = max(0.0, sin(wave_phase)) * 0.3
		node.visual_object.scale = Vector3.ONE * (1.0 + intensity)

func animate_heap_building():
	# Random pulsing during build
	for node in heap_nodes:
		var pulse = 1.0 + sin(time * 5.0 + node.value * 0.1) * 0.3
		node.visual_object.scale = Vector3.ONE * pulse

func animate_type_switch():
	# Color transition animation
	for node in heap_nodes:
		var transition_pulse = 1.0 + sin(time * 10.0 + node.array_index) * 0.4
		node.visual_object.scale = Vector3.ONE * transition_pulse

func animate_indicators():
	# Heap type indicator
	var type_text_scale = 1.0 + sin(time * 3.0) * 0.1
	$HeapTypeIndicator.scale = Vector3.ONE * type_text_scale
	
	# Update heap type indicator color
	var type_material = $HeapTypeIndicator.material_override as StandardMaterial3D
	if type_material:
		if is_max_heap:
			type_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
			type_material.emission = Color(0.5, 0.1, 0.1, 1.0)
		else:
			type_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
			type_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	
	# Operation indicator
	var op_height = (current_operation + 1) * 0.2 + 0.3
	var operation_indicator = get_node_or_null("OperationIndicator")
	if operation_indicator and operation_indicator is CSGCylinder3D:
		operation_indicator.height = op_height
		operation_indicator.position.y = 3 + op_height/2
	
	# Heap size indicator
	var size_scale = 1.0 + (heap_array.size() / 15.0) * 0.8
	$HeapSizeIndicator.scale = Vector3.ONE * size_scale
	
	# Pulsing operation indicator
	var op_pulse = 1.0 + sin(time * 4.0) * 0.2
	$OperationIndicator.scale.x = op_pulse
	$OperationIndicator.scale.z = op_pulse
