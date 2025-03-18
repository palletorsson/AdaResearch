extends Node3D

# Store references to all cubes in the scene
var cube_nodes: Array[Node3D] = []
var info_board: Node3D = null
var explain_board: Node3D = null
# Constants for animation
const BLINK_DURATION = 0.5
const PAUSE_DURATION = 0.5

func _ready():
	# Find all cubes in the scene
	find_all_cubes()
	
	set_nodes_visibility(["InfoBoard", "ExplainBoard", "Mondrian2d", "ZeldaTilemap"], false)
	# Start the cube sequence
	start_cube_sequence()

func find_all_cubes():
	"""
	Find all MeshInstance3D nodes that look like cubes
	"""
	cube_nodes.clear()
	find_cubes_recursive(get_tree().root)
	print("Found " + str(cube_nodes.size()) + " cube-like nodes")

func find_cubes_recursive(node: Node):
	"""
	Recursively find cube-like MeshInstance3D nodes
	"""
	if node is MeshInstance3D and "base" in node.name.to_lower():
		var mesh = node.mesh
		if mesh is BoxMesh:
			cube_nodes.append(node)
	
	for child in node.get_children():
		find_cubes_recursive(child)
# This function returns a dictionary where each key is a target string 
# and the value is the first node found whose name contains that string.
func find_nodes_by_names(target_names: Array, root: Node = null) -> Dictionary:
	if root == null:
		root = get_tree().root
	var results = {}
	for target in target_names:
		results[target] = _find_node_recursive(root, target)
	return results

# Recursive helper: returns the first node that contains the target in its name.
func _find_node_recursive(node: Node, target: String) -> Node:
	if target in node.name:
		return node
	for child in node.get_children():
		var found = _find_node_recursive(child, target)
		if found:
			return found
	return null

# You can also add a helper to toggle visibility on any node found.
func set_nodes_visibility(target_names: Array, visible: bool) -> void:
	var nodes = find_nodes_by_names(target_names)
	for key in nodes.keys():
		var node = nodes[key]
		if node and node.has_method("set_visible"):
			node.set_visible(visible)
			
func start_cube_sequence():
	# Sequence of cube animations
	await hide_all_cubes()
	await find_and_blink_specific_cube()
	await random_cube_play()
	await show_cubes_gradually()
	
	# After all cube animations complete, show the InfoBoard
	show_info_board()
	show_explain_board()
	set_nodes_visibility(["InfoBoard", "ExplainBoard", "Mondrian2d", "ZeldaTilemap"], true)


func hide_all_cubes() -> Signal:
	"""
	Hide all cubes with a small delay between each
	"""
	for cube in cube_nodes:
		cube.visible = false
		
	print("Hid all " + str(cube_nodes.size()) + " cubes")
	return get_tree().create_timer(5.0).timeout

func find_and_blink_specific_cube() -> Signal:
	"""
	Find and blink a specific cube (assuming grid-like arrangement)
	"""
	# Sort cubes by their global position
	cube_nodes.sort_custom(func(a, b): return a.global_position.z < b.global_position.z)
	
	# Assuming the 6th cube in the sorted list (index 5)
	if cube_nodes.size() > 5:
		var target_cube = cube_nodes[5]
		
		# First blink
		target_cube.visible = false
		await get_tree().create_timer(BLINK_DURATION).timeout
		
		# Show
		target_cube.visible = true
		await get_tree().create_timer(BLINK_DURATION).timeout
		
		# Second blink
		target_cube.visible = false
		await get_tree().create_timer(BLINK_DURATION).timeout
		
		# Final show
		target_cube.visible = true
	
	return get_tree().create_timer(1.0).timeout

func random_cube_play() -> Signal:
	"""
	Show and hide random cubes
	"""
	# Ensure we have cubes
	if cube_nodes.is_empty():
		return get_tree().create_timer(0.1).timeout
	
	# Show a random cube
	var random_show_cube = cube_nodes.pick_random()
	random_show_cube.visible = true
	
	# Wait a bit
	await get_tree().create_timer(1.0).timeout
	
	# Hide a random cube
	var random_hide_cube = cube_nodes.pick_random()
	random_hide_cube.visible = false
	
	return get_tree().create_timer(1.0).timeout

func show_cubes_gradually() -> void:
	"""
	Show all cubes one by one with a small delay
	"""
	for cube in cube_nodes:
		cube.visible = true
		await get_tree().create_timer(0.002).timeout

func show_info_board():
	"""
	Show the InfoBoard with a fade-in animation
	"""
	if info_board:
		# Create tween for smooth fade-in
		var tween = create_tween()
		
		# Make board visible but transparent
		info_board.visible = true

func show_explain_board():
	"""
	Show the InfoBoard with a fade-in animation
	"""
	if info_board:
		# Create tween for smooth fade-in
		var tween = create_tween()
		
		# Make board visible but transparent
		explain_board.visible = true


# Optional utility methods
func get_cube_names() -> Array:
	return cube_nodes.map(func(cube): return cube.name) 
