extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps"); await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null: stream.set_process(false); stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D: player.hide(); player.set_process(false); player.set_physics_process(false); player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/ten_print_textile/ten_print_textile.gd")
	check("Existing textile and lesson loaded",source!=null and source.lesson_node!=null)
	if source==null or source.lesson_node==null:return
	source.set_process(false)
	var desk=source.lesson_node; desk.act("RESET"); desk.act("HOLD")
	await snapshot("opening",source.to_global(Vector3(5,4,5)),source.to_global(Vector3(0,2,-3)),68)
	await snapshot("desk",source.to_global(Vector3(0,1.7,3)),source.to_global(Vector3(0,1.8,-3)),72)
	await snapshot("above",source.to_global(Vector3(0,34,-6)),source.to_global(Vector3(0,0,-10)),72)
	await snapshot("collection",source.to_global(Vector3(4,6,-13)),source.to_global(Vector3(0,1.6,-23)),74)
