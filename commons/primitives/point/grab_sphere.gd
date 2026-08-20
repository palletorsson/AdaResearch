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

## XP awarded on pickup
@export var xp_on_pickup: int = 1

## Haptic Feedback Parameters
@export var haptic_pickup_intensity: float = 0.5
@export var haptic_pickup_duration: float = 0.1
@export var haptic_drop_intensity: float = 0.3
@export var haptic_drop_duration: float = 0.05

# Original material
var _original_material : Material
var _glow_material : Material

# Pickup audio — built lazily on first pickup, and the synthesized chirp is
# ONE resource per process: the Modulor figure alone boots 37 of these
# spheres, and each was synthesizing ~4,000 samples in GDScript at _ready
# for a sound most spheres are never asked to make.
var _pickup_player : AudioStreamPlayer3D
var _pickup_stream : AudioStreamWAV
static var _shared_pickup_stream : AudioStreamWAV = null

# Glow state
var _is_glowing := false

# Current controller holding this object
var _current_controller : XRController3D
var _active_controllers: Array[XRController3D] = []

# Value mapper color updating
var _parent_value_mapper: Node3D = null
var _color_update_enabled := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	# Prevent gravity gun from affecting drag points
	add_to_group("no_gravity_gun")

	# Get the original material
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)
		# _glow_material is built lazily by _apply_glow on first pickup —
		# an eager duplicate per sphere was 37 duplicates in one figure.
	# audio is lazy too: see _play_pickup_sound

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	# Check if parent has value mapper functionality (detects value_mapper_3d, value_mapper_2d, etc.)
	_check_for_value_mapper_parent()



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
	if _shared_pickup_stream == null:
		_shared_pickup_stream = _build_pickup_stream()
	_pickup_stream = _shared_pickup_stream
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
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _glow_material)

func _restore_original_material() -> void:
	_is_glowing = false
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _original_material)

func _play_pickup_sound() -> void:
	if not _pickup_player:
		_setup_pickup_audio()   # first pickup builds the player; the chirp is unchanged
	if _pickup_player.playing:
		_pickup_player.stop()
	_pickup_player.play()

func _trigger_haptic(controller: XRController3D, intensity: float, duration: float) -> void:
	if controller:
		controller.trigger_haptic_pulse("haptic", 100.0, intensity, duration, 0)

# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	# Listen for button events on the associated controller
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		# Haptic Feedback for Pickup
		_trigger_haptic(_current_controller, haptic_pickup_intensity, haptic_pickup_duration)

		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)
		if _current_controller not in _active_controllers:
			_active_controllers.append(_current_controller)
		if _active_controllers.size() == 2:
			_duplicate_for_second_controller(_active_controllers[1])

	_apply_glow()
	_play_pickup_sound()
	# XP is handled globally by PickupXPListener using xp_on_pickup property


# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Toggle freeze state on drop if alter_freeze is enabled
	if alter_freeze and has_method("set_freeze_enabled"):
		var current_frozen = freeze
		set_freeze_enabled(!current_frozen)
		print("DEBUG: Toggled freeze state from ", current_frozen, " to ", !current_frozen)
	
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		# Haptic Feedback for Drop
		_trigger_haptic(_current_controller, haptic_drop_intensity, haptic_drop_duration)
		
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_active_controllers.erase(_current_controller)
		_current_controller = null

	# Restore original material when dropped
	_restore_original_material()
	
	# Send map-aware educational message through TextManager
	var context := {
		"object_name": str(name)
	}
	var handled := false
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		handled = TextManager.trigger_event("point_drop", context)
	if not handled:
		pass

# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	# Handle controller button presses
	if button == "ax_button":
		# Set alternate material when button pressed
		if alternate_material:
			var mesh_instance = get_node_or_null("MeshInstance3D")
			if mesh_instance:
				mesh_instance.set_surface_override_material(0, alternate_material)


# Called when a controller button is released
func _on_controller_button_released(button : String):
	# Handle controller button releases
	if button == "ax_button":
		# Restore material when button released
		if _is_glowing:
			_apply_glow()
		else:
			var mesh_instance = get_node_or_null("MeshInstance3D")
			if mesh_instance:
				mesh_instance.set_surface_override_material(0, _original_material)
		if _current_controller:
			_duplicate_for_second_controller(_current_controller)

func _duplicate_for_second_controller(controller: XRController3D) -> void:
	if controller == null:
		return
	var scene := load('res://commons/primitives/point/grab_sphere_point.tscn')
	if scene == null:
		return
	var instance: Node3D = scene.instantiate()
	if instance == null:
		return
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(instance)
	instance.global_transform = global_transform.translated(Vector3(0.1, 0, 0))

func _check_for_value_mapper_parent() -> void:
	# Check if this grab_sphere is part of a value mapper
	var parent = get_parent()
	if parent and parent.has_signal("values_changed"):
		_parent_value_mapper = parent
		_color_update_enabled = true
		# Connect to value changes
		_parent_value_mapper.values_changed.connect(_on_value_mapper_changed)

func _on_value_mapper_changed(r: float, g: float, b: float) -> void:
	if not _color_update_enabled:
		return

	var new_color = Color(r, g, b, 1.0)

	# Update the sphere's material color
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		# Get current material
		var current_mat = mesh_instance.get_surface_override_material(0)
		if not current_mat:
			current_mat = mesh_instance.get_active_material(0)

		# Create a new material based on current or create new one
		var new_mat: BaseMaterial3D
		if current_mat and current_mat is BaseMaterial3D:
			new_mat = current_mat.duplicate()
		else:
			new_mat = StandardMaterial3D.new()

		# Update color
		new_mat.albedo_color = new_color

		# If it's glowing, also update emission
		if _is_glowing and new_mat is StandardMaterial3D:
			var standard_mat = new_mat as StandardMaterial3D
			standard_mat.emission_enabled = true
			standard_mat.emission = new_color
			standard_mat.emission_energy_multiplier = glow_emission_energy

		# Apply the material
		mesh_instance.set_surface_override_material(0, new_mat)

		# Update stored materials
		_original_material = new_mat
		if _is_glowing:
			_glow_material = _build_glow_material(_original_material)
