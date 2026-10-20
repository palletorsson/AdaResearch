extends SceneTree
const DIR:="res://doc/book/iterations/2026-10-09-carousel-the-support-moves/printed/"
const OUT:="res://doc/book/iterations/2026-10-09-carousel-the-support-moves/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("CAROUSEL ","PASS " if ok else "FAIL ",title)
func ticks(n:int=2)->void:
	for i in n:await physics_frame;await process_frame
func pos(body:SoftBody3D)->PackedVector3Array:
	var p:=PackedVector3Array()
	for i in body.rest_points.size():p.append(body.get_point_transform(i))
	return p
func difference(a:PackedVector3Array,b:PackedVector3Array)->float:
	var d:=0.0
	for i in a.size():d=maxf(d,a[i].distance_to(b[i]))
	return d
func pin_error(study:Node3D)->float:
	var error:=0.0
	for i in study.sheet.pins:
		var target:Vector3=study.hub.to_global(Vector3(study.sheet.rest_points[i].x,0,0))
		error=maxf(error,target.distance_to(study.sheet.get_point_transform(i)))
	return error
func angle_error(a:float,b:float)->float:return absf(wrapf(a-b,-PI,PI))
func run()->void:
	check("Prepared project selects Jolt",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
	var host:=Node3D.new();host.position=Vector3(3,.3,-2);host.rotation.y=.6;root.add_child(host)
	var study=load(DIR+"study.gd").new();host.add_child(study);await ticks(3)
	check("Whole program builds caption, driven hub, sheet and pickable point",study.caption.text.contains("rad/s") and study.sheet!=null and study.point.has_method("pick_up") and study.hub.get_child_count()==3)
	check("Inherited sheet has 112 entries and two top-corner attachments",study.sheet.rest_points.size()==112 and study.sheet.pins.size()==2 and study.sheet.mode==1)
	var rest:PackedVector3Array=study.sheet.rest_points.duplicate();var mesh_id:int=study.sheet.mesh.get_instance_id();var body_id:int=study.sheet.get_instance_id();var point_id:int=study.point.get_instance_id()
	check("Inherited response coefficients and contact mask are retained",is_equal_approx(study.sheet.linear_stiffness,.34) and is_equal_approx(study.sheet.damping_coefficient,.05) and is_zero_approx(study.sheet.pressure_coefficient) and study.sheet.collision_mask & study.point.collision_layer!=0)
	study.set_physics_process(false);var start:float=study.phase;study._physics_process(.5)
	check("Rate times half a second advances 0.2 radians",angle_error(study.phase,start+.2)<.00001)
	check("Hub receives the commanded phase",angle_error(study.hub.rotation.y,study.phase)<.00001)
	check("Pinned world targets respect translated and rotated host",pin_error(study)<.001)
	var corners_before:=pos(study.sheet);study.act("REVERSE");study._physics_process(.5)
	check("Reverse changes direction without resetting phase",angle_error(study.phase,start)<.00001 and study.rate<0)
	study.act("SPEED");check("Speed resumes the positive base rate",is_equal_approx(study.rate,.4))
	study.act("SPEED");check("Second speed selection doubles the base rate",is_equal_approx(study.rate,.8))
	study.set_physics_process(true);await ticks(100)
	check("Driven boundary actually changes vertex positions",difference(corners_before,pos(study.sheet))>.05)
	check("Driven pins remain close to the moving targets",pin_error(study)<.025)
	var old_shape:=pos(study.sheet);var old_phase:float=study.phase
	study.act("STOP")
	check("Stop changes rate without replacing or teleporting the body",is_zero_approx(study.rate) and study.sheet.get_instance_id()==body_id and difference(old_shape,pos(study.sheet))<.000001)
	await ticks(35);var after_stop:=pos(study.sheet)
	check("Stopped support retains its phase",angle_error(old_phase,study.phase)<.000001)
	var free_motion:=0.0
	for i in old_shape.size():
		if i not in study.sheet.pins:free_motion=maxf(free_motion,old_shape[i].distance_to(after_stop[i]))
	check("Free entries keep moving after the support stops",free_motion>.005)
	check("Stopped pins retain their target positions",pin_error(study)<.001)
	check("Motion retains mesh identity, reference coordinates and vertex count",study.sheet.mesh.get_instance_id()==mesh_id and study.sheet.rest_points==rest and pos(study.sheet).size()==112)
	var event:=InputEventKey.new();event.keycode=KEY_2;event.pressed=true;study._unhandled_key_input(event)
	check("Reversing zero leaves zero",is_zero_approx(study.rate))
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await ticks();hand.global_position+=Vector3(.1,.1,0);await ticks()
	check("Real supplied XRTools pickup holds the inherited ball",study.point.is_picked_up())
	study.point.action();await ticks();check("Held trigger resumes at the base rate",is_equal_approx(study.rate,.4))
	study.point.action();await ticks();check("Held trigger holds without replacing the sheet",is_zero_approx(study.rate) and study.sheet.get_instance_id()==body_id)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks()
	check("Release returns the same point beside the study",study.point.position.is_equal_approx(Vector3(1.15,1.3,.6)) and study.point.get_instance_id()==point_id)
	study.act("REBUILD");study.set_physics_process(false);await ticks()
	check("Rebuild resets phase and sheet while retaining the point",study.sheet.get_instance_id()!=body_id and is_zero_approx(study.phase) and is_equal_approx(study.rate,.4) and study.point.get_instance_id()==point_id)
	var fast=load(OUT+"variation/study.gd").new();fast.position=Vector3(3,0,0);host.add_child(fast);fast.set_physics_process(false);await ticks()
	study.phase=0;fast.phase=0;study._physics_process(1);fast._physics_process(1)
	check("Full RATE edit doubles the commanded one-second angle",is_equal_approx(study.phase,.4) and is_equal_approx(fast.phase,.8))
	check("Full RATE edit keeps geometry and material settings",fast.sheet.rest_points==rest and is_equal_approx(fast.sheet.linear_stiffness,study.sheet.linear_stiffness))
	fast.set_physics_process(true);await ticks(45);check("Edited-rate host moves its same two attachment targets",pin_error(fast)<.025)
	fast.queue_free();await ticks()
	# Executed faulty complete hosts must fail their specific behavioural invariant.
	for fault in ["fault-delta","fault-targets","fault-stop"]:
		var bad=load(OUT+fault+"/study.gd").new();bad.position=Vector3(6,0,0);host.add_child(bad);bad.set_physics_process(false);await ticks()
		var ph:float=bad.phase;bad._physics_process(.5)
		var rejected:=false
		match fault:
			"fault-delta":rejected=angle_error(bad.phase,ph+.2)>.01
			"fault-targets":rejected=pin_error(bad)>.05
			"fault-stop":
				var id:int=bad.sheet.get_instance_id();bad.act("STOP");rejected=bad.sheet.get_instance_id()!=id or not is_zero_approx(bad.rate)
		check("Invariant rejects "+fault,rejected);bad.queue_free();await ticks()
	observations.free_motion_after_stop=free_motion
	observations.scope="Exact printed program; native Jolt, controlled elapsed intervals, transformed parent, actual pinned and free vertex positions, full RATE edit, three faulty whole hosts, supplied XRTools. No headset or independent student."
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	origin.queue_free();host.queue_free();await ticks();quit(0 if failures.is_empty() else 1)
