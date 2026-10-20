extends SceneTree
const OUT="res://doc/book/iterations/2026-10-10-dresses-from-the-loom/"
var checks: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func photo(camera: Camera3D, title: String) -> void:
	for i in range(6):camera.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+title+".png")
func run() -> void:
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X
	create_timer(110).timeout.connect(func():quit(98))
	var folder:="res://ada_run/garment_dresses_review/"
	var museum:Node3D=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json");museum.set("_hand_path",folder+"necklace_hand.json");museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter","tiling");museum.set("start_map","Ribbon_Patterns_03");museum.set("plan_file",folder+"plan.json")
	root.add_child(museum);current_scene=museum
	var start:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start<65000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps")
	await create_timer(1).timeout
	var walker:Camera3D=museum.get("_cam")
	if walker:
		for c in walker.get_children():
			if c is Timer:c.stop()
	var hall:Node3D
	for c in museum.get_children():
		if c is Node3D and str(c.get_meta("em_map",""))=="Ribbon_Patterns_03":hall=c
	check(hall!=null,"Actual final Tiling hall loads")
	var table:Node3D
	if hall:
		var deadline:=Time.get_ticks_msec()+20000
		while table==null and Time.get_ticks_msec()<deadline:
			for n in hall.find_children("*","Node3D",true,false):
				if n.scene_file_path=="res://commons/artifacts/garment_cutting_table/garment_cutting_table.tscn":table=n
			await process_frame
	check(table!=null,"Registered cutting table is installed in the live hall layout")
	if table:
		table.set_process(false)
		var cloth=load("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
		table.set_record(cloth.sample("houndstooth"))
		await physics_frame
		for spot in [Vector3(-1.1,.88,1.85),Vector3(.8,.88,1.4),Vector3(2.15,.88,1.4),Vector3(-2.5,.88,1.85)]:
			var s:=CapsuleShape3D.new();s.radius=.22;s.height=1.4
			var q:=PhysicsShapeQueryParameters3D.new();q.shape=s;q.transform=Transform3D(Basis.IDENTITY,table.to_global(spot));q.collision_mask=1
			var hits:=table.get_world_3d().direct_space_state.intersect_shape(q)
			check(hits.is_empty(),"Standing approach clear at "+str(spot))
			for hit in hits:print("BLOCKER ",hit.collider.get_path())
		var camera:=Camera3D.new();root.add_child(camera);camera.fov=48
		camera.global_position=table.to_global(Vector3(5.8,4.1,7.8));camera.look_at(table.to_global(Vector3(-.3,1.2,0)));table.pose_arm(table.tip)
		await photo(camera,"layout-museum")
		camera.global_position=table.to_global(Vector3(-1.1,4.5,1.2));camera.look_at(table.to_global(Vector3(-1.1,1.0,0)));camera.fov=53
		await photo(camera,"cutting-layout")
		table.act("CUT");table.advance(7);table.pose_arm(table.tip)
		camera.global_position=table.to_global(Vector3(-.5,2.5,4.6));camera.look_at(table.to_global(Vector3(-1.1,1.25,0)));camera.fov=56
		await photo(camera,"cutting")
		table.advance(20);table.act("ASSEMBLE");table.advance(11);table.pose_arm(table.tip)
		camera.global_position=table.to_global(Vector3(5.3,3.4,6.7));camera.look_at(table.to_global(Vector3(-.2,1.3,0)));camera.fov=50
		await photo(camera,"assembly")
		table.advance(20);table.pose_arm(Vector3(.8,2.5,-1.3))
		check(table.phase=="ready" and table.suit.visible,"Installed robot completes all ten panels")
		await photo(camera,"fitted-museum")
		camera.global_position=table.to_global(Vector3(3.3,1.70,2.95));camera.look_at(table.to_global(Vector3(2.15,1.03,-.2)));camera.fov=43
		await photo(camera,"fitted-suit")
		# Dress only the isolated snapshot's wardrobe; the user's save is untouched.
		walker.global_position=table.to_global(Vector3(.9,1.75,2.4));walker.look_at(table.to_global(Vector3(.9,1.75,0)));walker.make_current()
		check(table.wear(),"WEAR reaches the actual museum walker wardrobe")
		var w:Node=museum.get("_wardrobe")
		check(w!=null and w.costume.tailored_suit.visible and w.costume.outfit_id=="tailored_suit","The museum's existing avatar wears the completed suit")
		await create_timer(.4).timeout
		camera.global_position=table.to_global(Vector3(3.7,2.0,5.5));camera.look_at(w.costume.tailored_suit.global_position+Vector3(0,-.6,0));camera.fov=44
		await photo(camera,"worn-suit")
		camera.global_position=table.to_global(Vector3(-1.1,1.68,2.3));camera.look_at(table.to_global(Vector3(-.7,1.2,.0)));camera.fov=78
		await photo(camera,"player-view")

		for shape in ["aline","gown","pleated"]:
			table.act({"aline":"A-LINE","gown":"GOWN","pleated":"PLEATED"}[shape])
			check(table.suit.style==shape and table.record.picks.size()==96,"Installed "+shape+" selector preserves the cloth")
			if shape=="aline":
				camera.global_position=table.to_global(Vector3(-1.1,2.1,2.4));camera.look_at(table.to_global(Vector3(-1.1,1.03,.5)));camera.fov=70
				await photo(camera,"dress-controls")
			table.act("CUT");table.advance(20);table.act("ASSEMBLE");table.advance(20)
			camera.global_position=table.to_global(Vector3(3.1,1.73,3.15));camera.look_at(table.to_global(Vector3(2.15,1.02,-.2)));camera.fov=40
			await photo(camera,"fitted-"+shape)
			walker.make_current()
			check(table.wear() and w.costume.tailored_suit.style==shape,"Actual museum avatar wears "+shape)
			await create_timer(.2).timeout
			camera.global_position=table.to_global(Vector3(2.7,1.65,5.5));camera.look_at(w.costume.tailored_suit.global_position+Vector3(0,-.6,0));camera.fov=42
			await photo(camera,"worn-"+shape)
		table.act("TAKE OFF")
	var passed:=true
	for c in checks:passed=passed and c.passed
	var f:=FileAccess.open(OUT+"museum-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks},"\t"));f.close();quit(0 if passed else 1)
