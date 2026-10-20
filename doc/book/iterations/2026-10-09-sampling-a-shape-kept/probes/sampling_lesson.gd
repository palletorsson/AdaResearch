extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-09-sampling-a-shape-kept/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("SAMPLING ","PASS " if ok else "FAIL ",title)
func ticks(n:int=2)->void:
	for i in n:await physics_frame;await process_frame
func difference(a:PackedVector3Array,b:PackedVector3Array)->float:
	if a.size()!=b.size():return INF
	var d:=0.0
	for i in a.size():d=maxf(d,a[i].distance_to(b[i]))
	return d
func verts(node:MeshInstance3D)->PackedVector3Array:return node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func advance(study:Node,count:int)->void:
	for i in count:study._physics_process(1.0/60.0)
func fixture(folder:String)->Node3D:
	var node=load(OUT+folder+"/study.gd").new();root.add_child(node);node.set_physics_process(false);return node
func run()->void:
	var packaged=load(OUT+"printed/study.tscn").instantiate();root.add_child(packaged)
	check("Downloadable scene resolves relative script and creates the program",packaged.live.mesh!=null and packaged.point!=null and not packaged.caption.text.is_empty())
	packaged.queue_free();await ticks()
	var study:=fixture("printed")
	study.position=Vector3(3,1,-2);study.rotation.y=.6
	check("Full host initializes two surfaces, caption and inherited pickable",study.live.mesh!=null and study.kept.mesh==null and not study.caption.text.is_empty() and study.point.has_method("pick_up"))
	check("Supplied sphere uses 330 positions and 616 indexed triangles",study.surface.sim.positions.size()==330 and study.surface.indices.size()==1848)
	var initial:PackedVector3Array=study.surface.sim.positions.duplicate()
	advance(study,39)
	check("No automatic snapshot before declared step",study.saved_step==-1 and study.kept.mesh==null)
	advance(study,1)
	var saved:PackedVector3Array=study.saved_positions.duplicate()
	check("Step forty copies all current positions",study.saved_step==40 and saved==study.surface.sim.positions and verts(study.kept)==saved)
	check("Snapshot retains exact face connectivity",study.kept.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]==study.surface.indices and study.saved_indices==study.surface.indices)
	check("Simulation actually changed the sphere",difference(initial,saved)>.01)
	check("Live and saved meshes are separate resources",study.live.mesh!=study.kept.mesh)
	check("Coordinates remain local under a rotated translated host",verts(study.live)==saved and (study.kept.to_global(saved[100])-study.live.to_global(saved[100])).is_equal_approx(study.global_basis*Vector3(1.7,0,0)))
	var identity:int=study.kept.mesh.get_instance_id()
	advance(study,160)
	check("Saved vertices and selected step stay while live state advances",study.saved_step==40 and study.saved_positions==saved and verts(study.kept)==saved and study.kept.mesh.get_instance_id()==identity and difference(saved,study.surface.sim.positions)>.01)
	observations.shape_difference_40_200=difference(saved,study.surface.sim.positions)
	# Compare against the actual installed artifact, not a second copy of the helper.
	var installed=load("res://commons/artifacts/frozen_glass_vessel/frozen_glass_vessel.gd").new();installed.show_label=false;root.add_child(installed)
	observations.installed_difference=difference(study.surface.sim.positions,verts(installed._mi))
	check("Adapter's step-200 positions match installed vessel",difference(study.surface.sim.positions,verts(installed._mi))<.0001)
	check("Adapter retains installed vessel connectivity",study.surface.indices==installed._mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX])
	check("Pinned upper vertices retain their initial positions",range(initial.size()).all(func(i):return not study.surface.sim.pinned[i] or initial[i]==study.surface.sim.positions[i]))
	var expected:PackedVector3Array=study.surface.sim.positions.duplicate();study.capture()
	check("Explicit capture replaces saved mesh and records current step",study.saved_step==200 and study.saved_positions==expected and study.kept.mesh.get_instance_id()!=identity)
	study.surface.sim.positions[100]+=Vector3.UP
	check("Later solver mutation leaves snapshot unchanged",study.saved_positions==expected and verts(study.kept)==expected)
	var point_id:int=study.point.get_instance_id();study.restart()
	check("Restart reconstructs state and clears saved shape",study.step_count==0 and study.saved_step==-1 and study.kept.mesh==null and study.surface.sim.positions==initial and study.saved_positions.is_empty())
	check("Restart retains the carried PointBody instance",study.point.get_instance_id()==point_id)
	var edited:=fixture("variation");advance(edited,199)
	check("Independent step-200 edit waits through step199",edited.kept.mesh==null)
	advance(edited,1)
	check("Independent edit changes capture time, not recipe or topology",edited.saved_step==200 and difference(saved,edited.saved_positions)>.01 and edited.saved_indices==study.surface.indices)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await ticks();hand.global_position+=Vector3(.2,.2,0);await ticks();advance(study,10)
	var hand_position:Vector3=study.point.global_position;study.point.action()
	check("Real XRTools pickup and action capture while held",study.point.is_picked_up() and study.saved_step==10 and study.kept.mesh!=null)
	advance(study,5)
	check("Running sampler does not park the held point",study.point.global_position.is_equal_approx(hand_position))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks()
	var event:=InputEventKey.new();event.keycode=KEY_1;event.pressed=true;Input.parse_input_event(event);await ticks()
	check("Actual keyboard input invokes capture",study.saved_step==15)
	event=InputEventKey.new();event.keycode=KEY_2;event.pressed=true;Input.parse_input_event(event);await ticks()
	check("Actual keyboard input restarts the host",study.step_count==0 and study.kept.mesh==null)
	# Faults run complete programs. The observable contract must reject each.
	for fault in ["fault-follow","fault-clock","fault-faces"]:
		var bad:=fixture(fault);advance(bad,40);var old:PackedVector3Array=verts(bad.kept).duplicate();advance(bad,20);var rejected:=false
		match fault:
			"fault-follow":rejected=verts(bad.kept)!=old
			"fault-clock":bad.restart();rejected=bad.surface.sim.positions!=initial
			"fault-faces":rejected=bad.kept.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]!=study.surface.indices
		check("Behaviour rejects "+fault,rejected);bad.queue_free()
	study.set_physics_process(true);await ticks(45)
	check("Printed host automatically runs and captures on native physics ticks",study.step_count>=40 and study.saved_step==40)
	observations.merge({"source":"Exact tutorial blocks; custom Verlet solver running in native Godot; installed geometry comparison; synthetic XRTools.","vertices":330,"triangles":616,"headset":false})
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	study.queue_free();edited.queue_free();installed.queue_free();origin.queue_free();await ticks();quit(0 if failures.is_empty() else 1)
