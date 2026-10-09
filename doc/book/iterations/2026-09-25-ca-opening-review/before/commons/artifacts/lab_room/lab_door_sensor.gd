extends Node3D
class_name LabDoorSensor

## A two-panel sliding door that opens when a body enters its Area3D sensor.
## Used by lab_room — see _build_sliding_door() there. Two panels slide
## symmetrically outward into wall pockets; an indicator light on the
## sensor box turns green when open, accent-coloured when closed.

@export var left_panel: MeshInstance3D
@export var right_panel: MeshInstance3D
@export var indicator: MeshInstance3D
@export var area: Area3D
@export var panel_width: float = 0.7
@export var open_offset: float = 0.7   # how far panels slide outward
@export var open_seconds: float = 0.45
@export var open_color: Color = Color(0.4, 1.0, 0.55)
@export var closed_color: Color = Color(0.9, 0.22, 0.27)
## When TRUE the proximity Area3D opens the door on body_entered (legacy
## auto-airlock behaviour). When FALSE the door stays CLOSED on start
## and only opens when an external trigger calls _open_door() — e.g. the
## palm_scanner emitting palm_scanned. The default is now FALSE because
## the science-door pattern expects you to PROVE before you pass.
@export var auto_open_on_proximity: bool = false

var _open: bool = false
var _tween: Tween = null
var _left_closed_x: float = 0.0
var _right_closed_x: float = 0.0


func _ready() -> void:
	# Register so external triggers (palm_scanner, key_card readers,
	# scripted events) can find this handler via
	# get_tree().get_nodes_in_group("lab_door_sensors").
	add_to_group("lab_door_sensors")
	# Cache closed positions so we can return panels exactly there.
	if left_panel:
		_left_closed_x = left_panel.position.x
	if right_panel:
		_right_closed_x = right_panel.position.x
	# Only hook the proximity area when the legacy auto-airlock mode is
	# explicitly enabled. By default the door waits for an external
	# trigger (palm_scanner, key_card, scripted event).
	if area and auto_open_on_proximity:
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)
	# Door starts CLOSED — indicator reads red, panels at cached x.
	_open = false
	_set_indicator_color(closed_color)


func _on_body_entered(_body: Node3D) -> void:
	if not auto_open_on_proximity:
		return
	_open_door()


func _on_body_exited(_body: Node3D) -> void:
	if area == null or not auto_open_on_proximity:
		return
	# Only close when no bodies remain in the trigger volume.
	if area.get_overlapping_bodies().size() == 0:
		_close_door()


func _open_door() -> void:
	if _open:
		return
	_open = true
	_tween_panels(open_offset)
	_set_indicator_color(open_color)


func _close_door() -> void:
	if not _open:
		return
	_open = false
	_tween_panels(0.0)
	_set_indicator_color(closed_color)


func _tween_panels(offset: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	if left_panel:
		var lp_target := Vector3(_left_closed_x - offset, left_panel.position.y, left_panel.position.z)
		_tween.tween_property(left_panel, "position", lp_target, open_seconds)
	if right_panel:
		var rp_target := Vector3(_right_closed_x + offset, right_panel.position.y, right_panel.position.z)
		_tween.tween_property(right_panel, "position", rp_target, open_seconds)


func _set_indicator_color(c: Color) -> void:
	if not indicator:
		return
	var mat := indicator.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = c
	mat.emission = c
