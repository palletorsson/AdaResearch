extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-the-surface-includes-you/"
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("CA PRESENCE ",label," ",ok)
func frames(n:int=3) -> void:
	for i in n:await physics_frame
func equal_fields(a:Dictionary,b:Dictionary) -> bool:
	if a.size()!=b.size():return false
	for site in a:
		if not b.has(site) or absf(a[site]-b[site])>1e-9:return false
	return true
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var study=load(OUT+"printed/presence.gd").new();world.add_child(study);await frames()
	var w:=Vector2i(2,6)
	check("Printed construction creates eighty states, supports, point and label",study.current.size()==80 and study.supports.size()==80 and study.materials.size()==80 and study.point!=null and study.reading.text.contains("1.000"))
	var field:Dictionary=study.current.duplicate();field[w]=0.0
	check("Four axial neighbours, no centre or diagonals",study.neighbours(field,w)==4)
	field[Vector2i(1,6)]=.5;field[Vector2i(3,6)]=.3;field[Vector2i(2,5)]=.2;field[Vector2i(2,7)]=.50001
	check("Only health strictly above half contributes",study.neighbours(field,w)==1)
	check("Boundary has no wraparound contribution",study.neighbours(study.current,Vector2i(0,0))==2)
	var at:Vector3=study.cell_position(w);var old:Dictionary=study.current.duplicate()
	var next:Dictionary=study.evolve(old,at,true)
	check("Presence subtracts .04 without simultaneous recovery",is_equal_approx(next[w],.96))
	check("Update preserves previous dictionary",equal_fields(old,study.current) and not is_same(old,next))
	next=study.evolve(old,at+Vector3.UP*1.35,true)
	check("Exactly radius is outside decay; vertical separation counts",is_equal_approx(next[w],1.0))
	field=old.duplicate();field[w]=.3
	check("Missing input permits .04 recovery from four neighbours",is_equal_approx(study.evolve(field,at,false)[w],.34))
	field[w]=.02
	check("Decay clamps at zero",study.evolve(field,at,true)[w]==0.0)
	field[w]=.99
	check("Recovery clamps at one",study.evolve(field,at,false)[w]==1.0)
	for site in field:field[site]=0.0
	check("Entirely depleted field stays empty after withdrawal",equal_fields(field,study.evolve(field,at,false)))
	study.chain=true;study.reset();old=study.current.duplicate();next=study.evolve(old,at,false)
	check("SYNC chain middle rises but next neighbour waits",is_equal_approx(next[w],.505) and next[Vector2i(3,6)]==0)
	study.backwards=true
	check("SYNC reverse gives identical field",equal_fields(next,study.evolve(old,at,false)))
	study.synchronous=false;study.backwards=false;next=study.evolve(old,at,false)
	check("Forward SCAN permits within-pass propagation",is_equal_approx(next[Vector2i(3,6)],.01))
	study.backwards=true
	check("Reverse SCAN makes that neighbour wait",study.evolve(old,at,false)[Vector2i(3,6)]==0)
	var production=load("res://algorithms/cellularautomata/living_architecture/decaying_bridge.gd").new();production._study_requested=true;production._study_dimensions()
	var rng:=RandomNumberGenerator.new();rng.seed=86008;var parity:=true
	for sync in [true,false]:
		for reverse in [true,false]:
			study.synchronous=sync;study.backwards=reverse
			for present in [true,false]:
				for site in field:field[site]=rng.randf()
				var input:=Vector3(.3,.7,3.1)
				for i in 20:
					var got:Dictionary=study.evolve(field,input,present)
					var want:Dictionary=production.calculate_next(field,.1,input,present,sync,reverse)
					parity=parity and equal_fields(got,want);field=got
	check("160 updates across sources and schedules match installed solver",parity);production.free()
	study.synchronous=true;study.backwards=false;study.chain=false;study.reset()
	for i in 21:study.current=study.evolve(study.current,at+Vector3.UP*.25,true)
	study.redraw();await frames()
	check("Twenty-one nearby updates remove W support at .16",is_equal_approx(study.current[w],.16) and study.supports[w].disabled)
	for i in 60:study.current=study.evolve(study.current,at,false)
	check("Healthy boundary permits recovery after withdrawal",study.current[w]>.5)
	var space=world.get_world_3d().direct_space_state;var collisions:=true;var surfaces:=true
	for h in [.5,.3,.2,.199,0.0]:
		study.current[w]=h;study.redraw();await frames()
		var p:Vector3=study.view_position(w)
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.3,p-Vector3.UP*.3,1))
		collisions=collisions and not hit.is_empty() and absf(hit.position.y-(1.02 if h>=.2 else .88))<.002
		var wall_hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(.4,1.28,.72),Vector3(.7,1.28,.72),1))
		surfaces=surfaces and not wall_hit.is_empty()
	check("Native floor support crosses at .2; lower tray always receives",collisions)
	check("Wall backing stays solid for every health",surfaces)
	var reused:=0
	for node in study.get_children():
		if node is MeshInstance3D and is_same(node.material_override,study.materials[w]):reused+=1
	check("Floor and wall W share one changing material",reused==2)
	var transfer=load(OUT+"variants/threshold/presence.gd").new();world.add_child(transfer);transfer.chain=true;transfer.synchronous=false;transfer.reset();transfer.step()
	check("Independent .49 beginning reaches .5 but cannot pass recovery onward",is_equal_approx(transfer.current[w],.5) and transfer.current[Vector2i(3,6)]==0)
	var scan_fault=load(OUT+"variants/scan-fault/presence.gd").new();world.add_child(scan_fault);scan_fault.chain=true;scan_fault.reset();scan_fault.step()
	check("Using new buffer for SYNC fails third-cell prediction",scan_fault.current[Vector2i(3,6)]!=0)
	var flat_fault=load(OUT+"variants/flat-distance/presence.gd").new();world.add_child(flat_fault)
	check("Ignoring height fails out-of-radius prediction",flat_fault.evolve(flat_fault.current,at+Vector3.UP*2,true)[w]<1)
	transfer.queue_free();scan_fault.queue_free();flat_fault.queue_free();await frames()
	study.reset();study.position=Vector3(3,0,-2);study.rotation.y=.9
	var origin:=XROrigin3D.new();world.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=study.point.global_position;study.point.pick_up(hand);await frames()
	controller.global_position=study.to_global(study.view_position(w)+Vector3.UP*.05);await frames(6)
	check("Held point converts world position back through table scale",study.point.held() and study.input_position().is_equal_approx(at+Vector3.UP*.25))
	old=study.current.duplicate();study.point.action();await frames()
	check("Held trigger advances once using its current centre",study.ticks==1 and equal_fields(study.current,study.evolve(old,study.input_position(),true)))
	controller.global_position=study.to_global(study.view_position(w)+Vector3.UP*.4);await frames(6);study.point.action();await frames()
	check("Moving held point upward switches decay to recovery",is_equal_approx(study.current[w],1.0) and study.ticks==2)
	study.point.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames()
	check("Release parks locally in a rotated study",not study.point.held() and study.point.position.is_equal_approx(Vector3(-.65,1.12,.3)))
	study.current[w]=.3;study.step()
	check("Released point has no proximity influence",is_equal_approx(study.current[w],.34))
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER;var ticks:int=study.ticks
	study._unhandled_key_input(key);key.echo=true;study._unhandled_key_input(key)
	check("Enter steps once and ignores repeat",study.ticks==ticks+1)
	key.echo=false;key.keycode=KEY_C;study._unhandled_key_input(key);key.keycode=KEY_O;study._unhandled_key_input(key);key.keycode=KEY_V;study._unhandled_key_input(key)
	check("Order controls reset time and preserve CHAIN",study.chain and not study.synchronous and study.backwards and study.ticks==0 and is_equal_approx(study.current[w],.495))
	key.keycode=KEY_R;study._unhandled_key_input(key)
	for i in 310:study.step()
	check("Full reset clears chain; capacity holds at thirty seconds",not study.chain and study.ticks==300 and study.current[w]==1.0)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed blocks, installed solver parity, native renderer/collision, supplied XRTools poses, transfer and two deliberate faults. No physical headset or independent student."},"  "))
	world.queue_free();await frames();quit(0 if failures.is_empty() else 1)
