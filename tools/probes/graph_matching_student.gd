extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-matching-room-for-two/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("PASS " if ok else "FAIL ",label)
func ticks() -> void: await process_frame;await physics_frame;await process_frame
func valid(m) -> bool:
	var used: Array = []
	for a in m.people:
		var b: int = m.mate[a]
		if b == -1:continue
		if b not in m.tools or b in used or m.mate[b] != a or [a,b] not in m.links:return false
		used.append(b)
	for b in m.tools:
		if m.mate[b] != -1 and (m.mate[b] not in m.people or m.mate[m.mate[b]] != b):return false
	return true
func oracle(links: Array) -> int:
	# Enumerate link subsets and reject any repeated endpoint; no path search.
	var best := 0
	for mask in range(1 << links.size()):
		var used: Array = [];var count := 0;var ok := true
		for i in range(links.size()):
			if mask & (1 << i):
				if links[i][0] in used or links[i][1] in used:ok=false;break
				used.append(links[i][0]);used.append(links[i][1]);count+=1
		if ok:best=maxi(best,count)
	return best
func run() -> void:
	var study=load(OUT+"printed/study.tscn").instantiate();root.add_child(study);await ticks()
	var m=study.model;var original: Array=m.links.duplicate(true)
	check("Complete printed workshop builds four roles three links and three controls",study.figures.size()==4 and study.rods.size()==3 and study.controls.size()==3)
	check("Empty workshop has no pair",m.size()==0 and valid(m) and study.history==[0])
	study.controls[0].pointer_event({"event_type":0});check("Hover does not pair",m.size()==0)
	study.controls[0].pointer_event({"event_type":2});await ticks()
	check("Actual NEXT makes a valid maximal one-pair greedy result",m.mate==[2,-1,0,-1] and valid(m))
	check("Reused search finds the predicted alternating path",m.alternating_path()==[1,2,0,3])
	var event:=InputEventKey.new();event.keycode=KEY_1;event.pressed=true;Input.parse_input_event(event);await ticks()
	check("Actual key flips to two pairs without double booking",m.mate==[3,2,1,0] and valid(m))
	check("Cancelled relation and pair-count history appear",study.cancelled.visible and m.removed==[[2,0]] and study.history==[0,1,2])
	event.echo=true;Input.parse_input_event(event);await ticks();check("Key repeat is ignored",not m.done)
	study.advance();check("No alternating path certifies completion",m.done and m.size()==2 and m.links==original)
	study.controls[1].pointer_event({"event_type":2});study.advance();check("Reverse greedy order finds both pairs directly",m.size()==2 and study.history==[0,2] and valid(m))
	study.change_order();study.reset();var identity:int=study.point.get_instance_id()
	study.position=Vector3(3,0,-2);study.rotation.y=.8
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks()
	hand.global_position=study.to_global(Vector3(-.4,1.8,.2))
	for i in range(5):await ticks()
	var local:Vector3=study.to_local(study.point.global_position)-Vector3.UP*.6
	check("Transformed-host pickup moves figure0 in localXZ only",study.point.held() and study.places[0].is_equal_approx(Vector3(local.x,1,local.z)) and m.links==original)
	study.point.action();await ticks();check("Held trigger performs the greedy operation",m.size()==1 and valid(m))
	study.reset();study.change_order();check("Reset and order wait for release",m.size()==1 and not study.reverse_order)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await ticks()
	check("Release keeps the same point above the same figure",study.point.get_instance_id()==identity and not study.point.held() and study.point.position.is_equal_approx(study.places[0]+Vector3.UP*.6))
	study.advance();check("Moved drawing still permits two pairs",m.size()==2 and valid(m))
	study.queue_free();xr.queue_free();await ticks()
	var Model=load(OUT+"printed/matching_model.gd");var good:=true;var cases:=0
	for n in [2,3]:
		for mask in range(1 << (n*n)):
			for reverse in [false,true]:
				var model=Model.new();model.people.clear();model.tools.clear();model.links.clear()
				for i in range(n):model.people.append(i);model.tools.append(n+i)
				for a in range(n):
					for b in range(n):
						if mask & (1 << (a*n+b)):model.links.append([a,n+b])
				model.greedy(reverse);good=good and valid(model)
				for step in range(n+1):
					var before:int=model.size();var changed:bool=model.augment()
					good=good and valid(model) and model.size()==before+(1 if changed else 0)
					if not changed:break
				good=good and model.done and model.size()==oracle(model.links);cases+=1
	check("All 1056 two- and three-by-three graph/order cases match exhaustive optimum",good and cases==1056);observations.exhaustive_cases=cases
	var v=load(OUT+"variation/study.tscn").instantiate();root.add_child(v);await ticks();v.advance()
	check("Independent compatibility edit gives two listed-order pairs",v.model.size()==2 and valid(v.model))
	v.change_order();v.advance();check("Independent edit reverses which greedy order fails",v.model.size()==1 and v.model.alternating_path()==[0,2,1,3])
	v.advance();check("Independent edit repairs to two",v.model.size()==2 and valid(v.model));v.queue_free();await ticks()
	var f=load(OUT+"fault-direction/matching_model.gd").new();f.greedy();f.augment();check("Missing backwards selected edge is rejected",f.size()!=2)
	f=load(OUT+"fault-occupied/matching_model.gd").new();f.links=[[0,2],[0,3]];f.greedy();check("Allowing one occupied endpoint is rejected",not valid(f))
	f=load(OUT+"fault-parity/matching_model.gd").new();f.greedy();f.augment();check("Selecting wrong alternating parity is rejected",f.size()!=2 or not valid(f))
	var atlas=load("res://commons/artifacts/ada_relations/ada_relations.tscn").instantiate();root.add_child(atlas);await ticks()
	check("Atlas loads 25 sequences and four nearby controls",atlas.data.nodes.size()==25 and atlas.controls.size()==4)
	check("Recommended spine is a 24-link order, not chronology",atlas.shown_nodes.size()==25 and atlas.shown_edges.size()==24 and atlas.evidence.kind=="walk")
	atlas.controls[3].pointer_event({"event_type":2});check("Hall view gives graph theory eight rooms in order",atlas.shown_nodes.size()==8 and atlas.shown_nodes[7]=="GT_Matching" and atlas.shown_edges.size()==7)
	atlas.controls[0].pointer_event({"event_type":2});check("Hall dependency view is typed and sourced",atlas.evidence.kind=="dependency" and not atlas.shown_edges.is_empty() and atlas.shown_edges.all(func(e):return e.kind=="dependency" and not e.evidence.is_empty()))
	atlas.controls[3].pointer_event({"event_type":2})
	for kind in ["concept","shared"]:
		atlas.controls[0].pointer_event({"event_type":2});check("Atlas separates "+kind+" from other relations",atlas.evidence.kind==kind and atlas.shown_edges.all(func(e):return e.kind==kind))
	atlas.controls[0].pointer_event({"event_type":2});check("Timeline holds eight dated reviews, not route positions",atlas.shown_nodes.size()==8 and atlas.shown_edges.size()==7 and atlas.evidence.kind=="history")
	atlas.controls[2].pointer_event({"event_type":2});atlas.controls[1].pointer_event({"event_type":2});check("Next and previous preserve selected graph sequence",atlas.data.nodes[atlas.selected].id=="graphtheory")
	atlas.queue_free();await ticks()
	check("All planned Matching reconstruction checks completed",true)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"completed":true,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
