extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var sine: bool = map_id == "WaveFunctions_Sine_Space"
	var origin := hall.global_position + Vector3(0,0,4)
	var field := find_scene("/algorithms/wavefunctions/sine_space/SineSpace.gd" if sine else "/WavePropagation3D.gd")
	check("wave exhibit loaded",field != null)
	if field == null:return
	var rain := find_scene("/colorballs.gd") if sine else null
	var centre: float = 9.0 if sine else 12.185
	var near_z: float = 18.0 if sine else 16.0
	var far_z: float = 42.0 if sine else 35.0
	check("two broad pool ramps built",hall.find_children("BasinAccess_*","StaticBody3D",true,false).size()==2)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
	check("open basin without glass or fire",not data.map_info.museum.basin.glass and not data.map_info.museum.basin.fire)
	var space := hall.get_world_3d().direct_space_state
	for offset in [0.3,1.5,2.7]:
		var pos := origin+Vector3(centre,2,near_z+offset)
		var hit: Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(pos,pos+Vector3.DOWN*5,1))
		check("descending ramp height at %.1fm" % offset,not hit.is_empty() and absf(hit.position.y-origin.y+offset/3.0)<0.035)
	check("surface is recessed one metre",absf((field.walk_floor.global_position.y if sine else field.global_position.y+field.tile_height)-origin.y+1.0)<0.02)
	observations.surface_position=xyz(field.global_position-origin)
	if sine:
		check("colour rain retains 48 bodies",rain!=null and rain.ball_bodies.size()==48)
		if rain!=null:
			# Keep rain visible but out of this deterministic walker trial.
			for ball in rain.ball_bodies:ball.collision_layer=0
		var contacts: Array=[]
		var ball: RigidBody3D=rain.ball_bodies[0]
		rain.set_physics_process(false)
		ball.collision_layer=1;ball.contact_monitor=true;ball.max_contacts_reported=8
		ball.body_entered.connect(func(other):contacts.append(other))
		ball.global_position=field.walk_floor.to_global(Vector3(0.6,3.0,0.35))
		ball.linear_velocity=Vector3.ZERO;ball.sleeping=false
		for frame in range(110):await physics_frame
		check("rain still lands on the lowered wave collider",contacts.any(func(n):return is_instance_valid(n) and field.walk_floor.is_ancestor_of(n)))
		ball.collision_layer=0
		rain.set_physics_process(true)
	else:
		check("moving tiles use pool mode",field.pool_access and field.tile_collision_bodies.size()==400)
		check("moving tiles carry with physics bodies",field.tile_collision_bodies.all(func(n):return n is AnimatableBody3D))
		var rim_stable := true
		var positions_match := true
		for i in [0,19,380,399]:
			rim_stable= rim_stable and absf(field.tile_collision_bodies[i].global_position.y+field.tile_height*0.5-origin.y+1)<0.001
		for i in range(400):
			positions_match=positions_match and field.tile_multimesh.get_instance_transform(i).origin.is_equal_approx(field.tile_collision_bodies[i].position)
		check("four corner tiles meet a stable landing",rim_stable)
		check("display and tile collision agree",positions_match)
		var standalone=load("res://algorithms/wavefunctions/wave_propagation_3d/wave_propagation_3d.tscn").instantiate()
		check("other placements keep original defaults",not standalone.pool_access and is_equal_approx(standalone.tile_size,0.55))
		standalone.free()
	var walker: CharacterBody3D=museum.get("_player")
	walker.set_process(false);walker.set_physics_process(false);walker.visible=false
	var saved := walker.global_position
	walker.global_position=origin+Vector3(centre,0.05,near_z-0.8)
	walker.velocity=Vector3.ZERO
	var lows: Array=[]
	for direction in [1.0,-1.0]:
		var low := 0.0
		var grounded := 0
		var frames := 0
		var samples: Array=[]
		for frame in range(1800):
			await physics_frame
			frames+=1
			walker.velocity=Vector3(0,0 if walker.is_on_floor() else walker.velocity.y-9.8/Engine.physics_ticks_per_second,2.5*direction)
			walker.move_and_slide()
			var p := walker.global_position-origin
			low=minf(low,p.y)
			if walker.is_on_floor():grounded+=1
			if frame%30==0:samples.append(xyz(p))
			if (direction>0 and p.z>far_z+0.5) or (direction<0 and p.z<near_z-0.5):break
			if p.y < -2.0:break
		var end: Vector3=walker.global_position-origin
		check("crossing %s reaches deck at other end" % direction,(end.z>far_z+0.45 if direction>0 else end.z<near_z-0.45) and absf(end.y)<0.12)
		check("crossing %s descends onto the waves" % direction,low < -0.85 and low > -1.9)
		check("crossing %s keeps floor contact" % direction,float(grounded)/frames>0.7)
		observations["walk_%s" % direction]={"end":xyz(end),"lowest":low,"grounded_fraction":float(grounded)/frames,"samples":samples}
		lows.append(low)
		if direction>0 and end.z<far_z:break
	walker.global_position=saved;walker.velocity=Vector3.ZERO
	if sine:
		for x in [1.5,16.5]:
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(origin+Vector3(x,6,26),origin+Vector3(x,-3,26),1))
			check("side wall still prevents bypass at x%.1f"%x,not hit.is_empty() and hit.position.y-origin.y>2.5)
	await snapshot("pool-eye",origin+Vector3(centre-1.4,1.7,near_z-1.8),origin+Vector3(centre,-0.7,near_z+9),74)
	await snapshot("pool-above",origin+Vector3(centre-4,12,near_z-4),origin+Vector3(centre,-0.8,(near_z+far_z)*0.5),76)
	observations.scope="Actual museum CharacterBody walks down, crosses and returns via ramps. Physics running; controlled input, no physical headset claim."
