extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-abm-what-the-point-carries/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("ABM ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func fresh(folder: String = "printed"):
	return load(OUT+folder+"/foragers.gd").new()
func one(m,p:Vector2,v:Vector2,carrying:bool) -> void:
	m.positions.assign([p]);m.velocities.assign([v]);m.carrying.assign([carrying])
func equivalent(a,b) -> bool:
	if a.carrying!=b.carrying or a.delivered!=b.delivered:return false
	for i in range(a.positions.size()):
		if a.positions[i].distance_to(b.positions[i])>.00001 or a.velocities[i].distance_to(b.velocities[i])>.00001:return false
	for i in range(a.values.size()):
		if absf(a.values[i]-b.values[i])>.00001:return false
	return true
func run() -> void:
	var m=fresh()
	check("Six searchers start on an empty shared field",m.positions.size()==6 and m.carrying.count(false)==6 and m.values.count(0.0)==256)
	m.step()
	check("An empty-field search coasts east by0.15 cells",m.positions[0].is_equal_approx(Vector2(3.15,7.4)) and m.velocities[0]==Vector2(3,0))
	check("Searching does not deposit",m.values.count(0.0)==256)
	m.reset();one(m,Vector2(12,8),Vector2(3,0),false);m.step()
	check("Food contact switches to returning on the same point",m.carrying==[true] and m.positions.size()==1)
	check("Return requests change acceleration, not velocity instantaneously",m.velocities[0].is_equal_approx(Vector2(2.7,0)) and m.positions[0].is_equal_approx(Vector2(12.135,8)))
	check("Pickup tick deposits at its new position",is_equal_approx(m.values[m.index_at(m.positions[0])],1.0))
	one(m,Vector2(3,8),Vector2.ZERO,true);m.step()
	check("Home contact delivers once and removes cargo",m.delivered==1 and m.carrying==[false])
	check("Delivery starts an eastward departure",m.velocities[0].is_equal_approx(Vector2(.3,0)))
	m.step();check("Another tick near home does not count another delivery",m.delivered==1)
	m=fresh();one(m,Vector2(11,8),Vector2.ZERO,false);m.step()
	check("Contact is strictly inside one cell",m.carrying==[false])
	m=fresh();one(m,Vector2(10.99,8),Vector2(3,0),false);m.step()
	check("Entering food ring during movement waits until next tick",m.carrying==[false] and m.positions[0].x>11)
	m.step();check("Next tick notices the crossing",m.carrying==[true])
	m=fresh();one(m,Vector2(8,8),Vector2(3,0),false)
	m.values[m.index_at(m.sensor_position(0,m.TURN))]=4
	var desired:Vector2=Vector2.RIGHT.rotated(PI/4)*3
	check("Left sample selects familiar search turn",m.search_velocity(0).is_equal_approx(desired))
	var expected:Vector2=Vector2(3,0)+((desired-Vector2(3,0))/.5).limit_length(6)*.05
	m.step();check("Search uses old field before92percent decay",m.velocities[0].is_equal_approx(expected) and is_equal_approx(Array(m.values).max(),3.68))
	m=fresh();one(m,Vector2(8,8),Vector2(3,0),false);m.values.fill(4)
	check("Equal sensor readings keep direction",m.search_velocity(0)==Vector2(3,0))
	m=fresh();one(m,Vector2(8,8),Vector2.ZERO,true);m.values.fill(8);m.step()
	check("Returning ignores even a saturated trail and steers home",m.velocities[0].is_equal_approx(Vector2(-.3,0)) and m.positions[0].is_equal_approx(Vector2(7.985,8)))
	check("Deposits saturate at eight",Array(m.values).max()<=8 and is_equal_approx(m.values[m.index_at(m.positions[0])],8))
	m=fresh();one(m,Vector2(8,8),Vector2.ZERO,false);m.step()
	check("A released stationary searcher gets the declared east fallback",m.velocities[0].is_equal_approx(Vector2(.3,0)))
	one(m,Vector2(15.99,2),Vector2(3,0),false);m.step()
	check("Motion wraps within the carried sixteen-cell plane",m.positions[0].is_equal_approx(Vector2(.14,2)))
	m.values[10]=5;m.delivered=7;var step_count:int=m.steps;m.replace_agents()
	check("Replace resets bodies while keeping field, deliveries and clock",m.positions.size()==6 and m.carrying.count(false)==6 and m.values[10]==5 and m.delivered==7 and m.steps==step_count)
	m.retention=.55;m.return_speed=1.5;m.reset()
	check("Clear All resets all records while retaining chosen parameters",m.values.count(0.0)==256 and m.delivered==0 and m.steps==0 and m.retention==.55 and m.return_speed==1.5)
	m=fresh();var n=fresh();n.positions.reverse();n.velocities.reverse();n.carrying.reverse()
	for i in range(300):m.step();n.step()
	n.positions.reverse();n.velocities.reverse();n.carrying.reverse()
	check("Shared old-field decisions survive reversed traversal",equivalent(m,n))
	check("Unassisted authored arrangement completes a delivery cycle",m.delivered>0)
	var bounded:=true
	for i in range(1500):
		m.step()
		for j in range(6):bounded=bounded and m.positions[j].is_finite() and m.positions[j].x>=0 and m.positions[j].x<16 and m.positions[j].y>=0 and m.positions[j].y<16 and m.velocities[j].length()<=3.00001
	check("1500 further ticks remain finite and speed-bounded",bounded)
	m.reset();n=fresh()
	for i in range(120):m.step();n.step()
	check("Full reset replays the same120 ticks",equivalent(m,n))
	var variation=fresh("variation");one(variation,Vector2(8,8),Vector2.ZERO,true);variation.step()
	check("Independent slower-return edit matches numerical prediction",variation.velocities[0].is_equal_approx(Vector2(-.15,0)) and variation.positions[0].is_equal_approx(Vector2(7.9925,8)))
	var fault=fresh("fault-pickup");one(fault,Vector2(12,8),Vector2.ZERO,false);fault.step()
	check("Executed missing-pickup fault violates transition",not fault.carrying[0])
	fault=fresh("fault-replace");fault.values[10]=5;fault.replace_agents()
	check("Executed destructive-replacement fault loses old marks",fault.values[10]!=5)
	fault=fresh("fault-delivery");one(fault,Vector2(3,8),Vector2.ZERO,true);fault.step();fault.step()
	check("Executed repeated-delivery fault counts twice",fault.delivered==2)
	await host_checks()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code, numerical state transitions, independent speed edit, three executed faulty variants, synthetic XR. Author-operated; not independent learner or physical headset verification."},"  "))
	quit(0 if failures.is_empty() else 1)

func host_checks() -> void:
	var s=load(OUT+"printed/study.tscn").instantiate();root.add_child(s);await ticks();s.set_process(false)
	check("Host builds six unchanged PointBodies and256 field cells",s.points.size()==6 and s.tiles.size()==256 and s.points[0].get_script().get_base_script().resource_path.ends_with("/pickable.gd"))
	var ids:Array=[]
	for p in s.points:ids.append(p.get_instance_id())
	s.get_node("Run").emit_signal("pressed");s._process(.15)
	check("Actual Run control advances three fixed ticks",s.model.steps==3)
	s.model.values[10]=5;s.model.delivered=7;s.get_node("Replace").emit_signal("pressed")
	check("Replace button preserves shared history and pauses",s.model.steps==3 and s.model.delivered==7 and s.model.values[10]==5 and not s.playing)
	s.get_node("Reset").emit_signal("pressed")
	check("Clear All button resets both histories",s.model.steps==0 and s.model.delivered==0 and s.model.values.count(0.0)==256)
	var unchanged:=true
	for i in range(6):unchanged=unchanged and s.points[i].get_instance_id()==ids[i]
	check("Controls reuse the original six sphere instances",unchanged)
	s.position=Vector3(4,.2,-3);s.rotation.y=.7
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	var p=s.points[0];hand.global_position=p.global_position;p.pick_up(pickup);await ticks()
	check("Carried point attaches through real XRTools code",p.held())
	s.playing=true;hand.global_position=s.to_global(s.place(Vector2(12,8)));await ticks();s._process(.3)
	check("Hold pauses and maps hand position under transformed host",s.model.steps==0 and s.model.positions[0].distance_to(Vector2(12,8))<.001 and s.model.velocities[0]==Vector2.ZERO and not s.model.carrying[0])
	p.action();await ticks();check("Held trigger selects that point",s.witness==0)
	s.get_node("Step").emit_signal("pressed");s.get_node("Replace").emit_signal("pressed");s.get_node("Reset").emit_signal("pressed")
	check("Held point blocks ticks and reset operations",s.model.steps==0 and s.model.positions[0].distance_to(Vector2(12,8))<.001)
	p.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	s._process(0);s.get_node("Step").emit_signal("pressed")
	check("Release plus one tick collects food and displays cargo",s.model.carrying[0] and s.cargo[0].visible and not s.sensors[0].visible and s.model.velocities[0].is_equal_approx(Vector2(-.3,0)))
	hand.global_position=p.global_position;p.pick_up(pickup);await ticks();hand.global_position=s.to_global(s.place(Vector2(3,8)));await ticks();s._process(.2)
	check("Dragging a returning body retains its carry state",s.model.carrying[0] and s.cargo[0].visible)
	p.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	s._process(0);s.single_step()
	check("Moving same body home delivers and restores search samples",s.model.delivered==1 and not s.cargo[0].visible and s.sensors[0].visible)
	check("Caption names state, units and delivery count","SEARCH" in s.caption.text and "cells/s" in s.caption.text and "delivered 1" in s.caption.text)
	s.queue_free();xr.queue_free();await ticks()
