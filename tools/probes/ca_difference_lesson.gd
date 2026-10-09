extends SceneTree
const OUT:="res://doc/book/iterations/2026-10-08-ca-what-a-difference-keeps/"
var checks:Array=[]
var failures:Array=[]
var max_error:=0.0
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("CA DIFFERENCE ",label," ",ok)
func frames(n:int=3) -> void:
	for i in n:await physics_frame
func error(a:PackedFloat64Array,b:PackedFloat64Array) -> float:
	if a.size()!=b.size():return INF
	var d:=0.0
	for i in a.size():d=maxf(d,absf(a[i]-b[i]))
	return d
func configure(model,integer:bool,scatter:bool,drive:float,pull:float,changed:bool=true) -> void:
	model.integer_storage=integer;model.scattered=scatter;model.drive=drive;model.pull=pull;model.changed=changed;model.reset()
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var Pair=load(OUT+"printed/paired.gd");var model=Pair.new()
	check("Both 1331-site arrays start at four except B centre five",model.a.size()==1331 and model.a.count(4)==1331 and model.b.count(4)==1330 and model.b[665]==5)
	model.b[0]=6;check("Changing B leaves independent A intact",model.a[0]==4);model.reset()
	check("Interior has26 and corner7 neighbours; no self or wrap",model.neighbours[665].size()==26 and not model.neighbours[665].has(665) and model.neighbours[0].size()==7 and not model.neighbours[0].has(10))
	var oa:PackedFloat64Array=model.a;var ob:PackedFloat64Array=model.b
	model.step();check("Integer uniform first update erases intervention in whole arrays",model.a==model.b and model.report().count==0 and model.report().maximum==0)
	check("Step retains old arrays and advances once",oa.count(4)==1331 and ob[665]==5 and model.tick==1)
	configure(model,false,false,0,.25);model.step()
	check("Fractional first update has27 differences and peak0.75",model.report().count==27 and absf(model.report().maximum-.75)<1e-12)
	check("Centre loses quarter; neighbour gains quarter divided by26",absf(model.b[665]-4.75)<1e-12 and absf(model.b[664]-4.0-.25/26)<1e-12)
	var bounded:=true;var previous:float=model.report().maximum
	for i in 19:
		model.step();var current:float=model.report().maximum;bounded=bounded and current<=previous+1e-12;previous=current
	check("Unforced fractional peak never increases through20 updates",bounded and model.report().count>27 and previous<.75)
	configure(model,false,false,0,0);oa=model.a.duplicate();ob=model.b.duplicate()
	for i in 20:model.step()
	check("No pull or drive preserves all values and one difference",model.a==oa and model.b==ob and model.report().count==1 and model.report().maximum==1)
	configure(model,false,true,1,.25,false)
	for i in 25:model.step()
	check("Identical beginnings stay identical under matched forcing",model.a==model.b and model.report().count==0)
	var production=load("res://algorithms/cellularautomata/ca_showcase/difference_model.gd").new()
	var schedule:=true
	for i in [0,1,665,1330]:
		for gen in [0,1,20,99]:schedule=schedule and model.sample(i,gen)==production.sample(i,gen) and absf(model.sample(i,gen))<=1
	check("Supplied finite forcing schedule matches installed samples",schedule)
	var parity:=true;var in_bounds:=true
	for settings in [[true,false,0,.25],[false,false,0,.25],[true,true,1,.25],[false,true,1,.25],[true,true,4,1.0],[false,true,4,1.0]]:
		configure(model,settings[0],settings[1],settings[2],settings[3]);production.integer_storage=settings[0];production.scattered=settings[1];production.disturbance=settings[2];production.coupling=settings[3];production.changed=true;production.reset()
		for i in 20:
			model.step();production.step();var d:float=maxf(error(model.a,production.a),error(model.b,production.b));max_error=maxf(max_error,d);parity=parity and d==0
			for v in model.a:in_bounds=in_bounds and v>=0 and v<=9
			for v in model.b:in_bounds=in_bounds and v>=0 and v<=9
	check("120 complete paired updates exactly match installed model",parity)
	check("Both storage modes remain bounded under strong shared drive",in_bounds)
	configure(model,false,false,0,0);model.b[665]=4.0+5e-7
	check("Count excludes tiny difference but maximum and mean retain it",model.report().count==0 and model.report().maximum>0 and model.report().mean>0)
	var corner=load(OUT+"variants/corner/paired.gd").new();corner.integer_storage=false;corner.reset();corner.step()
	check("Printed corner edit affects exactly8 sites and keeps peak0.75",corner.report().count==8 and absf(corner.report().maximum-.75)<1e-12)
	check("Corner propagation respects recipient neighbour counts and no wrap",absf(corner.b[1]-4-.25/11)<1e-12 and absf(corner.b[133]-4-.25/26)<1e-12 and corner.b[10]==4)
	var wrong=load(OUT+"variants/unmatched/paired.gd").new();configure(wrong,false,true,1,.25,false);wrong.step()
	check("Unmatched forcing fault fails equal-beginning control",wrong.a!=wrong.b)
	var scan=load(OUT+"variants/in-place/paired.gd").new();configure(scan,false,false,0,.25);scan.step()
	check("In-place update fault fails analytic first-step result",scan.report().count!=27 or absf(scan.b[664]-4-.25/26)>1e-12)
	var study=load(OUT+"printed/difference.gd").new();world.add_child(study);await frames()
	check("Complete construction builds two1331-site volumes and three images",study.volumes.size()==2 and study.volumes[0].instance_count==1331 and study.textures.size()==3 and study.point!=null)
	oa=study.model.a.duplicate();ob=study.model.b.duplicate();study.select_slice(6)
	check("Spatial section changes without state or clock mutation",study.slice_z==6 and study.model.a==oa and study.model.b==ob and study.model.tick==0)
	var img:Image=study.textures[2].get_image();var dark:Color=Color("112c31")
	check("Slice6 hides centre difference while global count stays1",img.get_pixel(5,5).is_equal_approx(dark) and study.model.report().count==1)
	study.select_slice(5);img=study.textures[2].get_image()
	check("Slice5 restores visible centre and frames agree",img.get_pixel(5,5).is_equal_approx(Color("ffd18e")) and is_zero_approx(study.frames[0].position.z) and is_zero_approx(study.frames[1].position.z))
	study.model.integer_storage=false;study.model.reset();study.step()
	check("First fractional gain is4over3 and printed with measured maximum",absf(study.gain-4.0/3)<1e-12 and study.reading.text.contains("0.75000000") and study.reading.text.contains("GAIN"))
	img=study.textures[2].get_image();var first_peak:=img.get_pixel(5,5)
	for i in 19:study.step()
	check("Peak can stay bright while numeric maximum fades",study.model.report().maximum<.75 and study.gain>4.0/3 and first_peak.is_equal_approx(study.textures[2].get_image().get_pixel(5,5)))
	var transforms:=true
	for side in 2:
		for z in 11:
			for y in 11:
				for x in 11:
					var i:int=model.index(Vector3i(x,y,z));var at:=Vector3((-.85 if side==0 else .85)+(x-5)*.085,1.12+y*.085,(z-5)*.085)
					transforms=transforms and study.volumes[side].get_instance_transform(i).origin.is_equal_approx(at)
	check("All2662 spatial addresses stay fixed while state colours change",transforms)
	var hit=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1.2,.6),Vector3(0,.8,.6),1))
	check("Native table remains solid below selection rail",not hit.is_empty() and absf(hit.position.y-1.04)<.001)
	study.position=Vector3(3,0,-2);study.rotation.y=.8
	var origin:=XROrigin3D.new();world.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await frames()
	oa=study.model.a.duplicate();ob=study.model.b.duplicate();var gen:int=study.model.tick
	controller.global_position=study.to_global(Vector3(0,1.24,.085));await frames(6)
	check("Held world position selects localZ6 in rotated study without a step",study.point.held() and study.slice_z==6 and study.model.tick==gen and study.model.a==oa and study.model.b==ob)
	study.point.action();await frames();check("Point trigger advances exactly one update",study.model.tick==gen+1)
	controller.global_position=study.to_global(Vector3(0,1.24,4));await frames(6);check("Hand reader clamps beyond rail to slice10",study.slice_z==10)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await frames();check("Release parks at last chosen slice",not study.point.held() and study.point.position.is_equal_approx(Vector3(0,1.24,.425)))
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_R;study._unhandled_key_input(key)
	check("Replay keeps storage and section while restoring beginning",study.model.tick==0 and not study.model.integer_storage and study.slice_z==10 and study.model.report().count==1)
	key.keycode=KEY_ENTER;study._unhandled_key_input(key);key.echo=true;study._unhandled_key_input(key);check("Keyboard STEP ignores key repeat",study.model.tick==1)
	key.echo=false;key.keycode=KEY_I;study._unhandled_key_input(key);check("Storage toggle resets pair, not slice",study.model.integer_storage and study.model.tick==0 and study.slice_z==10)
	for keycode in [KEY_C,KEY_P,KEY_N,KEY_B]:key.keycode=keycode;study._unhandled_key_input(key)
	check("Remaining controls set matched scattered drive with no pull",not study.model.changed and study.model.pull==0 and study.model.drive==1 and study.model.scattered and study.model.a==study.model.b)
	model.tick=99;model.step();oa=model.a.duplicate();model.step();check("Model stops at100 without extra state change",model.tick==100 and model.a==oa)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"maximum_parity_difference":max_error,"scope":"Exact printed files;120 paired source updates; analytic storage/boundary cases; corner transfer; two faults; nativegeometry and supplied XRTools poses. No physical headset or independent student."},"  "))
	world.queue_free();await frames();quit(0 if failures.is_empty() else 1)
