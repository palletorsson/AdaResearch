extends Node3D
## One pointer owner for legacy scalar controls. Native grabs take precedence.
const LAYERS: int = (1 << 20) | (1 << 22)
var control: Node3D
var driver: Node3D
var angular := false
var axis := Vector3.RIGHT
var _pointer: Node3D
var _previous: Vector3
var _raw := 0.0
var custom_axis := false
var _resume_auto := false

static func attach(host: Node3D, joint: Node3D, direction: Vector3 = Vector3.RIGHT, is_angular: bool = false) -> Node3D:
	var helper := load("res://commons/interactables/scalar_pointer.gd").new() as Node3D
	helper.name = "ScalarPointer"
	helper.control = host; helper.driver = joint; helper.axis = direction; helper.angular = is_angular
	helper.custom_axis = joint.get("slider_value") != null
	host.add_child(helper)
	return helper

func _ready() -> void:
	set_process(false)
	if Engine.is_editor_hint(): return
	for node in control.find_children("*", "CollisionObject3D", true, false):
		# Give authored collision bodies a path to this adapter without replacing
		# an existing specialist interaction script.
		if node is StaticBody3D and node.get_script() == null:
			node.set_script(preload("res://commons/interactables/joystick_pointer_body.gd"))
			node.control_path = node.get_path_to(self)
		elif node is XRToolsInteractableHandle:
			node.control_path = node.get_path_to(self)
		node.collision_layer |= LAYERS
		if node is XRToolsPickable: node.original_collision_layer = node.collision_layer
	driver.grabbed.connect(func(_joint): cancel(false))

func current() -> float:
	if angular: return driver.hinge_position
	return driver.slider_value if custom_axis else driver.slider_position
func bounds() -> Vector2:
	if angular: return Vector2(driver.hinge_limit_min, driver.hinge_limit_max)
	if custom_axis: return Vector2(driver.limit_min, driver.limit_max)
	return Vector2(driver.slider_limit_min, driver.slider_limit_max)
func point(world: Vector3) -> Vector3:
	return control.to_local(world) if angular else driver.get_parent().to_local(world)
func move(value: float) -> void:
	if angular: driver.move_hinge(deg_to_rad(value))
	else: driver.move_slider(value)
func pointer_event(event: XRToolsPointerEvent) -> void:
	if not event or not is_instance_valid(event.pointer) or not driver.grabbed_handles.is_empty(): return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if is_instance_valid(_pointer): return
			_pointer = event.pointer; _previous = point(event.position); _raw = current(); set_process(true)
			_resume_auto = custom_axis and driver.auto_drive
			if _resume_auto: driver.auto_drive = false
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer != _pointer: return
			var at := point(event.position)
			_raw += (at.y - _previous.y) * 300.0 if angular else (at - _previous).dot(axis)
			var limits := bounds()
			_raw = clampf(_raw, limits.x, limits.y)
			move(_raw); _previous = at
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			if event.pointer == _pointer: cancel(true)
func cancel(apply_release: bool) -> void:
	_pointer = null; set_process(false)
	if apply_release and is_instance_valid(driver) and driver.default_on_release:
		move(driver.default_value if custom_axis else driver.default_position)
	if _resume_auto and is_instance_valid(driver): driver.auto_drive = true
	_resume_auto = false
func _process(_delta: float) -> void:
	if not is_instance_valid(_pointer): cancel(true)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_processing(): cancel(true)
