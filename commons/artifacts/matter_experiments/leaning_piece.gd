extends XRToolsPickable
## A real loose body. Desktop turns the actual grab frame; XR uses the wrist.
## Other Leaning Together bodies include layer 17 in their mask, so a held
## plank remains a contact support while the player/body ignore that layer.
signal tapped(impulse: Vector3)
var tap_speed := .25

func _init() -> void:
	freeze = true;freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	collision_layer = 1|4|(1<<20);collision_mask = 1|4|(1<<16)|(1<<17)
	release_mode = ReleaseMode.UNFROZEN;continuous_cd = true;can_sleep = false
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = .08;angular_damp = .12
	contact_monitor = true;max_contacts_reported = 16
	second_hand_grab = SecondHandGrab.SECOND
	set_meta("desktop_passive_carry",true)
	picked_up.connect(_held);dropped.connect(_released)

func _held(_body: Node3D) -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

func _released(_body: Node3D) -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

func pointer_event(event: XRToolsPointerEvent) -> void:
	if event.event_type!=XRToolsPointerEvent.Type.PRESSED or is_picked_up():return
	var direction := (event.position-event.pointer.global_position).normalized()
	var impulse := direction*mass*tap_speed
	apply_impulse(impulse,event.position-global_position);tapped.emit(impulse)

func _input(event: InputEvent) -> void:
	if not is_picked_up() or not event is InputEventKey or not event.pressed:return
	var hand := get_picked_up_by()
	if hand==null or hand.has_method("drop_object"):return # Native XR wrist owns its orientation.
	var axis := Vector3.ZERO
	match event.physical_keycode:
		KEY_Q:axis = Vector3.UP if event.shift_pressed else Vector3.FORWARD
		KEY_E:axis = Vector3.DOWN if event.shift_pressed else Vector3.BACK
		KEY_Z:axis = Vector3.RIGHT
		KEY_X:axis = Vector3.LEFT
	if axis!=Vector3.ZERO:
		hand.rotate_object_local(axis,deg_to_rad(5));get_viewport().set_input_as_handled()
