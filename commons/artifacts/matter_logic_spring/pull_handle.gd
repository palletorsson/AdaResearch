extends XRToolsPickable
## A hand supplies a retained one-dimensional compression, not a throw velocity.
var machine: Node3D
var pointer: Node3D
var start_y := 0.0
var start_height := 0.0
func is_dragging() -> bool:return is_instance_valid(pointer)
func pointer_event(event: XRToolsPointerEvent) -> void:
	if not is_instance_valid(machine) or is_picked_up():return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if machine.active:return
			pointer=event.pointer;start_y=machine.to_local(event.position).y;start_height=machine.grip_position().y
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer==pointer and is_instance_valid(pointer):
				var at: Vector3=machine.grip_position();at.y=start_height+machine.to_local(event.position).y-start_y
				machine.follow_handle(machine.to_global(at))
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			if event.pointer==pointer:
				pointer=null
				if not machine.active:machine._lift(0)
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(pointer):pointer=null
	if is_picked_up() and is_instance_valid(machine):
		machine.follow_handle(global_position)
		global_position = machine.to_global(machine.grip_position())
		global_basis = machine.global_basis
