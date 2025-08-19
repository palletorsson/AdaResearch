extends Node3D

# Binary Search Tree Visualization
# Interactive BST with insertion, deletion, and traversal animations

@export_category("Tree Configuration")
@export var auto_insert_values: bool = true
@export var initial_values: Array[int] = [50, 30, 70, 20, 40, 60, 80]
@export var insertion_speed: float = 1.0
@export var show_traversal: bool = true

@export_category("Visual Settings")
@export var node_radius: float = 0.5
@export var level_spacing: float = 3.0
@export var horizontal_spacing: float = 2.0
@export var show_connections: bool = true

var root: TreeNode = null
var operation_queue: Array = []
var current_operation: Dictionary = {}
var operation_timer: float = 0.0
var ui_labels: Array = []

# Colors
var default_node_color = Color(0.6, 0.6, 0.8)
var highlight_color = Color(0.9, 0.7, 0.2)
var insert_color = Color(0.2, 0.8, 0.2)
var delete_color = Color(0.8, 0.2, 0.2)

class TreeNode:
	var value: int
	var left: TreeNode = null
	var right: TreeNode = null
	var mesh_instance: MeshInstance3D = null
	var text_label: Label3D = null
	var position_3d: Vector3 = Vector3.ZERO
	var level: int = 0
	
	func _init(val: int):
		value = val

func _ready():
	setup_environment()
	setup_ui()
	
	if auto_insert_values:
		for val in initial_values:
			queue_insert(val)

func _process(delta):
	if operation_queue.size() > 0 and current_operation.is_empty():
		current_operation = operation_queue.pop_front()
		operation_timer = 0.0
	
	if not current_operation.is_empty():
		operation_timer += delta
		if operation_timer >= insertion_speed:
			execute_current_operation()
			operation_timer = 0.0

func setup_environment():
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-30, 45, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 10, 15)
	camera.look_at(Vector3.ZERO)
	add_child(camera)

func queue_insert(value: int):
	operation_queue.append({
		"type": "insert",
		"value": value
	})

func queue_delete(value: int):
	operation_queue.append({
		"type": "delete", 
		"value": value
	})

func queue_traversal(type: String):
	operation_queue.append({
		"type": "traversal",
		"traversal_type": type  # "inorder", "preorder", "postorder"
	})

func execute_current_operation():
	match current_operation.type:
		"insert":
			insert_value(current_operation.value)
		"delete":
			delete_value(current_operation.value)
		"traversal":
			start_traversal(current_operation.traversal_type)
	
	current_operation.clear()

func insert_value(value: int):
	if root == null:
		root = TreeNode.new(value)
		root.level = 0
		create_node_visual(root)
		calculate_positions()
	else:
		var new_node = TreeNode.new(value)
		insert_recursive(root, new_node)
		create_node_visual(new_node)
		calculate_positions()
	
	print("Inserted: ", value)

func insert_recursive(node: TreeNode, new_node: TreeNode):
	if new_node.value < node.value:
		if node.left == null:
			node.left = new_node
			new_node.level = node.level + 1
		else:
			insert_recursive(node.left, new_node)
	else:
		if node.right == null:
			node.right = new_node
			new_node.level = node.level + 1
		else:
			insert_recursive(node.right, new_node)

func delete_value(value: int):
	root = delete_recursive(root, value)
	calculate_positions()
	print("Deleted: ", value)

func delete_recursive(node: TreeNode, value: int) -> TreeNode:
	if node == null:
		return null
	
	if value < node.value:
		node.left = delete_recursive(node.left, value)
	elif value > node.value:
		node.right = delete_recursive(node.right, value)
	else:
		# Node to be deleted found
		if node.mesh_instance:
			node.mesh_instance.queue_free()
		
		if node.left == null:
			return node.right
		elif node.right == null:
			return node.left
		
		# Node with two children
		var min_right = find_min(node.right)
		node.value = min_right.value
		node.right = delete_recursive(node.right, min_right.value)
		
		# Update visual
		update_node_visual(node)
	
	return node

func find_min(node: TreeNode) -> TreeNode:
	while node.left != null:
		node = node.left
	return node

func create_node_visual(node: TreeNode):
	# Create sphere mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = node_radius
	sphere.height = node_radius * 2
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = default_node_color
	material.emission_enabled = true
	material.emission = default_node_color * 0.3
	mesh_instance.material_override = material
	
	node.mesh_instance = mesh_instance
	add_child(mesh_instance)
	
	# Create text label
	var label = Label3D.new()
	label.text = str(node.value)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	mesh_instance.add_child(label)
	node.text_label = label

func update_node_visual(node: TreeNode):
	if node.text_label:
		node.text_label.text = str(node.value)

func calculate_positions():
	if root == null:
		return
	
	# Calculate positions using in-order traversal for x-coordinates
	var positions = []
	collect_inorder_positions(root, positions)
	
	# Assign x positions
	for i in range(positions.size()):
		positions[i].position_3d.x = (i - positions.size() / 2.0) * horizontal_spacing
		positions[i].position_3d.y = -positions[i].level * level_spacing
		positions[i].position_3d.z = 0
	
	# Update visual positions
	update_visual_positions()
	
	# Update connections
	if show_connections:
		update_connections()

func collect_inorder_positions(node: TreeNode, positions: Array):
	if node == null:
		return
	
	collect_inorder_positions(node.left, positions)
	positions.append(node)
	collect_inorder_positions(node.right, positions)

func update_visual_positions():
	update_positions_recursive(root)

func update_positions_recursive(node: TreeNode):
	if node == null:
		return
	
	if node.mesh_instance:
		node.mesh_instance.position = node.position_3d
	
	update_positions_recursive(node.left)
	update_positions_recursive(node.right)

func update_connections():
	# Remove old connection lines
	for child in get_children():
		if child.name.begins_with("Connection"):
			child.queue_free()
	
	# Create new connection lines
	create_connections_recursive(root)

func create_connections_recursive(node: TreeNode):
	if node == null:
		return
	
	if node.left != null:
		create_connection_line(node.position_3d, node.left.position_3d)
		create_connections_recursive(node.left)
	
	if node.right != null:
		create_connection_line(node.position_3d, node.right.position_3d)
		create_connections_recursive(node.right)

func create_connection_line(from: Vector3, to: Vector3):
	var line = MeshInstance3D.new()
	line.name = "Connection"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	cylinder.height = 1.0
	line.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.4, 0.6, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material
	
	# Position and orient line
	var center = (from + to) / 2
	line.position = center
	line.look_at(to, Vector3.UP)
	line.scale.y = from.distance_to(to)
	
	add_child(line)

func start_traversal(traversal_type: String):
	var traversal_order = []
	
	match traversal_type:
		"inorder":
			inorder_traversal(root, traversal_order)
		"preorder":
			preorder_traversal(root, traversal_order)
		"postorder":
			postorder_traversal(root, traversal_order)
	
	print("Traversal (", traversal_type, "): ", traversal_order)
	animate_traversal(traversal_order)

func inorder_traversal(node: TreeNode, order: Array):
	if node == null:
		return
	
	inorder_traversal(node.left, order)
	order.append(node.value)
	inorder_traversal(node.right, order)

func preorder_traversal(node: TreeNode, order: Array):
	if node == null:
		return
	
	order.append(node.value)
	preorder_traversal(node.left, order)
	preorder_traversal(node.right, order)

func postorder_traversal(node: TreeNode, order: Array):
	if node == null:
		return
	
	postorder_traversal(node.left, order)
	postorder_traversal(node.right, order)
	order.append(node.value)

func animate_traversal(order: Array):
	# Simple animation - could be enhanced to show step-by-step highlighting
	for i in range(order.size()):
		var node = find_node_with_value(root, order[i])
		if node and node.mesh_instance:
			var material = node.mesh_instance.material_override
			material.albedo_color = highlight_color
			await get_tree().create_timer(0.5).timeout
			material.albedo_color = default_node_color

func find_node_with_value(node: TreeNode, value: int) -> TreeNode:
	if node == null:
		return null
	
	if node.value == value:
		return node
	elif value < node.value:
		return find_node_with_value(node.left, value)
	else:
		return find_node_with_value(node.right, value)

func setup_ui():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var info_label = Label.new()
	info_label.position = Vector2(20, 20)
	info_label.text = "Binary Search Tree"
	canvas.add_child(info_label)
	ui_labels.append(info_label)
	
	var controls_label = Label.new()
	controls_label.position = Vector2(20, 50)
	controls_label.text = "Auto-inserting values..."
	canvas.add_child(controls_label)
	ui_labels.append(controls_label) 