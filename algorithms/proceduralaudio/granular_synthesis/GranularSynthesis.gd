extends Node3D

# Granular Synthesis Visualization
# Demonstrates micro-sound manipulation and grain-based audio synthesis

var time := 0.0
var grain_timer := 0.0
var synthesis_timer := 0.0

# Granular synthesis parameters
var grain_size := 0.1  # Duration in seconds
var grain_density := 10.0  # Grains per second
var grain_pitch := 1.0  # Pitch multiplier
var grain_position := 0.0  # Position in source material
var grain_scatter := 0.05  # Random variation

# Visual representation
var active_grains := []
var waveform_data := []
var output_buffer := []

# Grain structure
class Grain:
	var position: Vector3
	var size: float
	var pitch: float
	var age: float
	var lifetime: float
	var amplitude: float
	var source_position: float

func _ready():
	initialize_waveform_data()
	initialize_synthesis_parameters()

func _process(delta):
	time += delta
	grain_timer += delta
	synthesis_timer += delta
	
	update_grain_parameters()
	spawn_new_grains(delta)
	animate_existing_grains(delta)
	visualize_waveform_source()
	show_granular_parameters()
	demonstrate_output_synthesis()

func initialize_waveform_data():
	# Create sample waveform data
	waveform_data.clear()
	for i in range(200):
		var t = float(i) / 200.0
		var sample = sin(t * TAU * 3) + sin(t * TAU * 7) * 0.5 + sin(t * TAU * 11) * 0.25
		waveform_data.append(sample)

func initialize_synthesis_parameters():
	grain_size = 0.08
	grain_density = 12.0
	grain_pitch = 1.0
	grain_position = 0.0
	grain_scatter = 0.03

func update_grain_parameters():
	# Animate parameters over time
	grain_size = 0.05 + sin(time * 0.5) * 0.03
	grain_density = 8.0 + cos(time * 0.7) * 4.0
	grain_pitch = 0.8 + sin(time * 0.3) * 0.4
	grain_position = fmod(time * 0.1, 1.0)
	grain_scatter = 0.02 + sin(time * 1.2) * 0.01

func spawn_new_grains(delta: float):
	# Calculate grain spawn rate
	var spawn_rate = grain_density * delta
	var grains_to_spawn = int(spawn_rate)
	
	# Handle fractional spawning
	if randf() < (spawn_rate - grains_to_spawn):
		grains_to_spawn += 1
	
	# Spawn new grains
	for i in range(grains_to_spawn):
		spawn_grain()

func spawn_grain():
	var grain = Grain.new()
	
	# Random position in grain cluster
	grain.position = Vector3(
		randf_range(-4, 4),
		randf_range(-2, 2),
		randf_range(-2, 2)
	)
	
	# Grain properties
	grain.size = grain_size * (1.0 + randf_range(-0.3, 0.3))
	grain.pitch = grain_pitch * (1.0 + randf_range(-grain_scatter, grain_scatter))
	grain.lifetime = grain.size
	grain.age = 0.0
	grain.amplitude = randf_range(0.5, 1.0)
	
	# Source position with scatter
	grain.source_position = grain_position + randf_range(-grain_scatter, grain_scatter)
	grain.source_position = fmod(grain.source_position + 1.0, 1.0)  # Wrap around
	
	active_grains.append(grain)

func animate_existing_grains(delta: float):
	var container = $GrainCluster
	
	# Clear previous grain visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update and visualize active grains
	var i = 0
	while i < active_grains.size():
		var grain = active_grains[i]
		grain.age += delta
		
		if grain.age >= grain.lifetime:
			# Remove expired grain
			active_grains.remove_at(i)
			continue
		
		# Update grain position (movement)
		grain.position.y += delta * 2.0  # Rise upward
		
		# Create visual representation
		var grain_sphere = CSGSphere3D.new()
		var life_ratio = grain.age / grain.lifetime
		var envelope = sin(life_ratio * PI)  # Bell curve envelope
		
		grain_sphere.radius = grain.size * envelope * 2.0
		grain_sphere.position = grain.position
		
		var material = StandardMaterial3D.new()
		# Color based on pitch and amplitude
		var pitch_ratio = (grain.pitch - 0.4) / 0.8  # Normalize pitch range
		material.albedo_color = Color(
			pitch_ratio,
			grain.amplitude,
			1.0 - pitch_ratio,
			envelope * 0.8
		)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
		grain_sphere.material_override = material
		
		container.add_child(grain_sphere)
		
		i += 1

func visualize_waveform_source():
	var container = $WaveformSource
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create waveform visualization
	for i in range(waveform_data.size() - 1):
		var t1 = float(i) / waveform_data.size()
		var t2 = float(i + 1) / waveform_data.size()
		
		var pos1 = Vector3(
			(t1 - 0.5) * 10,
			waveform_data[i] * 2,
			0
		)
		var pos2 = Vector3(
			(t2 - 0.5) * 10,
			waveform_data[i + 1] * 2,
			0
		)
		
		# Create waveform segment
		var segment = CSGCylinder3D.new()
		segment.radius = 0.05
		
		segment.height = pos1.distance_to(pos2)
		
		segment.position = (pos1 + pos2) * 0.5
		segment.look_at_from_position(segment.position, pos2, Vector3.UP)
		segment.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		var material = StandardMaterial3D.new()
		
		# Highlight current grain position
		var pos_diff = abs(t1 - grain_position)
		if pos_diff < grain_size or pos_diff > (1.0 - grain_size):
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.6
		else:
			material.albedo_color = Color(0.3, 0.7, 1.0)
		
		segment.material_override = material
		container.add_child(segment)
	
	# Show grain reading position
	var read_head = CSGSphere3D.new()
	read_head.radius = 0.2
	read_head.position = Vector3(
		(grain_position - 0.5) * 10,
		sin(time * 8) * 0.3,
		1.0
	)
	
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(1.0, 1.0, 0.0)
	head_material.emission_enabled = true
	head_material.emission = Color(1.0, 1.0, 0.0) * 0.8
	read_head.material_override = head_material
	
	container.add_child(read_head)

func show_granular_parameters():
	var container = $GrainParameters
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Visualize parameters as bars
	var parameters = [
		["Size", grain_size * 20],
		["Density", grain_density / 16.0],
		["Pitch", grain_pitch],
		["Scatter", grain_scatter * 50]
	]
	
	for i in range(parameters.size()):
		var param_name = parameters[i][0]
		var param_value = parameters[i][1]
		
		# Parameter bar
		var bar = CSGBox3D.new()
		bar.size = Vector3(0.8, param_value * 3, 0.8)
		bar.position = Vector3(i * 1.2 - parameters.size() * 0.6, param_value * 1.5, 0)
		
		var material = StandardMaterial3D.new()
		var color_hue = float(i) / parameters.size()
		material.albedo_color = Color.from_hsv(color_hue, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(color_hue, 0.8, 1.0) * 0.3
		material.metallic = 0.3
		material.roughness = 0.4
		bar.material_override = material
		
		container.add_child(bar)
		
		# Parameter label (small cube)
		var label = CSGBox3D.new()
		label.size = Vector3(0.3, 0.3, 0.3)
		label.position = Vector3(i * 1.2 - parameters.size() * 0.6, -1, 0)
		
		var label_material = StandardMaterial3D.new()
		label_material.albedo_color = Color(1.0, 1.0, 1.0)
		label.material_override = label_material
		
		container.add_child(label)

func demonstrate_output_synthesis():
	var container = $OutputSynthesis
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Simulate output buffer
	update_output_buffer()
	
	# Visualize output waveform
	for i in range(output_buffer.size() - 1):
		var t1 = float(i) / output_buffer.size()
		var t2 = float(i + 1) / output_buffer.size()
		
		var pos1 = Vector3(
			(t1 - 0.5) * 8,
			output_buffer[i] * 3,
			0
		)
		var pos2 = Vector3(
			(t2 - 0.5) * 8,
			output_buffer[i + 1] * 3,
			0
		)
		
		# Create output waveform segment
		var segment = CSGCylinder3D.new()
		segment.radius = 0.08
		
		segment.height = pos1.distance_to(pos2)
		
		segment.position = (pos1 + pos2) * 0.5
		segment.look_at_from_position(segment.position, pos2, Vector3.UP)
		segment.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		var material = StandardMaterial3D.new()
		var amplitude = abs(output_buffer[i])
		material.albedo_color = Color(0.2 + amplitude, 1.0, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.2 + amplitude, 1.0, 0.2) * 0.4
		segment.material_override = material
		
		container.add_child(segment)
	
	# Show grain contributions
	var grain_contributions = CSGSphere3D.new()
	grain_contributions.radius = max(0.1, float(active_grains.size()) * 0.05)
	grain_contributions.position = Vector3(0, 4, 0)
	
	var contrib_material = StandardMaterial3D.new()
	contrib_material.albedo_color = Color(1.0, 0.5, 0.0)
	contrib_material.emission_enabled = true
	contrib_material.emission = Color(1.0, 0.5, 0.0) * 0.6
	grain_contributions.material_override = contrib_material
	
	container.add_child(grain_contributions)

func update_output_buffer():
	# Simulate granular synthesis output
	output_buffer.clear()
	
	for i in range(100):
		var sample = 0.0
		var t = float(i) / 100.0
		
		# Sum contributions from all active grains
		for grain in active_grains:
			var grain_phase = grain.age / grain.lifetime
			if grain_phase < 1.0:
				# Apply grain envelope
				var envelope = sin(grain_phase * PI)
				
				# Sample from source material
				var source_index = int(grain.source_position * waveform_data.size()) % waveform_data.size()
				var source_sample = waveform_data[source_index]
				
				# Apply pitch and amplitude
				var grain_contribution = source_sample * envelope * grain.amplitude * 0.1
				sample += grain_contribution
		
		# Add some movement to the output
		sample += sin(time * 4 + t * TAU * 2) * 0.1
		
		output_buffer.append(sample)
