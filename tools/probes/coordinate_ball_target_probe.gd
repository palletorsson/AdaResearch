extends "res://tools/probes/void_triangle_probe.gd"

var drop_events := 0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	for mode in [false, true]: await exercise_target(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Godot target, physics, desktop grip and synthetic XR controllers. Physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func carry_to(where: Vector3, use_xr: bool) -> void:
	if use_xr: hand_at(right,where)
	else:
		game.camera.global_position=where+Vector3(0,0,1.5)
		game.camera.global_basis=Basis.IDENTITY
		game.body.desktop_pointer._hold_distance=1.5
	await frames(12)

func exercise_target(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	game.checkpoint=2
	game.place_player(Vector3(18,-11.94,7.5))
	await frames(60)
	var content: Node3D=game.building.content
	while not content.pending.is_empty(): await frames(2)
	var target: Node3D=content.exhibits["2/museum-point_coordinates-10-6"].get_node("Artifact")
	var frame: Node3D=content.exhibits["2/frame"].get_node("Artifact")
	var fixed_pose:=frame.global_transform
	var point: RigidBody3D=game.coordinate_point
	var original_points:=get_nodes_in_group("ada_coordinate_point").size()
	var centre: Vector3=target.global_position+Vector3(0,target.catch_height,0)
	drop_events=0
	target.balls_dropped.connect(func(_count): drop_events+=1)
	check(tag+"original target uses arrows and world coordinate labels",target.encounter=="arrows" and target.ball_labels and target.label_space=="world")
	check(tag+"fixed frame has no experimental grip",frame.find_child("FrameControl",true,false)==null)
	check(tag+"no balls before a delivery",target._tags.is_empty())
	if use_xr:
		hand_at(right,point.global_position);await frames(12)
		right.set_input("grip",1.0);await frames(12)
	else:
		game.body.desktop_pointer._grab_held(point);await frames(12)
	check(tag+"original black point is actually held",point.is_picked_up())
	await carry_to(centre+Vector3(-.8,0,0),use_xr)
	check(tag+"outside the target does not trigger",drop_events==0)
	# Capture the target before the real held point enters it.
	if use_xr and "--capture" in OS.get_cmdline_user_args():
		game.get_node("XROrigin3D").hide()
		await photograph("target-before.png",Vector3(15.7,-10.2,8.2),centre+Vector3(0,.7,0),72)
	await carry_to(centre,use_xr)
	check(tag+"arrival creates exactly seven falling balls once",drop_events==1 and target._tags.size()==7)
	check(tag+"the existing held point reaches the target",point.global_position.distance_to(centre)<.1)
	var highest:float=-INF
	for entry in target._tags:
		highest=maxf(highest,entry.body.global_position.y+target.ball_radius)
	check(tag+"all balls spawn below the next floor",highest < -6.36 and target.drop_height+1.4+target.ball_radius+target.position.y<5.64)
	if use_xr and "--capture" in OS.get_cmdline_user_args():
		await photograph("balls-falling.png",Vector3(15.6,-9.8,8.5),centre+Vector3(0,1,0),75)
	var first:RigidBody3D=target._tags[0].body
	var y_before:=first.global_position.y
	var label_before:String=target._tags[0].tag.text
	await frames(18)
	check(tag+"gravity changes the position and its label",first.global_position.y<y_before and target._tags[0].tag.text!=label_before)
	# SceneTree.process_frame fires BEFORE the target's _process. Sample after
	# all nodes have updated, so labels and physics positions are the same frame.
	await create_timer(0.0).timeout
	var labels_match:=true
	for entry in target._tags:
		var w:Vector3=entry.body.global_position
		labels_match=labels_match and entry.tag.text=="%.1f, %.1f, %.1f"%[w.x,w.y,w.z]
		labels_match=labels_match and entry.tag.global_position.is_equal_approx(w+Vector3(0,target.ball_radius+target.label_gap,0))
	check(tag+"every upright label follows the real world Vector3",labels_match)
	await frames(100)
	check(tag+"remaining inside does not repeatedly spawn",drop_events==1 and target._tags.size()==7)
	var on_floor:=true
	for entry in target._tags: on_floor=on_floor and entry.body.global_position.y>-12 and entry.body.global_position.y<-11.7
	check(tag+"balls land on this floor instead of the one above",on_floor)
	check(tag+"point movement leaves coordinate frame fixed",frame.global_transform.is_equal_approx(fixed_pose))
	if use_xr and "--capture" in OS.get_cmdline_user_args():
		await photograph("balls-on-floor.png",Vector3(15.5,-10.3,8),centre+Vector3(0,-.65,0),68)
		await photograph("fixed-frame.png",Vector3(3.4,-10.35,-.8),Vector3(-2,-11.3,2),75)
	await carry_to(centre+Vector3(-.8,0,0),use_xr)
	await carry_to(centre,use_xr)
	check(tag+"leave and return drops another seven",drop_events==2 and target._tags.size()==14)
	if use_xr: right.set_input("grip",0.0)
	else: game.body.desktop_pointer._drop_held()
	await frames(5)
	check(tag+"original black point remains reusable",not point.is_picked_up() and get_nodes_in_group("ada_coordinate_point").size()==original_points and point.is_in_group("ada_coordinate_point"))
	game.queue_free();await frames(3)
	if use_xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)
