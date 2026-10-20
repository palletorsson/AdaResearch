extends "res://tools/probes/void_grid_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await capture_room()
	else:
		await arrangement(false)
		await arrangement(true)
		# Existing real-XR drawing -> shaft Grid -> selection/copy/return/retry contract.
		await replay_contract()
	OS.delay_msec(150)
	await frames(10)
	var filename := "capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Point Trace arrangement and editable route; retained drawing reaches the shaft Grid. Desktop and synthetic XR, not a physical headset."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive(use_xr: bool) -> void:
	await start(use_xr)
	game.checkpoint=4
	game.place_player(Vector3(11,-23.94,4))
	await frames(45)
	var content: Node3D = game.building.content
	var deadline := Time.get_ticks_msec()+10000
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
	var record: Node3D = content.exhibits["4/record"].get_node("Artifact")
	var glass: Node3D = content.exhibits["4/surface"].get_node("Artifact/GlassWall")
	var grid: Node3D = record.get_node("GridReplay/SavedTraceGrid")
	check(tag+": only three framing props added",content.data.floors[4].props.size()==3)
	for item in content.data.floors[4].props:
		var prop: Node3D = content.props["4/"+str(item.id)]
		check(tag+": shared editor pose reaches "+str(item.id),prop.position.is_equal_approx(Vector3(item.position[0],0,item.position[1])) and is_equal_approx(prop.rotation_degrees.y,float(item.facing)))
	check(tag+": work light is live",content.props["4/trace-work-light"].get_node("Prefab/WorkBeam").is_visible_in_tree())
	check(tag+": original glass with pens remains enabled",glass.pens_enabled and glass.simple_pens and glass.glass_surface)
	check(tag+": Grid stays in shaft A",grid.global_position.is_equal_approx(Vector3(-10,-25,0)))
	var eye := Vector3(-6,-22.35,1.8)
	var panel: Node3D = grid.get_node("ArchivePanel")
	check(tag+": Grid controls visible from the solid rim",ray(eye,panel.global_position+Vector3(.1,0,0)).is_empty())
	check(tag+": clear view from the rim into the lattice",ray(eye,grid.global_position+Vector3(0,.5,0)).is_empty())
	check(tag+": shaft remains open below the Grid",ray(Vector3(-10,-24.2,0),Vector3(-10,-31,0)).is_empty())
	var floor_hit := ray(Vector3(-6,-23.5,1.8),Vector3(-6,-24.2,1.8))
	check(tag+": Grid controls approached on solid floor",not floor_hit.is_empty() and absf(floor_hit.position.y+24)<.04)
	# Follow the current user placements through the same route shown in the editor.
	for stop in content.data.floors[4].route:
		var target := Vector3(float(stop.position[0]),-24,float(stop.position[1]))
		var reached: bool = await move_to(target)
		check(tag+": "+str(stop.label),reached)
		if not reached: break
	check(tag+": route reaches the next descent without damage",game.deaths==0 and is_equal_approx(game.health.get_health(),100))
	if use_xr:
		await draw_bead(record)
	await finish_room(use_xr)

func draw_bead(record: Node3D) -> void:
	var bead: Node3D = record.get_node("Bead10mm")
	var point: RigidBody3D = bead.get_node("GrabPoint")
	var grid: Node3D = record.get_node("GridReplay/SavedTraceGrid")
	var archive: Node = root.get_node("TraceData")
	archive.clear_traces()
	game.place_player(Vector3(point.global_position.x,-23.94,point.global_position.z+1.6))
	await frames(20)
	hand_at(right,point.global_position)
	await frames(15)
	right.set_input("grip",1.0)
	await frames(20)
	check("XR: original drawing bead is picked up",game.pickups[1].picked_up_object==point)
	var begin: Vector3 = point.global_position
	for i in range(24):
		hand_at(right,begin+Vector3(i*.045,sin(i*.24)*.25,.25))
		await frames(2)
	var monitor: Node3D = record.get_node("SamplingMonitor")
	check("XR: monitor follows the same held bead",monitor.sources.size()==3 and monitor.active_source==bead)
	right.set_input("grip",0.0)
	await frames(45)
	check("XR: releasing the bead retains its sampled positions",archive.saved_traces.size()==1 and archive.saved_traces[0]==bead._trail_points and bead._trail_points.size()>12)
	check("XR: shaft Grid receives those exact positions",grid._trace_data_list.size()==1 and grid._trace_data_list[0].raw_points==bead._trail_points)

func capture_room() -> void:
	await arrive(true)
	var record: Node3D = game.building.content.exhibits["4/record"].get_node("Artifact")
	await draw_bead(record)
	# Keep the live floor and its drawing, but move the test avatar out of frame.
	game.place_player(Vector3(18,-23.94,7.5))
	await frames(20)
	game._set_enabled(false)
	for item in [
		["trace-drawing.png",Vector3(1.4,-22.35,-1.2),Vector3(-.8,-22.7,-6.3)],
		["trace-beads.png",Vector3(1.4,-22.35,4.5),Vector3(-2.5,-22.85,1)],
		["trace-grid.png",Vector3(-5.5,-22.35,4.1),Vector3(-9.8,-24.2,0)],
		["trace-glass.png",Vector3(.8,-22.35,-5.1),Vector3(-.5,-22.65,-7.5)],
		["trace-room.png",Vector3(-6,-22.35,3.4),Vector3(-.3,-22.8,-3.7)]
	]:
		await photograph(item[0],item[1],item[2])
		check("Native Mobile screenshot: "+str(item[0]),FileAccess.file_exists(out.path_join(item[0])))
	await finish_room(true)
