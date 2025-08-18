extends Node3D

var time = 0.0
var tree_operation_timer = 0.0
var tree_operation_interval = 3.0
var traversal_step = 0
var traversal_timer = 0.0
var traversal_interval = 0.5

# Tree operations
enum TreeOperation {
	INSERT,
	DELETE,
	INORDER_TRAVERSAL,
	PREORDER_TRAVERSAL,
	POSTORDER_TRAVERSAL,
	SEARCH
}

var current_operation = TreeOperation.INSERT
var search_target = 0
var traversal_order = []
var current_traversal_index = 0

# Tree node class
class TreeNode:
	var value: int
	var left_child: TreeNode
	var right_child: TreeNode
	var parent: TreeNode
	var visual_object: CSGSphere3D
	var level: int
	var position_in_level: int
	
	func _init(val: int):
		value = val
		left_child = null
		right_child = null
		parent = null
		level = 0
		position_in_level = 0

var root: TreeNode = null
var all_nodes = []
var tree_edges = []

func _ready():
	setup_materials()
	build_initial_tree()

func setup_materials():
	# Root marker material
	var root_material = StandardMaterial3D.new()
	root_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
	root_material.emission_enabled = true
	root_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$RootMarker.material_override = root_material
	
	# Traversal indicator material
	var traversal_material = StandardMaterial3D.new()
	traversal_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	traversal_material.emission_enabled = true
	traversal_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$TraversalIndicator.material_override = traversal_material
	
	# Height indicator material
	var height_material = StandardMaterial3D.new()
	height_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	height_material.emission_enabled = true
	height_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$HeightIndicator.material_override = height_material

func build_initial_tree():
	# Build a sample binary search tree
	var values = [50, 30, 70, 20, 40, 60, 80]
	for value in values:
		insert_node(value)

func _process(delta):
	time += delta
	tree_operation_timer += delta
	traversal_timer += delta
	
	# Switch operations
	if tree_operation_timer >= tree_operation_interval:
		tree_operation_timer = 0.0
		switch_operation()
	
	# Handle traversal animation
	if current_operation >= TreeOperation.INORDER_TRAVERSAL and current_operation <= TreeOperation.POSTORDER_TRAVERSAL:
		if traversal_timer >= traversal_interval:
			traversal_timer = 0.0
			advance_traversal()
	
	animate_tree()
	animate_indicators()

func switch_operation():
	current_operation = (current_operation + 1) % TreeOperation.size()
	
	match current_operation:
		TreeOperation.INSERT:
			var new_value = randi() % 100
			insert_node(new_value)
		
		TreeOperation.DELETE:
			if all_nodes.size() > 3:  # Keep minimum tree size
				var random_node = all_nodes[randi() % all_nodes.size()]
				delete_node(random_node.value)
		
		TreeOperation.INORDER_TRAVERSAL:
			start_traversal("inorder")
		
		TreeOperation.PREORDER_TRAVERSAL:
			start_traversal("preorder")
		
		TreeOperation.POSTORDER_TRAVERSAL:
			start_traversal("postorder")
		
		TreeOperation.SEARCH:
			if all_nodes.size() > 0:
				search_target = all_nodes[randi() % all_nodes.size()].value
				start_search(search_target)

func insert_node(value: int):
	if root == null:
		root = TreeNode.new(value)
		create_visual_node(root)
		all_nodes.append(root)
	else:
		var new_node = TreeNode.new(value)
		insert_recursive(root, new_node)
		create_visual_node(new_node)
		all_nodes.append(new_node)
	
	calculate_positions()
	update_edges()

func insert_recursive(current: TreeNode, new_node: TreeNode):
	if new_node.value < current.value:
		if current.left_child == null:
			current.left_child = new_node
			new_node.parent = current
		else:
			insert_recursive(current.left_child, new_node)
	else:
		if current.right_child == null:
			current.right_child = new_node
			new_node.parent = current
		else:
			insert_recursive(current.right_child, new_node)

func delete_node(value: int):
	var node_to_delete = find_node(root, value)
	if node_to_delete:
		delete_node_recursive(node_to_delete)
		all_nodes.erase(node_to_delete)
		node_to_delete.visual_object.queue_free()
		calculate_positions()
		update_edges()

func delete_node_recursive(node: TreeNode):
	# Simplified deletion - just remove leaf nodes or nodes with one child
	if node.left_child == null and node.right_child == null:
		# Leaf node
		if node.parent:
			if node.parent.left_child == node:
				node.parent.left_child = null
			else:
				node.parent.right_child = null
	elif node.left_child == null:
		# Only right child
		if node.parent:
			if node.parent.left_child == node:
				node.parent.left_child = node.right_child
			else:
				node.parent.right_child = node.right_child
			node.right_child.parent = node.parent
		else:
			root = node.right_child
			root.parent = null
	elif node.right_child == null:
		# Only left child
		if node.parent:
			if node.parent.left_child == node:
				node.parent.left_child = node.left_child
			else:
				node.parent.right_child = node.left_child
			node.left_child.parent = node.parent
		else:
			root = node.left_child
			root.parent = null

func find_node(current: TreeNode, value: int) -> TreeNode:
	if current == null:
		return null
	
	if current.value == value:
		return current
	elif value < current.value:
		return find_node(current.left_child, value)
	else:
		return find_node(current.right_child, value)

func create_visual_node(node: TreeNode):
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.3
	
	# Node material based on value
	var node_material = StandardMaterial3D.new()
	var color_intensity = (node.value % 100) / 100.0
	node_material.albedo_color = Color(
		0.8,
		0.3 + color_intensity * 0.7,
		0.3 + (1.0 - color_intensity) * 0.7,
		1.0
	)
	node_material.emission_enabled = true
	node_material.emission = node_material.albedo_color * 0.3
	sphere.material_override = node_material
	
	$TreeNodes.add_child(sphere)
	node.visual_object = sphere

func calculate_positions():
	if root == null:
		return
	
	# Calculate level and position for each node
	calculate_node_levels(root, 0)
	
	# Position nodes based on level and position
	for node in all_nodes:
		var x_offset = (node.position_in_level - get_level_center(node.level)) * 2.0
		var y_position = 3 - node.level * 1.5
		var z_position = 0
		
		node.visual_object.position = Vector3(x_offset, y_position, z_position)
	
	# Update root marker
	if root:
		$RootMarker.position = Vector3(root.visual_object.position.x, root.visual_object.position.y + 1, 0)

func calculate_node_levels(node: TreeNode, level: int):
	node.level = level
	
	# Calculate position in level using inorder traversal
	var level_nodes = get_nodes_at_level(level)
	for i in range(level_nodes.size()):
		level_nodes[i].position_in_level = i
	
	if node.left_child:
		calculate_node_levels(node.left_child, level + 1)
	if node.right_child:
		calculate_node_levels(node.right_child, level + 1)

func get_nodes_at_level(level: int) -> Array:
	var level_nodes = []
	for node in all_nodes:
		if node.level == level:
			level_nodes.append(node)
	
	# Sort by value for consistent positioning
	level_nodes.sort_custom(func(a, b): return a.value < b.value)
	return level_nodes

func get_level_center(level: int) -> float:
	var level_nodes = get_nodes_at_level(level)
	return (level_nodes.size() - 1) / 2.0

func update_edges():
	# Clear existing edges
	for edge in tree_edges:
		edge.queue_free()
	tree_edges.clear()
	
	# Create new edges
	for node in all_nodes:
		if node.left_child:
			create_edge(node, node.left_child)
		if node.right_child:
			create_edge(node, node.right_child)

func create_edge(parent: TreeNode, child: TreeNode):
	var edge = CSGCylinder3D.new()
	var distance = parent.visual_object.position.distance_to(child.visual_object.position)
	
	edge.height = distance
	edge.top_radius = 0.03
	edge.bottom_radius = 0.03
	
	# Position and orient edge
	var mid_point = (parent.visual_object.position + child.visual_object.position) * 0.5
	edge.position = mid_point
	
	# Orient edge
	var direction = (child.visual_object.position - parent.visual_object.position).normalized()
	if direction != Vector3.UP:
		var axis = Vector3.UP.cross(direction).normalized()
		var angle = acos(Vector3.UP.dot(direction))
		edge.transform.basis = Basis(axis, angle)
	
	# Edge material
	var edge_material = StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.6, 0.6, 0.6, 1.0)
	edge_material.emission_enabled = true
	edge_material.emission = Color(0.2, 0.2, 0.2, 1.0)
	edge.material_override = edge_material
	
	$TreeEdges.add_child(edge)
	tree_edges.append(edge)

func start_traversal(type: String):
	traversal_order.clear()
	current_traversal_index = 0
	
	match type:
		"inorder":
			inorder_traversal(root)
		"preorder":
			preorder_traversal(root)
		"postorder":
			postorder_traversal(root)

func inorder_traversal(node: TreeNode):
	if node == null:
		return
	
	inorder_traversal(node.left_child)
	traversal_order.append(node)
	inorder_traversal(node.right_child)

func preorder_traversal(node: TreeNode):
	if node == null:
		return
	
	traversal_order.append(node)
	preorder_traversal(node.left_child)
	preorder_traversal(node.right_child)

func postorder_traversal(node: TreeNode):
	if node == null:
		return
	
	postorder_traversal(node.left_child)
	postorder_traversal(node.right_child)
	traversal_order.append(node)

func advance_traversal():
	if current_traversal_index < traversal_order.size():
		current_traversal_index += 1
	else:
		current_traversal_index = 0  # Reset for loop

func start_search(target: int):
	# Search will be animated in animate_tree()
	pass

func animate_tree():
	# Reset all node scales
	for node in all_nodes:
		node.visual_object.scale = Vector3.ONE
	
	match current_operation:
		TreeOperation.INORDER_TRAVERSAL, TreeOperation.PREORDER_TRAVERSAL, TreeOperation.POSTORDER_TRAVERSAL:
			animate_traversal_highlighting()
		
		TreeOperation.SEARCH:
			animate_search_highlighting()
		
		TreeOperation.INSERT:
			animate_insert_highlighting()
		
		TreeOperation.DELETE:
			animate_delete_highlighting()

func animate_traversal_highlighting():
	# Highlight visited nodes
	for i in range(min(current_traversal_index, traversal_order.size())):
		var node = traversal_order[i]
		var intensity = 1.0 - (current_traversal_index - i - 1) * 0.2
		intensity = max(0.3, intensity)
		node.visual_object.scale = Vector3.ONE * (1.0 + intensity * 0.5)
		
		# Update material emission
		var material = node.visual_object.material_override as StandardMaterial3D
		if material:
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func animate_search_highlighting():
	# Animate search path
	var current_node = root
	var search_path = []
	
	# Build search path
	while current_node:
		search_path.append(current_node)
		if current_node.value == search_target:
			break
		elif search_target < current_node.value:
			current_node = current_node.left_child
		else:
			current_node = current_node.right_child
	
	# Animate path
	var wave_progress = fmod(time * 2.0, search_path.size())
	for i in range(search_path.size()):
		var node = search_path[i]
		var distance_from_wave = abs(i - wave_progress)
		var intensity = max(0.0, 1.0 - distance_from_wave)
		node.visual_object.scale = Vector3.ONE * (1.0 + intensity * 0.8)

func animate_insert_highlighting():
	# Pulse all nodes
	var pulse = 1.0 + sin(time * 4.0) * 0.2
	for node in all_nodes:
		node.visual_object.scale = Vector3.ONE * pulse

func animate_delete_highlighting():
	# Different pulse for delete
	var pulse = 1.0 + sin(time * 6.0) * 0.15
	for node in all_nodes:
		node.visual_object.scale = Vector3.ONE * pulse

func animate_indicators():
	# Traversal indicator
	var traversal_height = (current_operation + 1) * 0.3
	$TraversalIndicator.size.y = traversal_height
	$TraversalIndicator.position.y = -4 + traversal_height/2
	
	# Height indicator (tree height)
	var tree_height = get_tree_height()
	var height_indicator_height = tree_height * 0.4 + 0.5
	$HeightIndicator.size.y = height_indicator_height
	$HeightIndicator.position.y = -4 + height_indicator_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 3.0) * 0.1
	$TraversalIndicator.scale.x = pulse
	$HeightIndicator.scale.x = pulse

func get_tree_height() -> int:
	if root == null:
		return 0
	
	var max_level = 0
	for node in all_nodes:
		max_level = max(max_level, node.level)
	
	return max_level + 1
