
# Lighting system for organic atmosphere
class_name OrganicLighting
extends Node

func setup_organic_lighting(container: Node3D, space_size: Vector3):
	"""Create atmospheric lighting for the organic space"""
	
	# Main ambient light
	var ambient = DirectionalLight3D.new()
	ambient.light_energy = 0.3
	ambient.light_color = Color(0.9, 0.95, 1.0)
	ambient.position = Vector3(0, space_size.y * 0.5, 0)
	ambient.rotation_degrees = Vector3(-45, 0, 0)
	container.add_child(ambient)
	
	# Colored accent lights
	var colors = [
		Color(1.0, 0.4, 0.6),  # Pink
		Color(0.4, 0.8, 1.0),  # Blue  
		Color(0.8, 1.0, 0.4),  # Green
		Color(1.0, 0.8, 0.4)   # Orange
	]
	
	for i in range(4):
		var accent_light = OmniLight3D.new()
		accent_light.light_energy = 0.5
		accent_light.light_color = colors[i]
		accent_light.omni_range = space_size.x * 0.3
		
		var angle = i * TAU / 4
		accent_light.position = Vector3(
			cos(angle) * space_size.x * 0.3,
			sin(i * 0.7) * space_size.y * 0.2,
			sin(angle) * space_size.z * 0.3
		)
		
		container.add_child(accent_light)
		
		# Animate the lights
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(accent_light, "light_energy", 0.8, 2.0 + i * 0.5)
		tween.tween_property(accent_light, "light_energy", 0.2, 2.0 + i * 0.5)
