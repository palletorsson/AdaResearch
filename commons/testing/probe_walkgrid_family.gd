extends Node3D
## THE WHOLE WALKGRID FAMILY IN A SLOT (Palle, 2026-10-31: "convert the whole walkgrid family; bump maps?"). Every
## TopologySpace subclass is made with the script alone, told a 10 x 8 m slot 1 m deep with a half-metre rim, and
## measured: (A) it fills the slot, lowest point on the floor, highest under the rim; (B) the rim is flat; the ones
## that are not heightfields over a rectangle (Mobius, torus, hyperbolic) are expected to fail the slot and are
## listed as self-sufficient, not counted. (C) BUMP: the noise space with bump_map on carries a normal map the size
## of its grid on its material; with collision_step 4 its trimesh has about a sixteenth of the faces of the look.
## Writes ada_run/workstation/walkgrid_family.json and a picture of the family in a row.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_walkgrid_family.tscn

const SELF_SUFFICIENT := ["MobiusSpace", "TorusSpace", "HyperbolicSpace"]

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var cam := Camera3D.new();add_child(cam);cam.current = true
	var report := {"checks": [], "self_sufficient": [], "fitted": []}
	var dir := DirAccess.open("res://commons/context/walkgrids/");var names: Array[String] = []
	dir.list_dir_begin();var f := dir.get_next()
	while f != "":
		if f.ends_with("Space.gd") and f != "TopologySpace.gd":names.append(f.trim_suffix(".gd"))
		f = dir.get_next()
	names.sort()
	var slot := {"slot_size": [10, 8], "slot_depth": 1.0, "slot_margin": 0.0, "rim_width": 0.5, "edge_band": 1.0}
	var i := 0
	for name in names:
		var t0 := Time.get_ticks_msec()
		var node := Node3D.new();node.set_script(load("res://commons/context/walkgrids/%s.gd" % name))
		for k in slot:node.set_meta("config_%s" % k, slot[k])
		node.set_meta("config_gravity_point_test", false)
		node.name = name;node.position = Vector3((i % 5) * 12.0 - 24.0, 0, int(i / 5) * 10.0 - 15.0);add_child(node)
		if node.has_method("apply_grid_config"):node.apply_grid_config(slot)
		for t in 4:
			await get_tree().physics_frame
		var mi: MeshInstance3D = node.get("mesh_instance")
		var ok_fit := false;var ok_rim := false;var data := {}
		if mi != null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			var box: AABB = mi.mesh.get_aabb()
			ok_fit = absf(box.size.x - 10.0) < .05 and absf(box.size.z - 8.0) < .05 and absf(box.position.y) < 1e-3 and box.end.y <= 0.9 + 1e-3
			var verts: PackedVector3Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var worst := 0.0;var rim_n := 0
			for v in verts:
				if absf(v.x) > 4.5 - 1e-3 or absf(v.z) > 3.5 - 1e-3:rim_n += 1;worst = maxf(worst, absf(v.y))
			ok_rim = rim_n > 100 and worst < 1e-3
			data = {"size": box.size, "low": box.position.y, "high": box.end.y, "rim_vertices": rim_n, "rim_worst": worst}
		else:data = {"mesh": false}
		data["seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
		if name in SELF_SUFFICIENT:
			report.self_sufficient.append({"name": name, "fits": ok_fit and ok_rim, "data": data})
		else:
			report.fitted.append(name)
			_check(report, "%s: fills the 10 x 8 slot on the floor under the rim, with a flat rim" % name, ok_fit and ok_rim, data)
		_save(out_dir, report)   # progress for the watchdog: the report grows after every surface
		i += 1
	# C - bump: the noise space shaded by a normal map, walked on a coarse trimesh
	var bump := Node3D.new();bump.set_script(load("res://commons/context/walkgrids/NoiseSpace.gd"))
	var bcfg := slot.duplicate();bcfg.bump_map = true;bcfg.collision_step = 4
	for k in bcfg:bump.set_meta("config_%s" % k, bcfg[k])
	bump.set_meta("config_gravity_point_test", false);bump.position = Vector3(0, 0, 30);add_child(bump);bump.apply_grid_config(bcfg)
	for t in 4:
		await get_tree().physics_frame
	var bmat := (bump.mesh_instance as MeshInstance3D).material_override as StandardMaterial3D
	var has_map: bool = bmat != null and bmat.normal_enabled and bmat.normal_texture != null and bmat.normal_texture.get_width() == bump.resolution + 1
	var shape: ConcavePolygonShape3D = bump.collision_shape.shape
	var faces_coarse: int = shape.get_faces().size() / 3;var faces_fine: int = bump.resolution * bump.resolution * 2
	var ratio: float = float(faces_coarse) / float(faces_fine)
	_check(report, "C bump: the noise space carries a normal map the size of its grid; collision_step 4 gives about a sixteenth of the faces", has_map and ratio < 0.08 and ratio > 0.04, {"map": has_map, "faces_fine": faces_fine, "faces_coarse": faces_coarse, "ratio": ratio})
	cam.transform = Transform3D(Basis(), Vector3(0, 26, 34)).looking_at(Vector3(0, 0, -2));cam.fov = 60
	for t in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("walkgrid_family.png"))
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	_save(out_dir, report)
	print("[probe_walkgrid_family] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _save(out_dir: String, report: Dictionary) -> void:
	var o := FileAccess.open(out_dir.path_join("walkgrid_family.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_walkgrid_family] %s  %s" % ["ok  " if ok else "FAIL", what])
