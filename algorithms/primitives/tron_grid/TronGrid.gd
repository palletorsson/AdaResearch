extends Node3D

var time = 0.0
var grid_size = 20
var grid_spacing = 1.0
var navigator_position = Vector3.ZERO
var trail_points = []
var max_trail_length = 50

# Navigation patterns
enum NavigationPattern {
	SPIRAL,
	MAZE_RUNNER,
	COORDINATE_SWEEP,
	RANDOM_WALK
}

var current_pattern = NavigationPattern.SPIRAL
var pattern_timer = 0.0
var pattern_interval = 8.0

func _ready():
	create_grid_lines()
	create_coordinate_axes()
	create_reference_points()
	setup_materials()

func create_grid_lines():
	var grid_parent = $GridLines
	
	# Create grid lines along X and Z axes
	for i in range(-grid_size/2, grid_size/2 + 1):
		# X-direction lines
		var x_line = CSGBox3D.new()
		x_line.size = Vector3(grid_size * grid_spacing, 0.02, 0.02)
		x_line.position = Vector3(0, 0, i * grid_spacing)
		grid_parent.add_child(x_line)
		
		# Z-direction lines
		var z_line = CSGBox3D.new()
		z_line.size = Vector3(0.02, 0.02, grid_size * grid_spacing)
		z_line.position = Vector3(i * grid_spacing, 0, 0)
		grid_parent.add_child(z_line)

func create_coordinate_axes():
	var axes_parent = $CoordinateAxes
	
	# X-axis (Red)
	var x_axis = CSGCylinder3D.new()
	x_axis.height = grid_size * grid_spacing * 1.2
	x_axis.radius = 0.05
	
	x_axis.rotation_degrees = Vector3(0, 0, 90)
	x_axis.position = Vector3(0, 0, 0)
	axes_parent.add_child(x_axis)
	
	# Y-axis (Green)
	var y_axis = CSGCylinder3D.new()
	y_axis.height = grid_size * grid_spacing * 0.8
	y_axis.radius = 0.05
	
	y_axis.position = Vector3(0, grid_size * grid_spacing * 0.4, 0)
	axes_parent.add_child(y_axis)
	
	# Z-axis (Blue)
	var z_axis = CSGCylinder3D.new()
	z_axis.height = grid_size * grid_spacing * 1.2
	z_axis.radius = 0.05
	
	z_axis.rotation_degrees = Vector3(90, 0, 0)
	z_axis.position = Vector3(0, 0, 0)
	axes_parent.add_child(z_axis)
	
	# Store axes for material assignment
	x_axis.set_meta("axis_type", "x")
	y_axis.set_meta("axis_type", "y")
	z_axis.set_meta("axis_type", "z")

func create_reference_points():
	var ref_parent = $ReferencePoints
	
	# Create reference points at key coordinates
	var key_points = [
		Vector3(0, 0, 0),      # Origin
		Vector3(5, 0, 0),      # +X
		Vector3(-5, 0, 0),     # -X
		Vector3(0, 0, 5),      # +Z
		Vector3(0, 0, -5),     # -Z
		Vector3(5, 0, 5),      # +X+Z
		Vector3(-5, 0, -5)     # -X-Z
	]
	
	for i in range(key_points.size()):
		var point = CSGSphere3D.new()
		point.radius = 0.1
		point.position = key_points[i]
		ref_parent.add_child(point)

func setup_materials():
	# Grid lines material - cyan glow
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.0, 1.0, 1.0, 0.8)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.emission_enabled = true
	grid_material.emission = Color(0.0, 0.3, 0.3, 1.0)
	
	for child in $GridLines.get_children():
		child.material_override = grid_material
	
	# Coordinate axes materials
	for child in $CoordinateAxes.get_children():
		var axis_material = StandardMaterial3D.new()
		axis_material.emission_enabled = true
		
		match child.get_meta("axis_type"):
			"x":
				axis_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
				axis_material.emission = Color(0.5, 0.1, 0.1, 1.0)
			"y":
				axis_material.albedo_color = Color(0.3, 1.0, 0.3, 1.0)
				axis_material.emission = Color(0.1, 0.5, 0.1, 1.0)
			"z":
				axis_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
				axis_material.emission = Color(0.1, 0.1, 0.5, 1.0)
		
		child.material_override = axis_material
	
	# Navigator material - bright orange
	var navigator_material = StandardMaterial3D.new()
	navigator_material.albedo_color = Color(1.0, 0.6, 0.0, 1.0)
	navigator_material.emission_enabled = true
	navigator_material.emission = Color(0.8, 0.3, 0.0, 1.0)
	$Navigator.material_override = navigator_material
	
	# Reference points material - white glow
	var ref_material = StandardMaterial3D.new()
	ref_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	ref_material.emission_enabled = true
	ref_material.emission = Color(0.5, 0.5, 0.5, 1.0)
	
	for child in $ReferencePoints.get_children():
		child.material_override = ref_material
	
	# Coordinate display material
	var coord_material = StandardMaterial3D.new()
	coord_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	coord_material.emission_enabled = true
	coord_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$CoordinateDisplay.material_override = coord_material
	
	# Grid mode indicator material
	var mode_material = StandardMaterial3D.new()
	mode_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	mode_material.emission_enabled = true
	mode_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$GridModeIndicator.material_override = mode_material

func _process(delta):
	time += delta
	pattern_timer += delta
	
	# Switch navigation patterns
	if pattern_timer >= pattern_interval:
		pattern_timer = 0.0
		current_pattern = (current_pattern + 1) % NavigationPattern.size()
		clear_trail()
	
	update_navigator_position()
	update_trail()
	animate_grid_effects()
	update_coordinate_display()

func update_navigator_position():
	var pattern_progress = pattern_timer / pattern_interval
	
	match current_pattern:
		NavigationPattern.SPIRAL:
			navigate_spiral(pattern_progress)
		
		NavigationPattern.MAZE_RUNNER:
			navigate_maze_runner(pattern_progress)
		
		NavigationPattern.COORDINATE_SWEEP:
			navigate_coordinate_sweep(pattern_progress)
		
		NavigationPattern.RANDOM_WALK:
			navigate_random_walk()

func navigate_spiral(progress):
	var angle = progress * PI * 8.0  # Multiple rotations
	var radius = progress * 6.0
	
	navigator_position = Vector3(
		cos(angle) * radius,
		0.2,
		sin(angle) * radius
	)
	
	$Navigator.position = navigator_position

func navigate_maze_runner(progress):
	# Create a maze-like path using step functions
	var steps = 16
	var step_progress = fmod(progress * steps, 1.0)
	var current_step = int(progress * steps)
	
	# Pre-defined maze path
	var maze_points = [
		Vector3(0, 0.2, 0), Vector3(3, 0.2, 0), Vector3(3, 0.2, 3),
		Vector3(0, 0.2, 3), Vector3(-3, 0.2, 3), Vector3(-3, 0.2, 0),
		Vector3(-3, 0.2, -3), Vector3(0, 0.2, -3), Vector3(3, 0.2, -3),
		Vector3(6, 0.2, -3), Vector3(6, 0.2, 0), Vector3(6, 0.2, 3),
		Vector3(3, 0.2, 6), Vector3(0, 0.2, 6), Vector3(-3, 0.2, 6),
		Vector3(-6, 0.2, 6)
	]
	
	if current_step < maze_points.size() - 1:
		var start_point = maze_points[current_step]
		var end_point = maze_points[current_step + 1]
		navigator_position = start_point.lerp(end_point, step_progress)
	else:
		navigator_position = maze_points[-1]
	
	$Navigator.position = navigator_position

func navigate_coordinate_sweep(progress):
	# Sweep through coordinate system in organized pattern
	var phase = fmod(progress * 3.0, 1.0)
	var sweep_phase = int(progress * 3.0)
	
	match sweep_phase:
		0:  # X-axis sweep
			navigator_position = Vector3(
				lerp(-8.0, 8.0, phase),
				0.2,
				0
			)
		1:  # Z-axis sweep
			navigator_position = Vector3(
				0,
				0.2,
				lerp(-8.0, 8.0, phase)
			)
		2:  # Diagonal sweep
			navigator_position = Vector3(
				lerp(-6.0, 6.0, phase),
				0.2,
				lerp(-6.0, 6.0, phase)
			)
	
	$Navigator.position = navigator_position

func navigate_random_walk():
	# Random walk with grid snapping
	if fmod(time, 0.5) < 0.1:  # Move every 0.5 seconds
		var directions = [
			Vector3(1, 0, 0), Vector3(-1, 0, 0),
			Vector3(0, 0, 1), Vector3(0, 0, -1)
		]
		
		var random_direction = directions[randi() % directions.size()]
		var new_position = navigator_position + random_direction * grid_spacing
		
		# Clamp to grid bounds
		new_position.x = clamp(new_position.x, -8.0, 8.0)
		new_position.z = clamp(new_position.z, -8.0, 8.0)
		new_position.y = 0.2
		
		navigator_position = new_position
		$Navigator.position = navigator_position

func update_trail():
	# Add current position to trail
	if trail_points.size() == 0 or trail_points[-1].distance_to(navigator_position) > 0.5:
		trail_points.append(navigator_position)
		
		# Create trail segment
		if trail_points.size() > 1:
			create_trail_segment(trail_points[-2], trail_points[-1])
	
	# Limit trail length
	while trail_points.size() > max_trail_length:
		trail_points.pop_front()
		
		# Remove oldest trail segment
		if $NavigatorTrail.get_child_count() > 0:
			$NavigatorTrail.get_child(0).queue_free()

func create_trail_segment(start_pos, end_pos):
	var segment = CSGCylinder3D.new()
	var length = start_pos.distance_to(end_pos)
	
	segment.height = length
	segment.radius = 0.03
	
	
	# Position and orient
	var mid_point = (start_pos + end_pos) * 0.5
	segment.position = mid_point
	
	# Orient segment
	var direction = (end_pos - start_pos).normalized()
	if direction != Vector3.UP:
		var axis = Vector3.UP.cross(direction).normalized()
		var angle = acos(Vector3.UP.dot(direction))
		segment.transform.basis = Basis(axis, angle)
	
	# Trail material
	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1.0, 0.4, 0.0, 0.8)
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.emission_enabled = true
	trail_material.emission = Color(0.4, 0.1, 0.0, 1.0)
	segment.material_override = trail_material
	
	$NavigatorTrail.add_child(segment)

func clear_trail():
	trail_points.clear()
	for child in $NavigatorTrail.get_children():
		child.queue_free()

func animate_grid_effects():
	# Pulse grid lines
	var pulse = 1.0 + sin(time * 2.0) * 0.2
	
	for child in $GridLines.get_children():
		var material = child.material_override as StandardMaterial3D
		if material:
			var base_emission = Color(0.0, 0.3, 0.3, 1.0)
			material.emission = base_emission * pulse
	
	# Animate navigator
	var nav_pulse = 1.0 + sin(time * 4.0) * 0.3
	$Navigator.scale = Vector3.ONE * nav_pulse

func update_coordinate_display():
	# Update coordinate display based on navigator position
	var coord_height = (abs(navigator_position.x) + abs(navigator_position.z)) * 0.1 + 0.5
	$CoordinateDisplay.size.y = coord_height
	$CoordinateDisplay.position.y = 4 + coord_height/2
	
	# Update grid mode indicator
	var mode_height = (current_pattern + 1) * 0.3
	var gridmodeindicator = get_node_or_null("GridModeIndicator")
	if gridmodeindicator and gridmodeindicator is CSGCylinder3D:
		gridmodeindicator.height = mode_height
		gridmodeindicator.position.y = 4 + mode_height/2
