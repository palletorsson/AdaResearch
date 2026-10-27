extends "res://algorithms/softbodies/rounded_softbody.gd"
## A preview floor can pause during the source's two-frame delayed capture.
## Wait for a live physics space, then perform the original rest-state capture
## without another asynchronous gap. Simulation and measurements are unchanged.
func _capture_rest_state() -> void:
	await get_tree().physics_frame
	while is_inside_tree():
		if is_instance_valid(_soft_body) and can_process() and _soft_body.can_process():
			var rid := _soft_body.get_physics_rid()
			if rid.is_valid() and PhysicsServer3D.soft_body_get_space(rid).is_valid(): break
		await get_tree().physics_frame
	if not is_inside_tree(): return
	if seat_specimen and show_cabinet: _seat_specimen_on_deck()
	_vertex_count = _sb_point_count()
	_rest_positions.resize(_vertex_count)
	_prev_positions.resize(_vertex_count)
	_vertex_strain.resize(_vertex_count)
	for i in range(_vertex_count):
		var p: Vector3 = PhysicsServer3D.soft_body_get_point_global_position(_sb_rid,i)
		_rest_positions[i] = p - _soft_body.global_position
		_prev_positions[i] = p
		_vertex_strain[i] = 0.0
	_rest_volume = _compute_volume()
	_current_volume = _rest_volume
	_volume_history.clear()
