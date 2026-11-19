extends SceneTree
## Bubble Brush (Point_Trace, floor 4): when is the installed line sung, against how long the held bead
## keeps widening, at one hand speed a run. For the opera desk card "bubble-brush":
## "Does the second 'wider' still accompany a widening bead at different hand speeds?"
##
## The production desktop hand takes the brush and is then carried sideways at --drift metres a second
## (0 = held still). Every physics tick is logged: where the hand is, the growing bead's centre and
## radius, how many beads are frozen, whether the cue was offered, what is being sung. From the score's
## own word times, the radius of the bead is read at the moment each word of the line begins.
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/bubble_brush_timing.gd -- \
##       --void-start-floor=4 --no-opening --drift=0.03 --out=<dir>
##
## <dir>/bubble_timing.json and at_second_wider.png (the player's picture when the second "wider" begins).

const SONG := "chapter_04_bubble_brush"

var game: Node3D
var opera: Node
var progress: RefCounted
var out := "res://ada_run/bubble_timing"
var base := 0.0


func _initialize() -> void:
	run.call_deferred()


func frames(n: int) -> void:
	for i in n: await physics_frame


func _words(object_id: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(opera.get("score_path"))))
	if parsed is Dictionary:
		for phrase in parsed.phrases:
			if str(phrase.object_id) == object_id: return phrase.words
	return []


func run() -> void:
	var drift := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--drift="): drift = float(arg.trim_prefix("--drift="))
	DirAccess.make_dir_recursive_absolute(out)
	var badges = load("res://commons/player/badges.gd")
	badges.collected_file = out.path_join("isolated-collected.json"); badges.reread()
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate(); root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.scene_loaded(); game.scene_visible()
	var deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		if game.building.content.roots.has(4) and not game.building.content.pending.any(func(j): return int(j.index) == 4): break
	game.body.set_physics_process(false)
	base = game.building.spec.levels[4]
	opera = game.get_meta("inner_opera"); progress = opera.trace_progression
	var result := {"map": "Point_Trace", "floor": 4, "drift_m_per_s": drift, "passed": false, "checks": []}
	if progress == null:
		result.checks.append({"check": "the Point Trace progression is loaded", "ok": false})
		FileAccess.open(out.path_join("bubble_timing.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
		quit(1); return
	game.body.global_position = Vector3(0, base + .05, 0)
	await frames(90)
	var bubble: Node3D = progress.artifact("bubble-brush")
	var brush: RigidBody3D = bubble.brush
	# the production desktop hand takes the brush, a metre in front of the eye
	game.body.global_position = Vector3(brush.global_position.x, base + .05, brush.global_position.z + .8)
	game.camera.global_position = brush.global_position + Vector3(0, 0, 1.0)
	game.camera.global_basis = Basis.IDENTITY
	await frames(3)
	game.body.desktop_pointer._grab_held(brush)
	await frames(25)
	for i in 8: await process_frame
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var log_rows := []
	var t := 0.0
	var born := -1.0                       # seconds on this run's clock; may be before 0
	var cue_at := -1.0
	var sung_at := -1.0
	var sung_text := ""
	var sung_id := ""
	var cue_centre := Vector3.ZERO
	var words := []
	var shot := false
	var heard_before: int = (opera.get("heard") as Array).size()
	var events_before: int = progress.events.filter(func(e): return e.object == SONG).size()
	var stream_seconds := 0.0
	while t < 16.0:
		game.camera.global_position += Vector3(drift * tick, 0, 0)
		game.camera.global_basis = Basis.IDENTITY
		game.body.desktop_pointer._hold_distance = 1.0
		await physics_frame
		t += tick
		var current: Dictionary = bubble.current
		# the bead may have been born while the hand was taking the brush: its age is read back from its size
		if is_equal_approx(born, -1.0) and not current.is_empty(): born = t - (float(current.r) - float(bubble.start_radius)) / float(bubble.growth_rate)
		if cue_at < 0.0 and progress.events.filter(func(e): return e.object == SONG).size() > events_before:
			cue_at = t
			cue_centre = current.c if not current.is_empty() else Vector3.ZERO
		var heard: Array = opera.get("heard")
		if sung_at < 0.0 and heard.size() > heard_before:
			sung_at = t
			sung_text = str(heard[heard.size() - 1].text)
			sung_id = str(heard[heard.size() - 1].object)
			words = _words(sung_id)
			var stream: Variant = (opera.voice.get("streams") as Dictionary).get(sung_id)
			if stream is AudioStream: stream_seconds = (stream as AudioStream).get_length()
		log_rows.append([snappedf(t, 0.001), snappedf(float(current.r), 0.0001) if not current.is_empty() else -1.0, bubble.bubbles.size(),
			1 if (not current.is_empty() and cue_at >= 0.0 and (current.c as Vector3).is_equal_approx(cue_centre)) else 0])
		# the player's picture when the last word of the line begins
		if not shot and sung_at >= 0.0 and not words.is_empty() and t >= sung_at + float(words[words.size() - 1].start_frame) / 44100.0:
			shot = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("at_last_word.png"))
		if sung_at >= 0.0 and stream_seconds > 0.0 and t > sung_at + stream_seconds + 1.0: break
	game.body.desktop_pointer._drop_held()

	# what the bead was doing when each word began
	var at_words := []
	for word in words:
		var when := sung_at + float(word.start_frame) / 44100.0
		var row: Array = log_rows[mini(log_rows.size() - 1, int(when / tick))]
		var later: Array = log_rows[mini(log_rows.size() - 1, int((when + 0.25) / tick))]
		at_words.append({"word": str(word.text), "seconds_into_the_line": snappedf(float(word.start_frame) / 44100.0, 0.01), "seconds_after_the_bead_was_born": snappedf(when - born, 0.01),
			"radius_m": row[1], "the_bead_that_earned_the_line": row[3] == 1, "still_widening": row[3] == 1 and later[3] == 1 and float(later[1]) > float(row[1]) + 0.001, "beads_frozen": row[2]})
	var max_radius := float(bubble.max_radius)
	var growth := float(bubble.growth_rate)
	result["rule"] = {"start_radius_m": float(bubble.start_radius), "growth_m_per_s": growth, "max_radius_m": max_radius, "seconds_from_birth_to_full_size": snappedf((max_radius - float(bubble.start_radius)) / growth, 0.01),
		"cue_after_this_much_growth_m": minf(.08, (max_radius - float(bubble.start_radius)) * .5)}
	result["times"] = {"bead_born_s": snappedf(born, 0.01), "cue_offered_s_after_birth": snappedf(cue_at - born, 0.01) if cue_at >= 0.0 else null,
		"line_started_s_after_birth": snappedf(sung_at - born, 0.01) if sung_at >= 0.0 else null, "wait_between_cue_and_line_s": snappedf(sung_at - cue_at, 0.01) if sung_at >= 0.0 and cue_at >= 0.0 else null,
		"line_length_s": snappedf(stream_seconds, 0.01)}
	result["sung"] = {"object": sung_id, "text": sung_text}
	result["at_each_word"] = at_words
	var frozen_end: int = bubble.bubbles.size()
	result["beads_frozen_at_the_end"] = frozen_end
	result["checks"].append({"check": "the brush was held and a bead grew", "ok": born > -0.99})
	result["checks"].append({"check": "reported: was the line offered and sung at this hand speed", "ok": true, "offered": cue_at >= 0.0, "sung": sung_at >= 0.0})
	var last_ok := not at_words.is_empty() and bool(at_words[at_words.size() - 1].still_widening)
	result["checks"].append({"check": "reported: when the last word of the line begins, is the bead that earned it still widening", "ok": true, "still_widening": last_ok})
	result["passed"] = born > -0.99
	FileAccess.open(out.path_join("bubble_timing.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
	print("[bubble_brush_timing] done drift ", drift)
	quit(0)
