extends "res://tools/probes/void_trace_site_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	await light_trial()
	await replay_contract()
	await desktop_trial()
	OS.delay_msec(200)
	await frames(10)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real tower, Mobile renderer, XRTools and synthetic tracked controllers; no physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func light_trial() -> void:
	await arrive(true)
	game.atmosphere.animate_sky = false
	game.atmosphere.set_sky_time(180)
	var content: Node3D = game.building.content
	var record: Node3D = content.exhibits["4/record"].get_node("Artifact")
	var grid: Node3D = record.get_node("GridReplay/SavedTraceGrid")
	var archive: Node = root.get_node("TraceData")
	check("No trace or light is invented on arrival",archive.saved_traces.is_empty() and record.get_node("Bead10mm/TraceIllumination").tubes.multimesh.visible_instance_count == 0 and active_lights() == 0)
	for item in content.data.floors[4].props:
		if item.kind == "work_light":
			var lamp: Node3D = content.props["4/"+str(item.id)].get_node("Prefab")
			check("Reduced work light: " + str(item.id),is_equal_approx(lamp.beam_energy,1.2))
	check("Other floors retain the catalog work-light setting",is_equal_approx(content.catalog.props.work_light.settings.beam_energy,7.5))
	var eye := Vector3(2.3,-21.9,5.0)
	var target := Vector3(-2.0,-22.65,1.3)
	await photograph("before-drawing.png",eye,target)
	for item in ["Bead10mm","Bead40mm","Bead80mm"]:
		var bead: Node3D = record.get_node(NodePath(item))
		var point: RigidBody3D = bead.get_node("GrabPoint")
		var view: Node3D = bead.get_node("TraceIllumination")
		check(str(item)+": original drawing recorder retained",bead.get_script().resource_path=="res://commons/primitives/point/draw_dot.gd")
		game.place_player(Vector3(point.global_position.x,-23.94,point.global_position.z+1.5))
		await frames(15)
		hand_at(right,point.global_position);await frames(12)
		right.set_input("grip",1.0);await frames(15)
		check(str(item)+": real XR grip takes the existing bead",game.pickups[1].picked_up_object==point)
		var begin := point.global_position
		for i in range(80):
			var t := float(i) / 79.0 * TAU
			hand_at(right,begin+Vector3(sin(t)*.72,.46+cos(t)*.38,.32+sin(t*2)*.2))
			await frames(2)
		await frames(6)
		check(str(item)+": visible cylinders follow recorded segments",view.tubes.multimesh.visible_instance_count==bead._trail_points.size()-1 and view.starts[0]==bead._trail_points[0] and view.ends[-1]==bead._trail_points[-1])
		check(str(item)+": mesh has emission and two bounded real lights",view.tubes.multimesh.mesh.material.emission_enabled and view.lamps.size()==2 and view.lamps[0].visible and view.lamps[1].visible and not view.lamps[0].shadow_enabled)
		right.set_input("grip",0.0);await frames(25)
		check(str(item)+": release keeps the light and exact source for Grid",view.lamps[0].visible and archive.saved_traces[-1]==bead._trail_points and grid._trace_data_list[-1].raw_points==bead._trail_points)
	check("Three drawings share a six-light ceiling",active_lights()==6)
	await photograph("trace-lit.png",eye,target)
	set_trace_lights(false)
	await photograph("trace-light-off.png",eye,target)
	set_trace_lights(true)
	await photograph("trace-close.png",Vector3(-.4,-22.25,3.5),Vector3(-2,-22.55,1.4))
	await photograph("grid-shaft.png",Vector3(-5.5,-22.35,4.1),Vector3(-9.8,-24.2,0))
	check("Grid stays at the authored shaft location",grid.global_position.is_equal_approx(Vector3(-10,-25,0)))
	check("Grid controls and lattice remain visible from the solid rim",ray(Vector3(-6,-22.35,1.8),grid.get_node("ArchivePanel").global_position+Vector3(.1,0,0)).is_empty() and ray(Vector3(-6,-22.35,1.8),grid.global_position+Vector3(0,.5,0)).is_empty())
	check("The shaft remains open below the lattice",ray(Vector3(-10,-24.2,0),Vector3(-10,-31,0)).is_empty())
	var bead: Node3D = record.get_node("Bead10mm")
	var view: Node3D = bead.get_node("TraceIllumination")
	var kept: Array = archive.saved_traces[0].duplicate()
	bead.clear_trail();await frames(8)
	check("Clearing a live drawing removes its mesh and light",view.tubes.multimesh.visible_instance_count==0 and not view.lamps[0].visible and not view.lamps[1].visible)
	check("Clearing the live view does not erase the released Grid record",archive.saved_traces[0]==kept and grid._trace_data_list[0].raw_points==kept)
	var copy: Node3D = load("res://commons/void/trace_record.tscn").instantiate()
	copy.position = Vector3(4,-24,4)
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["Bead10mm"],"parts":{"Bead10mm":{"position":[0,1.15,0],"rotation":[0,90,0]}}})
	await frames(8)
	var copied: Node3D = copy.get_node("Bead10mm/TraceIllumination")
	check("Editor copy has independent mesh and lights with no invented drawing",copy.get_child_count()==1 and copied.lamps[0]!=view.lamps[0] and copied.tubes.multimesh!=view.tubes.multimesh and copied.tubes.multimesh.visible_instance_count==0)
	check("World-space recording survives editor rotation",copied.is_set_as_top_level() and copied.global_transform.is_equal_approx(Transform3D.IDENTITY))
	copy.queue_free();await frames(8)
	await shadow_trial(record)
	game.place_player(game.spawn_for(0));await frames(20)
	check("Sleeping floor disables every trace light",active_lights()==0 and not record.can_process())
	game.place_player(game.spawn_for(4));await frames(25)
	check("Returning restores retained trace lighting",active_lights()==6 and archive.saved_traces[0]==kept)
	game.die("Trace light retry");await wait_for_recovery(0)
	check("Retry retains the drawing, light and archive",active_lights()==6 and archive.saved_traces[0]==kept and game.checkpoint==4)
	await finish_room(true)

func shadow_trial(record: Node3D) -> void:
	var drawing: Node3D = record.get_node("ShadowPoint")
	var point: RigidBody3D = drawing.point
	var light: Node3D = drawing.get_node("TraceIllumination")
	game.place_player(Vector3(17,-23.94,3));await frames(15)
	hand_at(left,point.global_position);await frames(12)
	left.set_input("grip",1.0);await frames(15)
	check("Black point still uses real left-hand pickup",game.pickups[0].picked_up_object==point)
	var begin := point.global_position
	for i in range(50):
		var t := float(i)/49.0 * TAU
		hand_at(left,begin+Vector3(sin(t)*.65,.5+cos(t)*.4,.3+sin(t*2)*.3));await frames(3)
	left.set_input("grip",0.0);await frames(20)
	check("Black point's retained mesh supplies light",light.tubes.multimesh.visible_instance_count==drawing.ink.get_child_count() and light.lamps[0].visible)
	await photograph("black-point-trace.png",Vector3(16,-22.1,5.6),Vector3(18.5,-22.4,3.3))
	var count: int = light.tubes.multimesh.visible_instance_count
	hand_at(left,point.global_position);await frames(10)
	left.set_input("grip",1.0);await frames(15)
	check("New pickup does not light a bridge between separate strokes",light.tubes.multimesh.visible_instance_count==count)
	left.set_input("grip",0.0);await frames(10)

func desktop_trial() -> void:
	await arrive(false)
	var record: Node3D = game.building.content.exhibits["4/record"].get_node("Artifact")
	var drawing: Node3D = record.get_node("ShadowPoint")
	drawing.point.on_desktop_grab(null);await frames(8)
	drawing.point.position += Vector3(0,.4,0);await frames(8)
	drawing.point.on_desktop_drop(null);await frames(10)
	check("Desktop drawing creates the same illuminated trace",drawing.get_node("TraceIllumination").lamps[0].visible and root.get_node("TraceData").saved_traces.size()==1)
	game.place_player(Vector3(11,-23.94,4));await frames(15)
	var route_ok := true
	for stop in game.building.content.data.floors[4].route:
		if not await move_to(Vector3(stop.position[0],-24,stop.position[1])):
			route_ok=false;print("[void] route blocked: ",stop.label);break
	check("Authored drawing-to-Grid route stays walkable",route_ok and game.deaths==0)
	await finish_room(false)

func active_lights() -> int:
	var count := 0
	for view in get_nodes_in_group("void_trace_light"):
		for lamp in view.lamps:
			if lamp.is_visible_in_tree(): count += 1
	return count

func set_trace_lights(enabled: bool) -> void:
	for view in get_nodes_in_group("void_trace_light"):
		for lamp in view.lamps:
			if not enabled: lamp.set_meta("capture_visibility", lamp.visible)
			lamp.visible = bool(lamp.get_meta("capture_visibility", false)) if enabled else false

func photograph(filename: String, at: Vector3, target: Vector3) -> void:
	if DisplayServer.get_name()=="headless": return
	var origin := game.get_node_or_null("XROrigin3D") as Node3D
	if origin != null: origin.hide()
	await super.photograph(filename,at,target)
	if origin != null: origin.show()
