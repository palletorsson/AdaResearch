extends Node3D

# Script to create an X cross with 1 meter diagonal lines

func _ready():
	setup_cross()

func setup_cross():
	# Create an X cross with two diagonal 1 meter lines
	var half_length = 0.5

	# Configure the two diagonal lines forming the X cross
	var line_configs = [
		{"line_name": "Line1", "start": Vector3(-half_length, -half_length, 0), "end": Vector3(half_length, half_length, 0)},  # Bottom-left to top-right
		{"line_name": "Line2", "start": Vector3(-half_length, half_length, 0), "end": Vector3(half_length, -half_length, 0)}   # Top-left to bottom-right
	]

	for config in line_configs:
		var line_node = get_node_or_null(config["line_name"] + "/lineContainer")
		if line_node:
			# Set positions
			line_node.set_positions(config["start"], config["end"])

			# Set line properties
			line_node.set_line_properties(0.01, Color(1.0, 0.5, 0.3, 1.0))
