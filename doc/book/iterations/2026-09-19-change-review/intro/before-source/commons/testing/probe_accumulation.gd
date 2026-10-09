extends "res://commons/testing/probe_color_recovery.gd"

func press(ui: Node3D, id: String, cam: Camera3D) -> void:
	var area: Area3D = ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam, area, area.global_position)
	XRToolsPointerEvent.released(cam, area, area.global_position)

func run() -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl = "res://ada_run/accumulation-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl+".unused"); em.set("_hand_path", ctl+".unused-hand")
	em.set("start_chapter", "change"); em.set("start_map", "Change_Intro")
	var f = FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"change", "dollhouse":0, "grid_pack":1})); f.close()
	root.add_child(em); current_scene = em
	var ui: Node3D
	for i in 2400:
		ui = em.find_child("AccumulationComparison", true, false)
		if ui and ui.marker: break
		await process_frame
	check(ui != null and ui.marker != null, "comparison loads in the accumulation bay in Change_Intro")
	if not ui or not ui.marker: quit(1); return
	em.set_process(false); em.set_physics_process(false)
	var cam: Camera3D = em.get("_cam"); var player: CharacterBody3D = em.get("_player")
	player.set_physics_process(false); em.get("_feel").set_process(false)
	var wardrobe = em.get("_wardrobe"); wardrobe.appearance_save_path = ""; wardrobe.costume.visible = false
	var b: Node3D = ui.bench
	player.global_position += b.to_global(Vector3(0,1.7,3)) - cam.global_position
	cam.look_at(b.to_global(Vector3(0,1.5,0)))
	for i in 90: em.call("_cull_artifacts"); await process_frame

	check(b._n==4 and b.sample_fraction==0.5,"entry begins with four midpoint rectangles")
	check(ui.buttons.size()==6,"six pointer controls share the existing count slider")
	check(not ui.show_reference and not b._error_bar_inst.get_parent().visible,"reference comparison starts hidden")
	var curve=b._curve_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var midpoint:float=b._compute_riemann_sum(4)
	var total:float=0
	for i in 4:total+=ui.contribution(i).area
	check(is_equal_approx(total,midpoint),"selected height-times-width contributions add to the displayed sum")
	check(is_equal_approx(ui.contribution(0).width,1.25) and is_equal_approx(ui.contribution(0).x,0.625),"first midpoint address and interval width are explicit")
	var exact:float=2.5+0.2*(1-cos(10.0))+0.03*sin(25.0)
	check(absf(b._true_integral-exact)<0.000001,"4096-midpoint reference is close to an independent antiderivative value")
	var reference:float=b._true_integral
	press(ui,"HOLD",cam)
	var held_mesh=ui.held_root.get_child(2).mesh
	var held_vertices=held_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(ui.held.n==4 and ui.held.rule=="MID" and is_equal_approx(ui.held.sum,midpoint),"hold records current count, rule and total")
	press(ui,"RULE",cam)
	check(b.sample_fraction==1.0 and ui.rule==1,"pointer selects the right edge rule")
	check(is_equal_approx(ui.contribution(3).x,5.0),"right rule includes the last endpoint")
	var right:float=b._compute_riemann_sum(4)
	press(ui,"RULE",cam)
	check(b.sample_fraction==0.0 and is_equal_approx(ui.contribution(0).x,0.0),"left rule includes the first endpoint")
	var left:float=b._compute_riemann_sum(4)
	check(absf((right-left)-1.25*(b._f(5)-b._f(0)))<0.000001,"left/right difference agrees with the independent endpoint identity")
	check(ui.held.sum==midpoint and held_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==held_vertices,"held vertices and total survive live rule changes")
	press(ui,"CELL +",cam);check(ui.selected==1,"pointer selects another contribution")
	press(ui,"CELL -",cam);check(ui.selected==0,"pointer returns to the earlier contribution")
	press(ui,"REFERENCE",cam)
	check(ui.show_reference and b._plate_readout.text.contains("4096 MID ref"),"reference control names its finite midpoint computation")
	check(b._true_integral==reference,"reference remains midpoint-based under all live sampling rules")
	b._slider.set_normalized_value(1.0);b._on_slider_changed(1.0)
	press(ui,"HOLD",cam)
	check(ui.held.n==128 and ui.held_root.get_child(2).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==128*6,"hold flushes a pending slider redraw before copying rectangle geometry")
	check(b._curve_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==curve,"sampling and count controls preserve the underlying curve")
	press(ui,"RESET",cam)
	check(b._n==4 and ui.rule==0 and ui.selected==0 and ui.held.is_empty() and not ui.held_root.visible and not ui.show_reference,"reset restores four midpoint rectangles and clears held comparison")
	check(ui.buttons.values().all(func(button):return button.global_position.y>0.55 and button.global_position.y<1.65),"all six controls remain in the standing reach band")
	var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()]
	q.transform.origin=b.to_global(Vector3(0,0.85,2));await physics_frame
	check(b.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"standing approach to the console is clear")
	for x in [0.0, 1.3, 1.9]:
		var ray = PhysicsRayQueryParameters3D.create(b.to_global(Vector3(0.6,1.7,2.5)), b.to_global(Vector3(x,1.7,0.15)), 1, [player.get_rid()])
		check(b.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "museum walls leave plot %s visible from the approach" % x)
	await capture(cam,b.to_global(Vector3(0.6,1.9,2.5)),b.to_global(Vector3(0.5,1.5,0)),"accumulation_four")
	press(ui,"HOLD",cam);press(ui,"RULE",cam);press(ui,"REFERENCE",cam)
	await capture(cam,b.to_global(Vector3(0.6,1.9,2.5)),b.to_global(Vector3(0.6,1.5,0)),"accumulation_rules")
	b._slider.set_normalized_value(0.6);b._on_slider_changed(0.6);b._refresh_all()
	await capture(cam,b.to_global(Vector3(0.6,1.9,2.5)),b.to_global(Vector3(0.6,1.5,0)),"accumulation_refined")
	var legacy:Node3D=load("res://commons/artifacts/riemann_sum_workbench/riemann_sum_workbench.tscn").instantiate()
	legacy.position=Vector3(1000,0,0);root.add_child(legacy)
	for i in 10:await process_frame
	check(legacy.comparison==null and legacy._n==16 and legacy.sample_fraction==0.5,"unconfigured workbench retains its default midpoint interface")
	legacy.queue_free()
	for i in 10:await process_frame
	f=FileAccess.open("res://ada_run/probe_accumulation.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("ACCUMULATION ",checks," checks / ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
