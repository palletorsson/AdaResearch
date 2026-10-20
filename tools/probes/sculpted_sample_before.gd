extends "res://tools/probes/transformation_encounters.gd"
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var desk=find_scene("/timing_machines/pg_workshop.gd")
	check("Sculpted desk bound",desk!=null and desk.ready_for_input and desk.chapter=="sculpted")
	if desk==null:return
	await create_timer(2).timeout
	observations.origin=xyz(desk.global_position);observations.model=xyz(desk.model.global_position)
	await snapshot("opening",desk.to_global(Vector3(1,6,-1)),desk.model.to_global(Vector3(0,2,0)),85)
	await snapshot("desk",desk.to_global(Vector3(0,1.8,3)),desk.to_global(Vector3(0,1.4,0)),65)
	await snapshot("above",desk.to_global(Vector3(0,47,-15)),desk.to_global(Vector3(0,0,-18)),70)
	if stream!=null:observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
