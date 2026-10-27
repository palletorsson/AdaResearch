extends "res://commons/void/trials/tiling_04/probe.gd"
func run() -> void:
	trial="tiling_04"
	out="res://commons/void/trials/tiling_04/evidence"
	DirAccess.make_dir_recursive_absolute(out)
	await start(false)
	await frames(120)
	inspect_floor("measure: ")
	FileAccess.open(out.path_join("initial-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify({"bounds":measured,"fit":fit_notes,"failed":failed},"\t"))
	game.queue_free();await frames(10);quit()
