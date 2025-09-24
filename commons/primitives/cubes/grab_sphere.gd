@tool
extends XRToolsPickable


## Alternate material when button pressed
@export var alternate_material : Material

## Freeze behavior options
@export var alter_freeze : bool = true  # Enable alternating freeze behavior

## Pickup feedback
@export var glow_color: Color = Color(1.0, 0.6, 1.0)
@export var glow_emission_energy: float = 2.0
@export var pickup_sound_volume_db: float = -6.0

# Original material
var _original_material : Material
var _glow_material : Material

# Pickup audio
var _pickup_player : AudioStreamPlayer3D
var _pickup_stream : AudioStreamWAV

# Glow state
var _is_glowing := false

# Current controller holding this object
var _current_controller : XRController3D

# Educational messages about points from queer CGI perspective
var _queer_point_messages := [
	"A point at (0, 0, 0) isn't 'nothing' - it's the origin, the center from which all other positions are understood.",
	"Moving a point doesn't destroy its essence - it transforms its relationships.",
	"Point = (x, y, z) - where x = width axis, y = height axis, z = depth axis.",
	"A point's meaning comes from its relationships to everything around it.",
	"Every point is an act of claiming space and asserting presence in the digital world.",
	"No point exists in isolation - even alone, it exists in relationship to the camera and viewer.",
	"A point's coordinates are relational, not absolute - context gives them meaning.",
	"CGI worlds are built through points linking together.",
	"Points gain power through connection - lines, triangles, and meshes are chosen family networks."	
]

# Track message index to cycle through them
var _message_index := 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	# Get the original material
	_original_material = $MeshInstance3D.get_active_material(0)
	_glow_material = _build_glow_material(_original_material)
	_setup_pickup_audio()

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)



func _build_glow_material(source: Material) -> Material:
	var material := source
	if material:
		material = material.duplicate()
	else:
		material = StandardMaterial3D.new()

	if material is BaseMaterial3D:
		var base_mat := material as BaseMaterial3D
		base_mat.emission_enabled = true
		base_mat.emission = glow_color
		base_mat.emission_energy_multiplier = glow_emission_energy
		base_mat.albedo_color = base_mat.albedo_color.lerp(glow_color, 0.3)

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
	var tone := 880.0
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
	$MeshInstance3D.set_surface_override_material(0, _glow_material)

func _restore_original_material() -> void:
	_is_glowing = false
	$MeshInstance3D.set_surface_override_material(0, _original_material)

func _play_pickup_sound() -> void:
	if not _pickup_player:
		return
	if _pickup_player.playing:
		_pickup_player.stop()
	_pickup_player.play()

func _get_next_queer_message() -> String:
	if _message_index >= _queer_point_messages.size():
		return ""  # No more messages available
	
	var message = _queer_point_messages[_message_index]
	_message_index += 1
	return message

# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	# Listen for button events on the associated controller
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)

	_apply_glow()
	_play_pickup_sound()


# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Toggle freeze state on drop if alter_freeze is enabled
	if alter_freeze and has_method("set_freeze_enabled"):
		var current_frozen = freeze
		set_freeze_enabled(!current_frozen)
		print("DEBUG: Toggled freeze state from ", current_frozen, " to ", !current_frozen)
	
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_current_controller = null

	# Restore original material when dropped
	_restore_original_material()
	
	# Send educational message about points from queer perspective
	var educational_message = _get_next_queer_message()
	if educational_message != "":
		GameManager.add_console_message(educational_message, "info", "queer_cgi")

# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	# Handle controller button presses
	if button == "ax_button":
		# Set alternate material when button pressed
		if alternate_material:
			$MeshInstance3D.set_surface_override_material(0, alternate_material)


# Called when a controller button is released
func _on_controller_button_released(button : String):
	# Handle controller button releases
	if button == "ax_button":
		# Restore material when button released
		if _is_glowing:
			_apply_glow()
		else:
			$MeshInstance3D.set_surface_override_material(0, _original_material)
