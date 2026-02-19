class_name MapCatalogDesktop3D
extends Node3D

## Standalone desktop catalog for browsing all sequence JSON maps.
## Uses MapBrowser3D and delegates loading to the global SceneManager.
## Camera modes: Static, Isometric, Spin, Player (WASD fly).

const CLEAN_KEEP_GROUP := "map_switcher_ui_keep"

enum CameraMode {
	STATIC,
	ISOMETRIC,
	SPIN,
	PLAYER
}

@export var fly_mode_enabled: bool = true
@export var fly_toggle_key: Key = KEY_F
@export var fly_look_requires_button: bool = false
@export var look_mouse_button: MouseButton = MOUSE_BUTTON_RIGHT
@export var fly_up_key: Key = KEY_E
@export var fly_down_key: Key = KEY_Q
@export var fly_speed: float = 4.0
@export var fly_boost_multiplier: float = 2.5
@export var fly_look_sensitivity: float = 0.002

@onready var _preview_camera: Camera3D = $PreviewCamera
@onready var _map_browser: Node3D = $MapBrowser3D
@onready var _status_label: Label3D = $StatusLabel
@onready var _overlay: DesktopMapSwitcherOverlay = $DesktopMapSwitcherOverlay
@onready var _map_data_editor: MapDataEditorOverlay = $MapDataEditorOverlay
@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _key_light: DirectionalLight3D = $KeyLight
@onready var _fill_light: DirectionalLight3D = $FillLight

var _is_mouse_look_active: bool = false
var _fly_yaw: float = 0.0
var _fly_pitch: float = 0.0

# Camera mode state
var _camera_mode: CameraMode = CameraMode.SPIN
var _spin_angle: float = 0.0
var _spin_speed: float = 0.3  # radians/sec
var _orbit_radius: float = 8.0
var _orbit_height: float = 6.0
var _orbit_center: Vector3 = Vector3.ZERO

# Store original camera transform so STATIC can restore it
var _static_camera_position: Vector3 = Vector3(0.0, 1.2, 6.5)
var _static_camera_rotation: Vector3 = Vector3(-0.2618, 0.0, 0.0)  # ~-15° pitch

# Grid system for rendering maps in-scene
const GRID_SYSTEM_SCENE_PATH := "res://commons/grid/grid_system.tscn"
var _grid_system: Node3D = null

func _ready() -> void:
	if not _map_browser:
		push_warning("MapCatalogDesktop3D: MapBrowser3D node not found")
		return

	if _map_browser.has_signal("sequence_selected"):
		_map_browser.sequence_selected.connect(_on_sequence_selected)

	if _map_browser.has_signal("map_selected"):
		_map_browser.map_selected.connect(_on_map_selected)

	if _preview_camera:
		# Capture the initial camera transform from the scene as the "static" default
		_static_camera_position = _preview_camera.global_position
		_static_camera_rotation = _preview_camera.rotation
		_fly_yaw = _preview_camera.rotation.y
		_fly_pitch = _preview_camera.rotation.x

	_mark_clean_keep(_preview_camera)
	_mark_clean_keep(_map_browser)
	_mark_clean_keep(_status_label)
	_mark_clean_keep(_world_environment)
	_mark_clean_keep(_key_light)
	_mark_clean_keep(_fill_light)
	_mark_clean_keep(_map_data_editor)

	# Connect map data editor save → reload the map live
	if _map_data_editor and _map_data_editor.has_signal("map_data_saved"):
		_map_data_editor.map_data_saved.connect(_on_map_data_saved)

	# Hide the old 3D menu — sidebar replaces it
	if _map_browser:
		_map_browser.visible = false

	_sync_mouse_look_state()

	# Default to spin camera
	call_deferred("_start_default_spin")

	_set_status("Loaded sequence registry catalog")

func _start_default_spin() -> void:
	set_camera_mode(CameraMode.SPIN)

## Load a map by destroying any old grid and creating a fresh one.
func load_map_fresh(map_name: String) -> bool:
	_destroy_old_grids()

	var grid_scene := load(GRID_SYSTEM_SCENE_PATH)
	if not (grid_scene is PackedScene):
		push_warning("MapCatalogDesktop3D: Cannot load grid_system.tscn")
		return false

	_grid_system = (grid_scene as PackedScene).instantiate() as Node3D
	if not _grid_system:
		return false

	# Set map_name BEFORE adding to tree so it loads on _ready()
	if "map_name" in _grid_system:
		_grid_system.map_name = map_name

	_grid_system.transform.origin = Vector3(0.0, -0.5, 0.0)
	add_child(_grid_system)

	# Notify the JSON editor overlay of the new map
	if _map_data_editor:
		_map_data_editor.set_current_map(map_name)

	# Listen for generation complete to recenter orbit
	if _grid_system.has_signal("map_generation_complete"):
		_grid_system.map_generation_complete.connect(_on_map_generation_complete)

	return true

func _destroy_old_grids() -> void:
	if _grid_system and is_instance_valid(_grid_system):
		remove_child(_grid_system)
		_grid_system.queue_free()
		_grid_system = null

	for node in get_tree().get_nodes_in_group("grid_system"):
		if is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)
			node.queue_free()

## Create a fresh GridSystem for each map load — destroy old one first.
func ensure_grid_system() -> Node3D:
	# Kill the old one completely
	if _grid_system and is_instance_valid(_grid_system):
		_grid_system.queue_free()
		_grid_system = null

	# Also kill any other grid systems lingering in the scene
	for node in get_tree().get_nodes_in_group("grid_system"):
		if is_instance_valid(node):
			node.queue_free()

	# Instantiate fresh
	var grid_scene := load(GRID_SYSTEM_SCENE_PATH)
	if not (grid_scene is PackedScene):
		push_warning("MapCatalogDesktop3D: Cannot load grid_system.tscn")
		return null

	_grid_system = (grid_scene as PackedScene).instantiate() as Node3D
	if not _grid_system:
		return null

	_grid_system.transform.origin = Vector3(0.0, -0.5, 0.0)
	add_child(_grid_system)

	# Listen for map load to recenter orbit
	if _grid_system.has_signal("map_generation_complete"):
		_grid_system.map_generation_complete.connect(_on_map_generation_complete)

	return _grid_system

## Reload the current map after its JSON was edited and saved.
func _on_map_data_saved(map_name: String) -> void:
	if map_name.is_empty():
		return
	# Re-load the map so changes are visible immediately
	load_map_fresh(map_name)
	_set_status("Reloaded %s after JSON edit" % map_name)

## Recenter orbit on the loaded map.
func _on_map_generation_complete() -> void:
	_update_orbit_center()
	# Re-apply spin if active
	if _camera_mode == CameraMode.SPIN:
		_start_spin_camera()

## Calculate orbit center from grid dimensions, with AABB fallback.
func _update_orbit_center() -> void:
	if not _grid_system or not is_instance_valid(_grid_system):
		return

	# Try grid data_component first
	var data_comp = _grid_system.get("data_component") if "data_component" in _grid_system else null
	if data_comp and data_comp.has_method("get_grid_dimensions"):
		var dims: Vector3i = data_comp.get_grid_dimensions()
		if dims.x > 0 or dims.z > 0:
			var grid_origin: Vector3 = _grid_system.global_transform.origin
			_orbit_center = grid_origin + Vector3(float(dims.x) * 0.5, float(dims.y) * 0.5 + 0.5, float(dims.z) * 0.5)
			var map_extent := maxf(float(dims.x), float(dims.z))
			_orbit_radius = maxf(map_extent * 0.8, 6.0)
			_orbit_height = maxf(float(dims.y) + 2.0, 4.0)
			return

	# Fallback: compute AABB from all visible geometry in the scene
	var aabb := _compute_scene_aabb(_grid_system)
	# If grid system AABB is tiny, try the whole scene
	if aabb.size.length() < 0.1:
		aabb = _compute_scene_aabb(self)
	if aabb.size.length() > 0.1:
		_orbit_center = aabb.get_center()
		var map_extent := maxf(aabb.size.x, aabb.size.z)
		_orbit_radius = maxf(map_extent * 0.8, 6.0)
		_orbit_height = maxf(aabb.size.y + 2.0, 4.0)

## Compute a merged AABB from all VisualInstance3D nodes under a root.
func _compute_scene_aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	for child in root.get_children():
		# Skip cameras and lights
		if child is Camera3D or child is Light3D:
			continue
		if child is VisualInstance3D and child.visible:
			var child_aabb := (child as VisualInstance3D).get_aabb()
			if child_aabb.size.length() < 0.01:
				continue
			var global_aabb: AABB = child.global_transform * child_aabb
			if first:
				merged = global_aabb
				first = false
			else:
				merged = merged.merge(global_aabb)
		if child is Node3D and child.get_child_count() > 0:
			var sub := _compute_scene_aabb(child as Node3D)
			if sub.size.length() > 0.01:
				if first:
					merged = sub
					first = false
				else:
					merged = merged.merge(sub)
	return merged

func _unhandled_input(event: InputEvent) -> void:
	# E key toggles edit mode
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and (key.keycode == KEY_E or key.physical_keycode == KEY_E):
			if not _is_text_focused():
				_toggle_edit_mode()
				get_viewport().set_input_as_handled()
				return

	# Edit mode handles its own input
	if _edit_mode:
		_handle_edit_input(event)
		return

	if _is_fly_toggle_event(event):
		fly_mode_enabled = not fly_mode_enabled
		_sync_mouse_look_state()
		_set_status("Fly mode %s" % ("enabled" if fly_mode_enabled else "disabled"))
		get_viewport().set_input_as_handled()
		return

	if not fly_mode_enabled:
		return

	if fly_look_requires_button and event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == look_mouse_button:
			_set_mouse_look(mouse_button_event.pressed)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _is_mouse_look_active:
		_apply_mouse_look((event as InputEventMouseMotion).relative)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if _edit_mode:
		# In edit mode, camera is manually controlled via _handle_edit_input
		return

	_sync_mouse_look_state()

	# Handle spin mode regardless of fly_mode or overlay visibility
	if _camera_mode == CameraMode.SPIN and _preview_camera:
		# Arrow key adjustments
		if Input.is_key_pressed(KEY_UP):
			_orbit_height += 4.0 * delta
		if Input.is_key_pressed(KEY_DOWN):
			_orbit_height = maxf(_orbit_height - 4.0 * delta, 0.5)
		if Input.is_key_pressed(KEY_LEFT):
			_orbit_radius = maxf(_orbit_radius - 4.0 * delta, 2.0)
		if Input.is_key_pressed(KEY_RIGHT):
			_orbit_radius += 4.0 * delta

		_spin_angle += _spin_speed * delta
		if _spin_angle > TAU:
			_spin_angle -= TAU
		var x := _orbit_center.x + _orbit_radius * cos(_spin_angle)
		var z := _orbit_center.z + _orbit_radius * sin(_spin_angle)
		_preview_camera.global_position = Vector3(x, _orbit_center.y + _orbit_height, z)
		_preview_camera.look_at(_orbit_center, Vector3.UP)
		return

	if not fly_mode_enabled:
		return

	if _overlay and _overlay.visible:
		return

	# Only allow WASD fly in STATIC or PLAYER modes
	if _camera_mode == CameraMode.STATIC or _camera_mode == CameraMode.PLAYER:
		_apply_fly_translation(delta)

# ---------------------------------------------------------------------------
# Camera mode API — called from overlay buttons
# ---------------------------------------------------------------------------

func set_camera_mode(mode_int: int) -> void:
	var mode: CameraMode = mode_int as CameraMode
	_camera_mode = mode

	match mode:
		CameraMode.STATIC:
			_apply_static_camera()
		CameraMode.ISOMETRIC:
			_apply_isometric_camera()
		CameraMode.SPIN:
			_start_spin_camera()
		CameraMode.PLAYER:
			_apply_player_camera()

	_set_status(_camera_mode_label(mode))

func _camera_mode_label(mode: CameraMode) -> String:
	match mode:
		CameraMode.STATIC:
			return "Camera: Static (default elevated view)"
		CameraMode.ISOMETRIC:
			return "Camera: Isometric (45° top-down)"
		CameraMode.SPIN:
			return "Camera: Spin (orbiting around center)"
		CameraMode.PLAYER:
			return "Camera: Player perspective (ground level, WASD fly)"
	return "Camera mode changed"

func _apply_static_camera() -> void:
	if not _preview_camera:
		return
	_preview_camera.global_position = _static_camera_position
	_preview_camera.rotation = _static_camera_rotation
	_fly_yaw = _static_camera_rotation.y
	_fly_pitch = _static_camera_rotation.x
	fly_mode_enabled = true

func _apply_isometric_camera() -> void:
	if not _preview_camera:
		return
	# Classic isometric-ish: elevated 45° angle from a corner
	_preview_camera.global_position = Vector3(10.0, 10.0, 10.0)
	_preview_camera.look_at(Vector3.ZERO, Vector3.UP)
	_fly_yaw = _preview_camera.rotation.y
	_fly_pitch = _preview_camera.rotation.x
	fly_mode_enabled = false

func _start_spin_camera() -> void:
	if not _preview_camera:
		return
	# Recenter on actual scene content every time spin starts
	_update_orbit_center()
	# Start spinning from current angle
	var cam_pos := _preview_camera.global_position
	var dx := cam_pos.x - _orbit_center.x
	var dz := cam_pos.z - _orbit_center.z
	_spin_angle = atan2(dz, dx)
	fly_mode_enabled = false

func _apply_player_camera() -> void:
	if not _preview_camera:
		return
	# Ground-level first-person view
	_preview_camera.global_position = Vector3(0.0, 1.6, 0.0)
	_preview_camera.rotation = Vector3(0.0, 0.0, 0.0)
	_fly_yaw = 0.0
	_fly_pitch = 0.0
	fly_mode_enabled = true

# ---------------------------------------------------------------------------
# Existing functionality
# ---------------------------------------------------------------------------

func _on_sequence_selected(sequence_name: String) -> void:
	if _overlay and _overlay.start_sequence_via_best_path(sequence_name):
		_set_status("Starting sequence: %s" % sequence_name)
		return

	push_warning("MapCatalogDesktop3D: Could not start sequence: %s" % sequence_name)
	_set_status("Could not start sequence: %s" % sequence_name)

func _on_map_selected(map_name: String) -> void:
	if _overlay and _overlay.load_map_via_best_path(map_name):
		_set_status("Loading map: %s" % map_name)
		return

	push_warning("MapCatalogDesktop3D: Could not load map: %s" % map_name)
	_set_status("Could not load map: %s" % map_name)

func _is_fly_toggle_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	return key_event.keycode == fly_toggle_key or key_event.physical_keycode == fly_toggle_key

func _set_mouse_look(enabled: bool) -> void:
	if not fly_mode_enabled:
		enabled = false

	if enabled and _overlay and _overlay.is_mouse_over_panel():
		enabled = false

	_is_mouse_look_active = enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE

func _sync_mouse_look_state() -> void:
	var overlay_blocking := _overlay and _overlay.is_mouse_over_panel()
	var should_capture := fly_mode_enabled and not overlay_blocking and (not fly_look_requires_button or _is_mouse_look_active)
	if should_capture and not _is_mouse_look_active:
		_set_mouse_look(true)
	elif not should_capture and _is_mouse_look_active:
		_set_mouse_look(false)
	elif not should_capture and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_mouse_look(relative: Vector2) -> void:
	if not _preview_camera:
		return

	_fly_yaw -= relative.x * fly_look_sensitivity
	_fly_pitch -= relative.y * fly_look_sensitivity
	_fly_pitch = clamp(_fly_pitch, -PI * 0.49, PI * 0.49)
	_preview_camera.rotation = Vector3(_fly_pitch, _fly_yaw, 0.0)

func _apply_fly_translation(delta: float) -> void:
	if not _preview_camera:
		return

	var forward := 0.0
	if _is_pressed(KEY_W):
		forward += 1.0
	if _is_pressed(KEY_S):
		forward -= 1.0

	var strafe := 0.0
	if _is_pressed(KEY_D):
		strafe += 1.0
	if _is_pressed(KEY_A):
		strafe -= 1.0

	var vertical := 0.0
	if _is_pressed(fly_up_key) or _is_pressed(KEY_SPACE) or _is_pressed(KEY_PAGEUP) or _is_pressed(KEY_R):
		vertical += 1.0
	if _is_pressed(fly_down_key) or _is_pressed(KEY_CTRL) or _is_pressed(KEY_PAGEDOWN) or _is_pressed(KEY_C) or _is_pressed(KEY_X) or _is_pressed(KEY_Z):
		vertical -= 1.0

	var move_vector := Vector3.ZERO
	move_vector += -_preview_camera.global_transform.basis.z * forward
	move_vector += _preview_camera.global_transform.basis.x * strafe
	move_vector += Vector3.UP * vertical

	if move_vector.length_squared() <= 0.0001:
		return

	var speed := fly_speed
	if _is_pressed(KEY_SHIFT):
		speed *= fly_boost_multiplier

	_preview_camera.global_position += move_vector.normalized() * speed * delta

func _is_pressed(keycode: Key) -> bool:
	return Input.is_key_pressed(keycode) or Input.is_physical_key_pressed(keycode)

func _set_status(text: String) -> void:
	if _status_label:
		var fly_state := "ON" if fly_mode_enabled else "OFF"
		var look_hint := "RMB look" if fly_look_requires_button else "Mouse steers"
		_status_label.text = "%s\nFly %s: F toggle, %s, WASD move, up E/Space/PgUp/R, down Q/Ctrl/PgDn/C/X/Z" % [text, fly_state, look_hint]

func _is_text_focused() -> bool:
	var vp := get_viewport()
	if not vp:
		return false
	var focused := vp.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

func _mark_clean_keep(node: Node) -> void:
	if node:
		node.add_to_group(CLEAN_KEEP_GROUP)

# ---------------------------------------------------------------------------
# EDIT MODE — click to add/remove cubes, mouse orbit/pan/zoom
# ---------------------------------------------------------------------------

var _edit_mode: bool = false
var _edit_paint_height: int = 1  # height value to paint (1-6)
var _edit_dragging_left: bool = false
var _edit_dragging_right: bool = false
var _edit_drag_start: Vector2 = Vector2.ZERO
var _edit_last_mouse: Vector2 = Vector2.ZERO
var _edit_drag_threshold: float = 6.0  # pixels before drag vs click
var _edit_cursor: MeshInstance3D = null  # wireframe cursor showing hovered cell

func _toggle_edit_mode() -> void:
	_edit_mode = not _edit_mode
	if _edit_mode:
		# Switch to edit camera: stop spin, enable mouse
		_spin_speed = 0.0
		fly_mode_enabled = false
		_set_mouse_look(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_create_edit_cursor()
		_load_grammar_pieces()
		_set_status("EDIT MODE — Click:+1h RClick:-1h Scroll:zoom Tab:stamps R:rotate M:mirror Ctrl+Z:undo Ctrl+S:save")
	else:
		_spin_speed = 0.3
		_remove_edit_cursor()
		_set_status("Edit mode off")

func _create_edit_cursor() -> void:
	if _edit_cursor:
		return
	_edit_cursor = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.05, 1.05, 1.05)
	_edit_cursor.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	_edit_cursor.material_override = mat
	_edit_cursor.visible = false
	add_child(_edit_cursor)

func _remove_edit_cursor() -> void:
	if _edit_cursor:
		_edit_cursor.queue_free()
		_edit_cursor = null

func _handle_edit_input(event: InputEvent) -> void:
	if not _edit_mode or not _preview_camera:
		return

	# Mouse button events
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		# Scroll wheel = zoom
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_radius = maxf(_orbit_radius - 1.0, 2.0)
			_update_edit_camera()
			get_viewport().set_input_as_handled()
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_radius += 1.0
			_update_edit_camera()
			get_viewport().set_input_as_handled()
			return

		# Left mouse button
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_edit_dragging_left = false
				_edit_drag_start = mb.position
				_edit_last_mouse = mb.position
			else:
				# Release — if no drag, treat as click (add/remove)
				if not _edit_dragging_left:
					_edit_click(mb.position, false)
				_edit_dragging_left = false
			get_viewport().set_input_as_handled()
			return

		# Right mouse button
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_edit_dragging_right = false
				_edit_drag_start = mb.position
				_edit_last_mouse = mb.position
			else:
				if not _edit_dragging_right:
					_edit_click(mb.position, true)
				_edit_dragging_right = false
			get_viewport().set_input_as_handled()
			return

	# Mouse motion = orbit (left) or pan (right)
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not _edit_dragging_left and mm.position.distance_to(_edit_drag_start) > _edit_drag_threshold:
				_edit_dragging_left = true
			if _edit_dragging_left:
				# Left drag = orbit
				_spin_angle -= mm.relative.x * 0.005
				_orbit_height += mm.relative.y * 0.05
				_orbit_height = maxf(_orbit_height, 0.5)
				_update_edit_camera()
				get_viewport().set_input_as_handled()

		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not _edit_dragging_right and mm.position.distance_to(_edit_drag_start) > _edit_drag_threshold:
				_edit_dragging_right = true
			if _edit_dragging_right:
				# Right drag = pan
				var right := _preview_camera.global_transform.basis.x
				var up := Vector3.UP
				var pan_speed := _orbit_radius * 0.002
				_orbit_center -= right * mm.relative.x * pan_speed
				_orbit_center += up * mm.relative.y * pan_speed
				_update_edit_camera()
				get_viewport().set_input_as_handled()
		else:
			# No button — update cursor
			_update_edit_cursor_pos(mm.position)
			# Update stamp preview position if stamp is active
			if _stamp_index >= 0:
				var stamp_result := _edit_raycast(mm.position)
				if not stamp_result.is_empty():
					var sn: Vector3 = stamp_result.normal
					var sg := _world_to_grid(stamp_result.position - sn * 0.1)
					_update_stamp_preview(sg.x, sg.z)

		_edit_last_mouse = mm.position
		return

	# Key events
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return

		# Number keys 1-6 set paint height
		if key.keycode >= KEY_1 and key.keycode <= KEY_6:
			_edit_paint_height = key.keycode - KEY_0
			_set_status("EDIT — Paint height: %d" % _edit_paint_height)
			get_viewport().set_input_as_handled()
			return

		# Ctrl+S = save
		if key.keycode == KEY_S and key.ctrl_pressed:
			_edit_save_map()
			get_viewport().set_input_as_handled()
			return

		# Ctrl+Z = undo
		if key.keycode == KEY_Z and key.ctrl_pressed and not key.shift_pressed:
			_undo()
			get_viewport().set_input_as_handled()
			return

		# Ctrl+Y or Ctrl+Shift+Z = redo
		if (key.keycode == KEY_Y and key.ctrl_pressed) or (key.keycode == KEY_Z and key.ctrl_pressed and key.shift_pressed):
			_redo()
			get_viewport().set_input_as_handled()
			return

		# Tab / Shift+Tab = browse stamp pieces
		if key.keycode == KEY_TAB:
			if key.shift_pressed:
				_stamp_select_prev()
			else:
				_stamp_select_next()
			get_viewport().set_input_as_handled()
			return

		# R = rotate stamp 90° CW
		if key.keycode == KEY_R and _stamp_index >= 0:
			_stamp_rotation = (_stamp_rotation + 90) % 360
			if _stamp_grid_pos.x >= 0:
				_update_stamp_preview(_stamp_grid_pos.x, _stamp_grid_pos.y)
			_set_status("STAMP — Rotation: %d°" % _stamp_rotation)
			get_viewport().set_input_as_handled()
			return

		# M = mirror stamp on X axis
		if key.keycode == KEY_M and _stamp_index >= 0:
			_stamp_mirror_x = not _stamp_mirror_x
			if _stamp_grid_pos.x >= 0:
				_update_stamp_preview(_stamp_grid_pos.x, _stamp_grid_pos.y)
			_set_status("STAMP — Mirror: %s" % ("ON" if _stamp_mirror_x else "OFF"))
			get_viewport().set_input_as_handled()
			return

		# Enter = place stamp
		if key.keycode == KEY_ENTER and _stamp_index >= 0:
			_stamp_place()
			get_viewport().set_input_as_handled()
			return

		# Escape = cancel stamp (or exit edit mode)
		if key.keycode == KEY_ESCAPE:
			if _stamp_index >= 0:
				_stamp_cancel()
			else:
				_toggle_edit_mode()
			get_viewport().set_input_as_handled()
			return

		# 0 = paint void (height 0)
		if key.keycode == KEY_0:
			_edit_paint_height = 0
			_set_status("EDIT — Paint height: 0 (void)")
			get_viewport().set_input_as_handled()
			return

func _update_edit_camera() -> void:
	if not _preview_camera:
		return
	var x := _orbit_center.x + _orbit_radius * cos(_spin_angle)
	var z := _orbit_center.z + _orbit_radius * sin(_spin_angle)
	_preview_camera.global_position = Vector3(x, _orbit_center.y + _orbit_height, z)
	_preview_camera.look_at(_orbit_center, Vector3.UP)

func _edit_raycast(screen_pos: Vector2) -> Dictionary:
	"""Raycast from camera through screen position. Returns {position, normal, collider} or empty."""
	if not _preview_camera:
		return {}
	var from := _preview_camera.project_ray_origin(screen_pos)
	var dir := _preview_camera.project_ray_normal(screen_pos)
	var space := get_world_3d().direct_space_state
	if not space:
		return {}
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 100.0)
	return space.intersect_ray(query)

func _world_to_grid(world_pos: Vector3) -> Vector3i:
	"""Convert world position to grid coordinates."""
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	return Vector3i(roundi(world_pos.x / total_size), roundi(world_pos.y / total_size), roundi(world_pos.z / total_size))

func _update_edit_cursor_pos(screen_pos: Vector2) -> void:
	if not _edit_cursor:
		return
	var result := _edit_raycast(screen_pos)
	if result.is_empty():
		_edit_cursor.visible = false
		return
	var hit_normal: Vector3 = result.normal
	var grid_pos := _world_to_grid(result.position - hit_normal * 0.1)
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	# Show cursor at the top of the column
	var sc := _get_structure_component()
	if sc and grid_pos.x >= 0 and grid_pos.x < sc.grid_x and grid_pos.z >= 0 and grid_pos.z < sc.grid_z:
		var top_y := 0
		for y in range(sc.grid_y - 1, -1, -1):
			if sc.grid[grid_pos.x][y][grid_pos.z]:
				top_y = y
				break
		_edit_cursor.global_position = Vector3(grid_pos.x, top_y, grid_pos.z) * total_size
		_edit_cursor.visible = true
	else:
		_edit_cursor.visible = false

func _edit_click(screen_pos: Vector2, is_right: bool) -> void:
	"""2.5D heightmap editor: Left click = +1 layer, Right click = -1 layer.
	Hold Shift + click to set column to exact paint_height (number keys 1-6).
	If a stamp is active, click places the stamp instead."""
	var result := _edit_raycast(screen_pos)
	if result.is_empty():
		return

	# If stamp is active, place it on click
	if _stamp_index >= 0 and not is_right:
		var hit_normal_s: Vector3 = result.normal
		var grid_pos_s := _world_to_grid(result.position - hit_normal_s * 0.1)
		_stamp_grid_pos = Vector2i(grid_pos_s.x, grid_pos_s.z)
		_stamp_place()
		return
	elif _stamp_index >= 0 and is_right:
		_stamp_cancel()
		return

	var hit_pos: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	var sc := _get_structure_component()
	if not sc:
		return

	# Find which x,z column we hit
	var grid_pos := _world_to_grid(hit_pos - hit_normal * 0.1)
	var gx: int = grid_pos.x
	var gz: int = grid_pos.z

	if gx < 0 or gx >= sc.grid_x or gz < 0 or gz >= sc.grid_z:
		return

	# Get current height at this column
	var current_height := 0
	for y in range(sc.grid_y - 1, -1, -1):
		if sc.grid[gx][y][gz]:
			current_height = y + 1
			break

	# Determine target height
	var target_height: int
	if Input.is_key_pressed(KEY_SHIFT):
		# Shift+click: set to exact paint height (or 0 for right click)
		target_height = 0 if is_right else _edit_paint_height
	else:
		# Normal click: increment/decrement by 1
		if is_right:
			target_height = maxi(current_height - 1, 0)
		else:
			target_height = mini(current_height + 1, sc.grid_y)

	if target_height == current_height:
		return

	_push_undo()

	# Remove cubes above target height
	for y in range(target_height, sc.grid_y):
		if sc.grid[gx][y][gz]:
			sc.remove_cube_at(gx, y, gz)

	# Add cubes below target height that are missing
	for y in range(0, target_height):
		if not sc.grid[gx][y][gz]:
			sc.add_cube_at(gx, y, gz)

	# Update the structure data in data component so saves are correct
	_update_structure_data(gx, gz, target_height)

	_set_status("EDIT — Column %d,%d → h=%d" % [gx, gz, target_height])

func _update_structure_data(x: int, z: int, height: int) -> void:
	"""Update the underlying structure layout data at x,z to the new height."""
	if not _grid_system:
		return
	var dc = _grid_system.get("data_component") if "data_component" in _grid_system else null
	if not dc:
		return
	var sd = dc.get_structure_data() if dc.has_method("get_structure_data") else null
	if not sd or not ("layout_data" in sd):
		return
	var layout: Array = sd.layout_data
	if z < layout.size() and x < layout[z].size():
		layout[z][x] = str(height)

func _remove_collision_at(grid_pos: Vector3i) -> void:
	"""Remove collision body at grid position."""
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	var target_world := Vector3(grid_pos.x, grid_pos.y, grid_pos.z) * total_size
	for body in get_tree().get_nodes_in_group("grid_cubes"):
		if body is StaticBody3D and body.position.distance_to(target_world) < 0.1:
			body.queue_free()
			return

func _get_structure_component() -> GridStructureComponent:
	if _grid_system and "structure_component" in _grid_system:
		return _grid_system.structure_component as GridStructureComponent
	return null

func _edit_save_map() -> void:
	"""Save current grid state back to map_data.json."""
	if not _grid_system:
		_set_status("EDIT — No grid system to save")
		return

	var sc := _get_structure_component()
	var dc = _grid_system.get("data_component") if "data_component" in _grid_system else null
	if not sc or not dc:
		_set_status("EDIT — Missing structure/data component")
		return

	# Get structure layout — already updated live by _update_structure_data
	var new_structure: Array = []
	var sd = dc.get_structure_data() if dc and dc.has_method("get_structure_data") else null
	if sd and "layout_data" in sd and sd.layout_data.size() > 0:
		new_structure = sd.layout_data
	else:
		# Fallback: rebuild from grid state
		for z in range(sc.grid_z):
			var row: Array = []
			for x in range(sc.grid_x):
				var height := 0
				for y in range(sc.grid_y - 1, -1, -1):
					if sc.grid[x][y][z]:
						height = y + 1
						break
				row.append(str(height))
			new_structure.append(row)

	# Find the map_data.json path
	var map_name: String = _grid_system.map_name if "map_name" in _grid_system else ""
	if map_name.is_empty():
		_set_status("EDIT — No map name, can't save")
		return

	var candidate_paths: Array[String] = [
		"res://commons/maps/%s/map_data.json" % map_name,
	]
	var save_path := ""
	for p in candidate_paths:
		if FileAccess.file_exists(p):
			save_path = p
			break

	if save_path.is_empty():
		_set_status("EDIT — Can't find map_data.json for '%s'" % map_name)
		return

	# Read existing JSON, update structure layer, write back
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		_set_status("EDIT — Can't read %s" % save_path)
		return
	var json_text := file.get_as_text()
	file.close()

	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		_set_status("EDIT — JSON parse error in %s" % save_path)
		return
	var data: Dictionary = parser.data
	if not data.has("layers"):
		data["layers"] = {}
	data["layers"]["structure"] = new_structure

	# Update dimensions
	if data.has("map_info") and data["map_info"] is Dictionary:
		data["map_info"]["dimensions"] = {
			"width": sc.grid_x,
			"depth": sc.grid_z,
			"max_height": sc.grid_y
		}

	var out_file := FileAccess.open(save_path, FileAccess.WRITE)
	if not out_file:
		_set_status("EDIT — Can't write %s" % save_path)
		return
	# Use standard JSON.stringify then compact inner arrays onto single lines.
	# Turns multi-line ["1",\n"2",\n"3"] into ["1","2","3"] for readability.
	var json_out := JSON.stringify(data, "\t")
	json_out = _compact_inner_arrays(json_out)
	out_file.store_string(json_out)
	out_file.close()
	_set_status("EDIT — Saved to %s ✓" % save_path)

# ---------------------------------------------------------------------------
# UNDO / REDO — snapshot the whole layout + utility layer before each edit
# ---------------------------------------------------------------------------

const UNDO_MAX := 50
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []

func _snapshot_state() -> Dictionary:
	"""Capture current layout + utility state for undo."""
	var dc = _grid_system.get("data_component") if _grid_system and "data_component" in _grid_system else null
	if not dc:
		return {}
	var sd = dc.get_structure_data() if dc.has_method("get_structure_data") else null
	if not sd or not ("layout_data" in sd):
		return {}
	# Deep copy layout
	var layout_copy: Array = []
	for row in sd.layout_data:
		var row_copy: Array = []
		for cell in row:
			row_copy.append(str(cell))
		layout_copy.append(row_copy)
	# Deep copy utility layer if present
	var utility_copy: Array = []
	var map_data := _get_current_map_data()
	if map_data.has("layers") and map_data.layers.has("utility"):
		for row in map_data.layers.utility:
			var row_copy: Array = []
			for cell in row:
				row_copy.append(str(cell) if cell != null else "")
			utility_copy.append(row_copy)
	return {"layout": layout_copy, "utility": utility_copy}

func _push_undo() -> void:
	"""Push current state onto undo stack (call BEFORE making changes)."""
	var snap := _snapshot_state()
	if snap.is_empty():
		return
	_undo_stack.append(snap)
	if _undo_stack.size() > UNDO_MAX:
		_undo_stack.pop_front()
	_redo_stack.clear()

func _undo() -> void:
	if _undo_stack.is_empty():
		_set_status("EDIT — Nothing to undo")
		return
	# Push current state to redo before restoring
	var current := _snapshot_state()
	if not current.is_empty():
		_redo_stack.append(current)
	var prev: Dictionary = _undo_stack.pop_back()
	_restore_state(prev)
	_set_status("EDIT — Undo (%d left)" % _undo_stack.size())

func _redo() -> void:
	if _redo_stack.is_empty():
		_set_status("EDIT — Nothing to redo")
		return
	var current := _snapshot_state()
	if not current.is_empty():
		_undo_stack.append(current)
	var next: Dictionary = _redo_stack.pop_back()
	_restore_state(next)
	_set_status("EDIT — Redo (%d left)" % _redo_stack.size())

func _restore_state(state: Dictionary) -> void:
	"""Apply a snapshot back to the grid — rebuild structure from layout."""
	var sc := _get_structure_component()
	var dc = _grid_system.get("data_component") if _grid_system and "data_component" in _grid_system else null
	if not sc or not dc:
		return

	var layout: Array = state.get("layout", [])
	if layout.is_empty():
		return

	# Write layout back to data component
	var sd = dc.get_structure_data() if dc.has_method("get_structure_data") else null
	if sd and "layout_data" in sd:
		sd.layout_data = layout

	# Rebuild the grid visuals: clear all cubes, re-add from layout
	for x in range(sc.grid_x):
		for y in range(sc.grid_y):
			for z in range(sc.grid_z):
				if sc.grid[x][y][z]:
					sc.remove_cube_at(x, y, z)

	for z in range(mini(layout.size(), sc.grid_z)):
		for x in range(mini(layout[z].size(), sc.grid_x)):
			var h: int = int(str(layout[z][x]))
			for y in range(h):
				if y < sc.grid_y:
					sc.add_cube_at(x, y, z)

	# Restore utility layer if present
	var utility: Array = state.get("utility", [])
	if not utility.is_empty():
		var map_data := _get_current_map_data()
		if map_data.has("layers"):
			map_data.layers["utility"] = utility

func _get_current_map_data() -> Dictionary:
	"""Get the parsed map_data dict from the data component."""
	var dc = _grid_system.get("data_component") if _grid_system and "data_component" in _grid_system else null
	if not dc:
		return {}
	if dc.has_method("get_map_data"):
		var d = dc.get_map_data()
		if d is Dictionary:
			return d
	# Fallback: read from file
	var map_name: String = _grid_system.map_name if _grid_system and "map_name" in _grid_system else ""
	if map_name.is_empty():
		return {}
	var path := "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	return parser.data if parser.data is Dictionary else {}

# ---------------------------------------------------------------------------
# STAMP SYSTEM — paste voxel grammar pieces onto the grid
# ---------------------------------------------------------------------------

const GRAMMAR_PATH := "res://commons/maps/Structure_Examples/voxel_grammar_subset.json"

var _stamp_pieces: Array[Dictionary] = []  # loaded grammar pieces
var _stamp_index: int = -1                 # -1 = no stamp selected
var _stamp_rotation: int = 0               # 0, 90, 180, 270
var _stamp_mirror_x: bool = false
var _stamp_preview_meshes: Array[MeshInstance3D] = []
var _stamp_grid_pos: Vector2i = Vector2i(-1, -1)  # last hovered grid x,z

func _load_grammar_pieces() -> void:
	"""Load all pieces from the voxel grammar JSON."""
	if not _stamp_pieces.is_empty():
		return  # already loaded
	if not FileAccess.file_exists(GRAMMAR_PATH):
		push_warning("MapCatalogDesktop3D: Grammar file not found: %s" % GRAMMAR_PATH)
		return
	var file := FileAccess.open(GRAMMAR_PATH, FileAccess.READ)
	if not file:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_warning("MapCatalogDesktop3D: Grammar JSON parse error")
		return
	var data: Dictionary = parser.data
	if not data.has("pieces"):
		return
	for piece in data.pieces:
		if piece is Dictionary and piece.has("heightmap"):
			_stamp_pieces.append(piece)
	_set_status("EDIT — Loaded %d grammar pieces" % _stamp_pieces.size())

func _stamp_select_next() -> void:
	if _stamp_pieces.is_empty():
		_load_grammar_pieces()
	if _stamp_pieces.is_empty():
		return
	_stamp_index = (_stamp_index + 1) % _stamp_pieces.size()
	_stamp_rotation = 0
	_stamp_mirror_x = false
	var piece: Dictionary = _stamp_pieces[_stamp_index]
	_set_status("STAMP [%d/%d]: %s (%s) — R:rotate M:mirror Enter:place Esc:cancel" % [
		_stamp_index + 1, _stamp_pieces.size(),
		piece.get("name", "?"), piece.get("id", "?")])

func _stamp_select_prev() -> void:
	if _stamp_pieces.is_empty():
		_load_grammar_pieces()
	if _stamp_pieces.is_empty():
		return
	_stamp_index = (_stamp_index - 1) if _stamp_index > 0 else (_stamp_pieces.size() - 1)
	_stamp_rotation = 0
	_stamp_mirror_x = false
	var piece: Dictionary = _stamp_pieces[_stamp_index]
	_set_status("STAMP [%d/%d]: %s (%s) — R:rotate M:mirror Enter:place Esc:cancel" % [
		_stamp_index + 1, _stamp_pieces.size(),
		piece.get("name", "?"), piece.get("id", "?")])

func _stamp_cancel() -> void:
	_stamp_index = -1
	_stamp_rotation = 0
	_stamp_mirror_x = false
	_clear_stamp_preview()
	_set_status("EDIT MODE — stamp cancelled")

func _get_transformed_heightmap() -> Array:
	"""Return the current stamp piece heightmap after rotation + mirror."""
	if _stamp_index < 0 or _stamp_index >= _stamp_pieces.size():
		return []
	var piece: Dictionary = _stamp_pieces[_stamp_index]
	var hm: Array = piece.get("heightmap", [])
	if hm.is_empty():
		return []

	# Deep copy
	var result: Array = []
	for row in hm:
		var r: Array = []
		for cell in row:
			r.append(cell)
		result.append(r)

	# Apply rotation (0, 90, 180, 270) — rotate the 2D grid clockwise
	var rotations := _stamp_rotation / 90
	for _i in range(rotations):
		result = _rotate_90_cw(result)

	# Apply mirror on X axis
	if _stamp_mirror_x:
		for row in result:
			row.reverse()

	return result

static func _rotate_90_cw(grid: Array) -> Array:
	"""Rotate a 2D array 90° clockwise."""
	var rows: int = grid.size()
	if rows == 0:
		return []
	var cols: int = grid[0].size()
	var rotated: Array = []
	for c in range(cols):
		var new_row: Array = []
		for r in range(rows - 1, -1, -1):
			new_row.append(grid[r][c])
		rotated.append(new_row)
	return rotated

func _update_stamp_preview(gx: int, gz: int) -> void:
	"""Show/update a transparent preview of the stamp at grid position gx,gz."""
	_clear_stamp_preview()
	_stamp_grid_pos = Vector2i(gx, gz)

	var hm := _get_transformed_heightmap()
	if hm.is_empty():
		return

	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 1.0, 0.4, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true

	for rz in range(hm.size()):
		var row: Array = hm[rz]
		for rx in range(row.size()):
			var h: int = int(str(row[rx]))
			if h <= 0:
				continue
			for y in range(h):
				var mesh_inst := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(0.95, 0.95, 0.95)
				mesh_inst.mesh = box
				mesh_inst.material_override = mat
				mesh_inst.global_position = Vector3(
					(gx + rx) * total_size,
					y * total_size,
					(gz + rz) * total_size
				)
				add_child(mesh_inst)
				_stamp_preview_meshes.append(mesh_inst)

func _clear_stamp_preview() -> void:
	for m in _stamp_preview_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_stamp_preview_meshes.clear()

func _stamp_place() -> void:
	"""Place the current stamp at the previewed position."""
	if _stamp_index < 0 or _stamp_grid_pos.x < 0:
		return

	var sc := _get_structure_component()
	if not sc:
		return

	var hm := _get_transformed_heightmap()
	if hm.is_empty():
		return

	_push_undo()

	for rz in range(hm.size()):
		var row: Array = hm[rz]
		for rx in range(row.size()):
			var gx: int = _stamp_grid_pos.x + rx
			var gz: int = _stamp_grid_pos.y + rz
			if gx < 0 or gx >= sc.grid_x or gz < 0 or gz >= sc.grid_z:
				continue
			var target_h: int = int(str(row[rx]))

			# Get current height
			var current_h := 0
			for y in range(sc.grid_y - 1, -1, -1):
				if sc.grid[gx][y][gz]:
					current_h = y + 1
					break

			# Remove cubes above target
			for y in range(target_h, sc.grid_y):
				if sc.grid[gx][y][gz]:
					sc.remove_cube_at(gx, y, gz)

			# Add cubes below target
			for y in range(target_h):
				if y < sc.grid_y and not sc.grid[gx][y][gz]:
					sc.add_cube_at(gx, y, gz)

			_update_structure_data(gx, gz, target_h)

	var piece: Dictionary = _stamp_pieces[_stamp_index]
	_set_status("EDIT — Stamped '%s' at %d,%d" % [piece.get("name", "?"), _stamp_grid_pos.x, _stamp_grid_pos.y])
	_clear_stamp_preview()
	# Keep stamp selected for repeated placement
	_update_stamp_preview(_stamp_grid_pos.x, _stamp_grid_pos.y)

# ---------------------------------------------------------------------------
# JSON compact helper
# ---------------------------------------------------------------------------

static func _compact_inner_arrays(json: String) -> String:
	"""Collapse leaf arrays (no nested [] or {}) onto single lines.
	Uses regex to find arrays whose contents are only primitives."""
	var regex := RegEx.new()
	# Match [...] where the inside contains NO [ ] { } — i.e. leaf arrays only
	regex.compile("\\[([^\\[\\]{}]+)\\]")
	var result := json
	var prev := ""
	while result != prev:
		prev = result
		for m in regex.search_all(result):
			var full_match: String = m.get_string()
			var inner: String = m.get_string(1)
			# Strip newlines/tabs, tighten spacing
			var compacted := inner.replace("\n", "").replace("\t", "").strip_edges()
			while compacted.contains("  "):
				compacted = compacted.replace("  ", " ")
			# Remove spaces after commas: "1", "2" -> "1","2"
			compacted = compacted.replace(", ", ",")
			result = result.replace(full_match, "[" + compacted + "]")
		# Break after one pass to avoid infinite loop on identical arrays
		break
	return result
