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
	var launcher=load("res://doc/book/studies/shaders-lineage/water_museum.gd")
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(115).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
	launcher.configure(museum,output+"learner_control.json")
	var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output+"learner_control.json"))
	check(settings.first_map=="Shader_09_FBM" and not settings.has("travel") and not settings.has("resume_eye"),"Launcher prepares a separate lesson entry without stale travel or resume")
	museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
	while not bool(museum.get("_museum_core_ready")):await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
	for node in museum.get_children():
		if node is Node3D and str(node.get_meta("em_map",""))=="Shader_09_FBM":hall=node
	check(hall!=null,"Actual Water hall loads for the learner")
	if hall==null:quit(1);return
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false):timer.stop()
	study=launcher.mount(hall,launcher.LESSON)
	check(study!=null,"Supplied launcher finds the actual bathhouse")
	if study==null:quit(1);return
	camera=Camera3D.new();root.add_child(camera);await tick()
	check(study.surface.mesh is PlaneMesh and study.readout.is_inside_tree(),"Three extracted files create the study without production geometry helpers")
	check(is_equal_approx(study.relief,.15) and minf(study.phase,TAU-study.phase)<.00002,"Museum placement preserves starting local values")
	check(study.find_children("*","Camera3D",true,false).is_empty(),"Learner adds no camera to the prepared museum")
	var stage:Node3D=study.get_parent();var bridge_start:Transform3D=stage.bridge.transform
	var supported:=true;var clear:=true;var capsule:=CapsuleShape3D.new();capsule.height=1.6;capsule.radius=.24
	# Dry entrance apron -> learner point -> outer dry side.
	var path:Array[Vector3]=[Vector3(-6,0,2.5),Vector3(.65,0,2.5),Vector3(.65,0,2.0),Vector3(2,0,2.0),Vector3(2,0,0)]
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
	check(supported,"Approach from bathhouse apron has floor support every .25m")
	check(clear,"Standing body clears the approach, control and side of the study")
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
	hand.global_position=study.to_global(Vector3(1.15,1.4,1.2));await tick()
	check(study.control.is_picked_up() and absf(study.relief-.25)<.005,"Simulated pickup raises relief to its quarter-metre bound")
	check(absf(study.phase-PI)<.015,"Sideways hand movement reads a half-turn in the museum's local frame")
	study.control.action();await tick();check(study.mode==1,"Held point action selects changed normals")
	study.control.action();await tick();check(study.mode==2,"Next held action selects displaced vertices")
	hand.global_position=study.to_global(Vector3(.65,.89,1.2));await tick()
	check(is_zero_approx(study.relief),"Lowering the held point reaches zero displacement")
	hand.global_position=study.to_global(Vector3(.65,1.4,1.2));await tick()
	study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check(not study.control.is_picked_up() and study.control.freeze,"Release freezes the point")
	var phase:float=study.phase;await create_timer(.12).timeout
	check(is_equal_approx(study.phase,phase),"Released field phase remains held")
	check(stage.bridge.transform==bridge_start and not stage.playing,"Learner controls preserve the large bridge and basin's held state")
	check(study.surface.find_children("*","CollisionObject3D",true,false).is_empty(),"Learner water has no collider inside the actual museum")
	var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(0,1.5,0)),study.to_global(Vector3(0,.2,0)),1)
	var hit:=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider==study.bridge,"Small glass support retains its actual collision")
	var p:Vector3=stage.to_global(Vector3(0,0,-8))
	ray=PhysicsRayQueryParameters3D.create(p+Vector3.UP,p-Vector3.UP*2,1);hit=hall.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and stage.bridge.is_ancestor_of(hit.collider),"Large bridge still carries the crossing above the basin")
	museum.get("_player").hide();await tick()
	await photo("height",Vector3(2.6,2.8,3.6),Vector3(-.2,.95,0),74)
	study.control.action();await tick()
	await photo("colour",Vector3(2.6,2.8,3.6),Vector3(-.2,.95,0),74)
	study.control.action();await tick()
	await photo("normal",Vector3(2.6,2.8,3.6),Vector3(-.2,.95,0),74)
	# Compare coarse and fine geometry under identical controls and camera.
	study.control.action();await tick()
	var mesh:PlaneMesh=study.surface.mesh
	mesh.subdivide_width=0;mesh.subdivide_depth=0;await tick()
	await photo("four-corners",Vector3(2.6,2.8,3.6),Vector3(-.2,.95,0),74)
	mesh.subdivide_width=48;mesh.subdivide_depth=48;await tick()
	hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
	hand.global_position=study.to_global(Vector3(.65,1.2,1.2));await tick()
	study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);study.control.action();await tick()
	check(absf(study.relief-.15)<.005 and minf(study.phase,TAU-study.phase)<.015 and study.mode==0,"Carrying the point back and cycling restores the opening reading")
	xr.queue_free();await tick()
	study.control.action();study.control.action();await tick()
	await photo("in-the-hall",Vector3(3.0,4.2,3.8),Vector3(-4,.9,-6),95)
	var passed:bool=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(output+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Printed learner continuation mounted temporarily in actual bathhouse; synthetic XR pickup/action/release and sampled route. No physical headset, onward travel or learning claim."},"\t"));f.close();quit(0 if passed else 1)
