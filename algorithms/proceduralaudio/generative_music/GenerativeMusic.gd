extends Node3D

# Generative Music Algorithms
# Demonstrates algorithmic composition techniques

var time := 0.0
var note_timer := 0.0
var beat_timer := 0.0

# Musical parameters
var current_scale := [0, 2, 4, 5, 7, 9, 11]  # C major scale
var current_key := 60  # Middle C
var tempo := 120.0  # BPM
var beat_duration: float

# Markov chain for melody generation
var markov_chain := {}
var current_note := 0
var note_history := []

# Cellular automata for rhythm
var rhythm_cells := []
var rhythm_generations := []

# Fractal melody state
var fractal_iteration := 0
var fractal_seed := [0, 2, 4, 2]

func _ready():
	beat_duration = 60.0 / tempo
	initialize_markov_chain()
	initialize_rhythm_ca()
	initialize_fractal_system()

func _process(delta):
	time += delta
	note_timer += delta
	beat_timer += delta
	
	update_algorithmic_composer()
	animate_markov_chain()
	animate_cellular_automata()
	generate_fractal_melodies()

func initialize_markov_chain():
	# Create transition probabilities for notes
	markov_chain = {
		0: {2: 0.4, 4: 0.3, 7: 0.3},  # Tonic to other notes
		2: {0: 0.3, 4: 0.4, 5: 0.3},  # Supertonic transitions
		4: {2: 0.3, 5: 0.4, 7: 0.3},  # Mediant transitions
		5: {4: 0.4, 7: 0.3, 9: 0.3},  # Subdominant transitions
		7: {0: 0.4, 5: 0.3, 9: 0.3},  # Dominant transitions
		9: {7: 0.4, 11: 0.3, 0: 0.3}, # Submediant transitions
		11: {0: 0.5, 9: 0.3, 7: 0.2}  # Leading tone transitions
	}
	current_note = 0
	note_history = [0]

func initialize_rhythm_ca():
	# Initialize 1D cellular automaton for rhythm generation
	rhythm_cells.resize(16)
	for i in range(rhythm_cells.size()):
		rhythm_cells[i] = randi() % 2  # Random initial state
	
	rhythm_generations = [rhythm_cells.duplicate()]

func initialize_fractal_system():
	fractal_iteration = 0

func update_algorithmic_composer():
	var container = $AlgorithmicComposer
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show different composition algorithms
	var algorithms = ["Markov", "Cellular", "Fractal", "Stochastic"]
	
	for i in range(algorithms.size()):
		var algo_sphere = CSGSphere3D.new()
		algo_sphere.radius = 0.5 + sin(time * 2 + i) * 0.2
		algo_sphere.position = Vector3(
			cos(time + i * TAU / algorithms.size()) * 3,
			sin(time * 0.7 + i * TAU / algorithms.size()) * 1.5,
			sin(time * 0.5 + i) * 1
		)
		
		var material = StandardMaterial3D.new()
		var hue = float(i) / algorithms.size()
		material.albedo_color = Color.from_hsv(hue, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(hue, 0.8, 1.0) * 0.5
		algo_sphere.material_override = material
		
		container.add_child(algo_sphere)
		
		# Show connections between algorithms
		if i > 0:
			var connection = create_connection(
				container.get_child(i-1).position,
				algo_sphere.position
			)
			container.add_child(connection)

func animate_markov_chain():
	var container = $MarkovChain
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Generate next note based on Markov chain
	if note_timer > beat_duration / 2:
		note_timer = 0.0
		generate_next_markov_note()
	
	# Visualize scale degrees
	for i in range(current_scale.size()):
		var note_degree = current_scale[i]
		var note_sphere = CSGSphere3D.new()
		
		# Size based on probability of being current note
		if note_degree == current_note:
			note_sphere.radius = 0.4
		else:
			note_sphere.radius = 0.2
		
		var angle = float(i) / current_scale.size() * TAU
		note_sphere.position = Vector3(
			cos(angle) * 2.5,
			sin(angle) * 2.5,
			sin(time + i) * 0.3
		)
		
		var material = StandardMaterial3D.new()
		if note_degree == current_note:
			material.albedo_color = Color(1.0, 0.2, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.2, 0.2) * 0.8
		else:
			var probability = get_transition_probability(current_note, note_degree)
			material.albedo_color = Color(0.3 + probability * 0.7, 0.7, 1.0)
			material.emission_enabled = true
			material.emission = Color(0.3 + probability * 0.7, 0.7, 1.0) * 0.3
		
		note_sphere.material_override = material
		container.add_child(note_sphere)
	
	# Show transition probabilities as connections
	for i in range(current_scale.size()):
		for j in range(current_scale.size()):
			if i != j:
				var from_note = current_scale[i]
				var to_note = current_scale[j]
				var probability = get_transition_probability(from_note, to_note)
				
				if probability > 0.0:
					var from_pos = container.get_child(i).position
					var to_pos = container.get_child(j).position
					var connection = create_weighted_connection(from_pos, to_pos, probability)
					container.add_child(connection)

func generate_next_markov_note():
	if current_note in markov_chain:
		var transitions = markov_chain[current_note]
		var random_value = randf()
		var cumulative_prob = 0.0
		
		for next_note in transitions:
			cumulative_prob += transitions[next_note]
			if random_value <= cumulative_prob:
				current_note = next_note
				note_history.append(current_note)
				if note_history.size() > 10:
					note_history.remove_at(0)
				break

func get_transition_probability(from_note: int, to_note: int) -> float:
	if from_note in markov_chain and to_note in markov_chain[from_note]:
		return markov_chain[from_note][to_note]
	return 0.0

func animate_cellular_automata():
	var container = $CellularAutomata
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update cellular automaton
	if beat_timer > beat_duration:
		beat_timer = 0.0
		update_rhythm_ca()
	
	# Visualize current generation
	for i in range(rhythm_cells.size()):
		var cell_cube = CSGBox3D.new()
		cell_cube.size = Vector3(0.4, 0.4, 0.4)
		cell_cube.position = Vector3(i * 0.5 - rhythm_cells.size() * 0.25, 0, 0)
		
		var material = StandardMaterial3D.new()
		if rhythm_cells[i] == 1:
			material.albedo_color = Color(1.0, 1.0, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 0.2) * 0.8
		else:
			material.albedo_color = Color(0.3, 0.3, 0.3)
		
		cell_cube.material_override = material
		container.add_child(cell_cube)
	
	# Show previous generations
	var max_generations = min(8, rhythm_generations.size())
	for gen in range(max_generations):
		var generation = rhythm_generations[rhythm_generations.size() - 1 - gen]
		
		for i in range(generation.size()):
			if generation[i] == 1:
				var history_cube = CSGBox3D.new()
				history_cube.size = Vector3(0.2, 0.2, 0.2)
				history_cube.position = Vector3(
					i * 0.5 - generation.size() * 0.25,
					-gen * 0.6 - 1,
					0
				)
				
				var material = StandardMaterial3D.new()
				var alpha = 1.0 - float(gen) / max_generations
				material.albedo_color = Color(1.0, 0.5, 0.0, alpha * 0.7)
				material.flags_transparent = true
				history_cube.material_override = material
				
				container.add_child(history_cube)

func update_rhythm_ca():
	var new_generation = []
	
	for i in range(rhythm_cells.size()):
		var left = rhythm_cells[(i - 1 + rhythm_cells.size()) % rhythm_cells.size()]
		var center = rhythm_cells[i]
		var right = rhythm_cells[(i + 1) % rhythm_cells.size()]
		
		# FIXED: Rule 30 for rhythm generation - ensure all operands are int
		var next_state = left ^ (center | right)  # Use bitwise OR (|) instead of logical OR (or)
		new_generation.append(next_state)  # No need for int() conversion since result is already int
	
	rhythm_cells = new_generation
	rhythm_generations.append(rhythm_cells.duplicate())
	
	# Keep only recent generations
	if rhythm_generations.size() > 16:
		rhythm_generations.remove_at(0)

func generate_fractal_melodies():
	var container = $FractalMelodies
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update fractal iteration
	if int(time * 0.5) % 4 == 0 and int(time * 0.5) != fractal_iteration:
		fractal_iteration = int(time * 0.5)
	
	# Generate fractal melody using L-system rules
	var current_melody = generate_fractal_sequence(fractal_iteration % 4)
	
	# Visualize fractal melody
	for i in range(current_melody.size()):
		var note_value = current_melody[i]
		var note_cube = CSGBox3D.new()
		note_cube.size = Vector3(0.3, abs(note_value) * 0.1 + 0.2, 0.3)
		note_cube.position = Vector3(
			i * 0.4 - current_melody.size() * 0.2,
			note_value * 0.3,
			0
		)
		
		var material = StandardMaterial3D.new()
		var note_color = float(note_value + 12) / 24.0  # Normalize to 0-1
		material.albedo_color = Color.from_hsv(note_color * 0.8, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(note_color * 0.8, 0.8, 1.0) * 0.4
		note_cube.material_override = material
		
		container.add_child(note_cube)
		
		# Connect notes with lines
		if i > 0:
			var prev_pos = container.get_child(i-1).position
			var curr_pos = note_cube.position
			var connection = create_connection(prev_pos, curr_pos)
			container.add_child(connection)

func generate_fractal_sequence(iteration: int) -> Array:
	var sequence = fractal_seed.duplicate()
	
	# Apply fractal transformation rules
	for iter in range(iteration):
		var new_sequence = []
		
		for note in sequence:
			# L-system rules for melody generation
			match note:
				0:  # Tonic expands to I-V-vi
					new_sequence.append_array([0, 7, 9])
				2:  # Supertonic expands to ii-V
					new_sequence.append_array([2, 7])
				4:  # Mediant expands to iii-vi
					new_sequence.append_array([4, 9])
				5:  # Subdominant expands to IV-I
					new_sequence.append_array([5, 0])
				7:  # Dominant expands to V-I
					new_sequence.append_array([7, 0])
				9:  # Submediant expands to vi-ii-V
					new_sequence.append_array([9, 2, 7])
				11: # Leading tone expands to vii-I
					new_sequence.append_array([11, 0])
				_:
					new_sequence.append(note)
		
		sequence = new_sequence
		
		# Limit sequence length
		if sequence.size() > 32:
			sequence = sequence.slice(0, 32)
	
	return sequence

func create_connection(from: Vector3, to: Vector3) -> CSGCylinder3D:
	var connection = CSGCylinder3D.new()
	connection.radius = 0.02
	
	connection.height = from.distance_to(to)
	
	connection.position = (from + to) * 0.5
	connection.look_at(to, Vector3.UP)
	connection.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.6)
	material.flags_transparent = true
	connection.material_override = material
	
	return connection

func create_weighted_connection(from: Vector3, to: Vector3, weight: float) -> CSGCylinder3D:
	var connection = create_connection(from, to)
	connection.radius = weight * 0.1* 0.1
	
	var material = connection.material_override as StandardMaterial3D
	material.albedo_color = Color(1.0, weight, 0.0, weight)
	material.emission_enabled = true
	material.emission = Color(1.0, weight, 0.0) * weight * 0.5
	
	return connection
