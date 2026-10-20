extends SceneTree
var checks:Array=[]
var museum:Node3D
var hall:Node3D
var origin:Vector3
var camera:Camera3D
var output:String

func _initialize() -> void:call_deferred("run")
func check(ok:bool,title:String) -> void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func photo(title:String,at:Vector3,target:Vector3,fov:float=66) -> void:
	camera.global_position=origin+at;camera.look_at(origin+target);camera.fov=fov
	for i in range(8):camera.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+title+".png")

func run() -> void:
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X
	create_timer(115).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
	museum.set("start_chapter","shaders");museum.set("start_map","Shader_01_Shaping");museum.set("plan_file",output+"plan.json")
	root.add_child(museum);current_scene=museum
	var begin:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-begin<65000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps")
	await create_timer(1).timeout
	for c in museum.get_children():
		if c is Node3D and str(c.get_meta("em_map",""))=="Shader_01_Shaping":hall=c
	check(hall!=null,"Actual Shader_01_Shaping museum hall loads")
	if hall==null:quit(1);return
	origin=hall.global_position+Vector3(0,0,4)
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false):timer.stop()
	var stage:Node3D
	var graphs:Node3D
	for n in hall.find_children("*","Node3D",true,false):
		if n.scene_file_path.ends_with("/shader_shaping_wall.tscn"):stage=n
		if n.scene_file_path.ends_with("/shader_01_shaping.tscn"):graphs=n
	check(stage!=null,"New installation resolved through registry and map placement")
	check(graphs!=null,"Existing five-graph exhibit retained")
	camera=Camera3D.new();root.add_child(camera)
	if stage:
		check(stage.display.material_override==stage.cube_face.material_override,"Wall and cube share one live shader material")
		var wall_before:ArrayMesh=stage.display.mesh if stage.display.mesh is ArrayMesh else null
		var original_mesh:Mesh=stage.display.mesh
		stage.slider._track.move_slider(stage.slider.TRAVEL)
		await process_frame
		check(is_equal_approx(stage.radius,.46),"Actual slider receiver changes radius to upper limit")
		check(is_equal_approx(stage.material.get_shader_parameter("radius"),.46),"Slider change reaches shader uniform")
		stage.buttons.EDGE.get_node("InteractableAreaButton").button_pressed.emit(null)
		check(stage.soft and is_equal_approx(stage.material.get_shader_parameter("softness"),.045),"Actual EDGE button changes boundary softness")
		stage.buttons.RESET.get_node("InteractableAreaButton").button_pressed.emit(null)
		check(is_equal_approx(stage.radius,.30) and not stage.soft,"Actual RESET restores radius and hard edge")
		check(stage.display.mesh==original_mesh,"Changing the mask retains the original receiver mesh")
		check(stage.slider.global_position.y>=1.1 and stage.slider.global_position.y<1.6,"Radius handle mounted within standing reach")
		# Render the shader orthogonally to isolate sampled colour from scene lighting.
		var viewport:=SubViewport.new();viewport.size=Vector2i(128,128);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var quad:=MeshInstance3D.new();var qm:=QuadMesh.new();qm.size=Vector2(2,2);quad.mesh=qm;quad.material_override=stage.material;viewport.add_child(quad)
		var test_camera:=Camera3D.new();test_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;test_camera.size=2;test_camera.position=Vector3(0,0,2);viewport.add_child(test_camera);test_camera.make_current()
		for i in range(6):await process_frame
		await RenderingServer.frame_post_draw
		var image:=viewport.get_texture().get_image()
		check(image.get_pixel(64,64).r>.75,"GPU render: centre is inside the circle")
		check(image.get_pixel(4,4).r<.4,"GPU render: corner is outside the circle")
		check(image.get_pixel(106,64).r<.4,"GPU render: sample outside initial radius is dark")
		stage.set_radius(.46)
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		image=viewport.get_texture().get_image()
		check(image.get_pixel(106,64).r>.75,"GPU render: same sample enters enlarged radius")
		image.save_png(output+"shader-sample.png")
		viewport.queue_free();stage.act("RESET")
	if graphs:
		check(graphs.panels.size()==5 and graphs.wall_setting,"All five graphs receive museum mounting")
		for i in range(5):
			check(graphs.get_node("Display_%d"%i).mesh is QuadMesh,"Graph %d uses complete square UV domain"%i)
			check(graphs.panels[i].global_position.y>.9,"Graph %d controls raised to standing height"%i)
	await physics_frame
	for p in [Vector3(11,0,2),Vector3(11,0,6),Vector3(11,0,11),Vector3(11,0,16),Vector3(11,0,18),Vector3(16.6,0,11),Vector3(3.5,0,10)]:
		var query:=PhysicsRayQueryParameters3D.create(origin+p+Vector3.UP*.3,origin+p-Vector3.UP*.7,1)
		check(not hall.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"Floor supports approach "+str(p))
		var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.6
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.transform=Transform3D(Basis.IDENTITY,origin+p+Vector3.UP*.86);q.collision_mask=1
		var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
		check(hits.is_empty(),"Standing route clear "+str(p))
		for hit in hits:print("BLOCKER ",hit.collider.get_path())
	await photo("entrance",Vector3(11,1.70,1.5),Vector3(19,2,11),76)
	await photo("main-wall",Vector3(14.0,1.70,10.0),Vector3(20,2.1,11),62)
	await photo("controls",Vector3(16.4,1.62,11.4),Vector3(18.1,1.25,11),58)
	await photo("graph-wall",Vector3(7.2,1.70,10),Vector3(1,2.1,10),85)
	await photo("room",Vector3(10,3.3,3.2),Vector3(13,1.8,12),85)
	if stage:
		stage.act("EDGE");stage.set_radius(.40)
		await photo("soft-edge",Vector3(14.0,1.70,10.0),Vector3(20,2.1,11),62)
	var passed:=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(output+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual museum, native render and scripted control receivers; physical headset input not tested."},"\t"));f.close()
	quit(0 if passed else 1)
