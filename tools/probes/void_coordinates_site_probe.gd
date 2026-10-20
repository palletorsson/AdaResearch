extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await arrangement(false)
	if not "--capture" in OS.get_cmdline_user_args():
		await arrangement(true)
		# The original pickup/readout contract also runs against this new arrangement.
		await coordinate_checks()
	OS.delay_msec(150)
	await frames(10)
	var filename := "capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Point Coordinates with native desktop and synthetic XR traversal, original grip/readout/retry contract. Mobile-rendered captures; not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrangement(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR" if use_xr else "Desktop"
	game.checkpoint=2
	game.place_player(Vector3(0,-11.94,-7.5))
	await frames(45)
	var content: Node3D = game.building.content
	var point: Node3D = game.coordinate_point
	var frame: Node3D = content.exhibits["2/frame"].get_node("Artifact")
	check(tag+": one original grabbable point supplies the coordinate frame",frame._find_point()==point and get_nodes_in_group("ada_coordinate_point").size()==1)
	check(tag+": exactly three reusable props frame Coordinates",content.data.floors[2].props.size()==3)
	var scaffold: Node3D = content.props["2/coordinates-scaffold"]
	var wall: Node3D = content.props["2/coordinates-unfinished-wall"]
	var light: Node3D = content.props["2/coordinates-work-light"]
	for item in content.data.floors[2].props:
		var prop: Node3D = content.props["2/"+str(item.id)]
		check(tag+": shared editor pose reaches "+str(item.kind),prop.position.is_equal_approx(Vector3(item.position[0],0,item.position[1])) and is_equal_approx(prop.rotation_degrees.y,float(item.facing)))
	check(tag+": light is live and directed into the clear centre",light.get_node("Prefab/WorkBeam").is_visible_in_tree() and light.rotation_degrees.y==90)
	for xz in [Vector2(-3,-1),Vector2(-3,2),Vector2(0,3),Vector2(2,3)]:
		var lid := ray(Vector3(xz.x,-11.5,xz.y),Vector3(xz.x,-12.15,xz.y))
		check(tag+": solid floor supports the player at "+str(xz),not lid.is_empty() and lid.collider.get_meta("void_floor_index",-1)==2 and is_equal_approx(lid.position.y,-12))
	var sight := ray(Vector3(0,-10.35,-5.8),point.global_position)
	check(tag+": arrival sees the black point without a prop blocking it",sight.is_empty() or sight.collider==point)
	var readouts_clear := true
	for id in ["world","local"]:
		var card: Node3D = content.exhibits["2/"+id].get_node("Artifact")
		var hit := ray(Vector3(0,-10.35,-1.3),card.global_position-Vector3(0,0,.2))
		if not hit.is_empty(): readouts_clear=false
	check(tag+": both wall readouts have a clear sightline from the point",readouts_clear)
	var stops := [Vector3(0,-12,-1.4),Vector3(-1.4,-12,-1.4),Vector3(-1.4,-12,1.5),Vector3(-3,-12,1.5),Vector3(-1.4,-12,1.5),Vector3(1.5,-12,1.5),Vector3(3.1,-12,4.7),Vector3(0,-12,5.3),Vector3(0,-12,7.7)]
	var route_ok := true
	for stop in stops:
		if not await move_to(stop):
			route_ok=false
			break
	check(tag+": entrance, point, basin, readouts and exit are walkable",route_ok and game.deaths==0)
	if "--capture" in OS.get_cmdline_user_args():
		game._set_enabled(false)
		await photograph("coordinates-arrival.png",Vector3(.4,-10.35,-5.9),Vector3(-.4,-10.65,1.8),76)
		await photograph("coordinates-basin.png",Vector3(1.7,-10.35,-1.8),Vector3(-2.7,-11.2,2.3),80)
		await photograph("coordinates-point.png",Vector3(-1.6,-10.35,-2.1),Vector3(.3,-11.0,-.1),74)
		await photograph("coordinates-room.png",Vector3(-1.8,-10.35,5.8),Vector3(.2,-10.8,-1.3),86)
	check(tag+": prefab openings remain physical parts",ray(scaffold.to_global(Vector3(0,1.2,1.1)),scaffold.to_global(Vector3(0,1.2,0))).is_empty() and ray(wall.to_global(Vector3(.88,1.9,1)),wall.to_global(Vector3(.88,1.9,-.2))).is_empty())
	game.queue_free(); await frames(15)
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)
