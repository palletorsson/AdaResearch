extends Node3D

# Script to ensure perspective lines converge correctly to a vanishing point

func _ready():
	setup_perspective_lines()

func setup_perspective_lines():
	# Set up four lines converging to origin (0,0,0) from a rectangular frame
	var vanishing_point = Vector3.ZERO 

	# Define the four corners of the rectangle in the distance
	var corners = [
		Vector3(-0.25, -0.25, -2.0),  # Bottom-left
		Vector3(0.25, -0.25, -2.0),   # Bottom-right
		Vector3(-0.25, 0.25, -2.0),   # Top-left
		Vector3(0.25, 0.25, -2.0)     # Top-right
	]

	# Configure each line
	for i in range(4):
		var line_node = get_node_or_null("Line" + str(i + 1) + "/lineContainer")
		if line_node:
			var sphere1 = line_node.get_node_or_null("GrabSphere")
			var sphere2 = line_node.get_node_or_null("GrabSphere2")

			if sphere1 and sphere2:
				# One point at the corner, one at the vanishing point
				sphere1.position = corners[i]
				sphere2.position = vanishing_point

			# Set line properties
			line_node.line_thickness = 0.008
			line_node.line_color = Color(1.0, 0.3, 0.5, 1.0)

			# Update connections after positioning
			if line_node.has_method("update_connections"):
				line_node.update_connections()
