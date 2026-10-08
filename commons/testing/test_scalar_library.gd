extends SceneTree
## Actual library instances, native pickup, ray dispatch and live text sinks.
const OUT := "res://doc/reports/interfaces-2026-09-21/scalar-controls/"
var variant := "after"
var checks: Array = []
var failures: Array = []
var world: Node3D
var library: Node3D
var camera: Camera3D
var pointer: Node3D
class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		if is_instance_valid(held): held.let_go(self, Vector3.ZERO, Vector3.ZERO)
		held = null
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	print("SCALAR ", "PASS " if ok else "FAIL ", message)
	checks.append({"passed":ok,"message":message})
	if not ok: failures.append(message)
func settle() -> void:
	for i in 6: await process_frame; await physics_frame
func limits(joint: Node3D, angular: bool, axis: bool) -> Vector2:
	if angular:return Vector2(joint.hinge_limit_min,joint.hinge_limit_max)
	if axis:return Vector2(joint.limit_min,joint.limit_max)
	return Vector2(joint.slider_limit_min,joint.slider_limit_max)
func value(joint: Node3D, angular: bool, axis: bool) -> float:
	if angular:return joint.hinge_position
	if axis:return joint.slider_value
	return joint.slider_position
func move(joint: Node3D, v: float, angular: bool) -> void:
	if angular:joint.move_hinge(deg_to_rad(v))
	else:joint.move_slider(v)
func run() -> void:
	if not OS.get_cmdline_user_args().is_empty():variant=OS.get_cmdline_user_args()[0]
	world=Node3D.new();root.add_child(world)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.08,.10,.13)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.8
	world.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-25,0);world.add_child(light)
	library=load("res://commons/ui/demo/vr_component_demo.tscn").instantiate();world.add_child(library)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;camera.position=Vector3(.1,1.65,.9);camera.look_at(Vector3(0,1.16,0));camera.fov=65
	pointer=Node3D.new();world.add_child(pointer)
	for page in [0,1,2,7,8]:
		library.show_page(page);await settle()
		await capture("page-%d" % page)
		for i in library.controls.size():
			var control:Node3D=library.controls[i]
			var angular:=control.has_node("DialOrigin/InteractableHinge")
			if not angular and not control.has_node("SliderOrigin/InteractableSlider"):continue
			var joint:Node3D=control.get_node("DialOrigin/InteractableHinge" if angular else "SliderOrigin/InteractableSlider")
			var axis:=joint.get("slider_value")!=null
			var auto:bool=joint.get("auto_drive")==true
			if axis:joint.auto_drive=false
			for yaw in [0,90]:
				library.rotation_degrees.y=yaw;await settle()
				await exercise(control,joint,angular,axis,"page%d/%d yaw%d" % [page,i,yaw])
			if axis:
				joint.auto_drive=auto
				if auto:
					var old:float=joint.slider_value;await settle()
					check(absf(joint.slider_value-old)>.00001,"Axis automatic motion resumes after release")
					var start:Vector3=control.global_position
					control.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,control,start,start))
					old=joint.slider_value;await settle()
					check(not joint.auto_drive and absf(joint.slider_value-old)<.00001,"Pointer holds the automatic axis still")
					control.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,control,start,start))
					check(joint.auto_drive,"Automatic axis resumes after pointer release")
		library.rotation_degrees.y=0
		await capture("operated-%d" % page)
	var chooser:Node3D=load("res://commons/interactables/slider_horizontal.tscn").instantiate();world.add_child(chooser)
	chooser.set_choices(["A","B","C"])
	for index in 3:
		chooser.set_normalized_value(float(index)/2)
		check(chooser.get_node("Frame/Label3DValue").text==["A","B","C"][index],"Discrete chooser reaches option "+str(index))
	chooser.set_choices([]);chooser.set_normalized_value(.37)
	check(absf(chooser.get_normalized_value()-.37)<.001,"Clearing choices restores smooth travel")
	chooser.queue_free()
	FileAccess.open(OUT+variant+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"\t"))
	quit(0 if variant=="before" or failures.is_empty() else 1)
func capture(tag:String)->void:
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+variant+"/"+tag+".png")
func exercise(control:Node3D,joint:Node3D,angular:bool,axis:bool,tag:String)->void:
	var bounds:=limits(joint,angular,axis)
	if not angular: verify_endpoints(control,joint,axis,tag)
	var centre:=bounds.x+(bounds.y-bounds.x)*.5
	move(joint,centre,angular);await settle()
	var handle:Node3D=joint.find_children("InteractableHandle","RigidBody3D",true,false)[0]
	var at:=control.to_local(handle.global_position)
	check(at.z>=.004 and absf(at.x)<.05 and absf(at.y)<.06,tag+": grip starts on the centred front face")
	var hand:=TestGrabber.new();world.add_child(hand);hand.global_transform=handle.global_transform;hand.held=handle;handle.pick_up(hand)
	var rest:Vector3=joint.to_local(handle.handle_origin.global_position)
	for fraction in [.8,.2]:
		var target:=lerpf(bounds.x,bounds.y,fraction)
		if angular:hand.global_position=joint.get_parent().to_global(Basis(Vector3.RIGHT,deg_to_rad(target))*rest)
		else:hand.global_position=joint.get_parent().to_global(rest+(Vector3.UP if axis else Vector3.RIGHT)*target)
		await settle()
		var tolerance:=2.0 if angular else (bounds.y-bounds.x)*.052
		check(absf(value(joint,angular,axis)-target)<tolerance,tag+": physical grab reaches "+str(fraction))
		var stationary:=value(joint,angular,axis);await settle()
		check(absf(value(joint,angular,axis)-stationary)<.001,tag+": a still hand does not drift")
	check(library._has_held_control(),tag+": held control prevents page replacement")
	var before_release:=value(joint,angular,axis)
	hand.drop_object();hand.queue_free();await settle()
	var expected:float=(joint.default_value if axis else joint.default_position) if joint.default_on_release else before_release
	check(absf(value(joint,angular,axis)-expected)<.001,tag+": native release respects variant")
	check(not joint.is_processing(),tag+": manual driver idles after release")
	move(joint,centre,angular);await settle()
	var query:=PhysicsRayQueryParameters3D.create(control.to_global(Vector3(.012,.015,.3)),control.to_global(Vector3(.012,.015,-.03)),(1<<20)|(1<<22))
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and control.is_ancestor_of(hit.collider) and hit.collider.has_method("pointer_event"),tag+": real ray reaches an interactive surface")
	if hit.is_empty() or not control.is_ancestor_of(hit.collider) or not hit.collider.has_method("pointer_event"):return
	var start:Vector3=hit.position
	var delta:Vector3=control.global_basis*Vector3(0,.1,0) if angular else joint.get_parent().global_basis*(Vector3.UP if axis else Vector3.RIGHT)*(bounds.y-bounds.x)*.3
	var end:Vector3=start+delta
	XRToolsPointerEvent.pressed(pointer,hit.collider,start)
	for i in 30:XRToolsPointerEvent.moved(pointer,hit.collider,start+delta*float(i+1)/30,start+delta*float(i)/30)
	var wanted:=centre+30 if angular else lerpf(bounds.x,bounds.y,.8)
	check(absf(value(joint,angular,axis)-wanted)<(2 if angular else (bounds.y-bounds.x)*.052),tag+": small pointer steps follow panel-local motion")
	check(library._has_held_control(),tag+": pointer drag prevents page replacement")
	var other:=Node3D.new();world.add_child(other)
	var owned:=value(joint,angular,axis)
	XRToolsPointerEvent.pressed(other,hit.collider,start);XRToolsPointerEvent.moved(other,hit.collider,start-delta,start);XRToolsPointerEvent.released(other,hit.collider,start)
	check(absf(value(joint,angular,axis)-owned)<.001,tag+": a second pointer cannot steal input")
	other.queue_free()
	XRToolsPointerEvent.released(pointer,hit.collider,end)
	expected=(joint.default_value if axis else joint.default_position) if joint.default_on_release else owned
	check(absf(value(joint,angular,axis)-expected)<.001,tag+": pointer release respects variant")
	move(joint,centre,angular)
	XRToolsPointerEvent.pressed(pointer,hit.collider,start)
	XRToolsPointerEvent.moved(pointer,hit.collider,end,start)
	control.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if joint.default_on_release:check(absf(value(joint,angular,axis)-expected)<.001,tag+": focus loss returns to default")
	XRToolsPointerEvent.released(pointer,hit.collider,end)
	var lost:=Node3D.new();world.add_child(lost)
	XRToolsPointerEvent.pressed(lost,hit.collider,start);XRToolsPointerEvent.moved(lost,hit.collider,end,start)
	lost.queue_free();await settle()
	check(not library._has_held_control(),tag+": lost pointer releases the page guard")
	if joint.default_on_release:check(absf(value(joint,angular,axis)-expected)<.001,tag+": lost pointer returns to default")
	if control.has_method("set_normalized_value"):
		control.set_normalized_value(2)
		check(absf(control.get_normalized_value()-1)<.001,tag+": normalized setter clamps to the actual range")
		if control.has_method("set_range"):
			control.set_range(0,1)
			check(control.get_node("Frame/Label3DValue").text.to_float()<=1,tag+": value text agrees with the stopped control")
		control.set_normalized_value(.5)

func verify_endpoints(control:Node3D,joint:Node3D,axis:bool,tag:String)->void:
	var range_limits:=limits(joint,false,axis)
	var panel:MeshInstance3D
	for mesh in control.get_node("Frame").get_children():
		if mesh is MeshInstance3D and mesh.mesh is BoxMesh:
			panel=mesh;break
	if panel==null:return
	var frame_box:AABB=(control.global_transform.affine_inverse()*panel.global_transform)*panel.get_aabb()
	var centres:Array[Vector3]=[]
	for end in [0,1]:
		joint.move_slider(range_limits.x-1 if end==0 else range_limits.y+1)
		check(absf(value(joint,false,axis)-(range_limits.x if end==0 else range_limits.y))<.00001,tag+": hard stop clamps "+str(end))
		var fits:=true
		for mesh in joint.find_children("*","MeshInstance3D",true,false):
			if not mesh.is_visible_in_tree():continue
			var box:AABB=(control.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
			fits=fits and box.position.x>=frame_box.position.x-.001 and box.end.x<=frame_box.end.x+.001
			fits=fits and box.position.y>=frame_box.position.y-.001 and box.end.y<=frame_box.end.y+.001
		check(fits,tag+": visible grip stays inside backing at endpoint "+str(end))
		var origin:Node3D=joint.find_child("HandleOrigin",true,false)
		centres.append(control.to_local(origin.global_position))
	var travel:Vector3=centres[1]-centres[0]
	var horizontal:=control.name=="SliderHorizontal" or control.name=="VRAudioControlSlider"
	check((travel.x>.1 and absf(travel.y)<.001) if horizontal else (travel.y>.1 and absf(travel.x)<.001),tag+": maximum is rightward on a horizontal slot and upward on a vertical slot")
