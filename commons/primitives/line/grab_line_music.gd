extends GrabLine
class_name GrabLineMusic

# @identity
# essence: a GrabLine that sonifies itself — tip velocity drives volume, line length maps to pitch (base_frequency + length*range) through a live AudioStreamGenerator with selectable waveform and vibrato
# desire: to let the learner HEAR a line's two properties at once — how fast the hand moves (loudness) and how long the line is (pitch) — binding metric to sound
# critical_parameter: base_frequency/frequency_range (220Hz + 880Hz) — the pitch window the line's length is mapped onto; it decides whether stretching the line whispers or shrieks
# triggers: _process reads tip velocity and line length each frame; the generator playback is filled with the chosen waveform at the mapped frequency; movement above min_velocity_for_sound opens the volume
# emerges: that measurement and sensation are interchangeable — a number (length) becomes a frequency you feel in the body, closing the loop grab_line opened with its length label
# needs: real-time synthesis [has]; velocity->volume and length->pitch [has]; 4 waveforms plus vibrato [has]; apply_grid_config [missing]; scale-quantized pitch [missing — continuous glissando only]
# relationships: extends grab_line (gives the endpoint a voice); the sounding verb beside grab_line_drawer (marks) and grab_line_pusher (touches); turns the line primitive into a synthesizer
# truth: a length is already a pitch — the line was singing before we gave it a speaker

## GrabLine variant that produces music based on tip movement and line length

@export_group("Sound Settings")
@export var base_frequency: float = 220.0
@export var frequency_range: float = 880.0
@export var volume_db: float = -6.0
@export var min_velocity_for_sound: float = 0.1
@export var velocity_to_volume_scale: float = 2.0

@export_group("Waveform")
@export_enum("Sine", "Square", "Sawtooth", "Triangle") var waveform: int = 0
@export var enable_vibrato: bool = true
@export var vibrato_rate: float = 5.0
@export var vibrato_depth: float = 0.02

@export_group("Visual Feedback")
@export var glow_with_sound: bool = true
@export var music_tip_color_active: Color = Color(1.0, 0.2, 0.8, 1.0)
@export var music_tip_color_idle: Color = Color(0.5, 0.1, 0.4, 1.0)

var _audio_player: AudioStreamPlayer3D
var _audio_generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _last_tip_position: Vector3
var _current_velocity: float = 0.0
var _music_tip_mesh: MeshInstance3D
var _music_tip_light: OmniLight3D
var _vibrato_phase: float = 0.0

func _ready() -> void:
	super()
	_setup_audio()
	_setup_music_tip()
	_last_tip_position = get_tip_position()

func _setup_audio() -> void:
	_audio_generator = AudioStreamGenerator.new()
	_audio_generator.mix_rate = 44100.0
	_audio_generator.buffer_length = 0.1

	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "MusicPlayer"
	_audio_player.stream = _audio_generator
	_audio_player.volume_db = -80.0
	_audio_player.unit_size = 3.0
	_audio_player.max_distance = 10.0
	add_child(_audio_player)
	_audio_player.play()

	await get_tree().process_frame
	_playback = _audio_player.get_stream_playback()

func _setup_music_tip() -> void:
	if not _tip_marker:
		return

	_music_tip_mesh = MeshInstance3D.new()
	_music_tip_mesh.name = "MusicTipMesh"
	var sphere = SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	_music_tip_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = music_tip_color_idle
	mat.emission_enabled = true
	mat.emission = music_tip_color_idle
	mat.emission_energy_multiplier = 1.0
	_music_tip_mesh.material_override = mat
	_tip_marker.add_child(_music_tip_mesh)

	_music_tip_light = OmniLight3D.new()
	_music_tip_light.name = "MusicTipLight"
	_music_tip_light.light_color = music_tip_color_idle
	_music_tip_light.light_energy = 0.3
	_music_tip_light.omni_range = 0.5
	_tip_marker.add_child(_music_tip_light)

func _process(delta: float) -> void:
	super(delta)

	# Calculate tip velocity
	var current_pos = get_tip_position()
	_current_velocity = current_pos.distance_to(_last_tip_position) / delta if delta > 0 else 0.0
	_last_tip_position = current_pos

	# Update audio position to follow tip
	if _audio_player:
		_audio_player.global_position = current_pos

	_fill_audio_buffer(delta)
	_update_music_tip_visual()

func _fill_audio_buffer(delta: float) -> void:
	if not _playback:
		return

	var frames_available = _playback.get_frames_available()
	if frames_available <= 0:
		return

	# Play when tip is grabbed and moving
	var is_active = _tip_grabbed and _current_velocity > min_velocity_for_sound

	var target_volume = -80.0
	if is_active:
		var volume_factor = clamp((_current_velocity - min_velocity_for_sound) * velocity_to_volume_scale, 0.0, 1.0)
		target_volume = lerp(-40.0, volume_db, volume_factor)

	_audio_player.volume_db = lerp(_audio_player.volume_db, target_volume, delta * 10.0)

	# Calculate frequency based on line length
	var length_ratio = (line_length - min_length) / (max_length - min_length)
	var frequency = base_frequency + (frequency_range * (1.0 - length_ratio))

	if enable_vibrato:
		_vibrato_phase += delta * vibrato_rate * TAU
		frequency *= 1.0 + sin(_vibrato_phase) * vibrato_depth

	var sample_rate = _audio_generator.mix_rate
	var increment = frequency / sample_rate

	for i in frames_available:
		var sample = _generate_sample(_phase)
		_playback.push_frame(Vector2(sample, sample))
		_phase = fmod(_phase + increment, 1.0)

func _generate_sample(phase: float) -> float:
	match waveform:
		0: return sin(phase * TAU)
		1: return 1.0 if phase < 0.5 else -1.0
		2: return 2.0 * phase - 1.0
		3:
			if phase < 0.25:
				return phase * 4.0
			elif phase < 0.75:
				return 2.0 - phase * 4.0
			else:
				return phase * 4.0 - 4.0
	return 0.0

func _update_music_tip_visual() -> void:
	if not glow_with_sound:
		return

	var is_active = _tip_grabbed and _current_velocity > min_velocity_for_sound
	var target_color = music_tip_color_active if is_active else music_tip_color_idle
	var target_energy = 3.0 if is_active else 1.0

	if _music_tip_mesh and _music_tip_mesh.material_override:
		var mat = _music_tip_mesh.material_override as StandardMaterial3D
		mat.albedo_color = mat.albedo_color.lerp(target_color, 0.1)
		mat.emission = mat.emission.lerp(target_color, 0.1)
		mat.emission_energy_multiplier = lerp(mat.emission_energy_multiplier, target_energy, 0.1)

	if _music_tip_light:
		_music_tip_light.light_color = _music_tip_light.light_color.lerp(target_color, 0.1)
		_music_tip_light.light_energy = lerp(_music_tip_light.light_energy, 0.8 if is_active else 0.3, 0.1)

func set_waveform_type(type: int) -> void:
	waveform = clamp(type, 0, 3)
