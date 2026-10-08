extends SceneTree
var checks: Array[Dictionary] = []
func _initialize() -> void:call_deferred("run")
func check(ok: bool,title: String) -> void:
	checks.append({"passed":ok,"test":title})
	print("PASS " if ok else "FAIL ",title)
func run() -> void:
	root.size=Vector2i(1280,900)
	create_timer(150).timeout.connect(func():push_error("Museum film probe timeout");quit(99))
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var item: Dictionary=spec.item
	var folder: String=spec.run
	var museum: Node3D=load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter",item.sequence)
	museum.set("start_map",item.map)
	museum.set("plan_file",folder+"plan.json")
	root.add_child(museum)
	current_scene= museum
	var start:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-start<70000:await process_frame
	museum.set("_lazy_pending",0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1.0).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))==item.map:hall=child
	check(hall!=null,"Actual authored museum hall loads")
	var placed: Node3D
	if hall!=null:
		for node in hall.find_children("*","Node3D",true,false):
			if node.scene_file_path==item.monitor_scene:placed=node;break
	check(placed!=null,"Registered monitor appears in its hall")
	if placed!=null:
		placed.set_process(false)
		placed.set_physics_process(false)
		var stage: Node3D=placed.get("stage")
		check(stage.get("camera").is_current(),"Private film camera remains current after hall embedding")
		var captions_visible:=true
		for layer in stage.find_children("*","CanvasLayer",true,false):captions_visible=captions_visible and layer.visible
		check(captions_visible,"Private film captions survive hall embedding")
		stage.set("playhead",float(stage.get("duration"))*.72)
		stage.set("running",false)
		stage.call("refresh")
		placed.get("pause_label").text="PLAY"
		var eye:=Camera3D.new()
		root.add_child(eye)
		var screen: MeshInstance3D=placed.get("screen")
		var target:=screen.global_position
		var offset: Array=item.get("view_offset",[-.3,0,3.2])
		eye.global_position=target+placed.global_basis*Vector3(offset[0],offset[1],offset[2])
		eye.look_at(target)
		eye.fov=float(item.get("view_fov",68))
		eye.make_current()
		await physics_frame
		var standing_shape := CapsuleShape3D.new()
		standing_shape.radius = .28
		standing_shape.height = 1.5
		var standing_query := PhysicsShapeQueryParameters3D.new()
		standing_query.shape = standing_shape
		standing_query.transform = Transform3D(Basis.IDENTITY,eye.global_position-Vector3(0,.65,0))
		standing_query.collision_mask = 1
		var standing_hits := placed.get_world_3d().direct_space_state.intersect_shape(standing_query)
		check(standing_hits.is_empty(),"Standing space in front of monitor is clear")
		for hit in standing_hits:print("STANDING_BLOCKER ",hit.collider.get_path())
		check(placed.call("is_looking_at_screen",eye),"Clear viewing position")
		for corner in [Vector3(-1.24,-.68,0),Vector3(1.24,-.68,0),Vector3(-1.24,.68,0),Vector3(1.24,.68,0)]:
			var end:=screen.to_global(corner)
			var query:=PhysicsRayQueryParameters3D.create(eye.global_position,end.move_toward(eye.global_position,.002),1)
			var hit:=placed.get_world_3d().direct_space_state.intersect_ray(query)
			check(hit.is_empty(),"Screen corner visible "+str(corner))
			if not hit.is_empty():print("BLOCKER ",hit.collider.get_path())
		for key in placed.get("buttons"):
			var button: Node3D=placed.get("buttons")[key]
			var query:=PhysicsRayQueryParameters3D.create(button.global_position+placed.global_basis.z,button.global_position-placed.global_basis.z*.05,1|(1<<20))
			query.collide_with_areas=true
			var hit:=placed.get_world_3d().direct_space_state.intersect_ray(query)
			check(not hit.is_empty() and hit.collider==button,"Control reachable "+key)
		var time: float=stage.get("playhead")
		placed.call("activate","pause")
		placed.call("_physics_process",.2)
		placed.call("_process",.12)
		check(stage.get("playhead")>time,"Gaze starts the film")
		eye.rotation.y+=PI
		placed.call("_physics_process",.2)
		time=stage.get("playhead")
		placed.call("_process",.12)
		check(stage.get("playhead")==time,"Looking away freezes the film")
		eye.look_at(target)
		placed.call("activate","pause")
		placed.call("_physics_process",.2)
		placed.call("_process",.12)
		check(stage.get("playhead")==time,"Manual pause survives returning gaze")
		placed.get("viewport").render_target_update_mode=SubViewport.UPDATE_ALWAYS
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(spec.output+"museum.png"))
		print("MONITOR_POSITION ",placed.global_position)
		print("MONITOR_ROTATION ",placed.global_rotation_degrees)
	var passed:=true
	for c in checks:passed=passed and bool(c.passed)
	var file:=FileAccess.open(spec.output+"museum-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"map":item.map,"id":item.id,"checks":checks},"\t"))
	file.close()
	quit(0 if passed else 1)
