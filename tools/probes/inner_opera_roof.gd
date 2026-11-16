extends SceneTree
## THE INNER OPERA on the roof, measured (Palle, 2026-11-16)
## commons/void/inner_opera.gd joins the Godot-made voice (commons/void/inner_voice_godot.gd, the kit's GDScript
## renderer, nothing native) to the tower: a settled look at a bound thing earns one short sung thought in the
## player's head. Under this probe's scripted walker the voice is made and sounds at -80 dB: nothing is played
## aloud. What is read:
##   the node is there with the roof's five things in its score and no score error;
##   all five phrases are made off the game's thread, from nothing (the kept copies are deleted first): each as
##     long as its plan, none silent; they are written beside this report as WAV files, to be measured and heard;
##   after the opening has lifted it listens (quietly, under this walker), and the five things that stand on the
##     roof are bound;
##   the visitor wakes facing the panel: the look rests on the crate, and after the dwell the thought for the
##     crate comes, once, and not again while the look stays;
##   turned round: the look rests on the other three, and their thought comes;
##   THE NEGATIVE: looking up at the lid's far corner... no: looking at the open sky from outside, nothing is
##     looked at and nothing comes for three seconds;
##   outside, looking at the frame counter: its thought comes.
##
##   godot --path <stage> --script res://tools/probes/inner_opera_roof.gd -- --no-bridges --void-start-floor=0
##       --out=<dir>
##
## opera.json: checks with what was read.
var game: Node3D
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("opera.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _wait(seconds: float) -> void:
	var ticks := int(seconds * Engine.physics_ticks_per_second)
	for i in ticks: await physics_frame


func _crate() -> Node3D:
	var props: Dictionary = game.building.content.props
	for key in props:
		if str(key).begins_with("0/") and props[key] != null:
			var found := (props[key] as Node).get_node_or_null("Prefab") as Node3D
			if found != null and found.has_method("break_panel"): return found
	return null


## Turn the walker and its eye toward a place.
func _face(target: Vector3) -> void:
	var body: Node3D = game.body
	body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
	var eye: Camera3D = root.get_camera_3d()
	if eye != null: eye.look_at(target, Vector3.UP)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	if DirAccess.dir_exists_absolute("user://inner_voice/"):
		for kept in DirAccess.get_files_at("user://inner_voice/"): DirAccess.remove_absolute("user://inner_voice/" + kept)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var checks := []
	result = {"floor": int(game.checkpoint), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("0/care-units-crate") and game.has_meta("inner_opera"): break
		await physics_frame
	var opera: Variant = game.get_meta("inner_opera", null)
	if opera == null:
		checks.append({"check": "the game holds the inner opera", "ok": false})
		_save(); quit(); return
	var s: Dictionary = opera.state()
	checks.append({"check": "the node is there with the roof's five things in its score and no score error", "ok": str(s.score_error) == "" and Array(s.thoughts) == ["crate", "others", "clock", "letters", "here"],
		"platform": OS.get_name(), "thoughts": s.thoughts})
	_save()
	var began := Time.get_ticks_msec()
	var slowest_frame := 0.0
	while Array(opera.state().ready).size() < 5 and Time.get_ticks_msec() - began < 120000:
		await process_frame
		slowest_frame = maxf(slowest_frame, root.get_process_delta_time())
	s = opera.state()
	var whole := true
	var loud := {}
	var plans: Dictionary = {}
	for phrase in JSON.parse_string(FileAccess.get_file_as_string(str(s.score))).phrases: plans[str(phrase.object_id)] = int(phrase.voice_plan.frames)
	for id in s.thoughts:
		var bytes: PackedByteArray = opera.samples_of(str(id))
		var peak := 0
		for i in range(0, bytes.size(), 2): peak = maxi(peak, absi(bytes.decode_s16(i)))
		loud[id] = snappedf(float(peak) / 32767.0, 0.001)
		whole = whole and bytes.size() >= int(plans[str(id)]) * 2 and peak > 1600
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 44100
		wav.data = bytes
		wav.save_to_wav(folder.path_join("%s.wav" % str(id)))
	var made := {}
	for id in s.costs: made[id] = [snappedf(float(s.costs[id].seconds), 0.01), snappedf(float(s.costs[id].length_s), 0.01), bool(s.costs[id].cached)]
	var shipped_ones := 0
	for id in s.costs:
		if bool(s.costs[id].get("shipped", false)): shipped_ones += 1
	checks.append({"check": "all five phrases are there, each at least as long as its plan, none silent, either made off the game's thread from nothing or all five from the renders that travel with the game; written beside this report as WAV files",
		"ok": Array(s.ready).size() == 5 and whole and (shipped_ones == 5 or not made.values().any(func(m): return m[2])), "made_in_s__length_s__kept": made, "peak": loud, "travelling_with_the_game": shipped_ones,
		"all_five_after_s": snappedf(float(Time.get_ticks_msec() - began) / 1000.0, 0.1), "slowest_frame_while_making_ms": snappedf(slowest_frame * 1000.0, 0.1)})
	_save()
	var level: float = float(game.building.spec.levels[0]) + game.building.global_position.y
	var crate := _crate()
	game.place_player_at_spawn(0)
	_face(crate.to_global(Vector3(0, 1.6, -1.4)))
	await _wait(3.2)
	s = opera.state()
	checks.append({"check": "after the opening has lifted it listens, quietly under this walker, and the five things that stand on the roof are bound", "ok": bool(s.listening) and bool(s.quiet) and Array(s.bound).size() == 5,
		"bound": s.bound})
	_save()
	_face(crate.to_global(Vector3(0, 1.6, -1.4)))
	await _wait(1.6)
	var at_panel: Dictionary = opera.state()
	await _wait(4.0)
	var stayed: Dictionary = opera.state()
	checks.append({"check": "the visitor wakes facing the panel: the look rests on the crate, and after the dwell the thought for the crate comes, once, and not again while the look stays",
		"ok": str(at_panel.looking_at) == "crate" and Array(stayed.heard).size() == 1 and str(stayed.heard[0].object) == "crate" and str(stayed.heard[0].text) == "The boards are thin.",
		"looking_at": str(at_panel.looking_at), "heard": stayed.heard})
	_save()
	var row: Node3D = (game.building.content.exhibits.get("0/care-units-crate") as Node3D).get_node("Artifact")
	_face(row.global_position + Vector3(0, 1.4, 0))
	await _wait(0.2)
	var at_row: Dictionary = opera.state()
	await _wait(4.5)
	var after_row: Dictionary = opera.state()
	checks.append({"check": "turned round: the look rests on the other three, and their thought comes", "ok": str(at_row.looking_at) == "others" and Array(after_row.heard).size() == 2
		and str(after_row.heard[1].text) == "I am the one that woke.", "looking_at": str(at_row.looking_at), "heard": after_row.heard})
	_save()
	crate.break_panel(false)
	await _wait(0.4)
	game.place_player(crate.to_global(Vector3(0.6, 0.3, -5.0)))
	await _wait(0.5)
	_face(game.body.global_position + Vector3(-30, 40, -30))
	await _wait(0.2)
	var at_sky: Dictionary = opera.state()
	await _wait(3.0)
	var after_sky: Dictionary = opera.state()
	checks.append({"check": "THE NEGATIVE: outside, looking at the open sky, nothing is looked at and nothing comes for three seconds", "ok": str(at_sky.looking_at) == "" and Array(after_sky.heard).size() == 2,
		"looking_at": str(at_sky.looking_at)})
	_save()
	var clock: Node3D = game.building.content.exhibits.get("0/clock") as Node3D
	var clock_at: Vector3 = clock.global_position
	for drawn in clock.find_children("*", "VisualInstance3D", true, false):
		if (drawn as VisualInstance3D).is_visible_in_tree() and not drawn is Light3D:
			clock_at = (drawn as VisualInstance3D).global_transform * (drawn as VisualInstance3D).get_aabb().get_center()
			break
	_face(clock_at)
	await _wait(0.2)
	var at_clock: Dictionary = opera.state()
	await _wait(4.5)
	var after_clock: Dictionary = opera.state()
	checks.append({"check": "outside, looking at the frame counter: its thought comes", "ok": str(at_clock.looking_at) == "clock" and Array(after_clock.heard).size() == 3
		and str(after_clock.heard[2].text) == "A number is changing.", "looking_at": str(at_clock.looking_at), "heard": after_clock.heard})
	# the sung line on the viewfinder: every thought that came was written there, and it is taken off when the voice ends
	var display: Variant = game.get("charge_display")
	var written := 0
	for h in Array(after_clock.heard):
		if bool(h.get("on_display", false)): written += 1
	var still := str(display.get("sung")) if display is Object and is_instance_valid(display) else "no display"
	var waited := 0
	while still != "" and still != "no display" and waited < 600:
		await process_frame
		waited += 1
		still = str(display.get("sung"))
	checks.append({"check": "each thought that came was written on the viewfinder beside the charge, and the line is taken off when the voice ends",
		"ok": written == Array(after_clock.heard).size() and written >= 3 and still == "", "written": written, "left_on_display": still, "frames_until_clear": waited})
	result["passed"] = checks.all(func(c): return c.ok)
	_save()
	print("[inner_opera_roof] ", "PASSED" if result.passed else "FAILED")
	quit()
