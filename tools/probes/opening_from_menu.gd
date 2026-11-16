extends SceneTree
## THE OPENING, FROM THE MENU (Palle, 2026-11-16: "can we test that opening in desktop from menu choose load to the
## game"; and before that, from the headset: "we have to fade down to black before we go to the main scene in the
## menu, otherwise flash the world before we are moved")
##
## The game's real start on the desktop: the staging scene with its menu, the tower chosen through the menu's own
## call (the one its floor picker ends in), the staging's handover, and commons/void/opening.gd. EVERY frame drawn
## from the choice until the visitor is in the crate is measured for how bright it is:
##   the menu is on the screen;
##   after the choice the staging fades the menu down to black before anything is loaded into the world;
##   NO FLASH: from the first frame in which the tower's scene exists until the veil begins to lift, no frame is
##     brighter than black - through the staging's own fade-in, whatever camera is current;
##   in that black the visitor is put in the crate and the landing sounds; then the veil lifts onto the inside of
##     the crate, by itself and not by the timer.
## What it does not do: press the two menu buttons with a pointer (tools/probes/game_menu_route.gd does that).
##
##   godot --path <stage> --script res://tools/probes/opening_from_menu.gd -- --no-bridges --opera-quiet --out=<dir>
##
## menu_start.json: checks, and what each phase of the handover looked like. menu.png, after_choice.png,
## loading.png (if the staging showed its loading screen), black_with_tower.png, lifting.png, in_the_crate.png.
var folder := ""
var result := {}
var stage: Node


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("menu_start.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


## The window as it is drawn now, and how bright it is (0 black .. 1 white); saved when a name is given.
func _look(name := "") -> float:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if not name.is_empty(): image.save_png(folder.path_join(name))
	image.resize(64, 40, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for y in 40:
		for x in 64: total += image.get_pixel(x, y).get_luminance()
	return total / 2560.0


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	var checks := []
	result = {"checks": checks, "passed": false}
	stage = load("res://commons/scenes/vr_staging.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await create_timer(2.0).timeout
	var menu: Node = stage.get_node_or_null("MainMenu3D")
	var at_menu: float = await _look("menu.png")
	checks.append({"check": "the menu is on the screen", "ok": menu != null and bool(menu.get("visible")) and at_menu > 0.02 and menu.has_method("_open_void_floor"), "picture_brightness": snappedf(at_menu, 0.001)})
	_save()
	if menu == null or not menu.has_method("_open_void_floor"):
		quit(); return
	# the choice: the call the floor picker ends in
	menu.call("_open_void_floor", 0)
	var phases := {}                     # phase -> {frames, seconds, darkest, brightest}
	var order := []
	var shots := {}
	var phase := ""
	var seconds := 0.0
	var open_for := 0.0
	var sound_in_black := false
	var inside_at_sound := false
	var game: Node = null
	while seconds < 90.0 and open_for < 1.0:
		await process_frame
		var delta: float = root.get_process_delta_time()
		seconds += delta
		game = stage.get("current_scene") as Node
		var loading: Node = stage.get_node_or_null("LoadingScreen")
		var opening: Variant = game.get_meta("opening", null) if game != null else null
		var live: bool = opening != null and is_instance_valid(opening)
		var black: float = float(opening.blackness()) if live else 0.0
		if game == null: phase = "loading screen, no tower yet" if loading != null and bool(loading.get("visible")) else "menu fading out, no tower yet"
		elif live and black >= 0.999: phase = "tower in the world, veil black"
		elif live: phase = "veil lifting"
		else:
			phase = "in the crate"
			open_for += delta
		var name := ""
		if not shots.has(phase) and phase in ["loading screen, no tower yet", "in the crate"]:
			name = {"loading screen, no tower yet": "loading.png", "in the crate": "in_the_crate.png"}[phase]
		elif phase == "veil lifting" and not shots.has(phase) and black < 0.5: name = "lifting.png"
		elif phase == "tower in the world, veil black" and not shots.has(phase) and bool(game.get("ready_for_play")): name = "black_with_tower.png"
		if not name.is_empty(): shots[phase] = name
		var bright: float = await _look(name)
		if not phases.has(phase):
			phases[phase] = {"frames": 0, "seconds": 0.0, "darkest": 1.0, "brightest": 0.0}
			order.append(phase)
		var row: Dictionary = phases[phase]
		row.frames += 1
		row.seconds += delta
		row.darkest = minf(row.darkest, bright)
		row.brightest = maxf(row.brightest, bright)
		if live and black >= 0.999 and opening.sound != null and opening.sound.playing and not sound_in_black:
			sound_in_black = true
			var crate: Node3D = opening.crate
			inside_at_sound = crate != null and bool(crate.inside(root.get_camera_3d().global_position))
	for key in phases:
		for field in ["seconds", "darkest", "brightest"]: phases[key][field] = snappedf(float(phases[key][field]), 0.001)
	result["phases_in_order"] = order
	result["phases"] = phases
	var fading: Dictionary = phases.get("menu fading out, no tower yet", {})
	checks.append({"check": "after the choice the staging fades the menu down to black before anything is loaded into the world", "ok": not fading.is_empty() and float(fading.darkest) < 0.01,
		"darkest_before_the_tower": fading.get("darkest", -1.0), "the_staging_showed_its_loading_screen": phases.has("loading screen, no tower yet")})
	var veiled: Dictionary = phases.get("tower in the world, veil black", {})
	checks.append({"check": "NO FLASH: from the first frame in which the tower's scene exists until the veil begins to lift, no frame is brighter than black", "ok": not veiled.is_empty() and float(veiled.brightest) < 0.01
		and order.find("tower in the world, veil black") < order.find("veil lifting"), "frames_measured": veiled.get("frames", 0), "brightest_of_them": veiled.get("brightest", -1.0), "seconds_black_with_the_tower": veiled.get("seconds", 0.0)})
	var report: Dictionary = game.get_meta("opening_report", {}) if game != null else {}
	var opened: Dictionary = phases.get("in the crate", {})
	checks.append({"check": "in that black the visitor is put in the crate and the landing sounds; then the veil lifts onto the inside of the crate, by itself and not by the timer",
		"ok": sound_in_black and inside_at_sound and bool(report.get("inside_when_landed", false)) and not bool(report.get("gave_up", true)) and bool(report.get("sound_played", false))
		and not opened.is_empty() and float(opened.brightest) > 0.05, "report": report, "brightness_in_the_crate": opened.get("brightest", -1.0), "from_choice_to_sight_s": snappedf(seconds - open_for, 0.1)})
	result["passed"] = checks.all(func(c): return c.ok)
	_save()
	print("[opening_from_menu] ", "PASSED" if result.passed else "FAILED")
	quit()
