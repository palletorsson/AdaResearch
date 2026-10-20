extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/genetic_tree_sculptor/genetic_tree_sculptor.gd");check("Existing sculptor present",source!=null)
	if source==null:return
	var desk=source.get_node("LivingLesson");desk.act("RESET");desk.act("HOLD")
	await snapshot("opening",source.to_global(Vector3(6,5,5)),source.to_global(Vector3(0,1.6,-3)),68)
	for i in 4:desk.act("MORE")
	source.flush_preview()
	await snapshot("below",source.to_global(Vector3(0,1.75,3.1)),source.to_global(Vector3(0,1.3,-2)),82)
	desk.act("MORE");source.flush_preview()
	await snapshot("threshold",source.to_global(Vector3(6,5,5)),source.to_global(Vector3(0,1.6,-3)),68)
	await snapshot("above",source.to_global(Vector3(0,31,-3)),source.to_global(Vector3(0,0,-10)),70)
