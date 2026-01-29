extends Node3D
class_name MarkovChains

var time: float = 0.0
var generation_progress: float = 0.0
var entropy_level: float = 0.0
var convergence_rate: float = 0.0
var state_count: int = 5  # Reduced for clarity
var sequence_length: int = 20
var current_state: int = 0
var states: Array = []
var transitions: Array = []
var probability_values: Array = []
var sequence_elements: Array = []
var transition_matrix: Array = []
var step_timer: float = 0.0
var step_interval: float = 1.5  # Slower to see transitions

# New: For manifesting concepts
var probability_bars: Array = []  # Visual bars for dice roll
var visit_frequency: Array = []   # Track visits per state
var frequency_bars: Array = []    # Visual bars for stationary distribution
var transition_labels: Array = [] # Label3D for probabilities
var selector_indicator: Node3D = null
var is_selecting: bool = false
var selection_progress: float = 0.0
var selected_probability: float = 0.0

func _ready():
	# Initialize Markov Chains visualization
	print("Markov Chains Visualization initialized")
	initialize_transition_matrix()
	initialize_visit_frequency()
	create_states()
	create_transitions()
	create_probability_selector()  # NEW: Dice roll visualization
	create_frequency_display()     # NEW: Stationary distribution
	create_probability_values()
	create_sequence_elements()
	setup_markov_metrics()

func initialize_visit_frequency():
	visit_frequency.clear()
	for i in range(state_count):
		visit_frequency.append(0)

func _process(delta):
	time += delta
	step_timer += delta

	# Update generation step
	if step_timer >= step_interval:
		step_timer = 0.0
		advance_markov_step()

	# Handle selection animation
	if is_selecting:
		selection_progress += delta * 2.0
		if selection_progress >= 1.0:
			is_selecting = false
			if selector_indicator:
				selector_indicator.visible = false

	# Simulate generation progress
	generation_progress = min(1.0, time * 0.1)
	entropy_level = generation_progress * 0.8
	convergence_rate = generation_progress * 0.75

	animate_states(delta)
	animate_transitions(delta)
	animate_generation_engine(delta)
	animate_probability_matrix(delta)
	animate_generated_sequence(delta)
	animate_probability_selector(delta)
	update_markov_metrics(delta)

func animate_probability_selector(delta):
	# Animate the probability selection visualization
	if not is_selecting:
		return

	# Pulse the selector indicator
	if selector_indicator and selector_indicator.visible:
		var pulse = 1.0 + sin(time * 10.0) * 0.2
		selector_indicator.scale.x = pulse
		selector_indicator.scale.z = pulse

	# Animate the selected bar glowing
	for bar_data in probability_bars:
		var bar = bar_data["bar"]
		if bar.material_override.emission_energy_multiplier > 1.0:
			# Selected bar pulses
			var glow = 1.5 + sin(time * 8.0) * 0.5
			bar.material_override.emission_energy_multiplier = glow

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
	# Create Markov chain states with labels
	var states_node = $StateSpace/States

	# State names for educational value
	var state_names = ["Sunny", "Cloudy", "Rainy", "Windy", "Stormy"]

	for i in range(state_count):
		var state_container = Node3D.new()
		states_node.add_child(state_container)

		var state = CSGSphere3D.new()
		state.radius = 0.4  # Larger for VR visibility
		state.material_override = StandardMaterial3D.new()

		# Distinct colors for each state
		var colors = [
			Color(1.0, 0.8, 0.2),  # Sunny - yellow
			Color(0.6, 0.6, 0.7),  # Cloudy - gray
			Color(0.2, 0.4, 0.9),  # Rainy - blue
			Color(0.3, 0.9, 0.5),  # Windy - green
			Color(0.8, 0.2, 0.3)   # Stormy - red
		]
		state.material_override.albedo_color = colors[i % colors.size()]
		state.material_override.emission_enabled = true
		state.material_override.emission = state.material_override.albedo_color * 0.4

		# Position states in a circle
		var angle = float(i) / state_count * PI * 2
		var radius = 3.5
		var pos = Vector3(
			cos(angle) * radius,
			sin(angle) * radius * 0.5 + 1.0,  # Slight vertical spread
			0
		)
		state_container.position = pos
		state_container.add_child(state)

		# Add state label
		var label = Label3D.new()
		label.text = "S%d\n%s" % [i, state_names[i % state_names.size()]]
		label.font_size = 24
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 0.7, 0)
		label.modulate = Color(1, 1, 1, 1)
		label.outline_size = 4
		state_container.add_child(label)

		# Add current state indicator ring
		var ring = CSGTorus3D.new()
		ring.inner_radius = 0.5
		ring.outer_radius = 0.6
		ring.material_override = StandardMaterial3D.new()
		ring.material_override.albedo_color = Color(1, 1, 1, 0.8)
		ring.material_override.emission_enabled = true
		ring.material_override.emission = Color(1, 1, 1)
		ring.material_override.emission_energy_multiplier = 1.0
		ring.visible = (i == current_state)
		state_container.add_child(ring)

		states.append({
			"state": state,
			"container": state_container,
			"label": label,
			"ring": ring,
			"index": i,
			"position": pos,
			"visit_count": 0,
			"is_current": i == current_state
		})

func create_transitions():
	# Create transition arrows between states with probability labels
	var transitions_node = $StateSpace/Transitions
	for i in range(state_count):
		for j in range(state_count):
			if i != j and transition_matrix[i][j] > 0.08:  # Show more transitions
				var prob = transition_matrix[i][j]

				# Create arrow body (cylinder for better arrow look)
				var transition = CSGCylinder3D.new()
				transition.radius = 0.03 + prob * 0.05  # Thicker = higher probability
				transition.height = 1.0
				transition.material_override = StandardMaterial3D.new()

				# Color based on probability - brighter = higher
				var hue = 0.3 - prob * 0.3  # Green to red
				transition.material_override.albedo_color = Color.from_hsv(hue, 0.8, 0.7 + prob * 0.3)
				transition.material_override.emission_enabled = true
				transition.material_override.emission = Color.from_hsv(hue, 0.8, 0.5)
				transition.material_override.emission_energy_multiplier = 0.3 + prob * 0.5

				# Create arrowhead (cone)
				var arrowhead = CSGCylinder3D.new()
				arrowhead.radius = 0.1
				arrowhead.height = 0.15
				arrowhead.cone = true
				arrowhead.material_override = transition.material_override
				transition.add_child(arrowhead)
				arrowhead.position = Vector3(0, 0.5, 0)  # At end of arrow

				# Create probability label
				var label = Label3D.new()
				label.text = "%.0f%%" % (prob * 100)
				label.font_size = 24
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.modulate = Color(1, 1, 1, 0.9)
				label.outline_size = 4
				transition.add_child(label)
				label.position = Vector3(0.15, 0, 0)
				transition_labels.append(label)

				# Position and orient transition between states
				var from_pos = states[i]["position"]
				var to_pos = states[j]["position"]
				var direction = to_pos - from_pos
				var length = direction.length()
				var center = from_pos + direction.normalized() * (length * 0.5)

				transition.position = center
				transition.height = length * 0.7

				# Orient cylinder to point from->to
				if direction.length() > 0.001:
					var up = Vector3.UP
					if abs(direction.normalized().dot(up)) > 0.99:
						up = Vector3.RIGHT
					transition.look_at(to_pos, up)
					transition.rotate_object_local(Vector3.RIGHT, PI/2)

				transitions_node.add_child(transition)
				transitions.append({
					"transition": transition,
					"arrowhead": arrowhead,
					"label": label,
					"from_state": i,
					"to_state": j,
					"probability": prob,
					"active": false
				})

func create_probability_selector():
	# Create the "dice roll" visualization - shows probability bars being selected
	var selector_node = get_node_or_null("ProbabilitySelector")
	if not selector_node:
		selector_node = Node3D.new()
		selector_node.name = "ProbabilitySelector"
		add_child(selector_node)
		selector_node.position = Vector3(0, 5, 0)

	# Title label
	var title = Label3D.new()
	title.text = "TRANSITION PROBABILITIES"
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0, 1.5, 0)
	selector_node.add_child(title)

	# Create probability bars for each possible next state
	probability_bars.clear()
	var bar_width = 0.4
	var total_width = state_count * bar_width

	for i in range(state_count):
		var bar_container = Node3D.new()
		bar_container.position = Vector3((i - state_count/2.0 + 0.5) * bar_width * 1.5, 0, 0)
		selector_node.add_child(bar_container)

		# Bar background
		var bg = CSGBox3D.new()
		bg.size = Vector3(bar_width, 2.0, 0.1)
		bg.position = Vector3(0, 1.0, 0)
		var bg_mat = StandardMaterial3D.new()
		bg_mat.albedo_color = Color(0.2, 0.2, 0.2, 0.5)
		bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bg.material_override = bg_mat
		bar_container.add_child(bg)

		# Probability bar (will be scaled based on probability)
		var bar = CSGBox3D.new()
		bar.size = Vector3(bar_width * 0.8, 0.1, 0.15)
		bar.position = Vector3(0, 0.05, 0.05)
		var bar_mat = StandardMaterial3D.new()
		bar_mat.albedo_color = states[i]["state"].material_override.albedo_color if i < states.size() else Color.WHITE
		bar_mat.emission_enabled = true
		bar_mat.emission = bar_mat.albedo_color * 0.5
		bar.material_override = bar_mat
		bar_container.add_child(bar)

		# State label
		var state_label = Label3D.new()
		state_label.text = "S%d" % i
		state_label.font_size = 20
		state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		state_label.position = Vector3(0, -0.3, 0)
		bar_container.add_child(state_label)

		probability_bars.append({
			"container": bar_container,
			"bar": bar,
			"label": state_label,
			"state_index": i
		})

	# Selection indicator (shows where random value lands)
	selector_indicator = CSGBox3D.new()
	selector_indicator.size = Vector3(total_width * 1.5 + 0.5, 0.05, 0.2)
	var sel_mat = StandardMaterial3D.new()
	sel_mat.albedo_color = Color(1, 1, 0, 0.8)
	sel_mat.emission_enabled = true
	sel_mat.emission = Color(1, 1, 0)
	sel_mat.emission_energy_multiplier = 1.0
	selector_indicator.material_override = sel_mat
	selector_indicator.position = Vector3(0, 0, 0.1)
	selector_indicator.visible = false
	selector_node.add_child(selector_indicator)

func create_frequency_display():
	# Create stationary distribution visualization - bar chart of visit frequencies
	var freq_node = get_node_or_null("VisitFrequency")
	if not freq_node:
		freq_node = Node3D.new()
		freq_node.name = "VisitFrequency"
		add_child(freq_node)
		freq_node.position = Vector3(0, -8, 0)

	# Title label
	var title = Label3D.new()
	title.text = "VISIT FREQUENCY (Stationary Distribution)"
	title.font_size = 28
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0, 2.5, 0)
	freq_node.add_child(title)

	frequency_bars.clear()
	var bar_width = 0.5

	for i in range(state_count):
		var bar_container = Node3D.new()
		bar_container.position = Vector3((i - state_count/2.0 + 0.5) * bar_width * 1.5, 0, 0)
		freq_node.add_child(bar_container)

		# Frequency bar
		var bar = CSGBox3D.new()
		bar.size = Vector3(bar_width, 0.1, 0.3)
		bar.position = Vector3(0, 0.05, 0)
		var bar_mat = StandardMaterial3D.new()
		bar_mat.albedo_color = states[i]["state"].material_override.albedo_color if i < states.size() else Color.WHITE
		bar_mat.emission_enabled = true
		bar_mat.emission = bar_mat.albedo_color * 0.3
		bar.material_override = bar_mat
		bar_container.add_child(bar)

		# Percentage label
		var pct_label = Label3D.new()
		pct_label.text = "0%"
		pct_label.font_size = 18
		pct_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pct_label.position = Vector3(0, 0.3, 0)
		bar_container.add_child(pct_label)

		# State label
		var state_label = Label3D.new()
		state_label.text = "S%d" % i
		state_label.font_size = 20
		state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		state_label.position = Vector3(0, -0.3, 0)
		bar_container.add_child(state_label)

		frequency_bars.append({
			"container": bar_container,
			"bar": bar,
			"pct_label": pct_label,
			"state_index": i
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

	# Add "ONLY CURRENT STATE MATTERS" label to emphasize memoryless property
	var memoryless_label = Label3D.new()
	memoryless_label.text = "← Past fades (memoryless) | Current →"
	memoryless_label.font_size = 20
	memoryless_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	memoryless_label.position = Vector3(0, 1.0, 0)
	sequence_elements_node.add_child(memoryless_label)

	for i in range(sequence_length):
		var element = CSGBox3D.new()
		element.size = Vector3(0.3, 0.3, 0.3)
		element.material_override = StandardMaterial3D.new()
		element.material_override.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
		element.material_override.emission_enabled = true
		element.material_override.emission = Color(0.5, 0.5, 0.5, 1) * 0.1
		element.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		# Position in sequence
		var x = (i - sequence_length/2.0 + 0.5) * 0.4
		element.position = Vector3(x, 0, 0)

		sequence_elements_node.add_child(element)
		sequence_elements.append({
			"element": element,
			"state_value": -1,  # -1 means not generated yet
			"generation_step": i,
			"age": 0  # Track age for memoryless fading
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

	# Start selection animation
	is_selecting = true
	selection_progress = 0.0
	selected_probability = random_value

	# Update probability bars to show current state's transition probabilities
	update_probability_bars(current_state, random_value)

	# Select next state based on probabilities
	for i in range(state_count):
		cumulative_prob += current_row[i]
		if random_value <= cumulative_prob:
			next_state = i
			break

	# Mark which transitions are from current state
	var old_state = current_state
	for transition_data in transitions:
		transition_data["active"] = false
		if transition_data["from_state"] == old_state and transition_data["to_state"] == next_state:
			transition_data["active"] = true

	# Update current state
	states[current_state]["is_current"] = false
	current_state = next_state
	states[current_state]["is_current"] = true
	states[current_state]["visit_count"] += 1

	# Update visit frequency for stationary distribution
	visit_frequency[current_state] += 1
	update_frequency_display()

	# Update sequence element - fade older elements (memoryless property)
	var step = 0
	for element_data in sequence_elements:
		if element_data["state_value"] == -1:
			element_data["state_value"] = current_state
			element_data["age"] = 0
			break
		else:
			# Age existing elements
			element_data["age"] = element_data.get("age", 0) + 1
		step += 1

func update_probability_bars(from_state: int, random_val: float):
	# Update the probability selector to show current transition probabilities
	var current_row = transition_matrix[from_state]
	var cumulative = 0.0

	for i in range(probability_bars.size()):
		var bar_data = probability_bars[i]
		var prob = current_row[i] if i < current_row.size() else 0.0
		var bar = bar_data["bar"]

		# Scale bar height to probability
		var height = prob * 2.0
		bar.size.y = max(height, 0.05)
		bar.position.y = height / 2.0

		# Highlight the selected bar
		cumulative += prob
		var is_selected = (random_val <= cumulative and random_val > cumulative - prob)
		if is_selected:
			bar.material_override.emission_energy_multiplier = 2.0
		else:
			bar.material_override.emission_energy_multiplier = 0.3

	# Show and position selection indicator
	if selector_indicator:
		selector_indicator.visible = true
		selector_indicator.position.y = random_val * 2.0

func update_frequency_display():
	# Update the stationary distribution bar chart
	var total_visits = 0
	for v in visit_frequency:
		total_visits += v

	if total_visits == 0:
		return

	for i in range(frequency_bars.size()):
		var bar_data = frequency_bars[i]
		var visits = visit_frequency[i] if i < visit_frequency.size() else 0
		var frequency = float(visits) / total_visits
		var bar = bar_data["bar"]
		var pct_label = bar_data["pct_label"]

		# Scale bar height to frequency
		var height = frequency * 4.0  # Max height of 4 units
		bar.size.y = max(height, 0.05)
		bar.position.y = height / 2.0

		# Update percentage label
		pct_label.text = "%.1f%%" % (frequency * 100)
		pct_label.position.y = height + 0.3

func animate_states(delta):
	# Animate states
	for i in range(states.size()):
		var state_data = states[i]
		var state = state_data["state"]
		var container = state_data.get("container")
		var ring = state_data.get("ring")

		if state:
			# Pulse based on activity
			var pulse = 1.0
			if state_data["is_current"]:
				# Current state pulses strongly
				pulse = 1.2 + sin(time * 4.0) * 0.3
				# Show the ring indicator
				if ring:
					ring.visible = true
					ring.rotation.y += delta * 2.0  # Rotate ring
			else:
				# Other states pulse based on visit count
				var visit_intensity = min(1.0, state_data["visit_count"] * 0.05)
				pulse = 1.0 + sin(time * 2.0 + i * 0.3) * 0.15 * visit_intensity
				# Hide ring for non-current states
				if ring:
					ring.visible = false

			state.scale = Vector3.ONE * pulse

			# Change emission based on activity
			var activity = min(1.0, state_data["visit_count"] * 0.03)
			var current_boost = 1.5 if state_data["is_current"] else 0.0
			if state.material_override:
				var intensity = 0.3 + activity * 0.4 + current_boost
				state.material_override.emission_energy_multiplier = intensity

func animate_transitions(delta):
	# Animate transitions (arrows with probability labels)
	for i in range(transitions.size()):
		var transition_data = transitions[i]
		var transition = transition_data["transition"]
		var arrowhead = transition_data.get("arrowhead")
		var label = transition_data.get("label")

		if transition:
			# Animate based on activity - active transition glows and pulses
			if transition_data["active"]:
				# Active transition - bright glow, pulsing
				var pulse = 1.0 + sin(time * 6.0) * 0.5
				transition.scale = Vector3(pulse, pulse, 1.0)

				# Bright emission
				if transition.material_override:
					transition.material_override.emission_energy_multiplier = 2.0 + sin(time * 8.0) * 0.5

				# Show label prominently
				if label:
					label.modulate = Color(1, 1, 0, 1)  # Yellow highlight

				# Pulse arrowhead
				if arrowhead:
					arrowhead.scale = Vector3.ONE * (1.0 + sin(time * 6.0) * 0.3)
			else:
				# Inactive transition - subtle
				transition.scale = Vector3.ONE

				if transition.material_override:
					transition.material_override.emission_energy_multiplier = 0.3

				# Dim label
				if label:
					label.modulate = Color(1, 1, 1, 0.6)

				if arrowhead:
					arrowhead.scale = Vector3.ONE

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
		# Pulse based on generation progress
		var pulse = 1.0 + sin(time * 2.8) * 0.1 * generation_progress
		sequence_core.scale = Vector3.ONE * pulse

		# Change emission intensity
		if sequence_core.material_override:
			var intensity = 0.3 + generation_progress * 0.7
			sequence_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

	# Animate sequence elements - MEMORYLESS PROPERTY: fade older elements
	for i in range(sequence_elements.size()):
		var element_data = sequence_elements[i]
		var element = element_data["element"]

		if element:
			if element_data["state_value"] >= 0:
				# Generated element - use state color
				var state_idx = element_data["state_value"]
				if state_idx < states.size():
					var state_color = states[state_idx]["state"].material_override.albedo_color

					# MEMORYLESS: Fade based on age - older = more faded
					var age = element_data.get("age", 0)
					var fade = max(0.2, 1.0 - age * 0.15)  # Fade older elements

					# Most recent element is bright, older fade away
					element.material_override.albedo_color = state_color * fade
					element.material_override.emission = state_color * fade * 0.4
					element.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					element.material_override.albedo_color.a = fade

					# Only the most recent pulses strongly
					var pulse_strength = 0.1 if age > 0 else 0.4
					var pulse = 1.0 + sin(time * 3.5 + i * 0.2) * pulse_strength
					element.scale = Vector3.ONE * pulse * fade

					# Visual indicator: only current matters
					if age == 0:
						# Current element - highlight strongly
						element.scale = Vector3.ONE * 1.3
			else:
				# Not yet generated - dim and waiting
				element.material_override.albedo_color = Color(0.3, 0.3, 0.3, 0.3)
				element.material_override.emission = Color(0.3, 0.3, 0.3, 1) * 0.05
				element.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

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
	is_selecting = false
	selection_progress = 0.0

	# Reset state data
	for state_data in states:
		state_data["is_current"] = (state_data["index"] == 0)
		state_data["visit_count"] = 0

	# Reset visit frequency
	for i in range(visit_frequency.size()):
		visit_frequency[i] = 0
	update_frequency_display()

	# Reset sequence
	for element_data in sequence_elements:
		element_data["state_value"] = -1
		element_data["age"] = 0

	# Hide selector
	if selector_indicator:
		selector_indicator.visible = false
