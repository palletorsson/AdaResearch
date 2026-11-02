extends Node3D
## THE BOARD VOCABULARY (Palle, 2026-10-31: "rectangular boards vertically, horizontal or rotated, repeatedly
## parameterised, to fit as pieces in the playground structure"). (A) a spec of three boards compiles through the place
## builder: a floor row of ten (the path of screens), five upright posters facing south, three hung overhead - eighteen
## plates at the right poses, framed by the kit's own bars, no errors; (B) the principal-places hall loads its sidecar
## (activities.json beside the approved recipe): the samples, the ball tests, the path and the posters all stand, and
## the frames' assemblies are in the loaded recipe; (C) the approved recipe file is untouched - no "activities" in it.
## Pictures of the framed path. ada_run/workstation/board_vocabulary.json.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_board_vocabulary.tscn

const Builder = preload("res://commons/modular/places/place_builder.gd")
const HALL = preload("res://commons/void/trials/principal_places/places.tscn")
const RECIPE := "res://commons/void/trials/principal_places/recipe.json"

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .7;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-55, 35, 0);sun.light_energy = 1.0;sun.shadow_enabled = true;add_child(sun)
	var cam := Camera3D.new();add_child(cam);cam.current = true;cam.fov = 55
	var report := {"checks": []}
	# A - compile
	var tile := "res://algorithms/shaders/book_of_shaders/patterns_tile.gdshader"
	var spec := {"version": 1, "units": "metres", "places": [], "boards": [
		{"id": "path", "at": [-18, 0, 0], "size": [3, 3], "orient": "floor", "repeat": {"count": 10, "step": [4, 0, 0]}, "content": {"content": "shader", "shader": tile, "params": {"grid_size": 6.0}}},
		{"id": "posters", "at": [-16, 0, 4], "size": [2, 2], "orient": "wall", "facing": "south", "repeat": {"count": 5, "step": [8, 0, 0]}, "contents": [{"content": "wallpaper", "wallpaper_group": 1}, {"content": "wallpaper", "wallpaper_group": 5}]},
		{"id": "canopy", "at": [0, 3, -6], "size": [4, 2], "orient": "ceiling", "repeat": {"count": 3, "step": [0, 0, -3], "turn": 90}, "content": {"content": "colour", "colour": "#2bd4a0"}}]}
	var built: Dictionary = Builder.new().compile(spec)
	var errs: Array = built.get("errors", []);var recipe: Dictionary = built.get("recipe", {})
	var acts: Array = recipe.get("activities", [])
	var path: Array = acts.filter(func(a): return a.board == "path");var posters: Array = acts.filter(func(a): return a.board == "posters");var canopy: Array = acts.filter(func(a): return a.board == "canopy")
	var path_ok: bool = path.size() == 10 and path.all(func(a): return is_equal_approx(float(a.position[1]), 0.08) and a.rotation == [0, 0.0, 0]) and is_equal_approx(float(path[9].position[0]) - float(path[0].position[0]), 36.0)
	var posters_ok: bool = posters.size() == 5 and posters.all(func(a): return a.config.mount == "wall" and is_equal_approx(float(a.position[1]), 0.0)) and posters[1].config.wallpaper_group == 5
	var canopy_ok: bool = canopy.size() == 3 and canopy.all(func(a): return is_equal_approx(float(a.rotation[0]), 180.0) and is_equal_approx(float(a.position[1]), 2.92)) and is_equal_approx(float(canopy[1].rotation[1]), 90.0) and canopy[1].config.slot_size == [4.0, 2.0]
	var framed: bool = recipe.get("assemblies", []).size() >= 10 * 4 + 5 * 4 + 3 * 8 and recipe.get("parts", []).size() > 0
	_check(report, "A compile: ten floor boards in a row, five upright posters, three hung and turned - eighteen plates posed and framed by bars, no errors", errs.is_empty() and path_ok and posters_ok and canopy_ok and framed, {"errors": errs, "path": path_ok, "posters": posters_ok, "canopy": canopy_ok, "assemblies": recipe.get("assemblies", []).size(), "parts": recipe.get("parts", []).size()})
	# C - the approved recipe file carries no activities
	var file_text := FileAccess.get_file_as_string(RECIPE);var file_recipe: Dictionary = JSON.parse_string(file_text)
	var approved_assemblies: int = file_recipe.get("assemblies", []).size()
	_check(report, "C approved: the hall's recipe.json carries no activities and no boards - the sidecar does", not file_recipe.has("activities") and not file_recipe.has("boards"), {"keys": file_recipe.keys()})
	# B - the hall from its sidecar
	var hall: Node3D = HALL.instantiate();add_child(hall)
	for i in 6:
		await get_tree().physics_frame
	var by_kind := {}
	for c in hall.get_children():
		if c.has_meta("activity_artifact"):
			var k: String = str(c.get_meta("activity_artifact"));by_kind[k] = by_kind.get(k, 0) + 1
	# floor 210 keeps what stands on the tower's slab; the boards moved to the ANNEX (2026-11-02), where they are framed
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/trials/principal_places/activities.json"))
	var want_plates: int = preload("res://commons/modular/places/board_builder.gd").copies(side)
	var annex_spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/playgrounds/halls/playground_annex.json"))
	var hall_ok: bool = by_kind.get("display_plate", 0) == want_plates and by_kind.get("pocket_test", 0) == 3 and by_kind.get("noise_space", 0) == 2 and by_kind.get("random_space", 0) == 1 and by_kind.get("sine_space_floor", 0) == 1 and hall.recipe.assemblies.size() >= approved_assemblies
	var hall_assemblies: int = hall.recipe.assemblies.size()
	hall.queue_free()
	var annex: Node3D = load("res://commons/void/trials/playground_recipes/spec_hall.tscn").instantiate();annex.set_meta("config_spec", "res://commons/data/playgrounds/halls/playground_annex.json");add_child(annex)
	for i in 6:
		await get_tree().physics_frame
	var annex_plates := 0
	for c in annex.get_children():
		if c.get_meta("activity_artifact", "") == "display_plate":annex_plates += 1
	var annex_want: int = preload("res://commons/modular/places/board_builder.gd").copies(annex_spec)
	hall_ok = hall_ok and annex_plates == annex_want and annex.recipe.assemblies.size() > annex_want
	_check(report, "B hall: floor 210 keeps its four samples and three ball tests; the boards stand framed in the annex", hall_ok, {"by_kind": by_kind, "assemblies": hall_assemblies, "approved": approved_assemblies, "annex_plates": annex_plates, "annex_want": annex_want})
	var shots := {"boards_path": [Vector3(-22, 1.7, 9), Vector3(0, 0.5, 10)], "boards_above": [Vector3(0, 12, 22), Vector3(0, 0.5, 10)]}
	for k in shots:
		cam.transform = Transform3D(Basis(), shots[k][0]).looking_at(shots[k][1])
		for t in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % k))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("board_vocabulary.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_board_vocabulary] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_board_vocabulary] %s  %s" % ["ok  " if ok else "FAIL", what])
