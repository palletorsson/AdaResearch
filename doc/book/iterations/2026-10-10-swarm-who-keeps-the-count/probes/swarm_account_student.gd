extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-swarm-who-keeps-the-count/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("ACCOUNT ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func fresh(folder: String = "printed"):
	return load(OUT+folder+"/account.gd").new()
func event(kind:String,amount:int,species:String="prey") -> Dictionary:
	return {"kind":kind,"amount":amount,"species":species}
func fixture(a) -> void:
	a.begin(10,2)
	for e in [event("birth",2),event("loss",3),event("supplied",5)]:a.record(e)
func consistent(a,m) -> bool:
	return a.expected("prey")==m.prey_list.size() and a.expected("predator")==m.predator_list.size()
func same(a,b) -> bool:
	if a._rng.state!=b._rng.state or a.care_counts!=b.care_counts:return false
	for key in ["prey_list","predator_list","food_list"]:
		if a.get(key).size()!=b.get(key).size():return false
		for i in range(a.get(key).size()):
			var x=a.get(key)[i];var y=b.get(key)[i]
			if x.position!=y.position:return false
			if key!="food_list" and (x.health!=y.health or x.velocity!=y.velocity or x.dna!=y.dna):return false
	return true
func run() -> void:
	var a=fresh();fixture(a)
	check("Taught count10+2-3+5 equals14",a.expected("prey")==14 and a.difference("prey",14)==0)
	check("Prey events do not change predator count",a.expected("predator")==2)
	check("Supplied row can be omitted without deleting events",a.expected("prey",false)==9 and a.difference("prey",14,false)==5 and a.events.size()==3)
	a.record(event("food",8,"support"));a.record(event("pressure",3,"support"))
	check("Food and pressure do not count as creatures",a.expected("prey")==14 and a.expected("predator")==2 and a.total("support","food")==8)
	var e=event("birth",1);a.begin(0,0);a.record(e);e.amount=99
	check("Record owns a copy of event",a.expected("prey")==1)
	a.begin(4,3);check("Begin replaces baseline and clears events",a.events.is_empty() and a.expected("prey")==4 and a.expected("predator")==3)
	var v=fresh("variation");fixture(v)
	check("Independent filtered-default edit predicts gap5",v.expected("prey")==9 and v.difference("prey",14)==5)
	var f=fresh("fault-loss");fixture(f);check("Executed loss-sign fault rejected",f.expected("prey")!=14)
	f=fresh("fault-supply");fixture(f);check("Executed double-supply fault rejected",f.expected("prey")!=14)
	f=fresh("fault-history");f.begin(0,0);e=event("birth",1);f.record(e);e.amount=99
	check("Executed mutable-history fault rejected",f.expected("prey")!=1)
	var m=load(OUT+"printed/observed.gd").new();root.add_child(m)
	a=fresh();a.begin(m.prey_list.size(),m.predator_list.size());m.event_record.connect(a.record)
	check("Initial organisms form baseline, not births",a.events.is_empty() and a.expected("prey")==50 and a.expected("predator")==5 and m.prey_list[0].get_meta("arrival")=="initial")
	var p=m.prey_list[0];var q=m.prey_list[1]
	p.age=p.lifespan*.4;q.age=q.lifespan*.4;q.position=p.position
	m.check_for_mate(p)
	check("Actual model birth emits exactly one birth",a.total("prey","birth")==1 and m.prey_list.size()==51 and m.prey_list[-1].get_meta("arrival")=="birth" and consistent(a,m))
	for i in range(7,m.prey_list.size()):m.prey_list[i].health=-1
	m.update_prey(0.0)
	check("Actual health removals counted once",m.prey_list.size()==7 and a.total("prey","loss")==44 and consistent(a,m))
	m.balance_ecosystem()
	check("Actual low-prey replenishment is supply, not birth",m.prey_list.size()==12 and a.total("prey","supplied")==5 and a.total("prey","birth")==1 and consistent(a,m))
	check("Live omission gives exactly five unexplained prey",a.difference("prey",m.prey_list.size(),false)==5)
	for predator in m.predator_list:predator.health=-1
	m.update_predators(0.0)
	check("Predator removals also balance",m.predator_list.is_empty() and a.total("predator","loss")==5 and consistent(a,m))
	m.restart();a.begin(50,5)
	var predator=m.predator_list[0];p=m.prey_list[0];predator.position=p.position
	m.update_predators(0.0)
	check("Predation removal is present in prey account",a.total("prey","loss")>=1 and consistent(a,m))
	m.restart();a.begin(50,5)
	for pred in m.predator_list:pred.health=-1
	m.update_predators(0.0);m.balance_ecosystem()
	check("Actual predator replacement counted exactly twice",a.total("predator","supplied")==2 and consistent(a,m))
	m.restart();a.begin(50,5);m._record_care("food_added",3);m._record_care("pressure_steps",1)
	check("Care receipts include non-population support",a.total("support","food")==3 and a.total("support","pressure")==1 and consistent(a,m))
	m.restart();a.begin(50,5)
	var original=load("res://algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd").new();root.add_child(original);original.set_process(false)
	var agrees:=true;var unchanged:=true
	for step in range(2400):
		m.advance(1.0/60.0);original._process(1.0/60.0)
		agrees=agrees and consistent(a,m);unchanged=unchanged and same(m,original)
		if step%60==0:await ticks()
	check("Forty seconds: every completed update balances both populations",agrees)
	check("Observer matches unmodified source positions, health, DNA, care and RNG",unchanged)
	check("Natural run includes real losses and replenishment",a.total("prey","loss")>0 and a.total("prey","supplied")>0)
	var serial_ok:=true
	for i in range(a.events.size()):serial_ok=serial_ok and a.events[i].serial==i+1
	check("Complete event feed has contiguous receipt numbers",serial_ok)
	m.queue_free();original.queue_free();await ticks()
	await host_checks()
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":true,"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed scripts, actual supplied model equivalence, independent edit, three faulty variants and synthetic XR. No headset or independent learner claim."},"  "))
	quit(0 if failures.is_empty() else 1)
func host_checks() -> void:
	var s=load(OUT+"printed/study.tscn").instantiate();root.add_child(s);await ticks();s.set_process(false)
	check("Host creates55 half-metre carried PointBodies",s.points.size()==55 and is_equal_approx(s.points.values()[0].get_child(1).shape.radius,.255) and s.points.values()[0].scale==Vector3.ONE)
	check("Host starts paused with actual100 food markers",not s.playing and s.food.multimesh.instance_count==100)
	check("Display/model position conversion roundtrips",s.record(s.place(Vector3(.2,.1,-.3))).is_equal_approx(Vector3(.2,.1,-.3)))
	s.get_node("Run1").emit_signal("pressed");s._process(.05)
	check("Real run button advances three60Hz updates",s.model.tick==3)
	s.restart();s.position=Vector3(4,.2,-3);s.rotation.y=.7
	var body=s.model.prey_list[0];var id:int=body.get_instance_id();var point=s.points[id]
	var origin:=XROrigin3D.new();root.add_child(origin)
	var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=point.global_position;point.pick_up(pickup);await ticks()
	s.playing=true;hand.global_position=s.to_global(Vector3(2,1.4,-3));await ticks();s._process(.1)
	point.action_pressed.emit(pickup)
	check("Synthetic XR hold pauses population and selects source",point.held() and s.model.tick==0 and s.witness==id)
	check("Hand placement converts through rotated host",body.position.distance_to(s.record(s.to_local(point.global_position)))<.001 and body.velocity==Vector3.ZERO)
	check("Moving initial point creates no birth or loss",s.account.events.is_empty() and body.get_meta("arrival")=="initial")
	s.restart();check("Restart waits while body held",s.model.prey_list[0]==body)
	point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks();s.single_step()
	check("Released point stays same instance and count balances",s.points[id]==point and consistent(s.account,s.model) and s.model.tick==1)
	s.get_node("Record-1").emit_signal("pressed")
	check("Other bank filters account without deleting records",not s.show_supply and "FILTERED" in s.captions[0].text)
	s.get_node("Restart1").emit_signal("pressed")
	check("Restart resets organism and account together",s.model.tick==0 and s.account.events.is_empty() and s.points.size()==55 and s.show_supply)
	origin.queue_free();s.queue_free();await ticks()
