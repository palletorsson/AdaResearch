# simple_mario_slider.gd
extends Control

class_name SimpleMarioSlider

# UI Elements
@onready var freq1_slider = $"VBox/Freq1Container/Freq1Slider"
@onready var freq1_label = $"VBox/Freq1Container/Freq1Label"
@onready var freq2_slider = $"VBox/Freq2Container/Freq2Slider"
@onready var freq2_label = $"VBox/Freq2Container/Freq2Label"
@onready var volume_slider = $"VBox/VolumeContainer/VolumeSlider"
@onready var volume_label = $"VBox/VolumeContainer/VolumeLabel"
@onready var length_slider = $"VBox/LengthContainer/LengthSlider"
@onready var length_label = $"VBox/LengthContainer/LengthLabel"
@onready var attack_slider = $"VBox/AttackContainer/AttackSlider"
@onready var attack_label = $"VBox/AttackContainer/AttackLabel"
@onready var release_slider = $"VBox/ReleaseContainer/ReleaseSlider"
@onready var release_label = $"VBox/ReleaseContainer/ReleaseLabel"
@onready var noise_slider = $"VBox/NoiseContainer/NoiseSlider"
@onready var noise_label = $"VBox/NoiseContainer/NoiseLabel"
@onready var sparkle_toggle = $"VBox/SparkleContainer/SparkleToggle"
@onready var test_button = $"VBox/ButtonRow/TestButton"
@onready var randomize_button = $"VBox/ButtonRow/RandomizeButton"
@onready var reset_button = $"VBox/ButtonRow/ResetButton"
@onready var load_button = $"VBox/ButtonRow/LoadButton"
@onready var load_dialog = $"LoadSoundDialog"
@onready var waveform_label = $"VBox/VisualizationContainer/WaveformLabel"
@onready var waveform_display = $"VBox/VisualizationContainer/WaveformDisplay"
@onready var spectrum_label = $"VBox/VisualizationContainer/SpectrumLabel"
@onready var spectrum_display = $"VBox/VisualizationContainer/SpectrumDisplay"

# Sound parameters
var freq1: float = 880.0
var freq2: float = 1318.5
var volume: float = 0.5
var sound_length: float = 0.2
var attack_time: float = 0.018
var release_time: float = 0.12
var noise_amount: float = 0.08
var sparkle_enabled: bool = true
var vibrato_amount: float = 0.02

# Audio playback
var audio_player: AudioStreamPlayer
var external_players: Array = []
var use_custom_stream: bool = false
var custom_stream: AudioStream = null
var original_stream: AudioStream = null

# Visualization data
var waveform_points: PackedFloat32Array = PackedFloat32Array()
var raw_samples: PackedFloat32Array = PackedFloat32Array()
var spectrum_bins: PackedFloat32Array = PackedFloat32Array()

const SAMPLE_RATE := 44100
const DISPLAY_SAMPLES := 1024
const SPECTRUM_BINS := 48
const SPECTRUM_FREQ_MIN := 80.0
const SPECTRUM_FREQ_MAX := 4000.0
const SPECTRUM_SOURCE_SAMPLES := 1024
const DEFAULT_FREQ1 := 880.0
const DEFAULT_FREQ2 := 1318.5
const DEFAULT_VOLUME := 0.5
const DEFAULT_LENGTH := 0.2
const DEFAULT_ATTACK := 0.018
const DEFAULT_RELEASE := 0.12
const DEFAULT_NOISE := 0.08
const DEFAULT_SPARKLE := true

var rng := RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	setup_sliders()
	connect_signals()
	create_audio_player()
	_configure_load_dialog()
	# initialize_pickup_sound() wait with this until make a asingelton audio managere 
	setup_visualizations()
	update_all_labels()
	add_to_group("audio_emitters")
	update_waveform()

func setup_sliders():
	if freq1_slider:
		freq1_slider.min_value = 200.0
		freq1_slider.max_value = 2000.0
		freq1_slider.value = freq1
		freq1_slider.step = 5.0
	if freq2_slider:
		freq2_slider.min_value = 400.0
		freq2_slider.max_value = 3200.0
		freq2_slider.value = freq2
		freq2_slider.step = 5.0
	if volume_slider:
		volume_slider.min_value = 0.0
		volume_slider.max_value = 1.0
		volume_slider.value = volume
		volume_slider.step = 0.01
	if length_slider:
		length_slider.min_value = 0.1
		length_slider.max_value = 0.5
		length_slider.value = sound_length
		length_slider.step = 0.01
	if attack_slider:
		attack_slider.min_value = 0.0
		attack_slider.max_value = 0.08
		attack_slider.value = attack_time
		attack_slider.step = 0.001
	if release_slider:
		release_slider.min_value = 0.03
		release_slider.max_value = 0.3
		release_slider.value = release_time
		release_slider.step = 0.001
	if noise_slider:
		noise_slider.min_value = 0.0
		noise_slider.max_value = 0.3
		noise_slider.value = noise_amount
		noise_slider.step = 0.005
	if sparkle_toggle:
		sparkle_toggle.button_pressed = sparkle_enabled

func setup_visualizations():
	waveform_points.resize(DISPLAY_SAMPLES)
	spectrum_bins.resize(SPECTRUM_BINS)
	if waveform_display and not waveform_display.draw.is_connected(_on_waveform_draw):
		waveform_display.custom_minimum_size = Vector2(420, 160)
		waveform_display.draw.connect(_on_waveform_draw)
	if spectrum_display and not spectrum_display.draw.is_connected(_on_spectrum_draw):
		spectrum_display.custom_minimum_size = Vector2(420, 120)
		spectrum_display.draw.connect(_on_spectrum_draw)

func connect_signals():
	if freq1_slider:
		freq1_slider.value_changed.connect(_on_freq1_changed)
	if freq2_slider:
		freq2_slider.value_changed.connect(_on_freq2_changed)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if length_slider:
		length_slider.value_changed.connect(_on_length_changed)
	if attack_slider:
		attack_slider.value_changed.connect(_on_attack_changed)
	if release_slider:
		release_slider.value_changed.connect(_on_release_changed)
	if noise_slider:
		noise_slider.value_changed.connect(_on_noise_changed)
	if sparkle_toggle:
		sparkle_toggle.toggled.connect(_on_sparkle_toggled)
	if test_button:
		test_button.pressed.connect(_on_test_pressed)
	if randomize_button:
		randomize_button.pressed.connect(_on_randomize_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if load_dialog:
		load_dialog.file_selected.connect(_on_sound_file_selected)

func create_audio_player():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.bus = "Master"

func _configure_load_dialog() -> void:
	if load_dialog:
		load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		load_dialog.access = FileDialog.ACCESS_FILESYSTEM
		load_dialog.filters = PackedStringArray(["*.wav ; WAV Audio", "*.ogg ; OGG Audio", "*.mp3 ; MP3 Audio"])
		load_dialog.title = "Select Custom Sound"

func initialize_pickup_sound() -> void:
	original_stream = PickupCube.get_shared_pickup_stream()
	if original_stream == null:
		original_stream = PickupCube.get_default_pickup_stream()
		PickupCube.set_shared_pickup_stream(original_stream)
	_apply_stream_to_audio_player(original_stream)

func _apply_stream_to_audio_player(stream: AudioStream) -> void:
	if audio_player == null:
		return
	audio_player.stop()
	audio_player.stream = stream
	audio_player.volume_db = lerp(-20.0, 0.0, clamp(volume, 0.0, 1.0))

func _apply_stream_to_pickups(stream: AudioStream) -> void:
	PickupCube.set_shared_pickup_stream(stream)

func _clear_custom_stream_if_needed() -> void:
	if use_custom_stream:
		use_custom_stream = false
		custom_stream = null

func _parameters_match_defaults() -> bool:
	return (is_equal_approx(freq1, DEFAULT_FREQ1) and
		is_equal_approx(freq2, DEFAULT_FREQ2) and
		is_equal_approx(volume, DEFAULT_VOLUME) and
		is_equal_approx(sound_length, DEFAULT_LENGTH) and
		is_equal_approx(attack_time, DEFAULT_ATTACK) and
		is_equal_approx(release_time, DEFAULT_RELEASE) and
		is_equal_approx(noise_amount, DEFAULT_NOISE) and
		(sparkle_enabled == DEFAULT_SPARKLE))

func _apply_default_settings() -> void:
	freq1 = DEFAULT_FREQ1
	freq2 = DEFAULT_FREQ2
	volume = DEFAULT_VOLUME
	sound_length = DEFAULT_LENGTH
	attack_time = DEFAULT_ATTACK
	release_time = DEFAULT_RELEASE
	noise_amount = DEFAULT_NOISE
	sparkle_enabled = DEFAULT_SPARKLE
	if freq1_slider:
		freq1_slider.value = freq1
	if freq2_slider:
		freq2_slider.value = freq2
	if volume_slider:
		volume_slider.value = volume
	if length_slider:
		length_slider.value = sound_length
	if attack_slider:
		attack_slider.value = attack_time
	if release_slider:
		release_slider.value = release_time
	if noise_slider:
		noise_slider.value = noise_amount
	if sparkle_toggle:
		sparkle_toggle.button_pressed = sparkle_enabled

func _get_active_stream() -> AudioStream:
	if use_custom_stream and custom_stream:
		return custom_stream
	if _parameters_match_defaults():
		return PickupCube.get_shared_pickup_stream()
	update_waveform()
	return create_mario_sound()

func _on_reset_pressed() -> void:
	use_custom_stream = false
	custom_stream = null
	_apply_default_settings()
	update_all_labels()
	update_waveform()
	var stream = PickupCube.reset_shared_pickup_stream()
	original_stream = stream
	_apply_stream_to_audio_player(stream)

func _on_load_pressed() -> void:
	if load_dialog:
		load_dialog.popup_centered_ratio()

func _on_sound_file_selected(path: String) -> void:
	var resource = ResourceLoader.load(path)
	if resource == null or not resource is AudioStream:
		push_warning("Unsupported audio file: %s" % path)
		return
	custom_stream = resource
	use_custom_stream = true
	_apply_stream_to_audio_player(custom_stream)
	_apply_stream_to_pickups(custom_stream)
	update_waveform()

func _on_freq1_changed(value: float):
	_clear_custom_stream_if_needed()
	freq1 = value
	if freq1_label:
		freq1_label.text = "Frequency 1: %.0f Hz" % value
	update_waveform()

func _on_freq2_changed(value: float):
	_clear_custom_stream_if_needed()
	freq2 = value
	if freq2_label:
		freq2_label.text = "Frequency 2: %.0f Hz" % value
	update_waveform()

func _on_volume_changed(value: float):
	_clear_custom_stream_if_needed()
	volume = value
	if volume_label:
		volume_label.text = "Volume: %.2f" % value
	update_waveform()

func _on_length_changed(value: float):
	_clear_custom_stream_if_needed()
	sound_length = clamp(value, 0.05, 1.0)
	if length_label:
		length_label.text = "Length: %.2fs" % sound_length
	_ensure_envelope_within_bounds()
	update_waveform()

func _on_attack_changed(value: float):
	_clear_custom_stream_if_needed()
	attack_time = clamp(value, 0.0, 0.2)
	if attack_label:
		attack_label.text = "Attack: %s" % _format_ms(attack_time)
	_adjust_release_if_needed()
	update_waveform()

func _on_release_changed(value: float):
	_clear_custom_stream_if_needed()
	release_time = clamp(value, 0.0, 0.5)
	if release_label:
		release_label.text = "Release: %s" % _format_ms(release_time)
	_adjust_attack_if_needed()
	update_waveform()

func _on_noise_changed(value: float):
	_clear_custom_stream_if_needed()
	noise_amount = clamp(value, 0.0, 1.0)
	if noise_label:
		noise_label.text = "Noise Sparkle: %d%%" % int(round(noise_amount * 100.0))
	update_waveform()

func _on_sparkle_toggled(pressed: bool):
	_clear_custom_stream_if_needed()
	sparkle_enabled = pressed
	update_waveform()

func _on_test_pressed():
	var stream = _get_active_stream()
	_apply_stream_to_audio_player(stream)
	audio_player.play()
	_apply_stream_to_pickups(stream)

func _on_randomize_pressed():
	_clear_custom_stream_if_needed()
	rng.randomize()
	freq1_slider.value = rng.randf_range(420.0, 980.0)
	freq2_slider.value = freq1_slider.value + rng.randf_range(280.0, 620.0)
	volume_slider.value = rng.randf_range(0.45, 0.85)
	length_slider.value = rng.randf_range(0.16, 0.28)
	attack_slider.value = rng.randf_range(0.0, 0.035)
	release_slider.value = rng.randf_range(0.09, 0.18)
	noise_slider.value = rng.randf_range(0.02, 0.14)
	sparkle_toggle.button_pressed = rng.randf() > 0.2

func _ensure_envelope_within_bounds():
	var max_total = max(sound_length - 0.01, 0.02)
	var total = attack_time + release_time
	if total <= max_total:
		return
	release_time = clamp(max_total - attack_time, 0.0, max_total)
	if release_slider:
		release_slider.value = release_time

func shutdown_audio():
	if audio_player:
		audio_player.stop()
	for player in external_players.duplicate():
		if is_instance_valid(player):
			player.stop()
		_unregister_external_player(player)
	for cube in get_tree().get_nodes_in_group("mario_pickup_cubes"):
		if cube.has_method("shutdown_audio"):
			cube.shutdown_audio()
	if waveform_display:
		waveform_display.queue_redraw()
	if spectrum_display:
		spectrum_display.queue_redraw()

func _register_external_player(player: AudioStreamPlayer):
	if player == null or not is_instance_valid(player):
		return
	if player in external_players:
		return
	external_players.append(player)
	if player.has_signal("finished"):
		player.finished.connect(Callable(self, "_on_external_player_finished").bind(player), CONNECT_ONE_SHOT)

func _on_external_player_finished(player: AudioStreamPlayer):
	_unregister_external_player(player)

func _unregister_external_player(player: AudioStreamPlayer):
	if player == null:
		return
	if player in external_players:
		external_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()

func _adjust_release_if_needed():
	var max_total = max(sound_length - 0.01, 0.02)
	if attack_time + release_time > max_total:
		release_time = clamp(max_total - attack_time, 0.0, max_total)
		if release_slider:
			release_slider.value = release_time
			if release_label:
				release_label.text = "Release: %s" % _format_ms(release_time)

func _adjust_attack_if_needed():
	var max_total = max(sound_length - 0.01, 0.02)
	if attack_time + release_time > max_total:
		attack_time = clamp(max_total - release_time, 0.0, max_total)
		if attack_slider:
			attack_slider.value = attack_time
			if attack_label:
				attack_label.text = "Attack: %s" % _format_ms(attack_time)

func update_waveform():
	if use_custom_stream and custom_stream:
		for i in range(waveform_points.size()):
			waveform_points[i] = 0.0
		for i in range(spectrum_bins.size()):
			spectrum_bins[i] = 0.0
		if waveform_label:
			waveform_label.text = "Waveform (custom audio)"
		if spectrum_label:
			spectrum_label.text = "Spectrum (custom audio)"
		if waveform_display:
			waveform_display.queue_redraw()
		if spectrum_display:
			spectrum_display.queue_redraw()
		return
	if sound_length <= 0.0:
		return
	var total_samples = int(max(1, sound_length * SAMPLE_RATE))
	raw_samples.resize(total_samples)
	for i in range(total_samples):
		var t = float(i) / SAMPLE_RATE
		raw_samples[i] = _generate_sample(t)
	var display_time = min(sound_length, 0.12)
	var display_count = int(clamp(display_time * SAMPLE_RATE, 1.0, total_samples))
	var stride = float(display_count - 1) / max(DISPLAY_SAMPLES - 1, 1)
	for i in range(DISPLAY_SAMPLES):
		var sample_index = int(round(i * stride))
		waveform_points[i] = raw_samples[min(sample_index, display_count - 1)]
	_update_spectrum_from_samples()
	if waveform_label:
		waveform_label.text = "Waveform (first %s)" % _format_ms(display_time)
	if waveform_display:
		waveform_display.queue_redraw()
	if spectrum_display:
		spectrum_display.queue_redraw()

func _update_spectrum_from_samples():
	var sample_count = min(raw_samples.size(), SPECTRUM_SOURCE_SAMPLES)
	if sample_count <= 1:
		for i in range(SPECTRUM_BINS):
			spectrum_bins[i] = 0.0
		return
	for bin_index in range(SPECTRUM_BINS):
		var target_freq = lerp(SPECTRUM_FREQ_MIN, SPECTRUM_FREQ_MAX, float(bin_index) / float(max(SPECTRUM_BINS - 1, 1)))
		var normalized_freq = target_freq / SAMPLE_RATE
		var omega = TAU * normalized_freq
		var cos_omega = cos(omega)
		var coeff = 2.0 * cos_omega
		var q0 = 0.0
		var q1 = 0.0
		var q2 = 0.0
		for i in range(sample_count):
			var window = 0.5 - 0.5 * cos(TAU * float(i) / float(sample_count - 1))
			var value = raw_samples[i] * window
			q0 = coeff * q1 - q2 + value
			q2 = q1
			q1 = q0
		var magnitude = q1 * q1 + q2 * q2 - q1 * q2 * coeff
		spectrum_bins[bin_index] = sqrt(max(magnitude, 0.0))
	var max_value = 0.0001
	for i in range(SPECTRUM_BINS):
		max_value = max(max_value, spectrum_bins[i])
	for i in range(SPECTRUM_BINS):
		var normalized = pow(clamp(spectrum_bins[i] / max_value, 0.0, 1.0), 0.8)
		spectrum_bins[i] = normalized
	if spectrum_label:
		spectrum_label.text = "Spectrum (%.0f Hz - %.0f Hz)" % [SPECTRUM_FREQ_MIN, SPECTRUM_FREQ_MAX]

func _on_waveform_draw():
	if not waveform_display or waveform_points.is_empty():
		return
	var rect = waveform_display.get_rect()
	waveform_display.draw_rect(rect, Color(0.07, 0.08, 0.14, 1.0))
	var center_y = rect.size.y * 0.5
	waveform_display.draw_line(Vector2(0, center_y), Vector2(rect.size.x, center_y), Color(0.25, 0.3, 0.4, 0.7), 1.0)
	var point_array = PackedVector2Array()
	for i in range(waveform_points.size()):
		var x = (float(i) / max(waveform_points.size() - 1, 1)) * rect.size.x
		var y = center_y - (waveform_points[i] * rect.size.y * 0.45)
		point_array.append(Vector2(x, y))
	if point_array.size() > 1:
		var fill_points = PackedVector2Array()
		for point in point_array:
			fill_points.append(point)
		fill_points.append(Vector2(rect.size.x, center_y))
		fill_points.append(Vector2(0, center_y))
		var fill_colors = PackedColorArray()
		for _i in range(fill_points.size()):
			fill_colors.append(Color(0.2, 0.8, 0.6, 0.15))
		waveform_display.draw_polygon(fill_points, fill_colors)
		for i in range(point_array.size() - 1):
			var hue = clamp(absf(waveform_points[i]) * 0.6 + 0.35, 0.0, 1.0)
			var color = Color.from_hsv(0.32, 0.7, hue, 0.9)
			waveform_display.draw_line(point_array[i], point_array[i + 1], color, 2.0)
	var envelope_points = PackedVector2Array()
	var display_time = min(sound_length, 0.12)
	for i in range(point_array.size()):
		var ratio = float(i) / max(point_array.size() - 1, 1)
		var t = ratio * display_time
		var envelope = _compute_envelope(t)
		var y = center_y - envelope * rect.size.y * 0.45
		envelope_points.append(Vector2(ratio * rect.size.x, y))
	if envelope_points.size() > 1:
		waveform_display.draw_polyline(envelope_points, Color(1.0, 0.7, 0.2, 0.7), 1.5)
	var font = ThemeDB.fallback_font
	var font_size = 12
	waveform_display.draw_string(font, Vector2(10, 20), "Sweep %.0f ? %.0f Hz" % [freq1, freq2], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.9, 0.95, 1.0))
	waveform_display.draw_string(font, Vector2(10, rect.size.y - 10), "Attack %s  �  Release %s" % [_format_ms(attack_time), _format_ms(release_time)], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.85, 1.0))

func _on_spectrum_draw():
	if not spectrum_display or spectrum_bins.is_empty():
		return
	var rect = spectrum_display.get_rect()
	spectrum_display.draw_rect(rect, Color(0.05, 0.06, 0.12, 1.0))
	var bin_width = rect.size.x / float(SPECTRUM_BINS)
	for i in range(1, 6):
		var y = rect.size.y * (1.0 - float(i) / 6.0)
		spectrum_display.draw_line(Vector2(0, y), Vector2(rect.size.x, y), Color(0.18, 0.2, 0.3, 0.35), 1.0)
	for bin_index in range(SPECTRUM_BINS):
		var magnitude = spectrum_bins[bin_index]
		var height = magnitude * rect.size.y * 0.9
		var x = bin_width * bin_index
		var top = rect.size.y - height
		var color = Color.from_hsv(0.55 - magnitude * 0.25, 0.7, 0.85 + magnitude * 0.15, 0.9)
		spectrum_display.draw_rect(Rect2(Vector2(x + bin_width * 0.05, top), Vector2(bin_width * 0.9, height)), color)
	_draw_frequency_marker(freq1, Color(1.0, 0.65, 0.3, 1.0), rect)
	_draw_frequency_marker(freq2, Color(0.4, 0.85, 1.0, 1.0), rect)

func _draw_frequency_marker(freq: float, color: Color, rect: Rect2):
	var ratio = clamp((freq - SPECTRUM_FREQ_MIN) / (SPECTRUM_FREQ_MAX - SPECTRUM_FREQ_MIN), 0.0, 1.0)
	var x = rect.size.x * ratio
	spectrum_display.draw_line(Vector2(x, rect.size.y), Vector2(x, -4), color, 1.6)
	var font = ThemeDB.fallback_font
	var font_size = 11
	spectrum_display.draw_string(font, Vector2(clamp(x - 40, 4, rect.size.x - 60), 14), "%.0f Hz" % freq, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func update_all_labels():
	if freq1_slider:
		_on_freq1_changed(freq1_slider.value)
	if freq2_slider:
		_on_freq2_changed(freq2_slider.value)
	if volume_slider:
		_on_volume_changed(volume_slider.value)
	if length_slider:
		_on_length_changed(length_slider.value)
	if attack_slider:
		_on_attack_changed(attack_slider.value)
	if release_slider:
		_on_release_changed(release_slider.value)
	if noise_slider:
		_on_noise_changed(noise_slider.value)

func create_mario_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	if raw_samples.is_empty():
		update_waveform()
	var total_samples = raw_samples.size()
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	for i in range(total_samples):
		var clamped = clamp(raw_samples[i], -1.0, 1.0)
		var sample_int = int(clamped * 32767.0)
		data.encode_s16(i * 2, sample_int)
	stream.data = data
	return stream

func _generate_sample(t: float) -> float:
	var normalized = clamp(t / sound_length, 0.0, 1.0)
	var envelope = _compute_envelope(t)
	var sweep_freq = lerp(freq1, freq2, pow(normalized, 0.7))
	var vibrato = sin(TAU * 6.0 * t) * vibrato_amount * 40.0
	var primary = sin(TAU * (sweep_freq + vibrato) * t)
	var secondary = sin(TAU * freq2 * t)
	var harmonic = sin(TAU * freq1 * 2.0 * t) * 0.35
	var sparkle = 0.0
	if sparkle_enabled:
		var sparkle_env = pow(normalized, 2.2)
		sparkle = sin(TAU * (freq2 * 1.5 + vibrato) * t) * 0.4 * sparkle_env
	var noise = noise_amount * envelope * _pseudo_random(t * 977.0)
	var sample_value = (primary + secondary) * 0.5 + harmonic + sparkle + noise
	return clamp(sample_value * envelope * volume, -1.0, 1.0)

func _compute_envelope(t: float) -> float:
	var attack_component = 1.0
	if attack_time > 0.0:
		attack_component = clamp(t / attack_time, 0.0, 1.0)
	var release_component = 1.0
	if release_time > 0.0:
		var release_start = max(sound_length - release_time, 0.0001)
		if t >= release_start:
			release_component = clamp(1.0 - (t - release_start) / release_time, 0.0, 1.0)
	var long_fade = clamp(1.0 - t / sound_length, 0.0, 1.0)
	return clamp(pow(attack_component, 0.6) * release_component * long_fade, 0.0, 1.0)

func _pseudo_random(x: float) -> float:
	var value = sin(x) * 43758.5453
	return (value - floor(value)) * 2.0 - 1.0

func _format_ms(seconds: float) -> String:
	return "%d ms" % int(round(seconds * 1000.0))

# Public API for pickup cubes
func get_mario_sound() -> AudioStream:
	return _get_active_stream()

func get_sound_settings() -> Dictionary:
	return {
		"freq1": freq1,
		"freq2": freq2,
		"volume": volume,
		"length": sound_length,
		"attack": attack_time,
		"release": release_time,
		"noise": noise_amount,
		"sparkle_enabled": sparkle_enabled
	}

# Enhanced pickup cube that uses these simple sliders
class SimpleMarioPickupCube:
	extends Node3D
	
	@export var points_value: int = 1
	@export var rotation_speed: float = 2.0
	@export var bob_height: float = 0.2
	@export var bob_speed: float = 2.0
	
	var original_y: float
	var time_passed: float = 0.0
	var has_been_collected: bool = false
	var pickup_sound: AudioStreamPlayer3D
	
	# Reference to the simple slider control
	var mario_slider: SimpleMarioSlider
	
	func _ready() -> void:
		original_y = global_position.y
		add_to_group("mario_pickup_cubes")
		setup_pickup_sound()
		find_mario_slider()
		print("SimpleMarioPickupCube ready")
	
	func shutdown_audio() -> void:
		if pickup_sound:
			pickup_sound.stop()
		has_been_collected = true
		for player in get_children():
			if player is AudioStreamPlayer3D:
				player.stop()
	
	func _process(delta: float) -> void:
		if has_been_collected:
			return
		rotate_y(rotation_speed * delta)
		time_passed += delta
		var bob_offset = sin(time_passed * bob_speed) * bob_height
		global_position.y = original_y + bob_offset
	
	func setup_pickup_sound() -> void:
		pickup_sound = AudioStreamPlayer3D.new()
		add_child(pickup_sound)
		pickup_sound.unit_size = 2.0
		pickup_sound.max_distance = 20.0
		pickup_sound.volume_db = -6.0
		pickup_sound.stream = PickupCube.get_shared_pickup_stream()
	
	func find_mario_slider() -> void:
		mario_slider = get_tree().get_first_node_in_group("mario_slider_control")
		if not mario_slider:
			print("Warning: No SimpleMarioSlider found in scene")
	
	func collect() -> void:
		if has_been_collected:
			return
		has_been_collected = true
		var dynamic_sound: AudioStream = null
		if mario_slider:
			dynamic_sound = mario_slider.get_mario_sound()
			var settings = mario_slider.get_sound_settings()
			pickup_sound.volume_db = lerp(-20.0, 0.0, clamp(settings.volume, 0.0, 1.0))
		else:
			dynamic_sound = create_default_mario_sound()
		var sound_clone = AudioStreamPlayer3D.new()
		get_tree().root.add_child(sound_clone)
		sound_clone.stream = dynamic_sound
		sound_clone.global_position = global_position
		sound_clone.volume_db = pickup_sound.volume_db
		sound_clone.play()
		if mario_slider:
			mario_slider._register_external_player(sound_clone)
			sound_clone.finished.connect(func():
				if mario_slider:
					mario_slider._unregister_external_player(sound_clone)
				sound_clone.queue_free())
		else:
			sound_clone.finished.connect(func(): sound_clone.queue_free())
		GameManager.add_points(points_value, global_position)
		_play_collection_effect()
		await get_tree().create_timer(0.1).timeout
		queue_free()
	
	func create_default_mario_sound() -> AudioStream:
		return PickupCube.get_default_pickup_stream()


	func _play_collection_effect():
		var mesh_instance = find_child("CubeBaseMesh", true, false)
		if mesh_instance:
			var tween = create_tween()
			tween.parallel().tween_property(mesh_instance, "scale", mesh_instance.scale * 1.5, 0.2)
			tween.parallel().tween_property(mesh_instance, "modulate", Color.TRANSPARENT, 0.2)
	
	func _on_detection_area_body_entered(body: Node3D) -> void:
		if _is_player(body):
			collect()
	
	func _is_player(body: Node3D) -> bool:
		return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player")
