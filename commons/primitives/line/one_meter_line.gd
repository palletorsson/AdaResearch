extends Node3D

# Script to ensure the one meter line is correctly positioned

func _ready():
	var line = get_node_or_null("Line/lineContainer")
	if line:
		# Ensure grab spheres are exactly 1 meter apart
		var sphere1 = line.get_node_or_null("GrabSphere")
		var sphere2 = line.get_node_or_null("GrabSphere2")

		if sphere1 and sphere2:
			sphere1.position = Vector3(-0.5, 0, 0)
			sphere2.position = Vector3(0.5, 0, 0)

		# Set line properties
		line.line_thickness = 0.01
		line.line_color = Color(0.2, 0.8, 1.0, 1.0)

	# Update connections after positioning
	if line and line.has_method("update_connections"):
		line.update_connections()
