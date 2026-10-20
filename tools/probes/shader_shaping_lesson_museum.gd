extends SceneTree
var launcher:Script
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
	# A SceneTree --script loads before project autoloads. Load XR-dependent code afterward.
	launcher=load("res://doc/book/studies/shaders-lineage/shaping_museum.gd")
	root.size=Vector2i(1800,1200);root.msaa_3d=Viewport.MSAA_4X;create_timer(115).timeout.connect(func():quit(98))
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
	museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
	museum.set("start_chapter","shaders");museum.set("start_map","Shader_01_Shaping");museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
	while not bool(museum.get("_museum_core_ready")):await process_frame
	museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
	for node in museum.get_children():
		if node is Node3D and str(node.get_meta("em_map",""))=="Shader_01_Shaping":hall=node
	check(hall!=null,"Actual Shaping hall loads for the learner")
	if hall==null:quit(1);return
	var old:Camera3D=museum.get("_cam")
	if old:
		for timer in old.find_children("*","Timer",true,false):timer.stop()
	study=launcher.mount(hall,launcher.LESSON);camera=Camera3D.new();root.add_child(camera);await tick()
	check(study.receivers.size()==2 and study.readout.is_inside_tree(),"Supplied launcher mounts the extracted three-file program")
	check(is_equal_approx(study.radius,.30),"Museum placement preserves the initial local radius")
	check(study.find_children("*","Camera3D",true,false).is_empty(),"Learner adds no camera to the prepared museum")
	check(study.control.position.is_equal_approx(Vector3(.65,1.2,1.2)),"Point remains at its authored start in the museum")
	var supported:=true;var clear:=true;var capsule:=CapsuleShape3D.new();capsule.height=1.6;capsule.radius=.24
	# Walk from entrance side to the control, then past the left side of the study.
	var path:Array[Vector3]=[Vector3(3,0,2.8),Vector3(0,0,3),Vector3(.65,0,2.0),Vector3(1.7,0,2.0),Vector3(1.7,0,-1)]
	for i in range(1,path.size()):
		var n:=ceili(path[i-1].distance_to(path[i])/.25)
		for j in range(n+1):
			var p:Vector3=study.to_global(path[i-1].lerp(path[i],float(j)/n))
			var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.3,p-Vector3.UP*.7,1);ray.exclude=[museum.get("_player").get_rid()]
			supported=supported and not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.86;query.exclude=ray.exclude
			var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
			for hit in hits:print("BLOCKED ",hit.collider.get_path())
			clear=clear and hits.is_empty()
	check(supported,"Learner approach and bypass have floor support every .25m")
	check(clear,"Standing body clears the learner approach and bypass")
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_transform=study.control.global_transform;study.control.pick_up(pickup);await tick()
	hand.global_position=study.to_global(Vector3(.65,1.6,1.2));await tick()
	check(study.control.is_picked_up() and absf(study.radius-.452)<.015,"Simulated XR pickup carries the point and changes radius")
	study.control.action();await tick();check(study.soft,"Held point action switches the shader edge")
	study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
	check(not study.control.is_picked_up() and study.control.freeze,"Release preserves the carried point's frozen behaviour")
	var radius:float=study.radius;await create_timer(.12).timeout
	check(is_equal_approx(study.radius,radius),"Released height and shader radius remain stable")
	museum.get("_player").hide();xr.queue_free();await tick()
	await photo("student",Vector3(0,1.7,3.1),Vector3(0,1.65,.45),73)
	await photo("in-the-hall",Vector3(-3.5,2.5,3.5),Vector3(-1,1.6,-1),88)
	study.control.position=Vector3(.65,1.2,1.2);study.control.action();await tick()
	await photo("hard",Vector3(0,1.7,3.1),Vector3(0,1.65,.45),73)
	var passed:bool=checks.all(func(c):return c.passed)
	var f:=FileAccess.open(output+"report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Printed learner code temporarily mounted in actual museum by supplied launcher; native GPU, synthetic XR pickup/action/release and sampled walking route. No physical headset, onward travel or learner understanding claim."},"\t"));f.close();quit(0 if passed else 1)
