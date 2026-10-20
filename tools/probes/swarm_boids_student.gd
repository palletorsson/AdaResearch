extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-boids-who-is-near/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("BOIDS ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func fresh(folder: String = "printed"):
	return load(OUT+folder+"/flock.gd").new()
func same(a,b,tolerance:float = 0.00001) -> bool:
	for i in range(a.positions.size()):
		if a.positions[i].distance_to(b.positions[i])>tolerance or a.velocities[i].distance_to(b.velocities[i])>tolerance:return false
	return true
func run() -> void:
	var m=fresh()
	check("Six carried points retain explicit initial positions and velocities",m.positions.size()==6 and m.velocities[0]==Vector2(1,0))
	check("Local radius selects only points1 and2 for point0",m.neighbours(0)==[1,2])
	var r:Array=m.requests(0)
	check("Separation points left with bounded acceleration",r[0].is_equal_approx(Vector2(-6,0)))
	check("Alignment matches actual average velocity including speed",r[1].is_equal_approx(Vector2(-2,4)))
	var expected_cohesion:Vector2=(Vector2(1.5,.5).normalized()*3-Vector2(1,0))/.5
	check("Cohesion uses local mean offset and familiar steering",r[2].is_equal_approx(expected_cohesion))
	check("Weighted separation is capped again after combination",m.acceleration(0).is_equal_approx(Vector2(-6,0)))
	m.step()
	check("First separation tick slows rightward velocity to0.7",m.velocities[0].is_equal_approx(Vector2(.7,0)))
	check("First separation tick advances position by0.035",m.positions[0].is_equal_approx(Vector2(6.035,8)))
	m.reset();m.mode=1;m.step()
	check("First alignment tick is independently predicted0.9,0.2",m.velocities[0].is_equal_approx(Vector2(.9,.2)))
	m.reset();m.mode=2;m.step()
	check("First cohesion tick follows independently computed local centre",m.velocities[0].is_equal_approx(Vector2(1,0)+expected_cohesion*.05))
	m.reset();m.mode=3
	check("All-three mode sums weighted requests then caps",m.acceleration(0).is_equal_approx((Vector2(-9,0)+Vector2(-2,4)+expected_cohesion).limit_length(6)))
	m.radius=2
	check("Smaller radius drops point2 but retains close separation",m.neighbours(0)==[1] and m.requests(0)[0].is_equal_approx(Vector2(-6,0)) and not m.requests(0)[2].is_equal_approx(expected_cohesion))
	m.positions.assign([Vector2(5,5),Vector2(7,5)]);m.velocities.assign([Vector2.ZERO,Vector2.ZERO])
	check("Exactly-on-radius neighbour is excluded",m.neighbours(0).is_empty())
	m.positions.assign([Vector2(5,5),Vector2(5,5)]);m.velocities.assign([Vector2(1,0),Vector2(0,1)]);r=m.requests(0)
	check("Distinct coincident bodies count as neighbours without division by zero",m.neighbours(0)==[1] and r[0]==Vector2.ZERO and r[1].is_equal_approx(Vector2(-2,2)) and r[2]==Vector2.ZERO)
	m.positions.assign([Vector2(5,5)]);m.velocities.assign([Vector2(1,0)]);m.mode=3;m.step()
	check("No neighbours means coasting and no self-alignment brake",m.velocities[0]==Vector2(1,0) and m.positions[0].is_equal_approx(Vector2(5.05,5)))
	m.positions.assign([Vector2(5,5),Vector2(6,5)]);m.velocities.assign([Vector2(1,0),Vector2.ZERO]);m.mode=1;m.step()
	check("Stationary neighbours request braking instead of coasting",m.velocities[0].is_equal_approx(Vector2(.9,0)))
	m.positions.assign([Vector2(8,8),Vector2(7,8),Vector2(9,8)]);m.velocities.assign([Vector2(1,0),Vector2.ZERO,Vector2.ZERO]);r=m.requests(0)
	check("Balanced separation and zero centre contribute no request",r[0]==Vector2.ZERO and r[2]==Vector2.ZERO and r[1]==Vector2(-2,0))
	m.positions.assign([Vector2(.1,8),Vector2(15.9,8)]);m.velocities.assign([Vector2(-3,0),Vector2(3,0)])
	check("Direct neighbourhood distance does not cross periodic seam",m.neighbours(0).is_empty() and m.neighbours(1).is_empty())
	m.step();check("Movement itself still wraps at both edges",m.positions[0].is_equal_approx(Vector2(15.95,8)) and m.positions[1].is_equal_approx(Vector2(.05,8)))
	m=fresh();m.mode=3;var n=fresh();n.mode=3;n.positions.reverse();n.velocities.reverse()
	for i in range(20):m.step();n.step()
	n.positions.reverse();n.velocities.reverse()
	check("Reversing storage and traversal preserves20-step state within rounding tolerance",same(m,n))
	var bounded:=true;m=fresh();m.mode=3
	for step in range(1500):
		m.step()
		for i in range(6):
			bounded=bounded and m.velocities[i].length()<=3.00001 and m.positions[i].is_finite() and m.positions[i].x>=0 and m.positions[i].x<16 and m.positions[i].y>=0 and m.positions[i].y<16
	check("1500 steps remain finite and bounded",bounded)
	n=fresh();n.mode=3
	for i in range(100):n.step()
	m.reset()
	for i in range(100):m.step()
	check("Reset reproduces the exact state at tick100",m.positions==n.positions and m.velocities==n.velocities)
	m.radius=2;m.weights=Vector3(2,.5,0);m.reset()
	check("Reset bodies retains mode, radius and chosen weights",m.mode==3 and m.radius==2 and m.weights==Vector3(2,.5,0) and m.steps==0)
	var variation=fresh("variation");variation.mode=1;variation.step()
	check("Independent half-alignment edit produces0.95,0.1",variation.velocities[0].is_equal_approx(Vector2(.95,.1)))
	var fault=fresh("fault-self")
	check("Checker detects self included as neighbour",fault.neighbours(0).has(0))
	fault=fresh("fault-cap")
	check("Checker detects missing combined acceleration cap",fault.acceleration(0).length()>6.0001)
	fault=fresh("fault-order");n=fresh("fault-order");fault.mode=3;n.mode=3;n.positions.reverse();n.velocities.reverse();fault.step();n.step();n.positions.reverse();n.velocities.reverse()
	check("Checker detects in-place order leakage",not same(fault,n))
	await host_checks()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed sources; independent weight variation; three executed faulty variants; synthetic XRTools. Author-operated reconstruction, not an independent learner or physical headset test."},"  "))
	quit(0 if failures.is_empty() else 1)

func host_checks() -> void:
	var s=load(OUT+"printed/study.tscn").instantiate();root.add_child(s);await ticks();s.set_process(false)
	check("Printed host creates six same-class points and four cylinder arrows",s.points.size()==6 and s.arrows.size()==4 and s.points[0].get_script().get_base_script().resource_path.ends_with("/pickable.gd"))
	check("Initial diagram marks exactly the two named neighbours",s.halos[1].visible and s.halos[2].visible and not s.halos[0].visible and not s.halos[3].visible)
	check("Separation-only diagram hides alignment and cohesion",s.arrows[0].visible and not s.arrows[1].visible and not s.arrows[2].visible)
	var ids:Array=[]
	for point in s.points:ids.append(point.get_instance_id())
	s.get_node("Run").emit_signal("pressed");s._process(.15)
	check("Actual Run button advances three fixed steps",s.playing and s.flock.steps==3)
	s.get_node("Rule").emit_signal("pressed");s.get_node("Radius").emit_signal("pressed");s.get_node("Reset").emit_signal("pressed")
	check("Real controls change rule/radius and reset only body state",not s.playing and s.flock.steps==0 and s.flock.mode==1 and s.flock.radius==2 and s.flock.positions[0]==Vector2(6,8))
	check("Radius display matches the chosen world length",is_equal_approx(s.radius_ring.mesh.outer_radius,.325))
	var unchanged:=true
	for i in range(6):unchanged=unchanged and s.points[i].get_instance_id()==ids[i]
	check("All controls retain the original PointBody instances",unchanged)
	s.position=Vector3(4,.2,-3);s.rotation.y=.7
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	var point=s.points[2];hand.global_position=point.global_position;point.pick_up(pickup);await ticks()
	check("Actual carried PointBody attaches through XRTools",point.held())
	s.playing=true;var target:=Vector2(6.5,8)
	hand.global_position=s.to_global(s.place(target));await ticks();s._process(.3)
	check("Holding pauses everyone and records transformed local position",s.flock.steps==0 and s.flock.positions[2].distance_to(target)<.001 and s.flock.velocities[2]==Vector2.ZERO and s.flock.velocities[0]==Vector2(1,0))
	point.action();await ticks()
	check("Held trigger selects that point as the observed agent",s.witness==2 and s.flock.neighbours(2)==[0,1])
	point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	s._process(0)
	check("Release returns the same sphere to the model plane",not point.held() and point.position.is_equal_approx(s.place(target)))
	s._process(.05)
	check("After release local neighbours determine movement",s.flock.steps==1 and s.flock.velocities[2].is_equal_approx(Vector2(.05,.1)))
	check("Readout distinguishes velocity and acceleration units","cells/s²" in s.caption.text and "neighbours" in s.caption.text and "point 2" in s.caption.text)
	s.queue_free();xr.queue_free();await ticks()
