extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-pathfinding-a-route-kept/"
var checks: Array = []
var failures: Array = []
var observations := {}
var completed := false
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("PATH ","PASS " if ok else "FAIL ",title)
func ticks() -> void:await physics_frame;await process_frame
func find(model,start:int,goal:int,blocked:Array) -> Array:
	var ids:Array[int]=[];ids.assign(blocked)
	return model.find_path(start,goal,ids)
func key_press(code:Key,echo:bool=false) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;event.echo=echo
	Input.parse_input_event(event);await ticks()
func route_valid(model,path:Array,blocked:Array) -> bool:
	for id:int in path:
		if id in blocked:return false
	for i in range(path.size()-1):
		if path[i+1] not in model.neighbours[path[i]]:return false
	return true
func exhaustive_min(model,start:int,goal:int,blocked:Array,seen:Array=[]) -> int:
	if start in blocked or goal in blocked or start in seen:return 99
	if start==goal:return 0
	var best:=99;var now:Array=seen.duplicate();now.append(start)
	for next:int in model.neighbours[start]:best=mini(best,1+exhaustive_min(model,next,goal,blocked,now))
	return best
func drawing_valid(study) -> bool:
	for i in range(study.rods.size()):
		var rod:MeshInstance3D=study.rods[i];var ids:Array=study.ends[i]
		if not (rod.position-rod.basis.y*rod.mesh.height*.5).is_equal_approx(study.places[ids[0]]):return false
		if not (rod.position+rod.basis.y*rod.mesh.height*.5).is_equal_approx(study.places[ids[1]]):return false
	return true
func run() -> void:
	var study=load(OUT+"printed/study.tscn").instantiate();root.add_child(study);await ticks();study.set_process(false)
	var model=study.graph;var original:Array=model.neighbours.duplicate(true)
	check("Printed host creates seven lamps, seven rods, point and caption",study.lamps.size()==7 and study.rods.size()==7 and study.point!=null and "Route:" in study.caption.text)
	var carried=load(OUT+"printed/traversal.gd").new();var expected:Array=carried.neighbours.duplicate(true);expected[4].append(5);expected[5].append(4)
	check("Exactly one reciprocal detour extends the carried graph",original==expected)
	var initial:Array=find(model,3,6,[])
	check("Unblocked path uses four edges",initial==[3,1,0,2,6])
	check("Predecessors recover goal to start with explicit sentinel",model.predecessor[6]==2 and model.predecessor[2]==0 and model.predecessor[0]==1 and model.predecessor[1]==3 and model.predecessor[3]==-1)
	check("Search record includes vertices outside returned route",model.visited.size()>initial.size() and 4 in model.visited and 4 not in initial)
	check("Blocking zero takes the new detour",find(model,3,6,[0])==[3,1,4,5,2,6])
	check("Blocking zero and four returns empty without missing-key lookup",find(model,3,6,[0,4]).is_empty() and not model.predecessor.has(6))
	check("Start equals goal returns the one-vertex route",find(model,3,3,[])==[3])
	check("Blocked start and goal return no route",find(model,3,6,[3]).is_empty() and find(model,3,6,[6]).is_empty())
	check("Invalid endpoints return no route",find(model,-1,6,[]).is_empty() and find(model,3,7,[]).is_empty())
	check("New search clears old discovered state",find(model,6,6,[])==[6] and model.predecessor.size()==1 and model.visited==[6])
	var all_ok:=true;var cases:=0
	for mask in range(128):
		var blocked:Array[int]=[]
		for id in range(7):
			if mask & (1<<id):blocked.append(id)
		var path:Array=model.find_path(3,6,blocked);var shortest:=exhaustive_min(model,3,6,blocked)
		all_ok=all_ok and route_valid(model,path,blocked) and (path.is_empty() if shortest>=99 else path.size()-1==shortest)
		cases+=1
	observations.availability_cases=cases
	check("All128 availability masks agree with exhaustive simple-path oracle",all_ok)
	check("All searches retain the complete adjacency record",model.neighbours==original)
	study.replan();check("Rendered rods join the intended stable endpoints",drawing_valid(study))
	var point_id:int=study.point.get_instance_id()
	await key_press(KEY_1)
	check("Keyboard availability change recomputes the detour",study.phase==1 and study.path==[3,1,4,5,2,6])
	var visuals:=true
	for i in range(study.rods.size()):visuals=visuals and (study.rods[i].visible==(0 not in study.ends[i]))
	check("Blocked vertex and its hidden incident rods agree with availability",visuals and study.lamps[0].material_override.albedo_color==study.CLOSED)
	await key_press(KEY_1,true);check("Key echo cannot skip an availability state",study.phase==1)
	study.set_process(true)
	await key_press(KEY_1)
	await ticks()
	check("No-route state parks the same pickable point and explains the result",study.path.is_empty() and study.point.position.is_equal_approx(study.PARK) and "NO ROUTE" in study.caption.text and study.point.get_instance_id()==point_id)
	study.set_process(false)
	await key_press(KEY_1);check("Restore returns initial route without recreating graph",study.path==initial and study.graph.neighbours==original)
	var places:Array=study.places.duplicate();study.places[0]+=Vector3(0,5,0);study.replan()
	check("Coordinate change alone cannot change this unweighted route",study.path==initial)
	study.places.assign(places);study.replan()
	for unused in range(800):study._process(1.0/60.0)
	check("Traveller reaches goal along returned path",study.leg==study.path.size()-1 and study.cursor.is_equal_approx(study.places[6]+study.FRONT))
	await key_press(KEY_R);check("Replay retains availability and returns cursor to start",study.path==initial and study.leg==0 and study.cursor.is_equal_approx(study.places[3]+study.FRONT))
	study.position=Vector3(3,.2,-2);study.rotation.y=.6
	var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks()
	var saved:Vector3=study.cursor;hand.global_position+=Vector3(.3,.2,.1);await ticks();study._process(.5)
	check("Inherited XRTools hold pauses recorded cursor without changing adjacency",study.point.held() and study.cursor==saved and model.neighbours==original)
	study.point.action();await ticks()
	check("Held trigger replaces route with detour",study.path==[3,1,4,5,2,6] and study.phase==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for unused in range(4):await ticks()
	study._process(0.0)
	check("Release returns to route cursor in transformed host",not study.point.held() and study.point.position.is_equal_approx(study.cursor))
	study._process(.1);check("Released point continues along new route",not study.cursor.is_equal_approx(study.places[3]+study.FRONT))
	study.queue_free();xr.queue_free();await ticks()
	var variation=load(OUT+"variation/route.gd").new()
	check("Independent removal of detour leaves initial route intact",find(variation,3,6,[])==initial)
	check("Independent removal makes zero a single point of failure",find(variation,3,6,[0]).is_empty())
	var fault=load(OUT+"fault-block/route.gd").new();var bad:Array=find(fault,3,6,[0])
	check("Checker catches a route using a blocked vertex",not route_valid(fault,bad,[0]))
	fault=load(OUT+"fault-queue/route.gd").new();bad=find(fault,3,6,[])
	check("Checker catches a stack result falsely called fewest edges",bad.size()-1>exhaustive_min(fault,3,6,[]))
	fault=load(OUT+"fault-order/route.gd").new();bad=find(fault,3,6,[])
	check("Checker catches reversed reconstruction",bad[0]!=3 or bad[-1]!=6)
	completed=true;check("All planned pathfinding code checks completed",completed)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations,"scope":"Exact printed code, exhaustive128-mask oracle, independent detour removal, three executed faults, keyboard dispatch and synthetic XRTools in transformed host. No headset or independent-reader claim."},"  "))
	quit(0 if completed and failures.is_empty() else 1)
