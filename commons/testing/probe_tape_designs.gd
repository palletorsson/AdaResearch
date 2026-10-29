extends SceneTree
## Tape designs (tapes.json) in Godot. `-- texels`: every design's tile as tape_design.gd paints it, to
## ada_run/tape_design/texels_gd.json, for tools/tape_design_check.ts (headless is enough). Otherwise,
## in a window: one roll per design laid as a strip on the floor and one span between two blocks,
## photographed to ada_run/tape_design/designs.png with ada_run/tape_design/designs.json.
const Design := preload("res://commons/artifacts/tape_roll/tape_design.gd")
const Strip := preload("res://commons/artifacts/tape_roll/strip.gd")


func _init() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/tape_design")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var tapes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Design.FILE)).tapes
	if "texels" in OS.get_cmdline_user_args():
		var dump := {}
		for id in tapes:
			var flat := PackedInt32Array()
			for y in Design.TILE_H:
				for x in Design.TILE_W:flat.append_array(Design.texel(tapes[id], x, y))
			dump[id] = Array(flat)
		var f := FileAccess.open(out_dir.path_join("texels_gd.json"), FileAccess.WRITE);f.store_string(JSON.stringify(dump));f.close()
		quit(0);return
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("c9c4ba");e.ambient_light_energy = .6;env.environment = e;root.add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-60, 25, 0);sun.light_energy = 1.2;root.add_child(sun)
	var floor_body := StaticBody3D.new();floor_body.name = "Floor";root.add_child(floor_body)
	var fm := MeshInstance3D.new();var fb := BoxMesh.new();fb.size = Vector3(5, .2, 4);fm.mesh = fb;fm.position.y = -.1
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_body.add_child(fm)
	var fs := CollisionShape3D.new();var fbs := BoxShape3D.new();fbs.size = fb.size;fs.shape = fbs;fs.position.y = -.1;floor_body.add_child(fs)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(0, 2.3, 2.6)).looking_at(Vector3(0, 0, -.3));cam.fov = 55;root.add_child(cam);cam.current = true
	var report := {}
	var i := 0
	for id in tapes:
		var roll: Node = load("res://commons/artifacts/tape_roll/roll.tscn").instantiate()
		roll.call("apply_grid_config", {"tape": id});roll.position = Vector3(2.2, .2, 1.2 - i * .3);root.add_child(roll)
		await process_frame
		var z := -1.3 + i * .55
		var a := {"collider": floor_body, "position": Vector3(-2.1, 0, z), "normal": Vector3.UP}
		var b := {"collider": floor_body, "position": Vector3(1.6, 0, z), "normal": Vector3.UP}
		var strip: Node3D = Strip.new();strip.name = "Tape_" + id;root.add_child(strip)
		strip.tape_width = roll.call("_width");strip.material_override = roll.get("tape_material")
		var anchors: Array[Dictionary] = [Strip.anchor(a), Strip.anchor(b)];strip.anchors = anchors
		strip.draw_between(a.position, a.normal, b.position, b.normal)
		if roll.call("_prints"):
			strip.print_source = roll.call("printer", strip, floor_body, floor_body, i + 1)
			strip.print_reader = cam.position;strip.print_reader_set = true
			strip.lay_print(a.position, a.normal, b.position, b.normal)
		report[id] = {"width": strip.tape_width, "prints": roll.call("_prints"), "printed": strip.get("printed"), "label": roll.get("design").get("label", "")}
		i += 1
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("designs.png"))
	var f := FileAccess.open(out_dir.path_join("designs.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()
	quit(0)
