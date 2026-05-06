extends Node3D

# @identity
# essence: all lines → (0,0,0) — convergence to a single vanishing point as perspective law
# desire: learner sees how parallel lines in 3D space appear to converge when projected onto a 2D view
# critical_parameter: the shared origin — all four line endpoints are forced to (0,0,0)
# triggers: nothing at runtime — configured once in _ready() and remains static
# emerges: the vanishing point as the infinite location of all parallel directions — a limit, not a place
# needs: [missing VR controls — static demonstration only]
# relationships: sibling to scale_lines; both are special configurations of the line primitive
# truth: perspective is not distortion — it is projection, and projection reveals the vanishing point

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
