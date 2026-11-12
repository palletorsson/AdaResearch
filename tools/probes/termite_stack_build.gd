extends SceneTree
## THE TERMITE STACK BUILDS WHAT ITS INSTRUCTION SAYS (floor CA_AgentsCircuits; the Void, 2026-11-12)
## One worker on a lattice of stacks: it reads the height under it, turns as the instruction says for that height,
## adds a unit and steps on. Five instructions were run on a bench (a few lines of Python) before the work was
## built; the standing cells and their heights at each instruction's step budget are written below as predictions.
## Read in the running tower:
##   each of the five instructions builds exactly the predicted form (standing cells, cells at each height);
##   no stack is taller than the work says, and all are under the ceiling;
##   left running, a form grows; the plate at the rim gives the next instruction;
##   the rails of the kit yard keep a body out; what a frame costs while it builds and while it stands.
##
##   godot --path <stage> --script res://tools/probes/termite_stack_build.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## termites.json: checks with what was read. arrival.png, and one picture of each built form.
const PREDICTED := {
	"mound": {"standing": 714, "heights": [277, 352, 85]},
	"lace": {"standing": 186, "heights": [186]},
	"city": {"standing": 1548, "heights": [229, 752, 173, 95, 93, 73, 64, 69]},
	"terraces": {"standing": 694, "heights": [102, 77, 36, 61, 32, 116, 64, 42, 53, 58, 53]},
	"weave": {"standing": 227, "heights": [41, 147, 39]},
}
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "termite_stack": item = a
	checks.append({"check": "the termite stack is on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 1200:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var work: Node3D = null
		for n in [mount] + mount.find_children("*", "Node3D", true, false):
			if n.has_method("next_rule"): work = n; break
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var hub: Vector3 = work.global_position
		# 1 every instruction builds the form the bench predicted
		work.cycle = false
		var wrong := []
		var tallest_seen := 0.0
		var read := {}
		for name in PREDICTED:
			work.apply_grid_config({"rule": name})
			if str(work.rule) != name: work.call("_begin", name)
			work.finish()
			for i in 6: await process_frame
			var s: Dictionary = work.state()
			read[name] = {"standing": s.standing, "heights": s.heights, "steps": s.step}
			if int(s.standing) != int(PREDICTED[name].standing) or Array(s.heights) != Array(PREDICTED[name].heights): wrong.append(name)
			tallest_seen = maxf(tallest_seen, float(work.top()))
			await _shot(cam, hub + Vector3(4.4, 3.6, 5.6), hub + Vector3(0, 0.9, 0), folder.path_join("form_%s.png" % name))
			if name == "mound": await _shot(cam, Vector3(0, level + 1.6, 7.8), hub + Vector3(0, 1.2, 0), folder.path_join("arrival.png"))
		checks.append({"check": "each of the five instructions builds exactly the form predicted on the bench", "ok": wrong.is_empty(), "wrong": wrong, "read": read})
		checks.append({"check": "no stack is taller than the work says, and all stand under the ceiling", "ok": tallest_seen <= float(work.tallest) + 0.001 and tallest_seen + float(work.lift) < 5.6, "tallest_m": snappedf(tallest_seen, .01)})
		var ms_hold: float = work.frame_ms()
		for i in 120: await process_frame
		ms_hold = work.frame_ms()
		# 2 left running, a form grows
		work.call("_begin", "mound")
		var before: int = int(work.state().step)
		work.frame_ms()
		for i in 180: await process_frame
		var ms_build: float = work.frame_ms()
		var grown: Dictionary = work.state()
		checks.append({"check": "left running, the termite works and the form grows", "ok": int(grown.step) - before > 400 and int(grown.standing) > 0, "steps_in_three_seconds": int(grown.step) - before, "standing": grown.standing})
		await _shot(cam, hub + Vector3(4.4, 3.6, 5.6), hub + Vector3(0, 0.9, 0), folder.path_join("growing.png"))
		# 3 the plate gives the next instruction
		var was: String = str(work.rule)
		game.place_player(work.to_global(Vector3(float(work.field) * 0.5 + 1.0, 0.3, -0.9)))
		for i in 60: await physics_frame
		checks.append({"check": "the plate at the rim gives the next instruction", "ok": str(work.rule) != was, "from": was, "to": str(work.rule)})
		# 4 the yard keeps a body out
		game.place_player(hub + Vector3(5.2, 0.3, 2.2))
		for i in 40: await physics_frame
		var nearest := INF
		for i in 300:
			nearest = minf(nearest, body.global_position.x - hub.x)
			body.look_at(Vector3(hub.x, body.global_position.y, hub.z + 2.2), Vector3.UP)
			body.drive = Vector2(0, -1)
			await physics_frame
		body.drive = Vector2.ZERO
		for i in 20: await physics_frame
		checks.append({"check": "the rails of the yard keep a body out of the stacks", "ok": nearest > float(work.field) * 0.5 and int(game.checkpoint) == floor, "nearest_to_the_middle_m": snappedf(nearest, .01), "field_half_m": snappedf(float(work.field) * 0.5, .01)})
		checks.append({"check": "it costs little: while it builds, and next to nothing while a form stands", "ok": ms_build < 0.6 and ms_hold < 0.08, "ms_a_frame_building": snappedf(ms_build, .001), "ms_a_frame_standing": snappedf(ms_hold, .001)})
		work.cycle = true
		work.call("_begin", "mound")
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("termites.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[termite_stack_build] ", "PASSED" if result.passed else "FAILED")
	quit()
