extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var origin := find_scene("/origin.gd")
	var counter := find_scene("/frame_counter_display.gd")
	var shaft := find_scene("/arrival_shaft.gd")
	check("origin, counter and arrival shaft present",origin!=null and counter!=null and shaft!=null)
	if origin==null:return
	observations["origin_world"]=xyz(origin.global_position)
	check("origin marker is at actual world zero",origin.global_position.distance_to(Vector3.ZERO)<0.001)
	check("label belongs to the origin",origin.beam_label=="Point zero")
	check("one origin instance",hall.find_children("OriginSphere","MeshInstance3D",true,false).size()==1)
	var pool: Array=hall.get_meta("em_pool_cells",[])
	check("restored basin has sixteen cells",pool.size()==16)
	var world:=hall.get_world_3d().direct_space_state
	for x in [-1.25,1.25]:
		for z in [-1.25,1.25]:
			var hit:=world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,0.3,z),Vector3(x,-0.3,z),1))
			observations["glass_hit_"+str(Vector2(x,z))]={"collider":str(hit.get("collider","none")),"position":str(hit.get("position","none"))}
			check("glass at deck height "+str(Vector2(x,z)),not hit.is_empty() and absf(hit.position.y)<0.02)
			hit=world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,-0.15,z),Vector3(x,-2.3,z),1))
			observations["bottom_hit_"+str(Vector2(x,z))]={"collider":str(hit.get("collider","none")),"position":str(hit.get("position","none"))}
			check("basin bottom two metres down "+str(Vector2(x,z)),not hit.is_empty() and absf(hit.position.y+2.0)<0.02)
	for leg in [[Vector3(-1.5,-0.7,0.2),Vector3(1.5,-0.7,0.2)],[Vector3(0.2,-0.7,-1.5),Vector3(0.2,-0.7,1.5)]]:
		check("no internal wall across basin "+str(leg[0]),world.intersect_ray(PhysicsRayQueryParameters3D.create(leg[0],leg[1],1)).is_empty())
	var walker: CharacterBody3D=museum.get("_player")
	walker.global_position=museum._drop_point();walker.velocity=Vector3.ZERO
	museum.set_physics_process(true);await create_timer(2).timeout;museum.set_physics_process(false)
	check("arrival still lands safely",walker.is_on_floor() and absf(walker.global_position.y)<0.05)
	observations["arrival_landed"]=xyz(walker.global_position)
	walker.global_position=Vector3(6,0.025,2.6);walker.velocity=Vector3.ZERO
	await physics_frame
	check("approach from counter reaches basin",walker.move_and_collide(Vector3(-4.6,0,0))==null)
	check("approach has supporting floor",not floor_at(walker.global_position).is_empty())
	check("walk onto basin glass",walker.move_and_collide(Vector3(0,0,-1.4))==null)
	check("glass supports walker",not floor_at(walker.global_position).is_empty())
	var fold:=find_scene("/animated_folding_past.gd")
	check("Folding Past remains",fold!=null)
	await snapshot("origin-close",origin.global_position+Vector3(2.8,1.65,2.8),origin.global_position,60)
	await snapshot("basin-context",Vector3(4.8,1.65,3.8),Vector3(0,0,0),66)
	await snapshot("arrival-counter",shaft.global_position+Vector3(0,1.65,-0.5),counter.global_position,64)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum, exact world coordinates, four-quadrant basin collision and actual desktop walker; headset not tested."},"  "))
	print("ORIGIN RESTORATION ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
