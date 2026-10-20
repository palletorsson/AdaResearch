extends "res://tools/probes/portal_span_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_portals(false)
		game.place_player(Vector3(26,floor_y+1.06,.5));await frames(90)
		game._set_enabled(false)
		await photograph("first-skull.png",Vector3(27,floor_y+2.25,1.3),Vector3(28.8,floor_y+1.7,0),65)
		await frames(840)
		await photograph("strange-arrivals.png",Vector3(25.5,floor_y+2.65,2.4),Vector3(28.4,floor_y+1.8,0),75)
		await photograph("end-of-the-walk.png",Vector3(21,floor_y+2.7,1),Vector3(30,floor_y+2,0),72)
		await cleanup(false)
	else:
		await exercise_arrivals(false)
		await exercise_arrivals(true)
		if "--span" in OS.get_cmdline_user_args():
			await exercise_span(false)
			await exercise_span(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Godot desktop and synthetic XR; physical headset untested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func exercise_arrivals(use_xr: bool) -> void:
	await arrive_portals(use_xr)
	var tag:="XR: " if use_xr else "Desktop: "
	var span: Node3D=game.building.content.exhibits[str(floor_index)+"/sky-walk"].get_node("Artifact")
	var source: Node3D=span.get_node("StrangeArrivals")
	check(tag+"no release while visitor is at entry ramp",source.ready_to_emit and source.emitted==0)
	check(tag+"skull baked once; all three templates have geometry",source.templates.size()==3 and source.templates.all(func(t):return not t.is_empty()))
	check(tag+"arrival part has editor label and usable bounds",span.part_defaults.StrangeArrivals.label.contains("skull") and span.part_defaults.StrangeArrivals.bounds[3]>.2)
	game.place_player(Vector3(26,floor_y+1.06,.5));await frames(90)
	check(tag+"approach releases one real skull",source.emitted==1 and source.arrivals[0].get_meta("arrival_kind")=="skull")
	var skull: RigidBody3D=source.arrivals[0]
	check(tag+"skull falls and lands on the bridge",skull.position.y<.55 and skull.global_position.y>floor_y+1 and skull.linear_velocity.length()<.3)
	check(tag+"released skull is baked geometry",skull.find_children("*","CSGShape3D",true,false).is_empty())
	if use_xr:
		hand_at(right,skull.global_position);await frames(15)
		right.set_input("grip",1.0);await frames(15)
		check(tag+"controller grip picks up skull",game.pickups[1].picked_up_object==skull)
	else:
		game.body.desktop_pointer._grab_held(skull);await frames(10)
		check(tag+"desktop pointer picks up skull",skull.held())
	source._prune(150)
	check(tag+"held skull survives reclamation",is_instance_valid(skull) and source.arrivals.has(skull))
	if use_xr:
		hand_at(right,Vector3(27,floor_y+2.4,.4));await frames(10)
		right.set_input("grip",0.0);await frames(90)
	else:
		game.body.desktop_pointer._drop_held();await frames(90)
	check(tag+"release restores gravity",not skull.freeze and not skull.held())
	await frames(900)
	var kinds: Array=source.arrivals.map(func(b):return b.get_meta("arrival_kind"))
	check(tag+"slow sequence continues to cube and ring",source.emitted>=3 and kinds.has("open_cube") and kinds.has("ring"))
	# Shorten only the wait; exercise the production cap and reclamation.
	for i in 10:source.release_next()
	check(tag+"live arrivals capped at six",source.arrivals.size()==6 and source.release_next()==null)
	var fallen: RigidBody3D=source.arrivals.back()
	fallen.global_position=source.global_position+Vector3(0,-11,0)
	source._prune(0);await frames(1)
	check(tag+"lost object reclaimed and replacement permitted",not is_instance_valid(fallen) and source.arrivals.size()==5 and source.release_next()!=null)
	var before: int=source.emitted
	game.place_player(Vector3(-18.5,floor_y+.06,4.4));await frames(480)
	check(tag+"emission pauses when leaving",source.emitted==before)
	check(tag+"arrival encounter leaves visitor healthy",game.deaths==0 and is_equal_approx(game.health.get_health(),100))
	# The editor creates the same source, isolates this part, then moves/rotates it.
	var copy: Node3D=load("res://commons/void/portal_span.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["StrangeArrivals"],"parts":{"StrangeArrivals":{"position":[0,3,0],"rotation":[0,90,0]}}})
	await frames(10)
	var emitter: Node3D=copy.get_node("StrangeArrivals")
	var body: RigidBody3D=emitter.release_next()
	check(tag+"editor copy keeps working after move and turn",copy.get_child_count()==1 and body!=null and body.global_position.distance_to(emitter.to_global(Vector3(.12,1.45,0)))<.02 and body.linear_velocity.z>.6)
	var identity: int=body.get_instance_id()
	copy.free();await frames(2)
	check(tag+"removing emitter frees its released objects",not is_instance_id_valid(identity))
	await cleanup(use_xr)
