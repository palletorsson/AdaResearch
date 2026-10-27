extends "res://tools/probes/ca_spine_active.gd"
## A corrected camera from the clear aisle; no additional acceptance claim.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	take_photos = true;await start(false);level = 104
	game.place_player(game.spawn_for(level));await frames(100)
	var study: Node3D = artifact("structure_growth").get_node("StructureStudy")
	study.replay();study.step_once();await frames(8)
	var y: float = game.building.spec.levels[level]
	game.charge_display.hide()
	await photo("ca-104-witness",Vector3(1.2,y+2.8,-1.3),Vector3(0,y+2.72,-5.65))
	print("CA_BASELINE_RESULT corrected native witness camera");quit()
