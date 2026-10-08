extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message)
	print("FLOW ","PASS " if ok else "FAIL ",message)
func press(bench:Node3D,id:String,cam:Camera3D) -> void:
	var area=bench.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var scene=load("res://commons/testing/landscape_flow_workshop.tscn").instantiate();root.add_child(scene);current_scene=scene
	await create_timer(0.5).timeout
	var bench=scene.get_node("LandscapeFlowBench");var cam=scene.cam
	check(bench.trays.size()==4,"four physical trays constructed")
	check(bench.bodies.is_empty() and not bench.running,"waits for a release")
	check(bench.buttons.size()==9,"nine shared pointer controls")
	var area=bench.buttons["RULE"].get_node("InteractableAreaButton")
	cam.global_position=area.global_position+Vector3(0,0.7,0.6);cam.look_at(area.global_position)
	await process_frame
	var click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=cam.unproject_position(area.global_position)
	scene._unhandled_input(click)
	check(bench.reveal,"desktop mouse ray reaches a real pointer button")
	press(bench,"RULE",cam)
	for mode in 4:
		var a=bench.generate_samples(mode);var b=bench.generate_samples(mode)
		check(a==b,"seeded field replay "+str(mode))
		check(absf(Array(a).min())<0.00001 and absf(Array(a).max()-0.3)<0.00001,"matched peak-to-trough relief "+str(mode))
		check(bench.terrain_meshes[mode].get_parent().get_child(0).shape is ConcavePolygonShape3D,"rendered triangle surface has physical collision "+str(mode))
		var query=PhysicsRayQueryParameters3D.create(bench.trays[mode].to_global(Vector3(0,1,0)),bench.trays[mode].to_global(Vector3(0,-0.2,0)))
		var hit=bench.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit.collider.name=="MeasuredSurface","upper face intercepts a descending ray before the support slab "+str(mode))
	var sine=bench.generate_samples(0);var random_field=bench.generate_samples(1)
	press(bench,"SEED",cam)
	check(bench.seed_value==1730 and bench.generate_samples(1)!=random_field,"seed changes independent random heights")
	check(bench.generate_samples(0)==sine,"sine does not secretly change with seed")
	bench.seed_value=1729;bench.rebuild();await physics_frame
	press(bench,"RULE",cam);check(bench.details.text.contains("NOT GRADIENT DESCENT") and bench.details.text.contains("normalised"),"rule reveal declares physical model and normalisation")
	press(bench,"RELEASE",cam);check(bench.bodies.size()==128 and bench.running,"pointer releases four equal batches of 32")
	for mode in range(1,4):
		var a=bench.trays[0].to_local(bench.bodies[0].global_position);var b=bench.trays[mode].to_local(bench.bodies[mode*32].global_position)
		check(a.is_equal_approx(b),"matched release position tray "+str(mode))
	check(bench.bodies.all(func(b):
		var mode=bench.bodies.find(b)/32;var p=bench.trays[mode].to_local(b.global_position)
		return absf(p.x)<0.9 and absf(p.z)<1.4 and p.y>0.9),"all initial centres are above the interior, including on a tilt")
	await create_timer(0.8).timeout
	press(bench,"PAUSE",cam);var tick=bench.ticks
	await physics_frame;await process_frame
	var position=bench.bodies[0].position
	await create_timer(0.3).timeout
	check(bench.ticks==tick and bench.bodies[0].position.is_equal_approx(position),"pause freezes both clock and physical bodies")
	press(bench,"PAUSE",cam)
	while bench.running:await physics_frame
	var baseline=bench.snapshot()
	check(bench.ticks==12*bench.hz,"fixed window ends on declared physics tick")
	for mode in 4:
		var c=bench.counts(mode);check(c[0]+c[1]+c[2]==32,"every released body accounted for "+str(mode))
	check(bench.bodies.all(func(b):return b.freeze),"deadline freezes the observation instead of claiming equilibrium")
	cam.position=Vector3(8,7,11);cam.look_at(Vector3(0,1,0));await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/landscape_flow_overview.png")
	cam.position=Vector3(3.0,4.9,7.6);cam.look_at(Vector3(0,1.1,2.2));await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/landscape_flow_detail.png")
	# Explicit classification checks prevent silently treating any disappearance as success.
	press(bench,"RELEASE",cam);bench.running=false
	bench.record_exit(0,1);bench.record_exit(0,2)
	check(bench.counts(0)==[31,1,0],"each sphere can be counted only once")
	bench.record_exit(1,2);check(bench.counts(0)==[30,1,1],"other exits remain distinct from outlet crossings")
	press(bench,"TILT",cam);check(bench.angle_index==2 and bench.bodies.is_empty() and bench.ticks==0,"tilt edit resets batch before changing collider")
	press(bench,"RELIEF",cam);check(bench.amp_index==2 and absf(Array(bench.surfaces[0]).max()-0.55)<0.00001,"relief edit rebuilds measured and rendered surface")
	press(bench,"SIZE",cam);check(bench.radius_index==2,"size is a visitor control")
	press(bench,"WINDOW",cam);check(bench.window_index==2,"observation window is a visitor control")
	press(bench,"RESET",cam);check(bench.angle_index==2 and bench.radius_index==2 and not bench.has_run,"reset preserves current settings")
	bench.angle_index=1;bench.amp_index=1;bench.radius_index=1;bench.window_index=0;bench.seed_value=1730;bench.rebuild();await physics_frame
	press(bench,"RELEASE",cam)
	while bench.running:await physics_frame
	var second=bench.snapshot()
	check(bench.ticks==8*bench.hz,"changed window produces its own complete run")
	var n=bench.get_child_count();for i in 40:bench.refresh()
	check(n==bench.get_child_count(),"readouts reuse existing nodes")
	check(bench.buttons.values().all(func(b):return b.global_position.y>0.95 and b.global_position.y<1.2),"controls at standing reach")
	var report={"checks":checks,"failures":failures,"baseline":baseline,"second_run":second,"headset_tested":false,"hall_placement_tested":false,"status":"standalone_physical_prototype"}
	var f=FileAccess.open("res://ada_run/landscape_flow_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("FLOW RESULT ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
