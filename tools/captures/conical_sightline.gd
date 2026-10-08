extends SceneTree
var viewport: SubViewport
var scene: Node3D
var out: String
var checks: Array = []
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"pass":ok,"check":message})
	print("PASS " if ok else "FAIL ", message)
func settle() -> void:
	for i in 24: await physics_frame
func ray(x: float, y: float) -> Dictionary:
	return scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,y,5),Vector3(x,y,-5),1))
func shot(name: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(out.path_join(name+".png")) == OK, "saved "+name)
func run() -> void:
	out = OS.get_cmdline_user_args()[0]
	viewport = SubViewport.new()
	viewport.size = Vector2i(1800,1200)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	scene = load("res://commons/artifacts/conical_sightline/study.tscn").instantiate()
	viewport.add_child(scene)
	scene.overlay.hide()
	await settle()
	var work: Node3D = scene.work
	check(work.cut_enabled and is_zero_approx(work.cut_x), "default cut is enabled and centred")
	check(ray(0,2.8).is_empty(), "shared cone opens a sightline through all three walls")
	check(not ray(3.3,2.8).is_empty(), "uncut wall still blocks a ray")
	check(ray(-2.9,1.2).is_empty(), "ordinary door route remains clear at torso height")
	var counts: Array = []
	for wall in work.walls:
		var mesh: Array = wall.get_meshes()
		check(mesh.size()==2, "remaining wall has a generated CSG mesh")
		if mesh.size()==2: counts.append(mesh[1].get_faces().size()/3)
	await shot("cut-approach")
	scene.set_view(1)
	await shot("cut-inside")
	scene.set_view(2)
	await shot("cut-offcuts")
	scene._choose("Before / cut")
	await settle()
	check(not ray(0,2.8).is_empty(), "before state closes the central sightline")
	check(ray(-2.9,1.2).is_empty(), "doors still connect the rooms before cutting")
	scene.set_view(0)
	await shot("cut-before")
	scene._choose("Before / cut")
	await settle()
	check(ray(-0.7,2.8).is_empty(), "off-centre ray passes the original cut")
	scene._choose("Shift cut")
	await settle()
	check(not ray(-0.7,2.8).is_empty(), "same ray is blocked after translating the shared cone")
	check(ray(0.75,2.8).is_empty(), "translated axis opens a new sightline")
	scene._choose("Reset")
	await settle()
	check(ray(-0.7,2.8).is_empty() and is_zero_approx(work.cut_x), "reset restores the original opening")
	var report := FileAccess.open(out.path_join("verification.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"wall_triangles":counts,
		"scope":"Desktop scene; UI callbacks, CSG meshes and collision rays. Not a tracked-hand or walking-body test."}, "\t"))
	report.close()
	var failures := 0
	for c in checks:
		if not c["pass"]: failures += 1
	quit(0 if failures == 0 else 1)
