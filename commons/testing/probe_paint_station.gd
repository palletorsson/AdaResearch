extends Node3D
## paint_station in a window: coats poured through the station's own coat()/coat_body() (what a held
## tin or jar calls), then photographed. A scene (probe_paint_station.tscn), so the project's autoloads are up
## and the kit's XR Tools pickables compile as they do in the game. Writes ada_run/paint_station/{paint.png, report.json}.
func _ready() -> void:
	var root := self
	var out_dir := ProjectSettings.globalize_path("res://ada_run/paint_station");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .7;env.environment = e;root.add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-35, 20, 0);sun.light_energy = 1.1;root.add_child(sun)
	var floor_m := MeshInstance3D.new();var fb := BoxMesh.new();fb.size = Vector3(8, .1, 6);floor_m.mesh = fb;floor_m.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");floor_m.material_override = fmat;root.add_child(floor_m)
	var st: Node3D = load("res://commons/artifacts/paint_buckets/paint_station.tscn").instantiate();root.add_child(st)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(0, 1.75, 4.3)).looking_at(Vector3(0, 1.3, 0));cam.fov = 52;root.add_child(cam);cam.current = true
	for i in 3:
		await get_tree().process_frame
	var red := Color("d63a2f");var cyan := Color("00a6d6");var yellow := Color("f2d000");var magenta := Color("d6248f")
	var hit_by_body: bool = st.call("coat_body", st.get("panels")[0].node, red, "cover", "RED")   # through the lookup a tin's aim uses
	st.call("coat", 1, red, "cover", "RED");st.call("coat", 1, red, "cover", "RED")
	st.call("coat", 2, cyan, "glaze", "CYAN")
	var white := Color("f4f0e6")
	for pair in [[3, cyan, "CYAN", yellow, "YELLOW"], [4, magenta, "MAGENTA", yellow, "YELLOW"], [5, cyan, "CYAN", magenta, "MAGENTA"]]:   # over a white ground, as a painter would
		st.call("coat", pair[0], white, "cover", "WHITE");st.call("coat", pair[0], white, "cover", "WHITE")
		st.call("coat", pair[0], pair[1], "glaze", pair[2]);st.call("coat", pair[0], pair[3], "glaze", pair[4])
	var report := {"coat_body_found_the_panel": hit_by_body, "panels": []}
	for i in 6:
		var c: Color = st.call("shown", i)
		report["panels"].append({"panel": i + 1, "coats": st.get("panels")[i].coats, "shown": c.to_html(false), "named": st.call("colour_name", c)})
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("paint.png"))
	var f := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	get_tree().quit(0)
