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

# Audio synthesis
var sample_rate := 44100.0
var audio_stream: AudioStreamGenerator
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_buffer_size := 512
var active_notes := []
var audio_pad_phase := 0.0
var audio_pad_frequency := 140.0
var wave_mix := [0.6, 0.3, 0.1]
var vibrato_phase := 0.0
var vibrato_rate := 5.0
var vibrato_depth := 0.0
var pan_spread := 0.3
var global_gain := 0.6
var theme_noise := 0.02
var bass_interval := -12
var bass_probability := 0.4
var note_decay := 0.995
var theme_sequence := ["queer", "sci_fi", "cyberpunk", "epic"]
var current_theme_index := 0
var current_theme := ""
var theme_cycle_duration := 24.0
var theme_timer := 0.0
var current_theme_profile := {}
var theme_profiles := {
	"queer": {
		"scale": [0, 3, 5, 7, 10],
		"tempo": 112.0,
		"key": 60,
		"wave_mix": [0.6, 0.3, 0.15],
		"vibrato_depth": 0.012,
		"vibrato_rate": 4.5,
		"pan_spread": 0.5,
		"global_gain": 0.65,
		"bass_interval": -12,
		"bass_probability": 0.55,
		"note_decay": 0.996,
		"pad_freq": 190.0,
		"noise": 0.02,
		"accent_prob": 0.4
	},
	"sci_fi": {
		"scale": [0, 2, 3, 6, 8, 11],
		"tempo": 128.0,
		"key": 62,
		"wave_mix": [0.4, 0.4, 0.2],
		"vibrato_depth": 0.008,
		"vibrato_rate": 6.0,
		"pan_spread": 0.35,
		"global_gain": 0.6,
		"bass_interval": -12,
		"bass_probability": 0.4,
		"note_decay": 0.993,
		"pad_freq": 240.0,
		"noise": 0.03,
		"accent_prob": 0.25
	},
	"cyberpunk": {
		"scale": [0, 1, 3, 5, 7, 10],
		"tempo": 132.0,
		"key": 57,
		"wave_mix": [0.3, 0.45, 0.25],
		"vibrato_depth": 0.01,
		"vibrato_rate": 5.5,
		"pan_spread": 0.6,
		"global_gain": 0.7,
		"bass_interval": -12,
		"bass_probability": 0.65,
		"note_decay": 0.99,
		"pad_freq": 120.0,
		"noise": 0.04,
		"accent_prob": 0.5
	},
	"epic": {
		"scale": [0, 2, 4, 5, 7, 9, 11],
		"tempo": 96.0,
		"key": 55,
		"wave_mix": [0.55, 0.25, 0.2],
		"vibrato_depth": 0.009,
		"vibrato_rate": 3.8,
		"pan_spread": 0.4,
		"global_gain": 0.68,
		"bass_interval": -12,
		"bass_probability": 0.5,
		"note_decay": 0.997,
		"pad_freq": 170.0,
		"noise": 0.015,
		"accent_prob": 0.3
	}
}

# Cellular automata for rhythm
var rhythm_cells := []
var rhythm_generations := []

# Fractal melody state
var fractal_iteration := 0
var fractal_seed := [0, 2, 4, 2]

func _ready() -> void:
	randomize()
	setup_audio_synthesis()
	apply_theme_profile(theme_sequence[0])
	initialize_rhythm_ca()
	initialize_fractal_system()

func _process(delta: float) -> void:
	time += delta
	note_timer += delta
	beat_timer += delta
	
	update_algorithmic_composer()
	animate_markov_chain()
	animate_cellular_automata()
	generate_fractal_melodies()
	update_theme_cycle(delta)
	generate_audio_samples()

func initialize_markov_chain() -> void:
	markov_chain = {}
	if current_scale.is_empty():
		current_scale = [0, 2, 4, 5, 7, 9, 11]

	for i in range(current_scale.size()):
		var degree = current_scale[i]
		var transitions := {}
		for offset in [-2, -1, 1, 2]:
			var idx = i + offset
			if idx >= 0 and idx < current_scale.size():
				var target = current_scale[idx]
				transitions[target] = transitions.get(target, 0.0) + 1.0
		if transitions.is_empty():
			transitions[degree] = 1.0

		var total := 0.0
		for value in transitions.values():
			total += value
		for key in transitions.keys():
			transitions[key] = transitions[key] / total
		markov_chain[degree] = transitions

	current_note = current_scale[0]
	note_history = [current_note]

func initialize_rhythm_ca() -> void:
	# Initialize 1D cellular automaton for rhythm generation
	rhythm_cells.resize(16)
	for i in range(rhythm_cells.size()):
		rhythm_cells[i] = randi() % 2  # Random initial state
	
	rhythm_generations = [rhythm_cells.duplicate()]

func initialize_fractal_system() -> void:
	fractal_iteration = 0

func update_algorithmic_composer() -> void:
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

func animate_markov_chain() -> void:
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

func generate_next_markov_note() -> void:
	if not markov_chain.has(current_note):
		return

	var transitions: Dictionary = markov_chain[current_note]
	if transitions.is_empty():
		return

	var random_value = randf()
	var cumulative = 0.0

	for next_note in transitions.keys():
		cumulative += transitions[next_note]
		if random_value <= cumulative:
			current_note = next_note
			note_history.append(current_note)
			if note_history.size() > 10:
				note_history.remove_at(0)
			var accent = 1.0
			if not current_theme_profile.is_empty():
				var accent_prob = current_theme_profile.get("accent_prob", 0.3)
				accent = 1.2 if randf() < accent_prob else 0.9
			trigger_audio_note(current_note, accent)
			break

func get_transition_probability(from_note: int, to_note: int) -> float:
	if from_note in markov_chain and to_note in markov_chain[from_note]:
		return markov_chain[from_note][to_note]
	return 0.0

func animate_cellular_automata() -> void:
	var container = $CellularAutomata
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update cellular automaton
	if beat_timer > beat_duration:
		beat_timer = 0.0
		update_rhythm_ca()
		if current_theme_profile.is_empty():
			trigger_bass_note()
		else:
			if rhythm_cells[0] == 1 or randf() < bass_probability:
				trigger_bass_note()
	
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

func update_rhythm_ca() -> void:
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

func generate_fractal_melodies() -> void:
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
	connection.look_at_from_position(connection.position, to, Vector3.UP)
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

func setup_audio_synthesis() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.2

	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -6.0
	add_child(audio_player)
	audio_player.play()

	audio_playback = audio_player.get_stream_playback()
	reset_audio_state()

func ensure_playback() -> bool:
	if audio_playback:
		return true
	if not audio_player:
		return false
	audio_playback = audio_player.get_stream_playback()
	return audio_playback != null

func reset_audio_state() -> void:
	active_notes.clear()
	audio_pad_phase = 0.0
	vibrato_phase = 0.0

func apply_theme_profile(theme_name: String) -> void:
	if not theme_profiles.has(theme_name):
		return

	current_theme = theme_name
	current_theme_index = theme_sequence.find(theme_name)
	if current_theme_index == -1:
		current_theme_index = 0

	current_theme_profile = theme_profiles[theme_name]
	current_scale = current_theme_profile.get("scale", current_scale)
	current_key = current_theme_profile.get("key", current_key)
	tempo = current_theme_profile.get("tempo", tempo)
	beat_duration = 60.0 / tempo
	wave_mix = current_theme_profile.get("wave_mix", wave_mix)
	vibrato_depth = current_theme_profile.get("vibrato_depth", vibrato_depth)
	vibrato_rate = current_theme_profile.get("vibrato_rate", vibrato_rate)
	pan_spread = current_theme_profile.get("pan_spread", pan_spread)
	global_gain = current_theme_profile.get("global_gain", global_gain)
	bass_interval = current_theme_profile.get("bass_interval", bass_interval)
	bass_probability = current_theme_profile.get("bass_probability", bass_probability)
	note_decay = current_theme_profile.get("note_decay", note_decay)
	audio_pad_frequency = current_theme_profile.get("pad_freq", audio_pad_frequency)
	theme_noise = current_theme_profile.get("noise", theme_noise)
	note_timer = 0.0
	beat_timer = 0.0
	reset_audio_state()
	initialize_markov_chain()
	theme_timer = 0.0
	print("GenerativeMusic: activated %s theme" % theme_name)

func update_theme_cycle(delta: float) -> void:
	theme_timer += delta
	if theme_timer >= theme_cycle_duration:
		theme_timer = 0.0
		advance_theme()

func advance_theme() -> void:
	current_theme_index = (current_theme_index + 1) % theme_sequence.size()
	apply_theme_profile(theme_sequence[current_theme_index])

func trigger_audio_note(scale_degree: int, accent := 1.0) -> void:
	if current_scale.is_empty():
		return
	var midi_note = current_key + scale_degree
	var freq = midi_to_freq(midi_note)
	var note = {
		"phase": 0.0,
		"freq": freq,
		"velocity": accent,
		"envelope": 1.0,
		"decay": note_decay,
		"pan": clamp(randf_range(-pan_spread, pan_spread), -1.0, 1.0),
		"type": "lead"
	}
	active_notes.append(note)

func trigger_bass_note() -> void:
	var root_degree = current_scale[0] if current_scale.size() > 0 else 0
	var midi_note = current_key + root_degree + bass_interval
	var note = {
		"phase": 0.0,
		"freq": midi_to_freq(midi_note),
		"velocity": 0.8,
		"envelope": 1.0,
		"decay": pow(note_decay, 0.6),
		"pan": 0.0,
		"type": "bass"
	}
	active_notes.append(note)

func generate_audio_samples() -> void:
	if not audio_player or not audio_player.playing:
		return
	if not ensure_playback():
		return

	var available = audio_playback.get_frames_available()
	if available < audio_buffer_size:
		return

	var frames = min(audio_buffer_size, available)

	for _i in range(frames):
		vibrato_phase = wrapf(vibrato_phase + vibrato_rate * TAU / sample_rate, 0.0, TAU)
		var vibrato = sin(vibrato_phase) * vibrato_depth
		var left = 0.0
		var right = 0.0
		var idx = 0
		while idx < active_notes.size():
			var note = active_notes[idx]
			var freq = note.freq * (1.0 + vibrato)
			note.phase = wrapf(note.phase + freq * TAU / sample_rate, 0.0, TAU)
			var wave = generate_wave_sample(note.phase, note.type)
			var sample = wave * note.envelope * note.velocity
			left += sample * (1.0 - note.pan)
			right += sample * (1.0 + note.pan)
			note.envelope *= note.decay
			if note.envelope < 0.001:
				active_notes.remove_at(idx)
				continue
			active_notes[idx] = note
			idx += 1

		audio_pad_phase = wrapf(audio_pad_phase + audio_pad_frequency * TAU / sample_rate, 0.0, TAU)
		var pad = sin(audio_pad_phase) * 0.15
		var shimmer = sin(audio_pad_phase * 0.5 + time * 0.5) * 0.1
		var noise = randf_range(-1.0, 1.0) * theme_noise * 0.2
		var left_sample = clamp((left + pad + shimmer + noise) * global_gain, -1.0, 1.0)
		var right_sample = clamp((right + pad - shimmer + noise) * global_gain, -1.0, 1.0)
		audio_playback.push_frame(Vector2(left_sample, right_sample))

func generate_wave_sample(phase: float, note_type: String) -> float:
	var sine = sin(phase)
	var saw = 2.0 * (phase / TAU - floor(phase / TAU + 0.5))
	var triangle = (2.0 / PI) * asin(sine)
	var square = 1.0 if sine >= 0.0 else -1.0
	var base = wave_mix[0] * sine + wave_mix[1] * saw + wave_mix[2] * triangle
	match note_type:
		"bass":
			return 0.7 * sine + 0.3 * square
		"pad":
			return 0.6 * triangle + 0.4 * sine
		_:
			return base

func midi_to_freq(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

