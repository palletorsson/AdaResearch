extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-10-layout-the-same-connections/"
var checks: Array = []
var failures: Array = []
var observations := {}
var completed := false
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("LAYOUT ","PASS " if ok else "FAIL ",title)
func ticks() -> void: await physics_frame; await process_frame
func key_press(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new();event.keycode=code;event.pressed=true;event.echo=echo
	Input.parse_input_event(event);await ticks()
func fixture(folder: String):
	var node = load(OUT+folder+"/study.tscn").instantiate();root.add_child(node);return node
func rods_follow(study) -> bool:
	for i in range(study.rods.size()):
		var rod:MeshInstance3D=study.rods[i]
		var a:Vector3=rod.position-rod.basis.y*rod.mesh.height*.5
		var b:Vector3=rod.position+rod.basis.y*rod.mesh.height*.5
		if not a.is_equal_approx(study.drawing.positions[study.ends[i][0]]) or not b.is_equal_approx(study.drawing.positions[study.ends[i][1]]):return false
	return true
func mean_length(model, graph) -> float:
	var total:=0.0;var count:=0
	for a in range(graph.size()):
		for b:int in graph[a]:
			if a<b:total+=model.positions[a].distance_to(model.positions[b]);count+=1
	return total/count
func pair_model(folder: String):
	var model=load(OUT+folder+"/layout.gd").new()
	model.positions.assign([Vector3.ZERO,Vector3(2,0,0)])
	model.velocities.assign([Vector3.ZERO,Vector3.ZERO])
	return model
func run() -> void:
	var study=fixture("printed");await ticks();study.set_physics_process(false)
	check("Printed host initializes seven labels, six rods, the point and caption",study.numbers.size()==7 and study.rods.size()==6 and study.point!=null and "Queue:" in study.caption.text)
	var original:Array=study.graph.neighbours.duplicate(true)
	check("Carried graph retains both previous visit orders",study.visit_order(true)==[0,1,2,3,4,5,6] and study.visit_order(false)==[0,1,3,4,2,5,6])
	var model=load(OUT+"printed/layout.gd").new()
	var initial:Array=model.positions.duplicate()
	var force:Array=model.forces(original)
	var total:=Vector3.ZERO
	for f:Vector3 in force:total+=f
	check("Internal pair forces balance before integration",total.length()<0.00001)
	check("Force calculation does not change the positions it reads",model.positions==initial)
	var pair=pair_model("printed");var actual:Array=pair.forces([[1],[0]])
	check("Two-vertex force matches independent spring-minus-repulsion calculation",actual[0].is_equal_approx(Vector3(2.6925,0,0)) and actual[1].is_equal_approx(-actual[0]))
	actual=pair.forces([[],[]])
	check("Unconnected vertices repel without a spring",actual[0].is_equal_approx(Vector3(-.0075,0,0)))
	pair.positions[1]=Vector3(.3,0,0);actual=pair.forces([[1],[0]])
	check("Compressed edge pushes its ends apart",actual[0].x<0 and actual[1].x>0)
	pair.positions[1]=Vector3.ZERO;pair.step(1.0/60.0,[[1],[0]])
	check("Exact overlap stays finite without claiming a separation direction",pair.positions[0].is_finite() and pair.positions[1].is_finite())
	model.step(1.0/60.0,original)
	check("One shared step moves the drawing",model.positions!=initial)
	model.velocities[0]=Vector3.ONE;var fixed:Vector3=model.positions[0]
	model.step(1.0/60.0,original,0)
	check("Pin retains position and clears its velocity",model.positions[0]==fixed and model.velocities[0]==Vector3.ZERO)
	for unused in range(600):model.step(1.0/60.0,original)
	var bounded:=true
	for v:Vector3 in model.positions:bounded=bounded and v.is_finite() and absf(v.z)<.00001 and v.length()<10
	check("Default drawing remains finite and planar over ten simulated seconds",bounded)
	check("Integration never rewrites adjacency",original==study.graph.neighbours)
	study.drawing=model;study.redraw()
	check("Every cylinder follows its two identified endpoints",rods_follow(study))
	check("After release the same point draws vertex zero",study.point.position.is_equal_approx(model.positions[0]))
	await key_press(KEY_1);var saved:Array=model.positions.duplicate();study._physics_process(1.0/60.0)
	check("Actual key pauses simulation and preserves positions",not study.running and saved==model.positions)
	await key_press(KEY_1,true)
	check("Keyboard echo does not toggle back",not study.running)
	var point_id:int=study.point.get_instance_id()
	await key_press(KEY_R)
	check("Restart restores initial drawing with the same point and adjacency",study.drawing.positions==initial and study.point.get_instance_id()==point_id and study.graph.neighbours==original)
	study.position=Vector3(3,.2,-2);study.rotation.y=.6;study.running=false
	var xr:=XROrigin3D.new();root.add_child(xr)
	var hand:=XRController3D.new();xr.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks()
	hand.global_position=study.to_global(Vector3(.6,2,.4));await ticks()
	study._physics_process(1.0/60.0)
	var local:Vector3=study.to_local(study.point.global_position)
	check("Actual XRTools pickup and local-plane projection work in rotated host",study.point.is_picked_up() and study.drawing.positions[0].is_equal_approx(Vector3(local.x,local.y,0)) and study.lamps[0].visible)
	check("Pinned graph redraw retains endpoints and graph identity",rods_follow(study) and study.graph.neighbours==original)
	study.point.action();await ticks()
	check("Inherited hand trigger resumes layout",study.running)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
	for unused in range(4):await ticks()
	study._physics_process(1.0/60.0)
	check("Release resumes root motion and returns point to projected graph",not study.point.held() and not study.lamps[0].visible and study.point.position.is_equal_approx(study.drawing.positions[0]))
	check("Hand movement and release preserve both visit orders",study.visit_order(true)==[0,1,2,3,4,5,6] and study.visit_order(false)==[0,1,3,4,2,5,6])
	study.queue_free();xr.queue_free();await ticks()
	var base=load(OUT+"printed/layout.gd").new();var variant=load(OUT+"variation/layout.gd").new()
	for unused in range(600):base.step(1.0/60.0,original);variant.step(1.0/60.0,original)
	observations.mean_edge_default=mean_length(base,original);observations.mean_edge_variation=mean_length(variant,original)
	check("Independent longer-rest edit increases mean edge length from identical start",observations.mean_edge_variation>observations.mean_edge_default+.1)
	pair=pair_model("variation");actual=pair.forces([[1],[0]])
	check("Independent edit reduces stretched-pair pull by predicted amount",actual[0].is_equal_approx(Vector3(2.1925,0,0)))
	var fault=load(OUT+"fault-adjacency/layout.gd").new();var damaged:Array=original.duplicate(true);fault.step(1.0/60.0,damaged)
	check("Checker catches a layout that writes connectivity",damaged!=original)
	var bad=fixture("fault-rods");bad.set_physics_process(false);bad.redraw()
	check("Checker catches cylinders that do not track endpoint separation",not rods_follow(bad));bad.queue_free();await ticks()
	pair=pair_model("fault-step");pair.step(1.0/60.0,[[1],[0]])
	check("Checker catches sequential force sampling through centre drift",absf((pair.positions[0]+pair.positions[1]).x-2.0)>.0000001)
	completed=true;check("All planned layout code checks completed",completed)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":completed and failures.is_empty(),"completed":completed,"checks":checks,"failures":failures,"observations":observations,"scope":"Fresh exact printed scripts; physical assertions; keyboard dispatch; synthetic XRTools hand; independent rest-length edit; three executed faults. Not a physical headset or blind reader test."},"  "))
	quit(0 if completed and failures.is_empty() else 1)
