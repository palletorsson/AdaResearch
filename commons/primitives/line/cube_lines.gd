extends Node3D

# Script to create a 1x1x1 cube outline with lines

func _ready():
	setup_cube()

func setup_cube():
	# Define the 8 vertices of a 1x1x1 cube centered at origin
	var vertices = [
		# Bottom face (y = -0.5)
		Vector3(-0.5, -0.5, -0.5),  # 0: Bottom-back-left
		Vector3(0.5, -0.5, -0.5),   # 1: Bottom-back-right
		Vector3(0.5, -0.5, 0.5),    # 2: Bottom-front-right
		Vector3(-0.5, -0.5, 0.5),   # 3: Bottom-front-left
		# Top face (y = 0.5)
		Vector3(-0.5, 0.5, -0.5),   # 4: Top-back-left
		Vector3(0.5, 0.5, -0.5),    # 5: Top-back-right
		Vector3(0.5, 0.5, 0.5),     # 6: Top-front-right
		Vector3(-0.5, 0.5, 0.5)     # 7: Top-front-left
	]

	# Define the 12 edges of the cube
	var line_configs = [
		# Bottom face (4 edges)
		{"line_name": "Line1", "start": vertices[0], "end": vertices[1]},   # Back edge
		{"line_name": "Line2", "start": vertices[1], "end": vertices[2]},   # Right edge
		{"line_name": "Line3", "start": vertices[2], "end": vertices[3]},   # Front edge
		{"line_name": "Line4", "start": vertices[3], "end": vertices[0]},   # Left edge
		# Top face (4 edges)
		{"line_name": "Line5", "start": vertices[4], "end": vertices[5]},   # Back edge
		{"line_name": "Line6", "start": vertices[5], "end": vertices[6]},   # Right edge
		{"line_name": "Line7", "start": vertices[6], "end": vertices[7]},   # Front edge
		{"line_name": "Line8", "start": vertices[7], "end": vertices[4]},   # Left edge
		# Vertical edges (4 edges)
		{"line_name": "Line9", "start": vertices[0], "end": vertices[4]},   # Back-left vertical
		{"line_name": "Line10", "start": vertices[1], "end": vertices[5]},  # Back-right vertical
		{"line_name": "Line11", "start": vertices[2], "end": vertices[6]},  # Front-right vertical
		{"line_name": "Line12", "start": vertices[3], "end": vertices[7]}   # Front-left vertical
	]

	# Configure each line
	for config in line_configs:
		var line_node = get_node_or_null(config["line_name"] + "/lineContainer")
		if line_node:
			# Set positions
			line_node.set_positions(config["start"], config["end"])

			# Set line properties
			line_node.set_line_properties(0.008, Color(0.4, 0.8, 1.0, 1.0))
