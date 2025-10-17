extends Node3D

# Script to create a cross with 1 meter lines

func _ready():
	setup_cross()

func setup_cross():
	# Create a cross with two perpendicular 1 meter lines
	var half_length = 0.5

	# Configure the two lines forming the cross
	var line_configs = [
		{"line_name": "Line1", "start": Vector3(-half_length, 0, 0), "end": Vector3(half_length, 0, 0)},  # Horizontal
		{"line_name": "Line2", "start": Vector3(0, -half_length, 0), "end": Vector3(0, half_length, 0)}   # Vertical
	]

	for config in line_configs:
		var line_node = get_node_or_null(config["line_name"] + "/lineContainer")
		if line_node:
			var sphere1 = line_node.get_node_or_null("GrabSphere")
			var sphere2 = line_node.get_node_or_null("GrabSphere2")

			if sphere1 and sphere2:
				sphere1.position = config["start"]
				sphere2.position = config["end"]

			# Set line properties
			line_node.line_thickness = 0.01
			line_node.line_color = Color(1.0, 0.5, 0.3, 1.0)

			# Update connections after positioning
			if line_node.has_method("update_connections"):
				line_node.update_connections()
