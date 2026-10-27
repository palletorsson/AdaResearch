extends "res://commons/void/trials/postfoundationscrisis_03/probe.gd"
## Review cameras only; acceptance receipts remain the native probe's evidence.
func run() -> void:
	trial="postfoundationscrisis_03"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	take_photos=true
	await start(false)
	level=2
	game.place_player(game.spawn_for(2));await frames(45)
	var cave: Node3D=artifact("rhizome_cave_demo")
	await photo("03-rhizome-passages",cave.to_global(Vector3(22,15,15)),cave.to_global(Vector3(0,2,0)))
	await photo("05-inside-passages",cave.to_global(Vector3(0,1.65,-3)),cave.to_global(Vector3(4,1.65,5)))
	game.queue_free();await frames(5)
	quit()
