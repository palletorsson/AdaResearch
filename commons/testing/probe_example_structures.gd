extends Node3D
## THE EXAMPLE STRUCTURES (Palle, 2026-10-31: "add the element to example structures; show the same principle for tiling
## and pattern as well"). Every spec in commons/data/playgrounds/examples/ - path, array, corridor, canopy, court, rack,
## stack - compiles through the place builder with no errors into as many plates as its boards promise, framed; each
## stands alone in the hall's runtime scene (a preset recipe, no sidecar) and is photographed. Then the hall itself:
## from its sidecar it carries the shader path, the tiling corridor and the pattern rack beside the samples.
## Writes ada_run/workstation/example_structures.json and example_<name>.png.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_example_structures.tscn

const Builder = preload("res://commons/modular/places/place_builder.gd")
const Boards = preload("res://commons/modular/places/board_builder.gd")
const HALL = preload("res://commons/void/trials/principal_places/places.tscn")
const DIR := "res://commons/data/playgrounds/examples/"
const MAPS := "res://commons/data/playgrounds/maps/"

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .7;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-55, 35, 0);sun.light_energy = 1.0;sun.shadow_enabled = true;add_child(sun)
	var cam := Camera3D.new();add_child(cam);cam.current = true;cam.fov = 55
	var report := {"checks": [], "examples": {}}
	var dir := DirAccess.open(DIR);var names: Array[String] = []
	dir.list_dir_begin();var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):names.append(f.trim_suffix(".json"))
		f = dir.get_next()
	names.sort()
	var mdir := DirAccess.open(MAPS);var mnames: Array[String] = []
	mdir.list_dir_begin();var mf := mdir.get_next()
	while mf != "":
		if mf.ends_with(".json"):mnames.append(mf.trim_suffix(".json"))
		mf = mdir.get_next()
	mnames.sort()
	var runs: Array = []
	for n in names:runs.append([n, DIR, "example_"])
	for n in mnames:runs.append([n, MAPS, "map_"])
	for run in runs:
		var name: String = run[0];var folder: String = run[1];var prefix: String = run[2]
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + name + ".json"))
		var built: Dictionary = Builder.new().compile(spec);var errs: Array = built.get("errors", [])
		var recipe: Dictionary = built.get("recipe", {});var want := Boards.copies(spec)
		var acts: Array = recipe.get("activities", [])
		var scene: Node3D = HALL.instantiate();scene.recipe = recipe;add_child(scene)
		for i in 5:
			await get_tree().physics_frame
		var standing := 0
		for c in scene.get_children():
			if c.has_meta("activity_artifact"):standing += 1
		var framed: bool = recipe.get("assemblies", []).size() >= want * 4
		var ok: bool = errs.is_empty() and acts.size() == want and standing == want and framed
		report.examples[prefix + name] = {"plates": want, "standing": standing, "assemblies": recipe.get("assemblies", []).size(), "principle": spec.get("principle", "")}
		_check(report, "%s (%s): compiles clean into %d framed plates, all standing" % [name, spec.get("principle", ""), want], ok, {"errors": errs, "activities": acts.size(), "standing": standing, "assemblies": recipe.get("assemblies", []).size()})
		var look: Array = spec.get("camera", [[0, 10, 22], [0, 1, 0]])
		cam.transform = Transform3D(Basis(), Vector3(look[0][0], look[0][1], look[0][2])).looking_at(Vector3(look[1][0], look[1][1], look[1][2]))
		for t in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s%s.png" % [prefix, name]))
		scene.free()
		_save(out_dir, report)   # progress for the watchdog
	# the hall with its sidecar: the path, the tiling corridor and the pattern rack
	var side: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/trials/principal_places/activities.json"))
	var want_plates := Boards.copies(side) + (side.get("activities", []) as Array).filter(func(a): return a.artifact == "display_plate").size()
	var hall: Node3D = HALL.instantiate();add_child(hall)
	for i in 6:
		await get_tree().physics_frame
	var plates := 0
	for c in hall.get_children():
		if c.get_meta("activity_artifact", "") == "display_plate":plates += 1
	_check(report, "hall: from its sidecar the shader path, the tiling corridor and the pattern rack stand - %d display plates" % want_plates, plates == want_plates and want_plates > 50, {"plates": plates, "want": want_plates, "boards": (side.boards as Array).map(func(b): return b.id)})
	var shots := {"hall_corridor": [Vector3(-23, 2.0, -11), Vector3(0, 1.2, -11)], "hall_rack": [Vector3(16, 1.6, -3), Vector3(22, 1.5, -3)], "hall_all": [Vector3(0, 30, 34), Vector3(0, 0, -2)]}
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
	_save(out_dir, report)
	print("[probe_example_structures] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _save(out_dir: String, report: Dictionary) -> void:
	var o := FileAccess.open(out_dir.path_join("example_structures.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_example_structures] %s  %s" % ["ok  " if ok else "FAIL", what])
