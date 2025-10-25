@tool
extends XRToolsPickable

@export var alternate_material: Material
@export var alter_freeze: bool = true
@export var glow_color: Color = Color(0.9, 0.6, 1.0)
@export var glow_emission_energy: float = 2.0
@export var pickup_sound_volume_db: float = -6.0

var _original_material: Material
var _glow_material: Material
var _pickup_player: AudioStreamPlayer3D
var _pickup_stream: AudioStreamWAV
var _is_glowing := false
var _current_controller: XRController3D

func _ready() -> void:
	super()
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)
		_glow_material = _build_glow_material(_original_material)
	_setup_pickup_audio()
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _build_glow_material(source: Material) -> Material:
	var material := source if source else StandardMaterial3D.new()
	material = material.duplicate()
	if material is BaseMaterial3D:
		var base_mat := material as BaseMaterial3D
		base_mat.emission_enabled = true
		base_mat.emission = glow_color
		base_mat.emission_energy_multiplier = glow_emission_energy
		base_mat.albedo_color = base_mat.albedo_color.lerp(glow_color, 0.25)
	return material

func _setup_pickup_audio() -> void:
	_pickup_stream = _build_pickup_stream()
	_pickup_player = AudioStreamPlayer3D.new()
	_pickup_player.name = "PickupPlayer"
	_pickup_player.stream = _pickup_stream
	_pickup_player.autoplay = false
	_pickup_player.volume_db = pickup_sound_volume_db
	_pickup_player.unit_size = 0.5
	_pickup_player.attenuation_filter_cutoff_hz = 6000
	add_child(_pickup_player)

func _build_pickup_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.18
	var tone := 660.0
	var length := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(length * 2)
	for i in length:
		var t: float = float(i) / stream.mix_rate
		var envelope: float = min(t / 0.02, 1.0) * exp(-3.0 * t)
		var sample: float = sin(TAU * tone * t) * 0.45 * envelope
		var int_sample: int = int(sample * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF
	stream.data = data
	return stream

func _apply_glow() -> void:
	if not _glow_material:
		_glow_material = _build_glow_material(_original_material)
	_is_glowing = true
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _glow_material)

func _restore_original_material() -> void:
	_is_glowing = false
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _original_material)

func _play_pickup_sound() -> void:
	if _pickup_player:
		if _pickup_player.playing:
			_pickup_player.stop()
		_pickup_player.play()

func _on_picked_up(_pickable) -> void:
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)
	_apply_glow()
	_play_pickup_sound()

func _on_dropped(_pickable) -> void:
	if alter_freeze and has_method("set_freeze_enabled"):
		set_freeze_enabled(!freeze)
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_current_controller = null
	_restore_original_material()
	var context := {"object_name": str(name)}
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		TextManager.trigger_event("tetrahedron_drop", context)

func _on_controller_button_pressed(button: String) -> void:
	if button == "ax_button" and alternate_material:
		var mesh_instance = get_node_or_null("MeshInstance3D")
		if mesh_instance:
			mesh_instance.set_surface_override_material(0, alternate_material)

func _on_controller_button_released(button: String) -> void:
	if button == "ax_button":
		var mesh_instance = get_node_or_null("MeshInstance3D")
		if not mesh_instance:
			return
		if _is_glowing:
			_apply_glow()
		else:
			mesh_instance.set_surface_override_material(0, _original_material)
