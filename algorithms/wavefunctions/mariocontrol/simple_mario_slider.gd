# simple_mario_slider.gd
extends Node3D

class_name SimpleMarioSlider


# VR UI Elements
var freq1_slider: Node3D
var freq1_label: Label3D
var freq2_slider: Node3D
var freq2_label: Label3D
var volume_slider: Node3D
var volume_label: Label3D
var length_slider: Node3D
var length_label: Label3D
var attack_slider: Node3D
var attack_label: Label3D
var release_slider: Node3D
var release_label: Label3D
var noise_slider: Node3D
var noise_label: Label3D
var sparkle_toggle_btn: Node3D
var sparkle_label: Label3D
var test_button: Node3D
var randomize_button: Node3D
var reset_button: Node3D

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

# Slider parameter ranges for normalization
var _slider_ranges := {
	"freq1": {"min": 200.0, "max": 2000.0},
	"freq2": {"min": 400.0, "max": 3200.0},
	"volume": {"min": 0.0, "max": 1.0},
	"length": {"min": 0.1, "max": 0.5},
	"attack": {"min": 0.0, "max": 0.08},
	"release": {"min": 0.03, "max": 0.3},
	"noise": {"min": 0.0, "max": 0.3},
}

func _ready() -> void:
	rng.randomize()
	_build_vr_ui()
	create_audio_player()
	setup_visualizations()
	update_all_labels()
	add_to_group("audio_emitters")
	update_waveform()

func _build_vr_ui() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("MARIO CTRL", [
		[{"type": "slider_h", "label": "FREQ1", "default": _normalize("freq1", freq1)}],
		[{"type": "slider_h", "label": "FREQ2", "default": _normalize("freq2", freq2)}],
		[{"type": "slider_h", "label": "VOL", "default": _normalize("volume", volume)}],
		[{"type": "slider_h", "label": "LEN", "default": _normalize("length", sound_length)}],
		[{"type": "slider_h", "label": "ATK", "default": _normalize("attack", attack_time)}],
		[{"type": "slider_h", "label": "REL", "default": _normalize("release", release_time)}],
		[{"type": "slider_h", "label": "NOISE", "default": _normalize("noise", noise_amount)}],
		[{"type": "button", "label": "SPARKLE"}, {"type": "button", "label": "TEST"},
		 {"type": "button", "label": "RANDOM"}, {"type": "button", "label": "RESET"}],
	])
	panel.position = Vector3(0, 0.2, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Extract slider refs
	freq1_slider = panel.find_child("Param_0", true, false)
	freq2_slider = panel.find_child("Param_1", true, false)
	volume_slider = panel.find_child("Param_2", true, false)
	length_slider = panel.find_child("Param_3", true, false)
	attack_slider = panel.find_child("Param_4", true, false)
	release_slider = panel.find_child("Param_5", true, false)
	noise_slider = panel.find_child("Param_6", true, false)

	# Connect slider signals
	if freq1_slider and freq1_slider.has_signal("slider_moved"):
		freq1_slider.slider_moved.connect(_on_freq1_slider_moved)
	if freq2_slider and freq2_slider.has_signal("slider_moved"):
		freq2_slider.slider_moved.connect(_on_freq2_slider_moved)
	if volume_slider and volume_slider.has_signal("slider_moved"):
		volume_slider.slider_moved.connect(_on_volume_slider_moved)
	if length_slider and length_slider.has_signal("slider_moved"):
		length_slider.slider_moved.connect(_on_length_slider_moved)
	if attack_slider and attack_slider.has_signal("slider_moved"):
		attack_slider.slider_moved.connect(_on_attack_slider_moved)
	if release_slider and release_slider.has_signal("slider_moved"):
		release_slider.slider_moved.connect(_on_release_slider_moved)
	if noise_slider and noise_slider.has_signal("slider_moved"):
		noise_slider.slider_moved.connect(_on_noise_slider_moved)

	# Connect buttons
	sparkle_toggle_btn = panel.find_child("Btn_0", true, false)
	if sparkle_toggle_btn:
		var area = sparkle_toggle_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_sparkle_pressed)

	test_button = panel.find_child("Btn_1", true, false)
	if test_button:
		var area = test_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_test_pressed)

	randomize_button = panel.find_child("Btn_2", true, false)
	if randomize_button:
		var area = randomize_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_randomize_pressed)

	reset_button = panel.find_child("Btn_3", true, false)
	if reset_button:
		var area = reset_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_on_reset_pressed)

	# Value labels
	freq1_label = _make_label("Frequency 1: %.0f Hz" % freq1)
	freq2_label = _make_label("Frequency 2: %.0f Hz" % freq2)
	volume_label = _make_label("Volume: %.2f" % volume)
	length_label = _make_label("Length: %.2fs" % sound_length)
	attack_label = _make_label("Attack: %s" % _format_ms(attack_time))
	release_label = _make_label("Release: %s" % _format_ms(release_time))
	noise_label = _make_label("Noise Sparkle: %d%%" % int(round(noise_amount * 100.0)))
	sparkle_label = _make_label("Sparkle: ON" if sparkle_enabled else "Sparkle: OFF")

func _make_label(text: String) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = 24
	label.modulate = Color(0.85, 0.9, 1.0)
	label.visible = false  # Labels tracked internally for update_all_labels
	add_child(label)
	return label

func _set_slider_value(slider: Node3D, norm_value: float) -> void:
	if slider.has_method("set_normalized_value"):
		slider.set_normalized_value(clamp(norm_value, 0.0, 1.0))

func _get_slider_value(slider: Node3D) -> float:
	if slider and slider.has_method("get_normalized_value"):
		return slider.get_normalized_value()
	return 0.0

func _normalize(param: String, value: float) -> float:
	var r = _slider_ranges.get(param, {"min": 0.0, "max": 1.0})
	var range_size = r["max"] - r["min"]
	if range_size <= 0.0:
		return 0.0
	return clamp((value - r["min"]) / range_size, 0.0, 1.0)

func _denormalize(param: String, norm: float) -> float:
	var r = _slider_ranges.get(param, {"min": 0.0, "max": 1.0})
	return lerp(r["min"], r["max"], clamp(norm, 0.0, 1.0))

func setup_visualizations() -> void:
	waveform_points.resize(DISPLAY_SAMPLES)
	spectrum_bins.resize(SPECTRUM_BINS)

func create_audio_player() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.bus = "Master"

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
	_set_slider_value(freq1_slider, _normalize("freq1", freq1))
	_set_slider_value(freq2_slider, _normalize("freq2", freq2))
	_set_slider_value(volume_slider, _normalize("volume", volume))
	_set_slider_value(length_slider, _normalize("length", sound_length))
	_set_slider_value(attack_slider, _normalize("attack", attack_time))
	_set_slider_value(release_slider, _normalize("release", release_time))
	_set_slider_value(noise_slider, _normalize("noise", noise_amount))

func _get_active_stream() -> AudioStream:
	if use_custom_stream and custom_stream:
		return custom_stream
	if _parameters_match_defaults():
		return PickupCube.get_shared_pickup_stream()
	update_waveform()
	return create_mario_sound()

# -- VR slider callbacks (normalized 0..1) --

func _on_freq1_slider_moved(_value: float = 0.0) -> void:
	_clear_custom_stream_if_needed()
	freq1 = _denormalize("freq1", _get_slider_value(freq1_slider))
	if freq1_label:
		freq1_label.text = "Frequency 1: %.0f Hz" % freq1
	update_waveform()

func _on_freq2_slider_moved(_value: float = 0.0) -> void:
	_clear_custom_stream_if_needed()
	freq2 = _denormalize("freq2", _get_slider_value(freq2_slider))
	if freq2_label:
		freq2_label.text = "Frequency 2: %.0f Hz" % freq2
	update_waveform()

func _on_volume_slider_moved(_value: float = 0.0) -> void:
	_clear_custom_stream_if_needed()
	volume = _denormalize("volume", _get_slider_value(volume_slider))
	if volume_label:
		volume_label.text = "Volume: %.2f" % volume
	update_waveform()

func _on_length_slider_moved(_value: float = 0.0) -> void:
	_clear_custom_stream_if_needed()
	sound_length = clamp(_denormalize("length", _get_slider_value(length_slider)), 0.05, 1.0)
	if length_label:
		length_label.text = "Length: %.2fs" % sound_length
	_ensure_envelope_within_bounds()
	update_waveform()

func _on_attack_slider_moved(_value: float = 0.0) -> void:
	_clear_custom_stream_if_needed()
	attack_time = clamp(_denormalize("attack", _get_slider_value(attack_slider)), 0.0, 0.2)
	if attack_label:
		attack_label.text = "Attack: %s" % _format_ms(attack_time)
	_adjust_release_if_needed()
	update_waveform()

func _on_release_slider_moved(_value: float = 0.0) -> void:
	_clear_custom_stream_if_needed()
	release_time = clamp(_denormalize("release", _get_slider_value(release_slider)), 0.0, 0.5)
	if release_label:
		release_label.text = "Release: %s" % _format_ms(release_time)
	_adjust_attack_if_needed()
	update_waveform()

func _on_noise_slider_moved(_value: float = 0.0) -> void:
	_clear_custom_stream_if_needed()
	noise_amount = clamp(_denormalize("noise", _get_slider_value(noise_slider)), 0.0, 1.0)
	if noise_label:
		noise_label.text = "Noise Sparkle: %d%%" % int(round(noise_amount * 100.0))
	update_waveform()

func _on_sparkle_pressed() -> void:
	_clear_custom_stream_if_needed()
	sparkle_enabled = not sparkle_enabled
	if sparkle_label:
		sparkle_label.text = "Sparkle: ON" if sparkle_enabled else "Sparkle: OFF"
	update_waveform()

func _on_test_pressed() -> void:
	var stream = _get_active_stream()
	_apply_stream_to_audio_player(stream)
	audio_player.play()
	_apply_stream_to_pickups(stream)

func _on_randomize_pressed() -> void:
	_clear_custom_stream_if_needed()
	rng.randomize()
	freq1 = rng.randf_range(420.0, 980.0)
	freq2 = freq1 + rng.randf_range(280.0, 620.0)
	volume = rng.randf_range(0.45, 0.85)
	sound_length = rng.randf_range(0.16, 0.28)
	attack_time = rng.randf_range(0.0, 0.035)
	release_time = rng.randf_range(0.09, 0.18)
	noise_amount = rng.randf_range(0.02, 0.14)
	sparkle_enabled = rng.randf() > 0.2
	_set_slider_value(freq1_slider, _normalize("freq1", freq1))
	_set_slider_value(freq2_slider, _normalize("freq2", freq2))
	_set_slider_value(volume_slider, _normalize("volume", volume))
	_set_slider_value(length_slider, _normalize("length", sound_length))
	_set_slider_value(attack_slider, _normalize("attack", attack_time))
	_set_slider_value(release_slider, _normalize("release", release_time))
	_set_slider_value(noise_slider, _normalize("noise", noise_amount))
	update_all_labels()
	update_waveform()

func _on_reset_pressed() -> void:
	use_custom_stream = false
	custom_stream = null
	_apply_default_settings()
	update_all_labels()
	update_waveform()
	var stream = PickupCube.reset_shared_pickup_stream()
	original_stream = stream
	_apply_stream_to_audio_player(stream)

func _ensure_envelope_within_bounds() -> void:
	var max_total = max(sound_length - 0.01, 0.02)
	var total = attack_time + release_time
	if total <= max_total:
		return
	release_time = clamp(max_total - attack_time, 0.0, max_total)
	_set_slider_value(release_slider, _normalize("release", release_time))

func shutdown_audio() -> void:
	if audio_player:
		audio_player.stop()
	for player in external_players.duplicate():
		if is_instance_valid(player):
			player.stop()
		_unregister_external_player(player)
	for cube in get_tree().get_nodes_in_group("mario_pickup_cubes"):
		if cube.has_method("shutdown_audio"):
			cube.shutdown_audio()

func _register_external_player(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player in external_players:
		return
	external_players.append(player)
	if player.has_signal("finished"):
		player.finished.connect(Callable(self, "_on_external_player_finished").bind(player), CONNECT_ONE_SHOT)

func _on_external_player_finished(player: AudioStreamPlayer) -> void:
	_unregister_external_player(player)

func _unregister_external_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	if player in external_players:
		external_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()

func _adjust_release_if_needed() -> void:
	var max_total = max(sound_length - 0.01, 0.02)
	if attack_time + release_time > max_total:
		release_time = clamp(max_total - attack_time, 0.0, max_total)
		_set_slider_value(release_slider, _normalize("release", release_time))
		if release_label:
			release_label.text = "Release: %s" % _format_ms(release_time)

func _adjust_attack_if_needed() -> void:
	var max_total = max(sound_length - 0.01, 0.02)
	if attack_time + release_time > max_total:
		attack_time = clamp(max_total - release_time, 0.0, max_total)
		_set_slider_value(attack_slider, _normalize("attack", attack_time))
		if attack_label:
			attack_label.text = "Attack: %s" % _format_ms(attack_time)

func update_waveform() -> void:
	if use_custom_stream and custom_stream:
		for i in range(waveform_points.size()):
			waveform_points[i] = 0.0
		for i in range(spectrum_bins.size()):
			spectrum_bins[i] = 0.0
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

func _update_spectrum_from_samples() -> void:
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

func update_all_labels() -> void:
	if freq1_label:
		freq1_label.text = "Frequency 1: %.0f Hz" % freq1
	if freq2_label:
		freq2_label.text = "Frequency 2: %.0f Hz" % freq2
	if volume_label:
		volume_label.text = "Volume: %.2f" % volume
	if length_label:
		length_label.text = "Length: %.2fs" % sound_length
	if attack_label:
		attack_label.text = "Attack: %s" % _format_ms(attack_time)
	if release_label:
		release_label.text = "Release: %s" % _format_ms(release_time)
	if noise_label:
		noise_label.text = "Noise Sparkle: %d%%" % int(round(noise_amount * 100.0))
	if sparkle_label:
		sparkle_label.text = "Sparkle: ON" if sparkle_enabled else "Sparkle: OFF"

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


	func _play_collection_effect() -> void:
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

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	if audio_player:
		audio_player.stop()
	for child in get_children():
		if not child.owner:
			child.queue_free()
