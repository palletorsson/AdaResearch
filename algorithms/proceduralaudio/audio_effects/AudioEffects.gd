extends Node3D

# Audio Effects Visualization
# Demonstrates reverb, delay, chorus, distortion and other audio processing

var time := 0.0
var effect_timer := 0.0

# Effect parameters
var reverb_size := 0.7
var reverb_damping := 0.5
var delay_time := 0.3
var delay_feedback := 0.4
var chorus_rate := 2.0
var chorus_depth := 0.2
var distortion_drive := 0.6

# Audio processing simulation
var input_signal := []
var reverb_buffer := []
var delay_buffer := []
var output_signal := []

# Real-time audio synthesis
var sample_rate := 44100.0
var audio_stream: AudioStreamGenerator
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_buffer_size := 512
var input_phase := 0.0
var noise_phase := 0.0
var chorus_phase := 0.0
var audio_chorus_buffer := []
var audio_chorus_index := 0
var audio_delay_buffer := []
var audio_delay_index := 0
var audio_reverb_buffer := []
var audio_reverb_index := 0
var theme_sequence := ["queer", "sci_fi", "cyberpunk", "epic"]
var current_theme_index := 0
var theme_cycle_duration := 16.0
var theme_timer := 0.0
var current_theme := ""
var current_theme_profile := {}
var theme_profiles := {
	"queer": {
		"base_frequency": 220.0,
		"sparkle": 0.7,
		"noise": 0.18,
		"distortion_drive": 0.32,
		"reverb_size": 0.75,
		"reverb_damping": 0.42,
		"reverb_mix": 0.55,
		"delay_time": 0.34,
		"delay_feedback": 0.44,
		"delay_mix": 0.45,
		"chorus_rate": 1.6,
		"chorus_depth": 0.0045,
		"chorus_mix": 0.4
	},
	"sci_fi": {
		"base_frequency": 320.0,
		"sparkle": 0.9,
		"noise": 0.12,
		"distortion_drive": 0.24,
		"reverb_size": 0.62,
		"reverb_damping": 0.28,
		"reverb_mix": 0.5,
		"delay_time": 0.46,
		"delay_feedback": 0.52,
		"delay_mix": 0.48,
		"chorus_rate": 0.9,
		"chorus_depth": 0.006,
		"chorus_mix": 0.55
	},
	"cyberpunk": {
		"base_frequency": 140.0,
		"sparkle": 0.5,
		"noise": 0.25,
		"distortion_drive": 0.58,
		"reverb_size": 0.52,
		"reverb_damping": 0.35,
		"reverb_mix": 0.42,
		"delay_time": 0.28,
		"delay_feedback": 0.62,
		"delay_mix": 0.55,
		"chorus_rate": 2.1,
		"chorus_depth": 0.0055,
		"chorus_mix": 0.5
	},
	"epic": {
		"base_frequency": 260.0,
		"sparkle": 0.85,
		"noise": 0.1,
		"distortion_drive": 0.3,
		"reverb_size": 0.88,
		"reverb_damping": 0.5,
		"reverb_mix": 0.6,
		"delay_time": 0.38,
		"delay_feedback": 0.48,
		"delay_mix": 0.5,
		"chorus_rate": 1.3,
		"chorus_depth": 0.0035,
		"chorus_mix": 0.45
	}
}


func _ready():
	randomize()
	initialize_audio_buffers()
	setup_audio_synthesis()
	apply_theme_profile(theme_sequence[0])

func _process(delta):
	time += delta
	effect_timer += delta
	
	update_effect_parameters()
	generate_input_signal()
	visualize_reverb_effect()
	visualize_delay_effect()
	visualize_chorus_effect()
	visualize_distortion_effect()
	show_effect_chain()
	show_frequency_analysis()
	update_theme_cycle(delta)
	generate_audio_samples()

func initialize_audio_buffers():
	# Initialize buffers for audio processing simulation
	input_signal.resize(128)
	reverb_buffer.resize(256)
	delay_buffer.resize(192)
	output_signal.resize(128)
	
	# Fill with zeros
	for i in range(input_signal.size()):
		input_signal[i] = 0.0
	for i in range(reverb_buffer.size()):
		reverb_buffer[i] = 0.0
	for i in range(delay_buffer.size()):
		delay_buffer[i] = 0.0
	for i in range(output_signal.size()):
		output_signal[i] = 0.0

func update_effect_parameters():
	if current_theme_profile.is_empty():
		return
	
	var profile: Dictionary = current_theme_profile
	reverb_size = profile.get("reverb_size", 0.7) + sin(time * 0.3) * 0.1
	reverb_damping = clamp(profile.get("reverb_damping", 0.4) + cos(time * 0.4) * 0.05, 0.0, 1.0)
	delay_time = clamp(profile.get("delay_time", 0.3) + sin(time * 0.5) * 0.05, 0.05, 0.6)
	delay_feedback = clamp(profile.get("delay_feedback", 0.4) + cos(time * 0.6) * 0.05, 0.0, 0.95)
	chorus_rate = max(0.1, profile.get("chorus_rate", 1.5) + sin(time * 0.7) * 0.4)
	chorus_depth = clamp(profile.get("chorus_depth", 0.003) + cos(time * 0.8) * 0.0015, 0.0005, 0.02)
	distortion_drive = clamp(profile.get("distortion_drive", 0.4) + sin(time * 0.9) * 0.06, 0.0, 1.0)

func generate_input_signal():
	if current_theme_profile.is_empty():
		return
	
	var profile: Dictionary = current_theme_profile
	var base_freq = profile.get("base_frequency", 440.0)
	var sparkle = profile.get("sparkle", 0.6)
	var noise_amount = profile.get("noise", 0.1)
	
	for i in range(input_signal.size()):
		var t = time + float(i) / sample_rate
		var fundamental = sin(t * TAU * base_freq) * 0.5
		var harmonic = sin(t * TAU * base_freq * 2.0 + 0.3) * 0.3
		var shimmer = sin(t * TAU * base_freq * 0.5 + i * 0.02) * sparkle * 0.25
		var noise = randf_range(-1.0, 1.0) * noise_amount * 0.2
		input_signal[i] = (fundamental + harmonic + shimmer + noise) * 0.8

func visualize_reverb_effect():
	var container = $ReverbVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Simulate reverb (multiple delayed echoes)
	var reverb_taps = [0.1, 0.15, 0.23, 0.35, 0.47, 0.61, 0.79, 0.89]
	
	for i in range(reverb_taps.size()):
		var tap_delay = reverb_taps[i]
		var decay = pow(0.7, i)  # Exponential decay
		
		# Create reverb reflection visualization
		var reflection = CSGSphere3D.new()
		reflection.radius = 0.1 + decay * 0.3
		
		var angle = time * 2 + i * TAU / reverb_taps.size()
		reflection.position = Vector3(
			cos(angle) * (2 + tap_delay * 3),
			sin(angle + time) * 1.5,
			sin(angle * 0.7) * 1.0
		)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0, decay)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(0.3, 0.7, 1.0) * decay * 0.5
		reflection.material_override = material
		
		container.add_child(reflection)
	
	# Central reverb chamber
	var chamber = CSGSphere3D.new()
	chamber.radius = 1.5 + reverb_size * 0.5
	chamber.position = Vector3.ZERO
	
	var chamber_material = StandardMaterial3D.new()
	chamber_material.albedo_color = Color(0.5, 0.8, 1.0, 0.2)
	chamber_material.flags_transparent = true
	chamber_material.emission_enabled = true
	chamber_material.emission = Color(0.5, 0.8, 1.0) * 0.1
	chamber.material_override = chamber_material
	
	container.add_child(chamber)

func visualize_delay_effect():
	var container = $DelayVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show delay line as moving spheres
	var num_delays = 8
	
	for i in range(num_delays):
		var delay_sphere = CSGSphere3D.new()
		delay_sphere.radius = 0.2
		
		# Position based on delay time and feedback
		var delay_pos = fmod(time * 2 + i * delay_time, 4.0)
		delay_sphere.position = Vector3(
			delay_pos - 2.0,
			sin(time * 3 + i * 0.5) * 0.5,
			0
		)
		
		var material = StandardMaterial3D.new()
		var feedback_level = pow(delay_feedback, i)
		material.albedo_color = Color(1.0, 0.5, 0.2, feedback_level)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.2) * feedback_level * 0.6
		delay_sphere.material_override = material
		
		container.add_child(delay_sphere)
	
	# Delay line representation
	var delay_line = CSGBox3D.new()
	delay_line.size = Vector3(4.0, 0.1, 0.1)
	delay_line.position = Vector3(0, -1, 0)
	
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color(0.8, 0.8, 0.8)
	delay_line.material_override = line_material
	
	container.add_child(delay_line)

func visualize_chorus_effect():
	var container = $ChorusVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show chorus as modulated delay lines
	var num_voices = 6
	
	for i in range(num_voices):
		# LFO modulation for each voice
		var lfo_phase = time * chorus_rate + i * TAU / num_voices
		var modulation = sin(lfo_phase) * chorus_depth
		
		var voice_sphere = CSGSphere3D.new()
		voice_sphere.radius = 0.15
		
		# Position with pitch modulation
		var base_height = float(i - num_voices * 0.5) * 0.4
		voice_sphere.position = Vector3(
			modulation * 3,
			base_height + sin(lfo_phase * 0.5) * 0.2,
			cos(lfo_phase) * 0.5
		)
		
		var material = StandardMaterial3D.new()
		var voice_hue = float(i) / num_voices
		material.albedo_color = Color.from_hsv(voice_hue, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(voice_hue, 0.8, 1.0) * 0.4
		voice_sphere.material_override = material
		
		container.add_child(voice_sphere)
		
		# Connection lines showing modulation
		if i > 0:
			var connection = CSGCylinder3D.new()
			connection.radius = 0.02
			
			connection.height = 0.4
			connection.position = Vector3(modulation * 3, base_height - 0.2, 0)
			connection.rotation_degrees = Vector3(0, 0, 90)
			
			var conn_material = StandardMaterial3D.new()
			conn_material.albedo_color = Color(0.7, 0.7, 0.7, 0.6)
			conn_material.flags_transparent = true
			connection.material_override = conn_material
			
			container.add_child(connection)

func visualize_distortion_effect():
	var container = $DistortionVisualization
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show distortion as waveform shaping
	var waveform_points = 32
	
	for i in range(waveform_points):
		var t = float(i) / waveform_points
		var input_amplitude = sin(t * TAU * 2)
		
		# Apply distortion (soft clipping)
		var driven_signal = input_amplitude * (1.0 + distortion_drive * 3)
		var distorted_output = tanh(driven_signal)
		
		# Input waveform
		var input_point = CSGSphere3D.new()
		input_point.radius = 0.08
		input_point.position = Vector3(
			(t - 0.5) * 4,
			input_amplitude * 1.5,
			-0.5
		)
		
		var input_material = StandardMaterial3D.new()
		input_material.albedo_color = Color(0.3, 1.0, 0.3)
		input_point.material_override = input_material
		
		container.add_child(input_point)
		
		# Output waveform
		var output_point = CSGSphere3D.new()
		output_point.radius = 0.08
		output_point.position = Vector3(
			(t - 0.5) * 4,
			distorted_output * 1.5,
			0.5
		)
		
		var output_material = StandardMaterial3D.new()
		var distortion_amount = abs(distorted_output - input_amplitude)
		output_material.albedo_color = Color(1.0, 1.0 - distortion_amount, 0.2)
		output_material.emission_enabled = true
		output_material.emission = Color(1.0, 1.0 - distortion_amount, 0.2) * 0.4
		output_point.material_override = output_material
		
		container.add_child(output_point)
	
	# Distortion curve visualization
	var curve_display = CSGBox3D.new()
	curve_display.size = Vector3(4, 0.1, 1)
	curve_display.position = Vector3(0, 0, 0)
	
	var curve_material = StandardMaterial3D.new()
	curve_material.albedo_color = Color(1.0, 0.5, 0.0, 0.3)
	curve_material.flags_transparent = true
	curve_display.material_override = curve_material
	
	container.add_child(curve_display)

func show_effect_chain():
	var container = $EffectChain
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Show effects chain processing
	var effects = ["Input", "Distortion", "Chorus", "Delay", "Reverb", "Output"]
	
	for i in range(effects.size()):
		var effect_box = CSGBox3D.new()
		effect_box.size = Vector3(1.5, 0.8, 0.8)
		effect_box.position = Vector3(i * 2.5 - effects.size() * 1.25, 0, 0)
		
		var material = StandardMaterial3D.new()
		var effect_activity = sin(time * 4 + i * 0.5) * 0.5 + 0.5
		
		match effects[i]:
			"Input":
				material.albedo_color = Color(0.3, 1.0, 0.3)
			"Distortion":
				material.albedo_color = Color(1.0, 0.3, 0.3)
			"Chorus":
				material.albedo_color = Color(0.3, 0.3, 1.0)
			"Delay":
				material.albedo_color = Color(1.0, 0.5, 0.0)
			"Reverb":
				material.albedo_color = Color(0.5, 0.8, 1.0)
			"Output":
				material.albedo_color = Color(1.0, 1.0, 0.3)
		
		material.emission_enabled = true
		material.emission = material.albedo_color * effect_activity * 0.4
		material.metallic = 0.3
		material.roughness = 0.4
		effect_box.material_override = material
		
		container.add_child(effect_box)
		
		# Connection arrows
		if i < effects.size() - 1:
			var arrow = CSGCylinder3D.new()
			arrow.radius = 0.05
			arrow.height = 0.4
			arrow.position = Vector3(i * 2.5 - effects.size() * 1.25 + 1.0, 0, 0)
			arrow.rotation_degrees = Vector3(0, 0, -90)
			
			var arrow_material = StandardMaterial3D.new()
			arrow_material.albedo_color = Color(1.0, 1.0, 1.0)
			arrow.material_override = arrow_material
			
			container.add_child(arrow)

func show_frequency_analysis():
	var container = $FrequencyAnalysis
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Simulate frequency spectrum
	var num_bands = 16
	
	for i in range(num_bands):
		var frequency = 50.0 * pow(2, float(i) / 4.0)  # Logarithmic frequency scale
		var magnitude = sin(time * 2 + i * 0.3) * 0.5 + 0.5
		
		# Apply effect processing to frequency response
		match int(time) % 4:
			0:  # Clean signal
				magnitude *= 1.0
			1:  # Distortion emphasizes harmonics
				if i > 4:
					magnitude *= 1.5
			2:  # Chorus adds frequency spread
				magnitude += sin(time * 8 + i) * 0.2
			3:  # Reverb adds high-frequency content
				if i > 8:
					magnitude *= 1.3
		
		var band_height = magnitude * 3.0
		var spectrum_bar = CSGBox3D.new()
		spectrum_bar.size = Vector3(0.4, band_height, 0.4)
		spectrum_bar.position = Vector3(i * 0.6 - num_bands * 0.3, band_height * 0.5, 0)
		
		var material = StandardMaterial3D.new()
		var freq_ratio = float(i) / num_bands
		material.albedo_color = Color.from_hsv(freq_ratio * 0.8, 0.8, 1.0)
		material.emission_enabled = true
		material.emission = Color.from_hsv(freq_ratio * 0.8, 0.8, 1.0) * magnitude * 0.5
		spectrum_bar.material_override = material
		
		container.add_child(spectrum_bar)

func setup_audio_synthesis():
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.2

	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -4.0
	add_child(audio_player)
	audio_player.play()

	audio_playback = audio_player.get_stream_playback()

	audio_chorus_buffer.resize(int(sample_rate * 0.05))
	audio_delay_buffer.resize(int(sample_rate * 1.5))
	audio_reverb_buffer.resize(int(sample_rate * 2.0))
	reset_audio_delay_lines()

func reset_audio_delay_lines():
	audio_chorus_index = 0
	audio_delay_index = 0
	audio_reverb_index = 0

	for i in range(audio_chorus_buffer.size()):
		audio_chorus_buffer[i] = 0.0
	for i in range(audio_delay_buffer.size()):
		audio_delay_buffer[i] = 0.0
	for i in range(audio_reverb_buffer.size()):
		audio_reverb_buffer[i] = 0.0

func apply_theme_profile(theme_name: String):
	if not theme_profiles.has(theme_name):
		return

	current_theme = theme_name
	current_theme_index = theme_sequence.find(theme_name)
	if current_theme_index == -1:
		current_theme_index = 0

	current_theme_profile = theme_profiles[theme_name]
	reverb_size = current_theme_profile.get("reverb_size", reverb_size)
	reverb_damping = current_theme_profile.get("reverb_damping", reverb_damping)
	delay_time = current_theme_profile.get("delay_time", delay_time)
	delay_feedback = current_theme_profile.get("delay_feedback", delay_feedback)
	chorus_rate = current_theme_profile.get("chorus_rate", chorus_rate)
	chorus_depth = current_theme_profile.get("chorus_depth", chorus_depth)
	distortion_drive = current_theme_profile.get("distortion_drive", distortion_drive)
	theme_timer = 0.0
	reset_audio_delay_lines()
	print("AudioEffects: activated %s theme" % theme_name)

func update_theme_cycle(delta: float):
	theme_timer += delta
	if theme_timer >= theme_cycle_duration:
		theme_timer = 0.0
		advance_theme()

func advance_theme():
	current_theme_index = (current_theme_index + 1) % theme_sequence.size()
	apply_theme_profile(theme_sequence[current_theme_index])

func ensure_playback():
	if audio_playback:
		return true
	if not audio_player:
		return false
	audio_playback = audio_player.get_stream_playback()
	return audio_playback != null

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

	var profile: Dictionary = current_theme_profile
	var base_freq = profile.get("base_frequency", 220.0)
	var sparkle = profile.get("sparkle", 0.6)
	var noise_amount = profile.get("noise", 0.1)
	var drive = profile.get("distortion_drive", 0.3)
	var chorus_mix = profile.get("chorus_mix", 0.4)
	var delay_mix = profile.get("delay_mix", 0.45)
	var reverb_mix = profile.get("reverb_mix", 0.5)
	var frames_to_write = min(audio_buffer_size, available)
	var delay_samples = clamp(int(delay_time * sample_rate), 1, max(2, audio_delay_buffer.size() - 1))
	var reverb_decay = 0.35 + reverb_size * 0.4
	var damping = clamp(current_theme_profile.get("reverb_damping", reverb_damping), 0.0, 0.95)

	for _i in range(frames_to_write):
		input_phase = wrapf(input_phase + base_freq * TAU / sample_rate, 0.0, TAU)
		var base = sin(input_phase)
		var overtone = sin(input_phase * 2.0) * 0.45
		var shimmer = sin(input_phase * 0.5 + time * 0.5) * sparkle * 0.25
		var dry = (base + overtone + shimmer) * 0.4
		dry += randf_range(-1.0, 1.0) * noise_amount * 0.15

		var distorted = soft_clip(dry, drive)

		if audio_chorus_buffer.size() == 0:
			audio_chorus_buffer.resize(1)
		var chorus_size = audio_chorus_buffer.size()
		var chorus_delay = clamp(int((0.01 + chorus_depth) * sample_rate + sin(chorus_phase) * chorus_depth * sample_rate), 1, chorus_size - 1)
		var chorus_read = (audio_chorus_index - chorus_delay) % chorus_size
		var modulated = audio_chorus_buffer[chorus_read]
		audio_chorus_buffer[audio_chorus_index] = distorted
		audio_chorus_index = (audio_chorus_index + 1) % chorus_size
		chorus_phase = wrapf(chorus_phase + chorus_rate * TAU / sample_rate, 0.0, TAU)
		var chorus_out = distorted * (1.0 - chorus_mix) + modulated * chorus_mix

		if audio_delay_buffer.size() == 0:
			audio_delay_buffer.resize(1)
		var delay_size = audio_delay_buffer.size()
		var delay_read = (audio_delay_index - delay_samples) % delay_size
		var delay_sample = audio_delay_buffer[delay_read]
		audio_delay_buffer[audio_delay_index] = chorus_out + delay_sample * delay_feedback
		audio_delay_index = (audio_delay_index + 1) % delay_size
		var delay_out = chorus_out * (1.0 - delay_mix) + delay_sample * delay_mix

		if audio_reverb_buffer.size() == 0:
			audio_reverb_buffer.resize(1)
		var reverb_size_local = audio_reverb_buffer.size()
		var reverb_sample = audio_reverb_buffer[audio_reverb_index]
		var reverb_input = delay_out + reverb_sample * reverb_decay
		audio_reverb_buffer[audio_reverb_index] = reverb_input * (1.0 - damping)
		audio_reverb_index = (audio_reverb_index + 1) % reverb_size_local
		var wet = reverb_sample * reverb_mix

		var output = clamp(delay_out * (1.0 - reverb_mix) + wet, -1.0, 1.0)
		audio_playback.push_frame(Vector2(output, output))

func soft_clip(value: float, drive: float) -> float:
	var drive_amount = 1.0 + clamp(drive, 0.0, 1.0) * 6.0
	var y = value * drive_amount
	return y / (1.0 + abs(y))
