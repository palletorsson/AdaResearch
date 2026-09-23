extends XRToolsInteractableJoystick
## Keep the native limits, degree-sized detents and release signal. Resolve the
## held proxy in the rest frame, so a still hand does not accumulate rotation.
func _process(_delta: float) -> void:
	if grabbed_handles.is_empty(): return
	var positions: Array[Vector3] = []
	var angles := Vector2.ZERO
	for handle in grabbed_handles:
		positions.append(handle.global_position)
		var local: Vector3 = get_parent().to_local(handle.global_position)
		angles += Vector2(atan2(local.x,local.z),atan2(-local.y,Vector2(local.x,local.z).length()))
	angles /= grabbed_handles.size()
	move_joystick(angles.x,angles.y)
	# Moving the constrained ancestor must not move the free grab proxy too.
	for i in grabbed_handles.size(): grabbed_handles[i].global_position = positions[i]
