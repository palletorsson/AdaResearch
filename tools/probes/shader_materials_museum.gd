extends SceneTree
var checks: Array = []
var museum: Node3D
var hall: Node3D
var stage: Node3D
var camera: Camera3D
var origin: Vector3
var output: String

func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks.append({"passed":ok,"test":title}); print("PASS " if ok else "FAIL ",title)
func tick() -> void:
	for i in range(5): await process_frame
func photo(title: String, at: Vector3, target: Vector3, fov: float = 75) -> void:
	camera.global_position=stage.to_global(at); camera.look_at(stage.to_global(target)); camera.fov=fov
	for i in range(8): camera.make_current(); await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+title+".png")

func pixels() -> void:
	var view:=SubViewport.new(); view.size=Vector2i(128,128); view.own_world_3d=true; view.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(view)
	var env:=WorldEnvironment.new(); env.environment=Environment.new(); env.environment.background_mode=Environment.BG_COLOR; env.environment.background_color=Color.BLACK; env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color=Color.WHITE; env.environment.ambient_light_energy=.4; view.add_child(env)
	var mat: ShaderMaterial=stage.materials[0].duplicate(); mat.set_shader_parameter("rim_amount",0.0)
	var q:=MeshInstance3D.new(); var mesh:=SphereMesh.new(); mesh.radius=.9; mesh.height=1.8; mesh.radial_segments=96; mesh.rings=48; q.mesh=mesh; q.material_override=mat; view.add_child(q)
	var cam:=Camera3D.new(); cam.projection=Camera3D.PROJECTION_ORTHOGONAL; cam.size=2.2; cam.position=Vector3(0,0,3); view.add_child(cam); cam.make_current()
	await tick(); await RenderingServer.frame_post_draw
	var before:=view.get_texture().get_image()
	mat.set_shader_parameter("rim_amount",1.5); await tick(); await RenderingServer.frame_post_draw
	var after:=view.get_texture().get_image()
	print("RIM PIXELS centre ",before.get_pixel(64,64)," -> ",after.get_pixel(64,64)," edge ",before.get_pixel(114,64)," -> ",after.get_pixel(114,64))
	check(after.get_pixel(114,64).g-before.get_pixel(114,64).g>.2,"GPU: the curved silhouette gains an emissive rim")
	check(absf(after.get_pixel(64,64).g-before.get_pixel(64,64).g)<.02,"GPU: the front-facing centre stays unchanged by rim amount")
	var flat:=QuadMesh.new(); flat.size=Vector2(1.5,1.5); q.mesh=flat
	await tick(); await RenderingServer.frame_post_draw
	var facing: Color=view.get_texture().get_image().get_pixel(64,64)
	q.rotation.y=deg_to_rad(70); await tick(); await RenderingServer.frame_post_draw
	var oblique: Color=view.get_texture().get_image().get_pixel(64,64)
	check(oblique.g-facing.g>.2,"GPU: the same flat surface responds to its angle to the eye")
	view.queue_free()

func route_check() -> void:
	# Map-space route from the old room's opening, past the console and around both specimens.
	var route: Array[Vector3]=[Vector3(12,0,2),Vector3(15,0,2),Vector3(15,0,2.2),Vector3(24.5,0,2.2),Vector3(24.5,0,5.5),Vector3(27.5,0,5.5),Vector3(27.5,0,8.5),Vector3(26.3,0,9),Vector3(22.5,0,9),Vector3(22.5,0,5.5),Vector3(24.5,0,5.5),Vector3(24.5,0,2.2)]
	var supported:=true; var clear:=true
	var capsule:=CapsuleShape3D.new(); capsule.radius=.24; capsule.height=1.6
	for i in range(1,route.size()):
		var count:=ceili(route[i-1].distance_to(route[i])/.25)
		for j in range(count+1):
			var at: Vector3=origin+hall.global_basis*route[i-1].lerp(route[i],float(j)/count)
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*.7,1)
			ray.exclude=[museum.get("_player").get_rid()]
			var floor_hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
			if floor_hit.is_empty(): print("FLOOR GAP ",at-origin)
			supported=supported and not floor_hit.is_empty()
			var query:=PhysicsShapeQueryParameters3D.new(); query.shape=capsule; query.collision_mask=1; query.transform.origin=at+Vector3.UP*.86
			query.exclude=[museum.get("_player").get_rid()]
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
			for hit in hits: print("ROUTE BLOCK ",at-origin," ",hit.collider.get_path())
			clear=clear and hits.is_empty()
	check(supported,"Floor supports the old-room connection and new-bay loop at 0.25m intervals")
	check(clear,"A standing body clears the connection, console and specimen loop at 0.25m intervals")

func run() -> void:
	root.size=Vector2i(1800,1200); root.msaa_3d=Viewport.MSAA_4X; create_timer(125).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0])); output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",output+"control.json"); museum.set("_hand_path",output+"necklace_hand.json"); museum.set("_overrides_path",output+"em_overrides.json")
	museum.set("start_chapter","shaders"); museum.set("start_map","Shader_11_QueerRubber"); museum.set("plan_file",output+"plan.json"); root.add_child(museum); current_scene=museum
	var begin:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-begin<65000: await process_frame
	museum.set("_lazy_pending",0); museum.set_process(false); museum.set_physics_process(false); museum.call("flush_stamps"); await create_timer(1).timeout
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false): timer.stop()
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))=="Shader_11_QueerRubber":hall=child
	check(hall!=null,"Actual Queer Materials museum hall loads")
	if hall==null:quit(1);return
	for node in hall.find_children("*","Node3D",true,false):
		if node.scene_file_path.ends_with("/shader_material_parlour.tscn"):stage=node
	check(stage!=null,"Parlour resolves through registry and authored map")
	if stage==null:quit(1);return
	origin=stage.global_position-hall.global_basis*Vector3(24.5,0,8.5)
	check(museum.get("_gate").get("in_doorway",false),"Entry gate sits in the boundary opening rather than across the new setting")
	camera=Camera3D.new(); root.add_child(camera)
	var inventory:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):inventory.append(str(rec.get("token","")))
	for token in ["shader_11_queerrubber","dark_sphere","film_shader_view"]:
		check(inventory.any(func(t):return t.begins_with(token)),"Existing artifact retained: "+token)
	check(museum.call("_peek_next_authored_map")=="Shader_09_FBM","Onward order remains FBM / water")
	check(stage.sofa.scene_file_path.ends_with("/sofa.tscn") and stage.chair.scene_file_path.ends_with("/chair_modern.tscn") and stage.vase.scene_file_path.ends_with("/aalto_vase.tscn"),"Furniture reuses three existing project prefabs")
	check(stage.find_children("*","Camera3D",true,false).is_empty() and stage.find_children("*","WorldEnvironment",true,false).is_empty(),"Imported setting introduces no camera or global environment")
	check(stage.receivers.size()>=9,"Material receivers include both specimens and furniture meshes")
	var meshes:Array=[]; var transforms:Array=[]; var lights:Array=[]
	for receiver in stage.receivers: meshes.append(receiver.mesh); transforms.append(receiver.global_transform)
	for light in stage.find_children("*","Light3D",true,false):lights.append([light,light.global_transform,light.light_energy])
	stage.sliders.ROUGH._track.move_slider(stage.sliders.ROUGH.TRAVEL); await tick()
	check(is_equal_approx(stage.roughness,.95) and is_equal_approx(stage.materials[0].get_shader_parameter("roughness"),.95),"Physical roughness receiver updates the actual material")
	stage.sliders.RIM._track.move_slider(stage.sliders.RIM.TRAVEL); await tick()
	check(is_equal_approx(stage.rim_amount,1.5) and is_equal_approx(stage.materials[0].get_shader_parameter("rim_amount"),1.5),"Physical rim receiver updates the actual study shader")
	for key in ["PLASTIC","VELVET","OIL","STUDY"]:
		stage.buttons[key].get_node("InteractableAreaButton").button_pressed.emit(null); await tick()
		check(stage.NAMES[stage.mode]==key and stage.receivers.all(func(r):return r.material_override==stage.materials[stage.mode]),key+" button assigns one shared material to all receivers")
		check(stage.sliders.RIM.input_enabled==(key=="STUDY") and stage.sliders.RIM._handle.enabled==(key=="STUDY"),key+" has the appropriate rim-control availability")
	stage.act("OIL"); var kept:float=stage.rim_amount; stage.set_control("RIM",0)
	check(is_equal_approx(stage.rim_amount,kept),"Inactive RIM does not alter a different shader")
	stage.set_control("ROUGH",0); check(is_equal_approx(stage.materials[3].get_shader_parameter("roughness"),.05),"Shared roughness remains available in a collection preset")
	stage.buttons.RESET.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(stage.mode==0 and is_equal_approx(stage.roughness,.28) and is_equal_approx(stage.rim_amount,.8),"RESET restores study and both parameters")
	var retained:=true
	for i in range(meshes.size()):retained=retained and stage.receivers[i].mesh==meshes[i] and stage.receivers[i].global_transform.is_equal_approx(transforms[i])
	check(retained,"All mesh resources and placements survive every preset")
	check(lights.all(func(l):return l[0].global_transform.is_equal_approx(l[1]) and is_equal_approx(l[0].light_energy,l[2])),"Local lights retain position and energy through comparison")
	await pixels(); await physics_frame; route_check()
	await photo("parlour",Vector3(0,1.7,6.2),Vector3(0,1.7,-2),85)
	await photo("console",Vector3(-3.4,1.7,6.15),Vector3(-3.4,1.53,4.1),94)
	stage.set_control("RIM",0); await photo("rim-off",Vector3(1.8,1.7,3.5),Vector3(-.6,1.5,1.2),64)
	stage.set_control("RIM",1); await photo("rim-on",Vector3(1.8,1.7,3.5),Vector3(-.6,1.5,1.2),64)
	for key in ["PLASTIC","VELVET","OIL"]:
		stage.act(key); await photo(key.to_lower(),Vector3(0,1.7,6.2),Vector3(0,1.7,-2),85)
	stage.act("RESET"); await photo("overview",Vector3(0,3.7,6.3),Vector3(0,1.6,-1),90)
	await photo("furnished",Vector3(2.4,1.75,3.2),Vector3(-1.2,1.6,-2.6),88)
	var passed:bool=checks.all(func(c):return c.passed)
	var file:=FileAccess.open(output+"report.json",FileAccess.WRITE); file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual museum, control receivers, fixed geometry and GPU rim comparisons. No physical headset or ghost-student reconstruction claim."},"\t"));file.close()
	quit(0 if passed else 1)
