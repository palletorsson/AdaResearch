extends SceneTree
## THE OPENING, measured (Palle, 2026-11-16): the game begins in black, inside the delivery.
## commons/void/opening.gd hangs a black veil before the active camera from the first frame and lifts it only when
## the visitor is known to be inside the arrival crate, with the crate's landing heard in the dark. Read in the
## running tower, at a start on the roof:
##   the first frame drawn is black: the veil is there before anything is seen;
##   THE NEGATIVE: the visitor is put on the open roof, six metres from the crate, for three seconds with the game
##     ready: the veil stays fully black the whole time and the picture stays black;
##   put back at the spawn: the veil is still fully black when the landing begins to sound, and at that moment the
##     camera and the body are measured inside the crate (measured here, not taken from the opening), the crate
##     closed;
##   the blow is heard in black: the veil does not begin to lift until 1.25 s into the sound;
##   the lift takes 2.4 s and never darkens again; the last picture is brighter than the first and is the inside
##     of the crate; the opening has freed itself and did not open the crate.
##
##   godot --path <stage> --script res://tools/probes/void_opening.gd -- --no-bridges --void-start-floor=0
##       --opening --out=<dir>
##
## opening.json: checks with what was read. first.png, outside.png, landed.png, lifting.png, inside.png.
var game: Node3D
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("opening.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


## The window as it is drawn now: saved, and how bright it is (0 black .. 1 white).
func _look(name: String) -> float:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(folder.path_join(name))
	image.resize(64, 40, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for y in 40:
		for x in 64: total += image.get_pixel(x, y).get_luminance()
	return total / 2560.0


func _crate() -> Node3D:
	var props: Dictionary = game.building.content.props
	for key in props:
		if str(key).begins_with("0/") and props[key] != null:
			var found := (props[key] as Node).get_node_or_null("Prefab") as Node3D
			if found != null and found.has_method("break_panel"): return found
	return null


func _inside() -> bool:
	var crate := _crate()
	var active := root.get_camera_3d()
	return crate != null and active != null and bool(crate.inside(active.global_position)) and bool(crate.inside(game.body.global_position + Vector3(0, 0.9, 0)))


func _black() -> float:
	var opening: Variant = game.get_meta("opening", null)
	return float(opening.blackness()) if opening != null and is_instance_valid(opening) else 0.0


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	var checks := []
	result = {"floor": int(game.checkpoint), "checks": checks, "passed": false}
	var opening: Variant = game.get_meta("opening", null)
	var first: float = await _look("first.png")
	checks.append({"check": "the first frame drawn is black: the veil is there before anything is seen", "ok": opening != null and is_equal_approx(_black(), 1.0) and first < 0.01,
		"veil": _black(), "picture_brightness": snappedf(first, 0.0001)})
	_save()
	game.scene_loaded(); game.scene_visible()
	var level: float = float(game.building.spec.levels[0]) + game.building.global_position.y
	# the negative: ready, and NOT inside
	var held := true
	var ready_frames := 0
	var seconds := 0.0
	game.place_player(Vector3(3.0, level + 0.3, -3.0))
	while seconds < 3.0:
		await physics_frame
		seconds += 1.0 / Engine.physics_ticks_per_second
		if not _crate() == null and _inside(): game.place_player(Vector3(3.0, level + 0.3, -3.0))
		if bool(game.ready_for_play): ready_frames += 1
		held = held and is_equal_approx(_black(), 1.0)
	var outside: float = await _look("outside.png")
	checks.append({"check": "THE NEGATIVE: the visitor on the open roof, six metres from the crate, for three seconds with the game ready: the veil stays fully black and the picture stays black",
		"ok": held and ready_frames > 60 and not _inside() and outside < 0.01 and _crate() != null, "ready_frames": ready_frames, "picture_brightness": snappedf(outside, 0.0001)})
	_save()
	# back to the spawn: now it may lift
	game.place_player_at_spawn(0)
	var sound_at := -1.0
	var lift_at := -1.0
	var gone_at := -1.0
	var inside_at_sound := false
	var closed_at_sound := false
	var black_at_sound := 0.0
	var never_darker := true
	var last := 1.0
	var shot_landed := -1.0
	var shot_lifting := -1.0
	seconds = 0.0
	while seconds < 20.0 and gone_at < 0.0:
		await process_frame
		seconds += root.get_process_delta_time()
		var live: Variant = game.get_meta("opening", null)
		if live == null or not is_instance_valid(live):
			gone_at = seconds
			break
		var black: float = float(live.blackness())
		if sound_at < 0.0 and live.sound != null and live.sound.playing:
			sound_at = seconds
			inside_at_sound = _inside()
			closed_at_sound = not bool(_crate().broken)
			black_at_sound = black
			shot_landed = await _look("landed.png")
		if lift_at < 0.0 and black < 0.999: lift_at = seconds
		if black > last + 0.0001: never_darker = false
		last = black
		if shot_lifting < 0.0 and black < 0.5:
			shot_lifting = await _look("lifting.png")
	var report: Dictionary = game.get_meta("opening_report", {})
	checks.append({"check": "put back at the spawn: the veil is still fully black when the landing begins to sound, and at that moment the camera and the body are measured inside the crate, the crate closed",
		"ok": sound_at >= 0.0 and is_equal_approx(black_at_sound, 1.0) and inside_at_sound and closed_at_sound and shot_landed < 0.01 and bool(report.get("sound_played", false)) and not bool(report.get("gave_up", true)),
		"sound_began_s": snappedf(sound_at, 0.01), "picture_brightness": snappedf(shot_landed, 0.0001), "report": report})
	_save()
	checks.append({"check": "the blow is heard in black: the veil does not begin to lift until 1.25 s into the sound", "ok": lift_at - sound_at > 1.15 and lift_at - sound_at < 1.6, "black_for_s_of_sound": snappedf(lift_at - sound_at, 0.01)})
	_save()
	var inside: float = await _look("inside.png")
	var crate := _crate()
	checks.append({"check": "the lift takes 2.4 s and never darkens again; the last picture is brighter than the first and is the inside of the crate; the opening has freed itself and did not open the crate",
		"ok": gone_at > 0.0 and absf((gone_at - lift_at) - 2.4) < 0.35 and never_darker and inside > first + 0.01 and _inside() and not bool(crate.broken) and not game.has_meta("opening"),
		"lift_s": snappedf(gone_at - lift_at, 0.01), "brightness_mid_lift": snappedf(shot_lifting, 0.0001), "brightness_after": snappedf(inside, 0.0001)})
	result["passed"] = checks.all(func(c): return c.ok)
	_save()
	print("[void_opening] ", "PASSED" if result.passed else "FAILED")
	quit()
