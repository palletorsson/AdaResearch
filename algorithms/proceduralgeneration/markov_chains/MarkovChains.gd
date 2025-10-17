extends Node3D
class_name MarkovChains

var time: float = 0.0
var generation_progress: float = 0.0
var entropy_level: float = 0.0
var convergence_rate: float = 0.0
var state_count: int = 8
var sequence_length: int = 20
var current_state: int = 0
var states: Array = []
var transitions: Array = []
var probability_values: Array = []
var sequence_elements: Array = []
var transition_matrix: Array = []
var step_timer: float = 0.0
var step_interval: float = 0.8

func _ready():
	# Initialize Markov Chains visualization
	print("Markov Chains Visualization initialized")
	initialize_transition_matrix()
	create_states()
	create_transitions()
	create_probability_values()
	create_sequence_elements()
	setup_markov_metrics()

func _process(delta):
	time += delta
	step_timer += delta
	
	# Update generation step
	if step_timer >= step_interval:
		step_timer = 0.0
		advance_markov_step()
	
	# Simulate generation progress
	generation_progress = min(1.0, time * 0.1)
	entropy_level = generation_progress * 0.8
	convergence_rate = generation_progress * 0.75
	
	animate_states(delta)
	animate_transitions(delta)
	animate_generation_engine(delta)
	animate_probability_matrix(delta)
	animate_generated_sequence(delta)
	update_markov_metrics(delta)

func initialize_transition_matrix():
	# Create a random transition matrix
	transition_matrix = []
	for i in range(state_count):
		var row = []
		var total = 0.0
		
		# Generate random probabilities
		for j in range(state_count):
			var prob = randf()
			row.append(prob)
			total += prob
		
		# Normalize to ensure row sums to 1
		for j in range(state_count):
			row[j] = row[j] / total
		
		transition_matrix.append(row)

func create_states():
	# Create Markov chain states
	var states_node = $StateSpace/States
	for i in range(state_count):
		var state = CSGSphere3D.new()
		state.radius = 0.2
		state.material_override = StandardMaterial3D.new()
		
		# Different colors for different state types
		var state_type = i % 4
		match state_type:
			0:  # Starting states
				state.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			1:  # Active states
				state.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			2:  # Intermediate states
				state.material_override.albedo_color = Color(0.2, 0.2, 0.8, 1)
			3:  # Terminal states
				state.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		
		state.material_override.emission_enabled = true
		state.material_override.emission = state.material_override.albedo_color * 0.4
		
		# Position states in a circle
		var angle = float(i) / state_count * PI * 2
		var radius = 3.0
		var pos = Vector3(
			cos(angle) * radius,
			sin(angle) * radius,
			randf_range(-0.5, 0.5)
		)
		state.position = pos
		
		states_node.add_child(state)
		states.append({
			"state": state,
			"index": i,
			"position": pos,
			"visit_count": 0,
			"is_current": i == current_state
		})

func create_transitions():
	# Create transition arrows between states
	var transitions_node = $StateSpace/Transitions
	for i in range(state_count):
		for j in range(state_count):
			if i != j and transition_matrix[i][j] > 0.1:  # Only show significant transitions
				var transition = CSGBox3D.new()
				transition.size = Vector3(0.05, 0.05, 1.0)
				transition.material_override = StandardMaterial3D.new()
				
				# Color based on probability
				var prob = transition_matrix[i][j]
				var red_component = 0.8 * prob
				var green_component = 0.2 + 0.6 * (1.0 - prob)
				transition.material_override.albedo_color = Color(red_component, green_component, 0.2, 0.7)
				transition.material_override.emission_enabled = true
				transition.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.3
				transition.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				
				# Position and orient transition between states
				var from_pos = states[i]["position"]
				var to_pos = states[j]["position"]
				var center = (from_pos + to_pos) * 0.5
				var direction = to_pos - from_pos
				var length = direction.length()
				
				transition.position = center
				transition.scale.z = length * 0.8  # Slightly shorter to avoid overlap
				transition.look_at(to_pos, Vector3.UP)
				
				transitions_node.add_child(transition)
				transitions.append({
					"transition": transition,
					"from_state": i,
					"to_state": j,
					"probability": prob,
					"active": false
				})

func create_probability_values():
	# Create probability value indicators
	var probability_values_node = $ProbabilityMatrix/ProbabilityValues
	for i in range(state_count):
		for j in range(state_count):
			var prob_indicator = CSGSphere3D.new()
			prob_indicator.radius = 0.08
			prob_indicator.material_override = StandardMaterial3D.new()
			
			var prob = transition_matrix[i][j]
			var intensity = prob
			prob_indicator.material_override.albedo_color = Color(intensity, intensity, 0.2, 1)
			prob_indicator.material_override.emission_enabled = true
			prob_indicator.material_override.emission = Color(intensity, intensity, 0.2, 1) * 0.3
			
			# Position in grid formation
			var grid_size = state_count
			var x = (i - grid_size/2.0 + 0.5) * 0.4
			var y = (j - grid_size/2.0 + 0.5) * 0.4
			prob_indicator.position = Vector3(x, y, 0)
			
			probability_values_node.add_child(prob_indicator)
			probability_values.append({
				"indicator": prob_indicator,
				"from_state": i,
				"to_state": j,
				"probability": prob
			})

func create_sequence_elements():
	# Create generated sequence elements
	var sequence_elements_node = $GeneratedSequence/SequenceElements
	for i in range(sequence_length):
		var element = CSGBox3D.new()
		element.size = Vector3(0.3, 0.3, 0.3)
		element.material_override = StandardMaterial3D.new()
		element.material_override.albedo_color = Color(0.5, 0.5, 0.5, 1)
		element.material_override.emission_enabled = true
		element.material_override.emission = Color(0.5, 0.5, 0.5, 1) * 0.2
		
		# Position in sequence
		var x = (i - sequence_length/2.0 + 0.5) * 0.4
		element.position = Vector3(x, 0, 0)
		
		sequence_elements_node.add_child(element)
		sequence_elements.append({
			"element": element,
			"state_value": -1,  # -1 means not generated yet
			"generation_step": i
		})

func create_current_state_indicator():
	# Create current state indicator
	var current_state_node = $StateSpace/CurrentState
	var indicator = CSGSphere3D.new()
	indicator.radius = 0.3
	indicator.material_override = StandardMaterial3D.new()
	indicator.material_override.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	indicator.material_override.emission_enabled = true
	indicator.material_override.emission = Color(1.0, 1.0, 1.0, 1) * 0.6
	indicator.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	current_state_node.add_child(indicator)
	return indicator

func setup_markov_metrics():
	# Initialize Markov metrics
	var entropy_indicator = $MarkovMetrics/EntropyMeter/EntropyIndicator
	var convergence_indicator = $MarkovMetrics/ConvergenceMeter/ConvergenceIndicator
	if entropy_indicator:
		entropy_indicator.position.x = 0  # Start at middle
	if convergence_indicator:
		convergence_indicator.position.x = 0  # Start at middle

func advance_markov_step():
	# Advance one step in the Markov chain
	var current_row = transition_matrix[current_state]
	var random_value = randf()
	var cumulative_prob = 0.0
	var next_state = current_state
	
	# Select next state based on probabilities
	for i in range(state_count):
		cumulative_prob += current_row[i]
		if random_value <= cumulative_prob:
			next_state = i
			break
	
	# Update current state
	states[current_state]["is_current"] = false
	current_state = next_state
	states[current_state]["is_current"] = true
	states[current_state]["visit_count"] += 1
	
	# Update sequence element
	var step = 0
	for element_data in sequence_elements:
		if element_data["state_value"] == -1:
			element_data["state_value"] = current_state
			break
		step += 1
	
	# Mark active transitions
	for transition_data in transitions:
		transition_data["active"] = false
		if transition_data["to_state"] == current_state:
			transition_data["active"] = true

func animate_states(delta):
	# Animate states
	for i in range(states.size()):
		var state_data = states[i]
		var state = state_data["state"]
		
		if state:
			# Slight movement
			var base_pos = state_data["position"]
			var move_x = base_pos.x + sin(time * 0.8 + i * 0.2) * 0.1
			var move_y = base_pos.y + cos(time * 1.0 + i * 0.15) * 0.1
			var move_z = base_pos.z + sin(time * 1.2 + i * 0.1) * 0.05
			
			state.position.x = lerp(state.position.x, move_x, delta * 1.5)
			state.position.y = lerp(state.position.y, move_y, delta * 1.5)
			state.position.z = lerp(state.position.z, move_z, delta * 1.5)
			
			# Pulse based on activity
			var pulse = 1.0
			if state_data["is_current"]:
				# Current state pulses more
				pulse = 1.0 + sin(time * 4.0) * 0.4 * generation_progress
			else:
				# Other states pulse based on visit count
				var visit_intensity = min(1.0, state_data["visit_count"] * 0.1)
				pulse = 1.0 + sin(time * 2.0 + i * 0.3) * 0.2 * visit_intensity
			
			state.scale = Vector3.ONE * pulse
			
			# Change emission based on activity
			var activity = state_data["visit_count"] * 0.1 + (1.0 if state_data["is_current"] else 0.0)
			if state.material_override:
				var intensity = 0.4 + activity * 0.6
				state.material_override.emission = state.material_override.albedo_color * intensity

func animate_transitions(delta):
	# Animate transitions
	for i in range(transitions.size()):
		var transition_data = transitions[i]
		var transition = transition_data["transition"]
		
		if transition:
			# Update transition positions
			var from_pos = states[transition_data["from_state"]]["state"].position
			var to_pos = states[transition_data["to_state"]]["state"].position
			var center = (from_pos + to_pos) * 0.5
			var direction = to_pos - from_pos
			var length = direction.length()
			
			transition.position = lerp(transition.position, center, delta * 2.0)
			transition.scale.z = lerp(transition.scale.z, length * 0.8, delta * 2.0)
			if direction.length() > 0.001:
				transition.look_at(to_pos, Vector3.UP)
			
			# Animate based on activity
			if transition_data["active"]:
				# Active transition
				var pulse = 1.0 + sin(time * 5.0) * 0.4
				transition.scale.x = pulse * 0.05
				transition.scale.y = pulse * 0.05
				
				# Brighter emission
				var prob = transition_data["probability"]
				var red_component = 0.8 * prob
				var green_component = 0.2 + 0.6 * (1.0 - prob)
				transition.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.8
			else:
				# Inactive transition
				var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.1
				transition.scale.x = pulse * 0.05
				transition.scale.y = pulse * 0.05
				
				# Normal emission
				var prob = transition_data["probability"]
				var red_component = 0.8 * prob
				var green_component = 0.2 + 0.6 * (1.0 - prob)
				transition.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.3

func animate_generation_engine(delta):
	# Animate generation engine core
	var engine_core = $GenerationEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on generation progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * generation_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on generation
		if engine_core.material_override:
			var intensity = 0.3 + generation_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate chain method cores
	var text_core = $GenerationEngine/ChainMethods/TextGenerationCore
	if text_core:
		text_core.rotation.y += delta * 0.8
		var text_activation = sin(time * 1.5) * 0.5 + 0.5
		text_activation *= generation_progress
		
		var pulse = 1.0 + text_activation * 0.3
		text_core.scale = Vector3.ONE * pulse
		
		if text_core.material_override:
			var intensity = 0.3 + text_activation * 0.7
			text_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var music_core = $GenerationEngine/ChainMethods/MusicGenerationCore
	if music_core:
		music_core.rotation.y += delta * 1.0
		var music_activation = cos(time * 1.8) * 0.5 + 0.5
		music_activation *= generation_progress
		
		var pulse = 1.0 + music_activation * 0.3
		music_core.scale = Vector3.ONE * pulse
		
		if music_core.material_override:
			var intensity = 0.3 + music_activation * 0.7
			music_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var pattern_core = $GenerationEngine/ChainMethods/PatternGenerationCore
	if pattern_core:
		pattern_core.rotation.y += delta * 1.2
		var pattern_activation = sin(time * 2.0) * 0.5 + 0.5
		pattern_activation *= generation_progress
		
		var pulse = 1.0 + pattern_activation * 0.3
		pattern_core.scale = Vector3.ONE * pulse
		
		if pattern_core.material_override:
			var intensity = 0.3 + pattern_activation * 0.7
			pattern_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_probability_matrix(delta):
	# Animate probability matrix core
	var matrix_core = $ProbabilityMatrix/MatrixCore
	if matrix_core:
		# Rotate matrix
		matrix_core.rotation.y += delta * 0.3
		
		# Pulse based on generation progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * generation_progress
		matrix_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if matrix_core.material_override:
			var intensity = 0.3 + generation_progress * 0.7
			matrix_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate probability value indicators
	for i in range(probability_values.size()):
		var prob_data = probability_values[i]
		var indicator = prob_data["indicator"]
		
		if indicator:
			# Pulse based on probability value
			var prob = prob_data["probability"]
			var pulse = 1.0 + sin(time * 3.0 + i * 0.1) * 0.3 * prob * generation_progress
			indicator.scale = Vector3.ONE * pulse
			
			# Highlight if currently relevant
			var is_relevant = (prob_data["from_state"] == current_state)
			if is_relevant:
				indicator.material_override.emission = Color(prob, prob, 0.2, 1) * 0.8
			else:
				indicator.material_override.emission = Color(prob, prob, 0.2, 1) * 0.3

func animate_generated_sequence(delta):
	# Animate generated sequence core
	var sequence_core = $GeneratedSequence/SequenceCore
	if sequence_core:
		# Rotate sequence
		sequence_core.rotation.y += delta * 0.2
		
		# Pulse based on generation progress
		var pulse = 1.0 + sin(time * 2.8) * 0.1 * generation_progress
		sequence_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if sequence_core.material_override:
			var intensity = 0.3 + generation_progress * 0.7
			sequence_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate sequence elements
	for i in range(sequence_elements.size()):
		var element_data = sequence_elements[i]
		var element = element_data["element"]
		
		if element:
			if element_data["state_value"] >= 0:
				# Generated element - use state color
				var state_color = states[element_data["state_value"]]["state"].material_override.albedo_color
				element.material_override.albedo_color = state_color
				element.material_override.emission = state_color * 0.4
				
				# Pulse generated elements
				var pulse = 1.0 + sin(time * 3.5 + i * 0.2) * 0.3 * generation_progress
				element.scale = Vector3.ONE * pulse
			else:
				# Not yet generated
				element.material_override.albedo_color = Color(0.3, 0.3, 0.3, 1)
				element.material_override.emission = Color(0.3, 0.3, 0.3, 1) * 0.1
				
				# Subtle pulse for waiting elements
				var pulse = 1.0 + sin(time * 1.5 + i * 0.1) * 0.1
				element.scale = Vector3.ONE * pulse

func update_markov_metrics(delta):
	# Update entropy meter
	var entropy_indicator = $MarkovMetrics/EntropyMeter/EntropyIndicator
	if entropy_indicator:
		var target_x = lerp(-2, 2, entropy_level)
		entropy_indicator.position.x = lerp(entropy_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on entropy
		var green_component = 0.8 * entropy_level
		var red_component = 0.2 + 0.6 * (1.0 - entropy_level)
		entropy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update convergence meter
	var convergence_indicator = $MarkovMetrics/ConvergenceMeter/ConvergenceIndicator
	if convergence_indicator:
		var target_x = lerp(-2, 2, convergence_rate)
		convergence_indicator.position.x = lerp(convergence_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on convergence
		var green_component = 0.8 * convergence_rate
		var red_component = 0.2 + 0.6 * (1.0 - convergence_rate)
		convergence_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_step_interval(interval: float):
	step_interval = clamp(interval, 0.2, 3.0)

func get_current_state() -> int:
	return current_state

func get_generation_progress() -> float:
	return generation_progress

func get_entropy_level() -> float:
	return entropy_level

func get_convergence_rate() -> float:
	return convergence_rate

func reset_chain():
	current_state = 0
	time = 0.0
	step_timer = 0.0
	generation_progress = 0.0
	
	# Reset state data
	for state_data in states:
		state_data["is_current"] = (state_data["index"] == 0)
		state_data["visit_count"] = 0
	
	# Reset sequence
	for element_data in sequence_elements:
		element_data["state_value"] = -1
