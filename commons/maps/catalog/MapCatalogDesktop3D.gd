class_name MapCatalogDesktop3D
extends Node3D

## Standalone desktop catalog for browsing all sequence JSON maps.
## Uses MapBrowser3D and delegates loading to the global SceneManager.

const CLEAN_KEEP_GROUP := "map_switcher_ui_keep"

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
@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _key_light: DirectionalLight3D = $KeyLight
@onready var _fill_light: DirectionalLight3D = $FillLight

var _is_mouse_look_active: bool = false
var _fly_yaw: float = 0.0
var _fly_pitch: float = 0.0

func _ready() -> void:
	if not _map_browser:
		push_warning("MapCatalogDesktop3D: MapBrowser3D node not found")
		return
	
	if _map_browser.has_signal("sequence_selected"):
		_map_browser.sequence_selected.connect(_on_sequence_selected)
	
	if _map_browser.has_signal("map_selected"):
		_map_browser.map_selected.connect(_on_map_selected)

	if _preview_camera:
		_fly_yaw = _preview_camera.rotation.y
		_fly_pitch = _preview_camera.rotation.x

	_mark_clean_keep(_preview_camera)
	_mark_clean_keep(_map_browser)
	_mark_clean_keep(_status_label)
	_mark_clean_keep(_world_environment)
	_mark_clean_keep(_key_light)
	_mark_clean_keep(_fill_light)

	_sync_mouse_look_state()
	
	_set_status("Loaded sequence registry catalog")

func _unhandled_input(event: InputEvent) -> void:
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
	_sync_mouse_look_state()

	if not fly_mode_enabled:
		return

	if _overlay and _overlay.visible:
		return

	_apply_fly_translation(delta)

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

	if enabled and _overlay and _overlay.visible:
		enabled = false

	_is_mouse_look_active = enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE

func _sync_mouse_look_state() -> void:
	var should_capture := fly_mode_enabled and (not _overlay or not _overlay.visible) and (not fly_look_requires_button or _is_mouse_look_active)
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

func _mark_clean_keep(node: Node) -> void:
	if node:
		node.add_to_group(CLEAN_KEEP_GROUP)
