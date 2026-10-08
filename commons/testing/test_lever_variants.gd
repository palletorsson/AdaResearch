extends SceneTree
## Exercise real XRTools pickup and pointer dispatch, not a replacement model.
const OUT := "res://doc/reports/interfaces-2026-09-21/lever-variants/"
var variant := "after"
var checks: Array = []
var failures: Array = []
var world: Node3D
var camera: Camera3D
var pointer: Node3D
class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		held.let_go(self, Vector3.ZERO, Vector3.ZERO)
		held = null
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks.append({"passed":ok, "message":message})
	if not ok: failures.append(message)
	print("LEVER ", "PASS " if ok else "FAIL ", message)
func settle() -> void:
	for i in 6: await process_frame; await physics_frame
func near(a: float, b: float) -> bool: return absf(a-b)<.08
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty(): variant=OS.get_cmdline_user_args()[0]
	world=Node3D.new(); root.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(.09,.11,.14)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color(.9,.93,1)
	env.environment.ambient_light_energy=.8
	world.add_child(env)
	var light:=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-40,-25,0); world.add_child(light)
	camera=Camera3D.new(); world.add_child(camera); camera.current=true
	root.msaa_3d=Viewport.MSAA_4X
	pointer=Node3D.new(); world.add_child(pointer)
	var controls: Array[Node3D]=[]
	for i in 3:
		var type: String=["smooth","snap","zero"][i]
		var control: Node3D=load("res://commons/interactables/lever_"+type+".tscn").instantiate()
		control.position=Vector3((i-1)*.26,1,0); control.rotation_degrees.x=-35
		world.add_child(control); controls.append(control)
		check(control.has_method("pointer_event"),type+": shared pointer interface exists")
		if type=="zero":
			var hinge: Node3D=control.get_node("LeverOrigin/InteractableLever")
			check(hinge.default_on_release and is_zero_approx(hinge.default_position),"Zero variant actually returns to zero degrees")
	await capture("controls",Vector3(.25,1.48,.95),Vector3(0,1,0),55)
	if variant=="after":
		for i in 3: await exercise(controls[i],i)
	for control in controls: control.queue_free()
	await settle()
	if variant=="after": await reference()
	FileAccess.open(OUT+variant+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"\t"))
	quit(0 if variant=="before" or failures.is_empty() else 1)
func capture(tag: String, at: Vector3, target: Vector3, fov: float) -> void:
	camera.position=at; camera.look_at(target); camera.fov=fov
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+variant+"/"+tag+".png")
func exercise(control: Node3D, index: int) -> void:
	var type: String=["smooth","snap","zero"][index]
	for yaw in [0,90]:
		control.rotation_degrees.y=yaw; control.set_angle_degrees(0)
		await settle()
		var tag:=type+" yaw "+str(yaw)
		var handle: Node3D=control.hinge.get_node("HandleOrigin/InteractableHandle")
		for redirect in handle.find_children("GrabPointRedirect*","",true,false):
			check(redirect.target!=null,tag+": hand pose resolves")
		var hand:=TestGrabber.new(); world.add_child(hand)
		hand.global_transform=handle.global_transform; hand.held=handle; handle.pick_up(hand)
		var rest: Vector3=control.hinge.to_local(handle.handle_origin.global_position)
		hand.global_position=control.hinge.get_parent().to_global(Basis(Vector3.RIGHT,deg_to_rad(23))*rest)
		await settle()
		var expected:=25.0 if index==1 else 23.0
		check(near(control.get_angle_degrees(),expected),tag+": held input follows native detent law")
		await settle()
		check(near(control.get_angle_degrees(),expected),tag+": still hand does not drift")
		check(control._reading.label.text==("+25°" if index==1 else "+23°"),tag+": printed value follows the joint")
		hand.drop_object(); hand.queue_free(); await settle()
		check(near(control.get_angle_degrees(),0 if index==2 else expected),tag+": physical release obeys variant")
		check(not control.hinge.is_processing(),tag+": grab driver idles after release")
		check(handle.position.is_equal_approx(Vector3.ZERO),tag+": released handle matches visible grip")
		check((handle.collision_layer & ((1<<20)|(1<<22)))==((1<<20)|(1<<22)),tag+": grip keeps ray layers after release")
		control.set_angle_degrees(0); await settle()
		var query:=PhysicsRayQueryParameters3D.create(control.to_global(Vector3(.075,.02,.3)),control.to_global(Vector3(.075,.02,-.04)),(1<<20)|(1<<22))
		var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(),tag+": real ray reaches mounting face")
		if hit.is_empty(): continue
		var start: Vector3=hit.position
		var end:=start+control.global_basis*Vector3(0,-.06,0)
		XRToolsPointerEvent.pressed(pointer,hit.collider,start)
		# Small motions must accumulate across a detent, regardless of event rate.
		for step in 27:
			var previous:=start.lerp(end,float(step)/27)
			var at:=start.lerp(end,float(step+1)/27)
			XRToolsPointerEvent.moved(pointer,hit.collider,at,previous)
		check(near(control.get_angle_degrees(),25 if index==1 else 27),tag+": 27 small pointer steps accumulate")
		XRToolsPointerEvent.released(pointer,hit.collider,end)
		check(near(control.get_angle_degrees(),0 if index==2 else (25 if index==1 else 27)),tag+": pointer release obeys variant")
		control.set_angle_degrees(1000); check(near(control.get_angle_degrees(),45),tag+": upper stop clamps")
		control.set_angle_degrees(-1000); check(near(control.get_angle_degrees(),-45),tag+": lower stop clamps")
		control.set_angle_degrees(0)
		if index==2:
			for reason in ["exit","focus","lost pointer"]:
				var owner:=Node3D.new(); world.add_child(owner)
				XRToolsPointerEvent.pressed(owner,hit.collider,start)
				XRToolsPointerEvent.moved(owner,hit.collider,end,start)
				if reason=="exit": XRToolsPointerEvent.exited(owner,hit.collider,end)
				elif reason=="focus": control.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
				else: owner.queue_free(); await settle()
				check(near(control.get_angle_degrees(),0) and not control.is_processing(),tag+": "+reason+" returns and idles")
				if is_instance_valid(owner):owner.queue_free()
func reference() -> void:
	var demo: Node3D=load("res://commons/interactables/interactable_lever_demo.tscn").instantiate()
	world.add_child(demo); await settle()
	var ref: Node3D=demo.get_node("LeverReference")
	check(ref.controls.size()==3,"Reference contains all three production levers")
	check(ref.find_children("*","Label3D",true,false).is_empty(),"Reference uses only flat text surfaces")
	check(ref.station.position.z>ref.receivers[0].position.z,"Controls are in front of their receivers")
	check(near(ref.controls[0].position.distance_to(ref.controls[1].position),.24),"Three controls at 24 cm centres")
	await capture("overview",Vector3(.8,1.7,2.1),Vector3(0,1.16,.16),52)
	var hands: Array[TestGrabber]=[]
	for control in ref.controls:
		var h: Node3D=control.hinge.get_node("HandleOrigin/InteractableHandle")
		var hand:=TestGrabber.new();world.add_child(hand);hand.global_transform=h.global_transform;hand.held=h;h.pick_up(hand)
		var rest: Vector3=control.hinge.to_local(h.handle_origin.global_position)
		hand.global_position=control.hinge.get_parent().to_global(Basis(Vector3.RIGHT,deg_to_rad(23))*rest)
		hands.append(hand)
	await settle()
	for i in 3:check(near(ref.receivers[i].rotation_degrees.z,25 if i==1 else 23),"Receiver "+str(i)+" follows its lever")
	await capture("held",Vector3(.12,1.65,1.55),Vector3(0,1.2,.22),48)
	for hand in hands:hand.drop_object();hand.queue_free()
	await settle()
	for i in 3:check(near(ref.receivers[i].rotation_degrees.z,0 if i==2 else (25 if i==1 else 23)),"Receiver "+str(i)+" preserves its release distinction")
	await capture("released",Vector3(.12,1.65,1.55),Vector3(0,1.2,.22),48)
