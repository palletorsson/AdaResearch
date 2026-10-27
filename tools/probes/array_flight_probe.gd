extends "res://tools/probes/array_trial_probe.gd"
var Flight: GDScript

func run() -> void:
	# The provider depends on XRTools autoloads; load after SceneTree startup.
	Flight = load("res://commons/movement/museum_flight_box.gd")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	for use_xr in [false,true]:
		await visit_flight(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Native desktop and synthetic XR flight, actual pickup overlaps and gravity. Physical headset not tested."
	},"\t"))
	print("ARRAY_FLIGHT_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func flight_input(direction: Vector3, strength := 1.0) -> void:
	if direction.length()<.001:
		axes(Vector2.ZERO)
		return
	var up := Vector3.RIGHT if absf(direction.normalized().dot(Vector3.UP))>.98 else Vector3.UP
	var view := Basis.looking_at(direction,up)
	if xr:
		var origin: Node3D=game.get_node("XROrigin3D")
		left.set_pose("aim",Transform3D(origin.global_basis.inverse()*view,origin.to_local(game.body.global_position+Vector3(-.3,1.2,-.4))),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		left.set_input("primary",Vector2(0,strength))
	else:
		game.camera.global_basis=view
		game.body.drive=Vector2(0,-strength)

func fly_to(target: Vector3, limit := 240) -> bool:
	for i in limit:
		var offset: Vector3=target-game.body.global_position
		if offset.length()<.075:
			flight_input(Vector3.ZERO)
			await frames(3)
			return true
		flight_input(offset,clampf(offset.length()*3.0,.25,1.0))
		await frames(1)
		if game.recovering: break
	flight_input(Vector3.ZERO)
	print("FLIGHT MISSED ",target," ACTUAL ",game.body.global_position," recovering ",game.recovering)
	return false

func visit_flight(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	var content: Node3D=game.building.content
	var original: Node3D=content.exhibits["1/shaft-volume"].get_node("Artifact")
	var volume: Node3D=original.get_node("FlightArray")
	var museum_score: int=root.get_node("GameManager").player_score
	check(tag+"216 collectible addresses in six by six by six",volume.cells.size()==216 and volume.cubes.size()==216 and volume.values.size()==6 and volume.values[5].size()==6 and volume.values[5][5].size()==6)
	check(tag+"same flight base as the noise glass cube",volume.get_script().get_base_script().resource_path=="res://commons/movement/museum_flight_box.gd")
	check(tag+"no solid platforms or glass collisions obstruct flight",volume.find_children("*","StaticBody3D",true,false).is_empty())
	check(tag+"all cubes use the original pickup and trial scoring",volume.cubes.values().all(func(c):return c.hold=="collect" and c.motion=="still" and c.score_provider==game.trial_session))
	if xr:
		check(tag+"noise flight adapter installed once",game.body._movement_providers.filter(func(p):return p.name=="MuseumFlightAdapter").size()==1)
	var h: float=volume.edge_length/2
	var centre := Vector3(0,h,0)
	var boundaries := true
	for axis in 3:
		for sign_ in [-1,1]:
			var inside := centre
			var outside := centre
			inside[axis]+=sign_*(h-.01)
			outside[axis]+=sign_*(h+.04)
			boundaries=boundaries and volume.contains_point(volume.to_global(inside)) and not volume.contains_point(volume.to_global(outside))
	check(tag+"all six faces end flight at the box boundary",boundaries)
	if not xr:
		await photo("flight-box",Vector3(-13.7,-2.7,1.2),Vector3(-9.7,-8,-.2))
	# One relocation above the shaft. Entry, flight and collection below use input.
	game.place_player(volume.to_global(Vector3(0,volume.edge_length+1.7,0)))
	await frames(12)
	check(tag+"entry starts as a real fall above the box",game.body.velocity.y<-.5 and Flight.at_point(root.get_tree(),game.body.global_position)==null)
	await frames(65)
	var hovered: Vector3=game.body.global_position
	await frames(90)
	check(tag+"falling inside automatically hovers without drift",Flight.at_point(root.get_tree(),game.body.global_position)==volume and game.body.global_position.distance_to(hovered)<.02 and game.body.velocity.length()<.03)
	check(tag+"flight does not count as a fatal fall",not game.recovering and game.deaths==0)
	var rising: bool=await fly_to(volume.to_global(Vector3(-2,3.8,-2)))
	var lowered: bool=await fly_to(volume.to_global(Vector3(-2,.2,-2)))
	check(tag+"look or controller direction permits ascent and descent",rising and lowered)
	check(tag+"floor streaming keeps the whole flight lesson alive",game.floor_stream.focus==1 and volume.is_visible_in_tree() and volume.can_process())
	# Sweep every address using the real movement adapter; body overlaps collect.
	# The capsule may collect adjacent heights too, but no index can shift.
	var travelled := true
	for y in range(5,-1,-1):
		for z in 6:
			for step in 6:
				var x: int=step if z%2==0 else 5-step
				var cell := Vector3i(x,y,z)
				var target: Vector3=volume.cell_position(cell)-Vector3(0,.28,0)
				travelled=await fly_to(volume.to_global(target)) and travelled
				if game.recovering: break
			if game.recovering: break
		if game.recovering: break
	await frames(15)
	check(tag+"continuous flight reaches every address",travelled)
	check(tag+"all 216 pickups collected exactly once",volume.collected==216 and volume.cubes.is_empty() and game.trial_session.score==216)
	var zeroes := true
	for x in 6:
		for y in 6:
			for z in 6: zeroes=zeroes and volume.values[x][y][z]==0
	check(tag+"collection empties values without removing addresses",zeroes and volume.cells.size()==216 and volume.labels[Vector3i(5,5,5)].text=="[5,5,5] = 0")
	check(tag+"museum progress is unaffected",root.get_node("GameManager").player_score==museum_score)
	check(tag+"collecting everything keeps flight available",Flight.at_point(root.get_tree(),game.body.global_position)==volume and not game.recovering)
	if not xr:
		await photo("collected-array",Vector3(-10,-7.7,2.3),Vector3(-10,-9.3,-1.5))
	# Exit the side below the slab, away from the timber landing pads.
	await fly_to(volume.to_global(Vector3(h-.25,2,0)))
	flight_input(Vector3.RIGHT)
	for i in 35:
		await frames(1)
		if Flight.at_point(root.get_tree(),game.body.global_position)==null: break
	flight_input(Vector3.ZERO)
	await frames(8)
	check(tag+"leaving the side immediately restores gravity",Flight.at_point(root.get_tree(),game.body.global_position)==null and game.body.velocity.y<-.1)
	# Re-enter by walking back through the same face while falling.
	if xr: hand_at(left,game.body.global_position+Vector3(-.3,1.2,-.4))
	axes(Vector2(-1,0))
	await frames(30)
	axes(Vector2.ZERO)
	await frames(12)
	check(tag+"re-entering restores flight without restoring collected cubes",Flight.at_point(root.get_tree(),game.body.global_position)==volume and game.body.velocity.length()<.03 and volume.collected==216)
	game.die("Retry the flight array")
	await frames(130)
	var rebuilt: Node3D=content.exhibits["1/shaft-volume"].get_node("Artifact/FlightArray")
	check(tag+"retry restores all 216 cubes and clears local score",rebuilt.cubes.size()==216 and rebuilt.collected==0 and game.trial_session.score==0 and not game.recovering)
	check(tag+"retry leaves no stale flight zone",get_nodes_in_group("ada_museum_flight").size()==1 and Flight.at_point(root.get_tree(),game.body.global_position)==null)
	game.queue_free()
	await frames(6)
	check(tag+"unloading removes the flight volume",get_nodes_in_group("ada_museum_flight").is_empty())
	if xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)
