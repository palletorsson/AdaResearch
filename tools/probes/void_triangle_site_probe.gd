extends "res://tools/probes/void_pythagoras_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await capture_room()
	else:
		await arrangement(false)
		await arrangement(true)
		# Retained Trace -> Grid -> Triangle, real grips, closure and assembly.
		await triangle_contract()
	OS.delay_msec(150)
	await frames(10)
	var filename := "capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native tower route, proof walls, fold and retained drawing. Desktop and synthetic XR; not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive(use_xr: bool) -> void:
	await start(use_xr)
	game.checkpoint=5
	game.place_player(Vector3(11,-29.94,1.85))
	await frames(45)
	var content: Node3D = game.building.content
	var deadline := Time.get_ticks_msec()+15000
	while not content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		OS.delay_msec(5)
		await frames(1)

func finish_room(use_xr: bool) -> void:
	game.queue_free()
	await frames(15)
	root.get_node("TraceData").clear_traces()
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func arrangement(use_xr: bool) -> void:
	await arrive(use_xr)
	var tag := "XR" if use_xr else "Desktop"
	var content: Node3D = game.building.content
	check(tag+": four independent framing props",content.data.floors[5].props.size()==4)
	for item in content.data.floors[5].props:
		var prop: Node3D = content.props["5/"+str(item.id)]
		check(tag+": saved editor pose reaches "+str(item.id),prop.position.is_equal_approx(Vector3(item.position[0],0,item.position[1])) and is_equal_approx(prop.rotation_degrees.y,float(item.facing)))
	for title in ["triangle-work-light","triangle-fold-light"]:
		check(tag+": live light at "+title,content.props["5/"+title].get_node("Prefab/WorkBeam").is_visible_in_tree())
	for stop in content.data.floors[5].route:
		var reached: bool = await move_to(Vector3(float(stop.position[0]),-30,float(stop.position[1])))
		check(tag+": "+str(stop.label),reached)
		if not reached: break
	check(tag+": route completes without damage or a fall",game.deaths==0 and is_equal_approx(game.health.get_health(),100))
	var cubicle: Node3D = content.exhibits["5/drawing"].get_node("Artifact/PythagorasFloor")
	check(tag+": proof entrance stays open",ray(Vector3(0,-28.4,0),Vector3(0,-28.4,-4.8)).is_empty())
	var control: Node3D = cubicle.buttons.swap
	check(tag+": proof controls remain visible",ray(Vector3(-4.4,-28.4,0),control.global_position+Vector3(0,0,.1)).is_empty())
	control.get_node("InteractableAreaButton").button_pressed.emit(null)
	await frames(160)
	var exact: bool = cubicle.swapped
	for i in range(6):
		var proof: Node3D = cubicle.proofs[i]
		exact=exact and not proof.moving and proof.split==(i%2==0) and valid_tiling(proof,proof.a*proof.a+proof.b*proof.b)
	check(tag+": reachable control rearranges six geometrically valid proofs",exact)
	var surfaces: Node3D = content.exhibits["5/surfaces"].get_node("Artifact")
	var fold: Node3D = surfaces.get_node("FoldedStrip")
	var study: Node3D = fold.get_node("FoldStudy")
	# The light must clear the strip throughout its complete hinge cycle.
	var light: Node3D = content.props["5/triangle-fold-light"]
	var light_bounds := AABB(light.global_position+Vector3(-.56,0,-.61),Vector3(1.12,1.96,1.22)).grow(.08)
	var clear := true
	for seconds in range(48):
		study.set_study_time(seconds)
		for point in fold.vertex_positions:
			clear=clear and not light_bounds.has_point(fold.to_global(point))
	check(tag+": work light clears the full animated fold",clear)
	study.restart()
	check(tag+": strip replay remains active",study.is_playing() and fold.num_triangles==24)
	await finish_room(use_xr)

func capture_room() -> void:
	await arrive(false)
	game.place_player(Vector3(12.9,-29.94,7.8))
	await frames(20)
	game._set_enabled(false)
	var fold: Node3D = game.building.content.exhibits["5/surfaces"].get_node("Artifact/FoldedStrip")
	var study: Node3D = fold.get_node("FoldStudy")
	study.set_study_time(12)
	study.playing=false
	for item in [
		["triangle-arrival.png",Vector3(13.5,-28.35,6.5),Vector3(18.1,-27.8,-.5),86],
		["triangle-route.png",Vector3(12.8,-28.35,4.5),Vector3(.7,-28.5,-1.5),80],
		["triangle-proof.png",Vector3(0,-28.35,-.2),Vector3(0,-28.1,-5.8),95],
		["triangle-fold.png",Vector3(-14.3,-28.35,-1.1),Vector3(-16.2,-28.8,-4.6),80],
		["triangle-table.png",Vector3(-2.5,-28.35,7.5),Vector3(1.5,-28.8,3.4),80]
	]:
		await photograph(item[0],item[1],item[2],item[3])
		check("Native Mobile screenshot: "+str(item[0]),FileAccess.file_exists(out.path_join(item[0])))
	await finish_room(false)
