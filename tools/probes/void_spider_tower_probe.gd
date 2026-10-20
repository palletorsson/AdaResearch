extends "res://tools/probes/void_game_probe.gd"
const Ability := preload("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd")
const Behavior := preload("res://commons/void/spider.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	var capture := "--capture" in OS.get_cmdline_user_args()
	for use_xr in ([false] if capture else [false,true]):
		var ability: Node3D=Ability.new()
		root.add_child(ability);ability.set_unlocked(true)
		await start(use_xr)
		var tag := "XRTools / " if use_xr else "Desktop / "
		game.place_player(Vector3(-5,-41.94,-1.3))
		await frames(45)
		var spider: CharacterBody3D=game.building.content.exhibits["7/catalyst-spider"].get_node("Artifact")
		check(tag+"authored Cube floor mounts the real eight-leg creature",spider.gait.find_children("LegMesh_*","MeshInstance3D",true,false).size()==8 and absf(spider.global_position.y+42)<.1)
		check(tag+"landing and entry are outside the aggression radius",spider.attacks==0 and spider.state==Behavior.State.REST)
		if capture:
			game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
			game.camera.global_position=Vector3(-1.8,-40.25,-1.15)
			game.camera.look_at(spider.global_position+Vector3(0,1.1,0))
			await photo("spider-rest.png")
		if use_xr:
			var center: Vector3=spider.global_position+Vector3(0,1.2,2.4)
			hand_at(left,center+Vector3(-.08,0,0));hand_at(right,center+Vector3(.08,0,0))
			await frames(40)
			check(tag+"existing two-hand catalyst forms",ability.formed)
			right.set_input("trigger_click",true);await frames(1);right.set_input("trigger_click",false)
		else:
			game.camera.look_at(spider.global_position+Vector3.UP*1.1)
			var key := InputEventKey.new()
			key.keycode=KEY_C;key.pressed=true;Input.parse_input_event(key)
			await frames(25)
			check(tag+"existing two-hand catalyst forms",ability.formed)
			var click := InputEventMouseButton.new()
			click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;Input.parse_input_event(click)
			await frames(1)
			click.pressed=false;Input.parse_input_event(click)
			key.pressed=false;Input.parse_input_event(key)
		await frames(65)
		check(tag+"actual player firing path calms the spider",spider.state==Behavior.State.CALM)
		game.health.set_health(60)
		game.place_player(spider.global_position+Vector3(0,.06,1.6))
		await frames(140)
		check(tag+"calmed creature heals actual player health",game.health.get_health()==70 and spider.attacks==0)
		if capture:
			game.camera.global_position=Vector3(-2.5,-40.35,-2.0)
			game.camera.look_at(spider.global_position+Vector3(0,1.15,0))
			await photo("spider-calm.png")
		game.place_player(game.spawn_for(6));await frames(45)
		check(tag+"off-floor streaming pauses the creature",not spider.can_process())
		game.place_player(Vector3(-5,-41.94,-1.3));await frames(35)
		check(tag+"returning retains the same calmed creature",spider.can_process() and spider.state==Behavior.State.CALM and game.building.content.exhibits["7/catalyst-spider"].get_node("Artifact")==spider)
		game.queue_free()
		if is_instance_valid(ability): ability.queue_free()
		await frames(15)
		if use_xr:
			for tracker in [head,left,right]: XRServer.remove_tracker(tracker)
	FileAccess.open(out.path_join("tower-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"scope":"Actual authored floor, desktop catalyst and XRTools two-hand ability with synthetic trackers. No physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func photo(filename: String) -> void:
	game.notice_time=0
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
