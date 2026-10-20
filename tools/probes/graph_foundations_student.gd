extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-graph-two-orders/"
var checks: Array = []
var failures: Array = []
var completed := false
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("GRAPH ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func key_press(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new(); event.keycode=code; event.pressed=true; event.echo=echo
	Input.parse_input_event(event); await ticks()
func fixture(folder: String):
	var node = load(OUT+folder+"/study.tscn").instantiate(); root.add_child(node); return node
func visits(model, breadth: bool) -> Array:
	model.restart(breadth)
	var result: Array = []
	# Bound faults: the subject must finish, not merely avoid a crash.
	for unused in range(30):
		var vertex: int = model.next_visit()
		if vertex == -1: return result
		result.append(vertex)
	return result
func run() -> void:
	var study = fixture("printed"); await ticks()
	check("Printed scene creates seven lamps, a point and a readable label",study.lamps.size()==7 and study.point!=null and "Pending: [0]" in study.caption.text)
	var model = study.graph
	var original: Array = model.neighbours.duplicate(true)
	check("Queue visits in expected breadth-first order",visits(model,true)==[0,1,2,3,4,5,6])
	check("Stack visits in expected depth-first order",visits(model,false)==[0,1,3,4,2,5,6])
	check("Both runs keep every stored connection and its order",model.neighbours==original)
	check("Exhausted traversal returns no vertex",model.next_visit()==-1 and model.pending.is_empty())
	model.restart(true);model.next_visit()
	check("One visit records zero and two pending neighbours",model.visited==[0] and model.pending==[1,2])
	model.neighbours=[[1,2],[0,2,3],[0,1,3],[1,2]]
	check("Cyclic queue graph visits each identity once",visits(model,true)==[0,1,2,3])
	check("Cyclic stack graph visits each identity once",visits(model,false)==[0,1,2,3])
	check("Cycle terminates after skipping repeated candidates",model.next_visit()==-1 and model.pending.is_empty())
	model.neighbours=[[1],[0],[]]
	check("Disconnected vertex is not invented as reachable",visits(model,true)==[0,1] and visits(model,false)==[0,1])
	model.neighbours=[[0]]
	check("A self-loop cannot visit zero twice",visits(model,true)==[0])
	model.neighbours=original; study.restart(true)
	var point_id: int = study.point.get_instance_id()
	await key_press(KEY_1)
	check("Actual input dispatch advances exactly one visit",study.current==0 and model.visited==[0])
	await key_press(KEY_1,true)
	check("Key echo does not consume another visit",model.visited==[0])
	await key_press(KEY_1)
	check("Pending and lamp colour agree with second visit",study.current==1 and model.pending==[2,3,4] and study.lamps[1].material_override.albedo_color==study.TIDE and study.lamps[2].material_override.albedo_color==study.NEUTRAL)
	await key_press(KEY_2)
	check("Switch resets visit state without replacing connections",not model.breadth and model.pending==[0] and model.visited.is_empty() and study.current==-1 and model.neighbours==original)
	for unused in range(7): study.advance()
	check("Seventh visit remains visible until next action",study.finished and model.visited==[0,1,3,4,2,5,6] and study.current==6)
	study.advance()
	check("Next action prepares the other order without consuming zero",model.breadth and model.visited.is_empty() and model.pending==[0])
	study.position=Vector3(3,1,-2);study.rotation.y=.6
	var origin := XROrigin3D.new();root.add_child(origin)
	var hand := XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks()
	hand.global_position+=Vector3(.3,.2,.1);await ticks()
	check("Inherited PointBody attaches to the XRTools hand",study.point.is_picked_up() and study.point.held())
	study.point.action();await ticks()
	check("Inherited trigger performs one graph visit",model.visited==[0] and study.current==0)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for unused in range(4): await ticks()
	print("DROP: held=",study.point.held()," parent=",study.point.get_parent().get_path()," local=",study.point.position," visited=",model.visited)
	check("Drop parks point in transformed host and keeps visit state",not study.point.held() and study.point.position.is_equal_approx(study.PARK) and model.visited==[0])
	await key_press(KEY_R)
	check("Restart retains point identity and current method",study.point.get_instance_id()==point_id and model.breadth and model.visited.is_empty())
	var rods: Array = []
	for node in study.get_children():
		if node is MeshInstance3D and node.mesh is CylinderMesh: rods.append(node)
	check("Drawing has six rods for six undirected connections",rods.size()==6)
	var aligned := true
	for rod: MeshInstance3D in rods:
		var a:Vector3=rod.position-rod.basis.y*rod.mesh.height*.5
		var b:Vector3=rod.position+rod.basis.y*rod.mesh.height*.5
		var hit_a:=false;var hit_b:=false
		for position:Vector3 in study.places:
			hit_a=hit_a or a.is_equal_approx(position);hit_b=hit_b or b.is_equal_approx(position)
		aligned=aligned and hit_a and hit_b
	check("Every rendered rod ends on actual lamp positions",aligned)
	study.queue_free();origin.queue_free();await ticks()
	var variant = fixture("variation")
	check("Independent root edit changes queue order as predicted",visits(variant.graph,true)==[0,2,1,5,6,3,4])
	check("Independent root edit changes stack order as predicted",visits(variant.graph,false)==[0,2,5,6,1,3,4])
	var same_edges:=true
	for i in range(original.size()):
		var a:Array=original[i].duplicate();var b:Array=variant.graph.neighbours[i].duplicate();a.sort();b.sort();same_edges=same_edges and a==b
	check("Independent edit retains all edges and lamp positions",same_edges and variant.places.size()==7)
	variant.queue_free();await ticks()
	var fault=load(OUT+"fault-end/traversal.gd").new()
	check("Checker detects taking the wrong queue end",visits(fault,true)!=[0,1,2,3,4,5,6])
	fault=load(OUT+"fault-copy/traversal.gd").new();var prior:Array=fault.neighbours.duplicate(true);visits(fault,false)
	check("Checker detects reversing source neighbours in place",fault.neighbours!=prior)
	fault=load(OUT+"fault-repeat/traversal.gd").new();fault.neighbours=[[1,2],[0,3],[0,3],[1,2]]
	var repeated:Array=visits(fault,true)
	check("Checker detects visiting a pending duplicate twice",repeated.size()>4)
	completed=true
	check("All planned graph code checks completed",completed)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"scope":"Exact printed code, independent neighbour-order edit, cycle/disconnection tests, three executed faulty variants, real keyboard dispatch and synthetic XRTools hand. No headset or independent-reader claim."},"  "))
	quit(0 if completed and failures.is_empty() else 1)
