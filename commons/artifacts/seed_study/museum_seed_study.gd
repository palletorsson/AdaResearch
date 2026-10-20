extends "res://commons/artifacts/seed_study/seed_study.gd"
## The published experiment only owns keyboard shortcuts at its own board.

func _input(event: InputEvent) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or board == null or not is_visible_in_tree():
		return
	var local_eye := to_local(camera.global_position)
	if local_eye.z < 0.5 or local_eye.z > 3.5 or absf(local_eye.x) > 1.5:
		return
	var toward_board := camera.global_position.direction_to(board.global_position)
	if (-camera.global_basis.z).dot(toward_board) < 0.5:
		return
	super._input(event)
