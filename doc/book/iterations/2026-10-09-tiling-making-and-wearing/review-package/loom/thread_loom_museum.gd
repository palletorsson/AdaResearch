extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-09-thread-loom/"
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title}); print("PASS " if ok else "FAIL ",title)
func run() -> void:
	root.size = Vector2i(1600,1100)
	create_timer(100).timeout.connect(func(): quit(98))
	var folder := "res://ada_run/thread_loom_review/"
	var museum: Node3D = load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter","tiling"); museum.set("start_map","Symmetry_Seventeen")
	museum.set("plan_file",folder+"plan.json")
	root.add_child(museum); current_scene = museum
	var start := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start<75000: await process_frame
	museum.set("_lazy_pending",0); museum.set_process(false); museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var hall: Node3D
	for c in museum.get_children():
		if c is Node3D and str(c.get_meta("em_map",""))=="Symmetry_Seventeen": hall = c
	check(hall!=null,"Actual Symmetry hall loads")
	var loom: Node3D
	if hall:
		var deadline := Time.get_ticks_msec()+30000
		while loom==null and Time.get_ticks_msec()<deadline:
			for n in hall.find_children("*","Node3D",true,false):
				if n.scene_file_path=="res://commons/artifacts/thread_loom/thread_loom.tscn": loom = n; break
			await process_frame
		await create_timer(1).timeout
	check(loom!=null,"Registered hand loom installed in the real hall")
	if loom==null:
		print("LOOM_LIVE ",museum.get("_live").get("thread_loom",{}))
		for n in museum.find_children("*","Node3D",true,false):
			if "loom" in str(n.name).to_lower(): print("LOOM_NODE ",n.get_path()," scene=",n.scene_file_path)
		for a in museum.get("_inventory"):
			if "loom" in str(a.get("token","")): print("LOOM_INVENTORY ",a)
	if loom:
		for i in range(8):
			var side: float = loom.start_side()
			for step in range(33): loom.sample_shuttle(Vector3(lerpf(side*.56,-side*.56,float(step)/32),1.06,.60))
			loom.beat()
		loom.set_draft("twill")
		check(loom.picks.size()==12,"Installed loom accepts eight complete passes")
		var camera := Camera3D.new(); root.add_child(camera)
		camera.global_position = loom.to_global(Vector3(2.9,2.6,3.1))
		camera.look_at(loom.to_global(Vector3(-.12,1.0,.05))); camera.fov = 53; camera.make_current()
		await physics_frame
		var shape := CapsuleShape3D.new(); shape.radius = .22; shape.height = 1.4
		var query := PhysicsShapeQueryParameters3D.new(); query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY,loom.to_global(Vector3(0,.81,1.5)))
		query.collision_mask = 1
		var hits := loom.get_world_3d().direct_space_state.intersect_shape(query)
		check(hits.is_empty(),"Standing approach in front of loom clear")
		for h in hits: print("BLOCKER ",h.collider.get_path())
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"museum.png")
		camera.global_position = loom.to_global(Vector3(.12,1.65,1.4))
		camera.look_at(loom.to_global(Vector3(0,1.10,.55))); camera.fov = 73
		for i in range(3):
			camera.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"player-view.png")
	var passed := true
	for c in checks: passed = passed and c.passed
	var f := FileAccess.open(OUT+"museum-tests.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"checks":checks},"\t")); f.close()
	quit(0 if passed else 1)
