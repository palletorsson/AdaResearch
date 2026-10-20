extends Node3D
## Mouse ray for the existing VR menu. Desktop clicks use its normal callbacks;
## embedded Viewport2Din3D panels receive the same pointer events as VR.
var target: Node3D
var pressed_target: Node3D
var hit_position := Vector3.ZERO
var mouse_position := Vector2.ZERO
var buttons: Array[InputEventMouseButton] = []
var was_visible := false

func _ready() -> void:
	mouse_position = get_viewport().get_mouse_position()
	# Broaden the desktop hit region to include each label, as well as its cube.
	for button in get_parent().get_node("Buttons").get_children():
		var collider := button.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collider != null:
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.3, 0.22, 0.12)
			collider.shape = shape
			collider.position.x = 0.05

func _input(event: InputEvent) -> void:
	if not get_parent().is_visible_in_tree(): return
	if event is InputEventMouse:
		mouse_position = event.position
	if event is InputEventMouseButton:
		buttons.append(event.duplicate())

func _physics_process(_delta: float) -> void:
	var visible: bool = get_parent().is_visible_in_tree()
	if not visible:
		_clear_target()
		buttons.clear()
		was_visible = false
		return
	if not was_visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Untracked controllers sit at the origin on desktop and would otherwise
		# dwell-click whichever button happens to lie on their default ray.
		for pointer in get_parent().get_parent().find_children("FunctionPointer*", "Node3D", true, false):
			pointer.enabled = false
			pointer.hide()
		was_visible = true
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var origin := camera.project_ray_origin(mouse_position)
	var ray := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(mouse_position) * 20.0, 1048576)
	var hit: Dictionary = {}
	var next: Node3D = null
	# Hidden panels keep their physics bodies. Look past them to the visible UI.
	for attempt in range(16):
		hit = get_world_3d().direct_space_state.intersect_ray(ray)
		next = hit.get("collider") as Node3D
		if next == null: break
		if next.is_visible_in_tree() and get_parent().is_ancestor_of(next): break
		ray.exclude = ray.exclude + [next.get_rid()]
		next = null
	if next != target:
		_clear_target()
		target = next
		if is_instance_valid(target):
			hit_position = hit.position
			if target.has_method("_trigger_click"):
				target.pointer_entered(false) # Mouse hover highlights; click activates.
			else:
				XRToolsPointerEvent.entered(self, target, hit_position)
	if is_instance_valid(target):
		XRToolsPointerEvent.moved(self, target, hit.position, hit_position)
		hit_position = hit.position
	for event in buttons:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_instance_valid(target):
				pressed_target = target
				if target.has_method("_trigger_click"): target._trigger_click()
				else: XRToolsPointerEvent.pressed(self, target, hit_position)
			elif not event.pressed and is_instance_valid(pressed_target):
				if not pressed_target.has_method("_trigger_click"):
					XRToolsPointerEvent.released(self, pressed_target, hit_position)
				pressed_target = null
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and is_instance_valid(target) and target.has_method("global_to_viewport"):
			var wheel := event.duplicate() as InputEventMouseButton
			wheel.position = target.global_to_viewport(hit_position)
			wheel.global_position = wheel.position
			target.get_node("../Viewport").push_input(wheel)
	buttons.clear()

func _clear_target() -> void:
	if is_instance_valid(target):
		if target.has_method("pointer_exited"): target.pointer_exited()
		else: XRToolsPointerEvent.exited(self, target, hit_position)
	target = null
