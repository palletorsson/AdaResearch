extends SceneTree
const OUT="res://doc/book/iterations/2026-10-10-spanning-the-cost-of-a-spare/"
const ENDS:=[Vector2i(0,1),Vector2i(0,2),Vector2i(1,3),Vector2i(1,4),Vector2i(2,5),Vector2i(2,6),Vector2i(4,5),Vector2i(1,5)]
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
var completed:=false
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("PASS " if ok else "FAIL ",label)
func ticks() -> void:
	await process_frame;await physics_frame;await process_frame
func ids(value:Array) -> Array:
	var result:=value.duplicate();result.sort();return result
func ints(a:Array) -> Array[int]:
	var result:Array[int]=[];result.assign(a);return result
func key_press(code:int,echo:=false) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=true;e.echo=echo;Input.parse_input_event(e);await ticks()
func finish_model(model) -> void:
	for i in range(model.links.size()+1):model.step()
func forest(mask:int) -> Dictionary:
	# Independent component labels; no learner traversal or adjacency calls.
	var groups:=[0,1,2,3,4,5,6];var count:=0;var acyclic:=true
	for i in range(8):
		if not (mask & (1<<i)):continue
		count+=1;var a:int=groups[ENDS[i].x];var b:int=groups[ENDS[i].y]
		if a==b:acyclic=false
		for v in range(7):
			if groups[v]==b:groups[v]=a
	return {"mask":mask,"rank":count,"valid":acyclic}
func drawings_valid(study) -> bool:
	for i in range(study.model.links.size()):
		if not study.rods[i].visible:continue
		var r:Dictionary=study.model.links[i];var rod=study.rods[i]
		var a:Vector3=study.places[r.a];var b:Vector3=study.places[r.b]
		if not (rod.position-rod.basis.y*rod.mesh.height*.5).is_equal_approx(a):return false
		if not (rod.position+rod.basis.y*rod.mesh.height*.5).is_equal_approx(b):return false
	return true
func run() -> void:
	var study=load(OUT+"printed/study.tscn").instantiate();root.add_child(study);await ticks()
	var model=study.model;var original:Array=model.links.duplicate(true)
	check("Complete printed host creates seven vertices eight weighted rods and four controls",study.lamps.size()==7 and study.rods.size()==8 and study.weights.size()==8 and study.controls.size()==4)
	check("Initial scan has no chosen links and singleton0",model.cursor==0 and model.chosen.is_empty() and model.reachable(ints([]),0)==[0])
	check("Cost order matches independently written prediction",model.order==[2,1,3,0,5,4,6,7])
	study.toggle_break();study.toggle_spare();check("Failure comparison waits until scan finishes",not study.broken and not study.spare)
	study.controls[0].pointer_event({"event_type":0});check("Pointer hover cannot consume a decision",model.cursor==0)
	study.controls[0].pointer_event({"event_type":2});await ticks();check("Pointer STEP accepts first cheapest link",model.chosen==[2] and model.current==2 and "1-3" in study.decision.text)
	await key_press(KEY_1);await key_press(KEY_1,true);check("Keyboard steps once and ignores echo",model.cursor==2 and model.chosen==[2,1])
	finish_model(model);study.redraw();check("Full scan selects expected tree and explicitly refuses two cycles",model.chosen==[2,1,3,0,5,4] and model.refused==[6,7] and model.spans() and model.cost(model.chosen)==21.0)
	check("Reached set uses both directions",model.reachable(ints([0]),1)==[1,0] and ids(model.reachable(model.chosen,3))==[0,1,2,3,4,5,6])
	var selected:Array=model.chosen.duplicate();model.step();check("Stepping completed scan does not duplicate edges",model.chosen==selected and model.cursor==8)
	check("Rendering shows refused link as a cycle with its cost",study.weights[6].text=="7.0\ncycle" and drawings_valid(study))
	study.controls[1].pointer_event({"event_type":2});await ticks()
	check("Breaking0-1 separates1,3,4 without recomputing chosen tree",ids(model.reachable(study.active_links(),0))==[0,2,5,6] and model.chosen==selected and not study.rods[0].visible and "broken" in study.weights[0].text)
	study.controls[2].pointer_event({"event_type":2});await ticks()
	check("Adding spare4-5 restores all seven at extra cost7",ids(model.reachable(study.active_links(),0))==[0,1,2,3,4,5,6] and "spare 7.0" in study.caption.text and study.weights[6].text=="7.0\nspare")
	study.toggle_break();var active:Array[int]=study.active_links();check("Restoring failed edge with spare creates seven active links",active.size()==7 and model.cost(active)==28.0)
	active.erase(2);check("Spare cannot protect leaf3 against failure1-3",3 not in model.reachable(active,0))
	var folders:=["printed","variation"]
	var scenarios:=[[4.0,2.0,1.0,3.0,6.0,5.0,7.0,8.0],[4.0,2.0,1.0,3.0,6.0,5.0,.5,8.0],[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0],[-4.0,2.0,1.0,3.0,6.0,5.0,7.0,8.0]]
	var forests:Array=[]
	for mask in range(256):
		var f:=forest(mask)
		if f.valid:forests.append(f)
	var good:=true;var cases:=0;var Model=load(OUT+"printed/tree_model.gd")
	for costs:Array in scenarios:
		for f:Dictionary in forests:
			f.total=0.0
			for i in range(8):
				if f.mask & (1<<i):f.total+=costs[i]
		for available in range(256):
			var rank:=-1;var minimum:=INF
			for f:Dictionary in forests:
				if f.mask & available != f.mask:continue
				if f.rank>rank:rank=f.rank;minimum=f.total
				elif f.rank==rank:minimum=minf(minimum,f.total)
			var candidate=Model.new();candidate.links.clear()
			for i in range(8):
				if available & (1<<i):candidate.links.append({"a":ENDS[i].x,"b":ENDS[i].y,"cost":costs[i]})
			candidate.reset();finish_model(candidate)
			good=good and candidate.chosen.size()==rank and is_equal_approx(candidate.cost(candidate.chosen),minimum) and candidate.spans()==(rank==6) and candidate.complete()
			cases+=1
	observations.input_cases=cases;observations.independent_forest_subsets=forests.size()
	check("All1024 input subsets/cost cases attain independent exhaustive minimum forest cost",good)
	check("Scanning and failure comparison preserve original costs and link records",model.links==original)
	var edgecase=Model.new();edgecase.links=[{"a":0,"b":0,"cost":-10.0},{"a":0,"b":1,"cost":1.0},{"a":1,"b":0,"cost":2.0}];edgecase.reset();finish_model(edgecase)
	check("Self loop and parallel return are refused without claiming spanning",edgecase.chosen==[1] and edgecase.refused==[0,2] and not edgecase.spans())
	check("Invalid reachability starts return empty",model.reachable(model.chosen,-1).is_empty() and model.reachable(model.chosen,7).is_empty())
	await key_press(KEY_R);check("Reset clears selection failure spare and positions",model.cursor==0 and not study.broken and not study.spare and study.places==study.INITIAL)
	study.position=Vector3(2,0,-3);study.rotation.y=.7;var point_id:int=study.point.get_instance_id()
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks();hand.global_position=study.to_global(Vector3(-.3,2.5,.4))
	for i in range(5):await ticks()
	var projected:Vector3=study.to_local(study.point.global_position)-study.FRONT
	check("Held point moves vertex4 in local XY without rewriting weights",study.point.held() and study.places[4].is_equal_approx(Vector3(projected.x,projected.y,0)) and model.links==original and drawings_valid(study))
	study.point.action();await ticks();check("Held point trigger makes one edge decision",model.cursor==1 and model.chosen==[2])
	study.reset();check("Reset waits while point held",model.cursor==1 and study.point.held())
	finish_model(model);check("Moved drawing yields same minimum tree",model.chosen==selected and model.cost(model.chosen)==21.0)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await ticks()
	check("Release preserves point identity and returns it to drawing plane",not study.point.held() and study.point.get_instance_id()==point_id and study.point.position.is_equal_approx(study.places[4]+study.FRONT))
	study.queue_free();xr.queue_free();await ticks()
	var variant=load(OUT+"variation/study.tscn").instantiate();root.add_child(variant);await ticks();finish_model(variant.model);variant.redraw()
	check("Independent cheaper4-5 replaces2-5 and costs15.5",variant.model.chosen==[6,2,1,3,0,5] and variant.model.cost(variant.model.chosen)==15.5 and variant.weights[6].text=="0.5\nkept")
	variant.toggle_spare();check("Already selected spare adds no duplicate or cost",variant.active_links().size()==6 and "spare 0.0" in variant.caption.text)
	variant.toggle_break();check("Same spare cannot repair changed tree after0-1 failure",variant.model.reachable(variant.active_links(),0).size()<7)
	variant.queue_free();await ticks()
	var fault=load(OUT+"fault-direction/tree_model.gd").new();fault.reset();finish_model(fault);check("Checker rejects expensive-first tree despite valid spanning",fault.spans() and fault.cost(fault.chosen)!=21.0)
	fault=load(OUT+"fault-filter/tree_model.gd").new();fault.reset();finish_model(fault);check("Checker rejects accepting cycle edges",fault.chosen.size()!=6)
	fault=load(OUT+"fault-omission/tree_model.gd").new();fault.reset();check("Checker rejects omitted reverse neighbour",fault.reachable(ints([0]),1)!=[1,0])
	completed=true;check("All planned spanning code checks completed",completed)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations,"scope":"Fresh exact printed source, exhaustive forest oracle, transfer, faults, actual input and synthetic XRTools; no physical headset or independent reader."},"  "))
	quit(0 if completed and failures.is_empty() else 1)
