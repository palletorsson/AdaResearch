extends "res://tools/probes/void_voxel_probe.gd"

func visit(mode: bool) -> void:
	await start(mode)
	var tag := "XR: " if mode else "Desktop: "
	game.checkpoint=2
	game.place_player(Vector3(-11.7,-11.94,1.9)); await frames(140)
	check(tag+"arrival still reaches the original floor checkpoint", game.checkpoint==3 and game.health.get_health()==100)
	encounter=game.building.content.roots[3].get_node("Construction")
	var cells: Array=game.building.content.data.floors[3].construction
	check(tag+"shared floor loads every editable module",encounter.items==cells)
	for kind in ["Truss","Deck","Collar"]:
		check(tag+kind+" uses a single batched mesh",encounter.get_node(kind+kind) is MultiMeshInstance3D)
		check(tag+kind+" retains real collision",encounter.get_node(kind+"Collision").get_child_count()>0)
	var collars: Array=cells.filter(func(c):return c.kind=="collar")
	check(tag+"four collars join existing tower pillars",collars.size()==4 and collars.all(func(c):return int(c.position[0]) in [-14,-5] and absf(c.position[2])==7 and is_equal_approx(c.position[1],2.38)))
	check(tag+"original freestanding legs removed",cells.all(func(c):return not str(c.id).begins_with("NearPost") and not str(c.id).begins_with("FarPost")))
	for side in ["Near","Far"]:
		var ledger: Array=cells.filter(func(c):return str(c.id).begins_with(side+"Ledger"))
		check(tag+side+" continuous nine-metre pillar span",ledger.size()==9 and ledger.all(func(c):return c.kind=="truss" and is_equal_approx(c.position[1],2.38)))
	var deck: MultiMeshInstance3D=encounter.get_node("DeckDeck")
	check(tag+"deck is one metre square and 12 cm thick",deck.multimesh.mesh.get_aabb().size.is_equal_approx(Vector3(1,.12,1)))
	check(tag+"two banks total 36 editable deck tiles",deck.multimesh.instance_count==36)
	var truss: MultiMeshInstance3D=encounter.get_node("TrussTruss")
	check(tag+"truss bay is one metre long and half a metre deep",truss.multimesh.mesh.get_aabb().size.is_equal_approx(Vector3(1,.5,.2)))
	var carrier: Node3D=encounter.get_node("SuspendedPlatform")
	var platform: Node3D=carrier.platform
	check(tag+"platform now travels at the three-metre deck height",is_equal_approx(carrier.position.y,3))
	# A new level does not fill the volume underneath or cap the shaft.
	game.place_player(Vector3(-10,Y+.06,6.5));await frames(20)
	check(tag+"floor below the mezzanine remains walkable",game.body.is_on_floor() and absf(game.body.global_position.y-Y)<.1)
	var query:=PhysicsRayQueryParameters3D.create(Vector3(-8,Y+3.2,0),Vector3(-8,Y-1,0),1)
	query.exclude=[game.body.get_rid()]
	check(tag+"gap over the shaft remains open",game.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
	query=PhysicsRayQueryParameters3D.create(Vector3(-12.83,Y+2.53,5.2),Vector3(-12.83,Y+2.53,5.8),1)
	check(tag+"triangular opening has no invisible solid box",game.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
	query=PhysicsRayQueryParameters3D.create(Vector3(-12.83,Y+2.63,5.2),Vector3(-12.83,Y+2.63,5.8),1)
	var brace_hit:Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
	check(tag+"diagonal steel brace has matching collision",not brace_hit.is_empty() and brace_hit.collider==encounter.get_node("TrussCollision"))
	game.place_player(Vector3(-19.9,Y+.06,2.3));await frames(15)
	for waypoint in [[-20.3,0,2.3],[-20.3,0,6],[-18,1,6],[-16,2,6],[-13,3,6],[-10,3,6],[-10,3,5.4]]:
		if not await walk(waypoint,tag): await finish(mode); return
	check(tag+"mezzanine stays in Translation's live floor",game.floor_stream.focus==3)
	check(tag+"near-bank carrier is ready",await dock(platform,false))
	if not await walk([-10,3,4],tag):await finish(mode);return
	check(tag+"walk onto the platform attaches rider",platform.carried_player==game.body)
	var b0:Vector3=game.body.global_position
	var e0:Vector3=game.camera.global_position
	var p0:Vector3=platform.global_position
	check(tag+"carrier crosses the mezzanine gap",await dock(platform,true))
	var delta:Vector3=platform.global_position-p0
	check(tag+"body and view travel once",(game.body.global_position-b0-delta).length()<.09 and (game.camera.global_position-e0-delta).length()<.09)
	for waypoint in [[-10,3,-5.5],[-10,3,-6],[-13,3,-6],[-16,2,-6],[-18,1,-6],[-20.3,0,-6]]:
		if not await walk(waypoint,tag):await finish(mode);return
	check(tag+"both ramps and crossing completed without damage",game.health.get_health()==100 and game.deaths==0 and not is_instance_valid(platform.carried_player))
	var deaths:int=game.deaths
	game.place_player(Vector3(-8,Y+3.06,0));await frames(120)
	check(tag+"missing the platform remains a fatal shaft fall",game.deaths==deaths+1)
	await wait_for_recovery(deaths)
	check(tag+"restart retains floor and editable modules",game.checkpoint==3 and game.health.get_health()==100 and game.building.content.roots[3].get_node("Construction").items==cells)
	await finish(mode)

func photos() -> void:
	await start(true)
	game.place_player(game.spawn_for(3));await frames(35)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	game.get_node("XROrigin3D").hide();game.status.hide();game.notice_time=-1
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	encounter=game.building.content.roots[3].get_node("Construction")
	var carrier:Node3D=encounter.get_node("SuspendedPlatform")
	carrier.platform.set_physics_process(false)
	carrier.platform.global_position=carrier.to_global(Vector3(0,-.5,-4))
	carrier.platform.static_body.force_update_transform();carrier._update_suspension()
	await photo("whole-setup",Vector3(-5.8,Y+4.6,0),Vector3(-12,Y+2,0))
	await photo("trusses",Vector3(-10,Y+1.65,2.8),Vector3(-10,Y+2.6,6))
	await photo("crossing",Vector3(-10,Y+4.65,7),Vector3(-10,Y+3.6,-1))
	await photo("pillar-joint",Vector3(-7.5,Y+2,4.3),Vector3(-5,Y+2.3,7))
	await finish(true)

