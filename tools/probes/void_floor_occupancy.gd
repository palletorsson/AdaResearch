extends "res://tools/probes/void_game_probe.gd"
## WHAT YOU CAN STAND ON, MEASURED (2026-11-07). The artifact timeline's walk (tools/artifact_timeline.py) first
## guessed obstacles from registry footprints and put 75 number captions under tables, platforms and 2 cm mats.
## The built tower is the truth: per floor, a ray straight down at the centre of every 0.5 m cell of the slab
## (84 x 36), from 2.4 m to 10 cm under the slab, records the first thing it meets:
##     0..40   a surface that many cm above the slab (0 = the bare slab, 2 = a mat, ...)
##     254     something higher: you cannot stand there
##     255     nothing: a shaft, or off the slab
## Appends one JSON line per floor to --out (so a floor that hangs costs only itself) and prints
## "[occupancy] start N" before each floor. Run through tools/measure_void_occupancy.py.
const NX := 84
const NZ := 36
const STEP := .5
var floors: Array = []
var settle := 90
var out_file := ""

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_file = arg.trim_prefix("--out=")
		if arg.begins_with("--settle="): settle = int(arg.trim_prefix("--settle="))
		if arg.begins_with("--floors="):
			for s in arg.trim_prefix("--floors=").split(","): floors.append(int(s))
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = int(floors[0])
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(120)
	for f in floors:
		print("[occupancy] start %d" % int(f))
		game.place_player(game.spawn_for(int(f))); await frames(settle)
		var line := measure(int(f))
		var file := FileAccess.open(out_file, FileAccess.READ_WRITE) if FileAccess.file_exists(out_file) else FileAccess.open(out_file, FileAccess.WRITE)
		file.seek_end(); file.store_line(JSON.stringify(line)); file.close()
		print("[occupancy] done %d" % int(f))
	quit(0)

func measure(f: int) -> Dictionary:
	var level: float = float(game.building.spec.levels[f])
	var space := game.get_world_3d().direct_space_state
	var exclude: Array[RID] = [game.body.get_rid()]
	var x0 := -NX * STEP / 2.0 + STEP / 2.0
	var z0 := -NZ * STEP / 2.0 + STEP / 2.0
	var runs: Array = []   # [value, count, value, count, ...]
	for k in range(NZ):
		for i in range(NX):
			var x := x0 + i * STEP
			var z := z0 + k * STEP
			var q := PhysicsRayQueryParameters3D.create(Vector3(x, level + 2.4, z), Vector3(x, level - .1, z))
			q.exclude = exclude
			var hit := space.intersect_ray(q)
			var v := 255
			if not hit.is_empty():
				var cm := int(round((hit.position.y - level) * 100.0))
				v = clampi(cm, 0, 40) if cm <= 40 else 254
			if runs.size() >= 2 and int(runs[runs.size() - 2]) == v: runs[runs.size() - 1] = int(runs[runs.size() - 1]) + 1
			else: runs.append_array([v, 1])
	return {"floor": f, "nx": NX, "nz": NZ, "x0": x0, "z0": z0, "step": STEP, "rle": runs}
