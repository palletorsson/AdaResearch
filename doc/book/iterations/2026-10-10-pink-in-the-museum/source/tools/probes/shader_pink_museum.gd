extends SceneTree
var checks:Array=[]
var museum:Node3D
var hall:Node3D
var stage:Node3D
var camera:Camera3D
var origin:Vector3
var output:String
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func tick()->void:
	for i in range(5):await process_frame
func photo(title:String,at:Vector3,target:Vector3,fov:float=75)->void:
	camera.global_position=stage.to_global(at);camera.look_at(stage.to_global(target));camera.fov=fov
	for i in range(8):camera.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+title+".png")
func pixels()->void:
	var view:=SubViewport.new();view.size=Vector2i(128,128);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.BLACK;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1;view.add_child(env)
	var mat:ShaderMaterial=stage.material.duplicate();mat.set_shader_parameter("room_inverse",Transform3D.IDENTITY);mat.set_shader_parameter("glow",0.0);mat.set_shader_parameter("rim_amount",0.0);mat.set_shader_parameter("dots",1.0)
	var q:=MeshInstance3D.new();var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in [Vector3(-.8,-.8,0),Vector3(-.8,.8,0),Vector3(.8,.8,0),Vector3(-.8,-.8,0),Vector3(.8,.8,0),Vector3(.8,-.8,0)]:
		st.set_normal(Vector3.BACK);st.add_vertex(vertex)
	q.mesh=st.commit();q.material_override=mat;view.add_child(q)
	var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.2;cam.position=Vector3(0,0,3);view.add_child(cam);cam.make_current()
	await tick();await RenderingServer.frame_post_draw
	var patterned:=view.get_texture().get_image()
	var inside:Color=patterned.get_pixel(79,48);var outside:Color=patterned.get_pixel(64,64)
	print("MASK PIXELS ",inside," / ",outside)
	check(inside.r-outside.r>.2,"GPU: projected circle is visible on a mesh with no UV data")
	mat.set_shader_parameter("dots",0.0);await tick();await RenderingServer.frame_post_draw
	var flat:=view.get_texture().get_image()
	check(absf(flat.get_pixel(79,48).r-flat.get_pixel(64,64).r)<.03,"GPU: removing DOTS returns a uniform ground colour")
	var sphere_mesh:=SphereMesh.new();sphere_mesh.radius=.9;sphere_mesh.height=1.8;sphere_mesh.radial_segments=64;sphere_mesh.rings=32;q.mesh=sphere_mesh
	await tick();await RenderingServer.frame_post_draw
	var before:=view.get_texture().get_image();mat.set_shader_parameter("rim_amount",1.5);await tick();await RenderingServer.frame_post_draw
	var after:=view.get_texture().get_image()
	check(after.get_pixel(114,64).g-before.get_pixel(114,64).g>.2,"GPU: RIM brightens the curved edge")
	check(absf(after.get_pixel(64,64).g-before.get_pixel(64,64).g)<.02,"GPU: RIM leaves the front-facing centre unchanged")
	# Use a visibly coloured pigment for emission, not the near-black preset ground.
	mat.set_shader_parameter("ground",Color(.7,.16,.32))
	mat.set_shader_parameter("rim_amount",0.0);env.environment.ambient_light_energy=0;await tick();await RenderingServer.frame_post_draw
	var dark:Color=view.get_texture().get_image().get_pixel(64,64)
	mat.set_shader_parameter("glow",.8);await tick();await RenderingServer.frame_post_draw
	var emitting:Color=view.get_texture().get_image().get_pixel(64,64)
	print("EMISSION PIXELS ",dark," / ",emitting)
	check(dark.r<.03 and emitting.r-dark.r>.2,"GPU: GLOW makes the surface visible without incident light")
	await create_timer(.2).timeout;await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().get_pixel(64,64).is_equal_approx(emitting),"GPU: primary recipe has no clock-driven changes")
	view.queue_free()

func routes()->void:
	var route:Array[Vector3]=[Vector3(7.5,0,1.5),Vector3(7.5,0,2.5),Vector3(12.5,0,2.5),Vector3(15.5,0,2.5),Vector3(27.5,0,2.5),Vector3(27.5,0,5.5),Vector3(27.5,0,7),Vector3(27.5,0,8.5),Vector3(23,0,8.5),Vector3(23,0,11.7),Vector3(32,0,11.7),Vector3(32,0,8.5),Vector3(34,0,8.5),Vector3(34,0,2.5),Vector3(15.5,0,2.5)]
	var supported:=true;var clear:=true;var capsule:=CapsuleShape3D.new();capsule.radius=.24;capsule.height=1.6
	for i in range(1,route.size()):
		var count:=ceili(route[i-1].distance_to(route[i])/.25)
		for j in range(count+1):
			var at:Vector3=origin+hall.global_basis*route[i-1].lerp(route[i],float(j)/count)
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.3,at-Vector3.UP*.7,1);ray.exclude=[museum.get("_player").get_rid()]
			var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty():print("FLOOR GAP ",at-origin)
			supported=supported and not hit.is_empty()
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=at+Vector3.UP*.86;query.exclude=ray.exclude
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
			for block in hits:print("ROUTE BLOCK ",at-origin," ",block.collider.get_path())
			clear=clear and hits.is_empty()
	check(supported,"Connection and composition-stage loop have floor at 0.25m intervals")
	check(clear,"Standing body clears the connection, controls and composition loop")

func run()->void:
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(160).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
	museum.set("start_chapter","shaders");museum.set("start_map","Shader_12_PinkExtravaganza");museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
	var begin:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-begin<65000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false):timer.stop()
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))=="Shader_12_PinkExtravaganza":hall=child
	check(hall!=null,"Actual Pink Extravaganza museum hall loads")
	if hall==null:quit(1);return
	for node in hall.find_children("*","Node3D",true,false):
		if node.scene_file_path.ends_with("/shader_composition_stage.tscn"):stage=node
	check(stage!=null,"Composition stage resolves through the registry and authored map")
	if stage==null:quit(1);return
	origin=stage.global_position-hall.global_basis*Vector3(27.5,0,8.5);camera=Camera3D.new();root.add_child(camera)
	var inventory:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):inventory.append(str(rec.get("token","")))
	for token in ["shader_12_pinkextravaganza","dark_sphere","reference_plural_body"]:check(inventory.any(func(t):return t.begins_with(token)),"Existing artifact retained: "+token)
	check(museum.call("_peek_next_authored_map")=="Shader_10_ReactionDiffusion","Next hall remains Reaction–Diffusion")
	var stream:Node3D=museum.get("_portal_stream")
	check(stream!=null and not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false),"Authored entrance is accepted without a fallback")
	check(stream!=null and not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false),"Authored exit is accepted without a fallback")
	check(stage.sofa.scene_file_path.ends_with("/sofa.tscn"),"Primary furnished receiver is the existing sofa prefab")
	check(stage.receivers.size()==3 and stage.receivers.all(func(m):return m.material_override==stage.material),"One shared material covers sphere, cube and sofa")
	check(stage.find_children("*","Camera3D",true,false).is_empty() and stage.find_children("*","WorldEnvironment",true,false).is_empty(),"Stage introduces no camera or global environment")
	check(stage.material.get_shader_parameter("room_inverse").is_equal_approx(stage.global_transform.affine_inverse()),"Projection frame matches the placed and rotated stage")
	check(stage.ceiling.material_override.shader.resource_path.ends_with("/queer_water.gdshader") and stage.ceiling.find_children("*","CollisionObject3D",true,false).is_empty(),"Ceiling reuses dream water with no collider")
	check(stage.ceiling.basis.y.dot(Vector3.UP)<-.99 and stage.ceiling.position.y-.12>5.0,"Water front face points down above standing head clearance")
	var meshes:Array=[];var transforms:Array=[];var light_state:Array=[]
	for receiver in stage.receivers:meshes.append(receiver.mesh);transforms.append(receiver.global_transform)
	for lamp in stage.lights:light_state.append([lamp,lamp.global_transform,lamp.light_energy,lamp.light_color])
	stage.buttons.PALE.get_node("InteractableAreaButton").button_pressed.emit(null);await tick()
	check(stage.recipe=="PALE" and is_zero_approx(stage.dots) and is_zero_approx(stage.rim_amount) and is_zero_approx(stage.glow),"PALE selects the restrained recipe through its button receiver")
	var pale:Color=stage.ground_colour;var rough:float=stage.roughness
	for key in ["DOTS","RIM","GLOW"]:
		stage.sliders[key]._track.move_slider(stage.sliders[key].TRAVEL);await tick()
		var parameter:String={"DOTS":"dots","RIM":"rim_amount","GLOW":"glow"}[key]
		var expected:float={"DOTS":1.0,"RIM":1.5,"GLOW":.8}[key]
		check(is_equal_approx(stage.material.get_shader_parameter(parameter),expected),key+" physical handle updates its shader channel")
	check(stage.ground_colour==pale and is_equal_approx(stage.roughness,rough),"Editing individual channels preserves the selected ground and roughness")
	stage.buttons.LAYERED.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(stage.recipe=="LAYERED" and is_equal_approx(stage.dots,1) and is_equal_approx(stage.rim_amount,1) and is_equal_approx(stage.glow,.35),"LAYERED restores the composed material recipe")
	var values:Array=[]
	for key in ["ground","ink","edge_colour","dots","rim_amount","glow","roughness","room_inverse"]:values.append(stage.material.get_shader_parameter(key))
	for theatre in [false,true]:
		stage.buttons.SETTING.get_node("InteractableAreaButton").button_pressed.emit(null);await tick()
		check(stage.theatrical==theatre and stage.surroundings.visible==theatre,"SETTING selects "+("theatre" if theatre else "studio"))
		var after:Array=[]
		for key in ["ground","ink","edge_colour","dots","rim_amount","glow","roughness","room_inverse"]:after.append(stage.material.get_shader_parameter(key))
		check(values==after,"Surround switch preserves every primary recipe uniform")
	var retained:=true
	for i in range(meshes.size()):retained=retained and stage.receivers[i].mesh==meshes[i] and stage.receivers[i].global_transform.is_equal_approx(transforms[i])
	check(retained,"Material and setting comparisons retain primary meshes and placements")
	check(light_state.all(func(l):return l[0].global_transform.is_equal_approx(l[1]) and is_equal_approx(l[0].light_energy,l[2]) and l[0].light_color==l[3] and l[0].is_visible_in_tree()),"Stage lamps keep their transforms, energies, colours and visibility")
	check(stage.surroundings.find_children("*","GeometryInstance3D",true,false).all(func(g):return g.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and g.gi_mode==GeometryInstance3D.GI_MODE_DISABLED),"Switchable scenery casts no shadow or GI onto the primary comparison")
	stage.act("PALE");stage.act("SETTING");stage.buttons.RESET.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(stage.recipe=="LAYERED" and stage.theatrical and is_equal_approx(stage.glow,.35),"RESET restores material and theatre together")
	await pixels();await physics_frame;routes()
	museum.get("_player").hide()
	await photo("stage",Vector3(.4,1.7,6.65),Vector3(0,2,-2),90)
	await photo("console",Vector3(-3.2,1.7,7),Vector3(-3.2,1.25,4.85),100)
	stage.act("SETTING");stage.act("PALE");await photo("pale-studio",Vector3(1,1.7,3.7),Vector3(0,1.1,-1.3),85)
	stage.act("LAYERED");await photo("layered-studio",Vector3(1,1.7,3.7),Vector3(0,1.1,-1.3),85)
	stage.act("SETTING");await photo("layered-theatre",Vector3(1,1.7,3.7),Vector3(0,1.1,-1.3),85)
	await photo("above",Vector3(0,1.7,3.2),Vector3(0,5.6,-1),96)
	await photo("chair",Vector3(4.5,1.7,1.2),Vector3(6.05,3,-2.4),75)
	await photo("sofa",Vector3(-1.8,1.7,.45),Vector3(0,1.05,-1.65),78)
	await photo("overview",Vector3(-6.4,3.4,6),Vector3(0,2,-2.3),95)
	# Original collection and the later study are captured in map coordinates.
	await photo("collection",Vector3(18,1.7,-5),Vector3(20,2,0),90)
	await photo("plural-body",Vector3(17,1.7,-13),Vector3(17,2,-18),90)
	var passed:bool=checks.all(func(c):return c.passed)
	var file:=FileAccess.open(output+"report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual museum, physical control receivers, fixed geometry/light comparison, GPU mask/rim/emission and sampled new-bay route. Compatibility renderer, XR disabled. No headset, learner reconstruction or onward travel claim."},"\t"));file.close();quit(0 if passed else 1)
