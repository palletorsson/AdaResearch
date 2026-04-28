class_name DressingRoomCatalog3D
extends Node3D

## Standalone 3D viewer for dressing rooms. The thing the catalog wasn't:
## no auto-rotate, close camera, see the staging clearly, cycle through
## valid rotations.
##
## Reads commons/artifacts/dressing_rooms/<name>.json, builds the scene
## via DressingRoomBuilder, frames it with a static-camera-then-orbit
## approach. Mouse drags orbit, scroll zooms — but never auto-spins.

const DressingRoomBuilderScript = preload("res://commons/artifacts/catalog/DressingRoomBuilder.gd")

## Hotkeys.
@export var next_room_key: Key = KEY_N
@export var prev_room_key: Key = KEY_P
@export var next_rotation_key: Key = KEY_R
@export var reset_camera_key: Key = KEY_F
@export var toggle_overlay_key: Key = KEY_TAB

## Camera tuning. The catalog's camera was distant + auto-orbited;
## this one snaps close, holds still, lets you orbit if you want.
@export_group("Camera")
@export var orbit_sensitivity: float = 0.006
@export var pan_sensitivity: float = 0.01
@export var zoom_sensitivity: float = 0.4
@export var zoom_min: float = 1.0
@export var zoom_max: float = 18.0
@export var initial_pitch_deg: float = -22.0     # gentle look-down
@export var initial_yaw_deg: float = 30.0        # offset from front
@export var fit_padding: float = 0.45            # smaller = closer

@onready var _container: Node3D = $RoomContainer
@onready var _camera: Camera3D = $CameraRig/Camera3D
@onready var _camera_rig: Node3D = $CameraRig
@onready var _key_light: DirectionalLight3D = $KeyLight
@onready var _info_label: Label = $UI/Info
@onready var _hint_label: Label = $UI/Hints

var _rooms: Array[String] = []
var _index: int = 0
var _current_room_data: Dictionary = {}
var _current_rotation_index: int = 0
var _current_rotations: Array[int] = [0]
var _current_built: Node3D = null

# Orbit state.
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 0.0
var _orbit_distance: float = 6.0
var _orbit_focus: Vector3 = Vector3(0, 0.5, 0)
var _is_orbiting: bool = false
var _is_panning: bool = false
var _last_mouse: Vector2 = Vector2.ZERO


func _ready() -> void:
	_orbit_yaw = deg_to_rad(initial_yaw_deg)
	_orbit_pitch = deg_to_rad(initial_pitch_deg)
	_rooms = DressingRoomBuilderScript.list_dressing_rooms()
	if _rooms.is_empty():
		_set_info("No dressing rooms found at\nres://commons/artifacts/dressing_rooms/")
		return
	_load_room(_rooms[_index])
	_set_hints()


func _set_hints() -> void:
	if _hint_label:
		_hint_label.text = "[N] next room   [P] prev   [R] rotate   [F] reset camera   [Tab] hide UI   [drag] orbit   [scroll] zoom"


func _set_info(text: String) -> void:
	if _info_label:
		_info_label.text = text


# ──────────────────────────────────────────────────────────────────────
# Room loading
# ──────────────────────────────────────────────────────────────────────

func _load_room(lookup_name: String) -> void:
	# Clear existing.
	if _current_built and is_instance_valid(_current_built):
		_current_built.queue_free()
	_current_built = null
	_current_room_data = {}

	var data = DressingRoomBuilderScript.load_dressing_room(lookup_name)
	if not (data is Dictionary):
		_set_info("Could not load dressing room: %s" % lookup_name)
		return
	_current_room_data = data

	# Allowed rotations from schema.
	var rots_raw: Array = data.get("rotations", ["0"])
	_current_rotations.clear()
	for r in rots_raw:
		_current_rotations.append(int(str(r)))
	if _current_rotations.is_empty():
		_current_rotations = [0]
	_current_rotation_index = 0

	_rebuild_with_rotation()


func _rebuild_with_rotation() -> void:
	if _current_room_data.is_empty():
		return
	if _current_built and is_instance_valid(_current_built):
		_current_built.queue_free()
	var rot_deg: int = _current_rotations[_current_rotation_index]
	var lookup_cb := Callable(self, "_lookup_artifact_info")
	_current_built = DressingRoomBuilderScript.build(
		_current_room_data, rot_deg, lookup_cb)
	_container.add_child(_current_built)
	_frame_built()
	_set_info(_format_info(rot_deg))


func _format_info(rot_deg: int) -> String:
	var name: String = String(_current_room_data.get("lookup_name", "?"))
	var fp = _current_room_data.get("footprint", [1, 1, 1])
	var extras = _current_room_data.get("extras", [])
	var approach = String(_current_room_data.get("approach", "?"))
	var exit = String(_current_room_data.get("exit", "?"))
	return "%s   (%d/%d)\nrotation: %d°   footprint: %s\napproach: %s   exit: %s   extras: %d" % [
		name, _index + 1, _rooms.size(),
		rot_deg, str(fp),
		approach, exit, extras.size()]


## Look up an artifact's scene path. Scans the registry JSON files
## directly — the catalog's data provider is GridSystem-coupled and
## not always available outside a full map context.
func _lookup_artifact_info(lookup: String) -> Dictionary:
	# If the data provider doesn't expose get_artifact_info, scan the
	# registry JSONs directly for a scene path.
	var registry_dir := "res://commons/artifacts/registry/"
	var dir := DirAccess.open(registry_dir)
	if dir == null:
		return {}
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var raw := FileAccess.get_file_as_string(registry_dir + fname)
			var parsed = JSON.parse_string(raw)
			if parsed is Dictionary:
				var arts: Variant = parsed.get("artifacts")
				if not (arts is Dictionary):
					arts = parsed
				if arts is Dictionary and arts.has(lookup):
					var entry = arts[lookup]
					if entry is Dictionary:
						dir.list_dir_end()
						return entry
		fname = dir.get_next()
	dir.list_dir_end()
	return {}


# ──────────────────────────────────────────────────────────────────────
# Camera framing
# ──────────────────────────────────────────────────────────────────────

func _frame_built() -> void:
	if not _current_built:
		return
	var aabb := _aabb_of(_current_built)
	if aabb.size.length_squared() < 1e-6:
		return
	_orbit_focus = aabb.get_center()
	# Distance derived from AABB size + pad. 30% closer than the catalog's default.
	var radius: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z)) * 0.5
	var fov_rad: float = deg_to_rad(_camera.fov)
	_orbit_distance = clampf(
		radius / max(0.01, sin(fov_rad * 0.5)) * (1.0 - fit_padding) + radius,
		zoom_min, zoom_max
	)
	_update_camera_from_orbit()


func _aabb_of(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			var mesh_aabb: AABB = (n as MeshInstance3D).global_transform * n.get_aabb()
			if first:
				combined = mesh_aabb
				first = false
			else:
				combined = combined.merge(mesh_aabb)
		for child in n.get_children():
			stack.append(child)
	return combined


func _update_camera_from_orbit() -> void:
	if not _camera_rig or not _camera:
		return
	# Camera position on a sphere around the focus.
	var x: float = _orbit_distance * cos(_orbit_pitch) * sin(_orbit_yaw)
	var y: float = _orbit_distance * sin(_orbit_pitch)
	var z: float = _orbit_distance * cos(_orbit_pitch) * cos(_orbit_yaw)
	_camera_rig.global_position = _orbit_focus + Vector3(x, y, z)
	_camera_rig.look_at(_orbit_focus, Vector3.UP)


# ──────────────────────────────────────────────────────────────────────
# Input
# ──────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_orbiting = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_orbit_distance = max(zoom_min, _orbit_distance - zoom_sensitivity)
			_update_camera_from_orbit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_orbit_distance = min(zoom_max, _orbit_distance + zoom_sensitivity)
			_update_camera_from_orbit()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _is_orbiting:
			var delta: Vector2 = mm.position - _last_mouse
			_last_mouse = mm.position
			_orbit_yaw -= delta.x * orbit_sensitivity
			_orbit_pitch = clamp(_orbit_pitch + delta.y * orbit_sensitivity,
				deg_to_rad(-80), deg_to_rad(80))
			_update_camera_from_orbit()
		elif _is_panning:
			var delta: Vector2 = mm.position - _last_mouse
			_last_mouse = mm.position
			# Pan focus along camera basis.
			var basis_x: Vector3 = -_camera_rig.global_transform.basis.x
			var basis_y: Vector3 = _camera_rig.global_transform.basis.y
			_orbit_focus += basis_x * delta.x * pan_sensitivity * (_orbit_distance / 5.0)
			_orbit_focus += basis_y * delta.y * pan_sensitivity * (_orbit_distance / 5.0)
			_update_camera_from_orbit()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			next_room_key:
				_advance_room(1)
			prev_room_key:
				_advance_room(-1)
			next_rotation_key:
				_advance_rotation()
			reset_camera_key:
				_orbit_yaw = deg_to_rad(initial_yaw_deg)
				_orbit_pitch = deg_to_rad(initial_pitch_deg)
				_frame_built()
			toggle_overlay_key:
				if has_node("UI"):
					var ui: CanvasLayer = $UI
					ui.visible = not ui.visible


func _advance_room(delta: int) -> void:
	if _rooms.is_empty(): return
	_index = (_index + delta) % _rooms.size()
	if _index < 0:
		_index += _rooms.size()
	_load_room(_rooms[_index])


func _advance_rotation() -> void:
	if _current_rotations.size() <= 1:
		return
	_current_rotation_index = (_current_rotation_index + 1) % _current_rotations.size()
	_rebuild_with_rotation()
