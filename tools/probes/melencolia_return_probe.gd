extends "res://tools/probes/void_melencolia_court_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_melencolia(true)
		var hall: Node3D=game.building.content.exhibits[str(floor_index)+"/hall"].get_node("Artifact")
		game._set_enabled(false)
		await photograph("court-and-tableau.png",Vector3(6,floor_y+3.8,5),Vector3(-5,floor_y+1.6,-1),82)
		await photograph("pyramid-court.png",Vector3(5.8,floor_y+3.4,4),Vector3(0,floor_y+2.3,-2),67)
		await photograph("winged-skull.png",Vector3(-11.8,floor_y+2.1,.6),Vector3(-15.8,floor_y+2.1,-2.3),60)
		await photograph("composition.png",Vector3(4,floor_y+2.7,7),Vector3(4,floor_y+1,4.5),68)
		game._set_enabled(true);game.place_player(Vector3(4,floor_y+.06,6.5));await frames(12)
		for i in 3:
			var body: Node3D=hall.get_node("CompositionSolid%d"%i)
			hand_at(right,body.global_position);await frames(12)
			right.set_input("grip",1.0);await frames(12)
			check("Capture: actual grip of solid %d"%i,body.is_picked_up())
			hand_at(right,Vector3(3.4+i*.65,floor_y+1.2+i*.45,4.7));await frames(15)
			right.set_input("grip",0.0);await frames(90)
		await photograph("another-arrangement.png",Vector3(4,floor_y+2.7,7),Vector3(4,floor_y+1.3,4.5),68)
		await photograph("counter-return.png",Vector3(17,floor_y+2.2,3.7),Vector3(17,floor_y+1.5,5.8),76)
		await cleanup(true)
	else:
		for mode in [false,true]:
			await exercise_court(mode)
			await exercise_composition(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot desktop and synthetic XR. Real XRTools grip, release and pointer events; no physical headset claim."},"\t"))
	quit(0 if failed.is_empty() else 1)

func press_restore(study: Node3D) -> void:
	var button: Area3D=study.get_node("RestoreButton/InteractableAreaButton")
	XRToolsPointerEvent.pressed(game.camera,button,button.global_position)
	XRToolsPointerEvent.released(game.camera,button,button.global_position)
	await frames(3)

func exercise_composition(use_xr: bool) -> void:
	await arrive_melencolia(use_xr)
	var tag:="XR: " if use_xr else "Desktop: "
	var hall: Node3D=game.building.content.exhibits[str(floor_index)+"/hall"].get_node("Artifact")
	var study: Node3D=hall.get_node("CompositionTable/Study")
	var topology: Script=load("res://commons/void/platonic_study.gd")
	game.place_player(Vector3(4,floor_y+.06,6.5));await frames(15)
	check(tag+"three independent starting poses recorded after editor placement",study.homes.size()==3 and study.changed_count()==0)
	for i in 3:
		var body: Node3D=hall.get_node("CompositionSolid%d"%i)
		var visual: MeshInstance3D=body.get_node("MeshInstance3D")
		var box: AABB=visual.transform*visual.mesh.get_aabb()
		check(tag+"solid %d has a readable 65 cm envelope and unit body scale"%i,is_equal_approx(box.size[box.get_longest_axis_index()],.65) and body.scale.is_equal_approx(Vector3.ONE))
		var collider: CollisionShape3D=body.get_node("CollisionShape3D")
		var collision_box:=AABB(collider.shape.points[0],Vector3.ZERO)
		for p in collider.shape.points: collision_box=collision_box.expand(p)
		check(tag+"solid %d collision matches the visible mesh"%i,box.is_equal_approx(collision_box))
		var counts: Dictionary=topology.topology(visual.mesh)
		check(tag+"solid %d retains original vertex count"%i,counts.vertices.size()==[4,8,6][i] and body.scene_file_path==body.get_meta("void_source"))
		var other: Node3D=hall.get_node("CompositionSolid%d"%((i+1)%3))
		var other_pose:=other.transform
		if use_xr:
			hand_at(right,body.global_position);await frames(12);right.set_input("grip",1.0)
		else: game.body.desktop_pointer._grab_held(body)
		await frames(12)
		check(tag+"solid %d real pickup lights the same body"%i,body.is_picked_up() and body.get_node("CarriedLight").visible)
		var held:=body.global_position
		if use_xr: hand_at(right,held+Vector3(.2,.25,.2))
		else: game.camera.position.x+=.25
		await frames(15)
		check(tag+"solid %d moves independently"%i,body.global_position.distance_to(held)>.1 and other.transform.is_equal_approx(other_pose))
		await press_restore(study)
		check(tag+"restore never pulls solid %d out of the hand"%i,body.is_picked_up())
		if use_xr: right.set_input("grip",0.0)
		else: game.body.desktop_pointer._drop_held();game.camera.position.x-=.25
		await frames(5)
		var dropped:=body.global_transform
		await frames(90)
		check(tag+"solid %d stays where placed and its light settles"%i,not body.is_picked_up() and body.freeze and body.global_transform.is_equal_approx(dropped) and not body.get_node("CarriedLight").visible)
		check(tag+"placement change is reported",study.changed_count()==1)
		await press_restore(study)
		check(tag+"pointer restore returns authored arrangement",study.changed_count()==0 and body.transform.is_equal_approx(study.homes[body]))
	# Test actual saved path, including the one-metre court platform.
	game.place_player(Vector3(11,floor_y+.06,4));await frames(15)
	for stop in game.building.content.data.floors[floor_index].route:
		var raised: bool=stop.label in ["On the court","Between the same bodies","Another viewpoint","Return to the ramp"]
		var reached: bool=await move_to(Vector3(stop.position[0],floor_y+(1 if raised else 0),stop.position[1]),false,600)
		check(tag+"route / "+stop.label,reached)
		if not reached:print("BLOCKED ",game.body.global_position);break
	check(tag+"complete route retains health and checkpoint",game.deaths==0 and game.health.get_health()==100 and game.checkpoint==floor_index)
	var counter: Node3D=game.building.content.exhibits[str(floor_index)+"/museum-primitives_melencolia-26-3"].get_node("Artifact")
	var count_before: String=counter.label.text;await frames(10)
	check(tag+"Point Zero counter returns and advances",counter.label.text!=count_before and counter.get_script().resource_path.ends_with("frame_counter_display.gd"))
	# The table and three bodies remain independently curatable. Copies initialize
	# their own authored homes after the new placement, never the source homes.
	var copy: Node3D=load("res://commons/void/primitive_melencolia.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["CompositionTable","CompositionSolid0","CompositionSolid1","CompositionSolid2"],"parts":{"CompositionSolid1":{"position":[4,1.8,5],"rotation":[0,90,0]}}})
	await frames(6)
	var twin: Node3D=copy.get_node("CompositionTable/Study")
	var cube: Node3D=copy.get_node("CompositionSolid1")
	check(tag+"copy captures the curator's moved and turned cube",twin.homes.size()==3 and twin.homes[cube].origin==Vector3(4,1.8,5))
	cube.position.x+=.5;await press_restore(twin)
	check(tag+"copy reset is independent of source",cube.position==Vector3(4,1.8,5) and study.changed_count()==0)
	copy.queue_free();await frames(5)
	await cleanup(use_xr)
