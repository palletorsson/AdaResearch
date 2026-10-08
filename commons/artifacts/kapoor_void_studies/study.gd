extends Node3D

## Desktop orbit viewer for the Kapoor void-study companion.
const Exhibits := preload("res://commons/artifacts/kapoor_void_studies/kapoor_void_studies.tscn")

var _exhibit: Node3D
var _camera: Camera3D
var _readout: Label
var _target := Vector3(0.0, 1.5, 0.0)
var _yaw := 0.0
var _pitch := 0.18
var _distance := 21.0
var _dragging := false
var _black_surface := true
var _lights_on := true


func _ready() -> void:
	_exhibit = Exhibits.instantiate()
	add_child(_exhibit)
	_camera = Camera3D.new()
	_camera.name = "OrbitCamera"
	_camera.fov = 48.0
	_camera.near = 0.05
	_camera.far = 80.0
	add_child(_camera)
	_camera.make_current()
	_update_camera()
	_make_hud()


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_readout = Label.new()
	_readout.position = Vector2(22.0, 20.0)
	_readout.add_theme_color_override("font_color", Color(0.94, 0.89, 0.91))
	_readout.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.04, 0.95))
	_readout.add_theme_constant_override("shadow_offset_x", 2)
	_readout.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(_readout)
	_refresh_hud()


func _refresh_hud() -> void:
	if is_instance_valid(_readout):
		_readout.text = "KAPOOR / VOID STUDIES\nDrag: orbit   Wheel: distance\n1: descent   2: field   3: wall   4: wide\nB: near-black / chalk   L: lights   R: reset"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(5.0, _distance - 1.2)
			_update_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(29.0, _distance + 1.2)
			_update_camera()
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * 0.004
		_pitch = clampf(_pitch + event.relative.y * 0.003, -0.12, 0.75)
		_update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_focus(Vector3(-5.4, 1.2, 0.0), 8.0)
			KEY_2:
				_focus(Vector3(0.0, 1.1, 0.0), 9.0)
			KEY_3:
				_focus(Vector3(5.6, 2.0, 0.0), 8.5)
			KEY_4, KEY_R:
				_reset_view()
			KEY_B:
				_black_surface = not _black_surface
				_exhibit.set_black_surface(_black_surface)
				_refresh_hud()
			KEY_L:
				_lights_on = not _lights_on
				_exhibit.set_studio_lights(_lights_on)
				_refresh_hud()


func _focus(at: Vector3, distance: float) -> void:
	_target = at
	_distance = distance
	_yaw = 0.0
	_pitch = 0.15
	_update_camera()


func _reset_view() -> void:
	_target = Vector3(0.0, 1.5, 0.0)
	_distance = 21.0
	_yaw = 0.0
	_pitch = 0.18
	_black_surface = true
	_lights_on = true
	_exhibit.set_black_surface(true)
	_exhibit.set_studio_lights(true)
	_update_camera()
	_refresh_hud()


func _update_camera() -> void:
	if not is_instance_valid(_camera):
		return
	var direction := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	_camera.position = _target + direction * _distance
	_camera.look_at(_target, Vector3.UP)
