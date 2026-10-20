extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1.0).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false);observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/the_believing_turtle/the_believing_turtle.gd")
	check("Believing turtle present",source!=null)
	if source==null:return
	var origin:Vector3=source.global_position-hall.global_basis*Vector3(9.5,0,7.5)
	var desk=source.get_node("InterpreterLesson")
	await snapshot("arrival",source.to_global(Vector3(0,1.75,6.5)),source.to_global(Vector3(0,2.5,0)),90)
	desk.act("READ F");desk.act("ANGLE")
	for i in 5:desk.act("STEP")
	await snapshot("fork",source.to_global(Vector3(0,2.6,6.2)),source.to_global(Vector3(0,2.4,0)),94)
	desk.act("TREE")
	await snapshot("three",source.to_global(Vector3(0,3.1,6.2)),source.to_global(Vector3(0,3.2,0)),96)
	await snapshot("above",origin+hall.global_basis*Vector3(11.5,47,17),origin+hall.global_basis*Vector3(11.5,0,26),72)
	await snapshot("applications",origin+hall.global_basis*Vector3(11.5,2.0,30),origin+hall.global_basis*Vector3(11.5,3.0,39.5),80)
