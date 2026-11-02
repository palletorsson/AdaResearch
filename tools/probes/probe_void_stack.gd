extends SceneTree
## WALK ALL FLOORS (Palle, 2026-11-02: "can I walk all floors"). Opens a stacked playground trial
## (tools/playground_trial.py stack) the way the desktop opens it, then for each floor drops the player into shaft B
## above the next floor's soft pad and checks: it lands on that pad's floor (y within 0.6 m of the level), and the
## next floor's map is built (its spec hall exhibit exists and holds activities). A photograph per arrival.
## Writes ada_run/workstation/void_stack.json and void_stack_floor_<n>.png.
## Run: godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/probe_void_stack.gd -- --void-trial=playground_floors
var game: Node3D
var trial := "playground_floors"
var report := {"checks": [], "arrivals": []}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-trial="):trial = arg.trim_prefix("--void-trial=")
	var out := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out)
	load("res://commons/void/room_source.gd").use_main_tower = false
	game = load("res://commons/void/void.tscn").instantiate()
	game.trial_id = trial
	root.add_child(game);current_scene = game
	game.body.scripted_input = true;game.body.set_process_unhandled_input(false)
	game.scene_loaded();game.scene_visible()
	var levels: Array = game.building.spec.levels
	var floors: Array = game.building.content.data.floors
	var start: int = game.checkpoint
	await _until_built(start, 300)
	_check("start: floor %d (%s) built" % [start, floors[start].title], _built(start), {"floor": start})
	await _shot(out, start)
	var shaft_x := 0.0
	for s in game.building.spec.shafts:
		if s.name == "B":shaft_x = float(s.x)
	for k in range(start, floors.size() - 1):
		var below := k + 1
		var pad: Node3D = null
		for p in game.building.landing_pads:
			if int(p.get_meta("void_floor_index", -1)) == below:pad = p
		if pad == null:
			_check("floor %d -> %d: a soft pad in shaft B below" % [k, below], false, {});continue
		# stand in the hole on floor k, straight above the pad below, and let go
		var drop := Vector3(pad.global_position.x, float(levels[k]) + .4, pad.global_position.z)
		game.place_player(drop)
		var landed := false;var t := 0
		while t < 360:
			await physics_frame;t += 1
			if game.body.is_on_floor() and game.body.global_position.y < float(levels[k]) - 1.0:landed = true;break
		var y: float = game.body.global_position.y
		var on_level: bool = landed and absf(y - float(levels[below])) < .6
		var content: bool = floors[below].artifacts.size() > 0
		if content:await _until_built(below, 300)
		var built: bool = (not content) or _built(below)
		var acts: int = _activities(below)
		report.arrivals.append({"from": k, "to": below, "title": floors[below].title, "landed": landed, "y": snappedf(y, .01), "level": levels[below], "frames": t, "built": built, "activities": acts, "pad": [snappedf(pad.global_position.x, .01), snappedf(pad.global_position.z, .01)]})
		_check("floor %d -> %d (%s): dropped into shaft B, landed at %.2f on level %.1f%s" % [k, below, floors[below].title, y, float(levels[below]), (", its map built with %d activities" % acts) if content else ""], on_level and built and (not content or acts > 0), report.arrivals.back())
		# walk off the pad onto the slab before the photograph: a metre toward the hall
		game.place_player(Vector3(shaft_x - 5.0, float(levels[below]) + .2, 0.0))
		for i in 20:await physics_frame
		await _shot(out, below)
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size();report["trial"] = trial
	var f := FileAccess.open(out.path_join("void_stack.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	print("[probe_void_stack] %d/%d" % [passed, report.checks.size()])
	quit(0 if passed == report.checks.size() else 1)

func _built(floor: int) -> bool:
	var record: Dictionary = game.building.content.data.floors[floor]
	return record.artifacts.all(func(a): return game.building.content.exhibits.has(str(floor) + "/" + a.id))

func _until_built(floor: int, frames: int) -> void:
	for i in frames:
		if _built(floor):return
		await physics_frame

## How many activities the floor's spec hall holds (a map with nothing standing is not a map).
func _activities(floor: int) -> int:
	var n := 0
	for key in game.building.content.exhibits:
		if not str(key).begins_with(str(floor) + "/"):continue
		var hall: Node = game.building.content.exhibits[key].get_node_or_null("Artifact")
		if hall == null:continue
		for c in hall.get_children():
			if c.has_meta("activity_artifact"):n += 1
	return n

func _shot(out: String, floor: int) -> void:
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("void_stack_floor_%d.png" % floor))

func _check(what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_void_stack] %s  %s" % ["ok  " if ok else "FAIL", what])
