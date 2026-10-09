extends "res://doc/book/iterations/2026-09-19-change-review/intro/probes/base.gd"

func press(ui: Node3D, id: String, cam: Camera3D) -> void:
	var area: Area3D = ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam, area, area.global_position)
	XRToolsPointerEvent.released(cam, area, area.global_position)

func run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl = OUT+"change-intro-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl+".unused"); em.set("_hand_path", ctl+".unused-hand")
	em.set("start_chapter", "change"); em.set("start_map", "Change_Intro")
	var f = FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"change", "dollhouse":0, "grid_pack":1})); f.close()
	root.add_child(em); current_scene = em
	var ui: Node3D
	for i in 2400:
		ui = em.find_child("RateComparison", true, false)
		if ui and ui.second: break
		await process_frame
	check(ui != null and ui.second != null, "comparison loads in the actual Change_Intro hall")
	if not ui or not ui.second: quit(1); return
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var grid = ui
	while grid and not str(grid.name).begins_with("SimGrid_"): grid=grid.get_parent()
	if grid:
		for j in 3600:
			if grid.has_meta("stage_grid_ready"): break
			await process_frame
	var cam: Camera3D = em.get("_cam"); var player: CharacterBody3D = em.get("_player")
	player.set_physics_process(false); em.get("_feel").set_process(false)
	var wardrobe = em.get("_wardrobe"); wardrobe.appearance_save_path = ""; wardrobe.costume.visible = false
	var b: Node3D = ui.bench
	player.global_position += b.to_global(Vector3(0,1.7,3)) - cam.global_position
	cam.look_at(b.to_global(Vector3(0,1.5,0)))
	for i in 90: em.call("_cull_artifacts"); await process_frame
	check(ui.buttons.values().all(func(button):return button.global_position.y>0.55 and button.global_position.y<1.65), "all five buttons lie within the standing reach band")
	check(ui.buttons.size()==5, "five reachable pointer controls supplement the existing slider")
	check(not b._tangent_mesh_inst.visible and not b._derivative_root.visible and not b._sign_root.visible, "analytic answer starts hidden")
	var source = b._curve_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(is_equal_approx(b._f(0),0.65) and is_equal_approx(b._df(0),0.8), "function and analytic derivative agree with known values")
	check(is_equal_approx(ui.sample().h,0.5), "initial comparison uses half a position unit")
	var start: float = b._x
	press(ui,"x +",cam); check(is_equal_approx(b._x,start+0.125), "pointer advances the spatial sample")
	press(ui,"x -",cam); check(is_equal_approx(b._x,start), "pointer reverses the sample change")
	ui.set_x(0); b._refresh_all()
	var coarse: float = absf(ui.sample().rate-b._df(0))
	for i in 3: press(ui,"STEP",cam)
	check(ui.step_index==3 and is_equal_approx(ui.sample().h,0.0625), "three step presses reach the smallest finite interval")
	check(absf(ui.sample().rate-b._df(0))<coarse, "smaller interval improves this smooth example's estimate at x=0")
	check(absf(ui.sample().rate-b._df(0))>0.001, "a finite interval remains distinguishable from the analytic derivative")
	press(ui,"DERIVATIVE",cam)
	check(b._tangent_mesh_inst.visible and b._derivative_root.visible and b._sign_root.visible, "pointer reveals tangent, derivative plot and sign")
	check(b._plate_readout.text.contains("analytic"), "readout identifies the derivative as analytic")
	ui.set_x(5); b._refresh_all()
	check(ui.sample().h<0 and ui.sample().next>=b.x_min and ui.sample().next<=b.x_max, "right endpoint uses a labelled backward interval inside the domain")
	check(is_equal_approx(ui.sample().rate,(b._f(ui.sample().next)-b._f(5))/ui.sample().h), "signed backward difference uses its actual interval")
	b._slider.set_normalized_value(0.4); b._on_slider_changed(0.4); b._refresh_all()
	check(is_equal_approx(b._x,2.0) and is_equal_approx(ui.sample().x,2.0), "existing slider updates both sample and comparison")
	check(b._slope_word(0.01).contains("near zero") and not b._slope_word(0.01).contains("extremum"), "small slope is not asserted to be an extremum")
	check(b._curve_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==source, "controls preserve the source curve geometry")
	press(ui,"RESET",cam)
	check(is_equal_approx(b._x,b.initial_x) and ui.step_index==0 and not ui.revealed, "reset restores the discovery state")
	var capsule = CapsuleShape3D.new(); capsule.radius=0.22; capsule.height=1.6
	var q = PhysicsShapeQueryParameters3D.new(); q.shape=capsule; q.collision_mask=1; q.exclude=[player.get_rid()]
	q.transform.origin=b.to_global(Vector3(0,0.85,2)); await physics_frame
	check(b.get_world_3d().direct_space_state.intersect_shape(q).is_empty(), "standing approach to the comparison is clear")
	await capture(cam,b.to_global(Vector3(0,1.9,3.7)),b.to_global(Vector3(0,1.45,0)),"change_samples")
	press(ui,"DERIVATIVE",cam)
	await capture(cam,b.to_global(Vector3(0,2.0,3.8)),b.to_global(Vector3(0,1.65,0)),"change_derivative")
	for i in 3: press(ui,"STEP",cam)
	await capture(cam,b.to_global(Vector3(0,1.55,2)),b.to_global(Vector3(0,1.30,0.3)),"change_console")
	var legacy: Node3D = load("res://commons/artifacts/tangent_slope_workbench/tangent_slope_workbench.tscn").instantiate()
	legacy.position=Vector3(1000,0,0); root.add_child(legacy)
	for i in 10: await process_frame
	check(legacy.comparison==null and legacy._tangent_mesh_inst.visible, "unconfigured workbench keeps its existing interface")
	legacy.queue_free()
	for i in 10: await process_frame
	f=FileAccess.open(OUT+"probe_change_intro.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("CHANGE_INTRO ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
