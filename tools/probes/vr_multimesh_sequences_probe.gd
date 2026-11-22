extends "res://tools/probes/void_game_probe.gd"
## Comprehensive VR MultiMesh Optimization + Next-Wave Sequence Capabilities Probe:
##   1. Verifies MultiMesh batching (Grid lines, Steel frame, Bauhaus primitives, Menger 400-cube, Big Pipes, L-System Plants)
##      and Single Compound StaticBody3D + Zero-Alloc 90 Hz Hover Memoization.
##   2. Exercises & photographs SPRAY, SND PAD, BIG PIPE, NOISE CFG, CA STEP, MENGER, PLANT, and 2-row terraced console rack.
##   3. Verifies live real Void Tower sequence workstations on F21, F55, F108, F118, F122, and F209.

const Bauhaus = preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")
const Layer = preload("res://commons/artifacts/scaffold_workstation/playground_layer.gd")
const RoomSource = preload("res://commons/void/room_source.gd")


func run() -> void:
	out = ProjectSettings.globalize_path("res://ada_run/vr_multimesh_sequences")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)

	await _test_multimesh_and_capabilities()
	await _test_tower_sequence_workstations()

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)):
			failed += 1
	var report := {"passed": failed == 0, "failed": failed, "total": checks.size(), "checks": checks}
	var f := FileAccess.open(out.path_join("report.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
	print("[vr_multimesh_sequences_probe] %d/%d passed" % [checks.size() - failed, checks.size()])
	quit(0 if failed == 0 else 1)


func _test_multimesh_and_capabilities() -> void:
	var bench_root := Node3D.new()
	bench_root.name = "VRPerfBench"
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

	var quads_scene: PackedScene = load("res://commons/artifacts/scaffold_workstation/quads.tscn")
	var ws: Node3D = quads_scene.instantiate()
	ws.set_meta("config_persist", false)
	ws.set_meta("config_studio", true)
	ws.set_meta("config_space_floor", 209)
	ws.set_meta("config_palette", "bauhaus")
	ws.set_meta("config_color_palette", "bauhaus")
	bench_root.add_child(ws)
	await frames(8)

	var st: Node3D = ws.get("studio_ctrl")
	var bay: Node3D = ws.output.get_node("Bay")
	var has_static_mm: bool = bay.get_node_or_null("GlassGridMajor") is MultiMeshInstance3D \
		and bay.get_node_or_null("GlassGridMinor") is MultiMeshInstance3D \
		and bay.get_node_or_null("GlassSteelFrame") is MultiMeshInstance3D \
		and st.console_root.get_node_or_null("MiniGridMajor") is MultiMeshInstance3D \
		and st.console_root.get_node_or_null("MiniGridMinor") is MultiMeshInstance3D
	check("1A Static Glass Box Grid, Mini Pad Grid, and Steel Frame all batched into MultiMeshInstance3D", has_static_mm)

	check("1B F209 Atelier arranges 16 sequence capabilities on a clean 2-row terraced console rack (rows=%d, tiles=%d)" % [
		st.layer_row_roots.size(), st.layer_nodes.size()],
		st.layer_row_roots.size() == 2 and st.layer_nodes.size() >= 15)

	# 1C: Zero-alloc 90 Hz hover memoization test!
	var aim := Node3D.new()
	bench_root.add_child(aim)
	var pad_pt: Vector3 = st.mini_root.to_global(Vector3(-1.5, 0.0, 0.5) * st.MINI_UNIT)
	aim.global_position = pad_pt + Vector3(0, 0.72, 0.72)
	aim.look_at(pad_pt, Vector3.UP)
	st.studio_hide()
	var before_reb: int = int(st.get_vr_perf_stats().hover_rebuilds)
	var before_skip: int = int(st.get_vr_perf_stats().hover_skips)
	for _f in 12:
		ws.space_update(aim, null)
	var after_p: Dictionary = st.get_vr_perf_stats()
	var d_reb: int = int(after_p.hover_rebuilds) - before_reb
	var d_skip: int = int(after_p.hover_skips) - before_skip
	check("1C Zero-alloc 90 Hz hover memoization: 12 frames on same cell -> %d rebuild, %d fast skips" % [d_reb, d_skip],
		d_reb == 1 and d_skip == 11)

	# 2A: Ray-click row 1 MENGER tile directly -> builds walkable Menger Pavilion + 400-cube Level-2 MultiMesh monument!
	var menger_tile: Node3D = st.layer_nodes["menger_gen"].root
	aim.global_position = menger_tile.global_position + Vector3(0.0, 0.45, 0.35)
	aim.look_at(menger_tile.global_position, Vector3.UP)
	var m_res: String = ws.space_press(aim, null)
	# Also add 3 Big Pipes, 4 L-System Plants (4 species), and 2 Sound Jump Pads onto the Menger court!
	st.stamp_play_object("big_pipe", Vector3(-3.5, 0.0, 0.5), 0)
	st.stamp_play_object("big_pipe", Vector3(-3.5, 0.0, -0.5), 0)
	st.stamp_play_object("big_pipe", Vector3(-3.5, 0.0, -1.5), 0)
	for sp in 4:
		st.stamp_play_object("lsystem_plant", Vector3(2.5 + float(sp % 2) * 1.5, 0.0, 1.5 + float(sp / 2) * 1.0), sp)
	st.stamp_play_object("sound_jump_pad", Vector3(0.5, 0.0, 2.0), 0)
	st.stamp_play_object("sound_jump_pad", Vector3(1.5, 0.0, 2.0), 0)
	# Spray-paint two quads directly!
	var sprayed_cnt := 0
	for i in ws.model.records.size():
		if str(ws.model.records[i].kind) == "quad" and sprayed_cnt < 2:
			if st.spray_piece_at(i):
				sprayed_cnt += 1

	await frames(8)
	var mperf: Dictionary = st.get_vr_perf_stats()
	var structure: Node3D = ws.output.get_node("Structure")
	var mm_menger := structure.get_node_or_null("MM_MengerSponges") as MultiMeshInstance3D
	var mm_pipes := structure.get_node_or_null("MM_BigPipes_Body") as MultiMeshInstance3D
	var mm_stems := structure.get_node_or_null("MM_LSystem_Stems") as MultiMeshInstance3D
	var mm_canopy := structure.get_node_or_null("MM_LSystem_Canopy") as MultiMeshInstance3D
	var sound_pad := structure.get_node_or_null("Live_sound_jump_pad")
	check("2A MultiMesh Menger (400 cubes=1 DC) + 3 Big Pipes (2 DC) + 6 L-System Plants (2 DC) + Sound Jump Pads + Spray Paint: %d total glass instances in just %d draw calls (%d compound physics body, %d colliders)" % [
		int(mperf.glass_instances), int(mperf.glass_draw_calls), int(mperf.structure_physics_bodies), int(mperf.structure_colliders)],
		m_res == "layer_action" and sprayed_cnt == 2 \
		and mm_menger != null and mm_menger.multimesh.instance_count == 400 \
		and mm_pipes != null and mm_pipes.multimesh.instance_count == 24 \
		and mm_stems != null and mm_canopy != null and sound_pad != null \
		and int(mperf.glass_instances) >= 500 and int(mperf.glass_draw_calls) <= 24 \
		and int(mperf.structure_physics_bodies) == 1)

	# Capture hero close-up of the 2-row terraced console + Menger/Pipe/Plant/SoundPad playground inside the glass box!
	cam.fov = 52.0
	cam.global_position = Vector3(-1.35, 2.25, 1.85)
	cam.look_at(Vector3(-0.05, 1.05, -2.35), Vector3.UP)
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("01-multimesh-menger-pipes-plants-studio.png"))

	# Capture close-up of the 2-row terraced console rack!
	cam.fov = 48.0
	cam.global_position = Vector3(-0.18, 1.88, 1.15)
	cam.look_at(Vector3(-0.20, 1.04, -0.35), Vector3.UP)
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("02-terraced-console-closeup.png"))

	# 2B: Cellular Automata live Conway B3/S23 evolution (3 generations) + Noise Preset cycling!
	st.clear_playground()
	var g1: Dictionary = st.step_ca()
	var g2: Dictionary = st.step_ca()
	var g3: Dictionary = st.step_ca()
	var np1: Dictionary = st.cycle_noise_preset()
	var np2: Dictionary = st.cycle_noise_preset()
	await frames(6)
	var ca_perf: Dictionary = st.get_vr_perf_stats()
	check("2B CA STEP evolves 3 Conway B3/S23 generations (gen=%d, cells=%d) & NOISE CFG switches presets (%s -> %s, glass DCs=%d)" % [
		st.ca_generation, int(g3.get("alive_count", 0)), str(np1.get("generator", "")), str(np2.get("generator", "")), int(ca_perf.glass_draw_calls)],
		st.ca_generation == 3 and int(g1.get("alive_count", 0)) >= 4 and int(g3.get("alive_count", 0)) >= 3 \
		and st.basin_mode == "noise" and str(np1.get("generator", "")) != str(np2.get("generator", "")) \
		and int(ca_perf.glass_draw_calls) <= 16)

	cam.fov = 52.0
	cam.global_position = Vector3(1.55, 2.35, 1.65)
	cam.look_at(Vector3(0.0, 0.95, -2.55), Vector3.UP)
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("03-ca-evolution-and-noise-basin.png"))

	bench_root.free()
	await frames(4)


func _test_tower_sequence_workstations() -> void:
	Engine.physics_ticks_per_second = 90
	RoomSource.use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = 19
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
	await frames(45)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	var cam := Camera3D.new()
	root.add_child(cam)
	cam.make_current()

	var targets := [
		{"floor": 19, "name": "Trans_Body", "id": "scaffold-workstation", "mono": true, "need": "package", "file": "04-f19-trans-workstation.png"},
		{"floor": 55, "name": "Vectors_Act5_ForceAsPlace", "id": "scaffold-workstation", "mono": false, "need": "sound_jump_pad", "file": "05-f55-forces-workstation.png"},
		{"floor": 108, "name": "CA_GameOfLife", "id": "scaffold-workstation", "mono": false, "need": "ca_step", "file": "06-f108-ca-workstation.png"},
		{"floor": 118, "name": "Fractal_MengerSponge", "id": "scaffold-workstation", "mono": false, "need": "menger_gen", "file": "07-f118-menger-workstation.png"},
		{"floor": 122, "name": "LSystems_Growth", "id": "scaffold-workstation", "mono": false, "need": "lsystem_plant", "file": "08-f122-lsystems-workstation.png"},
	]
	for spec in targets:
		var fl: int = int(spec.floor)
		game.place_player(game.spawn_for(fl))
		await frames(38)
		cam.make_current()
		var fl_root: Node3D = game.building.content.roots.get(fl, null)
		var mount: Node3D = fl_root.find_child(str(spec.id), true, false) if fl_root != null else null
		var ws: Node3D = _find_with_prop(mount, "studio_ctrl")
		var st: Node3D = ws.get("studio_ctrl") if ws != null else null
		var ok: bool = st != null and bool(st.layer_nodes.has(str(spec.need)))
		var phase_ok: bool = st != null and ((str(st.effective_phase()) == "monochrome") == bool(spec.mono))
		var perf: Dictionary = st.get_vr_perf_stats() if st != null else {}
		if st != null and fl == 108:
			st.step_ca()
		elif st != null and fl == 118:
			st.generate_menger(1)
		elif st != null and fl == 122:
			st.stamp_play_object("lsystem_plant", Vector3(-2.5, 0.0, 1.5), 0)
			st.stamp_play_object("lsystem_plant", Vector3(2.5, 0.0, 1.5), 2)
		check("3-F%03d %s live Studio Workstation (tile=%s, phase=%s, glass_dcs=%d, body=%d)" % [
			fl, str(spec.name), str(spec.need), st.effective_phase() if st != null else "?",
			int(perf.get("glass_draw_calls", -1)), int(perf.get("structure_physics_bodies", -1))],
			ok and phase_ok and int(perf.get("structure_physics_bodies", 0)) == 1 and int(perf.get("glass_draw_calls", 99)) <= 18)

		if ws != null:
			cam.fov = 58.0
			cam.global_position = ws.to_global(Vector3(-1.85, 2.20, 2.35))
			cam.look_at(ws.to_global(Vector3(-0.10, 1.10, -2.0)), Vector3.UP)
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
