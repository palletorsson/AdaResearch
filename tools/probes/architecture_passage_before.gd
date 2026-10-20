extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false);observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/lsystem_dungeon/lsystem_dungeon.gd");check("Existing dungeon present",source!=null)
	if source==null:return
	var desk=source.get_node("ArchitectureLesson")
	observations.widths=[]
	for i in 3:
		desk.width_index=i;desk.rebuild()
		var low:=100.0;var high:=-100.0
		for cell in desk.occupied:
			if is_equal_approx((cell.y+.5)*desk.PITCH,-2.0+desk.PITCH*.5):
				low=minf(low,cell.x*desk.PITCH);high=maxf(high,(cell.x+1)*desk.PITCH)
		observations.widths.append({"label":desk.WIDTHS[i],"measured":high-low})
	desk.act("RESET")
	await snapshot("plan",source.to_global(Vector3(7,8,5)),source.to_global(Vector3(0,0,-4)),70)
	desk.act("BUILD")
	await snapshot("built",source.to_global(Vector3(7,8,5)),source.to_global(Vector3(0,0,-4)),70)
	await snapshot("inside",source.to_global(Vector3(0,1.7,-1)),source.to_global(Vector3(0,1.2,-5)),74)
	desk.act("ROOMS")
	await snapshot("room",source.to_global(Vector3(7,8,5)),source.to_global(Vector3(0,0,-4)),70)
	var origin:Vector3=source.global_position-hall.global_basis*Vector3(9.5,0,7.5)
	await snapshot("above",origin+hall.global_basis*Vector3(9.5,36,13),origin+hall.global_basis*Vector3(9.5,0,21),70)
