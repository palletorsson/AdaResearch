extends Node3D

# @identity
# essence: [100m, 10m, 1m, 10cm, 1mm] — a logarithmic ladder of reference lengths made tangible
# desire: learner viscerally understands the orders of magnitude separating human-scale from micro and macro
# critical_parameter: the 1m line — the human-body reference; all others derive meaning relative to it
# triggers: nothing — static configuration; the experience is spatial proximity and comparison
# emerges: the body as unit — standing next to 1m makes all other lengths relative to your own height
# needs: [missing VR controls — static reference display]
# relationships: sibling to perspective_lines; both configure existing line nodes for a specific lesson
# truth: every measurement is relative — scale only makes sense from a chosen reference

# Script to ensure scale lines are positioned correctly at different measurements

func _ready():
	setup_scale_lines()

func setup_scale_lines():
	# Define the scale lines with their measurements - larger at top, smaller at bottom
	var scales = [
		{"name": "Line_100m", "distance": 100.0, "thickness": 0.02, "color": Color(1.0, 0.2, 0.4, 1.0), "y_pos": 4.0},
		{"name": "Line_10m", "distance": 10.0, "thickness": 0.015, "color": Color(1.0, 0.5, 0.2, 1.0), "y_pos": 2.0},
		{"name": "Line_1m", "distance": 1.0, "thickness": 0.01, "color": Color(1.0, 0.8, 0.2, 1.0), "y_pos": 1.0},
		{"name": "Line_10cm", "distance": 0.1, "thickness": 0.005, "color": Color(0.4, 1.0, 0.4, 1.0), "y_pos": 0.5},
		{"name": "Line_1mm", "distance": 0.001, "thickness": 0.003, "color": Color(0.6, 0.4, 1.0, 1.0), "y_pos": 0.1}
	]

	# Configure each scale line
	for scale in scales:
		var line_node = get_node_or_null(scale["name"] + "/lineContainer")
		if line_node:
			# Set positions at the correct distance
			var half_distance = scale["distance"] / 2.0
			line_node.set_positions(Vector3(-half_distance, 0, 0), Vector3(half_distance, 0, 0))

			# Set line properties
			line_node.set_line_properties(scale["thickness"], scale["color"])

		# Position the parent line node at the correct Y position
		var parent_line = get_node_or_null(scale["name"])
		if parent_line:
			parent_line.position.y = scale["y_pos"]
