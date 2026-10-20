extends SceneTree
const DIR := "res://doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Cloth_Physics/"
const OUT := "res://doc/book/iterations/2026-10-09-cloth-which-points-stay/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("CLOTH ","PASS " if ok else "FAIL ",title)
func ticks(n:int=2)->void:
	for i in n:await physics_frame;await process_frame
func pos(body:SoftBody3D)->PackedVector3Array:
	var p:=PackedVector3Array()
	for i in body.rest_points.size():p.append(body.get_point_transform(i))
	return p
func pins(body:SoftBody3D)->Array[int]:
	var result:Array[int]=[]
	for i in body.rest_points.size():
		if body.is_point_pinned(i):result.append(i)
	return result
func difference(a:PackedVector3Array,b:PackedVector3Array)->float:
	var d:=0.0
	for i in a.size():d=maxf(d,a[i].distance_to(b[i]))
	return d
func run()->void:
	check("Jolt runs the prepared project",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
	var host:=Node3D.new();host.position=Vector3(3,1,-2);host.rotation.y=.6;root.add_child(host)
	var study=load(DIR+"study.gd").new();host.add_child(study);await ticks()
	var body:SoftBody3D=study.sheet
	check("Whole printed program initializes caption, sheet and inherited point",study.caption.text.contains("TOP ROW") and study.point.has_method("pick_up") and body.mesh!=null)
	check("Subdivisions produce 112 reference entries and 8 top pins",body.rest_points.size()==112 and pins(body).size()==8 and pins(body)==body.pins)
	var rest:PackedVector3Array=body.rest_points.duplicate();var flat:=true
	for p in rest:flat=flat and is_zero_approx(p.z) and absf(p.x)<=.601 and absf(p.y)<=.701
	check("Sheet reference positions occupy the local XY plane",flat)
	var before:=pos(body);var top:=pins(body);var frame_correct:=true;var marks_correct:=true
	for j in top.size():
		var i:int=top[j]
		frame_correct=frame_correct and before[i].distance_to(study.to_global(Vector3(0,1.3,0)+rest[i]))<.001
		marks_correct=marks_correct and study.markers.get_child(j).global_position.distance_to(before[i])<.001
	check("Top pins remain in world positions under transformed parent",frame_correct)
	check("Markers agree with actual physics pins",marks_correct)
	check("Open sheet uses zero pressure and inherited point collision layer",is_zero_approx(body.pressure_coefficient) and body.collision_mask & study.point.collision_layer!=0)
	var rid:=body.get_physics_rid();var point_id:int=study.point.get_instance_id()
	study.act("SUPPORT")
	check("Hiding the visible support retains pin set and simulated body",not study.frame.visible and pins(body)==top and body.get_physics_rid()==rid)
	check("Reduced visual support contains no physical collider",study.frame.get_child_count()==0 and study.frame is MeshInstance3D)
	study.act("PINS");var corners:=pins(body)
	check("Corners replace the top row, including unpinning previous points",corners.size()==2 and corners==body.pins)
	check("Boundary selection leaves coefficients and reference positions unchanged",is_equal_approx(body.linear_stiffness,.34) and is_equal_approx(body.damping_coefficient,.05) and is_zero_approx(body.pressure_coefficient) and body.rest_points==rest)
	await ticks(70);var sag:=pos(body);var corner_stays:=true;var middle_moves:=false
	for i in corners:corner_stays=corner_stays and before[i].distance_to(sag[i])<.001
	for i in top:
		if i not in corners:middle_moves=middle_moves or before[i].distance_to(sag[i])>.01
	check("Released upper entries move while corner positions stay fixed",corner_stays and middle_moves)
	study.act("PINS");body=study.sheet;await ticks();var held:=pos(body)
	check("Returning to the full row rebuilds it explicitly",body.get_physics_rid()!=rid and pins(body)==top and held[top[3]].distance_to(before[top[3]])<.001)
	var event:=InputEventKey.new();event.keycode=KEY_X;event.pressed=true;study._unhandled_key_input(event)
	check("Release key clears every pin",pins(body).is_empty() and study.caption.text.contains("RELEASED"))
	await ticks(25)
	check("Released former corner falls",body.get_point_transform(corners[0]).y<held[corners[0]].y-.02)
	study.act("REBUILD");await ticks();body=study.sheet
	check("Rebuild creates a fresh sheet and keeps the same point",body.get_physics_rid()!=rid and pins(body).size()==8 and study.point.get_instance_id()==point_id)
	var restored:=true
	for i in pins(body):restored=restored and body.get_point_transform(i).distance_to(study.to_global(Vector3(0,1.3,0)+rest[i]))<.001
	check("Rebuild restores the original top boundary",restored)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await ticks();hand.global_position+=Vector3(.1,.1,0);await ticks()
	check("Supplied XRTools grip carries the inherited point",study.point.is_picked_up())
	study.point.action();await ticks()
	check("Held trigger selects the two corners",pins(body).size()==2)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks()
	check("Release parks the point in the host frame",study.point.position.is_equal_approx(Vector3(.85,1.3,.3)))
	var variation=load(OUT+"variation/study.gd").new();variation.position=Vector3(3,0,0);host.add_child(variation);await ticks()
	check("Complete subdivision edit has 168 entries and 12 row pins",variation.sheet.rest_points.size()==168 and pins(variation.sheet).size()==12)
	variation.act("PINS");var vp:=pos(variation.sheet);var vi:=pins(variation.sheet);await ticks(40)
	check("Edited resolution still selects two stationary corners",vi.size()==2 and variation.sheet.get_point_transform(vi[0]).distance_to(vp[vi[0]])<.001 and variation.sheet.get_point_transform(vi[1]).distance_to(vp[vi[1]])<.001)
	variation.queue_free();await ticks()
	# Execute three faulty whole hosts. The same behavioural checks must reject them.
	for fault in ["fault-unpin","fault-or","fault-world"]:
		var bad=load(OUT+fault+"/study.gd").new();bad.position=Vector3(6,0,0);host.add_child(bad);await ticks();bad.act("PINS");await ticks()
		check("Boundary invariant rejects "+fault,pins(bad.sheet).size()!=2)
		observations[fault]={"actual_corner_count":pins(bad.sheet).size()};bad.queue_free();await ticks()
	var touch=load(DIR+"study.gd").new();touch.position=Vector3(3,0,0);host.add_child(touch)
	var control=load(DIR+"study.gd").new();control.position=Vector3(6,0,0);host.add_child(control);control.sheet.collision_mask &= ~4
	touch.point.on_desktop_grab(host);control.point.on_desktop_grab(host);await ticks(20)
	var contact_start:=pos(touch.sheet);var control_start:=pos(control.sheet);var contact_difference:=0.0
	for step in 90:
		var at:=Vector3(.085714,1.5,.3-step*.007)
		touch.point.global_position=touch.to_global(at);control.point.global_position=control.to_global(at);await ticks(1)
		var a:=pos(touch.sheet);var b:=pos(control.sheet)
		for i in a.size():contact_difference=maxf(contact_difference,((a[i]-contact_start[i])-(b[i]-control_start[i])).length())
	check("Point contact changes cloth motion versus disabled-contact control",contact_difference>.01)
	observations.contact_difference=contact_difference
	check("Reference coordinates survive selection, release and rebuild",body.rest_points==rest)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Exact printed program, native Jolt, transformed host, supplied XRTools, full edit and three faulty whole-host controls. No physical headset or independent student."},"  "))
	origin.queue_free();host.queue_free();await ticks();quit(0 if failures.is_empty() else 1)
