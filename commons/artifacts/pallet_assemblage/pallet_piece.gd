extends XRToolsPickable
## Desktop hands need an explicit orientation control; XR hands supply their own pose.
func _input(event: InputEvent) -> void:
	if not is_picked_up() or not event is InputEventKey or not event.pressed or event.echo:return
	var hand := get_picked_up_by()
	if hand==null or str(hand.name)!="MouseGrip":return
	var axis := Vector3.RIGHT if event.physical_keycode==KEY_X else Vector3.UP if event.physical_keycode==KEY_Y else Vector3.BACK if event.physical_keycode==KEY_Z else Vector3.ZERO
	if axis==Vector3.ZERO:return
	rotate_in_hand(axis,-15.0 if event.shift_pressed else 15.0)
	get_viewport().set_input_as_handled()

func rotate_in_hand(axis: Vector3,degrees: float) -> void:
	if not is_picked_up():return
	var hand := get_picked_up_by()
	hand.global_basis = (hand.global_basis*Basis(axis,deg_to_rad(degrees))).orthonormalized()
