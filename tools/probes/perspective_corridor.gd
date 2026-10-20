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
	check("native museum hand found",hand!=null)
	if hand==null:return
	hand.set_process(false);wing.visit(0)
	var p:Node3D=overlap.perspective
	var identity:int=wing.point.get_instance_id()
	walker.global_position=p.source.to_global(Vector3(0,0.05,1.1))
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,-0.8)
	hand._grab_held(wing.point);overlap.have_eye=false;overlap.update(0.016)
	check("actual walker enters perspective room",await walk_through(portal(-1,-2)))
	check("same carried point enters",overlap.point_sector==-2 and wing.point.get_instance_id()==identity)
	var room:Node3D=p.room
	check("front to back measures eight metres",is_equal_approx(p.FRONT-p.BACK,8))
	check("18 columns constructed",p.columns.size()==18)
	check("rear columns shrink in height and radius",p.columns[16].mesh.height<p.columns[0].mesh.height*0.5 and p.columns[16].mesh.top_radius<p.columns[0].mesh.top_radius*0.5)
	await capture("front",room.to_global(Vector3(0,1.7,4.25)),room.to_global(Vector3(0,1.5,-5.2)),66)
	check("walk to side path",await walk_to(room.to_global(Vector3(-3.1,0.05,4.25))))
	check("walk beside full corridor",await walk_to(room.to_global(Vector3(-3.1,0.05,-5.2))))
	check("side path has continuous floor",not floor_at(room.to_global(Vector3(-3.1,0,-5.2))).is_empty())
	await capture("side",room.to_global(Vector3(-5,1.8,-3.8)),room.to_global(Vector3(0,1.6,0)),85)
	check("sphere retains mesh radius",is_equal_approx(wing.point.get_child(0).mesh.radius,0.085))
	wing.point.visible=false
	await capture("room-above",room.to_global(Vector3(-8,11,9)),room.to_global(Vector3(0,0.8,-1)),65)
	wing.point.visible=true
	# Supported return uses the same actual collision body and portal sweep.
	walker.global_position=room.to_global(Vector3(-3.1,0.05,4.4));overlap.have_eye=false
	wing.point.global_position=wing.eye_position()+Vector3(0.2,-0.2,0.8);overlap.update(0.016)
	check("return approach clear",await walk_to(room.to_global(Vector3(0,0.05,4.9))))
	check("actual walker returns to linked rooms",await walk_through(portal(-2,-1)))
	hand._drop_held();overlap.update(0.016)
	check("same point returned",wing.point.get_instance_id()==identity and overlap.point_sector==-1)
	check("corner-room entry retained",not portal(-1,2).is_empty())
	wing.visit(1);overlap.update(0.016)
	check("navigation hides perspective room",not room.visible)
	observations["renderer"]=str(RenderingServer.get_current_rendering_method())
	observations["scope"]="Real museum walker and hand. Eight-metre geometric model inspired by Borromini, not a measured reconstruction. Physical XR acceptance open."
	complete=true
