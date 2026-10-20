extends "res://tools/probes/corner_rooms.gd"

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
	# Enter Rose, then its cyan doorway, with the original sphere.
	var rose:Dictionary=portal(-1,0)
	walker.global_position=rose.source.to_global(Vector3(0,0.05,1.1))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,-0.8)
	hand._grab_held(wing.point);overlap.have_eye=false;overlap.update(0.016)
	check("enter Rose through native doorway",await walk_through(rose))
	var gallery:Node3D=overlap.repeating
	walker.global_position=gallery.source.to_global(Vector3(0,0.05,1.1))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,-0.8)
	overlap.have_eye=false;overlap.update(0.016)
	check("enter repeating gallery through native doorway",await walk_through(portal(0,-3)))
	var identity:int=wing.point.get_instance_id();var room:Node3D=gallery.room
	var node_count:int=room.find_children("*","Node",true,false).size()
	await capture("inside",room.to_global(Vector3(0,1.7,1.1)),room.to_global(Vector3(0,1.7,-11)),82)
	# Use real collision sweeps, not a synthetic camera wrap.
	for axis:Vector3 in [Vector3.FORWARD,Vector3.RIGHT,Vector3.LEFT,Vector3.BACK]:
		walker.global_position=room.to_global(Vector3(0,0.05,-0.4))
		wing.point.global_position=wing.eye_position()+Vector3(0.15,-0.2,0)
		overlap.have_eye=false;overlap.update(0.016)
		var before:Vector2i=gallery.laps;var offset:Vector3=wing.point.global_position-wing.eye_position()
		var basis:Basis=walker.global_basis;var blocked:=false
		for step in range(350):
			var d:=axis*0.05
			if walker.test_move(walker.global_transform,d):blocked=true;break
			walker.global_position+=d;wing.point.global_position+=d;overlap.update(0.016)
			if gallery.laps!=before:break
		check("collision-supported wrap "+str(axis),not blocked and gallery.laps!=before)
		check("wrap retains point and held offset "+str(axis),wing.point.get_instance_id()==identity and (wing.point.global_position-wing.eye_position()).distance_to(offset)<0.0002)
		check("wrap keeps player heading "+str(axis),walker.global_basis.is_equal_approx(basis))
		check("wrap arrival has floor "+str(axis),not floor_at(walker.global_position).is_empty())
	check("one physical tile; visual neighbours have no colliders",room.find_children("*","MultiMeshInstance3D",true,false).all(func(n):return n.get_child_count()==0))
	check("visual patch does not grow with crossings",node_count==room.find_children("*","Node",true,false).size())
	# Leave one live point, walk a full lap, find the same record again.
	hand._drop_held();wing.point.global_position=room.to_global(Vector3(0.4,1.2,-1.2))
	overlap.update(0.016);var kept:Vector3=wing.point.global_position
	walker.global_position=room.to_global(Vector3(0,0.05,0));overlap.have_eye=false;overlap.update(0.016)
	for step in range(170):
		var d:=Vector3.FORWARD*0.05
		if walker.test_move(walker.global_transform,d):check("unheld lap path clear",false);return
		walker.global_position+=d;overlap.update(0.016)
	check("point left behind survives a lap",wing.point.global_position.is_equal_approx(kept) and wing.point.get_instance_id()==identity)
	check("eight point echoes share original mesh without physics",gallery.echoes.size()==8 and gallery.echoes.all(func(e):return e.mesh==wing.point.get_child(0).mesh and e.get_child_count()==0))
	hand._grab_held(wing.point)
	await capture("across-edge",room.to_global(Vector3(0,1.7,-3.2)),room.to_global(Vector3(0,1.6,-10)),80)
	wing.point.visible=false
	await capture("room-above",room.to_global(Vector3(-12,15,16)),room.to_global(Vector3(0,0.8,0)),72)
	wing.point.visible=true
	walker.global_position=gallery.target.to_global(Vector3(0,0.05,1.0));wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,0.5)
	overlap.have_eye=false;overlap.update(0.016)
	check("native return to Rose",await walk_through(portal(-3,0)))
	check("same held point returns",wing.point.get_instance_id()==identity and overlap.point_sector==0)
	wing.visit(1);overlap.update(0.016)
	check("navigation hides repeated geometry",not room.visible)
	observations["renderer"]=str(RenderingServer.get_current_rendering_method())
	observations["period_metres"]=gallery.PERIOD;observations["physical_tiles"]=1;observations["visible_tiles"]=9
	observations["scope"]="Native walker and hand, four wrap directions, identity/offset/heading/floor, unheld point persistence. Fixed 3x3 rendered neighbourhood; no gravity inversion or headset acceptance."
	complete=true
