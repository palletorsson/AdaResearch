extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var desk=find_scene("/space_colonization_algorithm/colonization_lesson.gd")
	check("Installed colonization lesson loaded",desk!=null)
	if desk==null:return
	desk.act("RESET")
	observations.origin=xyz(desk.global_position)
	await snapshot("opening",desk.to_global(Vector3(4,4,2)),desk.to_global(Vector3(0,2,-6)),78)
	await snapshot("desk",desk.to_global(Vector3(0,1.8,3)),desk.to_global(Vector3(0,2,-5)),75)
	await snapshot("above",desk.to_global(Vector3(0,35,-8)),desk.to_global(Vector3(0,0,-12)),70)
	await snapshot("deck",desk.to_global(Vector3(-5,6,-19)),desk.to_global(Vector3(0,1,-22)),70)
