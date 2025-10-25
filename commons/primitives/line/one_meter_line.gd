extends Node3D

# Script to ensure the one meter line is correctly positioned

func _ready():
	var line = get_node_or_null("Line/lineContainer")
	if line:
		# Set positions exactly 1 meter apart
		line.set_positions(Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0))

		# Set line properties
		line.set_line_properties(0.01, Color(0.2, 0.8, 1.0, 1.0))
