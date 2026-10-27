extends "res://commons/void/trials/forces_04/probe.gd"
func run() -> void:
	trial="forces_04";out="res://commons/void/trials/forces_04/evidence"
	await start(false)
	for f in range(1,2):
		level=f;game.place_player(game.spawn_for(f));await frames(80)
		inspect_floor("measure: ")
	FileAccess.open(out.path_join("initial-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify({"bounds":measured,"fit":fit_notes,"failed":failed},"\t"))
	game.queue_free();await frames(10);quit()
