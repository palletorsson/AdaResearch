extends Node3D

# Script to create an X cross with 1 meter diagonal lines

# @identity
# essence: two 1-metre diagonal lines crossed into an X — the simplest figure where lines meet and a point is born from intersection
# desire: the learner sees that a point can be defined not by placement but by where two lines agree — coordinates as consequence, not given
# critical_parameter: the two line endpoints (±0.5 corners); rotate or shift one and the crossing point slides off centre
# triggers: setup_cross on ready wires each child lineContainer via set_positions + set_line_properties
# emerges: that intersection is a second way to make a point — the grid's cells are nothing but a field of such crossings
# needs: [has two configured diagonals meeting at origin [has], missing a movable endpoint to watch the crossing point track]
# relationships: made of the line primitive; parent to the grid, whose every node is a crossing like this one
# truth: where two commitments cross, a location appears that neither line chose alone


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
