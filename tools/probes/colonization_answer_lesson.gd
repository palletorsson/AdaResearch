extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-colonization-who-can-answer/"
const SC = preload("res://algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/SpaceColonizationAlgorithm.gd")
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("COLONIZATION ", "PASS " if ok else "FAIL ", title)
func settle() -> void:
	for i in 3: await physics_frame
	await process_frame
func forks(rows: Array) -> int:
	var count := 0
	for i in rows.size():
		if rows.filter(func(n): return n.parent == i).size()>1: count+=1
	return count
func same(model, source) -> bool:
	if model.nodes.size()!=source.all_nodes.size() or model.active!=Array(source.active_attraction_points): return false
	for i in model.nodes.size():
		if not model.nodes[i].position.is_equal_approx(source.all_nodes[i].position): return false
		if model.nodes[i].parent!=source.all_nodes.find(source.all_nodes[i].parent): return false
	return true
func source_for(model):
	var source=SC.new()
	source.segment_length=.5;source.influence_distance=8;source.kill_distance=.32
	source.max_iterations=60;source.node_budget=192;source.growth_origin=Vector3.ZERO
	source.growth_policy="network" if model.network else "tips"
	source.attraction_points.assign(model.points);source.active_attraction_points.assign(model.active)
	source.create_root_nodes()
	return source
func dispose(source) -> void:
	source.clear_structure();source.free()
func xyz(p:Vector3)->Array:return [p.x,p.y,p.z]
func run() -> void:
	var G=load(DIR+"printed/growth.gd")
	var m=G.new();m.reset(false)
	check("Opening requests and root are explicit",m.nodes==[{"position":Vector3.ZERO,"parent":-1}] and m.points==[Vector3(-2,3,0),Vector3(2,3,0),Vector3(0,5,0)])
	var before: Array=m.nodes.duplicate(true);var d:Dictionary=m.decision()
	check("Decision is a pure snapshot with three unit votes",m.nodes==before and d.votes.size()==3 and d.votes.all(func(v):return is_equal_approx(v.direction.length(),1)))
	m.step();check("Symmetric first child is half metre above root",m.nodes.size()==2 and m.nodes[1].position.is_equal_approx(Vector3(0,.5,0)) and m.nodes[1].parent==0 and m.nodes[0].position==Vector3.ZERO)
	check("Newborn waits for the next generation",m.generation==1 and m.nodes.size()==2 and m.eligible()==[1])
	var comparisons:=0;var matched:=true
	for wide in [false,true]:
		for network in [false,true]:
			m=G.new();m.network=network;m.reset(wide);var source=source_for(m)
			for i in 15:
				m.step();source.grow_iteration();matched=matched and same(m,source);comparisons+=1
			dispose(source)
	check("Sixty source steps agree on positions parents and remaining requests",matched and comparisons==60)
	m=G.new();m.reset(true)
	for i in 15:m.step()
	check("One-root tips produces a strand",forks(m.nodes)==0 and m.nodes.size()>2)
	m.network=true;m.reset(true)
	for i in 15:m.step()
	check("Same eight requests with older sites eligible produces forks",forks(m.nodes)>0)
	check("Every child has an older parent and a half-metre edge",m.nodes.slice(1).all(func(n):return n.parent>=0 and n.parent<m.nodes.find(n) and is_equal_approx(n.position.distance_to(m.nodes[n.parent].position),.5)))
	m=G.new();m.reset(false);m.active=[Vector3(8,0,0)];check("Influence boundary eight is excluded",m.decision().votes.is_empty())
	m.active=[Vector3(.32,0,0),Vector3(.321,0,0)];d=m.decision()
	check("Kill boundary is inclusive; surviving request votes",d.remove.size()==1 and d.votes.size()==1)
	m.step();check("Reached removal retains original field witness",m.active.size()==1 and m.points.size()==3)
	m.network=true;m.nodes=[{"position":Vector3(-1,0,0),"parent":-1},{"position":Vector3(1,0,0),"parent":0}];m.active=[Vector3(0,2,0)]
	check("Nearest-site ties preserve list order",m.decision().votes[0].site==0)
	m=G.new();m.reset(false);m.points=[Vector3.LEFT,Vector3.RIGHT];m.active=m.points.duplicate();var source=source_for(m)
	m.step();source.grow_iteration()
	check("Declared cancellation difference: learner stops, installed tips appends zero edge",m.nodes.size()==1 and m.reason=="no new direction" and source.all_nodes.size()==2 and source.all_nodes[1].position==Vector3.ZERO)
	dispose(source)
	m.network=true;m.reset(false);m.points=[Vector3.LEFT,Vector3.RIGHT];m.active=m.points.duplicate();source=source_for(m)
	m.step();source.grow_iteration();check("Network cancellation agrees with source",same(m,source) and m.nodes.size()==1);dispose(source)
	m.reset(false);m.generation=60;check("Generation budget is not completion",not m.step() and m.reason=="budget" and m.active.size()==3)
	m.reset(false);m.nodes.resize(192);check("Node budget stops before reading an invalid extra entry",not m.step() and m.reason=="budget")
	var host:=Node3D.new();host.position=Vector3(4,0,3);host.rotation.y=.7;root.add_child(host)
	var study=load(DIR+"printed/colony.gd").new();host.add_child(study);await settle()
	check("Whole printed program builds live comparison and carried point",study.live.get_child_count()>4 and study.point.get_child_count()>=2 and study.live.scale.is_equal_approx(Vector3.ONE*.4))
	study.act("STEP");study.act("HOLD");var kept:Array=study.held.duplicate(true);var witness_id:int=study.witness.get_instance_id()
	study.model.nodes[1].position=Vector3(7,7,7)
	check("Held branch records are independent of subsequent edits",study.held==kept)
	study.act("FIELD");study.act("POLICY");study.act("RESET")
	check("Field and policy restart; reset retains witness",study.model.nodes.size()==1 and study.model.points.size()==3 and not study.model.network and study.held==kept and study.witness.get_instance_id()==witness_id)
	check("Branches are visual; no support collision added",study.live.find_children("*","CollisionObject3D",true,false).is_empty())
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();controller.global_position+=Vector3(.2,.1,0);await settle()
	check("Supplied pickup and hand movement do not advance growth",study.point.is_picked_up() and study.model.generation==0)
	study.point.action();await settle();check("Held action advances one generation",study.model.generation==1 and study.model.nodes[1].position.is_equal_approx(Vector3(0,.5,0)))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle();check("Release parks point relative to transformed host",study.point.position.is_equal_approx(Vector3(0,1.1,.8)))
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_F;study._unhandled_key_input(key)
	check("Keyboard field switch resets to eight known requests",study.model.points.size()==8 and study.model.generation==0)
	study.act("STEP");var unit_child:Vector3=study.model.nodes[1].position
	var edited=load(DIR+"variation/colony.gd").new();host.add_child(edited);await settle();edited.act("FIELD");edited.act("STEP")
	var weighted_child:Vector3=edited.model.nodes[1].position
	check("Full edited program produces predicted weighted child",weighted_child.is_equal_approx(Vector3(-1.5,29.5,.9).normalized()*.5) and not weighted_child.is_equal_approx(unit_child) and is_equal_approx(weighted_child.length(),.5))
	check("Student edit retains same requests and eligible root",edited.model.points==study.model.points and edited.model.nodes[1].parent==0)
	edited.act("RESET");edited.act("STEP");check("Symmetric opening hides the weighting difference",edited.model.nodes[1].position.is_equal_approx(Vector3(0,.5,0)))
	var bad=load(DIR+"wrong_units/growth.gd").new();bad.reset(false);bad.step();check("Oracle rejects missing final normalization",not is_equal_approx(bad.nodes[1].position.length(),.5))
	bad=load(DIR+"wrong_policy/growth.gd").new();bad.reset(false);bad.step();check("Oracle rejects always-eligible tips",bad.eligible()!=[1])
	var broken=load(DIR+"wrong_hold/colony.gd").new();host.add_child(broken);await settle();broken.act("STEP");broken.act("HOLD");broken.model.nodes[1].position=Vector3.ONE
	check("Oracle rejects shallow witness",broken.held[1].position==Vector3.ONE)
	origin.queue_free();host.queue_free();await settle()
	var receipt:Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_steps":comparisons,"unit_child":xyz(unit_child),"weighted_child":xyz(weighted_child),"scope":"Exact printed program and complete variation; three rejected faulty copies; author-led supplied poses, not independent learner/headset acceptance."}
	var file:=FileAccess.open(DIR+"checks.json",FileAccess.WRITE);file.store_string(JSON.stringify(receipt,"  "));file.close();quit(0 if failures.is_empty() else 1)
