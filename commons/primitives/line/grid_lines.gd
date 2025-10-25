extends Node3D

# Script to create a grid of lines on the XZ plane (horizontal ground plane)

@export var grid_size: int = 5  # Number of grid cells (will have grid_size+1 lines in each direction)
@export var cell_spacing: float = 1.0  # Distance between grid lines in meters

func _ready():
	setup_grid()

func setup_grid():
	var half_size = (grid_size * cell_spacing) / 2.0
	var line_index = 1

	# Create lines parallel to X axis (going along X, at different Z positions)
	for i in range(grid_size + 1):
		var z_pos = -half_size + (i * cell_spacing)
		var line_node = get_node_or_null("LineX" + str(i + 1) + "/lineContainer")
		if line_node:
			line_node.set_positions(
				Vector3(-half_size, 0, z_pos),
				Vector3(half_size, 0, z_pos)
			)
			# Highlight center lines
			if i == grid_size / 2:
				line_node.set_line_properties(0.01, Color(1.0, 0.3, 0.3, 1.0))  # Red for X axis
			else:
				line_node.set_line_properties(0.006, Color(0.6, 0.6, 0.6, 0.8))

	# Create lines parallel to Z axis (going along Z, at different X positions)
	for i in range(grid_size + 1):
		var x_pos = -half_size + (i * cell_spacing)
		var line_node = get_node_or_null("LineZ" + str(i + 1) + "/lineContainer")
		if line_node:
			line_node.set_positions(
				Vector3(x_pos, 0, -half_size),
				Vector3(x_pos, 0, half_size)
			)
			# Highlight center lines
			if i == grid_size / 2:
				line_node.set_line_properties(0.01, Color(0.3, 0.3, 1.0, 1.0))  # Blue for Z axis
			else:
				line_node.set_line_properties(0.006, Color(0.6, 0.6, 0.6, 0.8))
