extends SceneTree
## Live Godot 4.6 verification & visual inspection probe for the Worker Form &
## Endless Museum Dream-Body Assemblage System (around Playground Workbenches
## and across the Void Tower).

const OUT_DIR := "res://doc/book/iterations/2026-11-22-worker-assemblage"

var _results: Array[Dictionary] = []
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool, detail: String = "") -> void:
	var tag := "PASS" if ok else "FAIL"
	if not ok:
		_failed += 1
	var line := "[%s] %s%s" % [tag, label, (" — " + detail) if not detail.is_empty() else ""]
	print(line)
	_results.append({"label": label, "ok": ok, "detail": detail})


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(cam: Camera3D, pos: Vector3, look: Vector3, filename: String) -> void:
	cam.current = true
	cam.global_position = pos
	cam.look_at(look, Vector3.UP)
	await _frames(6)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	var full: String = ProjectSettings.globalize_path(OUT_DIR + "/" + filename)
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	img.save_png(full)
	print("SHOT ", filename, " bytes=", FileAccess.get_file_as_bytes(full).size())


func _max_saturation_in(node: Node) -> float:
	var best := 0.0
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m == null or not m.visible:
			continue
		var mat: Material = m.material_override
		if mat == null and m.mesh != null and m.mesh.get_surface_count() > 0:
			mat = m.get_surface_override_material(0)
			if mat == null:
				mat = m.mesh.surface_get_material(0)
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			var c: Color = sm.albedo_color
			var sat: float = maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
			best = maxf(best, sat)
			if sm.albedo_texture != null:
				var img: Image = sm.albedo_texture.get_image()
				if img != null and not img.is_empty():
					var w: int = img.get_width()
					var h: int = img.get_height()
					for sy in range(0, h, maxi(1, h / 8)):
						for sx in range(0, w, maxi(1, w / 8)):
							var pc: Color = img.get_pixel(sx, sy)
							var ps: float = maxf(pc.r, maxf(pc.g, pc.b)) - minf(pc.r, minf(pc.g, pc.b))
							best = maxf(best, ps)
	return best


func _sculpture_min_y(sc: Node3D) -> float:
	var low := INF
	for mi in sc.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m != null and m.mesh != null:
			var aabb: AABB = m.global_transform * m.mesh.get_aabb()
			low = minf(low, aabb.position.y)
	return low


func _run() -> void:
	var abs_out := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_out)

	var AssemScene: PackedScene = load("res://commons/artifacts/worker_assemblage/worker_assemblage.tscn")
	_check("0A WorkerAssemblage scene loads cleanly", AssemScene != null)

	# ── PART A: Standalone Formations Contact Sheet & Automated Assertions ──
	var stage := Node3D.new()
	stage.name = "AssemblageStage"
	root.add_child(stage)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("e8eaee")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f4f5f7")
	env.ambient_light_energy = 0.85
	env_node.environment = env
	stage.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	stage.add_child(sun)

	var floor_mi := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(24, 0.2, 14)
	floor_mi.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color("d8dce2")
	fmat.roughness = 0.85
	floor_mi.material_override = fmat
	floor_mi.position = Vector3(0, -0.1, 0)
	stage.add_child(floor_mi)

	var specs := [
		{"name": "Solo_F3_Mono", "x": -4.6, "cfg": {"floor": 3, "formation": "solo", "figure": "asawa_wire", "monochrome": "auto", "interactive": false}},
		{"name": "Dyad_F7_Mono", "x": -2.1, "cfg": {"floor": 7, "formation": "dyad", "figure": "stijl_robot", "monochrome": "auto", "interactive": true}},
		{"name": "Trio_F19_Mono", "x": 1.1, "cfg": {"floor": 19, "formation": "trio", "figure": "hadid_shell", "secondary_figure": "pierced_screen", "monochrome": "auto", "interactive": false}},
		{"name": "Assemblage_F209_Color", "x": 4.5, "cfg": {"floor": 209, "formation": "assemblage", "figure": "stijl_robot", "secondary_figure": "asawa_wire", "palette": "bauhaus", "monochrome": "auto", "interactive": true}},
	]

	var instances: Dictionary = {}
	for sp in specs:
		var inst := AssemScene.instantiate() as Node3D
		inst.name = str(sp.name)
		inst.position = Vector3(float(sp.x), 0.0, 0.0)
		inst.call("apply_grid_config", sp.cfg)
		stage.add_child(inst)
		instances[sp.name] = inst

	var cam := Camera3D.new()
	cam.fov = 46.0
	stage.add_child(cam)
	await _frames(24)
	await RenderingServer.frame_post_draw

	# Verify mesh counts, grounding flush to plinth top, and Concept Order #1 monochrome vs colour!
	for sp in specs:
		var inst: Node3D = instances[sp.name]
		var meshes := inst.find_children("*", "MeshInstance3D", true, false).size()
		var sc: Node3D = inst.find_child("PrimarySculpture", true, false) as Node3D
		var min_y: float = _sculpture_min_y(sc) if sc != null else -99.0
		var st: Dictionary = inst.call("get_state")
		var sat: float = _max_saturation_in(sc) if sc != null else 1.0
		var expect_mono: bool = bool(st.get("monochrome", false))
		var expected_plinth_y: float = 0.124 if str(sp.cfg.formation) == "assemblage" else 0.088
		var grounded_ok: bool = absf(min_y - expected_plinth_y) < 0.06
		var color_ok: bool = (sat < 0.06) if expect_mono else (sat > 0.30)
		_check("1-%s built=%d meshes, grounded_y=%.3f (exp %.3f), sat=%.3f (mono=%s)" % [sp.name, meshes, min_y, expected_plinth_y, sat, str(expect_mono)],
			meshes > 25 and grounded_ok and color_ok)

	await _shot(cam, Vector3(0.0, 2.35, 8.8), Vector3(0.0, 1.10, 0.0), "01-assemblage-formations-lineup.png")

	# Interactive API test on Assemblage_F209_Color: cycle_figure, cycle_axis, cycle_formation, set_palette_mode!
	var a209: Node3D = instances["Assemblage_F209_Color"]
	var st0: Dictionary = a209.call("get_state")
	a209.call("cycle_figure", 1)
	await _frames(4)
	var st1: Dictionary = a209.call("get_state")
	a209.call("cycle_axis")
	await _frames(4)
	var st2: Dictionary = a209.call("get_state")
	a209.call("set_palette_mode", "monochrome")
	await _frames(4)
	var sc_mono: Node3D = a209.find_child("PrimarySculpture", true, false) as Node3D
	var sat_after_mono: float = _max_saturation_in(sc_mono) if sc_mono != null else 1.0
	a209.call("set_palette_mode", "queer")
	await _frames(4)
	var st3: Dictionary = a209.call("get_state")
	_check("2A Interactive FORM / AXIS / PALETTE transitions",
		str(st1.primary_figure) != str(st0.primary_figure)
		and int(st2.axis_step) == 1
		and sat_after_mono < 0.06
		and not bool(st3.monochrome)
		and str(st3.palette) == "queer",
		"fig %s->%s, mono_sat=%.3f, pal=%s" % [st0.primary_figure, st1.primary_figure, sat_after_mono, st3.palette])

	stage.queue_free()
	await _frames(6)

	# ── PART B: Live Void Tower Verification (Around Workbenches + Curated Spine Floors) ──
	Engine.physics_ticks_per_second = 90
	load("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = 209
	var game: Node = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = false
	root.add_child(game)
	current_scene = game
	game.scene_loaded()
	game.scene_visible()
	game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	if game.get("soundscape") != null:
		game.soundscape.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(45)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	var content: Node = game.building.content
	var building: Node3D = game.building
	var vcam := Camera3D.new()
	vcam.fov = 52.0
	vcam.far = 160.0
	root.add_child(vcam)

	# Helper to inspect a floor and shoot a clean photo.
	var floors_to_check := [
		{"floor": 209, "id": "worker-assemblage-atelier", "kind": "monument", "file": "09-f209-atelier-monument.png", "cam_local": Vector3(0.3, 1.90, 3.8), "look_local": Vector3(0.0, 1.08, 0.0), "expect_mono": false},
		{"floor": 1, "id": "scaffold-workstation", "kind": "workbench", "file": "02-f01-workbench-assemblage-mono.png", "cam_local": Vector3(-1.3, 2.05, 3.7), "look_local": Vector3(-1.2, 1.05, -0.35), "expect_mono": true},
		{"floor": 7, "id": "scaffold-workstation", "kind": "workbench_assem", "file": "03-f07-workbench-assemblage-mono.png", "cam_local": Vector3(-2.6, 2.05, 3.3), "look_local": Vector3(-1.1, 1.05, -0.35), "expect_mono": true},
		{"floor": 13, "id": "worker-assemblage-trans-pre", "kind": "monument", "file": "04-f13-trans-pre-monument.png", "cam_local": Vector3(0.4, 1.90, 3.6), "look_local": Vector3(0.0, 1.08, 0.0), "expect_mono": true},
		{"floor": 19, "id": "worker-assemblage-trans-body", "kind": "monument", "file": "05-f19-trans-body-trio.png", "cam_local": Vector3(0.0, 1.95, 4.6), "look_local": Vector3(0.0, 1.05, 0.0), "expect_mono": true},
		{"floor": 28, "id": "worker-assemblage-color-arrival", "kind": "monument", "file": "06-f28-color-arrival-dyad.png", "cam_local": Vector3(0.0, 1.85, 3.6), "look_local": Vector3(0.0, 1.05, 0.0), "expect_mono": false},
		{"floor": 33, "id": "scaffold-workstation", "kind": "workbench_color", "file": "07-f33-workbench-color-trio.png", "cam_local": Vector3(0.0, 2.35, 4.8), "look_local": Vector3(0.0, 1.05, -0.35), "expect_mono": false},
	]

	for spec in floors_to_check:
		var fl: int = int(spec.floor)
		game.place_player(game.spawn_for(fl))
		content.call("load_floor", fl, true)
		await _frames(16)
		var fl_root: Node3D = content.roots[fl]
		var mount: Node3D = fl_root.get_node_or_null(str(spec.id))
		var art: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if art == null:
			_check("3-F%03d %s loaded" % [fl, str(spec.id)], false, "Artifact missing")
			continue

		var assem: Node3D = null
		if str(spec.kind).begins_with("workbench"):
			var st_ctrl: Node3D = art.get("studio_ctrl") as Node3D
			assem = st_ctrl.get("worker_assemblage") as Node3D if st_ctrl != null else null
			if str(spec.kind) == "workbench_assem" and assem != null:
				assem.call("cycle_formation")   # dyad -> assemblage right beside F7 workbench!
				await _frames(5)
			elif str(spec.kind) == "workbench_color" and assem != null:
				assem.call("cycle_formation")   # dyad -> assemblage
				assem.call("cycle_formation")   # assemblage -> trio (flanks BOTH pockets of F33 workbench!)
				await _frames(5)
		else:
			assem = art

		var st_info: Dictionary = assem.call("get_state") if assem != null else {}
		var sc: Node3D = assem.find_child("PrimarySculpture", true, false) as Node3D if assem != null else null
		var sat: float = _max_saturation_in(sc) if sc != null else -1.0
		var mono_ok: bool = (bool(st_info.get("monochrome", false)) == bool(spec.expect_mono))
		var sat_ok: bool = (sat >= 0.0 and sat < 0.06) if bool(spec.expect_mono) else (sat > 0.25)
		_check("3-F%03d %s (%s) fig=%s sub=%s mono=%s sat=%.3f" % [
			fl, str(spec.id), str(spec.kind), str(st_info.get("primary_figure", "?")),
			str(st_info.get("submode", "?")), str(st_info.get("monochrome", "?")), sat],
			assem != null and sc != null and mono_ok and sat_ok)

		var c_pos: Vector3 = mount.to_global(spec.cam_local)
		var c_look: Vector3 = mount.to_global(spec.look_local)
		await _shot(vcam, c_pos, c_look, str(spec.file))

		# On F33, also test live Palette Chooser -> MONO synchronization!
		if fl == 33 and str(spec.kind) == "workbench_color":
			var st33: Node3D = art.get("studio_ctrl") as Node3D
			st33.call("select_palette", "monochrome")
			await _frames(6)
			var sc33_mono: Node3D = assem.find_child("PrimarySculpture", true, false) as Node3D
			var sat33_mono: float = _max_saturation_in(sc33_mono) if sc33_mono != null else 1.0
			_check("3-F033 Palette Chooser -> MONO syncs companion DreamBodies to monochrome (sat=%.3f)" % sat33_mono,
				sat33_mono < 0.06 and bool((assem.call("get_state") as Dictionary).get("monochrome", false)))
			await _shot(vcam, c_pos, c_look, "08-f33-workbench-palette-mono-sync.png")
			st33.call("select_palette", "bauhaus")
			await _frames(4)

	# Extra wide shot on F209 showing BOTH the clean atelier monument [2.8, 0.6] and the Studio Workbench!
	game.place_player(game.spawn_for(209))
	await _frames(10)
	var f209_y: float = float(building.spec.levels[209])
	await _shot(vcam, Vector3(-1.2, f209_y + 2.55, 5.2), Vector3(8.5, f209_y + 1.25, 0.2), "10-f209-atelier-wide-with-workbench.png")

	var report := {
		"passed": _results.size() - _failed,
		"failed": _failed,
		"total": _results.size(),
		"checks": _results,
	}
	var rep_path := ProjectSettings.globalize_path(OUT_DIR + "/report.json")
	var rf := FileAccess.open(rep_path, FileAccess.WRITE)
	if rf != null:
		rf.store_string(JSON.stringify(report, "\t"))
		rf.close()

	print("SUMMARY: %d/%d PASS, %d FAIL" % [report.passed, report.total, report.failed])
	quit(0 if _failed == 0 else 1)
