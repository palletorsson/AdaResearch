extends Node3D

class_name VectorFields

enum FieldType { RADIAL, VORTEX, UNIFORM, SINUSOIDAL }

var current_field_type = FieldType.RADIAL
var grid_size = 10
var grid_spacing = 1.0
var vector_arrows = []
var test_particle_velocity = Vector3.ZERO
var trail_enabled = true
var trail_points = []
var max_trail_points = 100

func _ready():
	_create_grid()
	_create_vector_field()
	_connect_ui()
	_reset_particle()

func _create_grid():
	# Create grid lines for reference
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.3, 0.3, 0.3, 0.5)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	for i in range(-grid_size, grid_size + 1):
		# X lines
		var x_line = CSGBox3D.new()
		x_line.material = grid_material
		x_line.size = Vector3(grid_size * 2 * grid_spacing, 0.01, 0.01)
		x_line.position = Vector3(0, 0, i * grid_spacing)
		$Grid/GridLines.add_child(x_line)
		
		# Z lines
		var z_line = CSGBox3D.new()
		z_line.material = grid_material
		z_line.size = Vector3(0.01, 0.01, grid_size * 2 * grid_spacing)
		z_line.position = Vector3(i * grid_spacing, 0, 0)
		$Grid/GridLines.add_child(z_line)

func _create_vector_field():
	# Clear existing arrows
	for arrow in vector_arrows:
		arrow.queue_free()
	vector_arrows.clear()
	
	# Create vector arrows at grid points
	for x in range(-grid_size, grid_size + 1):
		for z in range(-grid_size, grid_size + 1):
			var pos = Vector3(x * grid_spacing, 0.1, z * grid_spacing)
			var field_vector = _calculate_field_vector(pos)
			
			var arrow = preload("res://algorithms/physicssimulation/vectorfields/VectorFieldArrow.gd").new()
			arrow.position = pos
			arrow.set_direction(field_vector)
			arrow.set_magnitude(field_vector.length())
			$VectorField.add_child(arrow)
			vector_arrows.append(arrow)

func _calculate_field_vector(pos: Vector3) -> Vector3:
	match current_field_type:
		FieldType.RADIAL:
			# Radial field: vectors point away from origin
			var direction = pos.normalized()
			return direction * 2.0
		
		FieldType.VORTEX:
			# Vortex field: vectors rotate around origin
			var direction = Vector3(-pos.z, 0, pos.x).normalized()
			return direction * 2.0
		
		FieldType.UNIFORM:
			# Uniform field: constant direction
			return Vector3(1, 0, 0) * 2.0
		
		FieldType.SINUSOIDAL:
			# Sinusoidal field: varying magnitude
			var magnitude = sin(pos.x * 0.5) * cos(pos.z * 0.5) * 2.0
			return Vector3(1, 0, 0) * magnitude
	
	return Vector3.ZERO

func _physics_process(delta):
	if trail_enabled:
		_update_particle_trail()
	
	# Update vector field if needed
	_update_vector_field()

func _update_particle_trail():
	var particle_pos = $TestParticle.position
	
	# Add current position to trail
	trail_points.append(particle_pos)
	
	# Limit trail length
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()
	
	# Clear existing trail
	for child in $ParticleTrail.get_children():
		child.queue_free()
	
	# Draw trail
	for i in range(1, trail_points.size()):
		var start = trail_points[i-1]
		var end = trail_points[i]
		
		var trail_segment = CSGBox3D.new()
		trail_segment.size = Vector3(0.05, 0.05, start.distance_to(end))
		trail_segment.position = (start + end) / 2
		trail_segment.look_at(end, Vector3.UP)
		
		var trail_material = StandardMaterial3D.new()
		trail_material.albedo_color = Color(0, 1, 0, 0.7)
		trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail_segment.material = trail_material
		
		$ParticleTrail.add_child(trail_segment)

func _update_vector_field():
	# Update vector field based on current type
	for i in range(vector_arrows.size()):
		var arrow = vector_arrows[i]
		var pos = arrow.position
		var field_vector = _calculate_field_vector(pos)
		arrow.set_direction(field_vector)
		arrow.set_magnitude(field_vector.length())

func _connect_ui():
	$UI/VBoxContainer/FieldTypeButton.pressed.connect(_on_field_type_pressed)
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/TrailToggle.pressed.connect(_on_trail_toggle_pressed)

func _on_field_type_pressed():
	current_field_type = (current_field_type + 1) % FieldType.size()
	_create_vector_field()
	
	# Update UI text
	var field_names = ["Radial", "Vortex", "Uniform", "Sinusoidal"]
	$UI/VBoxContainer/FieldTypeButton.text = "Field: " + field_names[current_field_type]

func _on_reset_pressed():
	_reset_particle()

func _on_trail_toggle_pressed():
	trail_enabled = !trail_enabled
	$UI/VBoxContainer/TrailToggle.text = "Trail: " + ("ON" if trail_enabled else "OFF")
	
	if !trail_enabled:
		# Clear trail
		for child in $ParticleTrail.get_children():
			child.queue_free()
		trail_points.clear()

func _reset_particle():
	$TestParticle.position = Vector3(0, 1, 0)
	test_particle_velocity = Vector3.ZERO
	trail_points.clear()
	
	# Clear trail
	for child in $ParticleTrail.get_children():
		child.queue_free()
