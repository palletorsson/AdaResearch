extends Node3D

# Configurable range for cube removal
@export var x_min: float = 2.0
@export var x_max: float = 4.0
@export var y_min: float = 0.0
@export var y_max: float = 2.0
@export var z_min: float = 2.0  # Start from Z=2 to skip rows 0-1
@export var z_max: float = 21.0

var timer: Timer
var all_boxes: Array = []

func _ready():
	# Create a timer that fires every 0.5 seconds
	timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Find all boxes initially
	find_all_boxes()
	
	# Display all found box names for inspection
	print("=== SCENE SCAN RESULTS ===")
	print("Found ", all_boxes.size(), " boxes total:")
	for i in range(all_boxes.size()):
		var box = all_boxes[i]
		if is_instance_valid(box):
			print("  ", i+1, ". Name: '", box.name, "' | Type: ", box.get_class(), " | Position: ", box.position)
		else:
			print("  ", i+1, ". [INVALID NODE]")
	print("=========================")
	
	# Start the timer
	timer.start()
	print("Started removing boxes every 0.5 seconds.")

func find_all_boxes():
	"""Find all box/cube nodes in the scene"""
	all_boxes.clear()
	var parent = get_parent()
	if not parent:
		print("No parent node found")
		return
	
	# Recursively find all boxes
	_find_boxes_recursive(parent)

func _find_boxes_recursive(node: Node):
	"""Recursively search for box/cube nodes"""
	# Check if this node is a box/cube
	if _is_box_node(node):
		all_boxes.append(node)
		print("Found box: ", node.name, " at position: ", node.position)
	
	# Search children
	for child in node.get_children():
		_find_boxes_recursive(child)

func _is_box_node(node: Node) -> bool:
	"""Check if a node is an instance of cube_scene.tscn but NOT a teleport and NOT in rows 0-1"""
	
	# Don't remove teleport nodes
	var name_lower = node.name.to_lower()
	if name_lower.contains("teleport"):
		return false
	
	# Don't remove boxes in rows 0 and 1 (Z position 0 and 1)
	if node.has_method("get") and node.get("position"):
		var pos = node.position
		if pos.z == 0 or pos.z == 1:
			return false
	
	# Check if this node is an instance of cube_scene.tscn
	# Method 1: Check if the scene file path matches
	if node.scene_file_path == "res://commons/primitives/cubes/cube_scene.tscn":
		return true
	
	# Method 2: Check if it's a Node3D with specific structure
	if node.get_class() == "Node3D":
		# Look for characteristic children of cube_scene.tscn
		# This depends on the actual structure of your cube_scene.tscn
		# You might need to adjust this based on what's inside the scene
		var has_cube_characteristics = false
		
		# Check for common cube scene characteristics
		# (Adjust these based on your actual cube_scene.tscn structure)
		for child in node.get_children():
			if child.get_class() == "MeshInstance3D":
				has_cube_characteristics = true
				break
			elif child.get_class() == "CollisionShape3D":
				has_cube_characteristics = true
				break
		
		if has_cube_characteristics:
			return true
	
	return false

func cleanup_invalid_boxes():
	"""Remove invalid/freed boxes from the list"""
	var valid_boxes = []
	for box in all_boxes:
		if is_instance_valid(box):
			valid_boxes.append(box)
		else:
			print("Cleaned up invalid box reference")
	
	all_boxes = valid_boxes

func _on_timer_timeout():
	"""Called every 0.5 seconds to remove one box"""
	# Clean up invalid references first
	cleanup_invalid_boxes()
	
	if all_boxes.size() == 0:
		print("No more boxes to remove!")
		timer.stop()
		return
	
	# Pick a random box to remove
	var random_index = randi() % all_boxes.size()
	var box_to_remove = all_boxes[random_index]
	
	# Check if the box is still valid
	if not is_instance_valid(box_to_remove):
		print("Box is no longer valid, removing from list")
		all_boxes.remove_at(random_index)
		return
	
	# Remove it from our list first
	all_boxes.remove_at(random_index)
	
	# Remove it from the scene
	print("Removing box: ", box_to_remove.name, " at position: ", box_to_remove.position)
	box_to_remove.queue_free()
	
	print("Boxes remaining: ", all_boxes.size())

# Manual function to start/stop the removal process
func start_removal():
	"""Start removing boxes every 0.5 seconds"""
	if timer:
		timer.start()
		print("Started box removal")

func stop_removal():
	"""Stop removing boxes"""
	if timer:
		timer.stop()
		print("Stopped box removal")

func reset_and_find_boxes():
	"""Reset the process and find all boxes again"""
	stop_removal()
	find_all_boxes()
	print("Reset complete. Found ", all_boxes.size(), " boxes.")
