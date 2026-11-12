extends SceneTree
## THE AUTOMATON ORGAN (floor CA_AgentsCircuits; Palle, 2026-11-12: "and then cellular automata as beats, or tones,
## harmonics?")
## Sixteen cells in a ring under one elementary rule; pipe k is the first pipe divided by k and sounds k times its
## 55 Hz; a row is a bar of sixteen steps. Read in the running tower, with its own walker:
##   HARMONICS  the sixteen pipes are 3.12 m / k long, and the sixteen samples sound 55 Hz x k;
##   THE RULE   over a run of bars every new row is the rule applied to the row before (the probe's own table, not
##              the work's function), or the single seed after a row with nothing left;
##   BEATS      in `steps` the notes of a bar are exactly the live cells, cell k at step k on pipe k;
##              in `chord` they all sound at step 0; in `pulse` every one is the drum;
##   THE ROOM'S RULE  the organ plays the rule the floor's rule explorer is set to, and follows a change;
##   THE FLOOR IS THE ROW  a body that steps onto a pad of the present row flips that cell and no other;
##   a plate changes the way of playing when a body steps on it; the lane beside the plates stays open;
##   it sounds while a body is near and is silent when nobody is; what a frame costs.
##
##   godot --path <stage> --script res://tools/probes/automaton_organ_play.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## organ.json: checks with what was read. arrival.png, organ.png, carpet.png, north.png.
const ID := "automaton-organ"
const EXPLORER := "f4_ca_rule_explorer_3_5"
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


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 700, speed: float = 0.34) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.12: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 25: await physics_frame
	return best


## The probe's own reading of a Wolfram number: the new cell is the bit the three cells above it point at.
func _rule(row: PackedByteArray, number: int) -> PackedByteArray:
	var table := []
	for code in 8: table.append(1 if (number & (1 << code)) != 0 else 0)
	var out := PackedByteArray()
	for i in row.size():
		var left: int = row[(i - 1 + row.size()) % row.size()]
		var right: int = row[(i + 1) % row.size()]
		out.append(table[left * 4 + int(row[i]) * 2 + right])
	return out


func _seed_row() -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(16)
	out[8] = 1
	return out


## Let the organ play `count` whole bars; return what each bar was: the row played, its notes, the row that followed.
func _bars(organ: Node, count: int) -> Array:
	var out := []
	var at: int = organ.bars()
	for i in 3000:
		await process_frame
		if organ.bars() != at:
			at = organ.bars()
			out.append({"played": organ.earlier(1), "notes": organ.last_bar().duplicate(true), "next": organ.row().duplicate()})
			if out.size() > count: break
	out.pop_front()                      # the bar under way when the listening began
	return out


func _live(row: PackedByteArray) -> Array:
	var out := []
	for k in row.size():
		if row[k] == 1: out.append(k)
	return out


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
	var key := str(floor) + "/" + ID
	for i in 1500:
		if game.building.content.exhibits.has(key) and game.building.content.exhibits.has(str(floor) + "/" + EXPLORER): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get(key)
	var organ: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
	checks.append({"check": "the floor holds the automaton organ", "ok": organ != null and organ.has_method("next_row")})
	if organ != null and organ.has_method("next_row"):
		for i in 240: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var at := organ.global_position
		var east: Vector3 = (organ.to_global(Vector3(0, 0, 1)) - at).normalized()       # the way the carpet runs out from the pipes
		var north: Vector3 = (organ.to_global(Vector3(1, 0, 0)) - at).normalized()      # toward the short pipes
		checks.append({"check": "the carpet runs east from the pipes, the short pipes are to the north", "ok": east.x > 0.99 and north.z < -0.99})

		# pictures, with the rule seven bars in: rule 90's whole triangle lies on the floor
		organ.apply_grid_config({"loudness_db": -50.0, "step_seconds": 30.0, "preroll": 7})
		for i in 20: await process_frame
		game.place_player(Vector3(-4.0, level + 0.3, 8.6))
		for i in 30: await physics_frame
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(-18.5, level + 1.2, 0.5), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(-13.2, level + 1.7, 5.8), Vector3(-18.6, level + 1.0, -0.6), folder.path_join("organ.png"))
		await _shot(cam, Vector3(-13.3, level + 4.9, 0.0), Vector3(-18.4, level + 0.2, 0.0), folder.path_join("carpet.png"))
		await _shot(cam, Vector3(-15.0, level + 1.7, 2.6), Vector3(-17.4, level + 1.1, -5.2), folder.path_join("north.png"))
		await _shot(cam, Vector3(-16.2, level + 1.6, 1.2), Vector3(-19.8, level + 1.2, 1.6), folder.path_join("pipes.png"))

		# 1 harmonics: the pipes and the tones
		var pipes_ok := true
		var tones_ok := true
		var pipes := []
		var tones := []
		for i in 600:
			if organ.ready_samples() > 16: break
			await process_frame
		for k in range(1, 17):
			var tall: float = organ.pipe_m(k)
			var hz: float = organ.tone_hz(k) if organ.ready_samples() > 16 else 0.0
			pipes.append(snappedf(tall, .001)); tones.append(snappedf(hz, .1))
			if absf(tall - 3.12 / float(k)) > 0.001: pipes_ok = false
			if absf(hz - 55.0 * float(k)) > 55.0 * float(k) * 0.004: tones_ok = false
		checks.append({"check": "pipe k is the first pipe's 3.12 m divided by k", "ok": pipes_ok, "metres": pipes})
		checks.append({"check": "tone k sounds k times 55 Hz (within 0.4 %), read off the rendered samples", "ok": tones_ok and organ.ready_samples() > 16, "hz": tones})

		# 2 the room's rule
		var explorer: Node = game.building.content.exhibits.get(str(floor) + "/" + EXPLORER).get_node_or_null("Artifact")
		for i in 200:
			if organ.following(): break
			await process_frame
		var room_rule: int = int(explorer.get("rule")) if explorer != null else -1
		checks.append({"check": "the organ plays the rule the floor's rule explorer is set to", "ok": explorer != null and organ.following() and organ.number() == room_rule, "rule": room_rule})

		# 3 the rule and the beats, with nobody near: fast bars, the notes logged whether or not they sound
		game.place_player(Vector3(-4.0, level + 0.3, 8.6))
		organ.apply_grid_config({"always": true, "step_seconds": 0.02, "preroll": 0, "plays": "steps"})
		var before_notes: int = organ.sounded()
		var run_bars: Array = await _bars(organ, 18)
		var obeyed := 0
		var restarts := 0
		var steps_ok := true
		for bar in run_bars:
			var want: PackedByteArray = _rule(bar.played, room_rule)
			if bar.next == want: obeyed += 1
			elif (_live(want).is_empty() or _live(want).size() == 16) and bar.next == _seed_row(): restarts += 1
			var notes := []
			for n in bar.notes: notes.append([int(n[0]), int(n[1]), int(n[2])])
			var should := []
			for k in _live(bar.played): should.append([k, k, 0])
			if notes != should: steps_ok = false
		checks.append({"check": "over a run of bars every new row is the rule applied to the row before, or the seed after a row with nothing left", "ok": run_bars.size() >= 16 and obeyed + restarts == run_bars.size() and obeyed >= 12,
			"bars": run_bars.size(), "by_the_rule": obeyed, "restarts": restarts, "rule": room_rule})
		checks.append({"check": "steps: the notes of a bar are exactly its live cells, cell k at step k on pipe k", "ok": steps_ok and run_bars.size() >= 16})
		checks.append({"check": "with `always` the notes leave a speaker", "ok": organ.sounded() > before_notes, "notes": organ.sounded() - before_notes})
		organ.apply_grid_config({"plays": "chord"})
		var chord_bars: Array = await _bars(organ, 5)
		var chord_ok: bool = chord_bars.size() >= 4
		for bar in chord_bars:
			var should := []
			for k in _live(bar.played): should.append([0, k, 0])
			var notes := []
			for n in bar.notes: notes.append([int(n[0]), int(n[1]), int(n[2])])
			if notes != should: chord_ok = false
		checks.append({"check": "chord: every live pipe sounds at the top of the bar and nothing after", "ok": chord_ok, "bars": chord_bars.size()})
		organ.apply_grid_config({"plays": "pulse"})
		var pulse_bars: Array = await _bars(organ, 5)
		var pulse_ok: bool = pulse_bars.size() >= 4
		for bar in pulse_bars:
			var should := []
			for k in _live(bar.played): should.append([k, k, 1])
			var notes := []
			for n in bar.notes: notes.append([int(n[0]), int(n[1]), int(n[2])])
			if notes != should: pulse_ok = false
		checks.append({"check": "pulse: one drum for every live cell, at that cell's step", "ok": pulse_ok, "bars": pulse_bars.size()})

		# 4 the console changes the rule; the organ follows at the next bar
		organ.apply_grid_config({"plays": "steps"})
		explorer.set_rule(30)
		var chaos_bars: Array = await _bars(organ, 8)
		var chaos_ok := 0
		for i in range(1, chaos_bars.size()):
			if chaos_bars[i].next == _rule(chaos_bars[i].played, 30): chaos_ok += 1
		var took: int = organ.number()
		explorer.set_rule(room_rule)
		await _bars(organ, 2)
		checks.append({"check": "the console is set to rule 30 and the organ's rows follow rule 30; set back, the organ goes back", "ok": took == 30 and chaos_ok >= chaos_bars.size() - 2 and chaos_bars.size() >= 6 and organ.number() == room_rule,
			"rows_by_rule_30": chaos_ok, "of": chaos_bars.size() - 1, "back_to": organ.number()})

		# 5 silent with nobody near, sounding with a body in the bay
		organ.apply_grid_config({"always": false, "step_seconds": 0.02})
		game.place_player(Vector3(-4.0, level + 0.3, 8.6))
		for i in 40: await physics_frame
		var quiet_from: int = organ.sounded()
		for i in 120: await process_frame
		var quiet: int = organ.sounded() - quiet_from
		game.place_player(Vector3(-13.8, level + 0.3, 5.4))
		for i in 40: await physics_frame
		var loud_from: int = organ.sounded()
		for i in 120: await process_frame
		var loud: int = organ.sounded() - loud_from
		checks.append({"check": "nobody near: no note leaves a speaker; a body in the bay: they do", "ok": quiet == 0 and loud > 0, "notes_alone": quiet, "notes_with_a_body": loud})

		# 6 the lane beside the plates, then a plate, then the row
		organ.apply_grid_config({"step_seconds": 600.0, "plays": "steps"})
		for i in 10: await process_frame
		var lane_far := Vector3(-13.8, level, -4.2)
		var lane := await _go(body, lane_far, 900, 0.7)
		checks.append({"check": "the lane between the organ's plates and the termite yard is walked end to end, and no plate is pressed", "ok": lane < 0.4 and str(organ.plays) == "steps" and int(game.checkpoint) == floor,
			"reached_within_m": snappedf(lane, .01), "plays": str(organ.plays)})
		var plate: Vector3 = organ.plate_centre(0)
		game.place_player(plate + east * 0.9 + Vector3(0, 0.3, 0))
		for i in 80: await physics_frame                       # the plates rest 1.2 s between presses
		await _go(body, plate, 300)
		checks.append({"check": "a body steps on the first plate and the organ plays chords", "ok": str(organ.plays) == "chord", "plays": str(organ.plays)})
		organ.apply_grid_config({"plays": "steps"})
		var cell := 5
		var pad: Vector3 = organ.pad_centre(cell)
		game.place_player(pad + east * 1.6 + Vector3(0, 0.3, 0))
		for i in 45: await physics_frame
		var was: PackedByteArray = organ.row().duplicate()
		await _go(body, pad, 300)
		var now: PackedByteArray = organ.row().duplicate()
		var others := 0
		for k in 16:
			if k != cell and was[k] != now[k]: others += 1
		var stood: Vector3 = organ.to_local(body.global_position)
		checks.append({"check": "a body steps onto a pad of the present row: that cell flips and no other", "ok": now[cell] == 1 - was[cell] and others == 0,
			"cell": cell, "was": was[cell], "now": now[cell], "others_changed": others, "stood_local": [snappedf(stood.x, .01), snappedf(stood.z, .01)]})
		await _shot(cam, body.global_position + Vector3(2.4, 2.2, 1.6), body.global_position + Vector3(-0.6, 0.3, -0.4), folder.path_join("on_the_row.png"))
		await _go(body, pad + east * 1.6, 300)
		var after: PackedByteArray = organ.row().duplicate()
		checks.append({"check": "walking off the row changes nothing", "ok": after == now})

		# 7 what it costs: playing on the floor, and rendering its samples on a bench
		organ.apply_grid_config({"step_seconds": 0.16, "always": true})
		organ.frame_ms()
		for i in 200: await process_frame
		var playing: float = organ.frame_ms()
		var fresh: Node3D = load("res://algorithms/cellularautomata/automaton_organ/automaton_organ.tscn").instantiate()
		fresh.set("loudness_db", -80.0)
		root.add_child(fresh)
		fresh.global_position = Vector3(0, level - 400.0, 0)
		var rendering := 0.0
		var render_frames := 0
		fresh.frame_ms()
		for i in 900:
			await process_frame
			if fresh.ready_samples() > 16: break
			render_frames += 1
		rendering = fresh.frame_ms()
		fresh.queue_free()
		checks.append({"check": "playing costs under 0.3 ms a frame; rendering its seventeen samples under 2 ms a frame, and it ends", "ok": playing < 0.3 and rendering < 2.0 and render_frames < 600,
			"playing_ms": snappedf(playing, .001), "rendering_ms": snappedf(rendering, .001), "render_frames": render_frames})
		organ.apply_grid_config({"always": false, "loudness_db": -12.0, "preroll": 0})
		game.place_player(Vector3(-4.0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("organ.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[automaton_organ_play] ", "PASSED" if result.passed else "FAILED")
	quit()
