extends "res://tools/probes/introduction_sequence_probe.gd"
## Supplement traversal evidence with paired, unobstructed in-tower views.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	take_photos=true
	await start(true)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	game.place_player(game.spawn_for(2));await frames(60)
	var sequence:Node3D=game.building.content.exhibits["2/sequence"].get_node("Artifact")
	var growth:Node3D=sequence.get_node("GrowingCube")
	var turn:Node3D=sequence.get_node("TurningPlank")
	growth.current_scale=.5;growth.pause_timer=60;growth.apply_scale()
	await photo("growth-small",Vector3(3.7,Y+2.65,.6),Vector3(0,Y-.3,0))
	growth.current_scale=3;growth.apply_scale()
	await photo("growth-full",Vector3(3.7,Y+2.65,.6),Vector3(0,Y-.3,0))
	turn.current_angle=0;turn.pause_timer=60;turn.is_rotating=false
	turn.mesh_instance.rotation=Vector3.ZERO;turn.static_body.transform=turn.mesh_instance.transform
	await photo("rotation-aligned",Vector3(-6.8,Y+2.65,.45),Vector3(-10.4,Y+.25,0))
	turn.current_angle=90;turn.mesh_instance.rotation.y=PI/2;turn.static_body.transform=turn.mesh_instance.transform
	await photo("rotation-turned",Vector3(-6.8,Y+2.65,.45),Vector3(-10.4,Y+.25,0))
	check("ferry available for photo",await dock(sequence.get_node("MovingPlatform").platform,false))
	await photo("three-crossings",Vector3(15.6,Y+2.65,.25),Vector3(-5,Y+.5,0))
	await photo("route-overview",Vector3(0,Y+5.3,8.6),Vector3(0,Y-.4,0))
	FileAccess.open(out.path_join("photo-notes.json"),FileAccess.WRITE).store_string(JSON.stringify({"source":"Production Godot Mobile renderer, inside the tower.","poses":"Small/full growth and aligned/quarter-turned plank paused at their real endpoint states for comparison.","traversal":"Recorded separately in checks.json and engine.log."},"\t"))
	game.queue_free();await frames(20)
	for item in [head,left,right]:XRServer.remove_tracker(item)
	quit(0 if failed.is_empty() else 1)

func photograph(filename: String,at: Vector3,target: Vector3) -> void:
	var camera:=Camera3D.new()
	game.add_child(camera)
	camera.environment=game.atmosphere.environment
	camera.fov=110 if filename=="route-overview" else 75
	camera.global_position=at;camera.look_at(target);camera.make_current()
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename+".png"))
	camera.queue_free();game.camera.make_current()
