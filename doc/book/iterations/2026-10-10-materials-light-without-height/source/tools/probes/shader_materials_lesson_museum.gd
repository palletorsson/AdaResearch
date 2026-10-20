extends SceneTree
var checks:Array=[]
var museum:Node3D
var hall:Node3D
var study:Node3D
var camera:Camera3D
var output:String
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
	checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func tick()->void:
	for i in range(6):await process_frame
func photo(name:String,at:Vector3,target:Vector3,fov:float=72)->void:
	camera.global_position=study.to_global(at);camera.look_at(study.to_global(target));camera.fov=fov
	for i in range(8):camera.make_current();await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+name+".png")
func run()->void:
	# --script initializes before autoloads; delay loading XR-dependent source.
	var launcher=load("res://doc/book/studies/shaders-lineage/materials_museum.gd")
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(115).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
	launcher.configure(museum,output+"learner_control.json")
	var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output+"learner_control.json"))
	check(settings.first_map=="Shader_11_QueerRubber" and not settings.has("travel") and not settings.has("resume_eye"),"Launcher prepares a separate lesson entry without stale travel or resume")
	museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
	while not bool(museum.get("_museum_core_ready")):await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
	for node in museum.get_children():
		if node is Node3D and str(node.get_meta("em_map",""))=="Shader_11_QueerRubber":hall=node
	check(hall!=null,"Actual Materials hall loads for the learner")
	if hall==null:quit(1);return
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false):timer.stop()
	study=launcher.mount(hall,launcher.LESSON)
	check(study!=null,"Supplied launcher finds the actual furnished parlour")
	if study==null:quit(1);return
	camera=Camera3D.new();root.add_child(camera);await tick()
	check(study.receivers.size()==2 and study.readout.is_inside_tree(),"Four extracted files create the study without production geometry helpers")
	check(is_equal_approx(study.strength,.6) and is_equal_approx(study.roughness,.35),"Museum placement preserves starting local values")
	check(study.find_children("*","Camera3D",true,false).is_empty(),"Learner adds no camera to the prepared museum")
	var stage:Node3D=study.get_parent();var chair_start:Transform3D=stage.chair.transform
	var supported:=true;var clear:=true;var capsule:=CapsuleShape3D.new();capsule.height=1.6;capsule.radius=.24
	# Front aisle -> learner control -> clear side; coordinates relative to study.
	var path:Array[Vector3]=[Vector3(-4.5,0,2.8),Vector3(.65,0,2.8),Vector3(.65,0,1.7),Vector3(1.55,0,1.7),Vector3(1.55,0,.3)]
	for i in range(1,path.size()):
		var n:=ceili(path[i-1].distance_to(path[i])/.25)
		for j in range(n+1):
			var p:Vector3=study.to_global(path[i-1].lerp(path[i],float(j)/n))
			var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.3,p-Vector3.UP*.7,1);ray.exclude=[museum.get("_player").get_rid()]
			supported=supported and not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.86;query.exclude=ray.exclude
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
			for hit in hits:print("BLOCKED ",hit.collider.get_path()," at ",study.to_local(p))
			clear=clear and hits.is_empty()
	check(supported,"Approach from parlour aisle has floor support every .25m")
	check(clear,"Standing body clears the approach, control and side of the study")
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
	hand.global_position=study.to_global(Vector3(1.15,1.4,1.2));await tick()
	check(study.control.is_picked_up() and absf(study.strength-1)<.015,"Simulated XR pickup raises relief to full strength")
	check(absf(study.roughness-.60)<.015,"Sideways hand movement controls roughness in the museum frame")
	study.control.action();await tick();check(study.mode==1,"Held point action selects height-map reading")
	study.control.action();await tick();check(study.mode==2,"Next held action selects encoded normals")
	hand.global_position=study.to_global(Vector3(.65,.89,1.2));await tick()
	check(is_zero_approx(study.strength),"Lowering the actual held point reaches zero relief")
	hand.global_position=study.to_global(Vector3(.65,1.4,1.2));await tick()
	study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check(not study.control.is_picked_up() and study.control.freeze,"Release freezes the carried point")
	var strength:float=study.strength;await create_timer(.12).timeout
	check(is_equal_approx(study.strength,strength),"Released relief remains stable")
	check(stage.chair.transform==chair_start,"Learner controls leave the installed furniture unchanged")
	check(study.control.surface.material_override==study.material,"The held point wears the same relief as both squares")
	museum.get("_player").hide();await tick()
	await photo("normal",Vector3(0,1.8,3.3),Vector3(0,1.65,.35),70)
	study.control.action();await tick()
	await photo("flat",Vector3(0,1.8,3.3),Vector3(0,1.65,.35),70)
	study.control.action();await tick()
	await photo("height",Vector3(0,1.8,3.3),Vector3(0,1.65,.35),70)
	# Restore with the same pickup system rather than assigning a frozen body's pose.
	hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
	hand.global_position=study.to_global(Vector3(.65,1.2,1.2));await tick()
	study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);study.control.action();study.control.action();await tick()
	check(absf(study.strength-.6)<.015 and absf(study.roughness-.35)<.015 and study.mode==0,"Carrying point back and cycling restores the opening state")
	xr.queue_free();await tick()
	study.control.action();await tick()
	await photo("in-the-hall",Vector3(-5.8,3.3,2.8),Vector3(-2.5,1.5,-1.7),92)
	var passed:bool=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(output+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Printed learner continuation mounted temporarily in actual parlour; synthetic XR pickup/action/release and sampled route. No physical headset, onward travel or learning claim."},"\t"));f.close();quit(0 if passed else 1)
