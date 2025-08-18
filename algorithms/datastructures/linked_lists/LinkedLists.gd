extends Node3D

var time = 0.0
var nodes = []
var pointers = []
var max_nodes = 8
var node_spacing = 1.5
var operation_timer = 0.0
var operation_interval = 2.0

# Operations
enum ListOperation {
	INSERT_HEAD,
	INSERT_TAIL,
	DELETE_HEAD,
	DELETE_TAIL,
	TRAVERSE,
	SEARCH
}

var current_operation = ListOperation.INSERT_HEAD
var search_target = 0

# Node data
class ListNode:
	var value: int
	var next_node: ListNode
	var visual_object: CSGSphere3D
	var position_index: int
	
	func _init(val: int):
		value = val
		next_node = null
		position_index = 0

func _ready():
	setup_materials()
	initialize_list()

func setup_materials():
	# Head pointer material
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
	head_material.emission_enabled = true
	head_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$HeadPointer.material_override = head_material
	
	# Operation indicator material
	var op_material = StandardMaterial3D.new()
	op_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	op_material.emission_enabled = true
	op_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$OperationIndicator.material_override = op_material
	
	# List size indicator material
	var size_material = StandardMaterial3D.new()
	size_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	size_material.emission_enabled = true
	size_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$ListSizeIndicator.material_override = size_material

func initialize_list():
	# Start with a few nodes
	for i in range(3):
		insert_at_tail(i + 1)

func _process(delta):
	time += delta
	operation_timer += delta
	
	if operation_timer >= operation_interval:
		operation_timer = 0.0
		perform_next_operation()
	
	animate_list()
	animate_indicators()

func perform_next_operation():
	current_operation = (current_operation + 1) % ListOperation.size()
	
	match current_operation:
		ListOperation.INSERT_HEAD:
			if nodes.size() < max_nodes:
				var new_value = randi() % 100
				insert_at_head(new_value)
		
		ListOperation.INSERT_TAIL:
			if nodes.size() < max_nodes:
				var new_value = randi() % 100
				insert_at_tail(new_value)
		
		ListOperation.DELETE_HEAD:
			if nodes.size() > 1:
				delete_head()
		
		ListOperation.DELETE_TAIL:
			if nodes.size() > 1:
				delete_tail()
		
		ListOperation.TRAVERSE:
			animate_traversal()
		
		ListOperation.SEARCH:
			if nodes.size() > 0:
				search_target = nodes[randi() % nodes.size()].value
				animate_search(search_target)

func insert_at_head(value: int):
	var new_node = ListNode.new(value)
	create_visual_node(new_node)
	
	if nodes.size() > 0:
		new_node.next_node = nodes[0]
	
	nodes.insert(0, new_node)
	update_node_positions()
	update_pointers()

func insert_at_tail(value: int):
	var new_node = ListNode.new(value)
	create_visual_node(new_node)
	
	if nodes.size() > 0:
		nodes[-1].next_node = new_node
	
	nodes.append(new_node)
	update_node_positions()
	update_pointers()

func delete_head():
	if nodes.size() == 0:
		return
	
	var head_node = nodes[0]
	head_node.visual_object.queue_free()
	nodes.erase(head_node)
	
	update_node_positions()
	update_pointers()

func delete_tail():
	if nodes.size() == 0:
		return
	
	var tail_node = nodes[-1]
	tail_node.visual_object.queue_free()
	nodes.erase(tail_node)
	
	# Update the new tail's next pointer
	if nodes.size() > 0:
		nodes[-1].next_node = null
	
	update_node_positions()
	update_pointers()

func create_visual_node(node: ListNode):
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.4
	
	# Node material based on value
	var node_material = StandardMaterial3D.new()
	var color_intensity = (node.value % 100) / 100.0
	node_material.albedo_color = Color(
		0.3 + color_intensity * 0.7,
		0.3 + (1.0 - color_intensity) * 0.7,
		0.8,
		1.0
	)
	node_material.emission_enabled = true
	node_material.emission = node_material.albedo_color * 0.3
	sphere.material_override = node_material
	
	$ListNodes.add_child(sphere)
	node.visual_object = sphere

func update_node_positions():
	for i in range(nodes.size()):
		var node = nodes[i]
		node.position_index = i
		var target_position = Vector3(-6 + i * node_spacing, 0, 0)
		node.visual_object.position = target_position

func update_pointers():
	# Clear existing pointers
	for child in $ListPointers.get_children():
		child.queue_free()
	pointers.clear()
	
	# Create new pointers
	for i in range(nodes.size() - 1):
		create_pointer(i, i + 1)
	
	# Update head pointer position
	if nodes.size() > 0:
		$HeadPointer.position = Vector3(-6 + 0 * node_spacing, 1.5, 0)
	else:
		$HeadPointer.position = Vector3(-6, 1.5, 0)

func create_pointer(from_index: int, to_index: int):
	var pointer = CSGCylinder3D.new()
	pointer.top_radius = 0.05
	pointer.bottom_radius = 0.05
	pointer.height = node_spacing * 0.8
	
	# Position between nodes
	var start_pos = Vector3(-6 + from_index * node_spacing + 0.4, 0, 0)
	var end_pos = Vector3(-6 + to_index * node_spacing - 0.4, 0, 0)
	pointer.position = (start_pos + end_pos) * 0.5
	pointer.rotation_degrees = Vector3(0, 0, 90)
	
	# Pointer material
	var pointer_material = StandardMaterial3D.new()
	pointer_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	pointer_material.emission_enabled = true
	pointer_material.emission = Color(0.2, 0.2, 0.05, 1.0)
	pointer.material_override = pointer_material
	
	$ListPointers.add_child(pointer)
	pointers.append(pointer)

func animate_traversal():
	# This will be handled in the animate_list function
	pass

func animate_search(target_value: int):
	# This will be handled in the animate_list function
	pass

func animate_list():
	# Animate node pulsing based on operation
	for i in range(nodes.size()):
		var node = nodes[i]
		var base_scale = 1.0
		var pulse_intensity = 0.0
		
		match current_operation:
			ListOperation.TRAVERSE:
				# Wave effect for traversal
				var wave_phase = time * 3.0 - i * 0.5
				pulse_intensity = max(0.0, sin(wave_phase)) * 0.3
			
			ListOperation.SEARCH:
				# Highlight matching nodes
				if node.value == search_target:
					pulse_intensity = sin(time * 8.0) * 0.5 + 0.5
				else:
					pulse_intensity = 0.1
			
			ListOperation.INSERT_HEAD, ListOperation.DELETE_HEAD:
				# Highlight head
				if i == 0:
					pulse_intensity = sin(time * 6.0) * 0.3 + 0.3
			
			ListOperation.INSERT_TAIL, ListOperation.DELETE_TAIL:
				# Highlight tail
				if i == nodes.size() - 1:
					pulse_intensity = sin(time * 6.0) * 0.3 + 0.3
		
		var scale_factor = base_scale + pulse_intensity
		node.visual_object.scale = Vector3.ONE * scale_factor
	
	# Animate pointers
	for pointer in pointers:
		var pointer_pulse = 1.0 + sin(time * 4.0 + pointer.position.x) * 0.1
		pointer.scale = Vector3(pointer_pulse, 1.0, pointer_pulse)
	
	# Animate head pointer
	var head_pulse = 1.0 + sin(time * 5.0) * 0.2
	$HeadPointer.scale = Vector3.ONE * head_pulse

func animate_indicators():
	# Operation indicator
	var op_height = (current_operation + 1) * 0.3
	$OperationIndicator.size.y = op_height
	$OperationIndicator.position.y = -3 + op_height/2
	
	# List size indicator
	var size_height = nodes.size() * 0.2 + 0.5
	$ListSizeIndicator.size.y = size_height
	$ListSizeIndicator.position.y = -3 + size_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 3.0) * 0.1
	$OperationIndicator.scale.x = pulse
	$ListSizeIndicator.scale.x = pulse

func get_operation_name() -> String:
	match current_operation:
		ListOperation.INSERT_HEAD:
			return "Insert Head"
		ListOperation.INSERT_TAIL:
			return "Insert Tail"
		ListOperation.DELETE_HEAD:
			return "Delete Head"
		ListOperation.DELETE_TAIL:
			return "Delete Tail"
		ListOperation.TRAVERSE:
			return "Traverse"
		ListOperation.SEARCH:
			return "Search"
		_:
			return "Unknown"
