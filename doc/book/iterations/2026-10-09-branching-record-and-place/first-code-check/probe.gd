extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-branching-record-and-place/"
const BR = preload("res://algorithms/proceduralgeneration/growth_systems/branchinggrowthalgorithm/branching_growth_algorithm.gd")
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("BRANCHING ","PASS " if ok else "FAIL ",title)
func settle()->void:
	for i in 3:await physics_frame
	await process_frame
func source_for(m):
	var s=BR.new();s.attraction_distance=8;s.growth_distance=.5;s.min_branch_distance=.32;s.max_branches=192;s.jitter=0;s.pulse_strength=0
	for n in m.nodes:s.add_branch(n.position,Vector3.UP,n.parent)
	for p in m.points:s.attractors.append(BR.Attractor.new(p))
	return s
func same(m,s)->bool:
	if m.nodes.size()!=s.branches.size():return false
	for i in m.nodes.size():
		var n:Dictionary=m.nodes[i];var b=s.branches[i]
		if not n.position.is_equal_approx(b.position) or n.parent!=b.parent_index or n.active!=b.is_active:return false
	for i in m.points.size():
		if m.reached[i]!=s.attractors[i].is_reached:return false
	return true
func timing_fixture(m)->void:
	m.reset();m.points=[Vector3(.1,0,0)];m.reached=[false]
	m.nodes=[{"position":Vector3.ZERO,"parent":-1,"target":-1,"active":true},{"position":Vector3(0,.1,0),"parent":0,"target":-1,"active":true}]
func run()->void:
	var G=load(DIR+"printed/growth.gd");var m=G.new();m.reset()
	var prior=load("res://doc/book/studies/procedural-generation-through-the-hands/PG_Space_Colonization/growth.gd")
	check("Field is unchanged from preceding hall",m.points==prior.field(true) and m.points.size()==8)
	check("Root has no selected target; nearest target is index0",m.nodes[0].target==-1 and m.nearest(Vector3.ZERO)==0)
	m.step();check("First child records predicted position parent and target",m.nodes.size()==2 and m.nodes[1].position.is_equal_approx(Vector3(-.4,.3,0)) and m.nodes[1].parent==0 and m.nodes[1].target==0 and m.nodes[0].active)
	m.step();check("Second step gives four records at three positions",m.nodes.size()==4 and m.distinct_count()==3 and m.nodes[2].position==m.nodes[1].position and m.nodes[3].position.is_equal_approx(Vector3(-.8,.6,0)))
	check("Coincident records retain independent parent histories",m.nodes[1].parent==0 and m.nodes[2].parent==0 and m.nodes[3].parent==1 and not is_same(m.nodes[1],m.nodes[2]))
	var comparisons:=0;var match_all:=true
	for setup in 4:
		m=G.new();m.reset()
		match setup:
			1:timing_fixture(m)
			2:m.points=[Vector3.ZERO];m.reached=[false]
			3:m.points=[Vector3(8,0,0),Vector3(-1,1,0),Vector3(1,1,0)];m.reached=[false,false,false]
		var source=source_for(m)
		for i in 12:
			m.step()
			if source.branches.size()<192:source.grow_step()
			match_all=match_all and same(m,source);comparisons+=1
		source.free()
	check("Forty-eight source steps match geometry parents active flags and reached flags",match_all and comparisons==48)
	m.reset();m.points=[Vector3(8,0,0)];m.reached=[false];check("Eight-metre boundary excluded",m.nearest(Vector3.ZERO)==-1)
	m.points=[Vector3.LEFT,Vector3.RIGHT];m.reached=[false,false]
	check("Equal-distance target keeps first index",m.nearest(Vector3.ZERO)==0)
	m.reached[0]=true;check("Reached flag removes target from eligibility without changing index",m.nearest(Vector3.ZERO)==1 and m.points[0]==Vector3.LEFT)
	m.reset();m.points=[Vector3(.32,0,0)];m.reached=[false];m.step()
	check("Near boundary is strict and child uses old parent distance",not m.reached[0] and m.nodes[0].active and m.nodes[1].position.is_equal_approx(Vector3(.5,0,0)))
	m.reset();m.points=[Vector3(.1,0,0)];m.reached=[false];m.step()
	check("Near target still gets child before parent retires",m.nodes.size()==2 and m.reached[0] and not m.nodes[0].active and m.nodes[1].active and m.nodes[1].position.is_equal_approx(Vector3(.5,0,0)))
	timing_fixture(m);m.step();check("Reached marking waits until both old sites have read",m.nodes.size()==4 and m.nodes[2].target==0 and m.nodes[3].target==0)
	m.reset();m.points=[Vector3.ZERO];m.reached=[false];m.step();check("Exact target permits a zero-length recorded child",m.nodes.size()==2 and m.distinct_count()==1 and m.reached[0])
	m.reset();m.points=[];m.reached=[];check("No target retires active root and adds nothing",not m.step() and not m.nodes[0].active and m.nodes.size()==1)
	m.reset();m.nodes.resize(192);check("Budget stops before another decision",not m.step() and m.reason=="record budget" and m.generation==0)
	var host:=Node3D.new();host.position=Vector3(4,0,3);host.rotation.y=.7;root.add_child(host)
	var study=load(DIR+"printed/branches.gd").new();host.add_child(study);await settle()
	check("Complete printed model builds inherited point and eight requests",study.model.points.size()==8 and study.live.get_child_count()>8 and study.live.scale.is_equal_approx(Vector3.ONE*.4))
	study.act("STEP");study.act("HOLD");var kept:Array=study.held.duplicate(true);var witness_id:int=study.witness.get_instance_id();study.model.nodes[1].position=Vector3.ONE
	check("Deep held records resist later mutation",study.held==kept)
	study.act("RESET");check("Reset retains held record and geometry",study.held==kept and study.witness.get_instance_id()==witness_id and study.model.nodes.size()==1)
	check("Growth geometry supplies no collision",study.live.find_children("*","CollisionObject3D",true,false).is_empty())
	var key:=InputEventKey.new();key.keycode=KEY_T;key.pressed=true;study._unhandled_key_input(key)
	var baseline_count:int=study.model.nodes.size();var baseline_unique:int=study.model.distinct_count()
	check("Keyboard ten executes bounded repeated step",study.model.generation<=10 and baseline_count<=192 and baseline_count>baseline_unique)
	study.act("RESET")
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();controller.global_position+=Vector3(.2,.1,0);await settle()
	check("Hand movement alone leaves generation unchanged",study.point.is_picked_up() and study.model.generation==0)
	study.point.action();await settle();check("Held action adds one correctly recorded child",study.model.nodes.size()==2 and study.model.nodes[1].target==0)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle();check("Release parks under transformed host",study.point.position.is_equal_approx(Vector3(0,1.1,.8)))
	var edited=load(DIR+"variation/branches.gd").new();host.add_child(edited);await settle();edited.act("STEP");edited.act("STEP")
	check("Complete student edit gives three records and three positions",edited.model.nodes.size()==3 and edited.model.distinct_count()==3 and edited.model.nodes[2].parent==1 and not edited.model.nodes[0].active)
	edited.act("RESET");edited.act("TEN")
	check("Retire-after-growth edit makes one parent chain",edited.model.nodes.slice(1).all(func(n):return n.parent==edited.model.nodes.find(n)-1) and edited.model.nodes.size()<baseline_count and edited.model.points==study.model.points)
	var counts:Dictionary={"baseline":[baseline_count,baseline_unique],"retired":[edited.model.nodes.size(),edited.model.distinct_count()]}
	var bad=load(DIR+"wrong_tie/growth.gd").new();bad.reset();bad.points=[Vector3.LEFT,Vector3.RIGHT];bad.reached=[false,false]
	check("Oracle rejects changed tie-breaking",bad.nearest(Vector3.ZERO)!=0)
	bad=load(DIR+"wrong_timing/growth.gd").new();timing_fixture(bad);bad.step();check("Oracle rejects immediate target consumption",bad.nodes.size()!=4)
	var broken=load(DIR+"wrong_hold/branches.gd").new();host.add_child(broken);await settle();broken.act("STEP");broken.act("HOLD");broken.model.nodes[1].position=Vector3.ONE
	check("Oracle rejects shallow held records",broken.held[1].position==Vector3.ONE)
	origin.queue_free();host.queue_free();await settle()
	var receipt:Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_steps":comparisons,"ten_step_counts":counts,"scope":"Exact printed code, declared no-jitter/no-pulse source opening, full student variation, rejected mutants and supplied XRTools poses. No physical headset or independent learner acceptance."}
	var f:=FileAccess.open(DIR+"checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(receipt,"  "));f.close();quit(0 if failures.is_empty() else 1)
