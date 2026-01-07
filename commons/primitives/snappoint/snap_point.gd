@tool
extends XRToolsPickable

## Snap Point - Interactive point that can snap to other snap points
## Maintains connections and updates all dependent geometry

## Snap detection parameters
@export var snap_distance: float = 0.15  # 15cm snap threshold
@export var snap_on_drop_only: bool = true  # Only snap when dropped (not while holding)
@export var show_snap_preview: bool = true  # Show preview when in snap range

## Visual feedback
@export var snap_glow_color: Color = Color(0.3, 1.0, 0.3, 1.0)  # Green when near snap
@export var snap_sound_volume_db: float = -8.0

## Alternate material when button pressed
@export var alternate_material : Material

## Freeze behavior options
@export var alter_freeze : bool = false  # Keep points movable by default

## Pickup feedback
@export var glow_color: Color = Color(1.0, 0.6, 1.0)
@export var glow_emission_energy: float = 2.0
@export var pickup_sound_volume_db: float = -6.0

## Haptic Feedback Parameters
@export var haptic_pickup_intensity: float = 0.5
@export var haptic_pickup_duration: float = 0.1
@export var haptic_drop_intensity: float = 0.3
@export var haptic_drop_duration: float = 0.05
@export var haptic_snap_intensity: float = 0.6
@export var haptic_snap_duration: float = 0.15

# Signals
signal snap_requested(to_point: Node3D)
signal snap_completed(to_point: Node3D)
signal snap_broken(from_point: Node3D)
signal point_moved(new_position: Vector3)

# Connection tracking
var connected_points: Array[Node3D] = []

# Original material
var _original_material : Material
var _glow_material : Material
var _snap_preview_material : Material

# Pickup audio
var _pickup_player : AudioStreamPlayer3D
var _pickup_stream : AudioStreamWAV
var _snap_player : AudioStreamPlayer3D

# Glow state
var _is_glowing := false
var _is_snap_preview := false

# Current controller holding this object
var _current_controller : XRController3D
var _active_controllers: Array[XRController3D] = []

# Snap detection
var _nearby_snap_points: Array[Node3D] = []
var _closest_snap_point: Node3D = null
var _last_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Call the super
	super()

	# Get the original material
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)
		_glow_material = _build_glow_material(_original_material, glow_color)
		_snap_preview_material = _build_glow_material(_original_material, snap_glow_color)
	
	_setup_pickup_audio()
	_setup_snap_audio()

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)
	
	# Register with connection manager (deferred to ensure manager is ready)
	call_deferred("_register_with_manager")
	
	_last_position = global_position

func _register_with_manager() -> void:
	# Find SnapConnectionManager in scene (autoload or scene child)
	var manager = get_node_or_null("/root/SnapConnectionManager")
	if not manager:
		# Search in the scene tree
		manager = _find_connection_manager(get_tree().root)
	
	if manager and is_instance_valid(manager) and manager.has_method("register_snap_point"):
		manager.register_snap_point(self)
	else:
		push_warning("SnapPoint: Could not find valid SnapConnectionManager in scene")

func _find_connection_manager(node: Node) -> Node:
	# Recursively search for SnapConnectionManager
	# Check by class name instead of script comparison
	if node is SnapConnectionManager:
		return node
	
	# Also check by class name string for compatibility
	if node.get_class() == "Node" and node.get_script():
		var script = node.get_script()
		if script and script.resource_path == "res://commons/primitives/snappoint/snap_connection_manager.gd":
			return node
	
	for child in node.get_children():
		var result = _find_connection_manager(child)
		if result:
			return result
	
	return null

func _process(delta: float) -> void:
	# Check if position changed
	if global_position.distance_to(_last_position) > 0.001:
		point_moved.emit(global_position)
		_last_position = global_position
	
	# Only detect nearby points when not being held (or if preview enabled while holding)
	if is_picked_up() and snap_on_drop_only:
		_clear_snap_preview()
		return
	
	_detect_nearby_snap_points()
	_update_snap_preview()

func _detect_nearby_snap_points() -> void:
	_nearby_snap_points.clear()
	_closest_snap_point = null
	
	var closest_distance := snap_distance
	
	# Find all other snap points in the scene
	var all_snap_points = get_tree().get_nodes_in_group("snap_points")
	
	for point in all_snap_points:
		if point == self or not is_instance_valid(point):
			continue
		
		var distance = global_position.distance_to(point.global_position)
		
		if distance <= snap_distance:
			_nearby_snap_points.append(point)
			
			if distance < closest_distance:
				closest_distance = distance
				_closest_snap_point = point

func _update_snap_preview() -> void:
	if not show_snap_preview:
		return
	
	if _closest_snap_point and not is_picked_up():
		if not _is_snap_preview:
			_apply_snap_preview()
	else:
		_clear_snap_preview()

func _apply_snap_preview() -> void:
	_is_snap_preview = true
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _snap_preview_material)

func _clear_snap_preview() -> void:
	if _is_snap_preview:
		_is_snap_preview = false
		_restore_original_material()

func _build_glow_material(source: Material, color: Color) -> Material:
	var material := source
	if material:
		material = material.duplicate()
	else:
		material = StandardMaterial3D.new()

	if material is BaseMaterial3D:
		var base_mat := material as BaseMaterial3D
		base_mat.emission_enabled = true
		base_mat.emission = color
		base_mat.emission_energy_multiplier = glow_emission_energy
		base_mat.albedo_color = base_mat.albedo_color.lerp(color, 0.3)

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

func _setup_snap_audio() -> void:
	var snap_stream = _build_snap_stream()
	_snap_player = AudioStreamPlayer3D.new()
	_snap_player.name = "SnapPlayer"
	_snap_player.stream = snap_stream
	_snap_player.autoplay = false
	_snap_player.volume_db = snap_sound_volume_db
	_snap_player.unit_size = 1.0
	_snap_player.attenuation_filter_cutoff_hz = 8000
	add_child(_snap_player)

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

func _build_snap_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.12
	var tone := 1200.0  # Higher pitch for snap
	var length := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(length * 2)
	for i in length:
		var t: float = float(i) / stream.mix_rate
		var envelope: float = exp(-8.0 * t)
		var sample: float = sin(TAU * tone * t) * 0.5 * envelope
		var int_sample: int = int(sample * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF
	stream.data = data
	return stream

func _apply_glow() -> void:
	if not _glow_material:
		_glow_material = _build_glow_material(_original_material, glow_color)
	_is_glowing = true
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _glow_material)

func _restore_original_material() -> void:
	_is_glowing = false
	_is_snap_preview = false
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _original_material)

func _play_pickup_sound() -> void:
	if not _pickup_player:
		return
	if _pickup_player.playing:
		_pickup_player.stop()
	_pickup_player.play()

func _play_snap_sound() -> void:
	if not _snap_player:
		return
	if _snap_player.playing:
		_snap_player.stop()
	_snap_player.play()

func _trigger_haptic(controller: XRController3D, intensity: float, duration: float) -> void:
	if controller:
		controller.trigger_haptic_pulse("haptic", 100.0, intensity, duration, 0)

# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_trigger_haptic(_current_controller, haptic_pickup_intensity, haptic_pickup_duration)
		
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)
		if _current_controller not in _active_controllers:
			_active_controllers.append(_current_controller)

	_apply_glow()
	_play_pickup_sound()

# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Check for snap if we have a nearby point
	if _closest_snap_point and _closest_snap_point not in connected_points:
		_attempt_snap(_closest_snap_point)
	
	# Toggle freeze state on drop if alter_freeze is enabled
	if alter_freeze and has_method("set_freeze_enabled"):
		var current_frozen = freeze
		set_freeze_enabled(!current_frozen)
	
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		_trigger_haptic(_current_controller, haptic_drop_intensity, haptic_drop_duration)
		
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_active_controllers.erase(_current_controller)
		_current_controller = null

	# Restore original material when dropped
	_restore_original_material()

func _attempt_snap(target_point: Node3D) -> void:
	if not is_instance_valid(target_point):
		return
	
	snap_requested.emit(target_point)
	
	# Find connection manager
	var manager = get_node_or_null("/root/SnapConnectionManager")
	if not manager:
		manager = _find_connection_manager(get_tree().root)
	
	if manager and manager.has_method("create_connection"):
		manager.create_connection(self, target_point)
	
	# Add to connected points
	if target_point not in connected_points:
		connected_points.append(target_point)
	
	# Add this to target's connected points (if it's also a snap_point)
	if target_point.has_method("add_connection"):
		target_point.add_connection(self)
	
	# Play snap sound and haptic
	_play_snap_sound()
	if _current_controller:
		_trigger_haptic(_current_controller, haptic_snap_intensity, haptic_snap_duration)
	
	snap_completed.emit(target_point)
	
	print("SnapPoint: Connected ", name, " to ", target_point.name)

func add_connection(point: Node3D) -> void:
	if point not in connected_points:
		connected_points.append(point)

func remove_connection(point: Node3D) -> void:
	if point in connected_points:
		connected_points.erase(point)
		snap_broken.emit(point)

# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	if button == "ax_button":
		if alternate_material:
			var mesh_instance = get_node_or_null("MeshInstance3D")
			if mesh_instance:
				mesh_instance.set_surface_override_material(0, alternate_material)

# Called when a controller button is released
func _on_controller_button_released(button : String):
	if button == "ax_button":
		if _is_glowing:
			_apply_glow()
		else:
			var mesh_instance = get_node_or_null("MeshInstance3D")
			if mesh_instance:
				mesh_instance.set_surface_override_material(0, _original_material)

func get_connected_points() -> Array[Node3D]:
	return connected_points

func is_connected_to(point: Node3D) -> bool:
	return point in connected_points

# Group management
func _enter_tree() -> void:
	add_to_group("snap_points")

func _exit_tree() -> void:
	remove_from_group("snap_points")
