extends SceneTree
const OUT="res://doc/book/iterations/2026-10-10-connectivity-a-way-back/"
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
func key_press(code:int,echo:=false) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=true;e.echo=echo;Input.parse_input_event(e);await ticks()
func drawings_valid(study) -> bool:
	for i in study.ledger.active_records():
		var r:Dictionary=study.ledger.records[i];var rod=study.rods[i];var tip=study.tips[i]
		var a:Vector3=study.places[r.from];var b:Vector3=study.places[r.to]
		if not (rod.position-rod.basis.y*rod.mesh.height*.5).is_equal_approx(a):return false
		if not (rod.position+rod.basis.y*rod.mesh.height*.5).is_equal_approx(b):return false
		if tip.basis.y.dot((b-a).normalized())<.999:return false
	return true
func run() -> void:
	var study=load(OUT+"printed/study.tscn").instantiate();root.add_child(study);await ticks()
	var model=study.ledger;var records:Array=model.records.duplicate(true);var scaffold:Array=model.neighbours.duplicate(true)
	check("Inherited host creates same point seven vertices eight arrows four controls",study.lamps.size()==7 and study.rods.size()==8 and study.controls.size()==4 and study.point.held()==false)
	check("Original seven events retained and new return starts omitted",model.records.size()==8 and model.omitted==[7] and model.active_records()==[0,1,2,3,4,5,6] and model.records[7].source=="R04: 5 reports to 1.")
	check("Directed rows do not invent reverse neighbours",model.directed(false)==[[1,2],[3,4],[5,6],[],[5],[],[]])
	check("Transposed rows reverse every active arrow",model.directed(true)==[[],[0],[0],[1],[1],[2,4],[2]])
	check("Initial outward and backward sets match prediction",ids(model.reachable(4,false))==[4,5] and ids(model.reachable(4,true))==[0,1,4] and model.component(4)==[4])
	study.controls[1].pointer_event({"event_type":0});check("Pointer hover cannot include return",model.omitted==[7])
	study.controls[1].pointer_event({"event_type":2});await ticks()
	check("Pointer press includes return and redraws its arrow",model.omitted.is_empty() and study.rods[7].visible and "included" in study.source_label.text and drawings_valid(study))
	check("Return creates predicted outward backward and mutual sets",ids(model.reachable(4,false))==[1,3,4,5] and ids(model.reachable(4,true))==[0,1,2,4,5] and model.component(4)==[1,4,5])
	check("Every start within component finds same maximal group",model.component(1)==[1,4,5] and model.component(5)==[1,4,5])
	check("One-way reachable vertex remains its own component",model.component(3)==[3] and model.component(0)==[0] and model.component(2)==[2])
	check("Text marks both outgoing-only incoming-only and neither",study.labels[1].text=="1 / BOTH" and study.labels[3].text=="3 / OUT" and study.labels[2].text=="2 / BACK" and study.labels[6].text=="6 / neither")
	# Independent Floyd-Warshall closure from literal endpoints, not model adjacency.
	var source:=[0,0,1,1,2,2,4,5];var dest:=[1,2,3,4,5,6,5,1]
	var kinds:=["report","payment","report","payment","report","payment","payment","report"]
	var good:=true;var cases:=0
	for mask in range(256):
		model.omitted.clear()
		for i in range(8):
			if mask & (1<<i):model.omitted.append(i)
		for filter in ["all","payment","report"]:
			model.filter_kind=filter;var closure:Array=[]
			for a in range(7):
				var row:Array=[]
				for b in range(7):row.append(a==b)
				closure.append(row)
			for i in range(8):
				if not (mask & (1<<i)) and (filter=="all" or kinds[i]==filter):closure[source[i]][dest[i]]=true
			for k in range(7):
				for a in range(7):
					for b in range(7):closure[a][b]=closure[a][b] or (closure[a][k] and closure[k][b])
			for a in range(7):
				var out:Array=[];var back:Array=[];var both:Array=[]
				for b in range(7):
					if closure[a][b]:out.append(b)
					if closure[b][a]:back.append(b)
					if closure[a][b] and closure[b][a]:both.append(b)
				good=good and ids(model.reachable(a,false))==out and ids(model.reachable(a,true))==back and model.component(a)==both
			cases+=1
	observations.subset_filter_cases=cases
	check("All768 subset-filter cases and all seven starts match independent closure",good)
	check("Queries preserve source records and earlier undirected scaffold",records==model.records and scaffold==model.neighbours)
	check("Invalid starts return empty safely",model.component(-1).is_empty() and model.reachable(7,true).is_empty())
	study.reset();model.filter_kind="missing"
	check("No active arrows still leaves zero-edge self reachability",model.component(4)==[4] and model.reachable(4,false)==[4])
	model.filter_kind="all";var original:Array=model.component(4)
	model.records.append(records[6].duplicate());model.records.append({"from":4,"to":4,"kind":"report","source":"test self"})
	check("Parallel records and self loop do not change reachability",model.component(4)==original and model.directed(false)[4]==[5,4])
	model.records.resize(8);study.reset();await ticks()
	await key_press(KEY_2);await key_press(KEY_1);check("Keyboard changes start to5 while retaining return",study.start==5 and model.component(study.start)==[1,4,5])
	await key_press(KEY_1,true);check("Key echo cannot skip a start",study.start==5)
	var places:Array=study.places.duplicate();await key_press(KEY_3)
	check("Drawing layout moves positions without changing graph or component",study.places!=places and model.records==records and model.component(5)==[1,4,5] and drawings_valid(study))
	await key_press(KEY_R);check("Reset restores initial start omitted return and drawing",study.start==4 and model.omitted==[7] and study.places==study.INITIAL)
	study.position=Vector3(2,0,-3);study.rotation.y=.7;var point_id:int=study.point.get_instance_id()
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks()
	hand.global_position=study.to_global(Vector3(.1,2.1,.4))
	for i in range(5):await ticks()
	var projected:Vector3=study.to_local(study.point.global_position)-study.FRONT
	check("Held carried point updates selected drawing in local XY only",study.point.held() and study.places[4].is_equal_approx(Vector3(projected.x,projected.y,0)) and model.component(4)==[4])
	places=study.places.duplicate();study.cycle_filter();study.switch_layout();study.reset()
	check("Start layout and reset wait while point held",study.start==4 and study.places==places and study.point.held())
	study.point.action();await ticks();check("Held trigger includes return and changes component",model.component(4)==[1,4,5] and "included" in study.source_label.text and drawings_valid(study))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await ticks()
	check("Release preserves object identity and selected projected position",not study.point.held() and study.point.get_instance_id()==point_id and study.point.position.is_equal_approx(study.places[4]+study.FRONT))
	study.controls[0].pointer_event({"event_type":2})
	for i in range(5):await ticks()
	print("START diagnostic ",study.start," actual=",study.point.position," desired=",study.places[5]+study.FRONT," held=",study.point.held()," filter=",model.filter_kind)
	check("START moves same point to new selected ID",study.start==5 and study.point.get_instance_id()==point_id and study.point.position.is_equal_approx(study.places[5]+study.FRONT))
	study.queue_free();xr.queue_free();await ticks()
	var variant=load(OUT+"variation/study.tscn").instantiate();root.add_child(variant);await ticks();variant.toggle_record()
	check("Independent5to2 return leaves4 alone but joins2and5",variant.ledger.component(4)==[4] and variant.ledger.component(2)==[2,5] and variant.ledger.component(5)==[2,5])
	check("Independent new arrow and source match changed destination",drawings_valid(variant) and variant.ledger.records[7].to==2 and "5 reports to 2" in variant.source_label.text)
	variant.queue_free();await ticks()
	var fault=load(OUT+"fault-direction/reachability.gd").new();check("Checker rejects searching outward twice",fault.component(4)!=[4])
	fault=load(OUT+"fault-filter/reachability.gd").new();check("Checker rejects union instead of intersection",fault.component(4)!=[4])
	fault=load(OUT+"fault-omission/reachability.gd").new();check("Checker rejects an omitted return still being followed",fault.component(4)!=[4])
	completed=true;check("All planned connectivity code checks completed",completed)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations,"scope":"Fresh exact printed code, independent closure oracle, transfer and faults, keyboard and synthetic XRTools; no physical headset or independent reader."},"  "))
	quit(0 if completed and failures.is_empty() else 1)
