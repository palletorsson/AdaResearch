extends Node3D

class_name SpringMassSystem

var mass_points = []
var springs = []
var paused = false
var gravity = Vector3(0, -9.8, 0)
var spring_stiffness = 2.0
var damping = 0.8

# Grid configuration (VR-optimized)
var grid_size = 2  # Reduced from 5 to 2 (2x2x2 = 8 points vs 726!)
var grid_spacing = 1.5  # Increased spacing for better visibility

# VR Performance optimization
var physics_update_interval = 2  # Update physics every 2 frames
var frame_counter = 0
var performance_timer = 0.0

func _ready():
	print("Creating VR-optimized spring-mass system...")
	_create_mass_point_grid()
	_create_spring_connections()
	_connect_ui()
	print("Created ", mass_points.size(), " mass points and ", springs.size(), " springs")

func _create_mass_point_grid():
	# Create a grid of mass points
	for x in range(-grid_size, grid_size + 1):
		for y in range(0, grid_size + 1):
			for z in range(-grid_size, grid_size + 1):
				var mass_point = preload("res://algorithms/physicssimulation/springmass/MassPoint.gd").new()
				mass_point.name = "MassPoint_" + str(x) + "_" + str(y) + "_" + str(z)
				mass_point.position = Vector3(x * grid_spacing, y * grid_spacing, z * grid_spacing)
				
				# Make some points fixed (boundary conditions)
				if y == grid_size or abs(x) == grid_size or abs(z) == grid_size:
					mass_point.is_fixed = true
				
				$MassPoints.add_child(mass_point)
				mass_points.append(mass_point)

func _create_spring_connections():
	# Create springs only between direct neighbors (VR-optimized)
	# This reduces the number of springs significantly
	for i in range(mass_points.size()):
		var point1 = mass_points[i]
		var pos1 = point1.position
		
		for j in range(i + 1, mass_points.size()):
			var point2 = mass_points[j]
			var pos2 = point2.position
			var distance = pos1.distance_to(pos2)
			
			# Only connect direct neighbors (not diagonals) for VR performance
			# This means distance should be exactly grid_spacing (with small tolerance)
			if abs(distance - grid_spacing) < 0.1 and distance > 0:
				var spring = {
					"point1": point1,
					"point2": point2,
					"rest_length": distance,
					"stiffness": spring_stiffness
				}
				springs.append(spring)
				
				# Create visual spring representation
				_create_spring_visual(spring)

func _create_spring_visual(spring):
	var spring_line = CSGBox3D.new()
	spring_line.size = Vector3(0.02, 0.02, spring.rest_length)
	spring_line.material = StandardMaterial3D.new()
	spring_line.material.albedo_color = Color(0.7, 0.7, 0.7, 0.5)
	spring_line.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Position spring between the two points
	var mid_point = (spring.point1.position + spring.point2.position) / 2
	spring_line.position = mid_point
	
	# Orient spring to point from point1 to point2
	var direction = (spring.point2.position - spring.point1.position).normalized()
	spring_line.look_at_from_position(spring_line.position, spring.point2.position, Vector3.UP)
	
	$Springs.add_child(spring_line)
	spring["visual"] = spring_line

func _physics_process(delta):
	if paused:
		return
	
	# Performance monitoring
	performance_timer += delta
	if performance_timer >= 1.0:  # Display FPS every second
		var current_fps = Engine.get_frames_per_second()
		print("Spring-Mass System FPS: ", current_fps, " | Mass Points: ", mass_points.size(), " | Springs: ", springs.size())
		performance_timer = 0.0
	
	# VR Performance: Skip physics calculations on some frames
	frame_counter += 1
	if frame_counter % physics_update_interval != 0:
		return
	
	var adjusted_delta = delta * physics_update_interval  # Adjust delta for skipped frames
	
	# Apply forces to mass points (less frequently for VR)
	_apply_spring_forces(adjusted_delta)
	
	# Update mass point physics
	for mass_point in mass_points:
		mass_point.update_physics(adjusted_delta, gravity)
	
	# Update spring visuals (less frequently)
	_update_spring_visuals()

func _apply_spring_forces(delta):
	for spring in springs:
		var point1 = spring.point1
		var point2 = spring.point2
		
		if point1.is_fixed and point2.is_fixed:
			continue
		
		var displacement = point2.position - point1.position
		var distance = displacement.length()
		
		if distance > 0:
			var direction = displacement / distance
			var stretch = distance - spring.rest_length
			var force = direction * stretch * spring.stiffness
			
			# Apply equal and opposite forces
			if not point1.is_fixed:
				point1.apply_force(force)
			if not point2.is_fixed:
				point2.apply_force(-force)

func _update_spring_visuals():
	for spring in springs:
		var visual = spring.visual
		var point1 = spring.point1
		var point2 = spring.point2
		
		# Update spring position and orientation
		var mid_point = (point1.position + point2.position) / 2
		visual.position = mid_point
		
		var direction = (point2.position - point1.position).normalized()
		visual.look_at_from_position(visual.position, point2.position, Vector3.UP)
		
		# Update spring length
		var current_length = point1.position.distance_to(point2.position)
		visual.size.z = current_length
		
		# Color spring based on stretch
		var stretch_ratio = current_length / spring.rest_length
		var color = Color.WHITE
		if stretch_ratio > 1.2:
			color = Color.RED
		elif stretch_ratio < 0.8:
			color = Color.BLUE
		else:
			color = Color.GREEN
		
		visual.material.albedo_color = color

func _connect_ui():
	$UI/VBoxContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$UI/VBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	$UI/VBoxContainer/SpringStiffnessSlider.value_changed.connect(_on_stiffness_changed)
	$UI/VBoxContainer/DampingSlider.value_changed.connect(_on_damping_changed)

func _on_reset_pressed():
	# Reset all mass points to initial positions
	for mass_point in mass_points:
		mass_point.reset_to_initial()

func _on_pause_pressed():
	paused = !paused
	$UI/VBoxContainer/PauseButton.text = "Resume" if paused else "Pause"

func _on_stiffness_changed(value: float):
	spring_stiffness = value
	$UI/VBoxContainer/StiffnessLabel.text = "Spring Stiffness: " + str(value)
	
	# Update all springs
	for spring in springs:
		spring.stiffness = value

func _on_damping_changed(value: float):
	damping = value
	$UI/VBoxContainer/DampingLabel.text = "Damping: " + str(value)
	
	# Update all mass points
	for mass_point in mass_points:
		mass_point.damping = value
