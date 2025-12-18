extends Node3D

## Universal Sound Controller
## Generalized version of MarioSoundController supporting multiple sound modes
## Controls various synthesis parameters via a 3D ball (ValueMapper3D)

# Load PickupCube class to access static functions for Mario mode compatibility
const PickupCube = preload("res://commons/scenes/mapobjects/pick_up_cube.gd")

enum SoundMode { MARIO, SINE_BELL, LASER_ZAP, TECHNO_KICK, NOISE_BURST }

@export var mode: SoundMode = SoundMode.MARIO:
	set(v):
		mode = v
		if is_inside_tree():
			_update_mapper_config()

@onready var value_mapper = $ValueMapper3D
@onready var audio_player = $AudioStreamPlayer3D

# Internal parameters (names adapted per mode)
var p1: float = 440.0 # Typically Freq/Start
var p2: float = 880.0 # Typically End/Mod
var p3: float = 8.0   # Typically Decay/Speed

# Audio settings
const SAMPLE_RATE = 44100
var sound_duration: float = 0.5

# Continuous playback settings
var play_on_move: bool = true
var last_play_time: float = 0.0
var min_play_interval: float = 0.6
var last_ball_position: Vector3 = Vector3.ZERO
var movement_threshold: float = 0.01

# Auto-save settings
var auto_save_timer: Timer
var save_interval: float = 3.0

var preview_cube: MeshInstance3D
var grab_sphere: Node3D

func _ready() -> void:
	_create_preview_cube()
	_setup_auto_save_timer()
	_update_mapper_config()

	if value_mapper:
		value_mapper.values_changed.connect(_on_values_changed)
		var initial = value_mapper.get_values()
		_on_values_changed(initial.x, initial.y, initial.z)
		
		grab_sphere = value_mapper.get_node_or_null("SpacePoint")
		if grab_sphere:
			last_ball_position = grab_sphere.global_position

func _process(_delta: float) -> void:
	if not play_on_move or not grab_sphere:
		return

	var current_pos = grab_sphere.global_position
	if current_pos.distance_to(last_ball_position) > movement_threshold:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_play_time >= min_play_interval:
			play_sound()
			last_play_time = current_time
		last_ball_position = current_pos

func _update_mapper_config():
	if not value_mapper: return
	
	match mode:
		SoundMode.MARIO:
			value_mapper.label_x = "Freq Start"; value_mapper.output_x_min = 200; value_mapper.output_x_max = 800
			value_mapper.label_y = "Freq End"; value_mapper.output_y_min = 400; value_mapper.output_y_max = 1200
			value_mapper.label_z = "Decay Rate"; value_mapper.output_z_min = 2.0; value_mapper.output_z_max = 12.0
		SoundMode.SINE_BELL:
			value_mapper.label_x = "Base Freq"; value_mapper.output_x_min = 100; value_mapper.output_x_max = 2000
			value_mapper.label_y = "Hardness"; value_mapper.output_y_min = 0.0; value_mapper.output_y_max = 1.0
			value_mapper.label_z = "Ring Time"; value_mapper.output_z_min = 0.5; value_mapper.output_z_max = 5.0
		SoundMode.LASER_ZAP:
			value_mapper.label_x = "Pitch"; value_mapper.output_x_min = 400; value_mapper.output_x_max = 3000
			value_mapper.label_y = "Drop"; value_mapper.output_y_min = 50;  value_mapper.output_y_max = 500
			value_mapper.label_z = "Speed"; value_mapper.output_z_min = 5.0; value_mapper.output_z_max = 30.0
		SoundMode.TECHNO_KICK:
			value_mapper.label_x = "Bass Freq"; value_mapper.output_x_min = 40;  value_mapper.output_x_max = 100
			value_mapper.label_y = "Punch"; value_mapper.output_y_min = 0.1; value_mapper.output_y_max = 2.0
			value_mapper.label_z = "Thump"; value_mapper.output_z_min = 2.0; value_mapper.output_z_max = 20.0
		SoundMode.NOISE_BURST:
			value_mapper.label_x = "Tone"; value_mapper.output_x_min = 100; value_mapper.output_x_max = 5000
			value_mapper.label_y = "Harshness"; value_mapper.output_y_min = 0.1; value_mapper.output_y_max = 1.0
			value_mapper.label_z = "Length"; value_mapper.output_z_min = 0.05; value_mapper.output_z_max = 0.5

	if value_mapper.has_method("update_labels"):
		value_mapper.call("update_labels")
	else:
		# Fallback: Manually update labels if method missing
		var x_l = value_mapper.get_node_or_null("XLabel")
		var y_l = value_mapper.get_node_or_null("YLabel")
		var z_l = value_mapper.get_node_or_null("ZLabel")
		if x_l: x_l.text = value_mapper.label_x
		if y_l: y_l.text = value_mapper.label_y
		if z_l: z_l.text = value_mapper.label_z
	
	# Force an update of the output text
	if value_mapper.has_method("_update_output"):
		value_mapper.call("_update_output")

func apply_grid_config(data: Dictionary):
	print("UniversalSound: Config received: %s" % data)
	if data.has("mode"):
		var m_str = data.mode.to_upper()
		if SoundMode.has(m_str): mode = SoundMode[m_str]
	if data.has("freq_start"): p1 = float(data.freq_start)
	if data.has("freq_end"): p2 = float(data.freq_end)
	if data.has("decay"): p3 = float(data.decay)
	_update_mapper_config()

func _on_values_changed(x: float, y: float, z: float) -> void:
	p1 = x; p2 = y; p3 = z
	if preview_cube:
		var mat = preview_cube.material_override as StandardMaterial3D
		if mat:
			var hue = 0.0
			match mode:
				SoundMode.MARIO: hue = 0.1 # Orange
				SoundMode.SINE_BELL: hue = 0.6 # Blue
				SoundMode.LASER_ZAP: hue = 0.8 # Purple
				SoundMode.TECHNO_KICK: hue = 0.0 # Red
				SoundMode.NOISE_BURST: hue = 0.3 # Green
			mat.albedo_color = Color.from_hsv(hue, 0.7, 0.9)
			mat.emission = mat.albedo_color * 0.5

func play_sound() -> void:
	var stream = _generate_sound()
	audio_player.stream = stream
	audio_player.play()
	_pulse_preview_cube()

func _generate_sound() -> AudioStreamWAV:
	var duration = sound_duration
	if mode == SoundMode.SINE_BELL: duration = p3
	elif mode == SoundMode.NOISE_BURST: duration = p3
	
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var sample_value = 0.0

		match mode:
			SoundMode.MARIO:
				var freq = p1 + ((p2 - p1) * progress)
				var env = exp(-progress * p3)
				sample_value = (1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0) * env * 0.3
			
			SoundMode.SINE_BELL:
				var freq = p1
				var env = exp(-progress * (5.0 / p3)) # Z maps to Ring Time
				# Add subtle harmonic based on p2 (Hardness)
				sample_value = sin(2.0 * PI * freq * t) * env * 0.4
				if p2 > 0.1:
					sample_value += sin(4.0 * PI * freq * t) * env * p2 * 0.2
			
			SoundMode.LASER_ZAP:
				var freq = p1 * exp(-progress * p3) # Exponential drop
				sample_value = (2.0 * (freq * t - floor(freq * t + 0.5))) * 0.3 # Sawtooth
			
			SoundMode.TECHNO_KICK:
				var freq = p1 * exp(-progress * p3) + 20.0
				var env = pow(1.0 - progress, p2) # Punch defines curve
				sample_value = sin(2.0 * PI * freq * t) * env * 0.6
			
			SoundMode.NOISE_BURST:
				var raw_noise = randf_range(-1.0, 1.0)
				# Simple low-pass like effect using p1 (Tone)
				var env = 1.0 - progress
				sample_value = raw_noise * env * 0.5

		var sample_int = int(clamp(sample_value, -1.0, 1.0) * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

func _create_preview_cube():
	preview_cube = MeshInstance3D.new()
	preview_cube.mesh = BoxMesh.new(); preview_cube.mesh.size = Vector3(0.2, 0.2, 0.2)
	preview_cube.position = Vector3(0, -0.5, 0)
	preview_cube.material_override = StandardMaterial3D.new()
	preview_cube.material_override.emission_enabled = true
	add_child(preview_cube)
	
	var label = Label3D.new()
	label.text = "Universal Sound"; label.position = Vector3(0, -0.65, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.font_size = 24
	label.scale = Vector3.ONE * 0.08
	add_child(label)

func _pulse_preview_cube():
	if not preview_cube: return
	var tween = create_tween()
	tween.tween_property(preview_cube, "scale", Vector3.ONE * 1.5, 0.1)
	tween.tween_property(preview_cube, "scale", Vector3.ONE, 0.4)

func _setup_auto_save_timer():
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = save_interval; auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(auto_save_timer)

func _on_auto_save_timeout():
	if mode == SoundMode.MARIO:
		PickupCube.set_shared_mario_parameters(p1, p2, p3, sound_duration)
