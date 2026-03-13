extends Node3D

var time = 0.0
var harmonic_count = 16
var fundamental_freq = 220.0
var harmonic_oscillators = []
var summation_nodes = []
var output_waveform = []
var waveform_resolution = 64

# Audio generation
var audio_player: AudioStreamPlayer
var audio_stream: AudioStreamGenerator
var audio_phase: Array = []  # Phase for each harmonic
var sample_rate: float = 44100.0
var audio_buffer_size: int = 1024
var theme_sequence := ["queer", "sci_fi", "cyberpunk", "epic"]
var current_theme_index := 0
var current_theme := "queer"
var theme_cycle_duration := 14.0
var theme_timer := 0.0
var current_theme_profile := {}
var target_fundamental := 220.0
var audio_vibrato_depth := 0.0
var audio_vibrato_rate := 0.4
var vibrato_phase := 0.0
var harmonic_randomness := 0.0
var shimmer_mix := 0.0
var theme_profiles := {
	"queer": {
		"fundamental": 196.0,
		"series": "triangle",
		"sweep": 60.0,
		"sweep_rate": 0.35,
		"vibrato_depth": 0.013,
		"vibrato_rate": 0.7,
		"detune": 0.004,
		"shimmer": 0.35,
		"amplitude_map": {3: 1.2, 4: 0.8, 5: 1.15, 7: 1.1}
	},
	"sci_fi": {
		"fundamental": 310.0,
		"series": "harmonic",
		"sweep": 80.0,
		"sweep_rate": 0.42,
		"vibrato_depth": 0.008,
		"vibrato_rate": 0.6,
		"detune": 0.0025,
		"shimmer": 0.25,
		"amplitude_map": {2: 1.1, 4: 1.05, 6: 0.9, 8: 0.8}
	},
	"cyberpunk": {
		"fundamental": 140.0,
		"series": "sawtooth",
		"sweep": 90.0,
		"sweep_rate": 0.28,
		"vibrato_depth": 0.015,
		"vibrato_rate": 0.5,
		"detune": 0.006,
		"shimmer": 0.2,
		"amplitude_map": {1: 1.1, 2: 1.0, 3: 0.95, 5: 0.85, 7: 0.8}
	},
	"epic": {
		"fundamental": 260.0,
		"series": "square",
		"sweep": 70.0,
		"sweep_rate": 0.3,
		"vibrato_depth": 0.01,
		"vibrato_rate": 0.55,
		"detune": 0.003,
		"shimmer": 0.3,
		"amplitude_map": {1: 1.0, 3: 1.1, 5: 1.05, 7: 0.9}
	}
}


func _ready() -> void:
	randomize()
	create_harmonic_oscillators()
	create_summation_stage()
	create_output_waveform()
	setup_materials()
	setup_audio_synthesis()
	apply_theme_profile(theme_sequence[0])

func setup_audio_synthesis() -> void:
	# Create audio stream for real-time synthesis
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.1  # 100ms buffer
	
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = 0.0  # Set audible volume
	add_child(audio_player)
	audio_player.play()
	
	# Initialize phase tracking for each harmonic
	audio_phase.resize(harmonic_count)
	for i in range(harmonic_count):
		audio_phase[i] = 0.0
	
	# Connect to audio generation callback
	print("AdditiveSynthesis: Audio synthesis enabled - %d harmonics at %.1f Hz" % [harmonic_count, fundamental_freq])

func create_harmonic_oscillators() -> void:
	var osc_parent = $HarmonicOscillators
	
	for i in range(harmonic_count):
		var harmonic_group = Node3D.new()
		osc_parent.add_child(harmonic_group)
		
		# Oscillator sphere
		var oscillator = CSGSphere3D.new()
		oscillator.radius = 0.15
		oscillator.position = Vector3(
			-7 + i * 0.9,
			2,
			0
		)
		harmonic_group.add_child(oscillator)
		
		# Amplitude control
		var amplitude_control = CSGCylinder3D.new()
		amplitude_control.radius = 0.05
		
		amplitude_control.height = 1.0
		amplitude_control.position = Vector3(
			-7 + i * 0.9,
			1,
			0
		)
		harmonic_group.add_child(amplitude_control)
		
		# Frequency indicator
		var freq_indicator = CSGBox3D.new()
		freq_indicator.size = Vector3(0.1, 0.3, 0.1)
		freq_indicator.position = Vector3(
			-7 + i * 0.9,
			2.5,
			0
		)
		harmonic_group.add_child(freq_indicator)
		
		harmonic_oscillators.append({
			"oscillator": oscillator,
			"amplitude_control": amplitude_control,
			"freq_indicator": freq_indicator,
			"harmonic_number": i + 1,
			"amplitude": calculate_initial_amplitude(i + 1),
			"phase": 0.0,
			"detune": 0.0,
			"theme_gain": 1.0
		})

func create_summation_stage() -> void:
	var sum_parent = $SummationStage
	
	# Create nodes showing the summation process
	for i in range(harmonic_count):
		var sum_node = CSGSphere3D.new()
		sum_node.radius = 0.08
		sum_node.position = Vector3(
			-7 + i * 0.9,
			0,
			0
		)
		sum_parent.add_child(sum_node)
		summation_nodes.append(sum_node)

func create_output_waveform() -> void:
	var wave_parent = $OutputWaveform
	
	for i in range(waveform_resolution):
		var wave_point = CSGSphere3D.new()
		wave_point.radius = 0.05
		wave_point.position = Vector3(
			-6 + i * 0.2,
			-2,
			0
		)
		wave_parent.add_child(wave_point)
		output_waveform.append(wave_point)

func calculate_initial_amplitude(harmonic_number: int) -> float:
	# Default to harmonic series (1/n)
	return 1.0 / harmonic_number

func setup_materials() -> void:
	# Harmonic oscillator materials
	for i in range(harmonic_oscillators.size()):
		var harmonic = harmonic_oscillators[i]
		var color_intensity = i / float(harmonic_count)
		
		# Oscillator material
		var osc_material = StandardMaterial3D.new()
		osc_material.albedo_color = Color(
			1.0 - color_intensity * 0.5,
			0.3 + color_intensity * 0.7,
			0.8,
			1.0
		)
		osc_material.emission_enabled = true
		osc_material.emission = osc_material.albedo_color * 0.4
		harmonic.oscillator.material_override = osc_material
		
		# Amplitude control material
		var amp_material = StandardMaterial3D.new()
		amp_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
		amp_material.emission_enabled = true
		amp_material.emission = Color(0.3, 0.3, 0.1, 1.0)
		harmonic.amplitude_control.material_override = amp_material
		
		# Frequency indicator material
		var freq_material = StandardMaterial3D.new()
		freq_material.albedo_color = Color(1.0, 0.4, 0.2, 1.0)
		freq_material.emission_enabled = true
		freq_material.emission = Color(0.4, 0.1, 0.05, 1.0)
		harmonic.freq_indicator.material_override = freq_material
	
	# Summation node materials
	var sum_material = StandardMaterial3D.new()
	sum_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	sum_material.emission_enabled = true
	sum_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	
	for node in summation_nodes:
		node.material_override = sum_material
	
	# Output waveform materials
	var wave_material = StandardMaterial3D.new()
	wave_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	wave_material.emission_enabled = true
	wave_material.emission = Color(0.4, 0.3, 0.1, 1.0)
	
	for point in output_waveform:
		point.material_override = wave_material
	
	# Control materials
	var fund_material = StandardMaterial3D.new()
	fund_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	fund_material.emission_enabled = true
	fund_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$FundamentalFreq.material_override = fund_material
	
	var count_material = StandardMaterial3D.new()
	count_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	count_material.emission_enabled = true
	count_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$HarmonicCount.material_override = count_material

func _process(delta: float) -> void:
	time += delta
	
	# Update fundamental frequency based on theme
	if current_theme_profile.is_empty():
		fundamental_freq = 220.0 + sin(time * 0.3) * 100.0
	else:
		var sweep = current_theme_profile.get("sweep", 80.0)
		var sweep_rate = current_theme_profile.get("sweep_rate", 0.3)
		fundamental_freq = lerp(fundamental_freq, target_fundamental + sin(time * sweep_rate) * sweep, 0.08)
	
	animate_harmonic_oscillators()
	animate_summation()
	animate_output_waveform()
	animate_controls()
	
	# Generate audio samples
	generate_audio_samples()
	update_theme_cycle(delta)

func animate_harmonic_oscillators() -> void:
	for i in range(harmonic_oscillators.size()):
		var harmonic = harmonic_oscillators[i]
		var harmonic_freq = fundamental_freq * harmonic.harmonic_number * (1.0 + harmonic.detune)
		
		# Update phase
		harmonic.phase += harmonic_freq * 2.0 * PI * get_process_delta_time()
		
		# Calculate current amplitude with theme emphasis
		var envelope = 1.0 + sin(time * 0.5 + i * 0.2) * 0.3
		var base_amplitude = harmonic.amplitude * harmonic.theme_gain
		var current_amplitude = base_amplitude * envelope
		
		# Animate oscillator
		var osc_scale = 0.8 + current_amplitude * sin(harmonic.phase) * 0.5
		harmonic.oscillator.scale = Vector3.ONE * osc_scale
		
		# Update amplitude control height
		var amp_height = current_amplitude * 1.5 + 0.3
		harmonic.amplitude_control.height = amp_height
		harmonic.amplitude_control.position.y = 1 + amp_height/2
		
		# Update frequency indicator
		var freq_scale = 1.0 + (harmonic_freq / 2000.0) * 0.8
		harmonic.freq_indicator.scale = Vector3.ONE * freq_scale
		
		# Update materials based on activity
		var osc_material = harmonic.oscillator.material_override as StandardMaterial3D
		if osc_material:
			var intensity = (current_amplitude * sin(harmonic.phase) + 1.0) * 0.5
			osc_material.emission = osc_material.albedo_color * (0.2 + intensity * 0.8)

func animate_summation() -> void:
	# Show progressive summation
	for i in range(summation_nodes.size()):
		var sum_node = summation_nodes[i]
		
		# Calculate partial sum up to this harmonic
		var partial_sum = 0.0
		for j in range(i + 1):
			var harmonic = harmonic_oscillators[j]
			var harmonic_freq = fundamental_freq * harmonic.harmonic_number
			var envelope = 1.0 + sin(time * 0.5 + j * 0.2) * 0.3
			var base_amplitude = harmonic.amplitude * harmonic.theme_gain
			var current_amplitude = base_amplitude * envelope
			
			partial_sum += current_amplitude * sin(harmonic.phase)
		
		# Scale and position based on partial sum
		var scale = 0.5 + abs(partial_sum) * 0.8
		sum_node.scale = Vector3.ONE * scale
		sum_node.position.y = partial_sum * 0.3
		
		# Update color
		var material = sum_node.material_override as StandardMaterial3D
		if material:
			var intensity = (partial_sum + 2.0) / 4.0  # Normalize to 0-1
			material.emission = Color(
				0.05 + intensity * 0.3,
				0.3,
				0.2 + (1.0 - intensity) * 0.3,
				1.0
			)

func animate_output_waveform() -> void:
	# Generate final waveform
	for i in range(output_waveform.size()):
		var wave_point = output_waveform[i]
		var x_position = i / float(waveform_resolution)
		
		# Calculate waveform value at this position
		var waveform_value = 0.0
		for j in range(harmonic_oscillators.size()):
			var harmonic = harmonic_oscillators[j]
			var harmonic_freq = fundamental_freq * harmonic.harmonic_number
			var envelope = 1.0 + sin(time * 0.5 + j * 0.2) * 0.3
			var current_amplitude = harmonic.amplitude * harmonic.theme_gain * envelope
			
			# Phase at this position
			var position_phase = x_position * 4.0 * PI + time * harmonic_freq * 0.01
			waveform_value += current_amplitude * sin(position_phase)
		
		# Position waveform point
		wave_point.position.y = -2 + waveform_value * 0.8
		
		# Scale based on amplitude
		var scale = 0.3 + abs(waveform_value) * 0.5
		wave_point.scale = Vector3.ONE * scale
		
		# Update color
		var material = wave_point.material_override as StandardMaterial3D
		if material:
			var intensity = (waveform_value + 2.0) / 4.0
			material.albedo_color = Color(
				1.0,
				0.8 - intensity * 0.4,
				0.2 + intensity * 0.6,
				1.0
			)
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func animate_controls() -> void:
	# Fundamental frequency control
	var fund_height = (fundamental_freq / 400.0) * 1.5 + 0.5
	$FundamentalFreq.height = fund_height
	$FundamentalFreq.position.y = -3 + fund_height/2
	
	# Harmonic count indicator
	var active_harmonics = count_active_harmonics()
	var count_height = (active_harmonics / float(harmonic_count)) * 1.5 + 0.5
	$HarmonicCount.height = count_height
	$HarmonicCount.position.y = -3 + count_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$FundamentalFreq.scale.x = pulse
	$HarmonicCount.scale.x = pulse

func count_active_harmonics() -> int:
	var count = 0
	for harmonic in harmonic_oscillators:
		if harmonic.amplitude > 0.1:
			count += 1
	return count

func set_harmonic_series(series_type: String) -> void:
	# Set different harmonic series
	for i in range(harmonic_oscillators.size()):
		var harmonic = harmonic_oscillators[i]
		
		match series_type:
			"harmonic":
				harmonic.amplitude = 1.0 / harmonic.harmonic_number
			"square":
				if harmonic.harmonic_number % 2 == 1:
					harmonic.amplitude = 1.0 / harmonic.harmonic_number
				else:
					harmonic.amplitude = 0.0
			"sawtooth":
				harmonic.amplitude = 1.0 / harmonic.harmonic_number
			"triangle":
				if harmonic.harmonic_number % 2 == 1:
					harmonic.amplitude = 1.0 / (harmonic.harmonic_number * harmonic.harmonic_number)
				else:
					harmonic.amplitude = 0.0
			_:
				harmonic.amplitude = 1.0 / harmonic.harmonic_number

# ============================================================================
# Real-time audio generation
# ============================================================================

func generate_audio_samples() -> void:
	if not audio_player or not audio_player.playing:
		return

	var playback = audio_player.get_stream_playback()
	if not playback:
		return

	var frames_available = playback.get_frames_available()

	if frames_available < 512:
		return

	var frames_to_fill = min(frames_available, 512)

	for _frame in range(frames_to_fill):
		vibrato_phase = wrapf(vibrato_phase + audio_vibrato_rate * TAU / sample_rate, 0.0, TAU)
		var vibrato = sin(vibrato_phase) * audio_vibrato_depth
		var sample: float = 0.0

		for i in range(harmonic_oscillators.size()):
			var harmonic = harmonic_oscillators[i]
			var harmonic_freq = fundamental_freq * harmonic.harmonic_number * (1.0 + harmonic.detune)
			var modulated_freq = harmonic_freq * (1.0 + vibrato)
			var envelope = 1.0 + sin(time * 0.5 + i * 0.2) * 0.3
			var base_amplitude = harmonic.amplitude * harmonic.theme_gain
			var current_amplitude = base_amplitude * envelope

			audio_phase[i] += modulated_freq * 2.0 * PI / sample_rate
			if audio_phase[i] > PI * 2.0:
				audio_phase[i] -= PI * 2.0
			elif audio_phase[i] < 0.0:
				audio_phase[i] += PI * 2.0

			var harmonic_sample = sin(audio_phase[i])
			if shimmer_mix > 0.0:
				harmonic_sample += sin(audio_phase[i] * 2.0 + time * 0.8) * shimmer_mix
			sample += current_amplitude * harmonic_sample

		sample = sample / float(harmonic_count) * 0.8
		sample = clamp(sample, -1.0, 1.0)

		playback.push_frame(Vector2(sample, sample))

func apply_theme_profile(theme_name: String) -> void:
	if not theme_profiles.has(theme_name):
		return

	current_theme = theme_name
	current_theme_index = theme_sequence.find(theme_name)
	if current_theme_index == -1:
		current_theme_index = 0

	current_theme_profile = theme_profiles[theme_name]
	target_fundamental = current_theme_profile.get("fundamental", fundamental_freq)
	audio_vibrato_depth = current_theme_profile.get("vibrato_depth", audio_vibrato_depth)
	audio_vibrato_rate = current_theme_profile.get("vibrato_rate", audio_vibrato_rate)
	harmonic_randomness = current_theme_profile.get("detune", harmonic_randomness)
	shimmer_mix = current_theme_profile.get("shimmer", shimmer_mix)
	set_harmonic_series(current_theme_profile.get("series", "harmonic"))
	apply_theme_to_harmonics()
	reset_audio_phases()
	theme_timer = 0.0
	print("AdditiveSynthesis: activated %s theme" % theme_name)

func apply_theme_to_harmonics() -> void:
	var amplitude_map: Dictionary = current_theme_profile.get("amplitude_map", {})
	for harmonic in harmonic_oscillators:
		var multiplier = amplitude_map.get(harmonic.harmonic_number, 1.0)
		harmonic.theme_gain = multiplier
		harmonic.detune = randf_range(-harmonic_randomness, harmonic_randomness)

func reset_audio_phases() -> void:
	for i in range(audio_phase.size()):
		audio_phase[i] = 0.0
	vibrato_phase = 0.0

func update_theme_cycle(delta: float) -> void:
	theme_timer += delta
	if theme_timer >= theme_cycle_duration:
		theme_timer = 0.0
		advance_theme()

func advance_theme() -> void:
	current_theme_index = (current_theme_index + 1) % theme_sequence.size()
	apply_theme_profile(theme_sequence[current_theme_index])

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

