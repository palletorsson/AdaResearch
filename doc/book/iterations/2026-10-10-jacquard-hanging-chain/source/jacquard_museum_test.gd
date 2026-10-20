extends SceneTree
var OUT := "res://doc/book/iterations/2026-10-10-jacquard-hanging-chain/" if "--chain" in OS.get_cmdline_user_args() else "res://doc/book/iterations/2026-10-10-jacquard-cards-and-layers/"
var checks: Array=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title}); print("PASS " if ok else "FAIL ",title)
func run() -> void:
	root.size=Vector2i(1800,1200); root.msaa_3d=Viewport.MSAA_4X
	create_timer(100).timeout.connect(func():quit(98))
	var folder:="res://ada_run/jacquard_review/"
	var museum:Node3D=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json"); museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter","tiling"); museum.set("start_map","Symmetry_Seventeen"); museum.set("plan_file",folder+"plan.json")
	root.add_child(museum); current_scene=museum
	var start:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start<65000: await process_frame
	museum.set("_lazy_pending",0); museum.set_process(false); museum.set_physics_process(false); museum.call("flush_stamps")
	await create_timer(1).timeout
	# Suspend only this isolated snapshot's walker-camera guard during photography.
	var walker_camera:Camera3D=museum.get("_cam")
	if walker_camera:
		for child in walker_camera.get_children():
			if child is Timer: child.stop()
	var hall:Node3D
	for c in museum.get_children():
		if c is Node3D and str(c.get_meta("em_map",""))=="Symmetry_Seventeen":hall=c
	check(hall!=null,"Actual Symmetry Seventeen hall loads from the current plan")
	var studio:Node3D; var handloom:Node3D
	if hall:
		var deadline:=Time.get_ticks_msec()+20000
		while (studio==null or handloom==null) and Time.get_ticks_msec()<deadline:
			for n in hall.find_children("*","Node3D",true,false):
				if n.scene_file_path=="res://commons/artifacts/jacquard_weaver/jacquard_studio.tscn":studio=n
				if n.scene_file_path=="res://commons/artifacts/thread_loom/thread_loom.tscn":handloom=n
			await process_frame
	check(studio!=null,"Registered Jacquard studio installed in the museum")
	check(handloom!=null,"Existing hand loom remains in the hall")
	if studio:
		var loom:Node3D=studio.loom
		loom.set_process(false); loom.set_preset("plain")
		for i in range(8):loom.start_pick(); loom.advance_cycle(2.8)
		loom.set_preset("diamond")
		for i in range(16):loom.start_pick(); loom.advance_cycle(2.8)
		check(loom.program.history.size()==24 and studio.layers.records==loom.program.history,"Installed pair produces and shares 24 committed picks")
		await physics_frame
		for spot in [Vector3(-1.7,.82,1.8),Vector3(1.9,.82,1.8),Vector3(-.1,.82,1.9),Vector3(-3.25,.82,1.8)]:
			var shape:=CapsuleShape3D.new(); shape.radius=.22; shape.height=1.4
			var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape
			query.transform=Transform3D(Basis.IDENTITY,studio.to_global(spot)); query.collision_mask=1
			var hits:=studio.get_world_3d().direct_space_state.intersect_shape(query)
			check(hits.is_empty(),"Standing approach clear at "+str(spot))
			for hit in hits: print("BLOCKER ",hit.collider.get_path())
		var camera:=Camera3D.new(); root.add_child(camera)
		loom.start_pick(); loom.advance_cycle(1.6)
		camera.global_position=studio.to_global(Vector3(5.8,4.1,7.8)); camera.look_at(studio.to_global(Vector3(0,1.35,.2)));camera.fov=48;camera.make_current()
		for i in range(8):
			camera.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"museum.png")
		camera.global_position=loom.to_global(Vector3(.25,1.65,2.30));camera.look_at(loom.to_global(Vector3(0,1.35,.45)));camera.fov=80
		for i in range(4):
			camera.make_current(); await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_camera_3d()==camera,"Museum capture retains the intended standing-view camera")
		root.get_texture().get_image().save_png(OUT+"player-view.png")
		loom.set_tartan()
		loom.weave_sample(96)
		check(loom.program.history.size()==96 and studio.layers.records==loom.program.history,"Installed loom shares all 96 tartan picks and yarn colours")
		var thread_colours: Array=loom.program.history[0].warp_colors
		check(thread_colours[0]!=thread_colours[4] and loom.program.history[4].weft_color==thread_colours[4],"Actual hall runs the shared warp/weft colour sett")
		studio.layers.set_gap(.065)
		loom.start_pick(); loom.advance_cycle(1.5)
		camera.global_position=studio.to_global(Vector3(5.8,4.1,7.8)); camera.look_at(studio.to_global(Vector3(0,1.35,.2)));camera.fov=48
		for i in range(5):camera.make_current();await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"tartan-museum.png")
	var passed:=true
	for c in checks:passed=passed and c.passed
	var f:=FileAccess.open(OUT+"museum-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks},"\t"));f.close()
	quit(0 if passed else 1)
