extends Node3D

class_name ThreeBodyProblem

var bodies = []
var paused = false
var trails_enabled = true
var gravitational_constant = 0.1
var time_scale = 1.0

func _ready():
	_create_star_field()
	_initialize_bodies()
	_connect_ui()

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
