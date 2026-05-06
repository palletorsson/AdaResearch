extends Node3D

# Script to create a right triangle with 1 meter sides and hypotenuse

func _ready():
	setup_right_triangle()

func setup_right_triangle():
	# Create a horizontal right triangle with 1 meter sides (lying flat on XZ plane)
	# Base = 1m, Height = 1m, Hypotenuse = sqrt(2)m ≈ 1.414m
	var side_length = 1.0

	# Define the three vertices of the right triangle (horizontal on XZ plane)
	# Right angle at origin
	var vertices = [
		Vector3(0, 0, 0),                    # Origin (right angle)
		Vector3(side_length, 0, 0),          # Right along X axis
		Vector3(0, 0, side_length)           # Forward along Z axis
	]

	# Configure the three lines forming the right triangle
	var line_configs = [
		{"line_name": "Line1", "start": vertices[0], "end": vertices[1]},  # Base
		{"line_name": "Line2", "start": vertices[0], "end": vertices[2]},  # Height
		{"line_name": "Line3", "start": vertices[1], "end": vertices[2]}   # Hypotenuse
	]

	for config in line_configs:
		var line_node = get_node_or_null(config["line_name"] + "/lineContainer")
		if line_node:
			# Set positions
			line_node.set_positions(config["start"], config["end"])

			# Set line properties - make hypotenuse a different color
			if config["line_name"] == "Line3":
				line_node.set_line_properties(0.012, Color(1.0, 0.3, 0.8, 1.0))  # Pink for hypotenuse
			else:
				line_node.set_line_properties(0.01, Color(0.3, 1.0, 0.8, 1.0))  # Cyan for sides
