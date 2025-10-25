extends Node3D

# Script to ensure perspective lines converge correctly to a vanishing point

func _ready():
	setup_perspective_lines()

func setup_perspective_lines():
	# Set up four lines converging to origin (0,0,0) from a rectangular frame
	var vanishing_point = Vector3.ZERO

	# Define the four corners of the rectangle in the distance
	var corners = [
		Vector3(-0.5, -0.5, -2.0),  # Bottom-left
		Vector3(0.5, -0.5, -2.0),   # Bottom-right
		Vector3(-0.5, 0.5, -2.0),   # Top-left
		Vector3(0.5, 0.5, -2.0)     # Top-right
	]

	# Configure each line
	for i in range(4):
		var line_node = get_node_or_null("Line" + str(i + 1) + "/lineContainer")
		if line_node:
			# Set positions - one point at the corner, one at the vanishing point
			line_node.set_positions(corners[i], vanishing_point)

			# Set line properties
			line_node.set_line_properties(0.008, Color(1.0, 0.3, 0.5, 1.0))
