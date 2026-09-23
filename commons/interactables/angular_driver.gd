extends XRToolsInteractableHinge
## Native limits, detents, degree signal and radian move API are retained.
## Resolve angles in the rest frame and unwrap around the current turn count.
func _process(_delta:float)->void:
	if grabbed_handles.is_empty(): return
	var held: Array[Vector3]=[]
	var total:=0.0
	for handle:XRToolsInteractableHandle in grabbed_handles:
		held.append(handle.global_position)
		var rest:Vector3=to_local(handle.handle_origin.global_position)
		var target:Vector3=get_parent().to_local(handle.global_position)
		rest.x=0
		target.x=0
		if rest.length_squared()<.000001 or target.length_squared()<.000001:
			total+=_hinge_position_rad
			continue
		var angle:=rest.signed_angle_to(target,Vector3.RIGHT)
		total+=_hinge_position_rad+wrapf(angle-_hinge_position_rad,-PI,PI)
	move_hinge(total/grabbed_handles.size())
	# The ancestor moves; a still hand must not move again with it.
	for i in grabbed_handles.size(): grabbed_handles[i].global_position=held[i]
