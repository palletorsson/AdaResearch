extends "res://tools/probes/void_game_probe.gd"
## Comprehensive automated + visual verification for the upgraded Bauhaus Studio Workstation:
##   1. Canonical BauhausKit part family (Monochrome vs Colour + collider identity)
##   2. Flat near-edge hand-principle template picking & single-trigger stamping (NO PartsArc!)
##   3. Live 1:4 glass-box mirroring + VR Visor 1:1 entry on F209 Primitives_Prefab_Library
##   4. Unified progression across real Void tower floors F1, F3, F5, F6, F7, and F209.

const Bauhaus = preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")
const Model = preload("res://commons/artifacts/scaffold_workstation/model.gd")
const RoomSource = preload("res://commons/void/room_source.gd")


func run() -> void:
	out = ProjectSettings.globalize_path("res://ada_run/studio_workstation")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)

	await _test_bauhaus_kit_and_console()
	await _test_tower_floors()

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)):
			failed += 1
	var report := {"passed": failed == 0, "failed": failed, "total": checks.size(), "checks": checks}
	var f := FileAccess.open(out.path_join("report.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
	print("[studio_workstation_probe] %d/%d passed" % [checks.size() - failed, checks.size()])
	quit(0 if failed == 0 else 1)


func _test_bauhaus_kit_and_console() -> void:
	# Clean studio lighting bench for Part 1 (Kit family) and Part 2 (Console interaction).
	var bench_root := Node3D.new()
	bench_root.name = "StudioBench"
	root.add_child(bench_root)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("52565d")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("e8e6e2")
	e.ambient_light_energy = 0.85
	env.environment = e
	bench_root.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 32, 0)
	sun.light_energy = 1.15
	bench_root.add_child(sun)

	var slab := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(36, 0.1, 36)
	slab.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color("6b6f76")
	smat.roughness = 0.85
	slab.material_override = smat
	slab.position.y = -0.05
	bench_root.add_child(slab)

	var cam := Camera3D.new()
	bench_root.add_child(cam)
	cam.make_current()

	# ── Part 1: Canonical BauhausKit family Monochrome vs Colour ──
	var kit_stage := Node3D.new()
	kit_stage.position = Vector3(-20, 0, 0)
	bench_root.add_child(kit_stage)
	var samples := [
		{"kind": "point", "at": [0, 0, 0]},
		{"kind": "rod_short", "at": [0, 0, 0], "end": [0, 0.5, 0]},
		{"kind": "rod", "at": [0, 0, 0], "end": [0, 1, 0]},
		{"kind": "diag", "at": [0, 0, 0], "end": [1, 0, 1]},
		{"kind": "panel", "at": [0, 0, 0], "plane": [0, 2], "half": 0},
		{"kind": "quad", "at": [0, 0, 0], "plane": [0, 2]},
		{"kind": "wedge", "at": [0, 0, 0], "turn": [0, 2, 0]},
		{"kind": "pyramid", "at": [0, 0, 0], "turn": [0, 0, 0]},
	]
	var shapes_match := true
	for row_idx in 2:
		var phase := "monochrome" if row_idx == 0 else "colour"
		for i in samples.size():
			var rec: Dictionary = samples[i]
			var vis := Bauhaus.visual(rec, 1.0, phase)
			vis.position = Vector3((i - 3.5) * 1.45, 0.45 if rec.kind in ["point", "rod", "rod_short", "diag"] else 0.08, (row_idx - 0.5) * 2.1)
			if rec.kind == "diag":
				vis.rotation = Vector3(0, 0, deg_to_rad(45.0))
			kit_stage.add_child(vis)
			if row_idx == 0:
				var s_m := Bauhaus.shape_for(rec, 2.0).get_debug_mesh().get_aabb()
				var s_c := Bauhaus.shape_for(rec, 2.0).get_debug_mesh().get_aabb()
				if not s_m.is_equal_approx(s_c):
					shapes_match = false
	check("1A BauhausKit builds all 8 primitives cleanly in monochrome & colour with identical colliders",
		kit_stage.get_child_count() == 16 and shapes_match)

	cam.fov = 46.0
	cam.global_position = kit_stage.global_position + Vector3(0.0, 4.6, 8.2)
	cam.look_at(kit_stage.global_position + Vector3(0.0, 0.3, 0.0), Vector3.UP)
	await frames(24)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("01-bauhaus-kit-mono-vs-colour.png"))

	# ── Part 2: Standalone Studio Workstation Console & Single-Trigger Stamping ──
	var quads_scene: PackedScene = load("res://commons/artifacts/scaffold_workstation/quads.tscn")
	var ws: Node3D = quads_scene.instantiate()
	ws.set_meta("config_persist", false)
	ws.set_meta("config_studio", true)
	ws.set_meta("config_space_floor", 7)
	ws.set_meta("config_palette", "bauhaus")
	bench_root.add_child(ws)
	await frames(8)

	var st: Node3D = ws.get("studio_ctrl")
	var legacy_arc_visible := false
	var arc_node: Node = ws.get("bench").get_node_or_null("PartsArc")
	if arc_node != null and arc_node.is_visible_in_tree():
		legacy_arc_visible = true
	var pc: Node = ws.get("place_controls")
	var place_vis: bool = pc != null and pc.is_visible_in_tree()
	check("2A Studio mode active, PartsArc hidden, PlaceParameters hidden, 8 flat tiles built",
		st != null and not legacy_arc_visible and not place_vis and st.tile_nodes.size() == 8)

	# Verify expanded 20 m x 14 m domain!
	var dom_span: Vector3 = (ws.model.domain_max - ws.model.domain_min) * Model.WORLD_STEP
	check("2B Expanded playground domain is 20m x 14m x 6m (matching Trans_Pre & motion/revolving)",
		is_equal_approx(dom_span.x, 20.0) and is_equal_approx(dom_span.z, 14.0) and is_equal_approx(dom_span.y, 6.0))

	# Test single-trigger tile picking + single-trigger stamping via aim node!
	var aim := Node3D.new()
	bench_root.add_child(aim)
	# Clear starter study first to test clean from-scratch stamping.
	st.clear_playground()
	var empty_count: int = ws.model.records.size()

	# Aim at QUAD tile on flat near-edge strip and pull trigger once.
	var quad_tile_pos: Vector3 = (st.tile_nodes["quad"].root as Node3D).global_position
	aim.global_position = quad_tile_pos + Vector3(0, 0.55, 0.55)
	aim.look_at(quad_tile_pos, Vector3.UP)
	var pick_res: String = ws.space_press(aim, null)
	check("2C Aiming at flat QUAD tile + single trigger selects 'quad' (res=%s, active=%s)" % [pick_res, st.active_tool],
		pick_res == "selected" and st.active_tool == "quad")

	# Raise drafting level to 1 M and aim at grid cell (-2.5, 0.5, -1.5) -> preview ghost & capture close-up!
	st.cycle_level()
	var target_pad: Vector3 = st.mini_root.to_global(Vector3(-2.5, 0.5, -1.5) * st.MINI_UNIT)
	aim.global_position = target_pad + Vector3(0, 0.72, 0.72)
	aim.look_at(target_pad, Vector3.UP)
	ws.space_update(aim, null)
	var ghost_ok: bool = st.hover_state.has("stamp") and st.mini_ghost.get_child_count() > 0

	# Capture close-up of the uncluttered Bauhaus console, flat template strip, mini grid & live ghost!
	cam.fov = 50.0
	cam.global_position = Vector3(0.0, 1.98, 1.48)
	cam.look_at(Vector3(-0.08, 1.02, 0.02), Vector3.UP)
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("02-console-closeup-ghost.png"))

	# Single trigger stamps the elevated 2x2m Bauhaus quad + legs + perimeter rods!
	var stamp_quad: String = ws.space_press(aim, null)
	var after_quad: int = ws.model.records.size()
	var perf: Dictionary = st.get_vr_perf_stats()
	var col_cnt: int = int(perf.get("structure_colliders", 0))
	var phys_bodies: int = int(perf.get("structure_physics_bodies", 0))
	var glass_dcs: int = int(perf.get("glass_draw_calls", 999))
	check("2D Single trigger stamps elevated 2x2m Bauhaus quad atomically (%d -> %d records, %d colliders in %d compound body, %d draw calls)" % [empty_count, after_quad, col_cnt, phys_bodies, glass_dcs],
		ghost_ok and stamp_quad == "placed" and after_quad > empty_count and col_cnt >= after_quad and phys_bodies == 1 and glass_dcs <= 12)

	# Switch back to LEVEL 0M, select WEDGE tile with 1 trigger, stamp ramp cleanly!
	st.cycle_level(); st.cycle_level()  # 1M -> 2M -> 0M
	var wedge_tile_pos: Vector3 = (st.tile_nodes["wedge"].root as Node3D).global_position
	aim.global_position = wedge_tile_pos + Vector3(0, 0.55, 0.55)
	aim.look_at(wedge_tile_pos, Vector3.UP)
	ws.space_press(aim, null)
	var ramp_target: Vector3 = st.mini_root.to_global(Vector3(-2.5, 0.0, 0.5) * st.MINI_UNIT)
	aim.global_position = ramp_target + Vector3(0, 0.72, 0.72)
	aim.look_at(ramp_target, Vector3.UP)
	var stamp_wedge: String = ws.space_press(aim, null)
	var after_wedge: int = ws.model.records.size()
	check("2E Selecting WEDGE tile + single trigger stamps Bauhaus ramp (%d -> %d records)" % [after_quad, after_wedge],
		stamp_wedge == "placed" and after_wedge == after_quad + 1)

	# UNDO reverses the stamped wedge cleanly.
	ws.undo(); ws.redraw()
	check("2F UNDO cleanly reverses the last stamped template (%d -> %d records)" % [after_wedge, ws.model.records.size()],
		ws.model.records.size() == after_quad)

	# 2G: Upward +Y point stacking when aiming at an existing point (both pad repeat-click & direct 3D point aim, up to 6 m ceiling)!
	var pt_tile_pos: Vector3 = (st.tile_nodes["point"].root as Node3D).global_position
	aim.global_position = pt_tile_pos + Vector3(0, 0.55, 0.55)
	aim.look_at(pt_tile_pos, Vector3.UP)
	ws.space_press(aim, null)
	var col_base := Vector3(1.5, 0.0, 1.0)
	var col_pad: Vector3 = st.mini_root.to_global(col_base * st.MINI_UNIT)
	aim.global_position = col_pad + Vector3(0, 0.72, 0.72)
	aim.look_at(col_pad, Vector3.UP)
	var r0: String = ws.space_press(aim, null)   # y = 0.0 (0 m)
	var r1: String = ws.space_press(aim, null)   # y = 0.5 (1 m) via same pad spot
	# Now aim directly at the elevated 3D point at y = 0.5 -> should preview & place y = 1.0 (2 m) with stack_from!
	var elevated_pt: Vector3 = st.mini_root.to_global(Vector3(1.5, 0.5, 1.0) * st.MINI_UNIT)
	aim.global_position = elevated_pt + Vector3(0, 0.45, 0.65)
	aim.look_at(elevated_pt, Vector3.UP)
	ws.space_update(aim, null)
	var has_stack_cue: bool = st.hover_state.has("stack_from") and is_equal_approx(float(st.hover_state.get("stamp_y", -1.0)), 1.0) and st.mini_ghost.get_node_or_null("UpwardGuideStem") != null

	# Capture close-up showing the +Y stacked column + amber upward ghost + vertical guide stem!
	cam.fov = 48.0
	cam.global_position = Vector3(0.45, 1.65, 0.92)
	cam.look_at(st.mini_root.to_global(Vector3(1.5, 0.7, 1.0) * st.MINI_UNIT), Vector3.UP)
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("02b-point-stack-upward-y.png"))

	var r2: String = ws.space_press(aim, null)   # y = 1.0 (2 m)
	# Keep stacking all the way to DOMAIN_MAX.y (3.0 = 6 m), then verify ceiling stops cleanly!
	var r3: String = ws.space_press(aim, null)   # 1.5
	var r4: String = ws.space_press(aim, null)   # 2.0
	var r5: String = ws.space_press(aim, null)   # 2.5
	var r6: String = ws.space_press(aim, null)   # 3.0 (6 m ceiling)
	var r7: String = ws.space_press(aim, null)   # full -> "" (refused cleanly)
	var pts_map: Dictionary = ws.model.points()
	var stacked_all := true
	for sy in [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]:
		if not pts_map.has(Model.key(Vector3(1.5, sy, 1.0))):
			stacked_all = false
	check("2G Point tool stacks upwards along +Y on existing points (0m..6m, stem cue=%s, ceiling stop='%s')" % [str(has_stack_cue), r7],
		r0 == "placed" and r1 == "placed" and r2 == "placed" and r3 == "placed" and r4 == "placed" and r5 == "placed" and r6 == "placed" and r7 == "" and has_stack_cue and stacked_all)

	bench_root.free()
	await frames(4)


func _test_tower_floors() -> void:
	Engine.physics_ticks_per_second = 90
	RoomSource.use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = 209
	game = load("res://commons/void/void.tscn").instantiate()
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
	await frames(50)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	# ── Part 3: Live F209 Primitives_Prefab_Library + VR Visor 1:1 Step-In! ──
	game.place_player(game.spawn_for(209))
	await frames(40)
	var f209_root: Node3D = game.building.content.roots.get(209, null)
	var ws209_mount: Node3D = f209_root.find_child("construction-stock", true, false) if f209_root != null else null
	var ws209: Node3D = _find_with_prop(ws209_mount, "studio_ctrl")
	var st209: Node3D = ws209.get("studio_ctrl") if ws209 != null else null
	var wb209: Node = st209.get("worker_unit").get_node_or_null("WorkerBeing") if st209 != null else null
	var wb209_parts: Array = wb209.get("parts") if wb209 != null else []
	check("3A F209 Primitives_Prefab_Library construction-stock spawned in Bauhaus Studio mode (phase=%s, worker_parts=%d)" % [
		st209.effective_phase() if st209 != null else "", wb209_parts.size()],
		ws209 != null and st209 != null and bool(ws209.get("studio")) and st209.effective_phase() in ["colour", "bauhaus"] and wb209_parts.size() >= 3)

	var cam := Camera3D.new()
	root.add_child(cam)
	cam.make_current()

	if ws209 != null and st209 != null:
		# Framing both F209's stock plinths, the humanoid work unit, the drafting console, and the 1:4 colour glass box!
		var w_pos: Vector3 = ws209.global_position
		cam.fov = 56.0
		cam.global_position = w_pos + Vector3(-4.8, 2.55, 4.1)
		cam.look_at(w_pos + Vector3(1.0, 1.25, -0.35), Vector3.UP)
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("03-f209-studio-overview.png"))

		# Enter VR Visor at 1:4 scale -> verify 1:1 playground scale & capture eye-level view from START!
		var entered: bool = ws209.visit.enter()
		await frames(10)
		var body_scale: float = float(game.body.get_meta("ada_body_scale", 1.0))
		var inside_ok: bool = entered and ws209.visit.active and is_equal_approx(body_scale, 0.25) and is_equal_approx(ws209.output_unit(), 0.5)
		check("3B Wearing F209 VR Visor enters glass box at exact 1:4 scale (body_scale=%.2f, unit=%.2f -> 1:1 20x14m playground)" % [body_scale, ws209.output_unit()],
			inside_ok)

		# Photograph from the shrunken 1/4-scale visitor's eye position inside the glass box!
		game.camera.make_current()
		game.camera.fov = 64.0
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-vr-inside-1to1.png"))

		ws209.visit.restore()
		await frames(8)
		check("3C Taking off VR Visor cleanly restores visitor scale & position",
			not ws209.visit.active and not game.body.has_meta("ada_scale_owner"))

	# ── Part 4: Progression Floors F1, F3, F5, F6, F7 in the Real Void Tower ──
	var floor_specs := [
		{"floor": 1, "name": "Point_One", "unlocked": 2, "worker": "Point_One", "file": "05-f01-point-one.png"},
		{"floor": 3, "name": "Point_Lines", "unlocked": 4, "worker": "Point_Lines", "file": "06-f03-point-lines.png"},
		{"floor": 5, "name": "Point_Triangle_Context", "unlocked": 5, "worker": "Point_Triangle_Context", "file": "07-f05-triangle.png"},
		{"floor": 6, "name": "Primitives_Polythedra", "unlocked": 7, "worker": "Primitives_Polythedra", "file": "08-f06-polyhedra.png"},
		{"floor": 7, "name": "Point_Animatedcube", "unlocked": 8, "worker": "Point_Animatedcube", "file": "09-f07-animatedcube.png"},
	]
	cam.make_current()
	for spec in floor_specs:
		var fl: int = int(spec.floor)
		game.place_player(game.spawn_for(fl))
		await frames(40)
		var fl_root: Node3D = game.building.content.roots.get(fl, null)
		var mount: Node3D = fl_root.find_child("scaffold-workstation", true, false) if fl_root != null else null
		var ws: Node3D = _find_with_prop(mount, "studio_ctrl")
		var st: Node3D = ws.get("studio_ctrl") if ws != null else null
		var unlocked_count := 0
		var worker_stage := ""
		var phase := ""
		var ch_h := 0.0
		if st != null:
			for info in st.tile_nodes.values():
				if bool(info.unlocked):
					unlocked_count += 1
			var wb: Node = st.get("worker_unit").get_node_or_null("WorkerBeing")
			if wb != null:
				worker_stage = str(wb.get("stage"))
			phase = st.effective_phase()
			ch_h = float(ws.get("chamber_height"))
		check("4-F%02d %s Studio Workstation unlocked=%d/%d, worker=%s, phase=%s, height=%.1fm" % [fl, spec.name, unlocked_count, int(spec.unlocked), worker_stage, phase, ch_h],
			st != null and unlocked_count == int(spec.unlocked) and worker_stage == str(spec.worker) and phase == "monochrome" and ch_h <= 5.45)

		if ws != null:
			cam.fov = 58.0
			# Stand cleanly inside the clear approach promenade between vending machines and console!
			cam.global_position = ws.to_global(Vector3(-1.85, 2.15, 2.35))
			cam.look_at(ws.to_global(Vector3(-0.15, 1.15, -1.8)), Vector3.UP)
			await frames(8)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join(str(spec.file)))

	cam.queue_free()


func _find_with_prop(node: Node, prop: String) -> Node3D:
	if node == null:
		return null
	if node is Node3D and node.get(prop) != null:
		return node
	for c in node.get_children():
		var hit := _find_with_prop(c, prop)
		if hit != null:
			return hit
	return null
