extends SceneTree
var OUT := ""
var checks := 0
var failures: Array[String] = []
var evidence: Dictionary = {}
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): OUT = a.trim_prefix("--out=")
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("MIDDLE ", "PASS " if ok else "FAIL ", message)
func run() -> void:
	var sound := OUT.contains("sound")
	var map_name := "WaveFunctions_Effect_Sound" if sound else "WaveFunctions_3D_Wave_Propagation"
	var id := "DualBallFMController" if sound else "coupled_oscillator_lattice"
	var em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl = OUT + "museum-control.json"
	var f = FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"wavefunctions", "dollhouse":0, "grid_pack":1})); f.close()
	em.EM_CONTROL = ctl; em._overrides_path = ctl + ".unused"; em._hand_path = ctl + ".unused-hand"
	em.start_chapter = "wavefunctions"; em.start_map = map_name
	root.add_child(em); current_scene = em
	await create_timer(2).timeout
	em.set_process(false); em.set_physics_process(false); em.flush_stamps()
	var seg: Node3D
	for rec in em._segments:
		if rec.node.get_meta("em_map", "") == map_name: seg = rec.node; break
	check(seg != null, "actual museum hall loaded: " + map_name)
	if not seg: finish(); return
	em._player.set_physics_process(false); em._feel.set_process(false)
	em._wardrobe.appearance_save_path = ""; em._wardrobe.costume.visible = false
	for rec in em._vis_records:
		var n = rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n): n.visible = true
	var ui: Node3D
	var ids: Array[String] = []
	for n in seg.find_children("*", "Node", true, false):
		if n.has_meta("artifact_lookup_name"):
			var found = str(n.get_meta("artifact_lookup_name")); ids.append(found)
			if found == id: ui = n
	check(ui != null, "primary artifact loaded: " + id)
	evidence.artifact_ids = ids
	if not ui: finish(); return
	if OUT.contains("replay-before") and not sound:
		var parent = ui.get_parent(); var pose = ui.transform
		parent.remove_child(ui); ui.queue_free()
		ui = load("res://doc/book/iterations/2026-09-19-wavefunctions-review/middle/before-source/algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd").new()
		ui.transform = pose; parent.add_child(ui)
		evidence.baseline_replay = "Frozen original artifact source at actual museum placement; current room and route retained."
	evidence.artifact_global = str(ui.global_position); evidence.segment_local = str(seg.to_local(ui.global_position))
	evidence.scale = str(ui.global_basis.get_scale())
	if OUT.contains("survey"):
		var capsule := CapsuleShape3D.new(); capsule.radius = .22; capsule.height = 1.6
		var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.collision_mask = 1
		q.exclude = [em._player.get_rid()]; q.collide_with_areas = false
		await physics_frame
		evidence.positions = {}
		for x in [3.8,4.3,4.8,5.0]:
			for z in [.5,1.0,1.5,2.0]:
				q.transform.origin = ui.to_global(Vector3(x,.85,z))
				evidence.positions[str(Vector2(x,z))] = seg.get_world_3d().direct_space_state.intersect_shape(q,8).map(func(h):return str(h.collider.get_path()))
		finish(); return
	for n in em.find_children("*", "Node", true, false):
		n.set_process(false); n.set_physics_process(false)
		if n is Timer: n.stop()
	var cam := Camera3D.new(); cam.fov = 57; em.add_child(cam)
	if sound:
		var labels: Array[String] = []
		for n in ui.find_children("*", "Label3D", true, false):
			if n.name == "TitleLabel": labels.append(n.text)
		evidence.titles = labels
		ui.set_baseline()
		await shot(cam, ui.to_global(Vector3(.25, 1.65, 2.65)), ui.to_global(Vector3(.25, 1.25, 0)), "instrument")
	else:
		if OUT.contains("after"):
			ui.act("RESET")
			for i in 300: ui.comparison_step(1.0/120.0)
			ui._refresh_comparison()
		else:
			ui.time = 0.0; ui.pulse_triggered = false
			for osc in ui.oscillators: osc.displacement = 0.0; osc.velocity = 0.0; osc.acceleration = 0.0
			for i in 300:
				ui.time += 1.0/120.0; ui._apply_excitation(1.0/120.0); ui._update_oscillators(1.0/120.0)
		ui._update_visualization()
		evidence.time = ui.time; evidence.drive = ui.excitation_mode; evidence.coupling = ui.coupling_strength
		await shot(cam, ui.to_global(Vector3(4.8, 2.35, 2.0)), ui.to_global(Vector3(0, .95, 0)), "lattice")
		if OUT.contains("after"):
			check(ui.comparison, "map opts into comparison")
			check(ui.buttons.size() == 3, "three comparison controls")
			check(ui.find_children("Comparison", "Node3D", false, false).size() == 1, "one live console")
			var capsule := CapsuleShape3D.new(); capsule.radius = .22; capsule.height = 1.6
			var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.collision_mask = 1
			q.exclude = [em._player.get_rid()]; q.collide_with_areas = false
			await physics_frame
			evidence.console_approaches = {}
			for z in [.72, 1.2, 1.68]:
				q.transform.origin = ui.to_global(Vector3(3.8, .85, z))
				var hits = seg.get_world_3d().direct_space_state.intersect_shape(q, 8)
				evidence.console_approaches[str(z)] = hits.map(func(h): return str(h.collider.get_path()))
				check(hits.is_empty(), "clear console standing approach z=" + str(z))
			ui.act("DRIVE")
			for i in 168: ui.comparison_step(1.0/120.0)
			ui._update_visualization(); ui._refresh_comparison()
			await shot(cam, ui.to_global(Vector3(4.8, 2.35, 2.0)), ui.to_global(Vector3(0, .95, 0)), "pulse-coupled")
			ui.act("COUPLING")
			for i in 168: ui.comparison_step(1.0/120.0)
			ui._update_visualization(); ui._refresh_comparison()
			await shot(cam, ui.to_global(Vector3(4.8, 2.35, 2.0)), ui.to_global(Vector3(0, .95, 0)), "pulse-independent")
	finish()
func shot(cam: Camera3D, pos: Vector3, target: Vector3, id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	cam.global_position = pos; cam.look_at(target)
	for i in 15: cam.make_current(); await process_frame
	cam.make_current(); check(root.get_camera_3d() == cam, "camera current before " + id)
	await RenderingServer.frame_post_draw
	check(root.get_camera_3d() == cam, "camera current after " + id)
	root.get_texture().get_image().save_png(OUT + id + ".png")
	var f = FileAccess.open(OUT + id + "-camera.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"position":str(pos),"target":str(target),"fov":cam.fov}, "  ")); f.close()
func finish() -> void:
	var f = FileAccess.open(OUT + "museum-checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":evidence,"headset_tested":false}, "  ")); f.close()
	print("MIDDLE COMPLETE ", checks, " / ", failures.size()); quit(0 if failures.is_empty() else 1)
