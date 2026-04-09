extends Node3D

## Map Studio — standalone map editor, no dependency on MapCatalogDesktop3D
## Overlays handle UI. This script handles camera + grid system.

const GRID_SYSTEM_SCENE_PATH := "res://commons/grid/grid_system.tscn"
const CLEAN_KEEP_GROUP := "map_studio_keep"

@onready var _camera: Camera3D = $PreviewCamera
@onready var _overlay: DesktopMapSwitcherOverlay = $DesktopMapSwitcherOverlay
@onready var _grid_editor: MapGridEditorOverlay = $MapGridEditorOverlay

var _grid_system: Node3D = null
var _fly_yaw: float = 0.0
var _fly_pitch: float = -0.26
var _is_fly_mode: bool = false
var _is_mouse_look: bool = false

func _ready() -> void:
	if _camera:
		_fly_yaw = _camera.rotation.y
		_fly_pitch = _camera.rotation.x

	_mark_keep($PreviewCamera)
	_mark_keep($WorldEnvironment)
	_mark_keep($KeyLight)
	_mark_keep($FillLight)
	_mark_keep($Floor)
	_mark_keep($StatusLabel)

	if _overlay and _overlay.has_signal("map_loaded"):
		_overlay.map_loaded.connect(_on_map_loaded)

func _mark_keep(node: Node) -> void:
	if node:
		node.add_to_group(CLEAN_KEEP_GROUP)

func _on_map_loaded(map_name: String) -> void:
	$StatusLabel.text = map_name

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F:
				_is_fly_mode = not _is_fly_mode
			KEY_ESCAPE:
				_is_fly_mode = false
				_is_mouse_look = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_mouse_look = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _is_mouse_look else Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.position += _camera.basis.z * -1.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.position += _camera.basis.z * 1.0

	if event is InputEventMouseMotion and _is_mouse_look:
		_fly_yaw -= event.relative.x * 0.003
		_fly_pitch = clampf(_fly_pitch - event.relative.y * 0.003, -1.4, 1.4)
		_camera.rotation = Vector3(_fly_pitch, _fly_yaw, 0)

func _process(delta: float) -> void:
	if not _is_fly_mode or not _camera:
		return
	var speed := 4.0
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= 2.5
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir -= _camera.basis.z
	if Input.is_key_pressed(KEY_S): dir += _camera.basis.z
	if Input.is_key_pressed(KEY_A): dir -= _camera.basis.x
	if Input.is_key_pressed(KEY_D): dir += _camera.basis.x
	if Input.is_key_pressed(KEY_E): dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q): dir -= Vector3.UP
	if dir.length() > 0:
		_camera.position += dir.normalized() * speed * delta
