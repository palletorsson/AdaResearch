extends Node3D

var time = 0.0
var oscillator_nodes = []
var filter_nodes = []
var spectrum_nodes = []
var frequency_bands = 32
var filter_frequency = 1000.0
var filter_resonance = 0.5
var filter_timer = 0.0
var filter_interval = 3.0

# Filter types
enum FilterType {
	LOW_PASS,
	HIGH_PASS,
	BAND_PASS,
	NOTCH
}

var current_filter = FilterType.LOW_PASS

# Oscillator types
enum OscillatorType {
	SAWTOOTH,
	SQUARE,
	TRIANGLE,
	NOISE
}

var oscillator_count = 4

# Audio synthesis
var sample_rate := 44100.0
var audio_stream: AudioStreamGenerator
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_buffer_size := 512
var audio_oscillators := []
var audio_noise_amount := 0.12
var audio_gain := 0.6
var base_frequency := 110.0
var target_fundamental := 110.0
var lfo_phase := 0.0
var lfo_rate := 0.4
var lfo_depth := 0.25
var filter_drive := 0.35
var filter_lp := 0.0
var filter_bp := 0.0
var filter_hp := 0.0
var theme_sequence := ["queer", "sci_fi", "cyberpunk", "epic"]
var current_theme_index := 0
var current_theme := ""
var theme_cycle_duration := 18.0
var theme_timer := 0.0
var current_theme_profile := {}
var theme_filter_sequence := []
var theme_filter_index := 0
var theme_profiles := {
	"queer": {
		"fundamental": 196.0,
		"filter_frequency": 1200.0,
		"resonance": 0.82,
		"drive": 0.32,
		"noise": 0.16,
		"gain": 0.65,
		"lfo_rate": 0.42,
		"lfo_depth": 0.28,
		"filter_sweep": 160.0,
		"sweep_rate": 0.32,
		"sweep": 140.0,
		"filters": [FilterType.BAND_PASS, FilterType.LOW_PASS],
		"oscillators": [
			{"type": OscillatorType.SAWTOOTH, "gain": 0.55, "detune": -0.01},
			{"type": OscillatorType.TRIANGLE, "gain": 0.42, "detune": 0.012},
			{"type": OscillatorType.NOISE, "gain": 0.18, "detune": 0.0}
		]
	},
	"sci_fi": {
		"fundamental": 310.0,
		"filter_frequency": 1800.0,
		"resonance": 0.65,
		"drive": 0.25,
		"noise": 0.1,
		"gain": 0.55,
		"lfo_rate": 0.55,
		"lfo_depth": 0.18,
		"filter_sweep": 220.0,
		"sweep_rate": 0.45,
		"sweep": 200.0,
		"filters": [FilterType.HIGH_PASS, FilterType.NOTCH],
		"oscillators": [
			{"type": OscillatorType.SAWTOOTH, "gain": 0.5, "detune": 0.0},
			{"type": OscillatorType.SQUARE, "gain": 0.45, "detune": 0.015}
		]
	},
	"cyberpunk": {
		"fundamental": 140.0,
		"filter_frequency": 780.0,
		"resonance": 0.9,
		"drive": 0.55,
		"noise": 0.25,
		"gain": 0.7,
		"lfo_rate": 0.3,
		"lfo_depth": 0.35,
		"filter_sweep": 190.0,
		"sweep_rate": 0.28,
		"sweep": 160.0,
		"filters": [FilterType.LOW_PASS, FilterType.BAND_PASS],
		"oscillators": [
			{"type": OscillatorType.SAWTOOTH, "gain": 0.6, "detune": -0.018},
			{"type": OscillatorType.SQUARE, "gain": 0.5, "detune": 0.02},
			{"type": OscillatorType.NOISE, "gain": 0.22, "detune": 0.0}
		]
	},
	"epic": {
		"fundamental": 260.0,
		"filter_frequency": 1450.0,
		"resonance": 0.7,
		"drive": 0.38,
		"noise": 0.12,
		"gain": 0.62,
		"lfo_rate": 0.36,
		"lfo_depth": 0.22,
		"filter_sweep": 210.0,
		"sweep_rate": 0.3,
		"sweep": 220.0,
		"filters": [FilterType.LOW_PASS, FilterType.NOTCH, FilterType.BAND_PASS],
		"oscillators": [
			{"type": OscillatorType.SAWTOOTH, "gain": 0.52, "detune": -0.008},
			{"type": OscillatorType.TRIANGLE, "gain": 0.4, "detune": 0.01},
			{"type": OscillatorType.SQUARE, "gain": 0.28, "detune": 0.0}
		]
	}
}

func _ready():
	randomize()
	create_oscillators()
	create_filter_stage()
	create_spectrum_display()
	setup_materials()
	setup_audio_synthesis()
	apply_theme_profile(theme_sequence[0])

func create_oscillators():
	var osc_parent = $Oscillators
	
	for i in range(oscillator_count):
		var osc_group = Node3D.new()
		osc_parent.add_child(osc_group)
		
		# Create harmonics for each oscillator
		var harmonic_count = 8
		var osc_data = []
		
		for h in range(harmonic_count):
			var harmonic = CSGSphere3D.new()
			harmonic.radius = 0.1
			harmonic.position = Vector3(
				-6 + i * 3.0,
				2 - h * 0.3,
				0
			)
			osc_group.add_child(harmonic)
			osc_data.append(harmonic)
		
		oscillator_nodes.append(osc_data)

func create_filter_stage():
	var filter_parent = $FilterStage
	
	# Create filter visualization as a 3D surface
	var filter_width = 16
	var filter_height = 8
	
	for x in range(filter_width):
		filter_nodes.append([])
		for y in range(filter_height):
			var filter_node = CSGSphere3D.new()
			filter_node.radius = 0.06
			filter_node.position = Vector3(
				-6 + x * 0.75,
				0.5 - y * 0.15,
				-2
			)
			filter_parent.add_child(filter_node)
			filter_nodes[x].append(filter_node)

func create_spectrum_display():
	var spectrum_parent = $SpectrumOutput
	
	for i in range(frequency_bands):
		var band = CSGBox3D.new()
		band.size = Vector3(0.2, 0.1, 0.2)
		band.position = Vector3(
			-6 + i * 0.4,
			-1.5,
			2
		)
		spectrum_parent.add_child(band)
		spectrum_nodes.append(band)

func setup_materials():
	# Oscillator materials
	for i in range(oscillator_nodes.size()):
		var color_intensity = i / float(oscillator_count)
		var osc_material = StandardMaterial3D.new()
		osc_material.albedo_color = Color(
			1.0 - color_intensity * 0.5,
			0.3 + color_intensity * 0.7,
			0.3,
			1.0
		)
		osc_material.emission_enabled = true
		osc_material.emission = osc_material.albedo_color * 0.4
		
		for harmonic in oscillator_nodes[i]:
			harmonic.material_override = osc_material
	
	# Filter materials
	var filter_material = StandardMaterial3D.new()
	filter_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	filter_material.emission_enabled = true
	filter_material.emission = Color(0.05, 0.2, 0.3, 1.0)
	
	for row in filter_nodes:
		for node in row:
			node.material_override = filter_material
	
	# Spectrum materials
	var spectrum_material = StandardMaterial3D.new()
	spectrum_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	spectrum_material.emission_enabled = true
	spectrum_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	
	for band in spectrum_nodes:
		band.material_override = spectrum_material
	
	# Control materials
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$FilterFrequency.material_override = freq_material
	
	var res_material = StandardMaterial3D.new()
	res_material.albedo_color = Color(0.3, 1.0, 0.3, 1.0)
	res_material.emission_enabled = true
	res_material.emission = Color(0.1, 0.5, 0.1, 1.0)
	$FilterResonance.material_override = res_material
	
	var type_material = StandardMaterial3D.new()
	type_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
	type_material.emission_enabled = true
	type_material.emission = Color(0.2, 0.05, 0.3, 1.0)
	$FilterType.material_override = type_material

func _process(delta):
	time += delta
	filter_timer += delta

	if theme_filter_sequence.size() > 0 and filter_timer >= filter_interval:
		filter_timer = 0.0
		theme_filter_index = (theme_filter_index + 1) % theme_filter_sequence.size()
		current_filter = theme_filter_sequence[theme_filter_index]

	if current_theme_profile.is_empty():
		filter_frequency = 500.0 + sin(time * 0.4) * 400.0
		filter_resonance = 0.3 + cos(time * 0.3) * 0.4
	else:
		var profile: Dictionary = current_theme_profile
		lfo_rate = profile.get("lfo_rate", lfo_rate)
		lfo_depth = profile.get("lfo_depth", lfo_depth)
		target_fundamental = profile.get("fundamental", target_fundamental)
		var sweep = profile.get("sweep", 180.0)
		var sweep_rate = profile.get("sweep_rate", 0.35)
		filter_frequency = lerp(filter_frequency, profile.get("filter_frequency", filter_frequency) + sin(time * sweep_rate) * sweep, 0.08)
		filter_resonance = clamp(lerp(filter_resonance, profile.get("resonance", filter_resonance), 0.1), 0.05, 1.25)
		base_frequency = lerp(base_frequency, target_fundamental, 0.02)

	lfo_phase = wrapf(lfo_phase + lfo_rate * TAU * delta, 0.0, TAU)

	animate_oscillators()
	animate_filter()
	animate_spectrum()
	animate_controls()
	update_theme_cycle(delta)
	generate_audio_samples()

func animate_oscillators():
	# Animate each oscillator's harmonics
	for i in range(oscillator_nodes.size()):
		var osc_type = i % 4  # Cycle through oscillator types
		
		for h in range(oscillator_nodes[i].size()):
			var harmonic = oscillator_nodes[i][h]
			var harmonic_freq = (h + 1)  # Harmonic number
			
			# Calculate amplitude based on oscillator type and harmonic
			var amplitude = calculate_harmonic_amplitude(osc_type, harmonic_freq)
			
			# Animate based on amplitude and time
			var scale = 0.5 + amplitude * (1.0 + sin(time * harmonic_freq * 2.0) * 0.5)
			harmonic.scale = Vector3.ONE * scale
			
			# Update material emission
			var material = harmonic.material_override as StandardMaterial3D
			if material:
				material.emission = material.albedo_color * (0.2 + amplitude * 0.8)

func calculate_harmonic_amplitude(osc_type: int, harmonic: int) -> float:
	match osc_type:
		OscillatorType.SAWTOOTH:
			# Sawtooth: all harmonics, 1/n amplitude
			return 1.0 / harmonic
		
		OscillatorType.SQUARE:
			# Square: odd harmonics only, 1/n amplitude
			if harmonic % 2 == 1:
				return 1.0 / harmonic
			else:
				return 0.0
		
		OscillatorType.TRIANGLE:
			# Triangle: odd harmonics, 1/n² amplitude
			if harmonic % 2 == 1:
				return 1.0 / (harmonic * harmonic)
			else:
				return 0.0
		
		OscillatorType.NOISE:
			# Noise: random amplitudes
			return randf()
		
		_:
			return 0.0

func animate_filter():
	# Visualize filter response
	for x in range(filter_nodes.size()):
		for y in range(filter_nodes[x].size()):
			var node = filter_nodes[x][y]
			
			# Calculate frequency for this position
			var freq = (x / float(filter_nodes.size())) * 4000.0  # 0-4kHz range
			var amplitude_pos = y / float(filter_nodes[x].size())
			
			# Calculate filter response
			var response = calculate_filter_response(freq, amplitude_pos)
			
			# Animate based on response
			var scale = 0.3 + response * 1.5
			node.scale = Vector3.ONE * scale
			
			# Update color based on response
			var material = node.material_override as StandardMaterial3D
			if material:
				var intensity = response
				material.albedo_color = Color(
					0.2 + intensity * 0.8,
					0.8 - intensity * 0.4,
					1.0 - intensity * 0.5,
					1.0
				)
				material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func calculate_filter_response(frequency: float, amplitude_level: float) -> float:
	var normalized_freq = frequency / 2000.0  # Normalize to 0-2
	var cutoff = filter_frequency / 2000.0
	var q = filter_resonance * 10.0 + 0.5
	
	var response = 0.0
	
	match current_filter:
		FilterType.LOW_PASS:
			# Simple low-pass response
			if normalized_freq < cutoff:
				response = 1.0 - (normalized_freq / cutoff) * 0.7
			else:
				response = max(0.0, 1.0 - pow((normalized_freq - cutoff) * 2.0, 2.0))
			
			# Add resonance peak
			if abs(normalized_freq - cutoff) < 0.1:
				response += filter_resonance * 0.8
		
		FilterType.HIGH_PASS:
			# High-pass response
			if normalized_freq > cutoff:
				response = 0.3 + (normalized_freq - cutoff) * 0.7
			else:
				response = max(0.0, 0.3 - (cutoff - normalized_freq) * 2.0)
			
			# Add resonance peak
			if abs(normalized_freq - cutoff) < 0.1:
				response += filter_resonance * 0.8
		
		FilterType.BAND_PASS:
			# Band-pass response
			var distance_from_center = abs(normalized_freq - cutoff)
			var bandwidth = 0.2 + filter_resonance * 0.3
			
			if distance_from_center < bandwidth:
				response = 1.0 - (distance_from_center / bandwidth)
			else:
				response = 0.0
		
		FilterType.NOTCH:
			# Notch response (inverse of band-pass)
			var distance_from_center = abs(normalized_freq - cutoff)
			var bandwidth = 0.15 + filter_resonance * 0.2
			
			if distance_from_center < bandwidth:
				response = distance_from_center / bandwidth
			else:
				response = 1.0
	
	return clamp(response, 0.0, 1.0)

func animate_spectrum():
	# Animate output spectrum
	for i in range(spectrum_nodes.size()):
		var band = spectrum_nodes[i]
		var frequency = (i / float(frequency_bands)) * 4000.0
		
		# Calculate final amplitude after filtering
		var base_amplitude = 0.0
		
		# Sum contributions from all oscillators
		for osc_idx in range(oscillator_count):
			for harmonic in range(8):
				var harmonic_freq = 220.0 * (osc_idx + 1) * (harmonic + 1)  # Base frequency * harmonic
				
				if abs(harmonic_freq - frequency) < 100.0:  # If this harmonic affects this frequency band
					var osc_amplitude = calculate_harmonic_amplitude(osc_idx % 4, harmonic + 1)
					base_amplitude += osc_amplitude * 0.2
		
		# Apply filter
		var filter_response = calculate_filter_response(frequency, 0.5)
		var final_amplitude = base_amplitude * filter_response
		
		# Add some dynamics
		final_amplitude *= (1.0 + sin(time * 3.0 + i * 0.2) * 0.3)
		
		# Animate spectrum bar
		var height = 0.1 + final_amplitude * 2.0
		band.size.y = height
		band.position.y = -1.5 + height/2
		
		# Update color
		var material = band.material_override as StandardMaterial3D
		if material:
			var intensity = final_amplitude
			material.albedo_color = Color(
				1.0,
				0.8 - intensity * 0.4,
				0.2 + intensity * 0.6,
				1.0
			)
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func animate_controls():
	# Filter frequency control
	var freq_height = (filter_frequency / 1000.0) * 1.5 + 0.5
	$FilterFrequency.height = freq_height
	$FilterFrequency.position.y = -3 + freq_height/2
	
	# Filter resonance control
	var res_height = filter_resonance * 1.5 + 0.5
	$FilterResonance.height = res_height
	$FilterResonance.position.y = -3 + res_height/2
	
	# Filter type indicator
	var type_height = (current_filter + 1) * 0.3 + 0.5
	$FilterType.height = type_height
	$FilterType.position.y = -3 + type_height/2
	
	# Update filter type color
	var type_material = $FilterType.material_override as StandardMaterial3D
	if type_material:
		match current_filter:
			FilterType.LOW_PASS:
				type_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
			FilterType.HIGH_PASS:
				type_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			FilterType.BAND_PASS:
				type_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
			FilterType.NOTCH:
				type_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
		
		type_material.emission = type_material.albedo_color * 0.3
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$FilterFrequency.scale.x = pulse
	$FilterResonance.scale.x = pulse
	$FilterType.scale.x = pulse

func get_filter_name() -> String:
	match current_filter:
		FilterType.LOW_PASS:
			return "Low Pass"
		FilterType.HIGH_PASS:
			return "High Pass"
		FilterType.BAND_PASS:
			return "Band Pass"
		FilterType.NOTCH:
			return "Notch"
		_:
			return "Unknown"

func setup_audio_synthesis():
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.2

	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -3.0
	add_child(audio_player)
	audio_player.play()

	audio_playback = audio_player.get_stream_playback()
	rebuild_audio_oscillators()
	reset_filter_state()

func ensure_playback() -> bool:
	if audio_playback:
		return true
	if not audio_player:
		return false
	audio_playback = audio_player.get_stream_playback()
	return audio_playback != null

func apply_theme_profile(theme_name: String):
	if not theme_profiles.has(theme_name):
		return

	current_theme = theme_name
	current_theme_index = theme_sequence.find(theme_name)
	if current_theme_index == -1:
		current_theme_index = 0

	current_theme_profile = theme_profiles[theme_name]
	base_frequency = current_theme_profile.get("fundamental", base_frequency)
	target_fundamental = base_frequency
	filter_frequency = current_theme_profile.get("filter_frequency", filter_frequency)
	filter_resonance = current_theme_profile.get("resonance", filter_resonance)
	filter_drive = current_theme_profile.get("drive", filter_drive)
	audio_noise_amount = current_theme_profile.get("noise", audio_noise_amount)
	audio_gain = current_theme_profile.get("gain", audio_gain)
	lfo_rate = current_theme_profile.get("lfo_rate", lfo_rate)
	lfo_depth = current_theme_profile.get("lfo_depth", lfo_depth)
	theme_filter_sequence = current_theme_profile.get("filters", [current_theme_profile.get("filter_type", FilterType.LOW_PASS)])
	theme_filter_index = 0
	if theme_filter_sequence.size() > 0:
		current_filter = theme_filter_sequence[0]
	reset_filter_state()
	rebuild_audio_oscillators()
	theme_timer = 0.0
	print("SubtractiveSynthesis: activated %s theme" % theme_name)

func rebuild_audio_oscillators():
	audio_oscillators.clear()
	if current_theme_profile.is_empty():
		return

	var osc_settings: Array = current_theme_profile.get("oscillators", [])
	if osc_settings.is_empty():
		osc_settings = [
			{"type": OscillatorType.SAWTOOTH, "gain": 0.6, "detune": 0.0}
		]

	for osc_data in osc_settings:
		var osc = {
			"type": osc_data.get("type", OscillatorType.SAWTOOTH),
			"gain": osc_data.get("gain", 0.5),
			"detune": osc_data.get("detune", 0.0),
			"phase": 0.0
		}
		audio_oscillators.append(osc)

func reset_filter_state():
	filter_lp = 0.0
	filter_bp = 0.0
	filter_hp = 0.0

func update_theme_cycle(delta: float):
	theme_timer += delta
	if theme_timer >= theme_cycle_duration:
		theme_timer = 0.0
		advance_theme()

func advance_theme():
	current_theme_index = (current_theme_index + 1) % theme_sequence.size()
	apply_theme_profile(theme_sequence[current_theme_index])

func generate_audio_samples():
	if not audio_player or not audio_player.playing:
		return
	if current_theme_profile.is_empty():
		return
	if not ensure_playback():
		return

	var available = audio_playback.get_frames_available()
	if available < audio_buffer_size:
		return

	var frames = min(audio_buffer_size, available)
	var profile: Dictionary = current_theme_profile
	var resonance = clamp(profile.get("resonance", filter_resonance), 0.05, 1.25)
	var filter_sweep = profile.get("filter_sweep", 180.0)
	var filter_lfo_rate = profile.get("sweep_rate", 0.3)

	for _i in range(frames):
		var lfo_value = sin(lfo_phase) * lfo_depth
		lfo_phase = wrapf(lfo_phase + lfo_rate * TAU / sample_rate, 0.0, TAU)

		var osc_sum = 0.0
		for osc in audio_oscillators:
			var osc_freq = base_frequency * (1.0 + osc.detune) + base_frequency * lfo_value
			var increment = osc_freq * TAU / sample_rate
			osc.phase = wrapf(osc.phase + increment, 0.0, TAU)
			osc_sum += waveform_sample(osc.type, osc.phase) * osc.gain

		var noise_component = randf_range(-1.0, 1.0) * audio_noise_amount
		var raw_signal = (osc_sum + noise_component) * audio_gain

		var cutoff = profile.get("filter_frequency", filter_frequency) + sin(time * filter_lfo_rate) * filter_sweep
		var filtered = process_filter_sample(raw_signal, cutoff, resonance)
		var driven = soft_clip(filtered, filter_drive)
		var output = clamp(driven, -1.0, 1.0)

		audio_playback.push_frame(Vector2(output, output))

func process_filter_sample(input_signal: float, cutoff: float, resonance: float) -> float:
	cutoff = clamp(cutoff, 60.0, sample_rate * 0.45)
	var g = 2.0 * sin(PI * cutoff / sample_rate)
	var r = clamp(resonance, 0.01, 1.4)
	filter_lp += g * filter_bp
	filter_hp = input_signal - filter_lp - r * filter_bp
	filter_bp += g * filter_hp
	filter_lp = clamp(filter_lp, -2.0, 2.0)
	filter_bp = clamp(filter_bp, -2.0, 2.0)
	filter_hp = clamp(filter_hp, -2.0, 2.0)

	match current_filter:
		FilterType.LOW_PASS:
			return filter_lp
		FilterType.HIGH_PASS:
			return filter_hp
		FilterType.BAND_PASS:
			return filter_bp
		FilterType.NOTCH:
			return filter_hp + filter_lp
		_:
			return input_signal

func waveform_sample(osc_type: int, phase: float) -> float:
	match osc_type:
		OscillatorType.SAWTOOTH:
			return 2.0 * (phase / TAU - floor(phase / TAU + 0.5))
		OscillatorType.SQUARE:
			return 1.0 if sin(phase) >= 0.0 else -1.0
		OscillatorType.TRIANGLE:
			return (2.0 / PI) * asin(sin(phase))
		OscillatorType.NOISE:
			return randf_range(-1.0, 1.0)
		_:
			return sin(phase)

func soft_clip(value: float, drive: float) -> float:
	var amount = 1.0 + clamp(drive, 0.0, 1.0) * 5.0
	var y = value * amount
	return y / (1.0 + abs(y))
