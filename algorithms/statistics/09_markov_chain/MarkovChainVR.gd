extends Node3D

# Interactive VR Markov Chain - Stochastic Processes
# Demonstrates state transitions, steady states, and random walks

class_name MarkovChainVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Markov Chain Settings
@export_category("Chain Parameters")
@export var chain_type: ChainType = ChainType.WEATHER_MODEL
@export var num_states: int = 3
@export var simulation_steps: int = 1000
@export var animation_speed: float = 2.0

# Visual Settings
@export_category("Visualization")
@export var show_transition_matrix: bool = true
@export var show_state_history: bool = true
@export var show_steady_state: bool = true

enum ChainType {
	WEATHER_MODEL,
	RANDOM_WALK,
	GENE_EXPRESSION,
	MARKET_MODEL
}

# State definitions for different chain types
var state_names: Array[String] = []
var state_colors: Array[Color] = []

# Markov Chain data
var transition_matrix: Array[Array] = []
var current_state: int = 0
var state_history: Array[int] = []
var state_probabilities: Array[float] = []
var steady_state_probs: Array[float] = []

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var state_display: Node3D
var transition_display: Node3D
var matrix_display: Node3D
var probability_chart: Node3D
var current_state_indicator: Node3D
var info_display: Label3D

# Animation
var simulation_tween: Tween
var is_running: bool = false

func _ready():
	setup_vr()
	initialize_chain_type()
	setup_visualization()
	setup_info_display()
	calculate_steady_state()

func setup_vr():
	"""Initialize VR system"""
	if enable_vr:
		var xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
		else:
			enable_vr = false
	
	xr_origin = XROrigin3D.new()
	add_child(xr_origin)
	
	var xr_camera = XRCamera3D.new()
	xr_origin.add_child(xr_camera)
	
	if enable_vr:
		for hand in ["left_hand", "right_hand"]:
			var controller = XRController3D.new()
			controller.tracker = StringName(hand)
			controller.button_pressed.connect(_on_controller_button)
			xr_origin.add_child(controller)
			controllers.append(controller)

func initialize_chain_type():
	"""Initialize chain based on selected type"""
	match chain_type:
		ChainType.WEATHER_MODEL:
			setup_weather_model()
		ChainType.RANDOM_WALK:
			setup_random_walk()
		ChainType.GENE_EXPRESSION:
			setup_gene_expression()
		ChainType.MARKET_MODEL:
			setup_market_model()

func setup_weather_model():
	"""Setup 3-state weather model: Sunny, Cloudy, Rainy"""
	num_states = 3
	state_names = ["Sunny", "Cloudy", "Rainy"]
	state_colors = [Color.YELLOW, Color.GRAY, Color.BLUE]
	
	# Transition probabilities
	transition_matrix = [
		[0.7, 0.2, 0.1],  # From Sunny
		[0.3, 0.4, 0.3],  # From Cloudy
		[0.2, 0.3, 0.5]   # From Rainy
	]
	
	current_state = 0  # Start sunny

func setup_random_walk():
	"""Setup 1D random walk with absorbing barriers"""
	num_states = 5
	state_names = ["Barrier L", "Left", "Center", "Right", "Barrier R"]
	state_colors = [Color.RED, Color.ORANGE, Color.WHITE, Color.ORANGE, Color.RED]
	
	# Random walk with absorbing barriers
	transition_matrix = [
		[1.0, 0.0, 0.0, 0.0, 0.0],  # Absorbing left barrier
		[0.5, 0.0, 0.5, 0.0, 0.0],  # Left position
		[0.0, 0.5, 0.0, 0.5, 0.0],  # Center position
		[0.0, 0.0, 0.5, 0.0, 0.5],  # Right position
		[0.0, 0.0, 0.0, 0.0, 1.0]   # Absorbing right barrier
	]
	
	current_state = 2  # Start in center

func setup_gene_expression():
	"""Setup gene expression model: Off, Low, High"""
	num_states = 3
	state_names = ["Off", "Low", "High"]
	state_colors = [Color.BLACK, Color.GREEN, Color.RED]
	
	# Gene expression transitions
	transition_matrix = [
		[0.6, 0.3, 0.1],  # From Off
		[0.2, 0.5, 0.3],  # From Low
		[0.1, 0.4, 0.5]   # From High
	]
	
	current_state = 0  # Start off

func setup_market_model():
	"""Setup financial market model: Bull, Neutral, Bear"""
	num_states = 3
	state_names = ["Bull", "Neutral", "Bear"]
	state_colors = [Color.GREEN, Color.YELLOW, Color.RED]
	
	# Market state transitions
	transition_matrix = [
		[0.6, 0.3, 0.1],  # From Bull
		[0.25, 0.5, 0.25], # From Neutral
		[0.1, 0.3, 0.6]   # From Bear
	]
	
	current_state = 1  # Start neutral

func setup_visualization():
	"""Create visualization elements"""
	# State display (circular arrangement)
	state_display = Node3D.new()
	add_child(state_display)
	create_state_nodes()
	
	# Transition arrows display
	transition_display = Node3D.new()
	add_child(transition_display)
	create_transition_arrows()
	
	# Transition matrix display
	matrix_display = Node3D.new()
	matrix_display.position = Vector3(-3.0, 1.0, 0)
	add_child(matrix_display)
	create_matrix_visualization()
	
	# Probability chart
	probability_chart = Node3D.new()
	probability_chart.position = Vector3(3.0, 1.0, 0)
	add_child(probability_chart)
	
	# Current state indicator
	current_state_indicator = Node3D.new()
	add_child(current_state_indicator)
	update_current_state_indicator()

func create_state_nodes():
	"""Create visual nodes for each state"""
	var radius = 1.5
	
	for i in range(num_states):
		var angle = float(i) / float(num_states) * TAU
		var position = Vector3(cos(angle) * radius, sin(angle) * radius, 0)
		
		var state_node = Node3D.new()
		state_node.position = position
		state_node.name = "state_" + str(i)
		
		# State sphere
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.2
		mesh_instance.mesh = sphere_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = state_colors[i]
		material.emission = state_colors[i] * 0.3
		mesh_instance.material_override = material
		
		state_node.add_child(mesh_instance)
		
		# State label
		var label = Label3D.new()
		label.text = state_names[i]
		label.position = Vector3(0, -0.4, 0)
		label.font_size = 18
		label.modulate = state_colors[i]
		state_node.add_child(label)
		
		state_display.add_child(state_node)

func create_transition_arrows():
	"""Create arrows showing transition probabilities"""
	for i in range(num_states):
		for j in range(num_states):
			if i != j and transition_matrix[i][j] > 0.01:  # Only show significant transitions
				create_transition_arrow(i, j, transition_matrix[i][j])

func create_transition_arrow(from_state: int, to_state: int, probability: float):
	"""Create arrow between two states"""
	var from_node = state_display.get_child(from_state)
	var to_node = state_display.get_child(to_state)
	
	var from_pos = from_node.position
	var to_pos = to_node.position
	
	# Create arrow
	var arrow = Node3D.new()
	arrow.name = "arrow_%d_%d" % [from_state, to_state]
	
	# Arrow line
	var line_mesh = MeshInstance3D.new()
	var start_pos = from_pos + (to_pos - from_pos).normalized() * 0.2
	var end_pos = to_pos - (to_pos - from_pos).normalized() * 0.2
	create_line_mesh(line_mesh, [start_pos, end_pos], Color.WHITE)
	arrow.add_child(line_mesh)
	
	# Probability label
	var prob_label = Label3D.new()
	prob_label.text = "%.2f" % probability
	prob_label.position = (start_pos + end_pos) / 2.0 + Vector3(0, 0.1, 0)
	prob_label.font_size = 12
	arrow.add_child(prob_label)
	
	transition_display.add_child(arrow)

func create_matrix_visualization():
	"""Create visual representation of transition matrix"""
	# Clear existing
	for child in matrix_display.get_children():
		child.queue_free()
	
	# Matrix title
	var title = Label3D.new()
	title.text = "Transition Matrix"
	title.position = Vector3(0, 1.0, 0)
	title.font_size = 20
	matrix_display.add_child(title)
	
	# Matrix cells
	var cell_size = 0.3
	var start_x = -float(num_states - 1) * cell_size / 2.0
	var start_y = float(num_states - 1) * cell_size / 2.0
	
	for i in range(num_states):
		for j in range(num_states):
			var cell = Node3D.new()
			cell.position = Vector3(start_x + j * cell_size, start_y - i * cell_size, 0)
			
			# Cell background
			var cell_mesh = MeshInstance3D.new()
			var plane_mesh = PlaneMesh.new()
			plane_mesh.size = Vector2(cell_size * 0.8, cell_size * 0.8)
			cell_mesh.mesh = plane_mesh
			
			var material = StandardMaterial3D.new()
			var intensity = transition_matrix[i][j]
			material.albedo_color = Color(intensity, intensity, intensity)
			cell_mesh.material_override = material
			
			cell.add_child(cell_mesh)
			
			# Cell value
			var value_label = Label3D.new()
			value_label.text = "%.2f" % transition_matrix[i][j]
			value_label.position = Vector3(0, 0, 0.01)
			value_label.font_size = 10
			cell.add_child(value_label)
			
			matrix_display.add_child(cell)

func setup_info_display():
	"""Create information display"""
	info_display = Label3D.new()
	info_display.position = Vector3(0, 2.5, 0)
	info_display.font_size = 20
	info_display.modulate = Color.WHITE
	add_child(info_display)
	update_info_display()

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		if is_running:
			stop_simulation()
		else:
			start_simulation()
	elif button_name == "grip_click":
		step_once()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if is_running:
				stop_simulation()
			else:
				start_simulation()
		elif event.keycode == KEY_S:
			step_once()
		elif event.keycode == KEY_R:
			reset_simulation()
		elif event.keycode == KEY_T:
			change_chain_type()

func start_simulation():
	"""Start continuous simulation"""
	is_running = true
	
	if simulation_tween:
		simulation_tween.kill()
	
	simulation_tween = create_tween()
	simulation_tween.set_loops()
	
	# Continuous stepping
	for i in range(simulation_steps):
		simulation_tween.tween_callback(step_once)
		simulation_tween.tween_delay(1.0 / animation_speed)

func stop_simulation():
	"""Stop continuous simulation"""
	is_running = false
	if simulation_tween:
		simulation_tween.kill()

func step_once():
	"""Perform single simulation step"""
	# Choose next state based on transition probabilities
	var rand_val = randf()
	var cumulative_prob = 0.0
	var next_state = current_state
	
	for j in range(num_states):
		cumulative_prob += transition_matrix[current_state][j]
		if rand_val <= cumulative_prob:
			next_state = j
			break
	
	# Update state
	current_state = next_state
	state_history.append(current_state)
	
	# Update visualizations
	update_current_state_indicator()
	update_probability_chart()
	update_info_display()
	
	# Limit history size for performance
	if state_history.size() > 1000:
		state_history = state_history.slice(-500)

func update_current_state_indicator():
	"""Update visual indicator of current state"""
	# Clear existing indicator
	for child in current_state_indicator.get_children():
		child.queue_free()
	
	var state_node = state_display.get_child(current_state)
	var indicator = Node3D.new()
	indicator.position = state_node.position
	
	# Glowing ring around current state
	var ring_mesh = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.25
	torus_mesh.outer_radius = 0.3
	ring_mesh.mesh = torus_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission = Color.WHITE * 0.8
	ring_mesh.material_override = material
	
	indicator.add_child(ring_mesh)
	current_state_indicator.add_child(indicator)

func update_probability_chart():
	"""Update state probability distribution chart"""
	# Clear existing chart
	for child in probability_chart.get_children():
		child.queue_free()
	
	# Calculate empirical probabilities
	calculate_empirical_probabilities()
	
	# Create probability bars
	for i in range(num_states):
		var empirical_prob = state_probabilities[i] if i < state_probabilities.size() else 0.0
		var steady_prob = steady_state_probs[i] if show_steady_state else 0.0
		
		create_probability_bar(i, empirical_prob, steady_prob)
	
	# Add chart label
	var chart_label = Label3D.new()
	chart_label.text = "State Probabilities"
	chart_label.position = Vector3(0, -1.0, 0)
	chart_label.font_size = 18
	probability_chart.add_child(chart_label)

func calculate_empirical_probabilities():
	"""Calculate empirical state probabilities from history"""
	state_probabilities.clear()
	state_probabilities.resize(num_states)
	state_probabilities.fill(0.0)
	
	if state_history.is_empty():
		return
	
	# Count state occurrences
	for state in state_history:
		if state < num_states:
			state_probabilities[state] += 1.0
	
	# Normalize to probabilities
	var total = float(state_history.size())
	for i in range(num_states):
		state_probabilities[i] /= total

func create_probability_bar(state_index: int, empirical_prob: float, steady_prob: float):
	"""Create probability bar for a state"""
	var x_pos = (float(state_index) - float(num_states - 1) / 2.0) * 0.4
	
	# Empirical probability bar (blue)
	var emp_bar = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.15, empirical_prob * 2.0, 0.05)
	emp_bar.mesh = box_mesh
	
	var emp_material = StandardMaterial3D.new()
	emp_material.albedo_color = Color.BLUE
	emp_material.emission = Color.BLUE * 0.2
	emp_bar.material_override = emp_material
	
	emp_bar.position = Vector3(x_pos - 0.1, empirical_prob, 0)
	probability_chart.add_child(emp_bar)
	
	# Steady state probability bar (red, if shown)
	if show_steady_state and steady_prob > 0:
		var steady_bar = MeshInstance3D.new()
		var steady_box = BoxMesh.new()
		steady_box.size = Vector3(0.15, steady_prob * 2.0, 0.05)
		steady_bar.mesh = steady_box
		
		var steady_material = StandardMaterial3D.new()
		steady_material.albedo_color = Color.RED
		steady_material.emission = Color.RED * 0.2
		steady_bar.material_override = steady_material
		
		steady_bar.position = Vector3(x_pos + 0.1, steady_prob, 0)
		probability_chart.add_child(steady_bar)
	
	# State label
	var state_label = Label3D.new()
	state_label.text = state_names[state_index]
	state_label.position = Vector3(x_pos, -0.3, 0)
	state_label.font_size = 12
	state_label.modulate = state_colors[state_index]
	probability_chart.add_child(state_label)

func calculate_steady_state():
	"""Calculate steady state probabilities"""
	# Simplified calculation: solve π = πP where π is steady state
	# For demonstration, use power method approximation
	
	steady_state_probs.clear()
	steady_state_probs.resize(num_states)
	steady_state_probs.fill(1.0 / float(num_states))  # Initial uniform distribution
	
	# Power method iterations
	for iteration in range(100):
		var new_probs: Array[float] = []
		new_probs.resize(num_states)
		new_probs.fill(0.0)
		
		for i in range(num_states):
			for j in range(num_states):
				new_probs[i] += steady_state_probs[j] * transition_matrix[j][i]
		
		steady_state_probs = new_probs

func create_line_mesh(mesh_instance: MeshInstance3D, points: Array[Vector3], color: Color):
	"""Create line mesh from points"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	var indices: PackedInt32Array = []
	for i in range(points.size() - 1):
		indices.append(i)
		indices.append(i + 1)
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.3
	material.flags_unshaded = true
	mesh_instance.material_override = material

func update_info_display():
	"""Update information display"""
	var text = "Markov Chain Simulation\n"
	text += "Type: %s\n" % get_chain_type_name()
	text += "Current State: %s\n" % state_names[current_state]
	text += "Steps: %d\n\n" % state_history.size()
	
	if state_probabilities.size() == num_states:
		text += "Current Probabilities:\n"
		for i in range(num_states):
			text += "%s: %.3f\n" % [state_names[i], state_probabilities[i]]
	
	if show_steady_state:
		text += "\nSteady State:\n"
		for i in range(num_states):
			text += "%s: %.3f\n" % [state_names[i], steady_state_probs[i]]
	
	text += "\nRunning: %s" % ("Yes" if is_running else "No")
	
	info_display.text = text

func change_chain_type():
	"""Change the type of Markov chain"""
	var current_index = chain_type as int
	chain_type = ((current_index + 1) % ChainType.size()) as ChainType
	
	reset_simulation()
	initialize_chain_type()
	setup_visualization()
	calculate_steady_state()

func reset_simulation():
	"""Reset simulation to initial state"""
	stop_simulation()
	current_state = 0
	state_history.clear()
	state_probabilities.clear()
	
	# Clear visualizations
	for display in [state_display, transition_display, matrix_display, probability_chart, current_state_indicator]:
		for child in display.get_children():
			child.queue_free()
	
	update_info_display()

func get_chain_type_name() -> String:
	"""Get display name for current chain type"""
	match chain_type:
		ChainType.WEATHER_MODEL:
			return "Weather Model"
		ChainType.RANDOM_WALK:
			return "Random Walk"
		ChainType.GENE_EXPRESSION:
			return "Gene Expression"
		ChainType.MARKET_MODEL:
			return "Market Model"
		_:
			return "Unknown"

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"chain_type": get_chain_type_name(),
		"num_states": num_states,
		"current_state": current_state,
		"steps_taken": state_history.size(),
		"state_names": state_names.duplicate(),
		"empirical_probabilities": state_probabilities.duplicate(),
		"steady_state_probabilities": steady_state_probs.duplicate(),
		"transition_matrix": transition_matrix.duplicate(),
		"is_running": is_running
	}