extends SceneTree
const OUT:="res://doc/book/iterations/2026-10-09-morphogenesis-who-connected-the-controls/"
var checks:Array=[]
var failures:Array=[]
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("MORPHOGENESIS ","PASS " if ok else "FAIL ",title)
func ticks()->void:await physics_frame;await process_frame
func press(key:Key,echo:bool=false)->void:
	var event:=InputEventKey.new();event.keycode=key;event.pressed=true;event.echo=echo;Input.parse_input_event(event);await ticks()
func fixture(folder:String):
	var n=load(OUT+folder+"/study.tscn").instantiate();n.position=Vector3(3,.4,-2);n.rotation.y=.7;root.add_child(n);return n
func triple(d:Dictionary)->Vector3:return Vector3(d.frequency,d.noise_amp,d.threshold)
func parameters(g)->Vector3:return Vector3(g.frequency,g.noise_amp,g.threshold)
func vertices(g)->PackedVector3Array:return g.gyroid_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
func run()->void:
	var study=fixture("printed");await ticks()
	check("Two complete specimens and carried point are constructed",study.generators.size()==2 and study.point!=null and study.holders.size()==2)
	check("Opening recipe has three predicted named values",triple(study.recipe(.3,0)).is_equal_approx(Vector3(1.11,.095,-.06)))
	check("Master recipe reaches declared endpoints",triple(study.recipe(-2,0)).is_equal_approx(Vector3(.9,.05,-.15)) and triple(study.recipe(2,0)).is_equal_approx(Vector3(1.6,.2,.15)))
	check("Frequency mode changes only its recipient",triple(study.recipe(1,1)).is_equal_approx(Vector3(1.6,.095,-.06)))
	check("Noise mode changes only its recipient",triple(study.recipe(1,2)).is_equal_approx(Vector3(1.11,.2,-.06)))
	check("Cut mode holds both field parameters",triple(study.recipe(1,3)).is_equal_approx(Vector3(1.11,.095,.15)))
	var a=study.generators[0];var b=study.generators[1]
	check("Both specimens use matching noise and sample volume",a.noise.seed==1337 and b.noise.seed==1337 and a.box_size==Vector3.ONE*8 and a.voxel_resolution==Vector3i(24,24,24))
	var kept:PackedVector3Array=vertices(a).duplicate()
	check("Matched beginning has identical actual mesh vertices",kept==vertices(b) and kept.size()>100)
	check("Both mesh skins have supplied collision",a.collision_body.get_child(0).shape is ConcavePolygonShape3D and b.collision_body.get_child(0).shape.get_faces().size()>100)
	check("Quarter-scale fixture is two metres wide",study.holders[0].scale==Vector3.ONE*.25 and a.gyroid_mesh.mesh.get_aabb().size.x*.25<=2.001)
	var old_mesh:int=b.gyroid_mesh.mesh.get_instance_id()
	await press(KEY_UP);check("Keyboard preview updates value without rebuilding",is_equal_approx(study.preview,.4) and b.gyroid_mesh.mesh.get_instance_id()==old_mesh and is_equal_approx(study.committed,.3))
	await press(KEY_UP,true);check("Echo input is ignored",is_equal_approx(study.preview,.4))
	await press(KEY_1);check("Mode selection alone leaves geometry intact",study.mode==1 and b.gyroid_mesh.mesh.get_instance_id()==old_mesh)
	await press(KEY_SPACE)
	check("Build commits only selected recipient on B",is_equal_approx(b.frequency,1.18) and is_equal_approx(b.noise_amp,.095) and is_equal_approx(b.threshold,-.06) and b.gyroid_mesh.mesh.get_instance_id()!=old_mesh)
	check("Reference A survives B rebuild unchanged",vertices(a)==kept and parameters(a).is_equal_approx(Vector3(1.11,.095,-.06)))
	check("Replacement removes stale mesh and collider",study.holders[1].get_child_count()==2)
	await press(KEY_R);check("Reset restores baseline mesh and control state",vertices(b)==kept and study.mode==0 and is_equal_approx(study.preview,.3))
	study.mode=3;study.preview=1;study.apply_preview();await ticks()
	var p:=Vector3(.4,.7,-.3);var da:float=a.calculate_gyroid_density(p);var db:float=b.calculate_gyroid_density(p)
	check("Cut change has predicted normalized-density difference",is_equal_approx(db-da,-.035))
	check("Cut-only edit changes actual boundary",vertices(b)!=kept and is_equal_approx(b.frequency,a.frequency) and is_equal_approx(b.noise_amp,a.noise_amp))
	study.reset();await ticks()
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await ticks();old_mesh=b.gyroid_mesh.mesh.get_instance_id()
	hand.global_position=study.to_global(Vector3(0,1.6,1.35));for i in 5:await ticks()
	check("Held point height uses the transformed lesson frame",study.point.held() and is_equal_approx(study.preview,1.0))
	check("Moving point only previews until trigger",b.gyroid_mesh.mesh.get_instance_id()==old_mesh and is_equal_approx(study.committed,.3))
	study.point.action();await ticks();check("XR trigger rebuilds from preview",is_equal_approx(study.committed,1) and parameters(b).is_equal_approx(Vector3(1.6,.2,.15)) and b.gyroid_mesh.mesh.get_instance_id()!=old_mesh)
	hand.global_position=study.to_global(Vector3(0,.1,1.35));for i in 5:await ticks()
	check("Height below the interval clamps preview",is_zero_approx(study.preview))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await ticks()
	check("Release preserves built surface and parks at preview",not study.point.held() and is_equal_approx(study.committed,1) and study.point.position.is_equal_approx(Vector3(0,.8,1.35)))
	old_mesh=b.gyroid_mesh.mesh.get_instance_id();study.point.action();await ticks()
	check("Unheld trigger cannot rebuild",b.gyroid_mesh.mesh.get_instance_id()==old_mesh)
	observations.mesh_vertices={"reference":kept.size(),"all_at_one":vertices(b).size()}
	study.queue_free();origin.queue_free();await ticks()
	var variation=fixture("variation");await ticks()
	check("Independent span edit changes both starting cuts",parameters(variation.generators[0]).is_equal_approx(Vector3(1.11,.095,-.12)))
	variation.preview=1;variation.apply_preview();await ticks()
	check("Independent span edit preserves frequency and noise",parameters(variation.generators[1]).is_equal_approx(Vector3(1.6,.2,.3)))
	variation.mode=3;variation.apply_preview();await ticks()
	check("Independent CUT mode keeps the common reference parameters",parameters(variation.generators[1]).is_equal_approx(Vector3(1.11,.095,.3)))
	variation.queue_free();await ticks()
	for fault in ["fault-cut","fault-coupled","fault-seed","fault-recipient"]:
		var bad=fixture(fault);await ticks();var detected:=false
		match fault:
			"fault-cut":detected=not triple(bad.recipe(.3,0)).is_equal_approx(Vector3(1.11,.095,-.06))
			"fault-coupled":detected=not triple(bad.recipe(1,1)).is_equal_approx(Vector3(1.6,.095,-.06))
			"fault-seed":detected=vertices(bad.generators[0])!=vertices(bad.generators[1])
			"fault-recipient":
				bad.preview=1;bad.apply_preview();detected=not parameters(bad.generators[0]).is_equal_approx(Vector3(1.11,.095,-.06)) or not parameters(bad.generators[1]).is_equal_approx(Vector3(1.6,.2,.15))
		check("Contract rejects "+fault,detected);bad.queue_free();await ticks()
	var receipt={"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Exact printed code inside the project; synthetic XRTools and actual input. No physical headset or independent human learner."}
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"));quit(0 if failures.is_empty() else 1)
