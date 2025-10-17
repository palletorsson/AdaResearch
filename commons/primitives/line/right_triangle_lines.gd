extends Node3D

# Script to create a right triangle with 1 meter sides and hypotenuse

func _ready():
	setup_right_triangle()

func setup_right_triangle():
	# Create a horizontal right triangle with 1 meter sides (lying flat on XZ plane)
	# Base = 1m, Height = 1m, Hypotenuse = sqrt(2)m ≈ 1.414m
	var side_length = 1.0
	var hypotenuse = sqrt(2.0) * side_length

	# Define the three vertices of the right triangle (horizontal on XZ plane)
	# Right angle at origin
	var vertices = [
		Vector3(0, 0, 0),                    # Origin (right angle)
		Vector3(side_length, 0, 0),          # Right along X axis
		Vector3(0, 0, side_length)           # Forward along Z axis
	]

	# Configure the three lines forming the right triangle
	var line_configs = [
		{"line_name": "Line1", "start": vertices[0], "end": vertices[1], "label": "Base (1m)"},      # Base
		{"line_name": "Line2", "start": vertices[0], "end": vertices[2], "label": "Height (1m)"},    # Height
		{"line_name": "Line3", "start": vertices[1], "end": vertices[2], "label": "Hypotenuse (%.3fm)" % hypotenuse}  # Hypotenuse
	]

	for config in line_configs:
		var line_node = get_node_or_null(config["line_name"] + "/lineContainer")
		if line_node:
			var sphere1 = line_node.get_node_or_null("GrabSphere")
			var sphere2 = line_node.get_node_or_null("GrabSphere2")

			if sphere1 and sphere2:
				sphere1.position = config["start"]
				sphere2.position = config["end"]

			# Set line properties - make hypotenuse a different color
			if config["line_name"] == "Line3":
				line_node.line_thickness = 0.012
				line_node.line_color = Color(1.0, 0.3, 0.8, 1.0)  # Pink for hypotenuse
			else:
				line_node.line_thickness = 0.01
				line_node.line_color = Color(0.3, 1.0, 0.8, 1.0)  # Cyan for sides

			# Update connections after positioning
			if line_node.has_method("update_connections"):
				line_node.update_connections()
