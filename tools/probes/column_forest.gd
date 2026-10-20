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
	var blue:Dictionary=portal(-1,1)
	walker.global_position=blue.source.to_global(Vector3(0,0.05,1.1))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,-0.8)
	hand._grab_held(wing.point);overlap.have_eye=false;overlap.update(0.016)
	check("native entry into Blue",await walk_through(blue))
	var forest:Node3D=overlap.forest;var room:Node3D=forest.room
	walker.global_position=forest.source.to_global(Vector3(0,0.05,1.1))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,-0.8)
	overlap.have_eye=false;overlap.update(0.016)
	check("native entry into column forest",await walk_through(portal(1,-4)))
	var identity:int=wing.point.get_instance_id()
	check("eight architectural columns",forest.columns.size()==8)
	check("front study has four branches",forest.branches.size()==4)
	await capture("inside",room.to_global(Vector3(0,1.75,8.8)),room.to_global(Vector3(0,6,-5)),88)
	check("clear walk along central nave",await walk_to(room.to_global(Vector3(0,0.05,0))) and await walk_to(room.to_global(Vector3(0,0.05,-8.5))))
	check("floor supports nave end",not floor_at(walker.global_position).is_empty())
	var count:int=room.find_children("*","Node",true,false).size()
	wing.point.global_position=wing.eye_position()-room.global_basis.x*0.7;forest.update_hand()
	var narrow:float=forest.angle;var narrow_tip:Vector3=forest.branches[0].position+forest.branches[0].basis.y*forest.branches[0].mesh.height/2
	wing.point.global_position=wing.eye_position()+room.global_basis.x*0.7;forest.update_hand()
	var wide_tip:Vector3=forest.branches[0].position+forest.branches[0].basis.y*forest.branches[0].mesh.height/2
	check("carried point opens branch angle",forest.angle>narrow+30)
	check("actual geometry spreads",wide_tip.x>narrow_tip.x+0.4)
	wing.point.action_pressed.emit(wing.point)
	check("native point trigger shows construction lines",forest.show_rule and forest.guides.all(func(g):return g.visible))
	wing.point.action_pressed.emit(wing.point)
	check("native point trigger hides construction lines",not forest.show_rule and forest.guides.all(func(g):return not g.visible))
	for i in range(80):
		wing.point.global_position=wing.eye_position()+room.global_basis.x*(0.7 if i%2==0 else -0.7);forest.update_hand()
	check("hand updates do not grow nodes",room.find_children("*","Node",true,false).size()==count)
	check("same live point throughout",wing.point.get_instance_id()==identity and overlap.point_sector==-4)
	await capture("study",room.to_global(Vector3(-3.5,1.7,8.1)),room.to_global(Vector3(-3.5,1.8,5.8)),65)
	wing.point.action_pressed.emit(wing.point)
	await capture("branches",room.to_global(Vector3(0,2.8,4.5)),room.to_global(Vector3(-4.6,8.8,2)),90)
	wing.point.visible=false
	await capture("room-above",room.to_global(Vector3(-14,19,18)),room.to_global(Vector3(0,4,0)),72)
	wing.point.visible=true
	walker.global_position=forest.target.to_global(Vector3(0,0.05,1.0))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,0.5)
	overlap.have_eye=false;overlap.update(0.016)
	check("native return to Blue",await walk_through(portal(-4,1)))
	check("same held point returned",wing.point.get_instance_id()==identity and overlap.point_sector==1)
	# Dynamic previews must follow the branch geometry changed inside the room.
	var link:Dictionary=portal(1,-4)
	camera.global_position=forest.source.to_global(Vector3(0,1.7,1));camera.look_at(forest.source.to_global(Vector3(0,1.7,-4)))
	overlap.update_visibility(camera)
	check("branch preview tracks live geometry",link.meshes.filter(func(c):return c.has_meta("original")).all(func(c):return c.global_transform.is_equal_approx(link.transfer.affine_inverse()*c.get_meta("original").get_ref().global_transform)))
	wing.visit(1);overlap.update(0.016)
	check("navigation hides forest",not room.visible)
	observations["renderer"]=str(RenderingServer.get_current_rendering_method())
	observations["scope"]="Gaudi-inspired geometric study, not surveyed basilica or structural solver. Native walker/point/action, dynamic geometry and preview; physical headset acceptance open."
	complete=true
