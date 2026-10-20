extends "res://doc/book/iterations/2026-10-17-wedge-spacing-stoppers/probe.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var alignment:=find_scene("/align_solid.gd")
	var anchor:=find_scene("/wedge_palace.gd")
	check("alignment and writing anchor retained",alignment!=null and anchor!=null)
	if alignment==null or anchor==null:return
	var origin:=alignment.global_position-Vector3(7,0,4)
	observations["origin"]=xyz(origin)
	check("architecture owns the platform",anchor.layout=="map" and anchor.get_child_count()==0)
	var wedges:Array=[];var stoppers:Array=[];var signs:Array=[]
	for n in hall.find_children("*","Node3D",true,false):
		if n.scene_file_path.ends_with("/walkableprism.tscn"):wedges.append(n)
		if n.scene_file_path.ends_with("/prism_block.tscn") and not n.has_meta("sculpture_piece"):stoppers.append(n)
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/street_sign.gd"):signs.append(n)
	check("ten stock wp units for side approaches and descent",wedges.size()==10)
	check("five standing prisms form one bank",stoppers.size()==5)
	check("STOP and three direction signs retained",signs.size()==4)
	var min_x:=INF;var max_x:=-INF;var min_z:=INF;var max_z:=-INF
	for n in stoppers:
		check("stopper remains solid and two metres tall",n.grain=="solid" and n.scale.is_equal_approx(Vector3.ONE*2))
		check("standing prism keeps its collider",n.get_node("StaticBody3D/CollisionShape3D").shape is ConcavePolygonShape3D)
		var mesh:MeshInstance3D=n.get_node("StaticBody3D/MeshInstance3D")
		var box:=mesh.get_aabb()
		for i in 8:
			var p:Vector3=mesh.global_transform*box.get_endpoint(i)-origin
			min_x=minf(min_x,p.x);max_x=maxf(max_x,p.x);min_z=minf(min_z,p.z);max_z=maxf(max_z,p.z)
	observations["bank_bounds_in_map_centres"]=[min_x,max_x,min_z,max_z]
	check("bank follows ten by two grid cells",absf(min_x-4.5)<0.01 and absf(max_x-14.5)<0.01 and absf(min_z-23.5)<0.01 and absf(max_z-25.5)<0.01)
	observations["left_clear_passage_m"]=min_x-1.5
	observations["right_clear_passage_m"]=17.5-max_x
	check("three metres clear on both sides",absf(min_x-1.5-3.0)<0.01 and absf(17.5-max_x-3.0)<0.01)
	for w in wedges:
		var p:Vector3=w.global_position-origin
		check("stock wp keeps its dimensions "+w.name,w.scale.is_equal_approx(Vector3.ONE))
		if absf(p.z-29)<0.01:
			check("side ramp points forward "+w.name,w.global_basis.z.dot(Vector3.BACK)>0.99)
			check("side ramp follows the blocker encounter "+w.name,p.z-1.5>max_z)
	for p in [Vector2(2,30),Vector2(17,30),Vector2(2,32),Vector2(17,32)]:
		check("broad structure-2 platform supports "+str(p),absf(height_at(origin+Vector3(p.x,0,p.y))-1.0)<0.02)
	for p in [Vector2(3,28.5),Vector2(16,28.5),Vector2(9.5,33.5)]:
		check("ramp has half-height collision "+str(p),absf(height_at(origin+Vector3(p.x,0,p.y))-0.5)<0.03)
	var walker:CharacterBody3D=museum.get("_player")
	walker.global_position=origin+Vector3(9.5,0.02,21.5);walker.velocity=Vector3.ZERO
	await tick()
	check("central bank blocks straight movement",not await walk_to(walker,origin+Vector3(9.5,0,26),120))
	for side in ["left","right"]:
		var x:=3.0 if side=="left" else 16.0
		walker.global_position=origin+Vector3(9.5,0.02,21.5);walker.velocity=Vector3.ZERO
		await tick()
		for p in [Vector2(x,21.5),Vector2(x,26),Vector2(x,27.2),Vector2(x,31)]:
			check(side+" route around bank then up "+str(p),await walk_to(walker,origin+Vector3(p.x,0,p.y)))
		check(side+" ramp reaches one metre height",absf(walker.global_position.y-origin.y-1.0)<0.08)
		for p in [Vector2(9.5,31),Vector2(9.5,35)]:
			check(side+" landing and descent "+str(p),await walk_to(walker,origin+Vector3(p.x,0,p.y)))
		check(side+" descent returns to floor",absf(walker.global_position.y-origin.y)<0.08)
	# The front of the platform is a step, so a grounded centre route cannot
	# bypass the side ramps. The original outer walls bound the platform ends.
	walker.global_position=origin+Vector3(9.5,0.02,27);walker.velocity=Vector3.ZERO
	await tick()
	check("central vertical face requires a side ramp",not await walk_to(walker,origin+Vector3(9.5,0,31),120))
	walker.global_position=origin+Vector3(9.5,0.02,35);walker.velocity=Vector3.ZERO
	await tick()
	for p in [Vector2(16,35),Vector2(19.5,35),Vector2(19.5,37),Vector2(19.5,35),Vector2(16,35),Vector2(14,43),Vector2(8,43)]:
		check("basin, rock room and exit approach "+str(p),await walk_to(walker,origin+Vector3(p.x,0,p.y)))
	var column:=find_scene("/wedge_column.gd")
	var model:=find_scene("/wedge_mouse_model.gd")
	check("sculpture and model on platform",column!=null and model!=null)
	if column!=null:
		check("six original prisms compose sculpture",column.pieces.size()==6)
		check("sculpture base rests on platform",absf(column.global_position.y-origin.y-1.0)<0.02)
		for piece in column.pieces:
			check("original prism retained "+piece.name,piece.scene_file_path.ends_with("/prism_block.tscn") and piece.get_node("StaticBody3D/CollisionShape3D").shape is ConcavePolygonShape3D)
		await snapshot("platform-sculpture",column.to_global(Vector3(-2.0,1.7,-3.1)),column.to_global(Vector3(0,0.95,0)),49)
	if model!=null:
		check("model plinth rests on platform",absf(model.global_position.y-origin.y-1.0)<0.02)
		check("player steers through returning joystick",model.joystick.get_node("JoystickOrigin/InteractableJoystick").default_on_release)
		check("model contains seven movable wedge bodies",model.pieces.size()==7)
		for b in [model.jump_button,model.home_button,model.reset_button]:
			check("button cap faces out of plinth "+b.name,model.to_local(b.get_node("Button/ButtonMesh").global_position).z < -0.52)
		check("mouse starts at plinth height",absf(model.mouse.global_position.y-model.global_position.y-model.TOP)<0.03)
		await snapshot("mouse-model",model.to_global(Vector3(1.6,2.1,-2.0)),model.to_global(Vector3(0,0.9,0)),50)
		await snapshot("model-controls",model.to_global(Vector3(0,1.25,-2.0)),model.to_global(Vector3(0,0.72,0)),53)
	await snapshot("sculpture-and-model",origin+Vector3(9.5,3.5,27.5),origin+Vector3(9.5,1.8,32),74)
	await snapshot("first-central-blockers",origin+Vector3(9.5,2.6,19),origin+Vector3(9.5,1,25),72)
	await snapshot("then-side-ramp",origin+Vector3(3,1.65,26),origin+Vector3(3,1.0,31),68)
	await snapshot("right-side-ramp",origin+Vector3(16,1.65,26),origin+Vector3(16,1.0,31),68)
	await snapshot("on-the-platform",origin+Vector3(4,2.65,31),origin+Vector3(13,1.4,31),70)
	await snapshot("grid-route-overview",origin+Vector3(9.5,20,23),origin+Vector3(9.5,0,28),58)
	await snapshot("far-descent",origin+Vector3(9.5,2.65,31),origin+Vector3(9.5,0.3,35.5),72)

func finish() -> void:
	var result:={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real museum geometry and native CharacterBody routes: central blockers, clear side passages, forward wp ramps, raised platform, descent and downstream access. Sculture and player-controlled model loaded on platform. No wearer or comprehension claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("WEDGE SCULPTURE AND MODEL ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
