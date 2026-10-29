extends SceneTree
## The three frames of reference at their defaults, side by side on a floor ruled every metre:
## CoordinateSystem3M (the frame you stand in), origin (the zero), xyz_coordinates (the frame you
## hold). In a window; writes ada_run/frames/frames.png and frames.json (each one's measured arms).
func _line(at: Vector3, size: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new();var b := BoxMesh.new();b.size = size;m.mesh = b;m.position = at
	var mat := StandardMaterial3D.new();mat.albedo_color = color;mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;m.material_override = mat;root.add_child(m)


func _init() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/frames");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("c9c4ba");e.ambient_light_energy = .7;env.environment = e;root.add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-55, 30, 0);root.add_child(sun)
	_line(Vector3(0, -.03, 0), Vector3(16, .05, 9), Color("8f8a84"))
	for x in range(-8, 9):_line(Vector3(x, .0, 0), Vector3(.012, .012, 9), Color("5d5a56"))   # a line every metre
	for z in range(-4, 5):_line(Vector3(0, .0, z), Vector3(16, .012, .012), Color("5d5a56"))
	var report := {}
	var frames := [["CoordinateSystem3M", "res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn", Vector3(-6, 0, -1)],
		["origin", "res://commons/primitives/origin/origin.tscn", Vector3(0, .5, 0)],
		["xyz_coordinates", "res://commons/context/XYZcoordinates/xyz_gadget.tscn", Vector3(3, 0, -1)]]
	var built := []
	for f in frames:
		var n: Node3D = load(f[1]).instantiate();n.position = f[2];root.add_child(n);built.append([f[0], n])
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(-.5, 6.5, 8.5)).looking_at(Vector3(-.5, .8, -.5));cam.fov = 60;root.add_child(cam);cam.current = true
	for i in 12:
		await process_frame
	for b in built:
		var n: Node3D = b[1];var box := AABB();var first := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null or not m.is_visible_in_tree():continue
			var a: AABB = m.global_transform * m.get_aabb()
			box = a if first else box.merge(a);first = false
		report[b[0]] = {"position": [n.global_position.x, n.global_position.y, n.global_position.z], "size": [snappedf(box.size.x, .01), snappedf(box.size.y, .01), snappedf(box.size.z, .01)]}
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("frames.png"))
	var f := FileAccess.open(out_dir.path_join("frames.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	quit(0)
