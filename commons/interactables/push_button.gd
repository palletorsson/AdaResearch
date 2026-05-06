extends Node3D

signal pressed

@export var pressed_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var released_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var pressed_emission_energy: float = 1.1
@export var released_emission_energy: float = 0.35
@export_group("Press Sound")
@export var play_press_sound: bool = true
@export var press_sound_volume_db: float = -14.0
@export var press_sound_pitch_scale: float = 1.0
@export var press_sound_frequency_hz: float = 980.0
@export var press_sound_duration: float = 0.08
@export var press_sound_decay: float = 9.0

@onready var _interactable: Node = $"InteractableAreaButton"
@onready var _button_mesh: MeshInstance3D = $"Button/ButtonMesh"
var _button_material: StandardMaterial3D
var _press_audio_player: AudioStreamPlayer3D
var _is_pressed_visual := false

var _colors_initialized: bool = false

func _ready() -> void:
	_button_material = _get_button_material()
	_setup_press_audio()
	_connect_signals()
	# Defer initial color sync to allow controller to set colors first
	await get_tree().process_frame
	await get_tree().process_frame
	if not _colors_initialized:
		_sync_color_to_state()
		_colors_initialized = true

func _process(_delta: float) -> void:
	if _colors_initialized:
		_sync_color_to_state()

func _connect_signals() -> void:
	if not _interactable:
		return
	if _interactable.has_signal("button_pressed") and not _interactable.is_connected("button_pressed", Callable(self, "_on_button_pressed")):
		_interactable.connect("button_pressed", Callable(self, "_on_button_pressed"))
	if _interactable.has_signal("button_released") and not _interactable.is_connected("button_released", Callable(self, "_on_button_released")):
		_interactable.connect("button_released", Callable(self, "_on_button_released"))

func _sync_color_to_state() -> void:
	_set_visual_state(_is_interactable_pressed())

func _set_visual_state(pressed: bool, force: bool = false) -> void:
	if not force and _is_pressed_visual == pressed:
		return
	_is_pressed_visual = pressed
	_apply_color(pressed_color if pressed else released_color, pressed)

func update_colors():
	"""Call this after changing pressed_color or released_color externally"""
	_colors_initialized = true
	_set_visual_state(_is_interactable_pressed(), true)

func _get_button_material() -> StandardMaterial3D:
	if not _button_mesh:
		return null
	var material := _button_mesh.get_surface_override_material(0)
	if not material:
		material = _button_mesh.material_override
	if not material and _button_mesh.mesh and _button_mesh.mesh.get_surface_count() > 0:
		material = _button_mesh.mesh.surface_get_material(0)
		if material:
			material = material.duplicate()
			_button_mesh.set_surface_override_material(0, material)
	return material

func _apply_color(color: Color, pressed: bool) -> void:
	if not _button_material:
		_button_material = _get_button_material()
	if _button_material:
		_button_material.albedo_color = color
		# Add emission for visibility in VR
		_button_material.emission_enabled = true
		_button_material.emission = color
		_button_material.emission_energy_multiplier = pressed_emission_energy if pressed else released_emission_energy

func _is_interactable_pressed() -> bool:
	if not _interactable or not _interactable.has_method("is_xr_class"):
		return false
	if not _interactable.is_xr_class("XRToolsInteractableAreaButton"):
		return false
	return bool(_interactable.get("pressed"))

func _on_button_pressed(_button) -> void:
	pressed.emit()
	_play_press_sound()
	_set_visual_state(true)

func _on_button_released(_button) -> void:
	_set_visual_state(false)

func _setup_press_audio() -> void:
	_press_audio_player = AudioStreamPlayer3D.new()
	_press_audio_player.name = "PressAudioPlayer"
	_press_audio_player.volume_db = press_sound_volume_db
	_press_audio_player.pitch_scale = press_sound_pitch_scale
	_press_audio_player.max_distance = 8.0
	_press_audio_player.unit_size = 0.8
	_press_audio_player.stream = _build_press_stream()
	add_child(_press_audio_player)

func _play_press_sound() -> void:
	if not play_press_sound:
		return
	if not _press_audio_player:
		_setup_press_audio()
	if not _press_audio_player:
		return
	_press_audio_player.volume_db = press_sound_volume_db
	_press_audio_player.pitch_scale = press_sound_pitch_scale
	_press_audio_player.stream = _build_press_stream()
	if _press_audio_player.playing:
		_press_audio_player.stop()
	_press_audio_player.play()

func _build_press_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false

	var duration: float = press_sound_duration if press_sound_duration > 0.02 else 0.02
	var frequency: float = press_sound_frequency_hz if press_sound_frequency_hz > 80.0 else 80.0
	var decay: float = press_sound_decay if press_sound_decay > 0.1 else 0.1
	var sample_count := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var denom: float = float(sample_count - 1) if sample_count > 1 else 1.0

	for i in sample_count:
		var t: float = float(i) / stream.mix_rate
		var progress: float = float(i) / denom
		var envelope: float = exp(-progress * decay)
		var tone: float = sin(TAU * frequency * t)
		var sample: float = tone * envelope * 0.28
		var sample_int := int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[2 * i] = sample_int & 0xFF
		data[2 * i + 1] = (sample_int >> 8) & 0xFF

	stream.data = data
	return stream
