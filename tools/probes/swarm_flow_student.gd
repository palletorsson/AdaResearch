extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-flow-directions-already-here/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("FLOW ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func fresh(folder:String="printed"):
	return load(OUT+folder+"/field.gd").new()
func one(model,p:Vector2=Vector2(4,8),v:Vector2=Vector2.ZERO) -> void:
	model.positions.assign([p]);model.velocities.assign([v])
func run() -> void:
	var m=fresh()
	check("Six carried positions begin with zero velocity",m.positions.size()==6 and m.velocities.count(Vector2.ZERO)==6)
	check("256 vectors contain a 32-cell northward patch",m.vectors.size()==256 and m.vectors.count(Vector2(0,1))==32)
	check("Periodic lookup wraps both negative and upper boundaries",m.index_at(Vector2(-.1,16.1))==15 and m.index_at(Vector2(16,16))==0)
	one(m)
	check("First desired velocity has declared units and magnitude",m.desired_at(m.positions[0])==Vector2(3,0))
	m.step()
	check("First tick accelerates to 0.3 cells per second",m.velocities[0].is_equal_approx(Vector2(.3,0)))
	check("First tick moves 0.015 cells",m.positions[0].is_equal_approx(Vector2(4.015,8)))
	one(m,Vector2(4,8),Vector2(3,0))
	check("Matching velocity needs no correction",m.acceleration(0).is_zero_approx())
	one(m,Vector2(4,8),Vector2(-3,0))
	check("Opposite velocity is corrected with at most6 cells/s squared",m.acceleration(0).is_equal_approx(Vector2(6,0)))
	one(m,Vector2(8.5,8),Vector2(3,0));m.step()
	check("Entering turning patch retains eastward motion while adding northward motion",m.velocities[0].x>0 and m.velocities[0].x<3 and m.velocities[0].y>0)
	m.patch_mode=1;m.set_patch();one(m,Vector2(8.5,8),Vector2(2,0));m.step()
	check("Zero direction brakes instead of random wandering or coasting",m.velocities[0].is_equal_approx(Vector2(1.8,0)))
	one(m,Vector2(8.5,8));m.step()
	check("Rest in zero field stays at rest",m.velocities[0]==Vector2.ZERO and m.positions[0]==Vector2(8.5,8))
	one(m,Vector2(15.99,2),Vector2(3,0));m.step()
	check("Continuous motion wraps at the declared edge",is_equal_approx(m.positions[0].x,.14))
	m=fresh();var original:PackedVector2Array=m.vectors.duplicate()
	var bounded:=true
	for step in range(1500):
		m.step()
		for i in range(6):
			bounded=bounded and m.velocities[i].length()<=3.00001 and m.positions[i].is_finite() and m.positions[i].x>=0 and m.positions[i].x<16 and m.positions[i].y>=0 and m.positions[i].y<16
	check("1500 steps keep positions finite and velocity bounded",bounded)
	check("1500 steps do not write any field vector",m.vectors==original)
	m=fresh();var n=fresh();n.positions.reverse();n.velocities.reverse()
	for i in range(100):m.step();n.step()
	n.positions.reverse();n.velocities.reverse()
	check("Agent order cannot change this read-only field or motion",m.positions==n.positions and m.velocities==n.velocities and m.vectors==n.vectors)
	var saved:Array=m.positions.duplicate();m.reset()
	for i in range(100):m.step()
	check("Reset reproduces the same motion at tick100",m.positions==saved)
	m=fresh();m.edit_cell(Vector2(2,2));var changed:=0
	for i in range(256):
		if m.vectors[i]!=original[i]:changed+=1
	check("Visitor edit changes exactly one address",changed==1 and m.sample(Vector2(2,2))==Vector2(0,1))
	m.edit_cell(Vector2(2,2));check("Second trigger edit supplies zero",m.sample(Vector2(2,2))==Vector2.ZERO)
	m.edit_cell(Vector2(2,2));check("Third edit returns the same eastward direction",m.sample(Vector2(2,2))==Vector2.RIGHT)
	var p:Array=m.positions.duplicate();var v:Array=m.velocities.duplicate();m.patch_mode=1;m.set_patch()
	check("Patch edit retains positions and velocities",p==m.positions and v==m.velocities and m.vectors.count(Vector2.ZERO)==32)
	var variation=fresh("variation");one(variation,Vector2(8.5,8));variation.step()
	check("Independent southward patch reverses first velocity sign",variation.velocities[0].is_equal_approx(Vector2(0,-.3)))
	var fault=fresh("fault-current");one(fault,Vector2(4,8),Vector2(3,0))
	check("Checker rejects omitted current velocity",not fault.acceleration(0).is_zero_approx())
	fault=fresh("fault-cap");one(fault,Vector2(4,8),Vector2(-3,0))
	check("Checker rejects omitted acceleration limit",fault.acceleration(0).length()>6.0001)
	fault=fresh("fault-write");var before:PackedVector2Array=fault.vectors.duplicate();fault.step()
	check("Checker rejects an agent writing into the supplied field",fault.vectors!=before)
	await host_checks()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code; independent patch variation; three deliberately faulty models; synthetic XRTools. Author-operated, not an independent student or headset assessment."},"  "))
	quit(0 if failures.is_empty() else 1)

func host_checks() -> void:
	var s=load(OUT+"printed/study.tscn").instantiate();root.add_child(s);await ticks();s.set_process(false)
	check("Printed host constructs six points and256 visible direction glyphs",s.points.size()==6 and s.arrows.size()==256 and s.tiles.size()==256)
	var ids:Array=[]
	for point in s.points:ids.append(point.get_instance_id())
	s.get_node("Run").emit_signal("pressed");s._process(.15)
	check("Actual button signal advances three fixed ticks",s.playing and s.field.steps==3)
	var positions:Array=s.field.positions.duplicate();s.get_node("Patch").emit_signal("pressed")
	check("Patch control clears32 directions without restarting motion",s.field.steps==3 and s.field.positions==positions and s.field.vectors.count(Vector2.ZERO)==32 and not s.arrows[136].visible)
	s.get_node("Reset").emit_signal("pressed")
	check("Reset pauses and restores field, positions and zero velocities",not s.playing and s.field.steps==0 and s.field.velocities.count(Vector2.ZERO)==6 and s.field.patch_mode==0)
	var same:=true
	for i in range(6):same=same and s.points[i].get_instance_id()==ids[i]
	check("All edits retain the same PointBody instances",same)
	s.position=Vector3(4,.2,-3);s.rotation.y=.7
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	var point=s.points[0];hand.global_position=point.global_position;point.pick_up(pickup);await ticks()
	check("Carried point attaches to the real XRTools pickup driver",point.held())
	s.playing=true
	var target:=Vector2(2.5,2.5);hand.global_position=s.to_global(s.place(target));await ticks();s._process(.3)
	check("Holding pauses all and records position in the transformed study",s.field.steps==0 and s.field.positions[0].distance_to(target)<.001)
	point.action();await ticks()
	check("Held trigger edits north at its addressed cell",s.field.sample(target)==Vector2(0,1))
	point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	s._process(0)
	check("Released point returns to its field plane",not point.held() and point.position.is_equal_approx(s.place(target)))
	s._process(.05)
	check("Released point reads the edited direction without depositing",s.field.velocities[0].is_equal_approx(Vector2(0,.3)) and s.field.sample(target)==Vector2(0,1))
	check("Readout identifies desired and current velocity with units","Desired" in s.caption.text and "velocity" in s.caption.text and "cells/s" in s.caption.text)
	s.queue_free();xr.queue_free();await ticks()
