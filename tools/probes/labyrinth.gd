extends "res://tools/probes/corner_rooms.gd"

func approach(link:Dictionary)->bool:
	var room:Node3D=overlap.sector_room(overlap.sector)
	if not await walk_to(room.to_global(Vector3(0,0.05,0))):return false
	return await walk_to(link.source.to_global(Vector3(0,0.05,0.9)))

func landing_checks()->void:
	var start:=Time.get_ticks_msec()
	while (not museum.get("_stamp_queue").is_empty() or not museum.get("_cartridge_pending_nodes").is_empty()) and Time.get_ticks_msec()-start<35000:
		museum.call("_drain_stamps");museum.call("_drain_cartridge_nodes");await tick()
	wing=find_scene("/noneuclidean_wing.gd")
	check("wing installed in museum",wing!=null)
	if wing==null:return
	while not wing.built:await tick()
	wing.set_process(false);overlap=wing.overlap;corners=overlap.corners
	walker=museum.get("_player")
	for n in walker.find_children("*","Node3D",true,false):
		if n.has_method("_grab_held"):hand=n;break
	check("native hand found",hand!=null)
	if hand==null:return
	hand.set_process(false);wing.visit(0)
	var blue:Dictionary=portal(-1,1)
	walker.global_position=blue.source.to_global(Vector3(0,0.05,1.1))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,-0.8)
	hand._grab_held(wing.point);overlap.have_eye=false;overlap.update(0.016)
	check("enter Blue",await walk_through(blue))
	var maze:Node3D=overlap.labyrinth
	walker.global_position=maze.source.to_global(Vector3(0,0.05,1.1))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,-0.8)
	overlap.have_eye=false;overlap.update(0.016)
	check("native entry to labyrinth A",await walk_through(portal(1,-5)))
	var identity:int=wing.point.get_instance_id()
	check("every paired doorway preserves heading",maze.pairs.all(func(p):return portal(p.a,p.b).transfer.basis.is_equal_approx(Basis.IDENTITY)))
	await capture("room-a",maze.rooms[0].to_global(Vector3(0.3,1.7,2.9)),maze.rooms[0].to_global(Vector3(-0.5,1.5,-3)),83)
	# Collision physically prevents use from either side until opened.
	for index in [0,2]:
		var room:Node3D=maze.rooms[index]
		var x:float=-3.2 if index==0 else 3.2
		var transform:=walker.global_transform;transform.origin=room.to_global(Vector3(x,0.05,0))
		check("locked shortcut collision %d"%index,walker.test_move(transform,Vector3(-0.6 if index==0 else 0.6,0,0)))
	# Leave the real point on A's podium. The other rooms keep its record.
	var resting:Vector3=maze.rooms[0].to_global(Vector3(-1.7,1.21,1.2))
	wing.move_together(maze.rooms[0].to_global(Vector3(0.1,1.7,2.5))-wing.eye_position())
	overlap.have_eye=false
	for i in range(24):
		await tick();hand.cam.look_at(resting)
		hand._hold_distance=hand.cam.global_position.distance_to(resting);hand._process(0.016)
	hand._drop_held();overlap.update(0.016)
	await tick();overlap.update(0.016);var kept:Vector3=wing.point.global_position
	check("native hand places marker on podium",kept.distance_to(resting)<0.02)
	for edge in [[-5,-6],[-6,-7],[-7,-8],[-8,-5]]:
		var link:Dictionary=portal(edge[0],edge[1])
		check("clear loop approach "+str(edge),await approach(link))
		check("native loop passage "+str(edge),await walk_through(link))
		check("loop arrival supported "+str(edge),not floor_at(walker.global_position).is_empty())
	check("four-room circuit returns to A with same marker",overlap.sector==-5 and overlap.point_sector==-5 and wing.point.global_position.is_equal_approx(kept) and wing.point.get_instance_id()==identity)
	observations["marker_loop"]={"kept":xyz(kept),"returned":xyz(wing.point.global_position),"player_sector":overlap.sector,"point_sector":overlap.point_sector}
	await capture("marker-returned",maze.rooms[0].to_global(Vector3(0.1,1.7,2.5)),maze.rooms[0].to_global(Vector3(-1.7,1.35,1.2)),70)
	hand._grab_held(wing.point)
	check("retrieve original marker",hand._held.get_instance_id()==identity)
	wing.point.global_position=maze.seal.global_position;overlap.update(0.016)
	check("held point opens both sides of shortcut",maze.shortcut_open and not maze.gate.visible and not maze.reverse_gate.visible and maze.gate.get_child(0).collision_layer==0 and maze.reverse_gate.get_child(0).collision_layer==0)
	await capture("shortcut",maze.rooms[0].to_global(Vector3(-1.6,1.7,0)),maze.rooms[0].to_global(Vector3(-7,1.5,0)),76)
	check("clear shortcut approach",await approach(portal(-5,-7)))
	check("shortcut reaches C directly",await walk_through(portal(-5,-7)))
	await capture("room-c",maze.rooms[2].to_global(Vector3(1.3,1.75,2.7)),maze.rooms[2].to_global(Vector3(-1,1.7,0)),85)
	check("shortcut remains open after leaving A",maze.shortcut_open)
	check("reverse shortcut approach",await approach(portal(-7,-5)))
	check("reverse shortcut returns to A",await walk_through(portal(-7,-5)))
	check("same held point through shortcut",wing.point.get_instance_id()==identity and overlap.point_sector==-5)
	check("museum return approach",await approach(portal(-5,1)))
	check("native return to Blue",await walk_through(portal(-5,1)))
	wing.visit(1);overlap.update(0.016)
	check("navigation hides every labyrinth room",maze.rooms.all(func(r):return not r.visible))
	observations["renderer"]=str(RenderingServer.get_current_rendering_method())
	observations["scope"]="Finite four-room loop, reversible hand-unlocked shortcut, real walker collision and one persistent marker. No headset acceptance."
	complete=true
