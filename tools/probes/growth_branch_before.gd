extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:
		stream.set_process(false)
		observations.entry=stream.get("_entry")
		observations.exit=stream.get("_exit")
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/parametric_lsystem/parametric_lsystem.gd")
	check("Original source present",source!=null)
	if source==null:return
	var origin:Vector3=source.global_position-hall.global_basis*Vector3(9.5,0,7.5)
	observations.source_transform=str(source.global_transform)
	var desk=source.get_node("GrowthLesson")
	await snapshot("arrival",origin+hall.global_basis*Vector3(9.5,1.75,2.2),source.to_global(Vector3(0,2,0)),76)
	for i in 3:desk.act("STEP")
	desk.act("HOLD")
	await snapshot("branch",source.to_global(Vector3(0,2.1,6.6)),source.to_global(Vector3(0,1.5,0)),72)
	await snapshot("above",origin+hall.global_basis*Vector3(9.5,25,8),origin+hall.global_basis*Vector3(9.5,0,14),74)
	await snapshot("rear",origin+hall.global_basis*Vector3(9.5,2,22),origin+hall.global_basis*Vector3(9.5,1,27),78)
