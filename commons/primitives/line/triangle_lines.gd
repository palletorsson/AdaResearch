extends Node3D

# Script to create an equilateral triangle with 1 meter sides

func _ready():
	setup_triangle()

func setup_triangle():
	# Create an equilateral triangle with 1 meter sides
	# Height of equilateral triangle = side * sqrt(3) / 2
	var side_length = 1.0
	var height = side_length * sqrt(3.0) / 2.0

	# Define the three vertices of the triangle
	# Centered at origin, with base parallel to X axis
	var vertices = [
		Vector3(-side_length / 2.0, -height / 3.0, 0),  # Bottom-left
		Vector3(side_length / 2.0, -height / 3.0, 0),   # Bottom-right
		Vector3(0, height * 2.0 / 3.0, 0)                # Top
	]

	# Configure the three lines forming the triangle
	var line_configs = [
		{"line_name": "Line1", "start": vertices[0], "end": vertices[1]},  # Bottom
		{"line_name": "Line2", "start": vertices[1], "end": vertices[2]},  # Right side
		{"line_name": "Line3", "start": vertices[2], "end": vertices[0]}   # Left side
	]

	for config in line_configs:
		var line_node = get_node_or_null(config["line_name"] + "/lineContainer")
		if line_node:
			# Set positions
			line_node.set_positions(config["start"], config["end"])

			# Set line properties
			line_node.set_line_properties(0.01, Color(0.3, 0.8, 1.0, 1.0))
