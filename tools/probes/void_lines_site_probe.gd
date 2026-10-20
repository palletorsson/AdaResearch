extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await capture_room()
	else:
		await arrangement(false)
		await arrangement(true)
	OS.delay_msec(150)
	await frames(10)
	var filename := "capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Point Lines worksite placement, real player traversal and original artifact contracts; synthetic XR, not a physical headset."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive(use_xr: bool) -> void:
	await start(use_xr)
	game.checkpoint=3
	game.place_player(Vector3(.5,-17.94,7.5))
	await frames(45)

func finish_room(use_xr: bool) -> void:
	game.queue_free()
	await frames(15)
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func arrangement(use_xr: bool) -> void:
	await arrive(use_xr)
	var tag := "XR" if use_xr else "Desktop"
	var content: Node3D = game.building.content
	var setting: Node3D = content.exhibits["3/setting_out"].get_node("Artifact")
	var directions: Node3D = content.exhibits["3/directions"].get_node("Artifact")
	var assembly: Node3D = content.exhibits["3/assembly"].get_node("Artifact")
	var consequences: Node3D = content.exhibits["3/consequences"].get_node("Artifact")
	check(tag+": four original areas still occupy floor 03",[setting,directions,assembly,consequences].all(func(area): return area.is_in_group("void_lines_area") and is_equal_approx(area.global_position.y,-18)))
	check(tag+": copied police barrier retained",content.exhibits.has("3/directions-copy-1"))
	check(tag+": original three props plus five construction guides",content.data.floors[3].props.size()==8)
	for item in content.data.floors[3].props:
		if not str(item.id).begins_with("lines-"): continue
		var prop: Node3D = content.props["3/"+str(item.id)]
		check(tag+": shared editor pose reaches "+str(item.id),prop.position.is_equal_approx(Vector3(item.position[0],0,item.position[1])) and is_equal_approx(prop.rotation_degrees.y,float(item.facing)))
	check(tag+": both work lights run",content.props["3/lines-work-light"].get_node("Prefab/WorkBeam").is_visible_in_tree() and content.props["3/lines-bench-light"].get_node("Prefab/WorkBeam").is_visible_in_tree())
	# Follow the same editable route that the lab editor draws.
	for stop in content.data.floors[3].route:
		var target := Vector3(float(stop.position[0]),-18,float(stop.position[1]))
		var reached: bool = await move_to(target)
		check(tag+": "+str(stop.label),reached)
		if not reached: break
	check(tag+": curated route causes no fall or health loss",game.deaths==0 and is_equal_approx(game.health.get_health(),100))
	var room: Node3D = setting.get_node("MeasurementRoom")
	room.point_b.position.x+=1
	await frames(5)
	check(tag+": endpoint movement still changes measured length",room.readout.text=="2.60 m")
	room.reset_line()
	check(tag+": measurement can still reset",room.readout.text=="1.60 m")
	var field: Node3D = setting.get_node("PairingPoints")
	var a: Node3D = field.points[0]
	var b: Node3D = field.points[1]
	a.global_position=b.global_position+Vector3(.1,0,0)
	a.dropped.emit(a)
	await frames(8)
	check(tag+": the existing twelve points still make connections",field.points.size()==12 and field.manager._connections.size()>0)
	check(tag+": the painted line into air stays non-solid",not directions.get_node("FollowIntoAir") is CollisionObject3D)
	var middle := ray(Vector3(10,-17,1.3),Vector3(10,-19,1.3))
	check(tag+": shaft crossing is supported by the original plank",not middle.is_empty() and middle.collider.get_meta("fixed_construction",false))
	var loose: Node3D = assembly.get_node("Hand_plank")
	check(tag+": bench plank remains grabbable",loose.enabled and not loose.has_meta("fixed_construction"))
	if use_xr:
		hand_at(right,loose.global_position)
		await frames(12)
		right.set_input("grip",1.0)
		await frames(10)
		check("XR: original plank can be picked up",loose.is_picked_up())
		right.set_input("grip",0.0)
		await frames(8)
		check("XR: original plank can be released",not loose.is_picked_up())
	check(tag+": X and plus still share tower health",consequences.hazard.health_provider==game.health and consequences.recovery.health_provider==game.health)
	# Test the user's current placements, not the original hard-coded hall coordinates.
	var danger: Vector3 = consequences.hazard.global_position
	game.place_player(Vector3(danger.x+1.6,-17.94,danger.z))
	await frames(12)
	check(tag+": enter the X from the clear side",await move_to(Vector3(danger.x,-18,danger.z)))
	await frames(40)
	check(tag+": X reduces health",game.health.get_health()<100 and not game.recovering)
	check(tag+": leave the X towards recovery",await move_to(Vector3(danger.x-1.7,-18,danger.z)))
	var after: float = game.health.get_health()
	await frames(45)
	check(tag+": leaving stops damage",is_equal_approx(after,game.health.get_health()))
	var recovery: Vector3 = consequences.recovery.global_position
	check(tag+": reach the raised plus at floor level",await move_to(Vector3(recovery.x,-18,recovery.z)))
	await frames(8)
	check(tag+": plus restores health",game.health.get_health()>after and consequences.recovery.is_spent())
	await finish_room(use_xr)

func capture_room() -> void:
	await arrive(false)
	game._set_enabled(false)
	for item in [
		["lines-arrival.png",Vector3(-1.6,-16.35,8.6),Vector3(.4,-16.65,4.5),85],
		["lines-network.png",Vector3(-14.1,-16.35,5.8),Vector3(-17.4,-16.85,.8),82],
		["lines-directions.png",Vector3(3,-16.35,-2.6),Vector3(-1.5,-17.1,-6.5),83],
		["lines-assembly.png",Vector3(13.6,-16.35,1.9),Vector3(17.1,-16.8,-3.5),86],
		["lines-consequences.png",Vector3(11.8,-16.35,-3.8),Vector3(7.7,-16.6,-5.3),85]
	]:
		await photograph(item[0],item[1],item[2],item[3])
		check("Native Mobile screenshot: "+str(item[0]),FileAccess.file_exists(out.path_join(item[0])))
	await finish_room(false)
