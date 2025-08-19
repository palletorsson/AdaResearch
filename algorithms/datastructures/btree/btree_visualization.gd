class_name BTreeVisualization
extends Node3D

# B-Tree: Hierarchical Data Organization & Database Democracy
# Visualizes self-balancing tree structures, node splitting, database indexing
# Explores information hierarchies and democratic data access

@export_category("B-Tree Configuration")
@export var tree_degree: int = 3  # Minimum degree (t) - order = 2t-1
@export var max_tree_height: int = 5
@export var auto_balance: bool = true
@export var show_internal_nodes: bool = true
@export var show_leaf_nodes: bool = true
@export var animate_operations: bool = true

@export_category("Operation Settings")
@export var insertion_mode: String = "sequential"  # sequential, random, bulk
@export var deletion_mode: String = "leaf_first"  # leaf_first, internal_first, random
@export var search_highlight: bool = true
@export var show_search_path: bool = true
@export var demo_dataset_size: int = 20

@export_category("Database Simulation")
@export var simulate_database_records: bool = true
@export var record_access_patterns: bool = true
@export var show_disk_access_simulation: bool = true
@export var cache_simulation: bool = true
@export var page_size_visualization: bool = true

@export_category("Visualization")
@export var node_spacing: float = 3.0
@export var level_height: float = 2.5
@export var key_display_mode: String = "numbers"  # numbers, letters, records
@export var show_node_utilization: bool = true
@export var highlight_splits: bool = true

@export_category("Animation")
@export var auto_demo: bool = true
@export var operation_delay: float = 1.2
@export var split_animation_duration: float = 1.5
@export var search_animation_speed: float = 0.8
@export var highlight_duration: float = 2.0

@export_category("Educational Features")
@export var show_degree_constraints: bool = true
@export var show_balance_properties: bool = true
@export var compare_with_binary_tree: bool = false
@export var performance_analysis: bool = true

# Colors for visualization
@export var internal_node_color: Color = Color(0.3, 0.6, 0.8, 1.0)    # Blue
@export var leaf_node_color: Color = Color(0.2, 0.8, 0.4, 1.0)        # Green
@export var root_node_color: Color = Color(0.9, 0.3, 0.2, 1.0)        # Red
@export var split_node_color: Color = Color(0.9, 0.6, 0.2, 1.0)       # Orange
@export var search_path_color: Color = Color(0.9, 0.2, 0.9, 1.0)      # Magenta
@export var key_color: Color = Color(0.9, 0.9, 0.2, 1.0)              # Yellow
@export var pointer_color: Color = Color(0.7, 0.7, 0.7, 1.0)          # Gray

# B-Tree node structure
class BTreeNode:
	var keys: Array = []           # Array of keys in node
	var children: Array = []       # Array of child node references
	var is_leaf: bool = true       # True if leaf node
	var parent: BTreeNode = null   # Parent node reference
	var position: Vector3          # 3D position for visualization
	var mesh_instance: MeshInstance3D = null  # Visual representation
	var is_full: bool = false      # Node capacity status
	
	func _init(degree: int):
		keys.resize(2 * degree - 1)
		children.resize(2 * degree)
		for i in range(keys.size()):
			keys[i] = null
		for i in range(children.size()):
			children[i] = null
	
	func get_key_count() -> int:
		var count = 0
		for key in keys:
			if key != null:
				count += 1
		return count
	
	func get_child_count() -> int:
		var count = 0
		for child in children:
			if child != null:
				count += 1
		return count
	
	func is_node_full(degree: int) -> bool:
		return get_key_count() >= (2 * degree - 1)
	
	func can_give_key(degree: int) -> bool:
		return get_key_count() > degree - 1
	
	func needs_merge(degree: int) -> bool:
		return get_key_count() < degree - 1

# B-Tree structure
var root: BTreeNode = null
var tree_height: int = 0
var total_nodes: int = 0
var total_keys: int = 0

# Operation tracking
var current_operation: String = ""
var operation_step: int = 0
var animation_queue: Array = []
var search_path: Array = []
var split_history: Array = []

# Performance metrics
var disk_accesses: int = 0
var cache_hits: int = 0
var cache_misses: int = 0
var operations_performed: int = 0

# Visualization elements
var node_meshes: Array = []
var connection_meshes: Array = []
var ui_display: CanvasLayer
var operation_timer: Timer

# Demo data
var demo_keys: Array = []
var current_demo_index: int = 0

func _init():
	name = "BTree_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	initialize_btree()
	
	if auto_demo:
		call_deferred("start_demo")

func setup_ui():
	"""Create comprehensive UI for B-Tree visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(600, 1000)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for B-Tree information
	for i in range(40):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup timer for animation operations"""
	operation_timer = Timer.new()
	operation_timer.wait_time = operation_delay
	operation_timer.timeout.connect(_on_operation_timer_timeout)
	add_child(operation_timer)

func initialize_btree():
	"""Initialize empty B-Tree"""
	root = BTreeNode.new(tree_degree)
	root.position = Vector3(0, 0, 0)
	tree_height = 1
	total_nodes = 1
	total_keys = 0
	
	create_node_visualization(root, root_node_color)
	print("B-Tree initialized with degree ", tree_degree)

func start_demo():
	"""Start comprehensive B-Tree demonstration"""
	generate_demo_data()
	current_demo_index = 0
	
	if animate_operations:
		operation_timer.start()
	else:
		perform_bulk_demo()

func generate_demo_data():
	"""Generate demonstration dataset"""
	demo_keys.clear()
	
	match insertion_mode:
		"sequential":
			for i in range(1, demo_dataset_size + 1):
				demo_keys.append(i)
		"random":
			for i in range(demo_dataset_size):
				demo_keys.append(randi_range(1, 100))
		"bulk":
			var sorted_keys = range(1, demo_dataset_size + 1)
			sorted_keys.shuffle()
			demo_keys = sorted_keys
	
	print("Generated demo data: ", demo_keys)

func perform_bulk_demo():
	"""Perform bulk operations without animation"""
	for key in demo_keys:
		insert_key(key)
	
	update_visualization()
	update_ui()

func insert_key(key: int):
	"""Insert key into B-Tree"""
	if not root:
		initialize_btree()
	
	print("Inserting key: ", key)
	operations_performed += 1
	
	# Check if root is full
	if root.is_node_full(tree_degree):
		# Create new root
		var new_root = BTreeNode.new(tree_degree)
		new_root.is_leaf = false
		new_root.children[0] = root
		root.parent = new_root
		
		# Split the old root
		split_child(new_root, 0)
		root = new_root
		tree_height += 1
		total_nodes += 1
	
	# Insert into non-full tree
	insert_non_full(root, key)
	total_keys += 1
	
	update_tree_positions()
	update_visualization()

func insert_non_full(node: BTreeNode, key: int):
	"""Insert key into non-full node"""
	disk_accesses += 1
	var i = node.get_key_count() - 1
	
	if node.is_leaf:
		# Insert into leaf node
		while i >= 0 and node.keys[i] != null and node.keys[i] > key:
			node.keys[i + 1] = node.keys[i]
			i -= 1
		node.keys[i + 1] = key
	else:
		# Find child to insert into
		while i >= 0 and node.keys[i] != null and node.keys[i] > key:
			i -= 1
		i += 1
		
		# Check if child is full
		if node.children[i].is_node_full(tree_degree):
			split_child(node, i)
			if node.keys[i] != null and key > node.keys[i]:
				i += 1
		
		insert_non_full(node.children[i], key)

func split_child(parent: BTreeNode, index: int):
	"""Split full child node"""
	var full_child = parent.children[index]
	var new_child = BTreeNode.new(tree_degree)
	var mid_index = tree_degree - 1
	
	# New child takes second half of keys
	new_child.is_leaf = full_child.is_leaf
	for i in range(tree_degree - 1):
		new_child.keys[i] = full_child.keys[i + tree_degree]
		full_child.keys[i + tree_degree] = null
	
	# Move children if not leaf
	if not full_child.is_leaf:
		for i in range(tree_degree):
			new_child.children[i] = full_child.children[i + tree_degree]
			full_child.children[i + tree_degree] = null
	
	# Move median key to parent
	# First shift parent's keys and children
	for i in range(parent.get_key_count(), index, -1):
		parent.keys[i] = parent.keys[i - 1]
	for i in range(parent.get_child_count(), index + 1, -1):
		parent.children[i] = parent.children[i - 1]
	
	# Insert median key and new child
	parent.keys[index] = full_child.keys[mid_index]
	parent.children[index + 1] = new_child
	full_child.keys[mid_index] = null
	
	# Update parent references
	new_child.parent = parent
	
	total_nodes += 1
	split_history.append({
		"parent": parent,
		"original_child": full_child,
		"new_child": new_child,
		"median_key": parent.keys[index]
	})
	
	print("Split node - median key: ", parent.keys[index])

func search_key(key: int) -> BTreeNode:
	"""Search for key in B-Tree"""
	search_path.clear()
	return search_node(root, key)

func search_node(node: BTreeNode, key: int) -> BTreeNode:
	"""Search for key in specific node"""
	if not node:
		return null
	
	search_path.append(node)
	disk_accesses += 1
	
	var i = 0
	var key_count = node.get_key_count()
	
	# Find position of key
	while i < key_count and node.keys[i] != null and key > node.keys[i]:
		i += 1
	
	# Key found
	if i < key_count and node.keys[i] == key:
		return node
	
	# Key not found and this is leaf
	if node.is_leaf:
		return null
	
	# Search in appropriate child
	return search_node(node.children[i], key)

func delete_key(key: int) -> bool:
	"""Delete key from B-Tree"""
	print("Deleting key: ", key)
	operations_performed += 1
	
	var result = delete_from_node(root, key)
	
	# Check if root became empty
	if root.get_key_count() == 0:
		if not root.is_leaf:
			root = root.children[0]
			tree_height -= 1
			total_nodes -= 1
	
	if result:
		total_keys -= 1
	
	update_tree_positions()
	update_visualization()
	return result

func delete_from_node(node: BTreeNode, key: int) -> bool:
	"""Delete key from specific node"""
	disk_accesses += 1
	var key_index = find_key_index(node, key)
	
	if key_index < node.get_key_count() and node.keys[key_index] == key:
		# Key found in current node
		if node.is_leaf:
			# Case 1: Delete from leaf
			delete_from_leaf(node, key_index)
		else:
			# Case 2: Delete from internal node
			delete_from_internal(node, key_index)
		return true
	elif node.is_leaf:
		# Key not found
		return false
	else:
		# Key might be in child
		var child_index = key_index
		var child = node.children[child_index]
		
		# Ensure child has enough keys
		if child.get_key_count() == tree_degree - 1:
			fill_child(node, child_index)
			
			# Recompute child index after filling
			if child_index > 0 and node.keys[child_index - 1] == key:
				return delete_from_node(node, key)
			elif child_index < node.get_key_count() and node.keys[child_index] == key:
				return delete_from_node(node, key)
			else:
				if key > node.keys[child_index]:
					child_index += 1
				child = node.children[child_index]
		
		return delete_from_node(child, key)

func find_key_index(node: BTreeNode, key: int) -> int:
	"""Find index where key should be in node"""
	var i = 0
	while i < node.get_key_count() and node.keys[i] != null and node.keys[i] < key:
		i += 1
	return i

func delete_from_leaf(node: BTreeNode, index: int):
	"""Delete key from leaf node"""
	for i in range(index, node.get_key_count() - 1):
		node.keys[i] = node.keys[i + 1]
	node.keys[node.get_key_count() - 1] = null

func delete_from_internal(node: BTreeNode, index: int):
	"""Delete key from internal node"""
	var key = node.keys[index]
	
	# Find predecessor or successor
	if node.children[index].get_key_count() >= tree_degree:
		# Replace with predecessor
		var predecessor = get_predecessor(node, index)
		node.keys[index] = predecessor
		delete_from_node(node.children[index], predecessor)
	elif node.children[index + 1].get_key_count() >= tree_degree:
		# Replace with successor
		var successor = get_successor(node, index)
		node.keys[index] = successor
		delete_from_node(node.children[index + 1], successor)
	else:
		# Merge children and delete
		merge_children(node, index)
		delete_from_node(node.children[index], key)

func get_predecessor(node: BTreeNode, index: int) -> int:
	"""Get predecessor of key at index"""
	var current = node.children[index]
	while not current.is_leaf:
		current = current.children[current.get_child_count() - 1]
	return current.keys[current.get_key_count() - 1]

func get_successor(node: BTreeNode, index: int) -> int:
	"""Get successor of key at index"""
	var current = node.children[index + 1]
	while not current.is_leaf:
		current = current.children[0]
	return current.keys[0]

func fill_child(node: BTreeNode, index: int):
	"""Fill child that has minimum number of keys"""
	# Try to borrow from left sibling
	if index > 0 and node.children[index - 1].get_key_count() >= tree_degree:
		borrow_from_prev(node, index)
	# Try to borrow from right sibling
	elif index < node.get_child_count() - 1 and node.children[index + 1].get_key_count() >= tree_degree:
		borrow_from_next(node, index)
	# Merge with sibling
	else:
		if index < node.get_child_count() - 1:
			merge_children(node, index)
		else:
			merge_children(node, index - 1)

func borrow_from_prev(node: BTreeNode, index: int):
	"""Borrow key from previous sibling"""
	var child = node.children[index]
	var sibling = node.children[index - 1]
	
	# Move key from parent to child
	for i in range(child.get_key_count(), 0, -1):
		child.keys[i] = child.keys[i - 1]
	child.keys[0] = node.keys[index - 1]
	
	# Move child pointer if not leaf
	if not child.is_leaf:
		for i in range(child.get_child_count(), 0, -1):
			child.children[i] = child.children[i - 1]
		child.children[0] = sibling.children[sibling.get_child_count() - 1]
		sibling.children[sibling.get_child_count() - 1] = null
	
	# Move key from sibling to parent
	node.keys[index - 1] = sibling.keys[sibling.get_key_count() - 1]
	sibling.keys[sibling.get_key_count() - 1] = null

func borrow_from_next(node: BTreeNode, index: int):
	"""Borrow key from next sibling"""
	var child = node.children[index]
	var sibling = node.children[index + 1]
	
	# Move key from parent to child
	child.keys[child.get_key_count()] = node.keys[index]
	
	# Move child pointer if not leaf
	if not child.is_leaf:
		child.children[child.get_child_count()] = sibling.children[0]
		for i in range(sibling.get_child_count() - 1):
			sibling.children[i] = sibling.children[i + 1]
		sibling.children[sibling.get_child_count() - 1] = null
	
	# Move key from sibling to parent
	node.keys[index] = sibling.keys[0]
	
	# Shift sibling keys
	for i in range(sibling.get_key_count() - 1):
		sibling.keys[i] = sibling.keys[i + 1]
	sibling.keys[sibling.get_key_count() - 1] = null

func merge_children(node: BTreeNode, index: int):
	"""Merge child with its sibling"""
	var child = node.children[index]
	var sibling = node.children[index + 1]
	
	# Pull key from parent
	child.keys[tree_degree - 1] = node.keys[index]
	
	# Copy keys from sibling
	for i in range(sibling.get_key_count()):
		child.keys[i + tree_degree] = sibling.keys[i]
	
	# Copy children from sibling if not leaf
	if not child.is_leaf:
		for i in range(sibling.get_child_count()):
			child.children[i + tree_degree] = sibling.children[i]
	
	# Shift parent's keys and children
	for i in range(index, node.get_key_count() - 1):
		node.keys[i] = node.keys[i + 1]
	node.keys[node.get_key_count() - 1] = null
	
	for i in range(index + 1, node.get_child_count() - 1):
		node.children[i] = node.children[i + 1]
	node.children[node.get_child_count() - 1] = null
	
	total_nodes -= 1

func update_tree_positions():
	"""Update 3D positions of all nodes"""
	if not root:
		return
	
	var level_nodes = {}
	collect_level_nodes(root, 0, level_nodes)
	
	for level in level_nodes.keys():
		var nodes = level_nodes[level]
		var node_count = nodes.size()
		var start_x = -(node_count - 1) * node_spacing / 2.0
		
		for i in range(node_count):
			var node = nodes[i]
			node.position = Vector3(
				start_x + i * node_spacing,
				level * level_height,
				0
			)

func collect_level_nodes(node: BTreeNode, level: int, level_dict: Dictionary):
	"""Collect nodes at each level for positioning"""
	if not level_dict.has(level):
		level_dict[level] = []
	
	level_dict[level].append(node)
	
	if not node.is_leaf:
		for child in node.children:
			if child:
				collect_level_nodes(child, level + 1, level_dict)

func update_visualization():
	"""Update 3D visualization of B-Tree"""
	clear_visualization()
	
	if not root:
		return
	
	visualize_tree(root)
	create_connections()

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

func visualize_tree(node: BTreeNode):
	"""Recursively visualize tree nodes"""
	if not node:
		return
	
	# Determine node color
	var color = internal_node_color
	if node == root:
		color = root_node_color
	elif node.is_leaf:
		color = leaf_node_color
	
	create_node_visualization(node, color)
	
	# Visualize children
	if not node.is_leaf:
		for child in node.children:
			if child:
				visualize_tree(child)

func create_node_visualization(node: BTreeNode, color: Color):
	"""Create 3D visualization for a node"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var key_count = node.get_key_count()
	
	# Size box based on number of keys
	mesh.size = Vector3(
		max(1.0, key_count * 0.4 + 0.6),
		0.4,
		0.8
	)
	
	mesh_instance.mesh = mesh
	mesh_instance.position = node.position
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	node_meshes.append(mesh_instance)
	node.mesh_instance = mesh_instance
	
	# Add key labels
	create_key_labels(node)

func create_key_labels(node: BTreeNode):
	"""Create labels for keys in node"""
	var key_count = node.get_key_count()
	
	for i in range(key_count):
		if node.keys[i] != null:
			var label = Label3D.new()
			label.text = str(node.keys[i])
			label.position = Vector3(
				node.position.x - (key_count - 1) * 0.2 + i * 0.4,
				node.position.y + 0.5,
				node.position.z
			)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(label)
			node_meshes.append(label)

func create_connections():
	"""Create visual connections between parent and child nodes"""
	if not root:
		return
	
	create_node_connections(root)

func create_node_connections(node: BTreeNode):
	"""Create connections for a specific node"""
	if node.is_leaf:
		return
	
	for child in node.children:
		if child:
			var connection = create_connection_line(node.position, child.position)
			add_child(connection)
			connection_meshes.append(connection)
			
			create_node_connections(child)

func create_connection_line(from_pos: Vector3, to_pos: Vector3) -> MeshInstance3D:
	"""Create visual connection line between nodes"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.02
	mesh.height = from_pos.distance_to(to_pos)
	
	mesh_instance.mesh = mesh
	mesh_instance.position = (from_pos + to_pos) / 2.0
	mesh_instance.look_at(to_pos, Vector3.UP)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = pointer_color
	material.emission_enabled = true
	material.emission = pointer_color * 0.2
	mesh_instance.material_override = material
	
	return mesh_instance

func _on_operation_timer_timeout():
	"""Handle animation timer for step-by-step operations"""
	if current_demo_index < demo_keys.size():
		insert_key(demo_keys[current_demo_index])
		current_demo_index += 1
		update_ui()
	else:
		operation_timer.stop()
		print("Demo complete!")

func update_ui():
	"""Update UI with current B-Tree state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(40):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 40:
		labels[0].text = "🌳 B-Tree - Hierarchical Data Organization"
		labels[1].text = "Degree (t): " + str(tree_degree) + " (Order: " + str(2 * tree_degree - 1) + ")"
		labels[2].text = "Max keys per node: " + str(2 * tree_degree - 1)
		labels[3].text = "Min keys per node: " + str(tree_degree - 1)
		labels[4].text = ""
		labels[5].text = "Tree Statistics:"
		labels[6].text = "Height: " + str(tree_height)
		labels[7].text = "Total Nodes: " + str(total_nodes)
		labels[8].text = "Total Keys: " + str(total_keys)
		labels[9].text = "Operations: " + str(operations_performed)
		labels[10].text = ""
		labels[11].text = "Performance Metrics:"
		labels[12].text = "Disk Accesses: " + str(disk_accesses)
		labels[13].text = "Cache Hits: " + str(cache_hits)
		labels[14].text = "Cache Misses: " + str(cache_misses)
		labels[15].text = "Avg Keys/Node: " + str(float(total_keys) / max(1, total_nodes))
		labels[16].text = ""
		labels[17].text = "B-Tree Properties:"
		labels[18].text = "Self-Balancing: ✓"
		labels[19].text = "Sorted Keys: ✓"
		labels[20].text = "Logarithmic Operations: ✓"
		labels[21].text = "Database Optimized: ✓"
		labels[22].text = ""
		labels[23].text = "Current Operation:"
		labels[24].text = "Mode: " + insertion_mode
		labels[25].text = "Status: " + get_operation_status()
		labels[26].text = "Demo Progress: " + str(current_demo_index) + "/" + str(demo_keys.size())
		labels[27].text = ""
		labels[28].text = "Database Simulation:"
		labels[29].text = "Page Size: " + str(2 * tree_degree - 1) + " keys"
		labels[30].text = "Disk Block Access: " + ("Simulated" if show_disk_access_simulation else "Off")
		labels[31].text = "Cache Behavior: " + ("Active" if cache_simulation else "Off")
		labels[32].text = ""
		labels[33].text = "Tree Balance Analysis:"
		labels[34].text = "Min Height: " + str(get_min_possible_height())
		labels[35].text = "Max Height: " + str(get_max_possible_height())
		labels[36].text = "Current Efficiency: " + get_height_efficiency()
		labels[37].text = ""
		labels[38].text = "Controls: I - Insert, D - Delete, S - Search, R - Reset"
		labels[39].text = "🏳️‍🌈 Explores data democracy & information hierarchies"

func get_operation_status() -> String:
	"""Get current operation status"""
	if operation_timer.is_stopped():
		return "Ready"
	else:
		return "Inserting..."

func get_min_possible_height() -> int:
	"""Calculate minimum possible height for current number of keys"""
	if total_keys == 0:
		return 0
	return int(ceil(log(total_keys + 1) / log(tree_degree * 2)))

func get_max_possible_height() -> int:
	"""Calculate maximum possible height for current number of keys"""
	if total_keys == 0:
		return 0
	return int(ceil(log(total_keys) / log(tree_degree)))

func get_height_efficiency() -> String:
	"""Calculate height efficiency percentage"""
	if total_keys == 0:
		return "N/A"
	
	var min_height = get_min_possible_height()
	var efficiency = float(min_height) / float(tree_height) * 100.0
	return str(int(efficiency)) + "%"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_I:
				var key = randi_range(1, 100)
				insert_key(key)
			KEY_D:
				if total_keys > 0:
					var key = randi_range(1, 100)
					delete_key(key)
			KEY_S:
				if total_keys > 0:
					var key = randi_range(1, 100)
					var result = search_key(key)
					print("Search for ", key, ": ", "Found" if result else "Not found")
					highlight_search_path()
			KEY_R:
				reset_btree()
			KEY_1:
				change_degree(2)
			KEY_2:
				change_degree(3)
			KEY_3:
				change_degree(4)
			KEY_4:
				change_degree(5)
			KEY_SPACE:
				if operation_timer.is_stopped():
					start_demo()
				else:
					operation_timer.stop()

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

func reset_btree():
	"""Reset B-Tree to initial state"""
	clear_visualization()
	total_nodes = 0
	total_keys = 0
	tree_height = 0
	disk_accesses = 0
	operations_performed = 0
	current_demo_index = 0
	operation_timer.stop()
	
	initialize_btree()
	update_ui()
	print("B-Tree reset")

func change_degree(new_degree: int):
	"""Change B-Tree degree"""
	tree_degree = new_degree
	reset_btree()
	print("Changed B-Tree degree to ", new_degree)

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive B-Tree algorithm information"""
	return {
		"name": "B-Tree",
		"description": "Self-balancing tree for databases and file systems",
		"properties": {
			"degree": tree_degree,
			"order": 2 * tree_degree - 1,
			"height": tree_height,
			"total_nodes": total_nodes,
			"total_keys": total_keys
		},
		"performance": {
			"disk_accesses": disk_accesses,
			"operations_performed": operations_performed,
			"height_efficiency": get_height_efficiency()
		},
		"complexity": {
			"search": "O(log n)",
			"insert": "O(log n)",
			"delete": "O(log n)",
			"space": "O(n)"
		}
	} 