# next_cube_example.gd
# Example of how to use the NextCube in the color grid scene
extends Node3D

# Reference to the grid colorizer
@onready var grid_colorizer = $GridColorizer  # Adjust path as needed

# Array of next cubes in the scene
var next_cubes: Array[NextCube] = []

func _ready():
	# Find all NextCube nodes in the scene
	find_next_cubes()
	
	# Connect to their signals
	connect_next_cube_signals()
	
	print("NextCubeExample: Ready with %d next cubes detected" % next_cubes.size())

func find_next_cubes():
	"""Find all NextCube instances in the scene"""
	next_cubes.clear()
	find_next_cubes_recursive(get_tree().current_scene)

func find_next_cubes_recursive(node: Node):
	"""Recursively find NextCube nodes"""
	if node is NextCube:
		next_cubes.append(node as NextCube)
		print("Found NextCube at: %s" % node.global_position)
	
	for child in node.get_children():
		find_next_cubes_recursive(child)

func connect_next_cube_signals():
	"""Connect to all next cube signals"""
	for next_cube in next_cubes:
		if not next_cube.next_requested.is_connected(_on_next_requested):
			next_cube.next_requested.connect(_on_next_requested)
			print("Connected to NextCube at %s" % next_cube.global_position)

func _on_next_requested(from_position: Vector3):
	"""Handle next pattern request from any next cube"""
	print("🎨 Next pattern requested from position: %s" % from_position)
	
	# If grid colorizer exists, advance to next pattern
	if grid_colorizer and grid_colorizer.has_method("advance_to_next_pattern"):
		grid_colorizer.advance_to_next_pattern()
	else:
		print("⚠️ GridColorizer not found or doesn't support pattern advancement")

# Alternative: Manual pattern cycling
func _on_next_cube_activated():
	"""Alternative handler for simpler pattern cycling"""
	if grid_colorizer:
		# Manually advance the pattern index
		if grid_colorizer.has_method("get_current_pattern_index"):
			var current_index = grid_colorizer.get_current_pattern_index()
			var pattern_count = grid_colorizer.get_pattern_count()
			var next_index = (current_index + 1) % pattern_count
			
			if grid_colorizer.has_method("set_pattern_by_index"):
				grid_colorizer.set_pattern_by_index(next_index)
				print("🎨 Advanced to pattern %d/%d" % [next_index + 1, pattern_count])

# Example usage in a map JSON:
# "utilities": [
#   [" ", " ", " ", " ", " ", "n", " ", " ", " ", " ", " "],
#   [" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "],
#   ...
# ]
# This would place a next cube in the center of the grid
