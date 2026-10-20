extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-colony-two-trails-underfoot/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("ACO ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func fresh(folder: String = "printed"):
	return load(OUT+folder+"/colony.gd").new()
func one(m,p:Vector2,v:Vector2,carrying:bool) -> void:
	m.positions.assign([p]);m.velocities.assign([v]);m.carrying.assign([carrying]);m.energy.assign([1.0])
func equivalent(a,b) -> bool:
	if a.carrying!=b.carrying or a.delivered!=b.delivered:return false
	for i in range(a.positions.size()):
		if a.positions[i].distance_to(b.positions[i])>.00001 or a.velocities[i].distance_to(b.velocities[i])>.00001:return false
	for i in range(a.home.size()):
		if absf(a.home[i]-b.home[i])>.0001 or absf(a.food[i]-b.food[i])>.0001:return false
	return true
func run() -> void:
	var m=fresh()
	check("24 carried agents start with two empty separate fields",m.positions.size()==24 and m.home.count(0.0)==256 and m.food.count(0.0)==256)
	one(m,Vector2(8,8),Vector2.RIGHT*3,false)
	var left:int=m.index_at(m.sensor_position(0,m.TURN))
	m.food[left]=4;m.home[left]=7
	check("Search reads food, not home",m.sense(0,m.TURN,m.carrying[0])==4)
	check("Strong left food sample requests the familiar turn",m.desired_velocity(0).is_equal_approx(Vector2.RIGHT.rotated(PI/4)*3))
	m.carrying[0]=true
	check("Same point returning reads home",m.sense(0,m.TURN,m.carrying[0])==7)
	m=fresh();one(m,Vector2(8,8),Vector2.RIGHT*3,false);m.deposit(0)
	check("Searcher writes only home",m.home[136]==.5 and m.food.count(0.0)==256)
	m.carrying[0]=true;m.deposit(0)
	check("Returner writes only food; previous home value retained",m.food[136]==.5 and m.home[136]==.5)
	m.food[136]=7.9;m.deposit(0);check("Field saturates at eight",m.food[136]==8)
	m=fresh();one(m,Vector2(8,8),Vector2.ZERO,false);m.home[0]=4;m.food[0]=2;m.step()
	check("Both channels evaporate before new deposits",is_equal_approx(m.home[0],3.98) and is_equal_approx(m.food[0],1.99))
	check("Energy declines before deposition",is_equal_approx(m.energy[0],.9975) and is_equal_approx(m.home[136],.49875))
	check("Sources replenish their own channels only",m.home[m.index_at(m.HOME)]==8 and m.food[m.index_at(m.HOME)]==0 and m.food[m.index_at(m.FOOD)]==8 and m.home[m.index_at(m.FOOD)]==0)
	m=fresh();one(m,Vector2(12,8),Vector2(3,0),false);m.energy[0]=.1;m.step()
	check("Food contact flips carry and renews energy",m.carrying==[true] and is_equal_approx(m.energy[0],.9975))
	check("Food contact reverses model heading once",m.velocities[0].is_equal_approx(Vector2(-3,0)) and m.positions[0].is_equal_approx(Vector2(11.85,8)))
	m.step();check("Remaining near food does not reverse again",m.velocities[0].x<0 and m.carrying[0])
	one(m,Vector2(3,8),Vector2(-3,0),true);m.step();m.step()
	check("Home turns returner into searcher and counts one delivery",not m.carrying[0] and m.delivered==1 and m.velocities[0].x>0)
	m=fresh();one(m,Vector2(11,8),Vector2.ZERO,false);m.step()
	check("Contact excludes exact radius boundary",not m.carrying[0])
	m=fresh();one(m,Vector2(10.99,8),Vector2(3,0),false);m.step()
	check("Entering a ring during movement waits until next tick",not m.carrying[0] and m.positions[0].x>11)
	m.step();check("Following tick detects contact",m.carrying[0])
	m=fresh();one(m,Vector2(8,8),Vector2.ZERO,true);m.step()
	check("Stationary returner uses declared west fallback",m.velocities[0].is_equal_approx(Vector2(-.3,0)))
	m=fresh();one(m,Vector2(15.99,2),Vector2(3,0),false);m.step()
	check("Periodic position stays inside field",m.positions[0].is_equal_approx(Vector2(.14,2)))
	m.home[10]=5;m.food[10]=3;m.delivered=7;var count:int=m.steps;m.replace_agents()
	check("Replace keeps both fields, tally and clock",m.positions.size()==24 and m.home[10]==5 and m.food[10]==3 and m.delivered==7 and m.steps==count)
	m.retention=.5;m.deposit_amount=.25;m.reset()
	check("Clear resets fields and records, retains parameters",m.home.count(0.0)==256 and m.food.count(0.0)==256 and m.delivered==0 and m.steps==0 and m.retention==.5 and m.deposit_amount==.25)
	m=fresh();var n=fresh();n.positions.reverse();n.velocities.reverse();n.carrying.reverse();n.energy.reverse()
	for i in range(400):m.step();n.step()
	n.positions.reverse();n.velocities.reverse();n.carrying.reverse();n.energy.reverse()
	check("Old-field decisions survive reversed agent traversal",equivalent(m,n))
	check("Authored arrangement completes an unassisted delivery",m.delivered>0)
	var bounded:=true
	for i in range(1600):
		m.step()
		for j in range(24):bounded=bounded and m.positions[j].is_finite() and m.positions[j].x>=0 and m.positions[j].x<16 and m.positions[j].y>=0 and m.positions[j].y<16 and m.velocities[j].length()<=3.00001 and m.energy[j]>=0
	check("2000 ticks remain finite and bounded",bounded)
	m.reset();n=fresh()
	for i in range(120):m.step();n.step()
	check("Reset replays identical state",equivalent(m,n))
	var v=fresh("variation");one(v,Vector2(8,8),Vector2.ZERO,false);v.deposit(0)
	check("Independent half-deposit edit gives0.25 in one channel",v.home[136]==.25 and v.food[136]==0)
	v.home.fill(0);v.step();check("Half-deposit tick prediction includes energy decay",is_equal_approx(v.home[136],.249375))
	var f=fresh("fault-read");one(f,Vector2(8,8),Vector2.RIGHT*3,false);f.food[left]=4;f.home[left]=7
	check("Executed wrong-read fault rejected",f.sense(0,f.TURN,false)!=4)
	f=fresh("fault-write");one(f,Vector2(8,8),Vector2.ZERO,false);f.deposit(0)
	check("Executed wrong-write fault rejected",f.home[136]!=.5 or f.food[136]!=0)
	f=fresh("fault-replace");f.home[10]=5;f.food[10]=3;f.replace_agents()
	check("Executed destructive-replace fault rejected",f.home[10]!=5 or f.food[10]!=3)
	await host_checks()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code, independent edit, three executed faults and synthetic XR. Author-operated; no physical headset or independent learner claim."},"  "))
	quit(0 if failures.is_empty() else 1)

func host_checks() -> void:
	var s=load(OUT+"printed/study.tscn").instantiate();root.add_child(s);s.playing=false;await ticks();s.set_process(false);s.restart()
	check("Host builds24 PointBodies and two batched256-cell fields",s.points.size()==24 and s.home_tiles.multimesh.instance_count==256 and s.food_tiles.multimesh.instance_count==256)
	check("Spheres are51cm across with matching grab shape",s.points[0].get_child(0).scale==Vector3.ONE*3 and is_equal_approx(s.points[0].get_child(1).shape.radius,.255) and s.points[0].scale==Vector3.ONE)
	var id:int=s.points[0].get_instance_id()
	s.get_node("Run1").emit_signal("pressed");s._process(.15);check("Run advances three fixed ticks",s.model.steps==3)
	s.model.home[10]=5;s.model.food[10]=3;s.get_node("Replace-1").emit_signal("pressed")
	check("Opposite-end Replace preserves both traces",s.model.home[10]==5 and s.model.food[10]==3 and not s.playing)
	s.get_node("Reset1").emit_signal("pressed");check("Clear resets both fields on same sphere instances",s.model.home.count(0.0)==256 and s.model.food.count(0.0)==256 and s.points[0].get_instance_id()==id)
	s.position=Vector3(4,.2,-3);s.rotation.y=.7
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	var p=s.points[0];hand.global_position=p.global_position;p.pick_up(pickup);await ticks()
	check("Same sphere attaches through real XRTools code",p.held())
	s.playing=true;hand.global_position=s.to_global(s.place(Vector2(12,8)));await ticks();s._process(.3)
	check("Hold pauses and records local position under transformed host",s.model.steps==0 and s.model.positions[0].distance_to(Vector2(12,8))<.001 and s.model.velocities[0]==Vector2.ZERO)
	p.action();await ticks();check("Held trigger selects witness",s.witness==0)
	s.get_node("Step1").emit_signal("pressed");s.get_node("Replace1").emit_signal("pressed");s.get_node("Reset1").emit_signal("pressed")
	check("Held point blocks stepping and reset",s.model.steps==0 and s.model.positions[0].distance_to(Vector2(12,8))<.001)
	p.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	s._process(0);s.get_node("Step-1").emit_signal("pressed")
	check("Release and step acquires cargo and switches caption",s.model.carrying[0] and s.cargo[0].visible and "READ HOME  /  LEAVE FOOD" in s.captions[0].text)
	hand.global_position=p.global_position;p.pick_up(pickup);await ticks();hand.global_position=s.to_global(s.place(Vector2(3,8)));await ticks();s._process(.2)
	check("Relocating same returner preserves its state",s.model.carrying[0])
	p.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(4):await ticks()
	s._process(0);s.single_step()
	check("Home delivers once and switches displayed channels",s.model.delivered==1 and not s.cargo[0].visible and "READ FOOD  /  LEAVE HOME" in s.captions[1].text)
	s.queue_free();xr.queue_free();await ticks()
