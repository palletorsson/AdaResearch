extends Node3D
class_name EnhancedFeedbackCyberneticss

# Control system parameters
var time: float = 0.0
var setpoint: float = 1.0
var current_output: float = 0.0
var previous_error: float = 0.0
var integral_sum: float = 0.0
var disturbance_level: float = 0.1

# PID Controller gains
var kp: float = 1.0  # Proportional gain
var ki: float = 0.1  # Integral gain
var kd: float = 0.05 # Derivative gain

# System dynamics
var plant_time_constant: float = 2.0
var plant_gain: float = 1.5
var sensor_delay: float = 0.1
var noise_amplitude: float = 0.05

# Control types
enum ControllerType { PID, PI, PD, P_ONLY, FUZZY, ADAPTIVE }
var current_controller: ControllerType = ControllerType.PID

# Performance metrics
var steady_state_error: float = 0.0
var overshoot: float = 0.0
var settling_time: float = 0.0
var rise_time: float = 0.0
var system_stable: bool = true

# Particle systems
var signal_particles: Array = []
var error_particles: Array = []
var control_particles: Array = []
var feedback_particles: Array = []

# Response history for graphing
var response_history: Array = []
var setpoint_history: Array = []
var error_history: Array = []
var max_history_length: int = 200

# Materials
var materials: Dictionary = {}

# Auto-randomization
var auto_randomize_timer: float = 0.0
var auto_randomize_interval: float = 15.0

func _ready():
	print("Enhanced Feedback Cybernetics System initialized")
	setup_materials()
	setup_ui_connections()
	initialize_system()
	create_particle_systems()
	create_connection_network()
	setup_response_tracking()

func _process(delta):
	time += delta
	auto_randomize_timer += delta
	
	# Auto-randomize every 15 seconds
	if auto_randomize_timer >= auto_randomize_interval:
		auto_randomize_timer = 0.0
		auto_randomize_system()
	
	update_control_system(delta)
	animate_systems(delta)
	update_visualizations(delta)
	calculate_performance_metrics()
	update_ui_display()

func setup_materials():
	materials["setpoint"] = create_material(Color(0.1, 0.8, 0.3), Color(0.05, 0.4, 0.15))
	materials["error"] = create_material(Color(0.8, 0.1, 0.8), Color(0.4, 0.05, 0.4))
	materials["control"] = create_material(Color(0.2, 0.5, 0.9), Color(0.1, 0.25, 0.45))
	materials["output"] = create_material(Color(0.8, 0.2, 0.1), Color(0.4, 0.1, 0.05))
	materials["feedback"] = create_material(Color(0.1, 0.9, 0.9), Color(0.05, 0.45, 0.45))
	materials["disturbance"] = create_material(Color(0.9, 0.6, 0.1), Color(0.45, 0.3, 0.05))

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
	var controller_option = $InteractiveControls/ControlPanel/ControllerTypeOption
	controller_option.add_item("PID Controller")
	controller_option.add_item("PI Controller")
	controller_option.add_item("PD Controller")
	controller_option.add_item("P Only")
	controller_option.add_item("Fuzzy Logic")
	controller_option.add_item("Adaptive")
	controller_option.item_selected.connect(_on_controller_type_changed)
	
	$InteractiveControls/ControlPanel/SetpointSlider.value_changed.connect(_on_setpoint_changed)
	$InteractiveControls/ControlPanel/KpSlider.value_changed.connect(_on_kp_changed)
	$InteractiveControls/ControlPanel/KiSlider.value_changed.connect(_on_ki_changed)
	$InteractiveControls/ControlPanel/KdSlider.value_changed.connect(_on_kd_changed)
	$InteractiveControls/ControlPanel/DisturbanceSlider.value_changed.connect(_on_disturbance_changed)
	
	$InteractiveControls/ControlPanel/ButtonContainer/StepResponseButton.pressed.connect(_on_step_response)
	$InteractiveControls/ControlPanel/ButtonContainer/ResetButton.pressed.connect(_on_reset_system)
	$InteractiveControls/ControlPanel/ButtonContainer/AutoTuneButton.pressed.connect(_on_auto_tune)

func initialize_system():
	current_output = 0.0
	integral_sum = 0.0
	previous_error = setpoint - current_output
	
	# Initialize system components
	update_system_positions()

func create_particle_systems():
	create_signal_particles()
	create_error_particles()
	create_control_particles()
	create_feedback_particles()

func create_signal_particles():
	var container = $DataFlowSystem/SignalParticles
	signal_particles.clear()
	
	for i in range(30):
		var particle = MeshInstance3D.new()
		particle.mesh = SphereMesh.new()
		particle.mesh.radius = 0.08
		particle.material_override = materials["setpoint"]
		
		# Position along forward path
		var progress = i / 30.0
		var x = lerp(-15.0, 15.0, progress)
		var y = sin(progress * TAU * 2) * 0.5
		var z = 0
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		signal_particles.append(particle)

func create_error_particles():
	var container = $DataFlowSystem/ErrorSignals
	error_particles.clear()
	
	for i in range(20):
		var particle = MeshInstance3D.new()
		particle.mesh = BoxMesh.new()
		particle.mesh.size = Vector3(0.1, 0.1, 0.1)
		particle.material_override = materials["error"]
		
		# Position around error node
		var angle = i * TAU / 20.0
		var radius = 2.0
		var x = -8 + cos(angle) * radius
		var y = sin(angle) * radius
		var z = cos(angle * 2) * 0.5
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		error_particles.append(particle)

func create_control_particles():
	var container = $DataFlowSystem/ControlSignals
	control_particles.clear()
	
	for i in range(25):
		var particle = MeshInstance3D.new()
		particle.mesh = CylinderMesh.new()
		particle.mesh.top_radius = 0.05
		particle.mesh.bottom_radius = 0.05
		particle.mesh.height = 0.2
		particle.material_override = materials["control"]
		
		# Position along control path
		var progress = i / 25.0
		var x = lerp(0.0, 8.0, progress)
		var y = sin(progress * TAU * 3) * 0.3
		var z = cos(progress * TAU * 2) * 0.2
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		control_particles.append(particle)

func create_feedback_particles():
	var container = $DataFlowSystem/FeedbackSignals
	feedback_particles.clear()
	
	for i in range(35):
		var particle = MeshInstance3D.new()
		particle.mesh = CapsuleMesh.new()
		particle.mesh.radius = 0.04
		particle.mesh.height = 0.15
		particle.material_override = materials["feedback"]
		
		# Position along feedback path
		var progress = i / 35.0
		var angle = progress * TAU
		var radius = 8.0
		var x = 8 + cos(angle + PI) * radius
		var y = -3 + sin(angle + PI) * 3.0
		var z = sin(progress * TAU * 4) * 0.3
		
		particle.position = Vector3(x, y, z)
		container.add_child(particle)
		feedback_particles.append(particle)

func create_connection_network():
	create_forward_connections()
	create_feedback_connections()

func create_forward_connections():
	var container = $ConnectionNetwork/ForwardConnections
	
	# Clear existing connections
	for child in container.get_children():
		child.queue_free()
	
	# Create main forward path connections
	var connections = [
		[Vector3(-15, 0, 0), Vector3(-8, 0, 0)],  # Setpoint to Error
		[Vector3(-8, 0, 0), Vector3(0, 0, 0)],    # Error to Controller
		[Vector3(0, 0, 0), Vector3(8, 0, 0)],     # Controller to Plant
		[Vector3(8, 0, 0), Vector3(15, 0, 0)]     # Plant to Output
	]
	
	for connection in connections:
		create_connection_line(connection[0], connection[1], container, materials["control"])

func create_feedback_connections():
	var container = $ConnectionNetwork/FeedbackConnections
	
	# Clear existing connections
	for child in container.get_children():
		child.queue_free()
	
	# Create feedback path connections
	var feedback_connections = [
		[Vector3(15, 0, 0), Vector3(8, -6, 0)],   # Output to Sensor
		[Vector3(8, -6, 0), Vector3(-8, -6, 0)],  # Sensor to Error (negative)
		[Vector3(-8, -6, 0), Vector3(-8, 0, 0)]   # Complete feedback loop
	]
	
	for connection in feedback_connections:
		create_connection_line(connection[0], connection[1], container, materials["feedback"])

func create_connection_line(pos1: Vector3, pos2: Vector3, container: Node3D, material: StandardMaterial3D):
	var line = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	var distance = pos1.distance_to(pos2)
	mesh.height = distance
	mesh.top_radius = 0.03
	mesh.bottom_radius = 0.03
	
	line.mesh = mesh
	line.material_override = material
	
	# Position and orient the line
	var midpoint = (pos1 + pos2) * 0.5
	line.position = midpoint
	line.look_at(pos2, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	
	container.add_child(line)

func setup_response_tracking():
	response_history.clear()
	setpoint_history.clear()
	error_history.clear()
	
	response_history.resize(max_history_length)
	setpoint_history.resize(max_history_length)
	error_history.resize(max_history_length)
	
	response_history.fill(0.0)
	setpoint_history.fill(setpoint)
	error_history.fill(setpoint)

func update_control_system(delta):
	# Add disturbances
	var disturbance = sin(time * 2.0) * disturbance_level + randf_range(-noise_amplitude, noise_amplitude)
	
	# Calculate error
	var error = setpoint - current_output
	
	# Calculate control signal based on controller type
	var control_signal = calculate_control_signal(error, delta)
	
	# Plant dynamics (first-order system with delay)
	var plant_input = control_signal + disturbance
	var target_output = plant_gain * plant_input
	current_output = lerp(current_output, target_output, delta / plant_time_constant)
	
	# Update histories
	response_history.push_back(current_output)
	setpoint_history.push_back(setpoint)
	error_history.push_back(abs(error))
	
	if response_history.size() > max_history_length:
		response_history.pop_front()
		setpoint_history.pop_front()
		error_history.pop_front()
	
	# Store previous error for derivative calculation
	previous_error = error

func calculate_control_signal(error: float, delta: float) -> float:
	match current_controller:
		ControllerType.PID:
			return calculate_pid_output(error, delta)
		ControllerType.PI:
			return calculate_pi_output(error, delta)
		ControllerType.PD:
			return calculate_pd_output(error, delta)
		ControllerType.P_ONLY:
			return kp * error
		ControllerType.FUZZY:
			return calculate_fuzzy_output(error, delta)
		ControllerType.ADAPTIVE:
			return calculate_adaptive_output(error, delta)
		_:
			return 0.0

func calculate_pid_output(error: float, delta: float) -> float:
	# Proportional term
	var p_term = kp * error
	
	# Integral term
	integral_sum += error * delta
	var i_term = ki * integral_sum
	
	# Derivative term
	var d_term = 0.0
	if delta > 0:
		d_term = kd * (error - previous_error) / delta
	
	return p_term + i_term + d_term

func calculate_pi_output(error: float, delta: float) -> float:
	var p_term = kp * error
	integral_sum += error * delta
	var i_term = ki * integral_sum
	return p_term + i_term

func calculate_pd_output(error: float, delta: float) -> float:
	var p_term = kp * error
	var d_term = 0.0
	if delta > 0:
		d_term = kd * (error - previous_error) / delta
	return p_term + d_term

func calculate_fuzzy_output(error: float, delta: float) -> float:
	# Simplified fuzzy logic controller
	var error_norm = clamp(error / setpoint, -1.0, 1.0)
	
	if abs(error_norm) < 0.1:  # Small error
		return kp * error * 0.5
	elif abs(error_norm) < 0.5:  # Medium error
		return kp * error * 1.0
	else:  # Large error
		return kp * error * 1.5

func calculate_adaptive_output(error: float, delta: float) -> float:
	# Adaptive controller adjusts gains based on system performance
	var performance_factor = 1.0 - abs(steady_state_error)
	var adaptive_kp = kp * (0.5 + performance_factor)
	var adaptive_ki = ki * performance_factor
	
	var p_term = adaptive_kp * error
	integral_sum += error * delta
	var i_term = adaptive_ki * integral_sum
	
	return p_term + i_term

func animate_systems(delta):
	animate_particles(delta)
	animate_system_components(delta)
	animate_pid_components(delta)
	update_stability_meter(delta)

func animate_particles(delta):
	# Animate signal flow particles
	for i in range(signal_particles.size()):
		var particle = signal_particles[i]
		if not is_instance_valid(particle):
			continue
		
		var flow_speed = 2.0 + abs(current_output - setpoint)
		var progress = fmod(time * flow_speed + i * 0.1, 1.0)
		var x = lerp(-15.0, 15.0, progress)
		var y = sin(progress * TAU * 3) * 0.5
		
		particle.position.x = x
		particle.position.y = y
		
		# Color based on signal strength
		var intensity = 0.5 + abs(setpoint - current_output) * 0.5
		var material = particle.material_override as StandardMaterial3D
		if material:
			material.emission_energy = 1.0 + intensity * 2.0
	
	# Animate error particles
	for i in range(error_particles.size()):
		var particle = error_particles[i]
		if not is_instance_valid(particle):
			continue
		
		var error_magnitude = abs(setpoint - current_output)
		var angle = time * 3.0 + i * TAU / error_particles.size()
		var radius = 1.0 + error_magnitude
		
		particle.position.x = -8 + cos(angle) * radius
		particle.position.y = sin(angle) * radius
		
		# Scale based on error
		var scale_factor = 1.0 + error_magnitude * 0.5
		particle.scale = Vector3.ONE * scale_factor
	
	# Animate control particles
	for i in range(control_particles.size()):
		var particle = control_particles[i]
		if not is_instance_valid(particle):
			continue
		
		var control_flow = abs(calculate_control_signal(setpoint - current_output, 0.016))
		var progress = fmod(time * (1.0 + control_flow) + i * 0.05, 1.0)
		var x = lerp(0.0, 8.0, progress)
		
		particle.position.x = x
		particle.position.y = sin(progress * TAU * 4) * 0.3 * control_flow
	
	# Animate feedback particles
	for i in range(feedback_particles.size()):
		var particle = feedback_particles[i]
		if not is_instance_valid(particle):
			continue
		
		var feedback_speed = 1.5 + current_output * 0.5
		var progress = fmod(time * feedback_speed + i * 0.03, 1.0)
		var path_progress = 1.0 - progress  # Reverse direction for feedback
		
		if path_progress > 0.66:  # Sensor to error junction
			var local_progress = (path_progress - 0.66) / 0.34
			particle.position.x = lerp(8.0, -8.0, local_progress)
			particle.position.y = -6.0
		elif path_progress > 0.33:  # Output to sensor
			var local_progress = (path_progress - 0.33) / 0.33
			particle.position.x = lerp(15.0, 8.0, local_progress)
			particle.position.y = lerp(0.0, -6.0, local_progress)
		else:  # Error junction vertical
			var local_progress = path_progress / 0.33
			particle.position.x = -8.0
			particle.position.y = lerp(-6.0, 0.0, local_progress)

func animate_system_components(delta):
	# Animate main control loop components
	var setpoint_node = $ControlSystems/MainControlLoop/Setpoint/SetpointSphere
	if setpoint_node:
		setpoint_node.scale = Vector3.ONE * (1.0 + sin(time * 2.0) * 0.1)
		var material = setpoint_node.material_override as StandardMaterial3D
		if material:
			material.emission_energy = 1.5 + setpoint * 0.5
	
	var controller_node = $ControlSystems/MainControlLoop/Controller/ControllerCube
	if controller_node:
		var control_activity = abs(calculate_control_signal(setpoint - current_output, 0.016))
		controller_node.scale = Vector3.ONE * (1.0 + control_activity * 0.1)
		controller_node.rotation.y += delta * control_activity
	
	var plant_node = $ControlSystems/MainControlLoop/Plant/PlantSphere
	if plant_node:
		plant_node.scale = Vector3.ONE * (1.0 + current_output * 0.1)
		plant_node.rotation.x += delta * current_output
	
	var output_node = $ControlSystems/MainControlLoop/Output/OutputSphere
	if output_node:
		output_node.scale = Vector3.ONE * (0.8 + current_output * 0.4)
		var material = output_node.material_override as StandardMaterial3D
		if material:
			var output_ratio = current_output / setpoint if setpoint != 0 else 0
			material.albedo_color = Color.GREEN.lerp(Color.RED, abs(1.0 - output_ratio))

func animate_pid_components(delta):
	# Animate PID controller components
	var p_node = $ControlSystems/PIDController/ProportionalNode/PNode
	var i_node = $ControlSystems/PIDController/IntegralNode/INode
	var d_node = $ControlSystems/PIDController/DerivativeNode/DNode
	
	var error = setpoint - current_output
	
	if p_node:
		var p_term = kp * error
		p_node.scale = Vector3.ONE * (1.0 + abs(p_term) * 0.1)
		p_node.rotation.y += delta * p_term
	
	if i_node:
		var i_term = ki * integral_sum
		i_node.scale = Vector3.ONE * (1.0 + abs(i_term) * 0.05)
		i_node.rotation.z += delta * i_term * 0.5
	
	if d_node:
		var d_term = kd * (error - previous_error) / 0.016 if 0.016 > 0 else 0
		d_node.scale = Vector3.ONE * (1.0 + abs(d_term) * 0.2)
		d_node.rotation.x += delta * d_term * 2.0

func update_stability_meter(delta):
	var stability_indicator = $VisualizationPanels/StabilityMeter/StabilityIndicator
	if stability_indicator:
		# Calculate stability based on error and oscillation
		var error = abs(setpoint - current_output)
		var stability_value = clamp(1.0 - error, 0.0, 1.0)
		
		# Position indicator on meter
		var angle = lerp(PI, 0.0, stability_value)
		var radius = 1.5
		stability_indicator.position.x = cos(angle) * radius
		stability_indicator.position.y = 0.5 + sin(angle) * radius
		
		# Color based on stability
		var material = stability_indicator.material_override as StandardMaterial3D
		if material:
			if stability_value > 0.8:
				material.albedo_color = Color.GREEN
			elif stability_value > 0.5:
				material.albedo_color = Color.YELLOW
			else:
				material.albedo_color = Color.RED

func update_visualizations(delta):
	update_response_graph()
	update_performance_metrics()

func update_response_graph():
	var graph_container = $VisualizationPanels/SystemResponseGraph/GraphData
	
	# Clear existing graph
	for child in graph_container.get_children():
		child.queue_free()
	
	# Draw response history
	if response_history.size() > 1:
		for i in range(response_history.size() - 1):
			var x1 = (i / float(max_history_length)) * 11.0 - 5.5
			var y1 = response_history[i] * 2.0 - 1.0
			var x2 = ((i + 1) / float(max_history_length)) * 11.0 - 5.5
			var y2 = response_history[i + 1] * 2.0 - 1.0
			
			create_graph_line(Vector3(x1, y1, 0.1), Vector3(x2, y2, 0.1), graph_container, materials["output"])
		
		# Draw setpoint line
		for i in range(setpoint_history.size() - 1):
			var x1 = (i / float(max_history_length)) * 11.0 - 5.5
			var y1 = setpoint_history[i] * 2.0 - 1.0
			var x2 = ((i + 1) / float(max_history_length)) * 11.0 - 5.5
			var y2 = setpoint_history[i + 1] * 2.0 - 1.0
			
			create_graph_line(Vector3(x1, y1, -0.1), Vector3(x2, y2, -0.1), graph_container, materials["setpoint"])

func create_graph_line(pos1: Vector3, pos2: Vector3, container: Node3D, material: StandardMaterial3D):
	var line = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	var distance = pos1.distance_to(pos2)
	mesh.height = distance
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.02
	
	line.mesh = mesh
	line.material_override = material
	
	var midpoint = (pos1 + pos2) * 0.5
	line.position = midpoint
	line.look_at(pos2, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	
	container.add_child(line)

func update_performance_metrics():
	# Update metrics display with colored indicators
	var metrics_container = $VisualizationPanels/PerformanceMetrics/MetricsDisplay
	
	# Clear existing metrics
	for child in metrics_container.get_children():
		child.queue_free()
	
	# Create metric indicators
	var metrics = [
		{"name": "SS Error", "value": steady_state_error, "pos": Vector3(-3, 2, 0)},
		{"name": "Overshoot", "value": overshoot, "pos": Vector3(-1, 2, 0)},
		{"name": "Rise Time", "value": rise_time, "pos": Vector3(1, 2, 0)},
		{"name": "Settling", "value": settling_time, "pos": Vector3(3, 2, 0)}
	]
	
	for metric in metrics:
		var indicator = MeshInstance3D.new()
		indicator.mesh = BoxMesh.new()
		indicator.mesh.size = Vector3(0.8, metric.value * 2.0 + 0.1, 0.2)
		indicator.position = metric.pos
		
		# Color based on performance (green = good, red = bad)
		var performance = 1.0 - clamp(metric.value, 0.0, 1.0)
		var color = Color.GREEN.lerp(Color.RED, 1.0 - performance)
		indicator.material_override = create_material(color, color * 0.5)
		
		metrics_container.add_child(indicator)

func calculate_performance_metrics():
	# Calculate steady state error
	if response_history.size() > 50:
		var recent_avg = 0.0
		for i in range(response_history.size() - 50, response_history.size()):
			recent_avg += response_history[i]
		recent_avg /= 50.0
		steady_state_error = abs(setpoint - recent_avg)
	
	# Calculate overshoot
	var max_response = 0.0
	for value in response_history:
		max_response = max(max_response, value)
	
	if setpoint > 0:
		overshoot = max(0.0, (max_response - setpoint) / setpoint)
	
	# Simple rise time and settling time calculations
	rise_time = time * 0.1  # Simplified
	settling_time = time * 0.2  # Simplified
	
	# System stability check
	if response_history.size() > 20:
		var variance = 0.0
		var mean = 0.0
		var recent_count = min(20, response_history.size())
		
		for i in range(response_history.size() - recent_count, response_history.size()):
			mean += response_history[i]
		mean /= recent_count
		
		for i in range(response_history.size() - recent_count, response_history.size()):
			variance += pow(response_history[i] - mean, 2)
		variance /= recent_count
		
		system_stable = variance < 0.1

func update_ui_display():
	$InteractiveControls/ControlPanel/SetpointLabel.text = "Setpoint: %.2f" % setpoint
	$InteractiveControls/ControlPanel/KpLabel.text = "Proportional Gain (Kp): %.2f" % kp
	$InteractiveControls/ControlPanel/KiLabel.text = "Integral Gain (Ki): %.3f" % ki
	$InteractiveControls/ControlPanel/KdLabel.text = "Derivative Gain (Kd): %.3f" % kd
	$InteractiveControls/ControlPanel/DisturbanceLabel.text = "Disturbance Level: %.2f" % disturbance_level
	
	$InteractiveControls/InfoDisplay/CurrentOutputLabel.text = "Current Output: %.3f" % current_output
	$InteractiveControls/InfoDisplay/SteadyStateErrorLabel.text = "Steady State Error: %.3f" % steady_state_error
	$InteractiveControls/InfoDisplay/SettlingTimeLabel.text = "Settling Time: %.2fs" % settling_time
	$InteractiveControls/InfoDisplay/OvershootLabel.text = "Overshoot: %.1f%%" % (overshoot * 100)
	$InteractiveControls/InfoDisplay/RiseTimeLabel.text = "Rise Time: %.2fs" % rise_time
	
	var stability_text = "Stable" if system_stable else "Unstable"
	$InteractiveControls/InfoDisplay/StabilityLabel.text = "System Stability: " + stability_text

# Auto-randomization function
func auto_randomize_system():
	# Randomize controller parameters
	kp = randf_range(0.5, 3.0)
	ki = randf_range(0.01, 0.5)
	kd = randf_range(0.01, 0.2)
	
	# Randomize setpoint
	setpoint = randf_range(0.5, 2.0)
	
	# Randomize disturbance
	disturbance_level = randf_range(0.05, 0.3)
	
	# Occasionally change controller type
	if randf() < 0.3:
		current_controller = randi() % ControllerType.size()
		$InteractiveControls/ControlPanel/ControllerTypeOption.selected = current_controller
	
	# Update UI sliders
	$InteractiveControls/ControlPanel/SetpointSlider.value = setpoint
	$InteractiveControls/ControlPanel/KpSlider.value = kp
	$InteractiveControls/ControlPanel/KiSlider.value = ki
	$InteractiveControls/ControlPanel/KdSlider.value = kd
	$InteractiveControls/ControlPanel/DisturbanceSlider.value = disturbance_level
	
	# Reset integral sum for new parameters
	integral_sum = 0.0
	
	print("Auto-randomized control system: Kp=%.2f, Ki=%.3f, Kd=%.3f, SP=%.2f" % [kp, ki, kd, setpoint])

func update_system_positions():
	# Update visual positions based on current values
	pass

# UI Event Handlers
func _on_controller_type_changed(index: int):
	current_controller = index as ControllerType
	integral_sum = 0.0  # Reset integral when changing controller

func _on_setpoint_changed(value: float):
	setpoint = value

func _on_kp_changed(value: float):
	kp = value

func _on_ki_changed(value: float):
	ki = value

func _on_kd_changed(value: float):
	kd = value

func _on_disturbance_changed(value: float):
	disturbance_level = value

func _on_step_response():
	setpoint = 1.5 if setpoint < 1.5 else 0.5
	$InteractiveControls/ControlPanel/SetpointSlider.value = setpoint

func _on_reset_system():
	time = 0.0
	current_output = 0.0
	integral_sum = 0.0
	previous_error = 0.0
	auto_randomize_timer = 0.0
	setup_response_tracking()

func _on_auto_tune():
	# Simple Ziegler-Nichols-like auto-tuning
	kp = 1.2
	ki = 0.1
	kd = 0.05
	
	$InteractiveControls/ControlPanel/KpSlider.value = kp
	$InteractiveControls/ControlPanel/KiSlider.value = ki
	$InteractiveControls/ControlPanel/KdSlider.value = kd
	
	integral_sum = 0.0

# Public API
func get_system_info() -> Dictionary:
	return {
		"output": current_output,
		"setpoint": setpoint,
		"error": setpoint - current_output,
		"stability": system_stable,
		"controller_type": current_controller,
		"kp": kp,
		"ki": ki,
		"kd": kd
	}
