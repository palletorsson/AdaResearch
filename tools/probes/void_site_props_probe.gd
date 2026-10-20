extends "res://tools/probes/void_triangle_probe.gd"
const Dressing := preload("res://commons/void/set_dressing.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	await site_checks(false)
	if not "--capture" in OS.get_cmdline_user_args(): await site_checks(true)
	OS.delay_msec(150)
	await frames(5)
	var filename := "capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Godot Point One, native physics and synthetic XR movement. Screenshots use Mobile renderer; no physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func site_checks(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR" if use_xr else "Desktop"
	game.place_player(Vector3(0,-5.94,7.5))
	await frames(45)
	var content: Node3D = game.building.content
	var lamp: Node3D = content.props["1/point-work-light"]
	var scaffold: Node3D = content.props["1/point-scaffold"]
	var wall: Node3D = content.props["1/point-unfinished-wall"]
	check(tag+": same four original Point One artifacts",content.data.floors[1].artifacts.size()==4 and content.exhibits.has("1/future") and content.exhibits.has("1/absence"))
	check(tag+": warm work light is active in the live hall",lamp.get_node("Prefab/WorkBeam").is_visible_in_tree() and lamp.get_node("Prefab/WorkBeam").light_energy>0)
	var surfaces := 0
	for prop in [lamp,scaffold,wall]:
		for mesh in prop.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh!=null: surfaces+=mesh.mesh.get_surface_count()
	check(tag+": three detailed props use at most sixteen mesh surfaces",surfaces<=16)
	var tarp: MeshInstance3D = scaffold.get_node("Prefab/Tarp")
	check(tag+": real subdivided cloth uses bounded slow wind",tarp.mesh.surface_get_array_len(0)>1000 and tarp.material_override.get_shader_parameter("wind_amplitude")<=.05 and tarp.material_override.get_shader_parameter("wind_speed")<.5)
	var open_ray := ray(scaffold.to_global(Vector3(0,1.2,1.4)),scaffold.to_global(Vector3(0,1.2,0)))
	check(tag+": scaffold front has no invisible bounding-box collision",open_ray.is_empty())
	var back_ray := ray(scaffold.to_global(Vector3(0,1.2,0)),scaffold.to_global(Vector3(0,1.2,-.8)))
	check(tag+": tarp rear has physical backing",not back_ray.is_empty() and scaffold.is_ancestor_of(back_ray.collider))
	var stud_gap := ray(wall.to_global(Vector3(.88,1.9,1)),wall.to_global(Vector3(.88,1.9,-.2)))
	check(tag+": unfinished stud opening stays open",stud_gap.is_empty())
	var panel := ray(wall.to_global(Vector3(-1,1.9,1)),wall.to_global(Vector3(-1,1.9,-.2)))
	check(tag+": plasterboard has actual collision",not panel.is_empty() and wall.is_ancestor_of(panel.collider))
	# Traverse the real floor: arrival, each podium, around the future sphere, exit.
	var stops := [Vector3(0,-6,4.5),Vector3(-3,-6,3.6),Vector3(0,-6,3.6),Vector3(3,-6,3.6),Vector3(1.7,-6,.5),Vector3(1.7,-6,-3.2),Vector3(0,-6,-2.8),Vector3(-1.8,-6,-3.2),Vector3(-1.8,-6,-6.2),Vector3(0,-6,-7.7)]
	var route_ok := true
	for stop in stops:
		if not await move_to(stop):
			route_ok=false
			break
	check(tag+": arrival, all podiums, future sphere and exit remain walkable",route_ok and game.deaths==0)
	# A copied/rotated catalog prop uses the same factory as saved editor records.
	var copy: Node3D = Dressing.build(game.building,content.roots[1],{"id":"probe-copy","kind":"scaffold_tarp","position":[17,5],"facing":270,"scale":1},content.catalog.props.scaffold_tarp)
	await frames(5)
	check(tag+": a catalog copy has independent geometry and rotated placement",copy.get_node("Prefab/Tarp")!=tarp and copy.position.is_equal_approx(Vector3(17,0,5)) and is_equal_approx(copy.rotation_degrees.y,270))
	check(tag+": copied scaffold retains open-front collision",ray(copy.to_global(Vector3(0,1.2,1.2)),copy.to_global(Vector3(0,1.2,0))).is_empty())
	copy.queue_free()
	if "--capture" in OS.get_cmdline_user_args():
		game._set_enabled(false)
		await photograph("point-one-arrival.png",Vector3(0,-4.35,6.8),Vector3(0,-4.6,-1.7),78)
		await photograph("point-one-work-light.png",Vector3(-1.0,-4.35,5.0),Vector3(-3.9,-4.9,4.1),66)
		await photograph("point-one-working-edge.png",Vector3(2.2,-4.35,-.7),Vector3(-2.4,-4.1,-4.8),75)
		await photograph("point-one-unfinished-wall.png",Vector3(1.3,-4.35,-3.0),Vector3(2.8,-4.5,-6.0),76)
	var lamp_id := lamp.get_instance_id()
	game.place_player(game.spawn_for(2)); await frames(20)
	check(tag+": leaving the hall hides the lamp with its floor",not lamp.get_node("Prefab/WorkBeam").is_visible_in_tree())
	game.place_player(Vector3(0,-5.94,7.5)); await frames(20)
	check(tag+": returning restores the same props and light",lamp.get_instance_id()==lamp_id and lamp.get_node("Prefab/WorkBeam").is_visible_in_tree())
	game.queue_free(); await frames(15)
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)
