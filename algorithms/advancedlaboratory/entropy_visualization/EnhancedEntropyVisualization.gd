extends Node3D
class_name EnhancedEntropyVisualizations

# Entropy system properties
var time: float = 0.0
var entropy_level: float = 0.0
var max_entropy: float = 0.0
var entropy_rate: float = 0.0
var temperature: float = 300.0
var animation_speed: float = 1.0
var is_paused: bool = false

# Auto-randomization
var auto_randomize_timer: float = 0.0
var auto_randomize_interval: float = 10.0

# Particle system
var particle_count: int = 100
var ordered_particles: Array = []
var transition_particles: Array = []
var disordered_particles: Array = []
var flow_particles: Array = []

# System types
enum SystemType { IDEAL_GAS, CRYSTAL_LATTICE, FLUID, PLASMA, INFORMATION }
var current_system: SystemType = SystemType.IDEAL_GAS

# Visualization components
var entropy_history: Array = []
var max_history_length: int = 100

# Materials for different particle states
var materials: Dictionary = {}

# Energy flow visualization
var energy_connections: Array = []
var flow_vectors: Array = []

func _ready():
	print("Enhanced Entropy Visualization initialized")
	setup_materials()
	setup_ui_connections()
	initialize_systems()
	create_particle_systems()
	setup_entropy_tracking()

func _process(delta):
	if not is_paused:
		time += delta * animation_speed
		auto_randomize_timer += delta
		
		# Auto-randomize every 10 seconds
		if auto_randomize_timer >= auto_randomize_interval:
			auto_randomize_timer = 0.0
			auto_randomize_system()
		
		update_entropy_calculations(delta)
		animate_systems(delta)
		update_visualizations(delta)
		update_ui_display()

func setup_materials():
	# Create materials for different entropy states
	materials["ordered"] = create_material(Color(0.1, 0.8, 0.3), Color(0.05, 0.4, 0.15))
	materials["transition"] = create_material(Color(0.9, 0.6, 0.1), Color(0.45, 0.3, 0.05))
	materials["disordered"] = create_material(Color(0.9, 0.2, 0.1), Color(0.45, 0.1, 0.05))
	materials["high_energy"] = create_material(Color(0.9, 0.1, 0.9), Color(0.45, 0.05, 0.45))
	materials["low_energy"] = create_material(Color(0.1, 0.5, 0.9), Color(0.05, 0.25, 0.45))

func create_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy = 2.0
	material.metallic = 0.2
	material.roughness = 0.3
	return material

func setup_ui_connections():
	# Connect UI controls
	var system_option = $InteractiveControls/ControlPanel/SystemTypeOption
	system_option.add_item("Ideal Gas")
	system_option.add_item("Crystal Lattice")
	system_option.add_item("Fluid")
	system_option.add_item("Plasma")
	system_option.add_item("Information")
	system_option.item_selected.connect(_on_system_type_changed)
	
	$InteractiveControls/ControlPanel/TemperatureSlider.value_changed.connect(_on_temperature_changed)
	$InteractiveControls/ControlPanel/ParticleCountSlider.value_changed.connect(_on_particle_count_changed)
	$InteractiveControls/ControlPanel/AnimationSpeedSlider.value_changed.connect(_on_animation_speed_changed)
	
	$InteractiveControls/ControlPanel/ButtonContainer/ResetButton.pressed.connect(_on_reset_pressed)
	$InteractiveControls/ControlPanel/ButtonContainer/PlayPauseButton.pressed.connect(_on_play_pause_pressed)
	$InteractiveControls/ControlPanel/ButtonContainer/RandomizeButton.pressed.connect(_on_randomize_pressed)

func initialize_systems():
	# Calculate maximum possible entropy for current system
	max_entropy = calculate_max_entropy()
	entropy_level = 0.1  # Start with low entropy

func create_particle_systems():
	clear_existing_particles()
	
	# Create ordered system particles
	create_ordered_particles()
	
	# Create transition system particles  
	create_transition_particles()
	
	# Create disordered system particles
	create_disordered_particles()
	
	# Create energy flow particles
	create_flow_particles()

func clear_existing_particles():
	for particle in ordered_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	for particle in transition_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	for particle in disordered_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	
	ordered_particles.clear()
	transition_particles.clear()
	disordered_particles.clear()

func create_ordered_particles():
	var container = $SystemsContainer/OrderedSystem/OrderedParticles
	var grid_size = int(sqrt(particle_count))
	
	for i in range(particle_count):
		var particle = create_particle_mesh()
		particle.material_override = materials["ordered"]
		
		# Perfect grid arrangement
		var x = (i % grid_size - grid_size * 0.5) * 0.8
		var y = (i / grid_size - grid_size * 0.5) * 0.8
		var z = sin(i * 0.1) * 0.2  # Slight variation
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		ordered_particles.append(particle)

func create_transition_particles():
	var container = $SystemsContainer/TransitionSystem/TransitionParticles
	
	for i in range(particle_count):
		var particle = create_particle_mesh()
		particle.material_override = materials["transition"]
		
		# Semi-random positions
		var angle = i * TAU / particle_count
		var radius = randf_range(2.0, 4.0)
		var x = cos(angle) * radius + randf_range(-0.5, 0.5)
		var y = sin(angle) * radius + randf_range(-0.5, 0.5)
		var z = randf_range(-1.0, 1.0)
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		transition_particles.append(particle)

func create_disordered_particles():
	var container = $SystemsContainer/DisorderedSystem/DisorderedParticles
	
	for i in range(particle_count):
		var particle = create_particle_mesh()
		particle.material_override = materials["disordered"]
		
		# Completely random positions
		var x = randf_range(-5.0, 5.0)
		var y = randf_range(-5.0, 5.0)
		var z = randf_range(-2.0, 2.0)
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		disordered_particles.append(particle)

func create_particle_mesh() -> MeshInstance3D:
	var particle = MeshInstance3D.new()
	
	# Vary particle shapes based on system type
	match current_system:
		SystemType.IDEAL_GAS:
			particle.mesh = SphereMesh.new()
			particle.mesh.radius = 0.1
		SystemType.CRYSTAL_LATTICE:
			particle.mesh = BoxMesh.new()
			particle.mesh.size = Vector3(0.15, 0.15, 0.15)
		SystemType.FLUID:
			particle.mesh = SphereMesh.new()
			particle.mesh.radius = 0.08
		SystemType.PLASMA:
			particle.mesh = SphereMesh.new()
			particle.mesh.radius = 0.12
		SystemType.INFORMATION:
			particle.mesh = BoxMesh.new()
			particle.mesh.size = Vector3(0.1, 0.1, 0.1)
	
	return particle

func create_flow_particles():
	var container = $EnergyFlowSystem/FlowParticles
	
	for i in range(20):
		var particle = MeshInstance3D.new()
		particle.mesh = SphereMesh.new()
		particle.mesh.radius = 0.05
		particle.material_override = materials["high_energy"]
		
		# Position along flow paths
		var t = i / 20.0
		var x = lerp(-10.0, 10.0, t)
		var y = sin(t * TAU * 2) * 2.0
		var z = cos(t * TAU) * 1.0
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		flow_particles.append(particle)

func setup_entropy_tracking():
	entropy_history.clear()
	entropy_history.resize(max_history_length)
	entropy_history.fill(0.0)

func update_entropy_calculations(delta):
	# Calculate entropy based on particle distribution and system type
	var new_entropy = calculate_system_entropy()
	
	# Calculate entropy rate
	entropy_rate = (new_entropy - entropy_level) / delta
	entropy_level = new_entropy
	
	# Update history
	entropy_history.push_back(entropy_level)
	if entropy_history.size() > max_history_length:
		entropy_history.pop_front()

func calculate_system_entropy() -> float:
	match current_system:
		SystemType.IDEAL_GAS:
			return calculate_gas_entropy()
		SystemType.CRYSTAL_LATTICE:
			return calculate_lattice_entropy()
		SystemType.FLUID:
			return calculate_fluid_entropy()
		SystemType.PLASMA:
			return calculate_plasma_entropy()
		SystemType.INFORMATION:
			return calculate_information_entropy()
		_:
			return 0.0

func calculate_gas_entropy() -> float:
	# Simplified ideal gas entropy: S = k * ln(V) + (3/2) * k * ln(T)
	var volume_factor = log(particle_count) / log(2)  # Normalize
	var temperature_factor = 1.5 * log(temperature / 300.0) / log(2)
	var time_factor = min(1.0, time * 0.1)  # Gradual increase
	
	return (volume_factor + temperature_factor + time_factor) / 10.0

func calculate_lattice_entropy() -> float:
	# Crystal lattice entropy (configurational)
	var disorder_factor = sin(time * 0.5) * 0.5 + 0.5
	var temperature_factor = temperature / 1000.0
	
	return disorder_factor * temperature_factor * 0.5

func calculate_fluid_entropy() -> float:
	# Fluid entropy with mixing
	var mixing_factor = sin(time * 0.3) * 0.3 + 0.7
	var temperature_factor = log(temperature / 273.0) / log(2)
	
	return mixing_factor * temperature_factor * 0.6

func calculate_plasma_entropy() -> float:
	# High temperature plasma entropy
	var ionization_factor = clamp(temperature / 10000.0, 0.0, 1.0)
	var time_factor = sin(time * 0.8) * 0.4 + 0.6
	
	return ionization_factor * time_factor * 0.9

func calculate_information_entropy() -> float:
	# Information theoretic entropy
	var information_content = sin(time * 0.2) * 0.5 + 0.5
	var uncertainty_factor = cos(time * 0.15) * 0.3 + 0.7
	
	return information_content * uncertainty_factor * 0.8

func calculate_max_entropy() -> float:
	# Theoretical maximum entropy for the system
	match current_system:
		SystemType.IDEAL_GAS:
			return 1.0
		SystemType.CRYSTAL_LATTICE:
			return 0.5
		SystemType.FLUID:
			return 0.8
		SystemType.PLASMA:
			return 1.2
		SystemType.INFORMATION:
			return log(particle_count) / log(2) / 10.0
		_:
			return 1.0

func animate_systems(delta):
	animate_particles(delta)
	animate_energy_flow(delta)
	animate_entropy_meter(delta)
	update_connections(delta)
	animate_temperature_effects(delta)

func animate_particles(delta):
	var entropy_factor = entropy_level / max_entropy
	
	# Animate ordered particles
	for i in range(ordered_particles.size()):
		var particle = ordered_particles[i]
		if not is_instance_valid(particle):
			continue
			
		# Add thermal motion based on temperature
		var thermal_motion = temperature / 300.0 * 0.02
		var noise_x = sin(time * 3.0 + i) * thermal_motion
		var noise_y = cos(time * 2.5 + i) * thermal_motion
		var noise_z = sin(time * 4.0 + i) * thermal_motion * 0.5
		
		particle.position += Vector3(noise_x, noise_y, noise_z) * delta
		
		# Color transition based on entropy
		var material = particle.material_override as StandardMaterial3D
		if material:
			var base_color = materials["ordered"].albedo_color
			var hot_color = materials["disordered"].albedo_color
			material.albedo_color = base_color.lerp(hot_color, entropy_factor * 0.3)
	
	# Animate transition particles
	for i in range(transition_particles.size()):
		var particle = transition_particles[i]
		if not is_instance_valid(particle):
			continue
			
		# Orbital motion with increasing chaos
		var angle = time * 0.5 + i * TAU / transition_particles.size()
		var radius = 3.0 + sin(time + i) * entropy_factor
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = sin(time * 2.0 + i) * entropy_factor
		
		particle.position = Vector3(x, y, z)
		
		# Scale based on energy
		var scale_factor = 1.0 + sin(time * 4.0 + i) * 0.2 * entropy_factor
		particle.scale = Vector3.ONE * scale_factor
	
	# Animate disordered particles
	for i in range(disordered_particles.size()):
		var particle = disordered_particles[i]
		if not is_instance_valid(particle):
			continue
			
		# Brownian motion
		var velocity = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-0.5, 0.5)
		) * temperature / 300.0 * delta
		
		particle.position += velocity
		
		# Keep within bounds
		particle.position.x = clamp(particle.position.x, -6, 6)
		particle.position.y = clamp(particle.position.y, -6, 6)
		particle.position.z = clamp(particle.position.z, -3, 3)

func animate_energy_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if not is_instance_valid(particle):
			continue
			
		# Flow from ordered to disordered
		var progress = fmod(time * 0.3 + i * 0.1, 1.0)
		var x = lerp(-12.0, 12.0, progress)
		var y = sin(progress * TAU * 3) * 2.0 * entropy_level
		var z = cos(progress * TAU * 2) * 1.0
		
		particle.position = Vector3(x, y, z)
		
		# Change color based on position
		var material = particle.material_override as StandardMaterial3D
		if material:
			if progress < 0.5:
				material.albedo_color = materials["low_energy"].albedo_color
			else:
				material.albedo_color = materials["high_energy"].albedo_color

func animate_entropy_meter(delta):
	var meter_indicator = $VisualizationPanels/EntropyMeter/MeterIndicator
	if meter_indicator:
		# Move indicator based on entropy level
		var target_x = lerp(-8.0, 8.0, entropy_level / max_entropy)
		meter_indicator.position.x = lerp(meter_indicator.position.x, target_x, delta * 3.0)
		
		# Pulsating effect
		var pulse = 1.0 + sin(time * 4.0) * 0.1
		meter_indicator.scale = Vector3.ONE * pulse
		
		# Color based on entropy
		var material = meter_indicator.material_override as StandardMaterial3D
		if material:
			var entropy_ratio = entropy_level / max_entropy
			var color = Color.GREEN.lerp(Color.RED, entropy_ratio)
			material.albedo_color = color
			material.emission = color * 0.5

func update_connections(delta):
	# Update particle connections for ordered system
	var connections_container = $SystemsContainer/OrderedSystem/OrderedConnections
	
	# Clear existing connections
	for child in connections_container.get_children():
		child.queue_free()
	
	# Create new connections based on proximity and order
	if ordered_particles.size() > 1:
		for i in range(min(ordered_particles.size(), 50)):  # Limit for performance
			for j in range(i + 1, min(i + 4, ordered_particles.size())):
				var p1 = ordered_particles[i]
				var p2 = ordered_particles[j]
				
				if is_instance_valid(p1) and is_instance_valid(p2):
					var distance = p1.position.distance_to(p2.position)
					if distance < 2.0:  # Only connect nearby particles
						create_connection_line(p1.position, p2.position, connections_container)

func create_connection_line(pos1: Vector3, pos2: Vector3, container: Node3D):
	var line = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	var distance = pos1.distance_to(pos2)
	mesh.height = distance
	mesh.top_radius = 0.01
	mesh.bottom_radius = 0.01
	
	line.mesh = mesh
	line.material_override = materials["low_energy"]
	
	# Position and orient the line
	var midpoint = (pos1 + pos2) * 0.5
	line.position = midpoint
	line.look_at(pos2, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	
	container.add_child(line)

func animate_temperature_effects(delta):
	# Update particle speeds and colors based on temperature
	var temp_factor = temperature / 300.0
	
	# Update all particle materials
	for particles in [ordered_particles, transition_particles, disordered_particles]:
		for particle in particles:
			if not is_instance_valid(particle):
				continue
				
			var material = particle.material_override as StandardMaterial3D
			if material:
				# Increase emission with temperature
				material.emission_energy = 1.0 + temp_factor * 2.0
				
				# Add heat color tint
				if temp_factor > 1.5:
					var heat_tint = Color.RED * (temp_factor - 1.5) * 0.3
					material.emission += heat_tint

func update_visualizations(delta):
	update_entropy_graph()
	update_information_display()

func update_entropy_graph():
	var graph_container = $VisualizationPanels/InformationPanel/EntropyGraph/GraphData
	
	# Clear existing graph
	for child in graph_container.get_children():
		child.queue_free()
	
	# Draw entropy history
	if entropy_history.size() > 1:
		for i in range(entropy_history.size() - 1):
			var x1 = (i / float(max_history_length)) * 15.0 - 7.5
			var y1 = entropy_history[i] * 2.0 - 1.0
			var x2 = ((i + 1) / float(max_history_length)) * 15.0 - 7.5
			var y2 = entropy_history[i + 1] * 2.0 - 1.0
			
			if abs(y2 - y1) < 0.5:  # Avoid drawing crazy lines
				create_graph_line(Vector3(x1, y1, 0), Vector3(x2, y2, 0), graph_container)

func create_graph_line(pos1: Vector3, pos2: Vector3, container: Node3D):
	var line = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	var distance = pos1.distance_to(pos2)
	mesh.height = distance
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.02
	
	line.mesh = mesh
	line.material_override = materials["high_energy"]
	
	var midpoint = (pos1 + pos2) * 0.5
	line.position = midpoint
	line.look_at(pos2, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	
	container.add_child(line)

func update_information_display():
	# Update entropy info labels
	pass  # UI updates handled in update_ui_display()

func update_ui_display():
	# Update all UI labels with current values
	$InteractiveControls/ControlPanel/TemperatureLabel.text = "Temperature: %.0fK" % temperature
	$InteractiveControls/ControlPanel/ParticleCountLabel.text = "Particle Count: %d" % particle_count
	$InteractiveControls/ControlPanel/AnimationSpeedLabel.text = "Animation Speed: %.1fx" % animation_speed
	
	$InteractiveControls/InfoDisplay/CurrentEntropyLabel.text = "Current Entropy: %.3f" % entropy_level
	$InteractiveControls/InfoDisplay/MaxEntropyLabel.text = "Maximum Entropy: %.3f" % max_entropy
	$InteractiveControls/InfoDisplay/EntropyRateLabel.text = "Entropy Rate: %.3f/s" % entropy_rate
	
	# System state description
	var state_text = "Ordered"
	var entropy_ratio = entropy_level / max_entropy
	if entropy_ratio > 0.7:
		state_text = "Highly Disordered"
	elif entropy_ratio > 0.4:
		state_text = "Transitioning"
	elif entropy_ratio > 0.1:
		state_text = "Partially Ordered"
	
	$InteractiveControls/InfoDisplay/SystemStateLabel.text = "System State: " + state_text

# UI Event Handlers
func _on_system_type_changed(index: int):
	current_system = index as SystemType
	initialize_systems()
	create_particle_systems()

func _on_temperature_changed(value: float):
	temperature = value

func _on_particle_count_changed(value: float):
	particle_count = int(value)
	create_particle_systems()

func _on_animation_speed_changed(value: float):
	animation_speed = value

func _on_reset_pressed():
	time = 0.0
	entropy_level = 0.1
	temperature = 300.0
	animation_speed = 1.0
	is_paused = false
	
	$InteractiveControls/ControlPanel/TemperatureSlider.value = 300.0
	$InteractiveControls/ControlPanel/AnimationSpeedSlider.value = 1.0
	$InteractiveControls/ControlPanel/ButtonContainer/PlayPauseButton.text = "Pause"
	
	setup_entropy_tracking()
	create_particle_systems()

func _on_play_pause_pressed():
	is_paused = !is_paused
	var button = $InteractiveControls/ControlPanel/ButtonContainer/PlayPauseButton
	button.text = "Play" if is_paused else "Pause"

func _on_randomize_pressed():
	auto_randomize_system()

func auto_randomize_system():
	# Randomize system parameters automatically
	temperature = randf_range(100.0, 800.0)
	animation_speed = randf_range(0.5, 3.0)
	
	# Randomly change system type occasionally
	if randf() < 0.3:  # 30% chance to change system type
		current_system = randi() % SystemType.size()
		initialize_systems()
		create_particle_systems()
	
	$InteractiveControls/ControlPanel/TemperatureSlider.value = temperature
	$InteractiveControls/ControlPanel/AnimationSpeedSlider.value = animation_speed
	$InteractiveControls/ControlPanel/SystemTypeOption.selected = current_system
	
	# Add random energy to system
	entropy_level = min(max_entropy, entropy_level + randf_range(0.1, 0.3))
	
	print("Auto-randomized system: Type=%s, Temp=%.1fK, Speed=%.1fx" % [
		SystemType.keys()[current_system], temperature, animation_speed
	])

# Public API
func get_entropy_level() -> float:
	return entropy_level

func get_entropy_ratio() -> float:
	return entropy_level / max_entropy if max_entropy > 0 else 0.0

func set_system_temperature(temp: float):
	temperature = clamp(temp, 1.0, 1000.0)

func get_system_info() -> Dictionary:
	return {
		"entropy": entropy_level,
		"max_entropy": max_entropy,
		"entropy_rate": entropy_rate,
		"temperature": temperature,
		"particle_count": particle_count,
		"system_type": current_system
	}
