class_name RedBlackTreeVisualization
extends Node3D

# Red-Black Tree: Self-Balancing Binary Democracy & Color Politics
# Visualizes self-balancing binary search trees, rotation operations, color properties
# Explores algorithmic justice and balanced representation in tree structures

@export_category("Red-Black Tree Configuration")
@export var auto_balance: bool = true
@export var show_color_properties: bool = true
@export var show_rotation_animations: bool = true
@export var validate_properties: bool = true
@export var demo_dataset_size: int = 15

@export_category("Operation Settings")
@export var insertion_mode: String = "random"  # sequential, random, balanced
@export var deletion_mode: String = "leaf_first"  # leaf_first, random, root_first
@export var search_highlight: bool = true
@export var show_search_path: bool = true
@export var animate_recoloring: bool = true

@export_category("Balancing Visualization")
@export var show_rotation_steps: bool = true
@export var highlight_violations: bool = true
@export var show_balance_metrics: bool = true
@export var rotation_speed: float = 1.0
@export var color_change_duration: float = 0.8

@export_category("Tree Layout")
@export var node_spacing_x: float = 2.0
@export var level_spacing_y: float = 2.5
@export var max_tree_width: float = 20.0
@export var tree_centering: bool = true
@export var dynamic_spacing: bool = true

@export_category("Animation")
@export var auto_demo: bool = true
@export var operation_delay: float = 1.5
@export var step_by_step_mode: bool = true
@export var rotation_animation_duration: float = 1.2
@export var highlight_duration: float = 2.0

@export_category("Educational Features")
@export var show_property_violations: bool = true
@export var explain_rotations: bool = true
@export var compare_with_bst: bool = false
@export var performance_analysis: bool = true

# Colors for visualization (Red-Black Tree specific)
@export var red_node_color: Color = Color(0.9, 0.2, 0.2, 1.0)       # Red nodes
@export var black_node_color: Color = Color(0.2, 0.2, 0.2, 1.0)     # Black nodes
@export var nil_node_color: Color = Color(0.1, 0.1, 0.1, 0.3)       # NIL nodes
@export var violation_color: Color = Color(1.0, 0.6, 0.0, 1.0)      # Violations
@export var rotation_color: Color = Color(0.2, 0.8, 0.9, 1.0)       # Rotation highlight
@export var search_path_color: Color = Color(0.9, 0.2, 0.9, 1.0)    # Search path
@export var new_node_color: Color = Color(0.2, 0.9, 0.2, 1.0)       # Newly inserted

# Red-Black Tree node colors
enum NodeColor {
	RED,
	BLACK
}

# Red-Black Tree node structure
class RBNode:
	var value: int = 0
	var color: NodeColor = NodeColor.RED
	var left: RBNode = null
	var right: RBNode = null
	var parent: RBNode = null
	var position: Vector3 = Vector3.ZERO
	var mesh_instance: MeshInstance3D = null
	var is_nil: bool = false  # Sentinel NIL nodes
	
	func _init(val: int = 0, node_color: NodeColor = NodeColor.RED):
		value = val
		color = node_color
	
	func is_red() -> bool:
		return color == NodeColor.RED and not is_nil
	
	func is_black() -> bool:
		return color == NodeColor.BLACK or is_nil
	
	func is_leaf() -> bool:
		return (left == null or left.is_nil) and (right == null or right.is_nil)
	
	func get_uncle() -> RBNode:
		if not parent or not parent.parent:
			return null
		
		var grandparent = parent.parent
		if parent == grandparent.left:
			return grandparent.right
		else:
			return grandparent.left
	
	func get_sibling() -> RBNode:
		if not parent:
			return null
		
		if self == parent.left:
			return parent.right
		else:
			return parent.left

# Tree structure
var root: RBNode = null
var nil_node: RBNode = null  # Sentinel NIL node
var tree_size: int = 0
var tree_height: int = 0
var black_height: int = 0

# Operation tracking
var current_operation: String = ""
var insertions_count: int = 0
var deletions_count: int = 0
var rotations_count: int = 0
var recolorings_count: int = 0
var property_violations: Array = []

# Animation state
var animation_queue: Array = []
var current_animation: Dictionary = {}
var is_animating: bool = false

# Visualization elements
var node_meshes: Array = []
var connection_meshes: Array = []
var ui_display: CanvasLayer
var operation_timer: Timer

# Demo data
var demo_values: Array = []
var current_demo_index: int = 0
var search_path: Array = []

func _init():
	name = "RedBlackTree_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	initialize_tree()
	
	if auto_demo:
		call_deferred("start_demo")

func setup_ui():
	"""Create comprehensive UI for Red-Black Tree visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(600, 1000)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for Red-Black Tree information
	for i in range(40):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup timer for step-by-step operations"""
	operation_timer = Timer.new()
	operation_timer.wait_time = operation_delay
	operation_timer.timeout.connect(_on_operation_timer_timeout)
	add_child(operation_timer)

func initialize_tree():
	"""Initialize empty Red-Black Tree with NIL sentinel"""
	# Create NIL sentinel node (always black)
	nil_node = RBNode.new(0, NodeColor.BLACK)
	nil_node.is_nil = true
	
	root = nil_node
	tree_size = 0
	tree_height = 0
	black_height = 1  # NIL nodes contribute to black height
	
	print("Red-Black Tree initialized with NIL sentinel")

func start_demo():
	"""Start comprehensive Red-Black Tree demonstration"""
	generate_demo_data()
	current_demo_index = 0
	
	if step_by_step_mode:
		operation_timer.start()
	else:
		perform_bulk_demo()

func generate_demo_data():
	"""Generate demonstration dataset"""
	demo_values.clear()
	
	match insertion_mode:
		"sequential":
			for i in range(1, demo_dataset_size + 1):
				demo_values.append(i)
		"random":
			for i in range(demo_dataset_size):
				demo_values.append(randi_range(1, 100))
		"balanced":
			# Generate values that create interesting rotation scenarios
			demo_values = [50, 25, 75, 10, 30, 60, 80, 5, 15, 27, 35, 55, 65, 70, 90]
			demo_values = demo_values.slice(0, demo_dataset_size)
	
	print("Generated demo data: ", demo_values)

func perform_bulk_demo():
	"""Perform bulk operations without animation"""
	for value in demo_values:
		insert_value(value)
	
	update_tree_layout()
	update_visualization()
	update_ui()

func insert_value(value: int):
	"""Insert value into Red-Black Tree"""
	print("Inserting value: ", value)
	current_operation = "Inserting " + str(value)
	insertions_count += 1
	
	var new_node = RBNode.new(value, NodeColor.RED)
	
	# Standard BST insertion
	if root == nil_node:
		root = new_node
		new_node.color = NodeColor.BLACK  # Root is always black
		new_node.left = nil_node
		new_node.right = nil_node
		tree_size = 1
	else:
		insert_bst(new_node)
		tree_size += 1
		
		# Fix Red-Black Tree properties
		fix_insert_violations(new_node)
	
	# Update tree metrics
	calculate_tree_metrics()
	update_tree_layout()
	update_visualization()

func insert_bst(new_node: RBNode):
	"""Perform standard BST insertion"""
	var current = root
	var parent = nil_node
	
	while current != nil_node:
		parent = current
		if new_node.value < current.value:
			current = current.left
		else:
			current = current.right
	
	new_node.parent = parent
	new_node.left = nil_node
	new_node.right = nil_node
	
	if new_node.value < parent.value:
		parent.left = new_node
	else:
		parent.right = new_node

func fix_insert_violations(node: RBNode):
	"""Fix Red-Black Tree property violations after insertion"""
	while node != root and node.parent.is_red():
		if node.parent == node.parent.parent.left:
			# Parent is left child of grandparent
			var uncle = node.parent.parent.right
			
			if uncle.is_red():
				# Case 1: Uncle is red - recolor
				node.parent.color = NodeColor.BLACK
				uncle.color = NodeColor.BLACK
				node.parent.parent.color = NodeColor.RED
				node = node.parent.parent
				recolorings_count += 1
			else:
				# Uncle is black - rotation needed
				if node == node.parent.right:
					# Case 2: Node is right child - left rotation
					node = node.parent
					rotate_left(node)
				
				# Case 3: Node is left child - right rotation
				node.parent.color = NodeColor.BLACK
				node.parent.parent.color = NodeColor.RED
				rotate_right(node.parent.parent)
		else:
			# Parent is right child of grandparent (symmetric cases)
			var uncle = node.parent.parent.left
			
			if uncle.is_red():
				# Case 1: Uncle is red - recolor
				node.parent.color = NodeColor.BLACK
				uncle.color = NodeColor.BLACK
				node.parent.parent.color = NodeColor.RED
				node = node.parent.parent
				recolorings_count += 1
			else:
				# Uncle is black - rotation needed
				if node == node.parent.left:
					# Case 2: Node is left child - right rotation
					node = node.parent
					rotate_right(node)
				
				# Case 3: Node is right child - left rotation
				node.parent.color = NodeColor.BLACK
				node.parent.parent.color = NodeColor.RED
				rotate_left(node.parent.parent)
	
	# Root is always black
	root.color = NodeColor.BLACK

func rotate_left(node: RBNode):
	"""Perform left rotation around node"""
	if not node or node.right == nil_node:
		return
	
	print("Performing left rotation on node ", node.value)
	rotations_count += 1
	
	var right_child = node.right
	node.right = right_child.left
	
	if right_child.left != nil_node:
		right_child.left.parent = node
	
	right_child.parent = node.parent
	
	if node.parent == nil_node:
		root = right_child
	elif node == node.parent.left:
		node.parent.left = right_child
	else:
		node.parent.right = right_child
	
	right_child.left = node
	node.parent = right_child
	
	# Queue rotation animation
	if show_rotation_animations:
		queue_rotation_animation(node, right_child, "left")

func rotate_right(node: RBNode):
	"""Perform right rotation around node"""
	if not node or node.left == nil_node:
		return
	
	print("Performing right rotation on node ", node.value)
	rotations_count += 1
	
	var left_child = node.left
	node.left = left_child.right
	
	if left_child.right != nil_node:
		left_child.right.parent = node
	
	left_child.parent = node.parent
	
	if node.parent == nil_node:
		root = left_child
	elif node == node.parent.right:
		node.parent.right = left_child
	else:
		node.parent.left = left_child
	
	left_child.right = node
	node.parent = left_child
	
	# Queue rotation animation
	if show_rotation_animations:
		queue_rotation_animation(node, left_child, "right")

func queue_rotation_animation(old_parent: RBNode, new_parent: RBNode, direction: String):
	"""Queue rotation animation for visualization"""
	var animation_data = {
		"type": "rotation",
		"old_parent": old_parent,
		"new_parent": new_parent,
		"direction": direction,
		"duration": rotation_animation_duration
	}
	animation_queue.append(animation_data)

func delete_value(value: int) -> bool:
	"""Delete value from Red-Black Tree"""
	var node_to_delete = search_node(value)
	if not node_to_delete or node_to_delete == nil_node:
		print("Value ", value, " not found for deletion")
		return false
	
	print("Deleting value: ", value)
	current_operation = "Deleting " + str(value)
	deletions_count += 1
	
	delete_node(node_to_delete)
	tree_size -= 1
	
	calculate_tree_metrics()
	update_tree_layout()
	update_visualization()
	return true

func delete_node(node: RBNode):
	"""Delete node from Red-Black Tree"""
	var original_color = node.color
	var replacement_node: RBNode
	
	if node.left == nil_node:
		replacement_node = node.right
		transplant(node, node.right)
	elif node.right == nil_node:
		replacement_node = node.left
		transplant(node, node.left)
	else:
		# Node has two children - find successor
		var successor = find_minimum(node.right)
		original_color = successor.color
		replacement_node = successor.right
		
		if successor.parent == node:
			replacement_node.parent = successor
		else:
			transplant(successor, successor.right)
			successor.right = node.right
			successor.right.parent = successor
		
		transplant(node, successor)
		successor.left = node.left
		successor.left.parent = successor
		successor.color = node.color
	
	# Fix Red-Black Tree properties if black node was deleted
	if original_color == NodeColor.BLACK:
		fix_delete_violations(replacement_node)

func transplant(old_node: RBNode, new_node: RBNode):
	"""Replace old_node with new_node in the tree"""
	if old_node.parent == nil_node:
		root = new_node
	elif old_node == old_node.parent.left:
		old_node.parent.left = new_node
	else:
		old_node.parent.right = new_node
	
	new_node.parent = old_node.parent

func fix_delete_violations(node: RBNode):
	"""Fix Red-Black Tree property violations after deletion"""
	while node != root and node.is_black():
		if node == node.parent.left:
			var sibling = node.parent.right
			
			if sibling.is_red():
				sibling.color = NodeColor.BLACK
				node.parent.color = NodeColor.RED
				rotate_left(node.parent)
				sibling = node.parent.right
			
			if sibling.left.is_black() and sibling.right.is_black():
				sibling.color = NodeColor.RED
				node = node.parent
			else:
				if sibling.right.is_black():
					sibling.left.color = NodeColor.BLACK
					sibling.color = NodeColor.RED
					rotate_right(sibling)
					sibling = node.parent.right
				
				sibling.color = node.parent.color
				node.parent.color = NodeColor.BLACK
				sibling.right.color = NodeColor.BLACK
				rotate_left(node.parent)
				node = root
		else:
			# Symmetric case - node is right child
			var sibling = node.parent.left
			
			if sibling.is_red():
				sibling.color = NodeColor.BLACK
				node.parent.color = NodeColor.RED
				rotate_right(node.parent)
				sibling = node.parent.left
			
			if sibling.right.is_black() and sibling.left.is_black():
				sibling.color = NodeColor.RED
				node = node.parent
			else:
				if sibling.left.is_black():
					sibling.right.color = NodeColor.BLACK
					sibling.color = NodeColor.RED
					rotate_left(sibling)
					sibling = node.parent.left
				
				sibling.color = node.parent.color
				node.parent.color = NodeColor.BLACK
				sibling.left.color = NodeColor.BLACK
				rotate_right(node.parent)
				node = root
	
	node.color = NodeColor.BLACK

func search_node(value: int) -> RBNode:
	"""Search for node with given value"""
	search_path.clear()
	return search_recursive(root, value)

func search_recursive(node: RBNode, value: int) -> RBNode:
	"""Recursive search implementation"""
	if node == nil_node:
		return nil_node
	
	search_path.append(node)
	
	if value == node.value:
		return node
	elif value < node.value:
		return search_recursive(node.left, value)
	else:
		return search_recursive(node.right, value)

func find_minimum(node: RBNode) -> RBNode:
	"""Find minimum value node in subtree"""
	while node.left != nil_node:
		node = node.left
	return node

func calculate_tree_metrics():
	"""Calculate tree height and black height"""
	tree_height = calculate_height(root)
	black_height = calculate_black_height(root)

func calculate_height(node: RBNode) -> int:
	"""Calculate height of tree"""
	if node == nil_node:
		return 0
	
	var left_height = calculate_height(node.left)
	var right_height = calculate_height(node.right)
	return max(left_height, right_height) + 1

func calculate_black_height(node: RBNode) -> int:
	"""Calculate black height of tree"""
	if node == nil_node:
		return 1
	
	var left_black_height = calculate_black_height(node.left)
	if node.is_black():
		return left_black_height + 1
	else:
		return left_black_height

func validate_rb_properties() -> Array:
	"""Validate Red-Black Tree properties"""
	property_violations.clear()
	
	# Property 1: Every node is either red or black (always true by design)
	
	# Property 2: Root is black
	if root != nil_node and root.is_red():
		property_violations.append("Root is not black")
	
	# Property 3: All NIL nodes are black (always true by design)
	
	# Property 4: Red nodes have black children
	check_red_property(root)
	
	# Property 5: All paths from root to NIL have same black height
	var reference_black_height = get_black_height_to_nil(root)
	check_black_height_property(root, 0, reference_black_height)
	
	return property_violations

func check_red_property(node: RBNode):
	"""Check that red nodes have black children"""
	if node == nil_node:
		return
	
	if node.is_red():
		if node.left.is_red():
			property_violations.append("Red node " + str(node.value) + " has red left child")
		if node.right.is_red():
			property_violations.append("Red node " + str(node.value) + " has red right child")
	
	check_red_property(node.left)
	check_red_property(node.right)

func get_black_height_to_nil(node: RBNode) -> int:
	"""Get black height from node to any NIL node"""
	if node == nil_node:
		return 1
	
	var left_height = get_black_height_to_nil(node.left)
	if node.is_black():
		return left_height + 1
	else:
		return left_height

func check_black_height_property(node: RBNode, current_black_height: int, reference_height: int):
	"""Check that all paths have same black height"""
	if node == nil_node:
		if current_black_height + 1 != reference_height:
			property_violations.append("Inconsistent black height: " + str(current_black_height + 1) + " vs " + str(reference_height))
		return
	
	var new_height = current_black_height
	if node.is_black():
		new_height += 1
	
	check_black_height_property(node.left, new_height, reference_height)
	check_black_height_property(node.right, new_height, reference_height)

func update_tree_layout():
	"""Update 3D positions of all nodes"""
	if root == nil_node:
		return
	
	# Calculate tree width for centering
	var tree_width = calculate_tree_width(root, 0)
	var start_x = -tree_width / 2.0
	
	assign_positions(root, start_x, tree_width, 0)

func calculate_tree_width(node: RBNode, level: int) -> float:
	"""Calculate total width needed for tree"""
	if node == nil_node:
		return 0.0
	
	var left_width = calculate_tree_width(node.left, level + 1)
	var right_width = calculate_tree_width(node.right, level + 1)
	
	return max(node_spacing_x, left_width + right_width + node_spacing_x)

func assign_positions(node: RBNode, x: float, width: float, level: int):
	"""Assign 3D positions to nodes using in-order traversal"""
	if node == nil_node:
		return x
	
	# Position left subtree
	x = assign_positions(node.left, x, width / 2.0, level + 1)
	
	# Position current node
	node.position = Vector3(x, level * level_spacing_y, 0)
	x += node_spacing_x
	
	# Position right subtree
	x = assign_positions(node.right, x, width / 2.0, level + 1)
	
	return x

func update_visualization():
	"""Update 3D visualization of Red-Black Tree"""
	clear_visualization()
	
	if root == nil_node:
		return
	
	visualize_tree(root)
	create_connections()
	
	if validate_properties:
		validate_rb_properties()

func clear_visualization():
	"""Clear existing visualization elements"""
	for mesh in node_meshes:
		if mesh and is_instance_valid(mesh):
			mesh.queue_free()
	node_meshes.clear()
	
	for mesh in connection_meshes:
		if mesh and is_instance_valid(mesh):
			mesh.queue_free()
	connection_meshes.clear()

func visualize_tree(node: RBNode):
	"""Recursively visualize tree nodes"""
	if node == nil_node:
		return
	
	create_node_visualization(node)
	
	# Visualize children
	visualize_tree(node.left)
	visualize_tree(node.right)

func create_node_visualization(node: RBNode):
	"""Create 3D visualization for a node"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.4
	mesh.height = 0.8
	
	mesh_instance.mesh = mesh
	mesh_instance.position = node.position
	
	# Set color based on Red-Black Tree color
	var color = red_node_color if node.is_red() else black_node_color
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	node_meshes.append(mesh_instance)
	node.mesh_instance = mesh_instance
	
	# Add value label
	var label = Label3D.new()
	label.text = str(node.value)
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_instance.add_child(label)

func create_connections():
	"""Create visual connections between parent and child nodes"""
	if root == nil_node:
		return
	
	create_node_connections(root)

func create_node_connections(node: RBNode):
	"""Create connections for a specific node"""
	if node == nil_node:
		return
	
	# Create connection to left child
	if node.left != nil_node:
		var connection = create_connection_line(node.position, node.left.position)
		add_child(connection)
		connection_meshes.append(connection)
	
	# Create connection to right child
	if node.right != nil_node:
		var connection = create_connection_line(node.position, node.right.position)
		add_child(connection)
		connection_meshes.append(connection)
	
	# Recurse to children
	create_node_connections(node.left)
	create_node_connections(node.right)

func create_connection_line(from_pos: Vector3, to_pos: Vector3) -> MeshInstance3D:
	"""Create visual connection line between nodes"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.05
	mesh.height = from_pos.distance_to(to_pos)
	
	mesh_instance.mesh = mesh
	mesh_instance.position = (from_pos + to_pos) / 2.0
	mesh_instance.look_at(to_pos, Vector3.UP)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5, 1.0)
	mesh_instance.material_override = material
	
	return mesh_instance

func _on_operation_timer_timeout():
	"""Handle animation timer for step-by-step operations"""
	if current_demo_index < demo_values.size():
		insert_value(demo_values[current_demo_index])
		current_demo_index += 1
		update_ui()
	else:
		operation_timer.stop()
		print("Demo complete!")

func highlight_search_path():
	"""Highlight the search path in visualization"""
	for node in search_path:
		if node.mesh_instance:
			var material = node.mesh_instance.material_override as StandardMaterial3D
			if material:
				material.albedo_color = search_path_color
				material.emission = search_path_color * 0.4
	
	# Reset after delay
	await get_tree().create_timer(highlight_duration).timeout
	update_visualization()

func update_ui():
	"""Update UI with current Red-Black Tree state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(40):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 40:
		labels[0].text = "🔴⚫ Red-Black Tree - Self-Balancing Binary Democracy"
		labels[1].text = "Tree Size: " + str(tree_size) + " nodes"
		labels[2].text = "Tree Height: " + str(tree_height)
		labels[3].text = "Black Height: " + str(black_height)
		labels[4].text = ""
		labels[5].text = "Operation Statistics:"
		labels[6].text = "Insertions: " + str(insertions_count)
		labels[7].text = "Deletions: " + str(deletions_count)
		labels[8].text = "Rotations: " + str(rotations_count)
		labels[9].text = "Recolorings: " + str(recolorings_count)
		labels[10].text = ""
		labels[11].text = "Red-Black Properties:"
		labels[12].text = "1. Nodes are red or black ✓"
		labels[13].text = "2. Root is black " + ("✓" if root == nil_node or root.is_black() else "✗")
		labels[14].text = "3. NIL nodes are black ✓"
		labels[15].text = "4. Red nodes have black children " + ("✓" if check_red_children_property() else "✗")
		labels[16].text = "5. Equal black height paths " + ("✓" if check_black_height_consistency() else "✗")
		labels[17].text = ""
		labels[18].text = "Balance Analysis:"
		labels[19].text = "Height Efficiency: " + get_height_efficiency()
		labels[20].text = "Red Node Ratio: " + get_red_node_ratio()
		labels[21].text = "Black Node Ratio: " + get_black_node_ratio()
		labels[22].text = "Balance Factor: " + get_balance_factor()
		labels[23].text = ""
		labels[24].text = "Current Operation:"
		labels[25].text = current_operation
		labels[26].text = "Demo Progress: " + str(current_demo_index) + "/" + str(demo_values.size())
		labels[27].text = "Property Violations: " + str(property_violations.size())
		labels[28].text = ""
		labels[29].text = "Performance Metrics:"
		labels[30].text = "Avg Search Depth: " + get_average_search_depth()
		labels[31].text = "Tree Balance Score: " + get_tree_balance_score()
		labels[32].text = "Rotation Efficiency: " + get_rotation_efficiency()
		labels[33].text = ""
		labels[34].text = "Democratic Access Analysis:"
		labels[35].text = "Max Path Length: " + str(tree_height)
		labels[36].text = "Min Path Length: " + str(black_height)
		labels[37].text = "Access Equality Index: " + get_access_equality_index()
		labels[38].text = ""
		labels[39].text = "🏳️‍🌈 Explores algorithmic justice & balanced representation"

func check_red_children_property() -> bool:
	"""Check if all red nodes have black children"""
	return check_red_children_recursive(root)

func check_red_children_recursive(node: RBNode) -> bool:
	"""Recursively check red children property"""
	if node == nil_node:
		return true
	
	if node.is_red():
		if node.left.is_red() or node.right.is_red():
			return false
	
	return check_red_children_recursive(node.left) and check_red_children_recursive(node.right)

func check_black_height_consistency() -> bool:
	"""Check if all paths have same black height"""
	if root == nil_node:
		return true
	
	var reference_height = get_black_height_to_nil(root)
	return check_black_height_recursive(root, 0, reference_height)

func check_black_height_recursive(node: RBNode, current_height: int, reference_height: int) -> bool:
	"""Recursively check black height consistency"""
	if node == nil_node:
		return (current_height + 1) == reference_height
	
	var new_height = current_height
	if node.is_black():
		new_height += 1
	
	return check_black_height_recursive(node.left, new_height, reference_height) and \
		   check_black_height_recursive(node.right, new_height, reference_height)

func get_height_efficiency() -> String:
	"""Calculate height efficiency compared to perfect balance"""
	if tree_size == 0:
		return "N/A"
	
	var perfect_height = int(ceil(log(tree_size + 1) / log(2)))
	var efficiency = float(perfect_height) / float(tree_height) * 100.0
	return str(int(efficiency)) + "%"

func get_red_node_ratio() -> String:
	"""Get percentage of red nodes"""
	if tree_size == 0:
		return "0%"
	
	var red_count = count_red_nodes(root)
	var ratio = float(red_count) / float(tree_size) * 100.0
	return str(int(ratio)) + "%"

func get_black_node_ratio() -> String:
	"""Get percentage of black nodes"""
	if tree_size == 0:
		return "0%"
	
	var black_count = count_black_nodes(root)
	var ratio = float(black_count) / float(tree_size) * 100.0
	return str(int(ratio)) + "%"

func count_red_nodes(node: RBNode) -> int:
	"""Count red nodes in subtree"""
	if node == nil_node:
		return 0
	
	var count = 1 if node.is_red() else 0
	return count + count_red_nodes(node.left) + count_red_nodes(node.right)

func count_black_nodes(node: RBNode) -> int:
	"""Count black nodes in subtree"""
	if node == nil_node:
		return 0
	
	var count = 1 if node.is_black() else 0
	return count + count_black_nodes(node.left) + count_black_nodes(node.right)

func get_balance_factor() -> String:
	"""Get balance factor (difference between subtree heights)"""
	if root == nil_node:
		return "N/A"
	
	var left_height = calculate_height(root.left)
	var right_height = calculate_height(root.right)
	var balance = abs(left_height - right_height)
	return str(balance)

func get_average_search_depth() -> String:
	"""Calculate average search depth"""
	if tree_size == 0:
		return "0"
	
	var total_depth = calculate_total_depth(root, 1)
	var average = float(total_depth) / float(tree_size)
	return str(snapped(average, 0.1))

func calculate_total_depth(node: RBNode, depth: int) -> int:
	"""Calculate total depth of all nodes"""
	if node == nil_node:
		return 0
	
	return depth + calculate_total_depth(node.left, depth + 1) + calculate_total_depth(node.right, depth + 1)

func get_tree_balance_score() -> String:
	"""Get overall tree balance score"""
	if tree_size <= 1:
		return "100%"
	
	var ideal_height = int(ceil(log(tree_size + 1) / log(2)))
	var balance_score = float(ideal_height) / float(max(1, tree_height)) * 100.0
	return str(int(balance_score)) + "%"

func get_rotation_efficiency() -> String:
	"""Get rotation efficiency metric"""
	if insertions_count == 0:
		return "N/A"
	
	var rotation_ratio = float(rotations_count) / float(insertions_count)
	var efficiency = max(0, 100 - int(rotation_ratio * 100))
	return str(efficiency) + "%"

func get_access_equality_index() -> String:
	"""Calculate access equality index"""
	if tree_height == 0:
		return "100%"
	
	var equality = float(black_height) / float(tree_height) * 100.0
	return str(int(equality)) + "%"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_I:
				var value = randi_range(1, 100)
				insert_value(value)
			KEY_D:
				if tree_size > 0:
					var value = randi_range(1, 100)
					delete_value(value)
			KEY_S:
				if tree_size > 0:
					var value = randi_range(1, 100)
					var result = search_node(value)
					print("Search for ", value, ": ", "Found" if result != nil_node else "Not found")
					if search_highlight:
						highlight_search_path()
			KEY_R:
				reset_tree()
			KEY_V:
				var violations = validate_rb_properties()
				print("Property violations: ", violations)
			KEY_SPACE:
				if operation_timer.is_stopped():
					start_demo()
				else:
					operation_timer.stop()

func reset_tree():
	"""Reset Red-Black Tree to initial state"""
	clear_visualization()
	insertions_count = 0
	deletions_count = 0
	rotations_count = 0
	recolorings_count = 0
	current_demo_index = 0
	operation_timer.stop()
	
	initialize_tree()
	update_ui()
	print("Red-Black Tree reset")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive Red-Black Tree algorithm information"""
	return {
		"name": "Red-Black Tree",
		"description": "Self-balancing binary search tree with color properties",
		"properties": {
			"tree_size": tree_size,
			"tree_height": tree_height,
			"black_height": black_height,
			"is_valid": validate_rb_properties().size() == 0
		},
		"operations": {
			"insertions": insertions_count,
			"deletions": deletions_count,
			"rotations": rotations_count,
			"recolorings": recolorings_count
		},
		"complexity": {
			"search": "O(log n)",
			"insert": "O(log n)",
			"delete": "O(log n)",
			"space": "O(n)"
		}
	} 