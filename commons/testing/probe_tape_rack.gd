extends Node3D
## The tape station with its rack (the printed roll and the tapes.json designs), as floor 3 builds it,
## in a scene so the XR Tools rolls compile as in the game. Photographs it and reports the rolls the
## station manages. Writes ada_run/tape_rack/{rack.png, report.json}.
func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/tape_rack");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-35, 15, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_m := MeshInstance3D.new();var fb := BoxMesh.new();fb.size = Vector3(8, .1, 6);floor_m.mesh = fb;floor_m.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");floor_m.material_override = fmat;add_child(floor_m)
	var station: Node3D = load("res://commons/artifacts/tape_roll/station.tscn").instantiate();add_child(station)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(.6, 1.55, 3.0)).looking_at(Vector3(.6, 1.0, 0));cam.fov = 55;add_child(cam);cam.current = true
	for i in 40:
		await get_tree().process_frame
	var rolls := []
	for r in station.get("rolls"):
		rolls.append({"name": str(r.name), "kind": r.get("kind"), "tape": r.get("tape"), "width": r.call("_width"), "prints": r.call("_prints"), "home": (station.get("home_poses") as Dictionary).has(str(r.name))})
	var report := {"rolls": rolls, "parts_the_editor_knows": (station.get("part_defaults") as Dictionary).keys().size()}
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("rack.png"))
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	get_tree().quit(0)
