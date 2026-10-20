extends XRToolsPickable
## Hand-positioned construction pieces; physical solids opt into gravity.
var floats := true
func _init() -> void:
	freeze=true;collision_layer=7;collision_mask=7
	mass=0.7;continuous_cd=true
	release_mode=ReleaseMode.FROZEN
	linear_damp=0.5;angular_damp=1.0
func held() -> bool: return is_picked_up() or has_meta("capability_desktop_held")
func on_desktop_grab(_pointer: Node3D) -> void:
	set_meta("capability_desktop_held",true);picked_up.emit(self)
func on_desktop_drop(_pointer: Node3D) -> void:
	remove_meta("capability_desktop_held");freeze=floats
	linear_velocity=Vector3.ZERO;angular_velocity=Vector3.ZERO
	dropped.emit(self)
func _input(event: InputEvent) -> void:
	if not has_meta("capability_desktop_held") or not event is InputEventKey or not event.pressed or event.echo:return
	var axis:=Vector3.ZERO;var turn:=PI/12
	match event.physical_keycode:
		KEY_Q:axis=Vector3.FORWARD
		KEY_E:axis=Vector3.BACK
		KEY_R:axis=Vector3.RIGHT
		KEY_F:axis=Vector3.LEFT
	if axis!=Vector3.ZERO:rotate_object_local(axis,turn);get_viewport().set_input_as_handled()
