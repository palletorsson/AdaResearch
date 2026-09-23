extends Node3D
## The three existing joystick scenes share printing and pointer input. The XR
## child remains the authority: radians in, degrees out, steps measured in degrees.
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface = preload("res://commons/ui/control_value_surface.gd")
const POINTER_LAYERS := (1 << 20) | (1 << 22)
const DRAG_DEGREES_PER_METRE := 450.0
var _joint: Node3D
var _handle: Node3D
var _reading: Dictionary = {}
var _pointer: Node3D
var _start: Vector3
var _start_angles: Vector2

func _ready() -> void:
	set_process(false)
	_joint = get_node("JoystickOrigin/InteractableJoystick")
	_handle = _joint.get_node("HandleOrigin/InteractableHandle")
	var face_material := StandardMaterial3D.new()
	face_material.albedo_color = Color(.82,.84,.77)
	face_material.roughness = .7
	get_node("Frame/MeshInstance3D").material_override = face_material
	# XRToolsPointerEvent delivers to the hit collider, not to its ancestors.
	for body in [get_node("Frame"), _joint.get_node("JoystickBody"), _handle]:
		body.collision_layer |= POINTER_LAYERS
	_joint.joystick_moved.connect(_on_moved)
	_joint.grabbed.connect(func(_node): _cancel_pointer(false))
	var rule := "RETURNS" if _joint.default_on_release else ("%s° / STAYS" % str(_joint.joystick_x_steps) if _joint.joystick_x_steps > 0 else "STAYS")
	var label := BakedText.make_label_mesh("XY · " + rule, Color(.08,.10,.12), Vector2(.178,.021), 2200, true)
	label.name = "ReleaseRule"
	label.position = Vector3(0,.08,.009)
	add_child(label)
	_reading = ValueSurface.build(self,Vector2(.176,.038),Vector3(0,-.115,.009))
	_reading.viewport.size = Vector2i(440,95)
	_reading.viewport.get_child(0).size = Vector2(440,95)
	_reading.label.size = Vector2(440,95)
	_reading.label.add_theme_font_size_override("font_size",37)
	_on_moved(_joint.joystick_x_position,_joint.joystick_y_position)

func get_angles_degrees() -> Vector2:
	return Vector2(_joint.joystick_x_position,_joint.joystick_y_position)

func set_angles_degrees(value: Vector2) -> void:
	_joint.move_joystick(deg_to_rad(value.x),deg_to_rad(value.y))
	_on_moved(_joint.joystick_x_position,_joint.joystick_y_position)

func _on_moved(x: float, y: float) -> void:
	var text := "X %+.1f°  Y %+.1f°" % [x,y]
	if not _reading.is_empty() and _reading.label.text != text:
		_reading.label.text = text
		_reading.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func pointer_event(event: XRToolsPointerEvent) -> void:
	if not event or not is_instance_valid(event.pointer) or not _joint.grabbed_handles.is_empty(): return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if is_instance_valid(_pointer): return
			_pointer = event.pointer
			_start = to_local(event.position)
			_start_angles = get_angles_degrees()
			set_process(true)
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer == _pointer:
				var offset := to_local(event.position)-_start
				set_angles_degrees(_start_angles+Vector2(offset.x,-offset.y)*DRAG_DEGREES_PER_METRE)
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			if event.pointer == _pointer: _cancel_pointer(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(_pointer): _cancel_pointer(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(_pointer): _cancel_pointer(true)

func _cancel_pointer(apply_release: bool) -> void:
	_pointer = null
	set_process(false)
	if apply_release and _joint.default_on_release:
		set_angles_degrees(Vector2(_joint.default_x_position,_joint.default_y_position))
