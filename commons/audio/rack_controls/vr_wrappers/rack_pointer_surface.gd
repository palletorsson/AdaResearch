# A flat, pointable screen. Converts world-space hits into viewport GUI input.
# Shared by complete module faces and individual cased rack controls.
extends StaticBody3D

var viewport: SubViewport
var screen_size := Vector2.ONE
var _pressed := false
var _owner: Node3D
var _last_pixel := Vector2.ZERO

func configure(target: SubViewport, dimensions: Vector2) -> void:
	viewport = target
	screen_size = dimensions
	collision_layer = (1 << 20) | (1 << 22)
	collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "HitShape"
	var box := BoxShape3D.new()
	box.size = Vector3(dimensions.x, dimensions.y, .004)
	shape.shape = box
	add_child(shape)
	set_process(false)

func pixel_at(world_point: Vector3) -> Vector2:
	var local := to_local(world_point)
	var pixels := Vector2(viewport.size)
	return Vector2(clampf(local.x / screen_size.x + .5, 0, 1),
		clampf(.5 - local.y / screen_size.y, 0, 1)) * pixels

func pointer_event(event) -> void:
	if not is_instance_valid(viewport): return
	if _pressed and event.pointer != _owner: return
	_last_pixel = pixel_at(event.position)
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if _pressed: return
			_owner = event.pointer
			_pressed = true
			set_process(true)
			_button(true)
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			cancel()
		XRToolsPointerEvent.Type.MOVED:
			var motion := InputEventMouseMotion.new()
			motion.position = _last_pixel
			motion.global_position = _last_pixel
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT if _pressed else 0
			viewport.push_input(motion, true)

## Release on cancellation too, so spring controls and momentary buttons reset.
func cancel() -> void:
	if _pressed and is_instance_valid(viewport):
		_button(false)
	_pressed = false
	_owner = null
	set_process(false)

func _button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = _last_pixel
	event.global_position = _last_pixel
	viewport.push_input(event, true)

func _process(_delta: float) -> void:
	if not is_instance_valid(_owner): cancel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel()
