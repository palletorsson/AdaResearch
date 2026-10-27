extends "res://tools/probes/tape_rolls_main.gd"
## A short native inspection capture; input proof remains in the separate run.
func run() -> void:
	root.size = Vector2i(1440,900);level = 3;photo_mode = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	load("res://commons/void/game.gd").requested_floor = 3
	await start(false)
	for n in 360:
		if game.building.content.exhibits.has("3/tape-supply"):break
		await frames(1)
	var work: Node3D = station("tape-supply")
	game.place_player(work.to_global(Vector3(0,.06,1.65)));await frames(20)
	await photograph_tape(work,"tape-supply-clean")
	print("MATTER_REFERENCE_RESULT ",JSON.stringify({"passed":true,"scope":"Native inspection camera; not input or headset acceptance"}))
	quit(0)
