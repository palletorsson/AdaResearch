extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-09-affect-one-cue/"
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("AFFECT ","PASS " if ok else "FAIL ",title)
func ticks()->void:await physics_frame;await process_frame
func key_press(code:Key,echo:bool=false)->void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;event.echo=echo
	Input.parse_input_event(event);await ticks()
func fixture(folder:String):
	var n=load(OUT+folder+"/study.tscn").instantiate();root.add_child(n);n.set_process(false);return n
func vertices(n:MeshInstance3D)->PackedVector3Array:return n.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func run()->void:
	var study=fixture("printed")
	await ticks()
	check("Downloadable root initializes meshes, material, point and label",study.left.mesh!=null and study.right.mesh!=null and study.point!=null and not study.caption.text.is_empty())
	check("Carried snapshot has 330 entries and 616 triangles",study.saved_positions.size()==330 and study.saved_indices.size()==1848)
	var previous=load("res://doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Playground_of_Joy/vessel_surface.gd").new();previous.sim.simulate(40,.0166667)
	check("Snapshot matches previous hall's actual construction",previous.sim.positions==study.saved_positions and previous.indices==study.saved_indices)
	check("Two displays share the same immutable geometry resource",study.left.mesh==study.right.mesh and vertices(study.left)==study.saved_positions)
	check("Materials belong to separate displays",study.left.material_override!=study.right.material_override)
	check("Baseline is still and neutral on both sides",study.condition==0 and study.left.rotation==Vector3.ZERO and study.right.rotation==Vector3.ZERO and study.left.material_override.albedo_color==study.right.material_override.albedo_color)
	var kept:PackedVector3Array=study.saved_positions.duplicate();var faces:PackedInt32Array=study.saved_indices.duplicate();var mesh_id:int=study.left.mesh.get_instance_id()
	study._process(1)
	check("Baseline does not move or advance the solver",study.left.rotation==Vector3.ZERO and study.right.rotation==Vector3.ZERO and study.surface.sim.positions==kept)
	study.next_condition();study._process(1)
	check("Only right node turns at the declared rate",is_equal_approx(study.right.rotation.z,.7) and study.left.rotation==Vector3.ZERO)
	check("Turning preserves geometry, colours and simulation state",vertices(study.right)==kept and study.right.mesh.get_instance_id()==mesh_id and study.left.material_override.albedo_color==study.right.material_override.albedo_color and study.surface.sim.positions==kept)
	study.next_condition()
	check("Colour condition clears the previous turn",study.condition==2 and study.right.rotation==Vector3.ZERO)
	check("Only right material changes",study.left.material_override.albedo_color==study.NEUTRAL and study.right.material_override.albedo_color==study.ACCENT)
	study._process(1)
	check("Colour condition remains still and preserves mesh data",study.right.rotation==Vector3.ZERO and vertices(study.right)==kept and study.saved_indices==faces)
	study.next_condition()
	check("Cycle returns to complete baseline",study.condition==0 and study.right.rotation==Vector3.ZERO and study.left.material_override.albedo_color==study.right.material_override.albedo_color)
	study.position=Vector3(3,1,-2);study.rotation.y=.6
	check("Host placement leaves saved local coordinates unchanged",vertices(study.left)==kept and vertices(study.right)==kept)
	await key_press(KEY_1)
	check("Actual keyboard dispatch cycles condition",study.condition==1)
	await key_press(KEY_1,true);check("Key echo cannot skip a comparison",study.condition==1)
	await key_press(KEY_2);check("Actual reset key restores baseline",study.condition==0)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
	hand.global_position=study.point.global_position;study.point.pick_up(pickup);await ticks();hand.global_position+=Vector3(.2,.3,0);await ticks()
	check("Carried PointBody attaches to the hand",study.point.is_picked_up() and study.point.held())
	study.point.action();await ticks();check("Inherited action selects motion condition",study.condition==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks();check("Release preserves condition and saved shape",not study.point.held() and study.condition==1 and vertices(study.right)==kept)
	study.queue_free();origin.queue_free();await ticks()
	var variation=fixture("variation");variation.set_condition(1);variation._process(1)
	check("Independent half-speed edit gives half the angle",is_equal_approx(variation.right.rotation.z,.35) and variation.left.rotation==Vector3.ZERO)
	check("Half-speed edit retains exact snapshot and colour",vertices(variation.right)==kept and variation.right.material_override.albedo_color==variation.left.material_override.albedo_color)
	variation.queue_free();await ticks()
	var fault=fixture("fault-shared");fault.set_condition(2)
	check("Test catches shared-material fault",fault.left.material_override.albedo_color!=fault.NEUTRAL)
	fault.queue_free();await ticks()
	fault=fixture("fault-cues");fault.set_condition(1);fault._process(1);fault.set_condition(2)
	check("Test catches accumulated-cues fault",fault.right.rotation!=Vector3.ZERO)
	fault.queue_free();await ticks()
	fault=fixture("fault-live");fault.set_condition(1);fault._process(1)
	check("Test catches continued-solver fault",vertices(fault.right)!=kept)
	fault.queue_free();await ticks()
	var out:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE);out.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed learner code, independent edit, three executed fault programs; no assertion about felt aliveness."},"\t"));out.close()
	quit(0 if failures.is_empty() else 1)
