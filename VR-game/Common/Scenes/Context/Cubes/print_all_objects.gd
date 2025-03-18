extends Node

func _ready():
	await get_tree().create_timer(4.0).timeout
	print_scene_tree(get_tree().root)

func print_scene_tree(node: Node, indent: String = ""):
	# Print the current node
	print(indent + node.name + " (Type: " + node.get_class() + ")")
	
	# Print node-specific properties that might be useful
	if node is Node3D:
		print(indent + "  Position: " + str(node.position))
		print(indent + "  Visible: " + str(node.visible))
	
	# Recursively print child nodes
	for child in node.get_children():
		print_scene_tree(child, indent + "  ")

# Alternative method to print all nodes with more details
func print_detailed_scene_tree():
	print("--- Detailed Scene Tree ---")
	_print_node_details(get_tree().root)

func _print_node_details(node: Node, indent: String = ""):
	# Print basic node information
	print(indent + "Node: " + node.name)
	print(indent + "  Type: " + node.get_class())
	
	# Print additional details based on node type
	if node is Node3D:
		print(indent + "  Position: " + str(node.position))
		print(indent + "  Rotation: " + str(node.rotation))
		print(indent + "  Scale: " + str(node.scale))
		print(indent + "  Visible: " + str(node.visible))
	
	if node is MeshInstance3D:
		print(indent + "  Mesh: " + (str(node.mesh) if node.mesh else "None"))
	
	if node is Camera3D:
		print(indent + "  Current: " + str(node.current))
	
	# Print script attached to the node
	if node.get_script():
		print(indent + "  Script: " + str(node.get_script().resource_path))
	
	# Recursively print child nodes
	for child in node.get_children():
		_print_node_details(child, indent + "  ")

# Method to find nodes by type
func find_nodes_by_type(type: String) -> Array:
	var matching_nodes = []
	_find_nodes_recursive(get_tree().root, type, matching_nodes)
	return matching_nodes

func _find_nodes_recursive(node: Node, type: String, result: Array):
	if node.is_class(type):
		result.append(node)
	
	for child in node.get_children():
		_find_nodes_recursive(child, type, result)
