extends SceneTree
const OUT:="res://doc/book/iterations/2026-10-09-contact-the-same-start/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("CONTACT ","PASS " if ok else "FAIL ",title)
func ticks(n:int=2)->void:
	for i in n:await physics_frame;await process_frame
func positions(body:SoftBody3D)->PackedVector3Array:
	var out:=PackedVector3Array()
	for i in body.rest_points.size():out.append(body.get_point_transform(i))
	return out
func difference(a:PackedVector3Array,b:PackedVector3Array)->float:
	var d:=0.0
	for i in a.size():d=maxf(d,a[i].distance_to(b[i]))
	return d
func unpinned(body:SoftBody3D)->bool:
	for i in body.rest_points.size():
		if body.is_point_pinned(i):return false
	return true
func same_recipe(a:SoftBody3D,b:SoftBody3D)->bool:
	return a.rest_points==b.rest_points and a.total_mass==b.total_mass and a.linear_stiffness==b.linear_stiffness and a.pressure_coefficient==b.pressure_coefficient and a.simulation_precision==b.simulation_precision and a.collision_mask==b.collision_mask and a.collision_layer==b.collision_layer and a.material_override.albedo_color==b.material_override.albedo_color
func run()->void:
	check("Prepared project uses Jolt",ProjectSettings.get_setting("physics/3d/physics_engine")=="Jolt Physics")
	var floor:=StaticBody3D.new();floor.position.y=-.1;var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(100,.2,100);collision.shape=box;floor.add_child(collision);root.add_child(floor)
	var host:=Node3D.new();host.position=Vector3(3,0,-2);host.rotation.y=.6;root.add_child(host)
	var study=load(OUT+"printed/study.gd").new();host.add_child(study);study.set_physics_process(false)
	var a:SoftBody3D=study.panels[0];var b:SoftBody3D=study.panels[1]
	check("Full host creates two panels, two inherited points and two captions",study.panels.size()==2 and study.points.size()==2 and study.captions.size()==2 and study.points[0].has_method("pick_up"))
	check("Same construction and properties except declared damping",same_recipe(a,b) and is_equal_approx(a.damping_coefficient,.1) and is_equal_approx(b.damping_coefficient,.6))
	check("Both previous perimeter selections are released",unpinned(a) and unpinned(b) and a.pins.is_empty() and b.pins.is_empty())
	check("Matching horizontal starting geometry at equal height",a.position.is_equal_approx(Vector3(-1,2.1,0)) and b.position.is_equal_approx(Vector3(1,2.1,0)) and a.basis.is_equal_approx(b.basis) and is_equal_approx(a.rotation.z,PI*.5))
	study._physics_process(0);check("Both captions are initialized",not study.captions[0].text.is_empty() and not study.captions[1].text.is_empty())
	await ticks()
	check("Shared points park correctly below the panels under a moved parent",study.points[0].global_position.is_equal_approx(study.to_global(study.bay(0)+study.CONTACT)) and study.points[1].global_position.is_equal_approx(study.to_global(study.bay(1)+study.CONTACT)))
	var start:=positions(a);await ticks(35);var fell:=difference(start,positions(a));check("Native panel vertices fall and deform",fell>.05)
	study._physics_process(1.49);check("No reading before the declared sample time",study.results.is_empty() and study.running)
	study._physics_process(.02);var recorded:Array=study.results.duplicate()
	check("First step beyond sample time keeps two finite positive heights",recorded.size()==2 and recorded.all(func(v):return is_finite(v) and v>0) and not study.running)
	var shape:=positions(a);await ticks(35);study._physics_process(.5)
	var moved:=difference(shape,positions(a));check("Readings stay while physics continues",study.results==recorded and moved>.001 and is_equal_approx(study.elapsed,1.51))
	var expected_low:=INF;var expected_high:=-INF
	for p in positions(a):
		var y:float=study.to_local(p).y;expected_low=minf(expected_low,y);expected_high=maxf(expected_high,y)
	check("Sample is local vertical extent, not absolute height",is_equal_approx(study.height_span(a),expected_high-expected_low))
	var old:int=a.get_instance_id();var point_id:int=study.points[0].get_instance_id();study.replay()
	check("Replay replaces panels and clears time and observations",study.panels[0].get_instance_id()!=old and study.results.is_empty() and is_zero_approx(study.elapsed) and study.running and not study.armed)
	check("Replay retains both point objects and reconstructs released geometry",study.points[0].get_instance_id()==point_id and unpinned(study.panels[0]) and study.panels[0].rest_points==a.rest_points)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.points[0].global_position
	study.points[0].pick_up(pickup);await ticks();hand.global_position+=Vector3(.4,.2,0);await ticks();var held_at:Vector3=study.points[0].global_position;study._physics_process(.2)
	check("Existing PointBody grips and interrupts the comparison",study.points[0].is_picked_up() and not study.running and study.results.is_empty() and study.status=="Hand changes the experiment")
	check("A held point is not teleported to its parking place",study.points[0].global_position.is_equal_approx(held_at) and held_at.distance_to(study.to_global(study.bay(0)+study.CONTACT))>.1)
	old=study.panels[0].get_instance_id();study.points[0].action();study._physics_process(.2)
	check("Trigger queues replay without rebuilding while held",study.armed and study.panels[0].get_instance_id()==old)
	var pointer:=Node.new();root.add_child(pointer);study.points[1].on_desktop_grab(pointer)
	study.points[0].let_go(pickup,Vector3.ZERO,Vector3.ZERO);study._physics_process(.2)
	check("Replay waits for the other held point too",study.armed and study.panels[0].get_instance_id()==old)
	study.points[1].on_desktop_drop(pointer);study._physics_process(.2)
	check("Last release parks points then starts a fresh drop",not study.armed and study.running and study.panels[0].get_instance_id()!=old and is_zero_approx(study.elapsed) and study.points[0].global_position.is_equal_approx(study.to_global(study.bay(0)+study.CONTACT)))
	old=study.panels[0].get_instance_id();var event:=InputEventKey.new();event.keycode=KEY_1;event.pressed=true;study._unhandled_key_input(event);study._physics_process(0)
	check("Keyboard 1 requests the same fresh replay",study.panels[0].get_instance_id()!=old)
	# Native runs advance the actual host clock, rather than manual time above.
	study.set_physics_process(true);study.replay();await ticks(100)
	check("Native timed run produces two observations",study.results.size()==2 and not study.running and study.elapsed>=1.5 and study.elapsed<1.54)
	observations.native_heights=study.results.duplicate()
	var edited=load(OUT+"variation/study.gd").new();edited.position=Vector3(5,0,0);host.add_child(edited);await ticks(100)
	check("Independent edit runs with equal damping and shared recipe",edited.results.size()==2 and edited.panels[0].damping_coefficient==edited.panels[1].damping_coefficient and same_recipe(edited.panels[0],edited.panels[1]))
	observations.equal_damping_heights=edited.results.duplicate()
	# Compare contact with the same fresh drop absent its point colliders.
	var contact=load(OUT+"printed/study.gd").new();contact.position=Vector3(10,0,0);host.add_child(contact)
	var clear=load(OUT+"printed/study.gd").new();clear.position=Vector3(15,0,0);host.add_child(clear)
	for point in clear.points:point.collision_layer=0
	await ticks(42);var contact_delta:=0.0;var cp:=positions(contact.panels[0]);var np:=positions(clear.panels[0])
	for i in cp.size():contact_delta=maxf(contact_delta,contact.to_local(cp[i]).distance_to(clear.to_local(np[i])))
	check("Point collider changes the otherwise matching native drop",contact_delta>.01)
	for fault in ["fault-reset","fault-confound","fault-held"]:
		var bad=load(OUT+fault+"/study.gd").new();bad.position=Vector3(22,0,0);host.add_child(bad);bad.set_physics_process(false);await ticks();var rejected:=false
		match fault:
			"fault-reset":var id:int=bad.panels[0].get_instance_id();bad.replay();rejected=bad.panels[0].get_instance_id()==id
			"fault-confound":rejected=not same_recipe(bad.panels[0],bad.panels[1])
			"fault-held":bad.points[0].on_desktop_grab(pointer);bad._physics_process(1.6);rejected=not bad.results.is_empty()
		check("Behaviour rejects "+fault,rejected);bad.queue_free();await ticks()
	# Regression for the installed gallery's HOLD/RELEASE control.
	var desk=load("res://commons/artifacts/timing_machines/soft_workshop.gd").new();root.add_child(desk)
	var support:=Node3D.new();support.position=Vector3(28,2,0);host.add_child(support)
	var specimen=load(OUT+"printed/pressure_panel.gd").new()
	for index in specimen.pins:specimen.set_point_pinned(index,false)
	specimen.pins.clear();support.add_child(specimen);await ticks()
	var anchor:=Node3D.new();support.add_child(anchor);var path:NodePath=specimen.get_path_to(anchor)
	specimen.set_point_pinned(0,true,path);await ticks(10);var offset:Vector3=specimen.get("attachments/0/offset")
	var identity:int=specimen.get_instance_id();desk._hold_bodies(support,true);await ticks(4)
	var held_shape:=positions(specimen);await ticks(20)
	check("Gallery HOLD keeps current points without replacing the body",difference(held_shape,positions(specimen))<.002 and specimen.get_instance_id()==identity)
	var anchors:int=desk.get_child_count();desk._hold_bodies(support,true)
	check("Repeated HOLD retains the same anchor",desk.get_child_count()==anchors and desk.saved_pins.size()==1)
	desk._hold_bodies(support,false);await ticks()
	var original:Array=specimen.get("pinned_points")
	check("RELEASE restores original pin, attachment and offset",original==[0] and specimen.get("attachments/0/spatial_attachment_path")==path and specimen.get("attachments/0/offset").is_equal_approx(offset))
	check("RELEASE removes temporary anchor records",desk.saved_pins.is_empty() and desk.get_child_count()==0)
	desk.queue_free()
	observations.merge({"contact_difference":contact_delta,"motion_after_sample":moved,"entries":start.size(),"scope":"Exact printed native Jolt programs; independent edit and faults; synthetic XRTools, no headset or independent learner."})
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	host.queue_free();floor.queue_free();origin.queue_free();pointer.queue_free();await ticks();quit(0 if failures.is_empty() else 1)
