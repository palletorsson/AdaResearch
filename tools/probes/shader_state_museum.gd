extends SceneTree
const Field=preload("res://commons/artifacts/shader_state_chamber/field.gd")
const Pointer=preload("res://addons/godot-xr-tools/events/pointer_event.gd")
var checks:Array=[]
var museum:Node3D
var hall:Node3D
var chamber:Node3D
var camera:Camera3D
var origin:Vector3
var output:String
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func settle()->void:
	var f=chamber.field
	while f.busy or f.pending_steps>0 or f.pending_reset>=0 or not f.brush_queue.is_empty():await process_frame
	await RenderingServer.frame_post_draw
func tick()->void:
	for i in range(5):await process_frame
func act(key:String)->void:chamber.buttons[key].get_node("InteractableAreaButton").button_pressed.emit(null)
func photo(title:String,at:Vector3,target:Vector3,fov:float=80)->void:
	camera.global_position=chamber.to_global(at);camera.look_at(chamber.to_global(target));camera.fov=fov
	for i in range(6):camera.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+title+".png")
func routes()->void:
	var route:Array[Vector3]=[Vector3(12.5,0,1.5),Vector3(12.5,0,7.5),Vector3(16,0,7.5),Vector3(16,0,11.5),Vector3(12.5,0,11.5),Vector3(12.5,0,15.9),Vector3(16,0,15.9),Vector3(17.5,0,16),Vector3(17.5,0,20),Vector3(13,0,20),Vector3(13,0,24),Vector3(12.5,0,27)]
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
	check(supported,"Entrance, control approach, wall approach and onward route have floor every 0.25m")
	check(clear,"Standing body clears the control/wall/onward route")

func run()->void:
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(140).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
	museum.set("start_chapter","shaders");museum.set("start_map","Shader_10_ReactionDiffusion");museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
	var begin:=Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec()-begin<65000:await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false):timer.stop()
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map",""))=="Shader_10_ReactionDiffusion":hall=child
	check(hall!=null,"Actual Reaction–Diffusion hall loads")
	if hall==null:quit(1);return
	for node in hall.find_children("*","Node3D",true,false):
		if node.scene_file_path.ends_with("/shader_state_chamber.tscn"):chamber=node
	check(chamber!=null,"State chamber resolves through registry and authored map")
	if chamber==null:quit(1);return
	origin=chamber.global_position-hall.global_basis*Vector3(12.5,0,12.5);camera=Camera3D.new();root.add_child(camera)
	var inventory:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):inventory.append(str(rec.get("token","")))
	for token in ["shader_10_reactiondiffusion","dark_sphere"]:check(inventory.any(func(t):return t.begins_with(token)),"Existing artifact retained: "+token)
	var stream:Node3D=museum.get("_portal_stream")
	check(stream!=null and not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false),"Authored entrance accepted without fallback")
	check(stream!=null and not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false),"Authored exit accepted without fallback")
	print("ONWARD MAP ",museum.call("_peek_next_authored_map"))
	check(chamber.find_children("*","Camera3D",true,false).is_empty() and chamber.find_children("*","WorldEnvironment",true,false).is_empty(),"Chamber adds no camera or global environment")
	check(chamber.receivers.size()==3 and chamber.receivers.all(func(n):return n.material_override==chamber.material),"Wall, sphere and cube read the same state material")
	var f=chamber.field
	check(f.views.size()==16 and f.views.all(func(v):return v.size==Vector2i(96,96) and not v.use_hdr_2d),"Two GPU groups provide eight sequential 96×96 data passes")
	check(not f.running and f.iterations==0,"Starts held with its seed visible")
	act("CLEAR");await settle();f.step(8);await settle()
	var uniform:Image=f.state_texture.get_image()
	check(Field.decode(uniform.get_pixel(40,40)).is_equal_approx(Vector2(1,0)),"Uniform A=1 B=0 survives eight updates")
	act("CLEAR");await settle()
	# Exercise world-coordinate input after the museum has rotated the artifact.
	var point:Vector3=chamber.touch.to_global(Vector3(-.84,-.84,.035))
	Pointer.pressed(camera,chamber.touch,point);Pointer.released(camera,chamber.touch,point);await settle()
	var marked:Image=f.state_texture.get_image();var b:float=Field.decode(marked.get_pixel(33,62)).y
	check(b>.99,"Pointer press marks the expected cell through the rotated wall-to-UV mapping")
	check(Field.decode(marked.get_pixel(62,33)).y<.001,"Asymmetric mark is not mirrored or transposed")
	var saved:PackedByteArray=marked.get_data();await create_timer(.15).timeout
	check(f.state_texture.get_image().get_data()==saved,"After release the held record remains exactly unchanged")
	# Simulated near-hand pose exercises the production proximity path, not an XR device.
	var hand:=Node3D.new();root.add_child(hand);hand.add_to_group("xr_controllers")
	hand.global_position=chamber.touch.to_global(Vector3(1.1,.7,.08))
	await create_timer(.12).timeout;await settle()
	check(Field.decode(f.state_texture.get_image().get_pixel(66,36)).y>.99,"Near-hand pose writes through the production touch path")
	var touched:PackedByteArray=f.state_texture.get_image().get_data();await create_timer(.12).timeout
	check(f.state_texture.get_image().get_data()==touched and f.brush_queue.is_empty(),"Stationary hand does not keep adding new marks")
	hand.global_position=chamber.touch.to_global(Vector3(-1.8,1.8,-.1));await create_timer(.12).timeout;await settle()
	check(f.state_texture.get_image().get_data()==touched,"Hand behind the wall cannot mark its front")
	hand.queue_free();await process_frame
	var iterations:int=f.iterations;act("STEP");await settle()
	check(f.iterations==iterations+1,"STEP advances exactly one update")
	check(f.state_texture.get_image().get_data()!=touched,"One update changes retained concentrations")
	var held:PackedByteArray=f.state_texture.get_image().get_data();act("INK");await tick()
	check(f.state_texture.get_image().get_data()==held and chamber.alternate_ink,"INK changes only the displayed palette")
	act("INK")
	chamber.sliders.FEED._track.move_slider(chamber.sliders.FEED.TRAVEL)
	chamber.sliders.LOSS._track.move_slider(chamber.sliders.LOSS.TRAVEL);await tick()
	check(is_equal_approx(f.feed,.065) and is_equal_approx(f.kill,.07),"Physical FEED/LOSS receivers set the declared parameter range")
	check(f.state_texture.get_image().get_data()==held,"Changing parameters while held does not rewrite the record")
	chamber.set_control("FEED",(.055-.02)/.045);chamber.set_control("LOSS",(.062-.045)/.025)
	act("RUN/HOLD");await create_timer(.12).timeout;act("RUN/HOLD");await settle()
	check(f.iterations>iterations+1 and not f.running,"RUN evolves, HOLD stops after its current batch")
	var stopped:PackedByteArray=f.state_texture.get_image().get_data();await create_timer(.12).timeout
	check(f.state_texture.get_image().get_data()==stopped,"No further update occurs while held")
	act("RESET");await settle();var seed_bytes:PackedByteArray=f.state_texture.get_image().get_data()
	check(f.iterations==0 and not f.running,"RESET restores the seeded field and holds it")
	await photo("seed",Vector3(0,1.7,6),Vector3(0,3,-3.8),90)
	f.step(6000);await settle();var grown:Image=f.state_texture.get_image();var cells:=0
	for y in range(Field.SIZE):
		for x in range(Field.SIZE):
			if Field.decode(grown.get_pixel(x,y)).y>.1:cells+=1
	print("GROWN CELLS ",cells)
	check(cells>500 and f.iterations==6000,"Six thousand updates spread the initial differences beyond their seed discs")
	check(chamber.material.get_shader_parameter("state_texture")==f.state_texture,"Finished buffer is bound to the shared display")
	await physics_frame;routes();museum.get("_player").hide()
	await photo("chamber",Vector3(.6,1.7,5.8),Vector3(0,3,-3.8),92)
	await photo("console",Vector3(-.2,1.7,4.7),Vector3(0,1.22,2.65),105)
	await photo("wall",Vector3(.2,1.7,-.4),Vector3(0,3.2,-3.96),95)
	await photo("sphere",Vector3(-4.6,1.7,2.0),Vector3(-4.8,1.55,-.2),65)
	await photo("cube",Vector3(5.8,1.7,1.5),Vector3(4.8,1.55,-.2),75)
	act("INK");await photo("ink",Vector3(.2,1.7,-.4),Vector3(0,3.2,-3.96),95);act("INK")
	await photo("looks-like-memory",Vector3(-6.5,1.7,-.3),Vector3(-7,2.6,-3.8),75)
	await photo("overview",Vector3(-7.5,4.3,6),Vector3(0,2,-2.5),95)
	await photo("earlier-panels",Vector3(4,1.7,-7.2),Vector3(4,2.1,-10.5),100)
	# Restore, evolve again and compare exact replay of the retained state.
	act("RESET");await settle();check(f.state_texture.get_image().get_data()==seed_bytes,"RESET reproduces exactly the same initial record")
	f.step(16);await settle();var replay:PackedByteArray=f.state_texture.get_image().get_data()
	act("RESET");await settle();f.step(16);await settle()
	check(f.state_texture.get_image().get_data()==replay,"Identical state and update count replay identically on this renderer")
	var passed:bool=checks.all(func(c):return c.passed)
	var file:=FileAccess.open(output+"report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual museum, pointer/control receivers, GPU state retention/evolution/reset, shared receivers and sampled route. Compatibility renderer, XR disabled. No headset, learner, cross-renderer or onward-travel claim."},"\t"));file.close();quit(0 if passed else 1)
