extends SceneTree
var checks: Array = []
var museum: Node3D
var hall: Node3D
var stage: Node3D
var camera: Camera3D
var origin: Vector3
var output: String

func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title}); print("PASS " if ok else "FAIL ",title)
func tick()->void:
	for i in range(5):await process_frame
func photo(title:String,at:Vector3,target:Vector3,fov:float=75)->void:
	camera.global_position=stage.to_global(at);camera.look_at(stage.to_global(target));camera.fov=fov
	for i in range(8):camera.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+title+".png")

func image_difference(a:Image,b:Image)->float:
	var total:=0.0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			var c:=a.get_pixel(x,y);var d:=b.get_pixel(x,y)
			total+=absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)
	return total/(a.get_width()*a.get_height()*3)
func coverage_difference(a:Image,b:Image)->int:
	var changed:=0
	for y in range(a.get_height()):
		for x in range(a.get_width()):
			var c:=a.get_pixel(x,y);var d:=b.get_pixel(x,y)
			if (c.r>.8 and c.b>.8 and c.g<.1)!=(d.r>.8 and d.b>.8 and d.g<.1):changed+=1
	return changed
func pixels()->void:
	var view:=SubViewport.new();view.size=Vector2i(256,256);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.MAGENTA;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1;view.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-30,0);view.add_child(light)
	var mat:ShaderMaterial=stage.material.duplicate();mat.set_shader_parameter("relief",.25);mat.set_shader_parameter("mode",0);mat.set_shader_parameter("octaves",1)
	var surface:=MeshInstance3D.new();surface.mesh=stage.surface.mesh;surface.material_override=mat;surface.custom_aabb=stage.surface.custom_aabb;view.add_child(surface)
	var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=12;cam.position=Vector3(0,9,7);view.add_child(cam);cam.look_at(Vector3.ZERO);cam.make_current()
	await tick();await RenderingServer.frame_post_draw
	var one:=view.get_texture().get_image()
	mat.set_shader_parameter("octaves",4);await tick();await RenderingServer.frame_post_draw
	var four:=view.get_texture().get_image()
	check(image_difference(one,four)>.002,"GPU: adding octaves changes the sampled colour field")
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	check(image_difference(four,view.get_texture().get_image())<.00001,"GPU: held field remains identical across render frames")
	cam.position=Vector3(0,1.2,9);cam.look_at(Vector3.ZERO);await tick();await RenderingServer.frame_post_draw
	var colour:=view.get_texture().get_image()
	mat.set_shader_parameter("mode",1);await tick();await RenderingServer.frame_post_draw
	var normal:=view.get_texture().get_image()
	check(image_difference(colour,normal)>.0002,"GPU: calculated normals change surface response")
	check(coverage_difference(colour,normal)==0,"GPU: normal mode leaves the flat silhouette unchanged")
	mat.set_shader_parameter("mode",2);await tick();await RenderingServer.frame_post_draw
	var height:=view.get_texture().get_image();var change:=coverage_difference(normal,height);print("DISPLACED PIXELS ",change)
	check(change>5,"GPU: height mode changes the silhouette of the same plane")
	mat.set_shader_parameter("relief",0.0);await tick();await RenderingServer.frame_post_draw
	check(coverage_difference(colour,view.get_texture().get_image())==0,"GPU: zero relief returns height mode to the flat plane")
	view.queue_free()

func route_check()->void:
	var route:Array[Vector3]=[Vector3(12.5,0,1.5),Vector3(12.5,0,5),Vector3(12.5,0,19),Vector3(19,0,19),Vector3(19,0,22),Vector3(23.5,0,22),Vector3(23.5,0,27),Vector3(12.5,0,27)]
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
	check(supported,"Bridge crossing and onward route have floor at 0.25m intervals")
	check(clear,"Standing body clears the bridge and onward route at 0.25m intervals")
	var center:Vector3=stage.to_global(Vector3(0,0,-8))
	var ray:=PhysicsRayQueryParameters3D.create(center+Vector3.UP,center-Vector3.UP*2,1)
	var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and absf(hit.position.y-center.y)<.01 and stage.bridge.is_ancestor_of(hit.collider),"Ray meets the glass bridge at deck height")
	center=stage.to_global(Vector3(3,0,-8));ray=PhysicsRayQueryParameters3D.create(center+Vector3.UP*.3,center-Vector3.UP*2,1);hit=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and absf(hit.position.y-center.y+1.2)<.03,"Beside the bridge, water has no collider; the basin floor lies 1.2m below")

func defaults_check()->void:
	var legacy=load("res://commons/artifacts/basin_water/basin_water.tscn").instantiate();legacy.position=Vector3(1000,0,0);root.add_child(legacy)
	check(legacy._study==null and legacy._mesh.material_override.shader.resource_path.ends_with("/basin_water.gdshader") and legacy._mesh.mesh.size==Vector2(5,5),"Unconfigured BasinWater retains the original shader and dimensions")
	legacy.apply_grid_config({"study":"on"});await tick()
	check(is_instance_valid(legacy._study),"Study can be installed after tree entry")
	legacy.apply_grid_config({"study":"off"});await tick()
	check(legacy._study==null and legacy._mesh.material_override.shader.resource_path.ends_with("/basin_water.gdshader") and legacy.find_children("WaterStudy","Node3D",true,false).is_empty(),"Opting out restores the legacy surface and removes study geometry")
	legacy.queue_free()
	var original=load("res://algorithms/shaders/book_of_shaders/shader_09_fbm.tscn").instantiate();original.position=Vector3(1000,0,0);root.add_child(original)
	check(original._displays.all(func(d):return d.mesh is BoxMesh) and original.panels.all(func(p):return is_equal_approx(p.position.y,.5)),"Unconfigured supporting rack keeps its original display geometry and height")
	original.queue_free()

func run()->void:
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(150).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
	museum.set("start_chapter","shaders");museum.set("start_map","Shader_09_FBM");museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
	var begin:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-begin<65000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false):timer.stop()
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))=="Shader_09_FBM":hall=child
	check(hall!=null,"Actual FBM museum hall loads")
	if hall==null:quit(1);return
	var basin:Node3D;var rack:Node3D
	for node in hall.find_children("*","Node3D",true,false):
		if node.scene_file_path.ends_with("/basin_water.tscn"):basin=node
		if node.scene_file_path.ends_with("/shader_09_fbm.tscn"):rack=node
	check(basin!=null and is_instance_valid(basin.get("_study")),"Existing BasinWater resolves its opt-in study")
	if basin==null or not is_instance_valid(basin.get("_study")):quit(1);return
	stage=basin.get("_study");origin=basin.global_position-hall.global_basis*Vector3(12.5,0,4.5);camera=Camera3D.new();root.add_child(camera)
	check(not museum.get("_gate").get("active",false),"No additional gate blocks the entrance")
	var stream:Node3D=museum.get("_portal_stream")
	check(stream!=null and not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false),"Authored entrance is accepted without a fallback")
	check(stream!=null and not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false),"Authored exit is accepted without a fallback")
	check(museum.call("_peek_next_authored_map")=="Shader_12_PinkExtravaganza","Next hall remains Pink Extravaganza")
	var inventory:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):inventory.append(str(rec.get("token","")))
	for token in ["basin_water","dark_sphere","shader_09_fbm"]:check(inventory.any(func(t):return t.begins_with(token)),"Existing artifact retained: "+token)
	check(rack!=null and rack.get("_displays").size()==4 and rack.get("_displays").all(func(d):return d.mesh is QuadMesh),"Four supporting graphs use full square UVs")
	check(rack!=null and rack.panels.all(func(p):return p.position.y>=1.0),"Supporting controls are raised to hand height")
	check(stage.find_children("*","Camera3D",true,false).is_empty() and stage.find_children("*","WorldEnvironment",true,false).is_empty(),"Setting introduces no camera or global environment")
	var kept_mesh:Mesh=stage.surface.mesh;var kept_transform:Transform3D=stage.surface.global_transform;var kept_bridge:Transform3D=stage.bridge.global_transform
	stage.sliders.SCALES._track.move_slider(stage.sliders.SCALES.TRAVEL);await tick()
	check(stage.octaves==4 and stage.material.get_shader_parameter("octaves")==4,"Physical SCALES handle updates octaves in the shader")
	stage.sliders.RELIEF._track.move_slider(stage.sliders.RELIEF.TRAVEL);await tick()
	check(is_equal_approx(stage.relief,.25) and is_equal_approx(stage.material.get_shader_parameter("relief"),.25),"Physical RELIEF handle updates the displacement bound")
	for key in ["COLOUR","NORMAL","HEIGHT"]:
		stage.buttons[key].get_node("InteractableAreaButton").button_pressed.emit(null);await tick()
		check(stage.MODES[stage.mode]==key and stage.material.get_shader_parameter("mode")==stage.mode,key+" button selects the corresponding shader operation")
	var held:float=stage.phase;await create_timer(.2).timeout
	check(is_equal_approx(stage.phase,held),"Default phase stays held across frames")
	stage.buttons.TIME.get_node("InteractableAreaButton").button_pressed.emit(null);await create_timer(.2).timeout
	check(stage.phase>held,"TIME button advances the field")
	stage.buttons.TIME.get_node("InteractableAreaButton").button_pressed.emit(null);held=stage.phase;await create_timer(.2).timeout
	check(is_equal_approx(stage.phase,held),"TIME button holds the current phase")
	stage.buttons.RESET.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(stage.mode==2 and stage.octaves==3 and is_equal_approx(stage.relief,.22) and is_zero_approx(stage.phase) and not stage.playing,"RESET restores the held three-scale height study")
	check(stage.surface.mesh==kept_mesh and stage.surface.global_transform.is_equal_approx(kept_transform) and stage.bridge.global_transform.is_equal_approx(kept_bridge),"Controls keep the mesh resource, placement and bridge fixed")
	check(is_equal_approx(stage.surface.position.y,-.4) and stage.surface.position.y+.25<-.06,"Normalized field bounds keep even maximum relief below the bridge bottom")
	check(stage.surface.find_children("*","CollisionObject3D",true,false).is_empty(),"Visual water owns no collider")
	await pixels();await defaults_check();await physics_frame;route_check()
	# Detached inspection cameras should not render the player's costume at its
	# original spawn while pretending it belongs to the exhibit.
	museum.get("_player").hide()
	await photo("bathhouse",Vector3(.7,1.7,3.7),Vector3(0,1,-10),84)
	await photo("console",Vector3(-3.3,1.7,3.25),Vector3(-3.3,1.52,1.1),98)
	await photo("bridge",Vector3(0,1.65,-5),Vector3(2,-.4,-10),83)
	for key in ["COLOUR","NORMAL","HEIGHT"]:
		stage.act(key);await photo(key.to_lower(),Vector3(5.95,1.65,-8),Vector3(0,-.4,-8),73)
	stage.set_control("SCALES",0);await photo("one-scale",Vector3(5.95,1.65,-8),Vector3(0,-.4,-8),73)
	stage.set_control("SCALES",1);await photo("four-scales",Vector3(5.95,1.65,-8),Vector3(0,-.4,-8),73)
	stage.act("RESET");await photo("overview",Vector3(9,5.4,2.5),Vector3(0,.1,-8),88)
	await photo("graphs",Vector3(0,1.7,-16),Vector3(0,2,-20),100)
	var passed:bool=checks.all(func(c):return c.passed)
	var file:=FileAccess.open(output+"report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual museum; physical control receivers; GPU mode/octave/hold/silhouette tests; sampled bridge/onward route. Compatibility renderer, XR disabled. No headset or learner reconstruction claim."},"\t"));file.close();quit(0 if passed else 1)
