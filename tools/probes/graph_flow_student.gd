extends SceneTree
const OUT="res://doc/book/iterations/2026-10-10-flow-room-for-another/"
const ENDS:=[Vector2i(0,1),Vector2i(0,2),Vector2i(1,3),Vector2i(1,4),Vector2i(2,3),Vector2i(3,5),Vector2i(4,5),Vector2i(5,6)]
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
var completed:=false
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("PASS " if ok else "FAIL ",label)
func ticks() -> void:await process_frame;await physics_frame;await process_frame
func finish_model(m) -> void:
	for i in range(25):
		if m.done:return
		m.step()
func valid(m) -> bool:
	for a in range(7):
		var balance:=0
		for b in range(7):
			if m.flow[a][b]!=-m.flow[b][a] or m.flow[a][b]>m.capacity[a][b]:return false
			balance+=m.flow[a][b]
		if balance!=(m.total if a==0 else (-m.total if a==6 else 0)):return false
	return true
func cut_value(mask:int,caps:Array) -> int:
	# Independent enumeration of all32 source/sink partitions, literal endpoints.
	var best:=100000
	for inside in range(32):
		var side:=[0]
		for v in range(1,6):
			if inside&(1<<(v-1)):side.append(v)
		var cost:=0
		for i in range(8):
			if mask&(1<<i) and ENDS[i].x in side and ENDS[i].y not in side:cost+=caps[i]
		best=mini(best,cost)
	return best
func run() -> void:
	var study=load(OUT+"printed/study.tscn").instantiate();root.add_child(study);await ticks()
	var m=study.model;var original:Array=m.links.duplicate(true)
	check("Complete printed harbour creates seven stations eight roads and two nearby controls",study.houses.size()==7 and study.rods.size()==8 and study.controls.size()==2)
	check("Empty allocation conserves flow and has first predicted route",m.total==0 and valid(m) and m.search()==[0,1,3,5,6])
	study.controls[0].pointer_event({"event_type":0});check("Hover does not allocate",m.total==0)
	study.controls[0].pointer_event({"event_type":2});await ticks()
	check("Actual pointer allocates first unit",m.total==1 and m.path==[0,1,3,5,6] and valid(m))
	check("Reverse residual represents one cancellable slot",m.residual(3,1)==1 and m.capacity[3][1]==0)
	var event:=InputEventKey.new();event.keycode=KEY_1;event.pressed=true;Input.parse_input_event(event);await ticks()
	check("Keyboard second route uses cancellation and reaches two",m.total==2 and m.path==[0,2,3,1,4,5,6] and m.flow[1][3]==0 and valid(m))
	check("Pink cancellation and forward numeric allocation are visible",study.cancelled.visible and study.weights[2].text=="0 / 1" and "cancel 1 slot on 1 -> 3" in study.caption.text)
	event.echo=true;Input.parse_input_event(event);await ticks();check("Keyboard echo does not advance",not m.done)
	study.advance();check("Empty search certifies completion and preserves total",m.done and m.total==2 and valid(m) and not study.cancelled.visible)
	study.advance();check("Completed model stays stable",m.total==2 and m.done and m.links==original)
	var Model=load(OUT+"printed/flow_model.gd");var good:=true;var cases:=0
	for caps in [[1,1,1,1,1,1,1,2],[2,3,1,3,2,2,2,4],[1,1,1,0,1,1,1,2]]:
		for mask in range(256):
			var candidate=Model.new();candidate.links.clear()
			for i in range(8):
				if mask&(1<<i):candidate.links.append({"a":ENDS[i].x,"b":ENDS[i].y,"cap":caps[i]})
			candidate.reset()
			for step in range(25):
				candidate.step();good=good and valid(candidate)
				if candidate.done:break
			good=good and candidate.done and candidate.total==cut_value(mask,caps);cases+=1
	observations.input_cases=cases;check("All768 inputs conserve flow and attain independently enumerated cut capacity",good)
	study.reset();check("Reset clears allocation and restores drawing",m.total==0 and not m.done and study.places==study.INITIAL and valid(m))
	study.position=Vector3(2,0,-3);study.rotation.y=.7;var identity:int=study.point.get_instance_id()
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks()
	hand.global_position=study.to_global(Vector3(.3,1.4,.5))
	for i in range(5):await ticks()
	var p:Vector3=study.to_local(study.point.global_position)-Vector3.UP*.24
	check("Held point moves yard4 in localXZ without changing capacities",study.point.held() and study.places[4].is_equal_approx(Vector3(p.x,1,p.z)) and m.links==original)
	study.point.action();await ticks();check("Held trigger allocates one route",m.total==1 and valid(m))
	study.reset();check("Reset waits for release",m.total==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for i in range(5):await ticks()
	check("Release retains same point above its yard",study.point.get_instance_id()==identity and not study.point.held() and study.point.position.is_equal_approx(study.places[4]+Vector3.UP*.24))
	study.advance();check("Moved drawing preserves attainable flow",m.total==2 and valid(m))
	study.queue_free();xr.queue_free();await ticks()
	var variant=load(OUT+"variation/study.tscn").instantiate();root.add_child(variant);await ticks();finish_model(variant.model)
	check("Independent destination-capacity edit permits only one unit",variant.model.done and variant.model.total==1 and valid(variant.model));variant.queue_free()
	var fault=load(OUT+"fault-reverse/flow_model.gd").new();fault.reset();finish_model(fault);check("Test rejects missing reverse cancellation",fault.total!=2 or not valid(fault))
	fault=load(OUT+"fault-bottleneck/flow_model.gd").new();fault.reset();fault.step();check("Test rejects largest-capacity rather than bottleneck",not valid(fault))
	fault=load(OUT+"fault-residual/flow_model.gd").new();fault.reset();finish_model(fault);check("Test rejects ignoring previously assigned flow",not valid(fault) or not fault.done)
	var gallery=load("res://commons/artifacts/graph_worlds/graph_worlds.tscn").instantiate();root.add_child(gallery);await ticks()
	check("Concrete gallery has eleven documented contexts",gallery.cases.size()==11 and gallery.controls.size()==4)
	gallery.select_case(0);gallery.act();check("Human visit adds one room to queue order",gallery.evidence.visited==[0,1])
	gallery.select_case(1);var trails=gallery.edges.duplicate(true);var places=gallery.positions.duplicate();gallery.act();check("Animal trail layout changes coordinates only",gallery.edges==trails and gallery.positions!=places)
	gallery.select_case(2);var route=gallery.evidence.route.duplicate();gallery.act();check("Bridge closure changes route and excludes closed crossing",gallery.evidence.route!=route and not [1,3] in gallery.edges)
	gallery.select_case(3);gallery.act();check("Social share omission changes event counts",gallery.evidence.counts[1]==1 and gallery.edges.size()==6)
	gallery.select_case(4);check("Ferry starts with three mutually reachable islands",gallery.evidence.mutual.size()==3);gallery.act();check("Return service joins all six islands",gallery.evidence.mutual.size()==6)
	gallery.select_case(5)
	for i in range(9):gallery.act()
	check("Village pipe failure strands three homes",gallery.evidence.reached.size()==4);gallery.act();check("Spare village pipe restores seven",gallery.evidence.reached.size()==7)
	gallery.select_case(6);gallery.act();gallery.act();check("Harbour companion uses same exact flow model",gallery.evidence.total==2)
	gallery.select_case(7);gallery.act();check("Workshop revision increases compatible pairs to two",gallery.evidence.pairs==[1,2])
	gallery.select_case(8);gallery.act();var infections=gallery.infected.duplicate();check("Contact round cannot cascade beyond initial neighbours",gallery.infected.size()<=2 and (gallery.infected==[0] or gallery.infected==[0,1]));gallery.select_case(8);gallery.act();check("Contact seed replays same first round",gallery.infected==infections)
	gallery.select_case(9);gallery.act();check("Historical bridge multigraph has four odd vertices",gallery.evidence.degree==[5,3,3,3] and gallery.edges.size()==7)
	gallery.select_case(10);gallery.act();check("Future relay outage removes route",gallery.evidence.route.is_empty());gallery.act();check("Future spare restores a route",not gallery.evidence.route.is_empty())
	gallery.queue_free();await ticks()
	completed=true;check("All planned flow and context checks completed",completed)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
