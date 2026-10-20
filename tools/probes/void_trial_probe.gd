extends "res://tools/probes/void_game_probe.gd"
const Source = preload("res://commons/void/room_source.gd")
var take_photos := false

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0,1.65,0))
		left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-.3,1.2,-.4))
		right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO); right.set_input("primary",Vector2.ZERO)
	var scene: PackedScene = load("res://commons/void/trials/transformation/trial.tscn")
	var staged: Node3D = scene.instantiate()
	check("trial satisfies staging scene type", is_instance_of(staged, load("res://addons/godot-xr-tools/staging/scene_base.gd")))
	game = staged
	game.force_xr = xr
	root.add_child(game); current_scene = game
	if not xr: game.body.scripted_input=true
	await frames(45)
	game.scene_loaded(); game.scene_visible()
	await frames(30)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("probe uses isolated save data", OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	check("normal tower keeps fourteen floors", Source.read_rooms().floors.size()==14)
	var museum_score: int = root.get_node("GameManager").player_score
	for use_xr in [false,true]:
		await start(use_xr)
		var tag := "XR" if use_xr else "desktop"
		var content: Node3D=game.building.content
		check(tag+" starts on isolated middle floor",game.checkpoint==1 and game.building.spec.levels.size()>=3)
		check(tag+" keeps floor and shafts",game.building.spec.width==42 and game.building.spec.shafts.size()==2)
		check(tag+" carries the thirteen original placements plus a deck",content.data.floors[1].artifacts.size()==14 and content.exhibits.keys().filter(func(key): return str(key).begins_with("1/")).size()==14)
		var still: Node3D=content.exhibits["1/still"].get_node("Artifact")
		var rise: Node3D=content.exhibits["1/rise"].get_node("Artifact")
		var turn: Node3D=content.exhibits["1/turn"].get_node("Artifact")
		var swell: Node3D=content.exhibits["1/swell"].get_node("Artifact")
		check(tag+" original pickup scene",still.get_script().resource_path=="res://commons/scenes/mapobjects/pick_up_cube.gd")
		check(tag+" lerp and demo modes survive import",rise.hold=="demo" and rise.motion=="slide" and rise.motion_curve=="lerp" and swell.motion=="all")
		var fixed: Transform3D=still.transform
		var old_y: float=rise.global_position.y
		var old_turn: Basis=turn.basis
		var skin: MeshInstance3D=swell.find_child("CubeBaseMesh",true,false)
		var old_scale: Vector3=skin.scale
		await frames(25)
		check(tag+" still stays still",still.transform.is_equal_approx(fixed))
		check(tag+" rise moves around placed height",absf(rise.global_position.y-old_y)>.01 and absf(rise.global_position.y+5)<.25)
		check(tag+" turn rotates",not turn.basis.is_equal_approx(old_turn))
		check(tag+" scale changes the original mesh",not skin.scale.is_equal_approx(old_scale))
		rise.collect();await frames(12)
		check(tag+" demonstration cannot be collected",is_instance_valid(rise) and not rise.has_been_collected)
		game.place_player(Vector3(-5,-5.94,-2));await frames(30)
		check(tag+" real body overlap collects once",game.trial_session.score==1 and not is_instance_valid(still))
		game._content_changed(1)
		check(tag+" pickup does not change museum score",root.get_node("GameManager").player_score==museum_score)
		game.place_player(Vector3(16,-5.94,8));await frames(15)
		var reached: bool=await move_to(Vector3(16,-5,3))
		check(tag+" walk onto the construction deck",reached and game.body.global_position.y>-5.6)
		check(tag+" deck cube uses the same collection",game.trial_session.score>=2)
		game.health.set_health(50)
		var cross: Node3D=content.exhibits["1/health-2"].get_node("Artifact")
		check(tag+" health cross uses Void health",cross.health_provider==game.health)
		game.place_player(Vector3(18.4,-5.94,4.5));await frames(30)
		check(tag+" walking over cross heals",game.health.get_health()>50)
		game.place_player(game.spawn_for(2));await frames(15)
		game.place_player(game.spawn_for(1));await frames(15)
		check(tag+" leave and return preserves collected state",not content.exhibits["1/still"].has_node("Artifact"))
		game.die("Retry trial");await frames(100)
		check(tag+" retry restores encounter and score",game.checkpoint==1 and game.trial_session.score==0 and content.exhibits["1/still"].has_node("Artifact") and not game.recovering)
		check(tag+" reset retains bounded artifact count",content.exhibits.keys().filter(func(key): return str(key).begins_with("1/")).size()==14)
		if take_photos and not xr:
			await photograph("comparison",Vector3(0,-3.9,6.2),Vector3(0,-4.8,-2))
			await photograph("raised-route",Vector3(19.5,-3.8,7.5),Vector3(16,-4.8,-.3))
		game.queue_free();await frames(5)
		if xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	check("trial selection does not leak into the tower",Source.read_rooms().floors.size()==14)
	FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed,"physical_headset":"not tested"},"\t"))
	print("VOID_TRIAL_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func photograph(filename: String, at: Vector3, target: Vector3) -> void:
	var photo := Camera3D.new()
	game.add_child(photo)
	photo.environment=game.atmosphere.environment
	photo.global_position=at;photo.look_at(target);photo.make_current()
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename+".png"))
	photo.queue_free();game.camera.make_current()

