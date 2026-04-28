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
const DressingRoomInspectorScript = preload("res://commons/artifacts/catalog/DressingRoomInspector.gd")

## Hotkeys.
@export var next_room_key: Key = KEY_N
@export var prev_room_key: Key = KEY_P
@export var next_rotation_key: Key = KEY_R
@export var reset_camera_key: Key = KEY_F
@export var toggle_overlay_key: Key = KEY_TAB
@export var toggle_inspector_key: Key = KEY_I

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

# Inspector + tile-picking state.
var _inspector: PanelContainer = null
var _pick_mode: String = "value"   # mirrors inspector's pick_mode_changed
var _tile_meta: Dictionary = {}    # MeshInstance3D → {row, col} for click-pick

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
	_setup_inspector()
	_rooms = DressingRoomBuilderScript.list_dressing_rooms()
	if _rooms.is_empty():
		_set_info("No dressing rooms found at\nres://commons/artifacts/dressing_rooms/")
		return
	_load_room(_rooms[_index])
	_set_hints()


func _setup_inspector() -> void:
	# The inspector lives inside the UI CanvasLayer, anchored to the right side.
	if not has_node("UI"):
		return
	var ui: CanvasLayer = $UI
	var holder := MarginContainer.new()
	holder.name = "InspectorHolder"
	holder.anchor_left = 1.0
	holder.anchor_right = 1.0
	holder.anchor_top = 0.0
	holder.anchor_bottom = 1.0
	holder.offset_left = -380
	holder.offset_right = -16
	holder.offset_top = 16
	holder.offset_bottom = -56
	holder.add_theme_constant_override("margin_left", 0)
	ui.add_child(holder)
	_inspector = DressingRoomInspectorScript.new()
	holder.add_child(_inspector)
	_inspector.data_changed.connect(_on_inspector_data_changed)
	_inspector.save_requested.connect(_on_save_requested)
	_inspector.pick_mode_changed.connect(func(mode): _pick_mode = mode)


func _on_inspector_data_changed() -> void:
	# Update local cache + rebuild scene without resetting rotation index.
	if _inspector:
		_current_room_data = _inspector.data
		_rebuild_with_rotation()


func _on_save_requested() -> void:
	if _inspector == null or _current_room_data.is_empty():
		return
	var lookup: String = String(_current_room_data.get("lookup_name", ""))
	if lookup.is_empty():
		_inspector.set_save_status("save error: no lookup_name", false)
		return
	var path: String = "res://commons/artifacts/dressing_rooms/%s.json" % lookup
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_inspector.set_save_status("save error: cannot open %s" % path, false)
		return
	f.store_string(JSON.stringify(_current_room_data, "\t"))
	f.close()
	_inspector.set_save_status("saved %s" % path, true)


func _set_hints() -> void:
	if _hint_label:
		_hint_label.text = "[N]/[P] room   [R] rotate   [F] reset cam   [I] inspector   [Tab] hide UI   click tile = paint   drag = orbit   scroll = zoom"


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
	_tile_meta.clear()
	if _current_rotation_index >= _current_rotations.size():
		_current_rotation_index = 0
	var rot_deg: int = _current_rotations[_current_rotation_index]
	var lookup_cb := Callable(self, "_lookup_artifact_info")
	_current_built = DressingRoomBuilderScript.build(
		_current_room_data, rot_deg, lookup_cb)
	_container.add_child(_current_built)
	# Tag footing tile MeshInstance3Ds with their UNROTATED row/col so the
	# inspector can edit the source data on click. We re-derive that from the
	# tile's name "Tile_<row>_<col>" then inverse-rotate to source coords.
	var footing: Node = _current_built.get_node_or_null("Footing")
	if footing:
		for child in footing.get_children():
			if child is MeshInstance3D:
				var n := child.name as String
				var parts := n.split("_")
				if parts.size() >= 3:
					var rotated_r: int = int(parts[1])
					var rotated_c: int = int(parts[2])
					var src := _unrotate_coord(rotated_r, rotated_c, rot_deg)
					_tile_meta[child.get_instance_id()] = src
	_frame_built()
	_set_info(_format_info(rot_deg))
	if _inspector:
		_inspector.set_data(_current_room_data)


# Convert (rotated_r, rotated_c) back to the source tile coordinates.
func _unrotate_coord(rotated_r: int, rotated_c: int, rot_deg: int) -> Dictionary:
	var footing: Dictionary = _current_room_data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	var rows: int = tiles.size()
	var cols: int = 0
	for row in tiles:
		if row is Array and row.size() > cols:
			cols = row.size()
	rot_deg = rot_deg % 360
	var src_r: int = rotated_r
	var src_c: int = rotated_c
	if rot_deg == 90:
		# rotated[r][c] = src[rows-1-c][r]  →  src_r = rows-1-rotated_c, src_c = rotated_r
		src_r = rows - 1 - rotated_c
		src_c = rotated_r
	elif rot_deg == 180:
		src_r = rows - 1 - rotated_r
		src_c = cols - 1 - rotated_c
	elif rot_deg == 270:
		src_r = rotated_c
		src_c = cols - 1 - rotated_r
	return {"row": src_r, "col": src_c}


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
	# If the mouse is hovering the inspector panel, never start orbit / pick
	# (the inspector handles its own clicks).
	if _is_pointer_over_inspector():
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			# On press: try to pick a tile; if hit, treat as edit-click.
			if mb.pressed and _try_pick_tile(mb.position):
				return
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
			toggle_inspector_key:
				if _inspector and _inspector.get_parent() is Control:
					var holder: Control = _inspector.get_parent() as Control
					holder.visible = not holder.visible


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


# ──────────────────────────────────────────────────────────────────────
# Tile picking via raycast
# ──────────────────────────────────────────────────────────────────────

func _is_pointer_over_inspector() -> bool:
	if _inspector == null:
		return false
	var holder: Control = _inspector.get_parent() as Control
	if holder == null or not holder.visible:
		return false
	var rect := holder.get_global_rect()
	return rect.has_point(get_viewport().get_mouse_position())


# Cast a ray from the camera through the click point, find the nearest
# footing tile, and pass the (row, col) to the inspector.
func _try_pick_tile(screen_pos: Vector2) -> bool:
	if _camera == null or _current_built == null:
		return false
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	var footing := _current_built.get_node_or_null("Footing")
	if footing == null:
		return false
	var best_node: MeshInstance3D = null
	var best_t: float = INF
	for child in footing.get_children():
		if not (child is MeshInstance3D): continue
		var mi: MeshInstance3D = child
		var aabb: AABB = mi.global_transform * mi.get_aabb()
		# Slab method ray-box intersect.
		var t_hit: float = _ray_aabb_t(origin, direction, aabb)
		if t_hit >= 0.0 and t_hit < best_t:
			best_t = t_hit
			best_node = mi
	if best_node == null:
		return false
	var coord: Dictionary = _tile_meta.get(best_node.get_instance_id(), {})
	if coord.is_empty():
		return false
	if _inspector and _inspector.handle_tile_click(int(coord.row), int(coord.col)):
		_current_room_data = _inspector.data
		_rebuild_with_rotation()
	return true


# Ray-AABB slab intersection — returns t of nearest hit, or -1 if no hit.
func _ray_aabb_t(origin: Vector3, dir: Vector3, aabb: AABB) -> float:
	var inv := Vector3(
		1.0 / dir.x if absf(dir.x) > 1e-9 else 1e9,
		1.0 / dir.y if absf(dir.y) > 1e-9 else 1e9,
		1.0 / dir.z if absf(dir.z) > 1e-9 else 1e9,
	)
	var min_p: Vector3 = aabb.position
	var max_p: Vector3 = aabb.position + aabb.size
	var t1: Vector3 = (min_p - origin) * inv
	var t2: Vector3 = (max_p - origin) * inv
	var tmin: float = max(max(min(t1.x, t2.x), min(t1.y, t2.y)), min(t1.z, t2.z))
	var tmax: float = min(min(max(t1.x, t2.x), max(t1.y, t2.y)), max(t1.z, t2.z))
	if tmax < 0 or tmin > tmax:
		return -1.0
	return tmin if tmin >= 0.0 else tmax
