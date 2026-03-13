extends Node3D

## DualBall FM Sound Controller
## Two 3D balls control 6 FM synthesis parameters
## Ball 1 (Blue): Carrier - Frequency, Attack, Decay
## Ball 2 (Orange): Modulator - Ratio, Index, Mod Decay

@onready var carrier_mapper = $Ball1_Carrier
@onready var modulator_mapper = $Ball2_Modulator
@onready var audio_player = $AudioStreamPlayer3D

# FM Synthesis Parameters
# Ball 1 - Carrier (Blue)
var carrier_freq: float = 440.0  # Hz (100-2000)
var attack_time: float = 0.05   # seconds (0.01-0.5)
var decay_time: float = 1.0     # seconds (0.1-3.0)

# Ball 2 - Modulator (Orange)
var mod_ratio: float = 2.0      # × carrier freq (0.5-8.0)
var mod_index: float = 3.0      # depth (0.0-10.0)
var mod_decay: float = 0.5      # seconds (0.1-2.0)

# Audio settings
const SAMPLE_RATE = 44100
var sound_duration: float = 2.0

# Movement detection
var play_on_move: bool = true
var last_play_time: float = 0.0
var min_play_interval: float = 0.3
var last_carrier_pos: Vector3 = Vector3.ZERO
var last_mod_pos: Vector3 = Vector3.ZERO
var movement_threshold: float = 0.01

var preview_cube: MeshInstance3D
var carrier_ball: Node3D
var modulator_ball: Node3D
var title_label: Label3D

func _ready() -> void:
	_create_preview_cube()
	_create_title_label()
	_setup_carrier_mapper()
	_setup_modulator_mapper()
	
	# Connect signals
	if carrier_mapper:
		carrier_mapper.values_changed.connect(_on_carrier_changed)
		var initial = carrier_mapper.get_values()
		_on_carrier_changed(initial.x, initial.y, initial.z)
		carrier_ball = carrier_mapper.get_node_or_null("SpacePoint")
		if carrier_ball:
			last_carrier_pos = carrier_ball.global_position
			_color_ball(carrier_ball, Color(0.2, 0.4, 1.0))  # Blue
	
	if modulator_mapper:
		modulator_mapper.values_changed.connect(_on_modulator_changed)
		var initial = modulator_mapper.get_values()
		_on_modulator_changed(initial.x, initial.y, initial.z)
		modulator_ball = modulator_mapper.get_node_or_null("SpacePoint")
		if modulator_ball:
			last_mod_pos = modulator_ball.global_position
			_color_ball(modulator_ball, Color(1.0, 0.5, 0.1))  # Orange

func _color_ball(ball: Node3D, color: Color) -> void:
	# Find the MeshInstance3D in the ball and color it
	for child in ball.get_children():
		if child is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.emission_enabled = true
			mat.emission = color * 0.3
			child.material_override = mat
			break

func _setup_carrier_mapper() -> void:
	if not carrier_mapper:
		return
	
	# Ball 1: Carrier parameters
	carrier_mapper.label_x = "Carrier Hz"
	carrier_mapper.output_x_min = 100.0
	carrier_mapper.output_x_max = 2000.0
	
	carrier_mapper.label_y = "Attack"
	carrier_mapper.output_y_min = 0.01
	carrier_mapper.output_y_max = 0.5
	
	carrier_mapper.label_z = "Decay"
	carrier_mapper.output_z_min = 0.1
	carrier_mapper.output_z_max = 3.0
	
	# Blue axis colors for carrier
	carrier_mapper.axis_color_x = Color(0.3, 0.5, 1.0)
	carrier_mapper.axis_color_y = Color(0.4, 0.6, 1.0)
	carrier_mapper.axis_color_z = Color(0.5, 0.7, 1.0)

func _setup_modulator_mapper() -> void:
	if not modulator_mapper:
		return
	
	# Ball 2: Modulator parameters
	modulator_mapper.label_x = "Mod Ratio"
	modulator_mapper.output_x_min = 0.5
	modulator_mapper.output_x_max = 8.0
	
	modulator_mapper.label_y = "Mod Index"
	modulator_mapper.output_y_min = 0.0
	modulator_mapper.output_y_max = 10.0
	
	modulator_mapper.label_z = "Mod Decay"
	modulator_mapper.output_z_min = 0.1
	modulator_mapper.output_z_max = 2.0
	
	# Orange axis colors for modulator
	modulator_mapper.axis_color_x = Color(1.0, 0.5, 0.2)
	modulator_mapper.axis_color_y = Color(1.0, 0.6, 0.3)
	modulator_mapper.axis_color_z = Color(1.0, 0.7, 0.4)

func _process(_delta: float) -> void:
	if not play_on_move:
		return
	
	var should_play = false
	
	# Check carrier ball movement
	if carrier_ball:
		var current_pos = carrier_ball.global_position
		if current_pos.distance_to(last_carrier_pos) > movement_threshold:
			should_play = true
			last_carrier_pos = current_pos
	
	# Check modulator ball movement
	if modulator_ball:
		var current_pos = modulator_ball.global_position
		if current_pos.distance_to(last_mod_pos) > movement_threshold:
			should_play = true
			last_mod_pos = current_pos
	
	if should_play:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_play_time >= min_play_interval:
			play_sound()
			last_play_time = current_time

func _on_carrier_changed(x: float, y: float, z: float) -> void:
	carrier_freq = x
	attack_time = y
	decay_time = z
	_update_preview_cube()

func _on_modulator_changed(x: float, y: float, z: float) -> void:
	mod_ratio = x
	mod_index = y
	mod_decay = z
	_update_preview_cube()

func play_sound() -> void:
	var stream = _generate_fm_sound()
	audio_player.stream = stream
	audio_player.play()
	_pulse_preview_cube()

func _generate_fm_sound() -> AudioStreamWAV:
	# Use decay_time as base duration, but cap it
	var duration = min(decay_time * 1.2, 3.0)
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Attack envelope (linear ramp up)
		var attack_env = 1.0
		if t < attack_time:
			attack_env = t / attack_time
		
		# Decay envelope (exponential decay after attack)
		var decay_env = 1.0
		if t > attack_time:
			decay_env = exp(-(t - attack_time) / decay_time)
		
		# Modulator envelope (exponential decay)
		var mod_env = exp(-t / mod_decay)
		
		# FM synthesis
		# Modulator: sin(2π × carrier_freq × mod_ratio × t) × mod_index × mod_env
		var modulator_freq = carrier_freq * mod_ratio
		var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
		
		# Carrier with phase modulation
		var carrier_env = attack_env * decay_env
		var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
		
		# Soft clipping to prevent harsh distortion at high mod index
		output = tanh(output * 0.8) * 0.5
		
		var sample_int = int(clamp(output, -1.0, 1.0) * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream

func _create_preview_cube() -> void:
	preview_cube = MeshInstance3D.new()
	preview_cube.name = "PreviewCube"
	var box = BoxMesh.new()
	box.size = Vector3(0.25, 0.25, 0.25)
	preview_cube.mesh = box
	preview_cube.position = Vector3(0, -0.8, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.2, 0.5)
	preview_cube.material_override = mat
	
	add_child(preview_cube)

func _create_title_label() -> void:
	title_label = Label3D.new()
	title_label.name = "TitleLabel"
	title_label.text = "FM Synth"
	title_label.position = Vector3(0, -1.0, 0)
	title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_label.font_size = 32
	title_label.modulate = Color(0.9, 0.9, 1.0)
	title_label.outline_size = 4
	title_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	title_label.scale = Vector3.ONE * 0.08
	add_child(title_label)

func _update_preview_cube() -> void:
	if not preview_cube:
		return
	
	var mat = preview_cube.material_override as StandardMaterial3D
	if not mat:
		return
	
	# Color based on sound character:
	# - Hue shifts with mod_ratio (bell-like at integers)
	# - Saturation increases with mod_index
	# - Value tied to carrier frequency
	
	var hue = fmod(mod_ratio / 8.0, 1.0)
	var sat = clamp(mod_index / 10.0, 0.3, 1.0)
	var val = clamp(carrier_freq / 2000.0 * 0.5 + 0.5, 0.5, 1.0)
	
	var color = Color.from_hsv(hue, sat, val)
	mat.albedo_color = color
	mat.emission = color * (0.3 + mod_index * 0.05)

func _pulse_preview_cube() -> void:
	if not preview_cube:
		return
	
	var tween = create_tween()
	tween.tween_property(preview_cube, "scale", Vector3.ONE * 1.6, 0.08)
	tween.tween_property(preview_cube, "scale", Vector3.ONE, 0.5).set_ease(Tween.EASE_OUT)

# Preset methods for quick sound design
func set_bell_preset() -> void:
	# Classic bell: integer ratio, medium index
	if carrier_mapper:
		carrier_mapper.set_values(880.0, 0.01, 2.0)
	if modulator_mapper:
		modulator_mapper.set_values(3.0, 4.0, 1.0)

func set_electric_piano_preset() -> void:
	# E-piano: ratio ~1, moderate index with fast mod decay
	if carrier_mapper:
		carrier_mapper.set_values(440.0, 0.01, 1.5)
	if modulator_mapper:
		modulator_mapper.set_values(1.0, 3.5, 0.3)

func set_brass_preset() -> void:
	# Brass-like: higher ratio, slow attack
	if carrier_mapper:
		carrier_mapper.set_values(220.0, 0.15, 1.0)
	if modulator_mapper:
		modulator_mapper.set_values(1.0, 5.0, 0.8)

func set_metallic_preset() -> void:
	# Metallic/harsh: non-integer ratio, high index
	if carrier_mapper:
		carrier_mapper.set_values(300.0, 0.01, 2.0)
	if modulator_mapper:
		modulator_mapper.set_values(1.414, 8.0, 0.15)

func get_current_params() -> Dictionary:
	return {
		"carrier_freq": carrier_freq,
		"attack_time": attack_time,
		"decay_time": decay_time,
		"mod_ratio": mod_ratio,
		"mod_index": mod_index,
		"mod_decay": mod_decay
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

