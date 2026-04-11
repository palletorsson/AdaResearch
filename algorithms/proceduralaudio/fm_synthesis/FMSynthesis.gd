# @identity
# essence: carrier(t) = sin(2pi*fc*t + I*sin(2pi*fm*t)) -- one oscillator bending another from inside
# desire: metallic bells and electric pianos cascade from two sine waves interfering at audio rate
# critical_parameter: modulation_index -- small changes cascade into dense harmonic spectra; ratio sets carrier:modulator
# triggers: theme profiles cycle carrier frequency, ratio, index depth, feedback amount, and harmonic mix
# emerges: sounds that analog circuits cannot produce -- infinite sidebands from two simple oscillators
# needs: AudioStreamGenerator [has]; carrier/modulator phase tracking [has]; feedback path [has]; VR controls [missing]
# relationships: extends additive/subtractive by replacing addition with interference; Chowning DX7 legacy
# truth: modulation is not addition -- it is mutual distortion, producing harmonics neither source contains alone.

extends Node3D

var time = 0.0
var carrier_freq = 440.0
var modulator_freq = 220.0
var modulation_index = 5.0
var fm_ratio = 1.0
var spectrum_nodes = []
var modulation_path_nodes = []
var spectrum_resolution = 32

# Audio synthesis
var sample_rate := 44100.0
var audio_stream: AudioStreamGenerator
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_buffer_size := 512
var carrier_phase := 0.0
var modulator_phase := 0.0
var vibrato_phase := 0.0
var feedback_state := 0.0
var theme_sequence := ["queer", "sci_fi", "cyberpunk", "epic"]
var current_theme_index := 0
var current_theme := ""
var theme_cycle_duration := 14.0
var theme_timer := 0.0
var current_theme_profile := {}
var theme_profiles := {
	"queer": {
		"carrier": 220.0,
		"carrier_depth": 80.0,
		"carrier_rate": 0.28,
		"ratio": 1.5,
		"ratio_depth": 0.4,
		"ratio_rate": 0.25,
		"index": 5.5,
		"index_depth": 1.8,
		"index_rate": 0.35,
		"feedback": 0.18,
		"harmonic_mix": 0.28,
		"gain": 0.75,
		"drive": 0.22,
		"vibrato_depth": 0.012,
		"vibrato_rate": 4.0
	},
	"sci_fi": {
		"carrier": 340.0,
		"carrier_depth": 140.0,
		"carrier_rate": 0.35,
		"ratio": 2.0,
		"ratio_depth": 0.6,
		"ratio_rate": 0.3,
		"index": 7.2,
		"index_depth": 2.0,
		"index_rate": 0.4,
		"feedback": 0.25,
		"harmonic_mix": 0.35,
		"gain": 0.7,
		"drive": 0.3,
		"vibrato_depth": 0.008,
		"vibrato_rate": 6.0
	},
	"cyberpunk": {
		"carrier": 150.0,
		"carrier_depth": 110.0,
		"carrier_rate": 0.22,
		"ratio": 0.75,
		"ratio_depth": 0.35,
		"ratio_rate": 0.2,
		"index": 9.0,
		"index_depth": 2.5,
		"index_rate": 0.28,
		"feedback": 0.42,
		"harmonic_mix": 0.4,
		"gain": 0.8,
		"drive": 0.45,
		"vibrato_depth": 0.02,
		"vibrato_rate": 2.5
	},
	"epic": {
		"carrier": 260.0,
		"carrier_depth": 120.0,
		"carrier_rate": 0.26,
		"ratio": 1.0,
		"ratio_depth": 0.3,
		"ratio_rate": 0.22,
		"index": 6.0,
		"index_depth": 1.5,
		"index_rate": 0.32,
		"feedback": 0.2,
		"harmonic_mix": 0.25,
		"gain": 0.78,
		"drive": 0.27,
		"vibrato_depth": 0.015,
		"vibrato_rate": 3.5
	}
}

func _ready() -> void:
	randomize()
	create_modulation_path()
	create_output_spectrum()
	setup_materials()
	setup_audio_synthesis()
	apply_theme_profile(theme_sequence[0])

func create_modulation_path() -> void:
	var path_parent = $ModulationPath
	
	# Create visual connection between modulator and carrier
	for i in range(20):
		var path_node = CSGSphere3D.new()
		path_node.radius = 0.05
		path_node.position = Vector3(
			lerp(3.0, -3.0, i / 19.0),
			1.5,
			0
		)
		path_parent.add_child(path_node)
		modulation_path_nodes.append(path_node)

func create_output_spectrum() -> void:
	var spectrum_parent = $OutputSpectrum
	
	for i in range(spectrum_resolution):
		var spectrum_bar = CSGBox3D.new()
		spectrum_bar.size = Vector3(0.2, 0.1, 0.2)
		spectrum_bar.position = Vector3(
			-6 + i * 0.4,
			-1,
			2
		)
		spectrum_parent.add_child(spectrum_bar)
		spectrum_nodes.append(spectrum_bar)

func setup_materials() -> void:
	# Carrier material
	var carrier_material = StandardMaterial3D.new()
	carrier_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	carrier_material.emission_enabled = true
	carrier_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$Carrier.material_override = carrier_material
	
	# Modulator material
	var modulator_material = StandardMaterial3D.new()
	modulator_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	modulator_material.emission_enabled = true
	modulator_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$Modulator.material_override = modulator_material
	
	# Modulation path materials
	var path_material = StandardMaterial3D.new()
	path_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	path_material.emission_enabled = true
	path_material.emission = Color(0.3, 0.3, 0.1, 1.0)
	
	for node in modulation_path_nodes:
		node.material_override = path_material
	
	# Spectrum materials
	var spectrum_material = StandardMaterial3D.new()
	spectrum_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	spectrum_material.emission_enabled = true
	spectrum_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	
	for bar in spectrum_nodes:
		bar.material_override = spectrum_material
	
	# Control materials
	var carrier_freq_material = StandardMaterial3D.new()
	carrier_freq_material.albedo_color = Color(1.0, 0.6, 0.2, 1.0)
	carrier_freq_material.emission_enabled = true
	carrier_freq_material.emission = Color(0.3, 0.15, 0.05, 1.0)
	$CarrierFreq.material_override = carrier_freq_material
	
	var mod_freq_material = StandardMaterial3D.new()
	mod_freq_material.albedo_color = Color(0.6, 0.2, 1.0, 1.0)
	mod_freq_material.emission_enabled = true
	mod_freq_material.emission = Color(0.15, 0.05, 0.3, 1.0)
	$ModulatorFreq.material_override = mod_freq_material
	
	var mod_index_material = StandardMaterial3D.new()
	mod_index_material.albedo_color = Color(0.2, 1.0, 0.6, 1.0)
	mod_index_material.emission_enabled = true
	mod_index_material.emission = Color(0.05, 0.3, 0.15, 1.0)
	$ModulationIndex.material_override = mod_index_material
	
	var ratio_material = StandardMaterial3D.new()
	ratio_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	ratio_material.emission_enabled = true
	ratio_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$FMRatio.material_override = ratio_material

func _process(delta: float) -> void:
	time += delta

	if current_theme_profile.is_empty():
		carrier_freq = 440.0 + sin(time * 0.2) * 200.0
		fm_ratio = 1.0 + sin(time * 0.15) * 1.5
		modulator_freq = carrier_freq * fm_ratio
		modulation_index = 3.0 + sin(time * 0.3) * 4.0
	else:
		var profile: Dictionary = current_theme_profile
		var carrier_base = profile.get("carrier", carrier_freq)
		var carrier_depth = profile.get("carrier_depth", 120.0)
		var carrier_rate = profile.get("carrier_rate", 0.28)
		carrier_freq = carrier_base + sin(time * carrier_rate) * carrier_depth

		var ratio_base = profile.get("ratio", fm_ratio)
		var ratio_depth = profile.get("ratio_depth", 0.3)
		var ratio_rate = profile.get("ratio_rate", 0.25)
		fm_ratio = max(0.1, ratio_base + sin(time * ratio_rate) * ratio_depth)
		modulator_freq = carrier_freq * fm_ratio

		var index_base = profile.get("index", modulation_index)
		var index_depth = profile.get("index_depth", 1.5)
		var index_rate = profile.get("index_rate", 0.35)
		modulation_index = max(0.05, index_base + sin(time * index_rate) * index_depth)

	animate_fm_synthesis()
	animate_controls()
	update_theme_cycle(delta)
	generate_audio_samples()

func animate_fm_synthesis() -> void:
	# Animate carrier oscillator
	var carrier_phase = time * carrier_freq * 2.0 * PI
	var carrier_scale = 1.0 + sin(carrier_phase) * 0.3
	$Carrier.scale = Vector3.ONE * carrier_scale
	
	# Animate modulator oscillator
	var modulator_phase = time * modulator_freq * 2.0 * PI
	var modulator_scale = 1.0 + sin(modulator_phase) * 0.4
	$Modulator.scale = Vector3.ONE * modulator_scale
	
	# Animate modulation path
	animate_modulation_path()
	
	# Calculate and display FM spectrum
	calculate_fm_spectrum()

func animate_modulation_path() -> void:
	# Show modulation signal traveling from modulator to carrier
	var wave_position = fmod(time * 2.0, 1.0)
	
	for i in range(modulation_path_nodes.size()):
		var node = modulation_path_nodes[i]
		var node_position = i / float(modulation_path_nodes.size() - 1)
		
		# Calculate distance from traveling wave
		var distance = abs(node_position - wave_position)
		var intensity = max(0.0, 1.0 - distance * 5.0)
		
		# Scale and animate based on modulation signal
		var modulation_value = sin(time * modulator_freq * 2.0 * PI) * modulation_index * 0.1
		var scale = 0.5 + intensity * (1.0 + modulation_value)
		node.scale = Vector3.ONE * scale
		
		# Update material
		var material = node.material_override as StandardMaterial3D
		if material:
			material.emission = Color(
				0.3 + intensity * 0.5,
				0.3 + intensity * 0.5,
				0.1 + intensity * 0.3,
				1.0
			)

func calculate_fm_spectrum() -> void:
	# Calculate FM spectrum using Bessel functions approximation
	for i in range(spectrum_nodes.size()):
		var bar = spectrum_nodes[i]
		var frequency_ratio = i / float(spectrum_resolution) * 8.0  # 0 to 8 times carrier frequency
		
		# Calculate sidebands using simplified Bessel function approximation
		var amplitude = calculate_fm_sideband_amplitude(frequency_ratio)
		
		# Add some dynamics
		amplitude *= (1.0 + sin(time * 3.0 + i * 0.2) * 0.3)
		
		# Update spectrum bar
		var height = 0.1 + amplitude * 2.0
		bar.size.y = height
		bar.position.y = -1 + height/2
		
		# Update color based on amplitude
		var material = bar.material_override as StandardMaterial3D
		if material:
			var intensity = amplitude
			material.albedo_color = Color(
				0.2 + intensity * 0.8,
				1.0 - intensity * 0.5,
				0.8 - intensity * 0.3,
				1.0
			)
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func calculate_fm_sideband_amplitude(frequency_ratio: float) -> float:
	# Simplified FM spectrum calculation
	# In real FM synthesis, this would use Bessel functions
	
	var carrier_ratio = 1.0
	var sideband_distance = abs(frequency_ratio - carrier_ratio)
	
	# Approximate sideband amplitudes
	var amplitude = 0.0
	
	# Carrier
	if sideband_distance < 0.1:
		amplitude = bessel_j0_approx(modulation_index)
	
	# First sidebands
	elif abs(sideband_distance - fm_ratio) < 0.1:
		amplitude = abs(bessel_j1_approx(modulation_index))
	
	# Second sidebands
	elif abs(sideband_distance - 2.0 * fm_ratio) < 0.1:
		amplitude = abs(bessel_j2_approx(modulation_index)) * 0.5
	
	# Higher order sidebands with decay
	else:
		var order = round(sideband_distance / fm_ratio)
		if order <= 6:
			amplitude = exp(-order * 0.5) * sin(modulation_index) / (order + 1)
	
	return clamp(amplitude, 0.0, 1.0)

# Simplified Bessel function approximations
func bessel_j0_approx(x: float) -> float:
	if abs(x) < 0.1:
		return 1.0 - x*x/4.0
	else:
		return sqrt(2.0 / (PI * abs(x))) * cos(abs(x) - PI/4.0)

func bessel_j1_approx(x: float) -> float:
	if abs(x) < 0.1:
		return x/2.0
	else:
		return sqrt(2.0 / (PI * abs(x))) * cos(abs(x) - 3.0*PI/4.0) * sign(x)

func bessel_j2_approx(x: float) -> float:
	if abs(x) < 0.1:
		return x*x/8.0
	else:
		return sqrt(2.0 / (PI * abs(x))) * cos(abs(x) - 5.0*PI/4.0)

func animate_controls() -> void:
	# Carrier frequency control
	var carrier_height = (carrier_freq / 800.0) * 1.5 + 0.5
	$CarrierFreq.height = carrier_height
	$CarrierFreq.position.y = -3 + carrier_height/2
	
	# Modulator frequency control
	var mod_height = (modulator_freq / 800.0) * 1.5 + 0.5
	$ModulatorFreq.height = mod_height
	$ModulatorFreq.position.y = -3 + mod_height/2
	
	# Modulation index control
	var index_height = (modulation_index / 10.0) * 1.5 + 0.5
	$ModulationIndex.height = index_height
	$ModulationIndex.position.y = -3 + index_height/2
	
	# FM ratio indicator
	var ratio_height = fm_ratio * 0.8 + 0.5
	$FMRatio.height = ratio_height
	$FMRatio.position.y = -3 + ratio_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$CarrierFreq.scale.x = pulse
	$ModulatorFreq.scale.x = pulse
	$ModulationIndex.scale.x = pulse
	$FMRatio.scale.x = pulse
	
	# Update carrier and modulator emission based on their signals
	var carrier_material = $Carrier.material_override as StandardMaterial3D
	if carrier_material:
		var carrier_intensity = (sin(time * carrier_freq * 2.0 * PI) + 1.0) * 0.5
		carrier_material.emission = Color(0.5, 0.1, 0.1, 1.0) * (0.5 + carrier_intensity)
	
	var modulator_material = $Modulator.material_override as StandardMaterial3D
	if modulator_material:
		var mod_intensity = (sin(time * modulator_freq * 2.0 * PI) + 1.0) * 0.5
		modulator_material.emission = Color(0.1, 0.1, 0.5, 1.0) * (0.5 + mod_intensity)

func setup_audio_synthesis() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.2

	audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -3.0
	add_child(audio_player)
	audio_player.play()

	audio_playback = audio_player.get_stream_playback()
	reset_phases()

func ensure_playback() -> bool:
	if audio_playback:
		return true
	if not audio_player:
		return false
	audio_playback = audio_player.get_stream_playback()
	return audio_playback != null

func reset_phases() -> void:
	carrier_phase = 0.0
	modulator_phase = 0.0
	vibrato_phase = 0.0
	feedback_state = 0.0

func apply_theme_profile(theme_name: String) -> void:
	if not theme_profiles.has(theme_name):
		return

	current_theme = theme_name
	current_theme_index = theme_sequence.find(theme_name)
	if current_theme_index == -1:
		current_theme_index = 0

	current_theme_profile = theme_profiles[theme_name]
	carrier_freq = current_theme_profile.get("carrier", carrier_freq)
	fm_ratio = current_theme_profile.get("ratio", fm_ratio)
	modulator_freq = carrier_freq * fm_ratio
	modulation_index = current_theme_profile.get("index", modulation_index)
	reset_phases()
	theme_timer = 0.0
	print("FMSynthesis: activated %s theme" % theme_name)

func update_theme_cycle(delta: float) -> void:
	theme_timer += delta
	if theme_timer >= theme_cycle_duration:
		theme_timer = 0.0
		advance_theme()

func advance_theme() -> void:
	current_theme_index = (current_theme_index + 1) % theme_sequence.size()
	apply_theme_profile(theme_sequence[current_theme_index])

func generate_audio_samples() -> void:
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
	var feedback = profile.get("feedback", 0.0)
	var harmonic_mix = profile.get("harmonic_mix", 0.25)
	var gain = profile.get("gain", 0.7)
	var drive = profile.get("drive", 0.25)
	var vibrato_depth = profile.get("vibrato_depth", 0.0)
	var vibrato_rate = profile.get("vibrato_rate", 5.0)

	for _i in range(frames):
		vibrato_phase = wrapf(vibrato_phase + vibrato_rate * TAU / sample_rate, 0.0, TAU)
		var vibrato = sin(vibrato_phase) * vibrato_depth
		var mod_freq = modulator_freq * (1.0 + vibrato)
		modulator_phase = wrapf(modulator_phase + mod_freq * TAU / sample_rate, 0.0, TAU)
		var mod_signal = sin(modulator_phase + feedback_state * feedback)
		var instantaneous_freq = carrier_freq + mod_signal * modulation_index * modulator_freq
		carrier_phase = wrapf(carrier_phase + instantaneous_freq * TAU / sample_rate, 0.0, TAU)
		var sample = sin(carrier_phase)
		sample += sin(carrier_phase * 2.0) * harmonic_mix
		sample = soft_clip(sample * gain, drive)
		feedback_state = sample
		audio_playback.push_frame(Vector2(sample, sample))

func soft_clip(value: float, drive: float) -> float:
	var amount = 1.0 + clamp(drive, 0.0, 1.0) * 4.5
	var y = value * amount
	return clamp(y / (1.0 + abs(y)), -1.0, 1.0)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
