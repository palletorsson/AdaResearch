extends Node3D

class_name ThreeBodyProblem

var bodies = []
var paused = false
var trails_enabled = true
var gravitational_constant = 0.1
var time_scale = 1.0
var rotation_time = 0.0

# Vibrant queer color palette for bodies
var queer_colors = [
	Color(1.0, 0.4, 0.7, 1.0),    # Hot pink
	Color(0.8, 0.3, 1.0, 1.0),    # Purple
	Color(0.3, 0.9, 1.0, 1.0),    # Cyan
	Color(1.0, 0.8, 0.2, 1.0),    # Gold
	Color(0.5, 1.0, 0.4, 1.0),    # Lime
	Color(1.0, 0.5, 0.3, 1.0)     # Coral
]

func _ready():
	_create_star_field()
	_initialize_bodies()
	_connect_ui()
	_apply_vibrant_colors()

	# Auto-start simulation
	paused = false
	trails_enabled = true

func _create_star_field():
	# Create a background star field for visual appeal
	var star_material = StandardMaterial3D.new()
	star_material.albedo_color = Color.WHITE
	star_material.emission_enabled = true
	star_material.emission = Color.WHITE * 0.5
	
	for i in range(200):
		var star = CSGSphere3D.new()
		star.radius = randf_range(0.01, 0.05)
		star.material = star_material
		
		# Random position in a large sphere
		var angle1 = randf_range(0, 2 * PI)
		var angle2 = randf_range(0, PI)
		var radius = randf_range(50, 100)
		
		star.position = Vector3(
			radius * sin(angle2) * cos(angle1),
			radius * sin(angle2) * sin(angle1),
			radius * cos(angle2)
		)
		
		$StarField.add_child(star)

func _initialize_bodies():
	# Get all celestial bodies
	bodies = $CelestialBodies.get_children()
	
	# Initialize each body
	for body in bodies:
		body.initialize()

func _physics_process(delta):
	if paused:
		return

	# Auto-rotate for dynamic 3D view
	rotation_time += delta
	rotation.y = sin(rotation_time * 0.2) * 0.4
	rotation.x = cos(rotation_time * 0.15) * 0.15

	# Apply gravitational forces between all bodies
	_apply_gravitational_forces(delta)

	# Update body positions and velocities
	_update_bodies(delta)

	# Update trails
	if trails_enabled:
		_update_trails()

func _apply_gravitational_forces(delta):
	# Calculate gravitational forces between all pairs of bodies
	for i in range(bodies.size()):
		for j in range(i + 1, bodies.size()):
			var body1 = bodies[i]
			var body2 = bodies[j]
			
			var distance_vector = body2.position - body1.position
			var distance = distance_vector.length()
			
			if distance > 0.1:  # Avoid division by zero
				var force_magnitude = gravitational_constant * body1.body_mass * body2.body_mass / (distance * distance)
				var force_direction = distance_vector.normalized()
				
				# Apply equal and opposite forces
				body1.apply_force(force_direction * force_magnitude)
				body2.apply_force(-force_direction * force_magnitude)

func _update_bodies(delta):
	# Update each body's physics
	for body in bodies:
		body.update_physics(delta * time_scale)

func _update_trails():
	# Update trails for each body
	for body in bodies:
		body.update_trail()

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/TrailToggle.pressed.connect(_on_trail_toggle_pressed)
	$UI/VBoxContainer/MassSlider.value_changed.connect(_on_mass_changed)

func _on_reset_pressed():
	# Reset all bodies to initial positions
	for body in bodies:
		body.reset_to_initial()
	
	# Clear trails
	for child in $Trails.get_children():
		child.queue_free()

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_trail_toggle_pressed():
	trails_enabled = !trails_enabled
	$UI/VBoxContainer/TrailToggle.text = "Trails: " + ("ON" if trails_enabled else "OFF")
	
	if !trails_enabled:
		# Clear all trails
		for child in $Trails.get_children():
			child.queue_free()

func _on_mass_changed(value: float):
	# Update mass of all bodies
	for body in bodies:
		body.body_mass = value

	# Update UI label
	$UI/VBoxContainer/MassLabel.text = "Mass: " + str(int(value))

func _apply_vibrant_colors():
	# Apply vibrant queer colors to celestial bodies
	for i in range(bodies.size()):
		var body = bodies[i]
		var color = queer_colors[i % queer_colors.size()]

		# Apply color to body mesh
		if body.has_node("MeshInstance3D"):
			var mesh_instance = body.get_node("MeshInstance3D")
			if mesh_instance.material_override:
				mesh_instance.material_override.albedo_color = color
				mesh_instance.material_override.emission_enabled = true
				mesh_instance.material_override.emission = color
				mesh_instance.material_override.emission_energy_multiplier = 3.0

		# Apply color to trail if available
		if body.has_method("set_trail_color"):
			body.set_trail_color(color)
