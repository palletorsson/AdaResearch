extends "res://tools/probes/translation_sequence_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	if "--capture" in OS.get_cmdline_user_args():
		await photos(); quit(); return
	for mode in [false,true]: await visit(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Production desktop and synthetic XR; physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func visit(mode: bool) -> void:
	await start(mode)
	var tag := "XR: " if mode else "Desktop: "
	game.checkpoint=2
	game.place_player(Vector3(-11.7,-11.94,1.9)); await frames(140)
	check(tag+"arrival from Introduction is safe", game.checkpoint==3 and game.health.get_health()==100 and game.deaths==0)
	encounter=game.building.content.exhibits["3/crossing"].get_node("Artifact")
	var room: Dictionary=game.building.content.data.floors[3]
	check(tag+"only one assembly and no extra structures",room.artifacts.size()==1 and room.walls.is_empty() and room.props.is_empty() and not room.has("basin"))
	check(tag+"four original cubes, four wp wedges and one moving assembly",encounter.recipe.members.size()==8 and encounter.get_child_count()==9 and encounter.part_defaults.size()==9)
	for member in encounter.recipe.members:
		var piece: Node3D=encounter.get_node(member.id)
		check(tag+member.id+" keeps Animated Cube source",piece.scene_file_path==("res://commons/artifacts/primitive_encounters/platform_block.tscn" if member.kind=="cube" else "res://commons/artifacts/primitive_encounters/wedge_blocker.tscn"))
	var carrier: Node3D=encounter.get_node("SuspendedPlatform")
	var platform: Node3D=carrier.platform
	check(tag+"deck is a thin solid two-metre platform",platform._support_shape.shape.size.is_equal_approx(Vector3(2,.16,2)))
	check(tag+"suspension reaches the ceiling",is_equal_approx(carrier.ceiling_y,Y+5.64))
	check(tag+"no pipes on the lesson floor",game.building.floor_details[3].find_children("*Riser*","",true,false).is_empty())
	if mode:
		head.set_pose("default",Transform3D(Basis.IDENTITY,Vector3(.22,1.65,.14)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(6)
	for waypoint in [[-13.25,0,1.9],[-13.25,0,8],[-10,0,8.2],[-10,1,5.5]]:
		if not await walk(waypoint,tag): await finish(mode); return
	check(tag+"platform returns to the near bank",await dock(platform,false))
	if not await walk([-10,1,4],tag): await finish(mode); return
	check(tag+"real walking contact attaches rider",platform.carried_player==game.body)
	var b0: Vector3=game.body.global_position
	var e0: Vector3=game.camera.global_position
	var p0: Vector3=platform.global_position
	check(tag+"crosses the open shaft",await dock(platform,true))
	var delta: Vector3=platform.global_position-p0
	check(tag+"body and view travel once with the deck",(game.body.global_position-b0-delta).length()<.09 and (game.camera.global_position-e0-delta).length()<.09)
	check(tag+"translation keeps orientation",platform.global_basis.is_equal_approx(Basis.IDENTITY))
	for i in range(4):
		var top: Vector3=carrier.trolleys[i].global_position
		var bottom: Vector3=platform.to_global(carrier.CORNERS[i]+Vector3.UP*.5)
		check(tag+"hanger %d stays over its moving corner"%i,absf(top.x-bottom.x)<.001 and absf(top.z-bottom.z)<.001 and absf(top.y-carrier.ceiling_y)<.001)
	for waypoint in [[-10,1,-5.5],[-10,0,-8.2]]:
		if not await walk(waypoint,tag): await finish(mode); return
	check(tag+"walk off onto the original wedge releases rider",not is_instance_valid(platform.carried_player) and game.health.get_health()==100 and game.deaths==0)
	# The old central excavation has been removed: the ordinary slab supports us.
	game.place_player(Vector3(0,Y+.06,0)); await frames(25)
	check(tag+"central floor restored",game.body.is_on_floor() and absf(game.body.global_position.y-Y)<.1 and game.health.get_health()==100)
	# From the raised route, a missed deck drops more than one floor.
	var deaths: int=game.deaths
	game.place_player(Vector3(-8,Y+1.06,0)); await frames(100)
	check(tag+"missing the platform is a fatal shaft fall",game.deaths==deaths+1)
	await wait_for_recovery(deaths)
	check(tag+"restart returns to Translation",game.checkpoint==3 and game.health.get_health()==100 and not game.recovering)
	encounter=game.building.content.exhibits["3/crossing"].get_node("Artifact")
	check(tag+"restart restores exactly nine pieces",encounter.get_child_count()==9)
	await edited_copy(tag)
	await finish(mode)

func edited_copy(tag: String) -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-19-translation-single-crossing/editor-copy-SuspendedPlatform.json"))
	var host: Node3D=game.building.content.roots[3]
	var mount:=Node3D.new(); host.add_child(mount)
	mount.position=Vector3(data.position[0],data.height,data.position[1]); mount.rotation_degrees.y=data.facing
	var copy: Node3D=load("res://commons/void/trials/transformation/translation_crossing.tscn").instantiate()
	mount.add_child(copy); copy.apply_grid_config(data.config)
	var carrier: Node3D=copy.get_node("SuspendedPlatform")
	var platform: Node3D=carrier.platform
	check(tag+"editor copy retains only the selected platform",copy.get_child_count()==1)
	check(tag+"copy moves and rotates the whole journey",platform.initial_position.is_equal_approx(Vector3(4,Y+1.5,5)) and platform.target_position.is_equal_approx(Vector3(-4,Y+1.5,5)))
	check(tag+"raising the deck keeps tracks at the ceiling",is_equal_approx(carrier.ceiling_y,Y+5.64))
	game.place_player(Vector3(4,Y+2.06,5)); await frames(18)
	check(tag+"edited deck accepts the same player",platform.carried_player==game.body)
	var b0: Vector3=game.body.global_position; var p0: Vector3=platform.global_position
	check(tag+"edited route completes",await dock(platform,true))
	check(tag+"edited deck carries the player",(game.body.global_position-b0-(platform.global_position-p0)).length()<.09)
	game.place_player(game.spawn_for(3)); mount.queue_free(); await frames(15)

func photos() -> void:
	await start(true)
	game.place_player(game.spawn_for(3)); await frames(35)
	game.atmosphere.animate_sky=false; game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	game.get_node("XROrigin3D").hide(); game.status.hide(); game.notice_time=-1
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	encounter=game.building.content.exhibits["3/crossing"].get_node("Artifact")
	var carrier: Node3D=encounter.get_node("SuspendedPlatform")
	carrier.platform.set_physics_process(false)
	carrier.platform.global_position=carrier.to_global(Vector3(0,-.5,-4))
	carrier.platform.static_body.force_update_transform(); carrier._update_suspension()
	await photo("approach",Vector3(-10,Y+1.65,8.3),Vector3(-10,Y+2,0))
	await photo("suspension",Vector3(-14,Y+2.2,4),Vector3(-10,Y+3,-.5))
	await photo("whole-setup",Vector3(-5.8,Y+4.4,7.9),Vector3(-10,Y+1.6,0))
	FileAccess.open(out.path_join("provenance.json"),FileAccess.WRITE).store_string(JSON.stringify({"source":"Actual Godot Mobile renderer, Transformation trial floor 3","pose":"Platform paused halfway for the photos; gameplay checked with the real motion running","headset":"Synthetic trackers for physics tests; no physical headset test"},"\t"))
	await finish(true)

func photo(filename: String,at: Vector3,target: Vector3) -> void:
	var camera:=Camera3D.new(); game.add_child(camera)
	camera.environment=game.atmosphere.environment; camera.fov=78
	camera.global_position=at; camera.look_at(target); camera.make_current()
	await frames(3); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename+".png"))
	camera.queue_free(); game.camera.make_current()
