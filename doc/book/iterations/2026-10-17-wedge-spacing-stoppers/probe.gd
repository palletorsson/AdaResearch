extends "res://tools/probes/transformation_encounters.gd"

func walk_to(walker: CharacterBody3D, target: Vector3, budget: int = 230) -> bool:
	for i in budget:
		var toward := Vector3(target.x-walker.global_position.x,0,target.z-walker.global_position.z)
		if toward.length()<0.12:return true
		var horizontal := toward.normalized()*2.8
		walker.velocity=Vector3(horizontal.x,-2.0 if walker.is_on_floor() else walker.velocity.y-0.1635,horizontal.z)
		walker.move_and_slide();await physics_frame
	observations["blocked_"+str(target)]={"position":xyz(walker.global_position),"collisions":walker.get_slide_collision_count()}
	if walker.get_slide_collision_count()>0:
		observations["blocked_"+str(target)]["collider"]=str(walker.get_last_slide_collision().get_collider().get_path())
	return false

func height_at(p: Vector3) -> float:
	var ray := PhysicsRayQueryParameters3D.create(p+Vector3.UP*2.0,p+Vector3.DOWN*0.4,1)
	var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.position.y-p.y if not hit.is_empty() else -999.0

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var alignment := find_scene("/align_solid.gd")
	var anchor := find_scene("/wedge_palace.gd")
	check("alignment and writing anchor retained",alignment!=null and anchor!=null)
	if alignment==null or anchor==null:return
	# The first alignment is still at cell 7,4. Origin here uses cell centres.
	var origin := alignment.global_position-Vector3(7,0,4)
	observations["origin"] = xyz(origin)
	check("map architecture replaces standalone platform",anchor.layout=="map" and anchor.get_child_count()==0)
	var wedges:Array=[];var signs:Array=[];var stoppers:Array=[]
	for n in hall.find_children("*","Node3D",true,false):
		if n.scene_file_path.ends_with("/walkableprism.tscn"):wedges.append(n)
		if n.scene_file_path.ends_with("/prism_block.tscn"):stoppers.append(n)
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/street_sign.gd"):signs.append(n)
	check("seven stock wp prisms make two approaches and centred descent",wedges.size()==7)
	for n in wedges:
		check("wp keeps stock 1m rise and 2m run: "+n.name,n.scale.is_equal_approx(Vector3.ONE))
	check("STOP and three arrow signs present",signs.size()==4)
	check("STOP faces the entering visitor",signs.any(func(n):return n.direction=="none" and n.sign_text=="STOP" and absf(n.global_basis.z.dot(Vector3.FORWARD)-1)<0.01))
	check("two-direction sign offers the symmetrical approaches",signs.any(func(n):return n.direction=="both"))
	for p in [Vector2(8,27),Vector2(10,27),Vector2(8,30),Vector2(10,30)]:
		check("structure 2 stands 1m above floor "+str(p),absf(height_at(origin+Vector3(p.x,0,p.y))-1.0)<0.02)
	for p in [Vector2(6.5,27.5),Vector2(11.5,27.5),Vector2(9,31.5)]:
		var h := height_at(origin+Vector3(p.x,0,p.y))
		observations["slope_height_"+str(p)] = h
		check("sloping collision at half rise "+str(p),absf(h-0.5)<0.03)
	check("two existing upright prism stoppers",stoppers.size()==2)
	for stopper in stoppers:
		check("stopper is a 2m solid prism",stopper.grain=="solid" and stopper.scale.is_equal_approx(Vector3.ONE*2))
		check("stopper retains its physical surface",stopper.get_node("StaticBody3D/CollisionShape3D").shape is ConcavePolygonShape3D)
	var west:Node3D=null;var east:Node3D=null
	for w in wedges:
		var p:Vector3=w.global_position-origin
		if absf(p.z-27)<0.05:
			if absf(p.x-7)<0.05:west=w
			if absf(p.x-11)<0.05:east=w
	check("facing ramp pair found",west!=null and east!=null)
	if west!=null and east!=null:
		var distance:float=west.to_global(Vector3(0,0.5,0.5)).distance_to(east.to_global(Vector3(0,0.5,0.5)))
		observations["gap_between_ramp_upper_edges_m"]=distance
		check("exactly 3m between facing upper edges",absf(distance-3.0)<0.001)
	var walker:CharacterBody3D=museum.get("_player")
	for side in ["west","east"]:
		var obstacle_x:=5.0 if side=="west" else 13.0
		var outside_x:=2.7 if side=="west" else 16.5
		var mouth_x:=4.8 if side=="west" else 13.2
		walker.global_position=origin+Vector3(obstacle_x,0.02,21.5);walker.velocity=Vector3.ZERO
		await tick()
		check(side+" stopper blocks the straight approach",not await walk_to(walker,origin+Vector3(obstacle_x,0,25.5),120))
		walker.global_position=origin+Vector3(obstacle_x,0.02,21.5);walker.velocity=Vector3.ZERO
		await tick()
		for p in [Vector2(outside_x,21.5),Vector2(outside_x,26.5),Vector2(mouth_x,27.5),Vector2(9,27.5)]:
			check(side+" detour and ascent "+str(p),await walk_to(walker,origin+Vector3(p.x,0,p.y)))
		check(side+" ascent reaches platform height",absf(walker.global_position.y-origin.y-1.0)<0.08)
		for p in [Vector2(9,30),Vector2(9,33.5)]:
			check(side+" route descends via "+str(p),await walk_to(walker,origin+Vector3(p.x,0,p.y)))
		check(side+" descent returns to normal floor",absf(walker.global_position.y-origin.y)<0.08)
	# Three flat shortcuts must meet physical wall, not merely a navigation rule.
	for x in [3.0,9.5,16.0]:
		walker.global_position=origin+Vector3(x,0.02,24);walker.velocity=Vector3.ZERO
		await tick()
		check("flat bypass blocked at x="+str(x),not await walk_to(walker,origin+Vector3(x,0,33),160))
	walker.global_position=origin+Vector3(16,0.02,33.5);walker.velocity=Vector3.ZERO
	await tick()
	for p in [Vector2(16,35),Vector2(19.5,35),Vector2(19.5,37),Vector2(19.5,35),Vector2(16,35),Vector2(14,43),Vector2(8,43)]:
		check("rock room and exit remain reachable "+str(p),await walk_to(walker,origin+Vector3(p.x,0,p.y)))
	await snapshot("entry-signs",origin+Vector3(9,1.65,21.5),origin+Vector3(9,1.3,26),62)
	await snapshot("west-approach",origin+Vector3(4.0,1.65,27.5),origin+Vector3(10,1.1,27.5),70)
	await snapshot("east-approach",origin+Vector3(15,1.65,27.5),origin+Vector3(9,1.1,27.5),70)
	await snapshot("platform-descent",origin+Vector3(9,2.65,28),origin+Vector3(9,0.5,35),68)
	await snapshot("standing-stoppers",origin+Vector3(9,5,19.5),origin+Vector3(9,1,25),70)
	await snapshot("three-metre-landing",origin+Vector3(9,12,27.4),origin+Vector3(9,0.8,28),65)
	await snapshot("route-overview",origin+Vector3(9.5,18,18),origin+Vector3(9.5,0,29),55)

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real museum geometry, native CharacterBody walking, floor rays and rendered captures. No headset comfort or visitor comprehension claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("WEDGE SPACING AND STOPPERS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
