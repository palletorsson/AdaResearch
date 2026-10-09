extends "res://tools/probes/forces_layout.gd"
## Capture the placed production artifacts, not substitute test-bay geometry.
func landing_checks() -> void:
	camera.set_cull_mask_value(19,false)
	await super.landing_checks()
	var wardrobe=museum.get("_player_wardrobe")
	if wardrobe is Node3D:wardrobe.visible=false
	observations.studies=[]
	observations.live_motion=[]
	for e in get_nodes_in_group("force_play"):
		if not hall.is_ancestor_of(e):continue
		check(e.kind+": full-size physical encounter placed",e.scale.is_equal_approx(Vector3.ONE) and e.bodies.size()>0)
		observations.studies.append({"kind":e.kind,"bodies":e.bodies.size(),"joints":e.joints.size(),"position":xyz(e.global_position-hall.global_position)})
		var width=e.extent.x;var depth=e.extent.y
		var eye=Vector3(-width*0.34,maxf(4.5,width*0.3),-depth*0.65-2)
		var target=Vector3(0,1.1,0)
		if e.kind=="tower":eye=Vector3(-4,3.8,-7.5);target.y=2.9
		if e.kind=="flight":eye=Vector3(-4,6.5,-15);target.y=2
		if e.kind=="stacking_table":eye=Vector3(1.5,1.9,-2.2);target.y=1.14
		var hall_origin=hall.global_position+Vector3(0,0,4)
		var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
		var frame=e.to_global(eye)-hall_origin
		frame.x=clampf(frame.x,2,plan.map_info.dimensions.width-2)
		frame.z=clampf(frame.z,2,plan.map_info.dimensions.depth-2)
		eye=e.to_local(hall_origin+frame)
		if e.kind=="support":check("support: stacked load stands before the hand intervenes",e.members.load.back().position.y>3.0)
		await snapshot(e.kind+"-before",e.to_global(eye),e.to_global(target),67)
		var start=e.bodies[0].position
		var clock=e.elapsed
		match e.kind:
			"tower":
				e.members.key.freeze=true;await tick()
				var key_start=e.members.key.position.x
				for step in range(60):
					e.members.key.position.x=key_start+4.0*(step+1)/60.0;await physics_frame
				await create_timer(3).timeout
				check("tower: moved key stays outside stack",absf(e.members.key.position.x)>3)
				check("tower: upper bricks fall in the actual hall",e.bodies.back().position.y<3.5)
			"gravity":
				e.action("RELEASE");await create_timer(1).timeout
				check("gravity: released cargo falls inside the museum",e.members.released[2].position.y<2.7)
			"mass":e.action("PUSH 1 s");await create_timer(1.4).timeout
			"bowling":e.action("ROLL");await create_timer(4.5).timeout
			"recoil":e.action("FIRE");await create_timer(0.5).timeout
			"friction":e.action("RELEASE");await create_timer(2).timeout
			"liquids":e.action("DROP");await create_timer(0.8).timeout
			"springs":e.bodies[0].apply_central_impulse(Vector3(4,0,3));await create_timer(0.8).timeout
			"swings":e.action("NUDGE");await create_timer(0.5).timeout
			"magnet":e.action("MAGNET 3 s");await create_timer(1.5).timeout
			"support":
				e.members.leg.freeze=true;await tick();e.members.leg.position.x+=4;e.members.leg.force_update_transform();e.members.leg.reset_physics_interpolation();await create_timer(2.5).timeout
				check("support: pulling a leg overturns the actual table",e.members.table.rotation.length()>0.4)
			_:
				continue
		await snapshot(e.kind+"-after",e.to_global(eye),e.to_global(target),67)
		observations.live_motion.append({"kind":e.kind,"start":xyz(start),"end":xyz(e.bodies[0].position),"clock":clock,"elapsed":e.elapsed,"processing":e.can_process(),"mode":e.process_mode,"frozen":e.bodies[0].freeze,"active":e.bodies[0].can_process()})
		check(e.kind+": simulation advances inside the museum",e.elapsed>clock+0.1)
		if e.kind=="magnet":
			await create_timer(2).timeout
			await snapshot("magnet-released",e.to_global(eye),e.to_global(target),67)
		# Capture intervention ends here; reset leaves production behavior unchanged.
		e.reset()
	if map_id=="Vectors_Act5_ForceAsPlace":
		var court=find_scene("/force_capability_lab.gd")
		check("mortar: all three controls turned towards approach",court!=null and is_equal_approx(court.mortar.buttons.FIRE.rotation.y,PI))
		if court!=null:await snapshot("mortar",court.to_global(Vector3(0,3.5,-12)),court.to_global(Vector3(4,0.5,-5)),62)
