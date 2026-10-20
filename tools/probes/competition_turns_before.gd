extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false);observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/Ecosystem/ForestCompetition.gd");check("Existing forest present",source!=null)
	if source==null:return
	var desk=source.get_node("CompetitionLesson")
	desk.act("RESET")
	await snapshot("opening",source.to_global(Vector3(7,6,6)),source.to_global(Vector3(0,1,-3)),66)
	desk.act("STEP");desk.act("STEP")
	observations.first_pair=desk.last_takes.duplicate()
	await snapshot("two-turns",source.to_global(Vector3(0,1.75,3.1)),source.to_global(Vector3(0,.8,-3)),78)
	for i in 4:desk.act("STEP")
	await snapshot("grown",source.to_global(Vector3(7,6,6)),source.to_global(Vector3(0,1,-3)),66)
	await snapshot("above",source.to_global(Vector3(0,29,-3)),source.to_global(Vector3(0,0,-9)),70)
	observations.source_transform=str(source.global_transform)
