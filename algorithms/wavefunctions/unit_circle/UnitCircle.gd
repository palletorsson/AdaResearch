extends Node3D
class_name UnitCircle

var time: float = 0.0
var angle: float = 0.0
var radius: float = 2.0
var wave_length: int = 50
var circle_points: Array = []
var sine_points: Array = []
var cosine_points: Array = []

func _ready():
	# Initialize Unit Circle visualization
	print("Unit Circle Visualization initialized")
	create_circle_points()
	create_sine_points()
	create_cosine_points()
	setup_grid()

func _process(delta):
	time += delta
	angle = time * 1.5  # Control rotation speed
	
	animate_rotating_point(delta)
	animate_sine_wave(delta)
	animate_cosine_wave(delta)
	animate_projections(delta)
	update_wave_trails(delta)

func create_circle_points():
	# Create circle outline points
	var circle_points_node = $Circle/CirclePoints
	var num_points = 64
	for i in range(num_points):
		var point_angle = (float(i) / num_points) * PI * 2
		var point = CSGSphere3D.new()
		point.radius = 0.05
		point.material_override = StandardMaterial3D.new()
		point.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		point.material_override.emission_enabled = true
		point.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.2
		
		var x = cos(point_angle) * radius
		var z = sin(point_angle) * radius
		point.position = Vector3(x, 0, z)
		
		circle_points_node.add_child(point)
		circle_points.append(point)

func create_sine_points():
	# Create sine wave points
	var sine_points_node = $SineWave/SinePoints
	for i in range(wave_length):
		var point = CSGSphere3D.new()
		point.radius = 0.06
		point.material_override = StandardMaterial3D.new()
		point.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
		point.material_override.emission_enabled = true
		point.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
		
		# Position points for sine wave
		var progress = float(i) / wave_length
		var x = (progress - 0.5) * 6
		var y = 0  # Will be updated in animation
		var z = 0
		point.position = Vector3(x, y, z)
		
		sine_points_node.add_child(point)
		sine_points.append(point)

func create_cosine_points():
	# Create cosine wave points
	var cosine_points_node = $CosineWave/CosinePoints
	for i in range(wave_length):
		var point = CSGSphere3D.new()
		point.radius = 0.06
		point.material_override = StandardMaterial3D.new()
		point.material_override.albedo_color = Color(0.2, 0.2, 0.8, 1)
		point.material_override.emission_enabled = true
		point.material_override.emission = Color(0.2, 0.2, 0.8, 1) * 0.3
		
		# Position points for cosine wave
		var progress = float(i) / wave_length
		var x = (progress - 0.5) * 6
		var y = 0  # Will be updated in animation
		var z = 0
		point.position = Vector3(x, y, z)
		
		cosine_points_node.add_child(point)
		cosine_points.append(point)

func setup_grid():
	# Create grid lines for reference
	var grid_lines = $Grid/GridLines
	
	# X-axis line
	var x_axis = CSGBox3D.new()
	x_axis.size = Vector3(20, 0.02, 0.02)
	x_axis.material_override = StandardMaterial3D.new()
	x_axis.material_override.albedo_color = Color(0.5, 0.5, 0.5, 1)
	x_axis.position = Vector3(0, -3, 0)
	grid_lines.add_child(x_axis)
	
	# Z-axis line
	var z_axis = CSGBox3D.new()
	z_axis.size = Vector3(0.02, 0.02, 20)
	z_axis.material_override = StandardMaterial3D.new()
	z_axis.material_override.albedo_color = Color(0.5, 0.5, 0.5, 1)
	z_axis.position = Vector3(0, -3, 0)
	grid_lines.add_child(z_axis)

func animate_rotating_point(delta):
	# Animate the rotating point on the circle
	var rotating_point = $RotatingPoint
	var point_core = $RotatingPoint/PointCore
	var radius_line = $RotatingPoint/RadiusLine
	
	if rotating_point and point_core and radius_line:
		# Calculate position on unit circle
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		# Update point position
		point_core.position = Vector3(x, 0, z)
		
		# Update radius line
		radius_line.position = Vector3(x * 0.5, 0, z * 0.5)
		radius_line.rotation.y = angle
		radius_line.scale = Vector3(radius, 1, 1)
		
		# Pulse the point
		var pulse = 1.0 + sin(time * 4.0) * 0.2
		point_core.scale = Vector3.ONE * pulse

func animate_sine_wave(delta):
	# Animate sine wave points
	for i in range(sine_points.size()):
		var point = sine_points[i]
		if point:
			var progress = float(i) / sine_points.size()
			var wave_angle = progress * PI * 4 - angle
			var y = sin(wave_angle) * 2
			
			point.position.y = lerp(point.position.y, y, delta * 5.0)
			
			# Color based on wave position
			var intensity = (sin(wave_angle) + 1.0) * 0.5
			var color = Color(0.8, 0.2, 0.2, 1) * intensity + Color(0.2, 0.2, 0.2, 1) * (1.0 - intensity)
			point.material_override.albedo_color = color
			point.material_override.emission = color * 0.3

func animate_cosine_wave(delta):
	# Animate cosine wave points
	for i in range(cosine_points.size()):
		var point = cosine_points[i]
		if point:
			var progress = float(i) / cosine_points.size()
			var wave_angle = progress * PI * 4 - angle
			var y = cos(wave_angle) * 2
			
			point.position.y = lerp(point.position.y, y, delta * 5.0)
			
			# Color based on wave position
			var intensity = (cos(wave_angle) + 1.0) * 0.5
			var color = Color(0.2, 0.2, 0.8, 1) * intensity + Color(0.2, 0.2, 0.2, 1) * (1.0 - intensity)
			point.material_override.albedo_color = color
			point.material_override.emission = color * 0.3

func animate_projections(delta):
	# Animate projection points that show the connection
	var sine_projection = $Projections/SineProjection/ProjectionCore
	var cosine_projection = $Projections/CosineProjection/ProjectionCore
	
	if sine_projection:
		# Project sine value from circle to sine wave
		var sine_value = sin(angle) * 2
		sine_projection.position.y = lerp(sine_projection.position.y, sine_value, delta * 5.0)
		
		# Pulse based on sine value
		var pulse = 1.0 + abs(sin(angle)) * 0.5
		sine_projection.scale = Vector3.ONE * pulse
		
		# Color based on sine value
		var intensity = (sin(angle) + 1.0) * 0.5
		var color = Color(0.8, 0.2, 0.2, 1) * intensity + Color(0.2, 0.2, 0.2, 1) * (1.0 - intensity)
		sine_projection.material_override.albedo_color = color
	
	if cosine_projection:
		# Project cosine value from circle to cosine wave
		var cosine_value = cos(angle) * 2
		cosine_projection.position.y = lerp(cosine_projection.position.y, cosine_value, delta * 5.0)
		
		# Pulse based on cosine value
		var pulse = 1.0 + abs(cos(angle)) * 0.5
		cosine_projection.scale = Vector3.ONE * pulse
		
		# Color based on cosine value
		var intensity = (cos(angle) + 1.0) * 0.5
		var color = Color(0.2, 0.2, 0.8, 1) * intensity + Color(0.2, 0.2, 0.2, 1) * (1.0 - intensity)
		cosine_projection.material_override.albedo_color = color

func update_wave_trails(delta):
	# Update circle points to show current position
	for i in range(circle_points.size()):
		var point = circle_points[i]
		if point:
			var point_angle = (float(i) / circle_points.size()) * PI * 2
			var distance_to_current = abs(angle - point_angle)
			distance_to_current = min(distance_to_current, PI * 2 - distance_to_current)
			
			# Highlight points near current position
			if distance_to_current < 0.3:
				var intensity = (0.3 - distance_to_current) / 0.3
				var pulse = 1.0 + intensity * 0.5
				point.scale = Vector3.ONE * pulse
				point.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
			else:
				point.scale = Vector3.ONE
				point.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.2

func set_rotation_speed(speed: float):
	# Allow external control of rotation speed
	pass

func get_current_angle() -> float:
	return angle

func get_sine_value() -> float:
	return sin(angle)

func get_cosine_value() -> float:
	return cos(angle)

func reset_animation():
	time = 0.0
	angle = 0.0
