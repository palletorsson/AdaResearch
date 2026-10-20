extends SceneTree
const OUT:="res://doc/book/iterations/2026-10-10-network-a-record-counted/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
var completed:=false
func _initialize() -> void:run.call_deferred()
func check(title:String,ok:bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("NETWORK ","PASS " if ok else "FAIL ",title)
func ticks() -> void:await physics_frame;await process_frame
func key_press(code:Key,echo:bool=false) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;event.echo=echo
	Input.parse_input_event(event);await ticks()
func totals(model) -> Array:
	var result:Array=[]
	for id in range(7):result.append(model.counts(id))
	return result
func drawings_valid(study) -> bool:
	for i in study.ledger.active_records():
		var r:Dictionary=study.ledger.records[i];var rod:MeshInstance3D=study.rods[i];var tip:MeshInstance3D=study.tips[i]
		var a:Vector3=study.places[r.from];var b:Vector3=study.places[r.to]
		if not (rod.position-rod.basis.y*rod.mesh.height*.5).is_equal_approx(a):return false
		if not (rod.position+rod.basis.y*rod.mesh.height*.5).is_equal_approx(b):return false
		if tip.basis.y.dot((b-a).normalized())<.999:return false
	return true
func run() -> void:
	var study=load(OUT+"printed/study.tscn").instantiate();root.add_child(study);await ticks()
	var ledger=study.ledger;var original:Array=ledger.records.duplicate(true);var scaffold:Array=ledger.neighbours.duplicate(true)
	check("Complete printed host creates seven vertices, arrows and four controls",study.lamps.size()==7 and study.rods.size()==7 and study.tips.size()==7 and study.controls.size()==4)
	var pairs:Array=[]
	for a in range(scaffold.size()):
		for b:int in scaffold[a]:
			if a<b:pairs.append(Vector2i(a,b))
	var record_pairs:Array=[]
	for record in original:record_pairs.append(Vector2i(record.from,record.to))
	pairs.sort();record_pairs.sort()
	check("Directed records preserve the previous seven undirected endpoint pairs",pairs==record_pairs)
	var incoming:=[0,1,1,1,1,2,1];var outgoing:=[2,2,2,0,1,0,0];var good:=true
	for id in range(7):good=good and ledger.counts(id)==Vector2i(incoming[id],outgoing[id])
	check("All-record counts match an independent table",good)
	ledger.omitted.assign([6]);check("Omitting P04 removes one outgoing at4 and incoming at5",ledger.counts(4)==Vector2i(1,0) and ledger.counts(5)==Vector2i(1,0))
	ledger.omitted.clear();ledger.filter_kind="payment"
	check("Payment filter counts four events and their directed endpoints",ledger.active_records()==[1,3,5,6] and ledger.counts(4)==Vector2i(1,1) and ledger.counts(5)==Vector2i(1,0))
	ledger.filter_kind="report";var reports:Array=totals(ledger);ledger.omitted.assign([6])
	check("Omitting payment under report filter has no effect",ledger.active_records()==[0,2,4] and totals(ledger)==reports)
	ledger.filter_kind="all";check("Omission persists when the filter changes",ledger.active_records().size()==6 and ledger.counts(4).y==0)
	var sources:=[0,0,1,1,2,2,4];var destinations:=[1,2,3,4,5,6,5];var kinds:=["report","payment","report","payment","report","payment","payment"]
	good=true;var cases:=0
	for mask in range(128):
		ledger.omitted.clear()
		for i in range(7):
			if mask & (1<<i):ledger.omitted.append(i)
		for filter in ["all","payment","report"]:
			ledger.filter_kind=filter;var ins:=0;var outs:=0;var active:=0
			for i in range(7):
				if not (mask & (1<<i)) and (filter=="all" or kinds[i]==filter):active+=1
			for id in range(7):
				var expected:=Vector2i.ZERO
				for i in range(7):
					if mask & (1<<i) or (filter!="all" and kinds[i]!=filter):continue
					if destinations[i]==id:expected.x+=1
					if sources[i]==id:expected.y+=1
				var got:Vector2i=ledger.counts(id);good=good and got==expected;ins+=got.x;outs+=got.y
			good=good and ins==active and outs==active;cases+=1
	observations.filter_omission_cases=cases
	check("All384 filter and omission combinations match endpoint oracle and totals",good)
	check("Counting preserves sources and undirected scaffold",ledger.records==original and ledger.neighbours==scaffold)
	study.reset();ledger.records.append(original[6].duplicate())
	check("Parallel events are counted separately from unique neighbours",ledger.counts(4)==Vector2i(1,2) and ledger.counts(5)==Vector2i(3,0))
	ledger.records.pop_back();ledger.records.append({"from":4,"to":4,"kind":"report","source":"Self-addressed test"})
	check("Self-addressed record contributes one incoming and one outgoing",ledger.counts(4)==Vector2i(2,2))
	ledger.records.pop_back();ledger.filter_kind="unknown";check("Empty filter returns zero without division or missing-key errors",ledger.active_records().is_empty() and ledger.counts(4)==Vector2i.ZERO)
	study.reset();await ticks();check("Cylinders and arrowheads agree with record direction",drawings_valid(study))
	await key_press(KEY_1);check("Keyboard selects payment filter and redraws counts",ledger.filter_kind=="payment" and "in 1 / out 0" in study.labels[5].text)
	await key_press(KEY_1,true);check("Key echo cannot skip a filter",ledger.filter_kind=="payment")
	study.controls[1].pointer_event({"event_type":0});check("Pointer hover cannot omit an event",ledger.omitted.is_empty())
	study.controls[1].pointer_event({"event_type":2});await ticks();check("Pointer press omits exactly P04 and hides its arrow",ledger.omitted==[6] and not study.rods[6].visible and not study.tips[6].visible)
	var before:Array=totals(ledger);var positions:Array=study.places.duplicate()
	study.controls[2].pointer_event({"event_type":2});await ticks()
	check("Layout moves positions without changing active counts or sources",study.places!=positions and totals(ledger)==before and ledger.records==original and drawings_valid(study))
	await key_press(KEY_R);check("Reset restores records filter and layout",ledger.active_records().size()==7 and study.places==study.INITIAL)
	var point_id:int=study.point.get_instance_id()
	study.position=Vector3(2,0,-3);study.rotation.y=.65
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks()
	before=totals(ledger);hand.global_position=study.to_global(Vector3(.1,1.7,.3))
	for unused in range(5):await ticks()
	var projected:Vector3=study.to_local(study.point.global_position)-study.FRONT
	check("Held point moves vertex4 in local XY while counts remain fixed",study.point.held() and study.places[4].is_equal_approx(Vector3(projected.x,projected.y,0)) and totals(ledger)==before and drawings_valid(study))
	positions=study.places.duplicate();study.switch_layout();study.reset()
	check("Layout and reset wait for release",study.places==positions and study.point.held())
	study.point.action();await ticks();check("Inherited held trigger filters the same records",ledger.filter_kind=="payment" and ledger.records==original)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for unused in range(5):await ticks()
	check("Release preserves point identity and returns it to the plane",not study.point.held() and study.point.get_instance_id()==point_id and study.point.position.is_equal_approx(study.places[4]+study.FRONT))
	study.reset();await ticks();study.places[4]=study.places[5];study.redraw()
	check("Coincident markers hide undrawable arrow but retain record and counts",not study.rods[6].visible and ledger.active_records().size()==7 and ledger.counts(5)==Vector2i(2,0))
	study.queue_free();xr.queue_free();await ticks()
	var variant=load(OUT+"variation/ledger.gd").new()
	check("Independent reversal changes endpoint roles and keeps seven events",variant.counts(4)==Vector2i(2,0) and variant.counts(5)==Vector2i(1,1) and variant.active_records().size()==7 and variant.records[6].source=="P04: 5 pays 4.")
	var reversed_study=load(OUT+"variation/study.tscn").instantiate();root.add_child(reversed_study);await ticks()
	check("Independent reversal draws an arrow from5 to4 with matching source",drawings_valid(reversed_study) and reversed_study.tips[6].basis.y.dot(Vector3.LEFT)>.999 and "5 pays 4" in reversed_study.source_label.text)
	reversed_study.queue_free();await ticks()
	var fault=load(OUT+"fault-direction/ledger.gd").new();check("Checker rejects outgoing counted as incoming",fault.counts(0)!=Vector2i(0,2))
	fault=load(OUT+"fault-filter/ledger.gd").new();fault.filter_kind="report";check("Checker rejects a filter that changes only the label",fault.active_records()!=[0,2,4])
	fault=load(OUT+"fault-omission/ledger.gd").new();fault.omitted.assign([6]);check("Checker rejects an omission that still contributes to counts",fault.counts(4)!=Vector2i(1,0))
	completed=true;check("All planned network code checks completed",completed)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations,"scope":"Fresh exact printed code; independent counts,384 filter/omission states, reversal exercise, three faulty variants, keyboard and synthetic XRTools. No physical headset or independent reader."},"  "))
	quit(0 if completed and failures.is_empty() else 1)
