extends Node3D
class_name WaveInterference

var time: float = 0.0
var wave_speed: float = 2.0
var frequency1: float = 1.0
var frequency2: float = 1.2
var amplitude: float = 1.0
var field_points: Array = []
var wave_rings1: Array = []
var wave_rings2: Array = []

func _ready():
	# Initialize Wave Interference visualization
	print("Wave Interference Visualization initialized")
	create_interference_field()
	create_wave_rings()
	setup_grid()

func _process(delta):
	time += delta
	
	animate_wave_sources(delta)
	animate_wave_rings(delta)
	animate_interference_field(delta)
	animate_interference_pattern(delta)

func create_interference_field():
	# Create field points for interference visualization
	var field_points_node = $InterferenceField/FieldPoints
	var grid_size = 20
	var spacing = 0.4
	
	for i in range(grid_size):
		for j in range(grid_size):
			var point = CSGSphere3D.new()
			point.radius = 0.04
			point.material_override = StandardMaterial3D.new()
			point.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
			point.material_override.emission_enabled = true
			point.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
			
			# Position points in a grid
			var x = (i - grid_size/2) * spacing
			var z = (j - grid_size/2) * spacing
			point.position = Vector3(x, 0, z)
			
			field_points_node.add_child(point)
			field_points.append(point)

func create_wave_rings():
	# Create wave rings for both sources
	var rings1_node = $WaveRings1
	var rings2_node = $WaveRings2
	
	# Create rings for source 1
	for i in range(8):
		var ring = CSGCylinder3D.new()
		ring.radius = 0.5 + i * 0.5
		 + i * 0.5
		ring.height = 0.02
		ring.material_override = StandardMaterial3D.new()
		ring.material_override.albedo_color = Color(0.2, 0.8, 0.2, 0.3)
		ring.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override.emission_enabled = true
		ring.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.2
		
		rings1_node.add_child(ring)
		wave_rings1.append(ring)
	
	# Create rings for source 2
	for i in range(8):
		var ring = CSGCylinder3D.new()
		ring.radius = 0.5 + i * 0.5
		 + i * 0.5
		ring.height = 0.02
		ring.material_override = StandardMaterial3D.new()
		ring.material_override.albedo_color = Color(0.8, 0.2, 0.2, 0.3)
		ring.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override.emission_enabled = true
		ring.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.2
		
		rings2_node.add_child(ring)
		wave_rings2.append(ring)

func setup_grid():
	# Create reference grid
	var grid_lines = $Grid/GridLines
	
	# Create grid lines
	for i in range(-5, 6):
		# X-direction lines
		var x_line = CSGBox3D.new()
		x_line.size = Vector3(10, 0.01, 0.01)
		x_line.material_override = StandardMaterial3D.new()
		x_line.material_override.albedo_color = Color(0.3, 0.3, 0.3, 1)
		x_line.position = Vector3(0, -3, i)
		grid_lines.add_child(x_line)
		
		# Z-direction lines
		var z_line = CSGBox3D.new()
		z_line.size = Vector3(0.01, 0.01, 10)
		z_line.material_override = StandardMaterial3D.new()
		z_line.material_override.albedo_color = Color(0.3, 0.3, 0.3, 1)
		z_line.position = Vector3(i, -3, 0)
		grid_lines.add_child(z_line)

func animate_wave_sources(delta):
	# Animate wave source cores
	var source1_core = $WaveSource1/SourceCore
	var source2_core = $WaveSource2/SourceCore
	
	if source1_core:
		# Pulse source 1
		var pulse1 = 1.0 + sin(time * frequency1 * PI * 2) * 0.3
		source1_core.scale = Vector3.ONE * pulse1
		
		# Change emission intensity
		var intensity1 = (sin(time * frequency1 * PI * 2) + 1.0) * 0.5
		source1_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity1
	
	if source2_core:
		# Pulse source 2
		var pulse2 = 1.0 + sin(time * frequency2 * PI * 2) * 0.3
		source2_core.scale = Vector3.ONE * pulse2
		
		# Change emission intensity
		var intensity2 = (sin(time * frequency2 * PI * 2) + 1.0) * 0.5
		source2_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity2

func animate_wave_rings(delta):
	# Animate wave rings expanding from sources
	for i in range(wave_rings1.size()):
		var ring = wave_rings1[i]
		if ring:
			# Expand rings from source 1
			var ring_time = time * wave_speed - i * 0.5
			var ring_radius = fmod(ring_time, 4.0)
			if ring_radius > 0:
				ring.radius = ring_radius
				
				# Fade out as ring expands
				var alpha = max(0, 1.0 - ring_radius / 4.0)
				ring.material_override.albedo_color = Color(0.2, 0.8, 0.2, alpha * 0.3)
				ring.material_override.emission = Color(0.2, 0.8, 0.2, 1) * alpha * 0.2
			else:
				ring.radius = 0.01
				
	
	for i in range(wave_rings2.size()):
		var ring = wave_rings2[i]
		if ring:
			# Expand rings from source 2
			var ring_time = time * wave_speed - i * 0.5
			var ring_radius = fmod(ring_time, 4.0)
			if ring_radius > 0:
				ring.radius = ring_radius
				
				# Fade out as ring expands
				var alpha = max(0, 1.0 - ring_radius / 4.0)
				ring.material_override.albedo_color = Color(0.8, 0.2, 0.2, alpha * 0.3)
				ring.material_override.emission = Color(0.8, 0.2, 0.2, 1) * alpha * 0.2
			else:
				ring.radius = 0.01
				

func animate_interference_field(delta):
	# Animate field points based on wave interference
	var source1_pos = Vector3(-3, 0, -3)
	var source2_pos = Vector3(3, 0, -3)
	
	for i in range(field_points.size()):
		var point = field_points[i]
		if point:
			# Calculate distance to each source
			var dist1 = point.global_position.distance_to(source1_pos)
			var dist2 = point.global_position.distance_to(source2_pos)
			
			# Calculate wave values at this point
			var wave1 = sin(time * frequency1 * PI * 2 - dist1 * wave_speed) * amplitude
			var wave2 = sin(time * frequency2 * PI * 2 - dist2 * wave_speed) * amplitude
			
			# Calculate interference
			var interference = wave1 + wave2
			
			# Update point position and appearance
			point.position.y = interference * 0.5
			
			# Color based on interference pattern
			var intensity = (interference + 2.0) / 4.0  # Normalize to 0-1
			var color = Color.RED.lerp(Color.BLUE, intensity)
			point.material_override.albedo_color = color
			point.material_override.emission = color * 0.3
			
			# Scale based on interference magnitude
			var scale = 1.0 + abs(interference) * 0.3
			point.scale = Vector3.ONE * scale

func animate_interference_pattern(delta):
	# Animate the interference pattern visualization
	var pattern_core = $InterferencePattern/PatternCore
	if pattern_core:
		# Rotate pattern
		pattern_core.rotation.y += delta * 0.5
		
		# Pulse based on overall interference
		var pulse = 1.0 + sin(time * 2.0) * 0.1
		pattern_core.scale = Vector3.ONE * pulse
		
		# Change color based on time
		var color_shift = sin(time * 1.5) * 0.5 + 0.5
		var color = Color(0.2, 0.8, 0.2, 1).lerp(Color(0.8, 0.2, 0.2, 1), color_shift)
		pattern_core.material_override.emission = color * 0.3

func set_frequency1(freq: float):
	frequency1 = clamp(freq, 0.1, 5.0)

func set_frequency2(freq: float):
	frequency2 = clamp(freq, 0.1, 5.0)

func set_wave_speed(speed: float):
	wave_speed = clamp(speed, 0.5, 5.0)

func set_amplitude(amp: float):
	amplitude = clamp(amp, 0.1, 2.0)

func get_interference_at_point(pos: Vector3) -> float:
	var source1_pos = Vector3(-3, 0, -3)
	var source2_pos = Vector3(3, 0, -3)
	
	var dist1 = pos.distance_to(source1_pos)
	var dist2 = pos.distance_to(source2_pos)
	
	var wave1 = sin(time * frequency1 * PI * 2 - dist1 * wave_speed) * amplitude
	var wave2 = sin(time * frequency2 * PI * 2 - dist2 * wave_speed) * amplitude
	
	return wave1 + wave2

func reset_simulation():
	time = 0.0
