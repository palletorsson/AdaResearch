extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-growth-what-a-branch-keeps/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void:run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("GROWTH ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	await physics_frame
	await physics_frame
	await physics_frame
	await process_frame
func close(a:Array,b:Array) -> bool:
	if a.size()!=b.size():return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):return false
	return true
func key(study:Node,code:int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	study._unhandled_key_input(event)
func run() -> void:
	var host:=Node3D.new();host.position=Vector3(4,0,-2);host.rotation.y=.65;root.add_child(host)
	var study=load(DIR+"printed/growth.gd").new();host.add_child(study);await settle()
	var model=study.model
	check("Complete printed program creates point and two initial readings",study.point.has_method("pick_up") and study.drawing.get_child_count()==4 and study.cursor==1 and study.held.cursor==1)
	check("Parallel replacement still reads old sentence",model.rewrite("AB",{"A":"B","B":"AA"}).text=="BAA")
	check("Inherited budget accepts4096 and refuses4098 as whole generation",model.rewrite("F".repeat(2048),{"F":"FF"}).accepted and not model.rewrite("F".repeat(2049),{"F":"FF"}).accepted)
	var frames:Array=study.reading.frames
	check("START and eleven independent frames accompany five segments",frames.size()==12 and study.reading.ends.size()==10 and frames[0].pos==Vector3.ZERO and frames[1].pos.is_equal_approx(Vector3.UP*.8))
	check("Save occurs before branch length and angle change",frames[2].stack_depth==1 and frames[2].segments==1 and is_equal_approx(frames[2].length,.576) and is_equal_approx(frames[2].angle,38))
	check("Turn changes heading without moving or drawing",frames[3].pos==frames[2].pos and frames[3].segments==1 and not frames[3].heading.is_equal_approx(Vector3.UP))
	for i in 3:study.step()
	key(study,KEY_H);var kept:Dictionary=study.held.duplicate(true)
	check("Hold copies actual displayed branch prefix",study.cursor==4 and kept.ends.size()==4 and kept.frame.stack_depth==1)
	study.step();var restored:Dictionary=study.snapshot().frame
	check("Return restores every state field",restored.pos.is_equal_approx(Vector3.UP*.8) and restored.heading.is_equal_approx(Vector3.UP) and is_equal_approx(restored.length,.8) and is_equal_approx(restored.angle,40) and restored.depth==0 and restored.stack_depth==0)
	check("Return keeps old branch and draws no connecting segment",study.snapshot().ends==kept.ends and study.held==kept and restored.segments==2)
	key(study,KEY_ENTER);check("Next trunk resumes at1.6 metres",study.cursor==6 and study.snapshot().frame.pos.is_equal_approx(Vector3.UP*1.6))
	study.choose(3)
	check("Ratio rereads same sentence and cursor without changing held snapshot",study.sentence==kept.text and study.cursor==6 and study.held==kept and is_equal_approx(study.reading.frames[2].length,.92))
	for i in 20:study.step()
	check("Repeated STEP stops at final frame",study.cursor==11 and study.snapshot().frame.stack_depth==0 and study.snapshot().frame.pos.is_equal_approx(Vector3.UP*2.4))
	key(study,KEY_T)
	check("TREE2 makes61 symbols25 segments with7.2m trunk",study.generation==2 and study.sentence.length()==61 and study.reading.ends.size()==50 and study.snapshot().frame.pos.is_equal_approx(Vector3.UP*7.2))
	var nested:Array=study.reading.frames.filter(func(f):return f.depth==2)
	check("Nested branch compounds ratio and angle",not nested.is_empty() and is_equal_approx(nested[0].length,1.058) and is_equal_approx(nested[0].angle,36.1))
	check("Drawing has one finite cylinder per segment without fitting",study.drawing.get_child_count()==29 and study.drawing.get_children().all(func(n):return n.transform.is_finite()) and is_equal_approx(study.drawing.get_child(0).mesh.height,.8))
	check("Extra closing bracket rejected before geometry",not model.read("F]F",.72).accepted and not model.read("F]F",.72).has("ends"))
	check("Unclosed branch rejected before geometry",not model.read("F[+F",.72).accepted and not model.read("F[+F",.72).has("ends"))
	check("Empty and non-drawing sentences stay valid",model.read("",.72).frames.size()==1 and model.read("X",.72).ends.is_empty())
	check("Lowercase f moves without drawing; G draws",model.read("fG",.72).ends[0].is_equal_approx(Vector3.UP*.8) and model.read("fG",.72).ends.size()==2)
	# All valid states and raw endpoints compared to the existing generator.
	var source=load("res://commons/artifacts/parametric_lsystem/parametric_lsystem.gd").new();root.add_child(source)
	source.lesson_enabled=true;source.angle_variation=0;source.base_angle=40;source.base_length=.8
	var comparisons:=0;var agree:=true;var frame_count:=0
	for ratio in [.45,.72,1.0,1.15]:
		for generation in [1,2]:
			source.length_decay=ratio;source.iterations=generation;source._generate()
			var expected:Dictionary=model.read(source._current_string,ratio)
			var ends:Array=[]
			for segment in source.tree_segments:ends.append(segment[0]);ends.append(segment[1])
			agree=agree and close(ends,expected.ends) and source.trace_frames.size()==expected.frames.size()
			for i in source.trace_frames.size():
				var a:Dictionary=source.trace_frames[i];var b:Dictionary=expected.frames[i]
				agree=agree and a.pos.is_equal_approx(b.pos) and a.dir.is_equal_approx(b.heading) and is_equal_approx(a.length,b.length) and is_equal_approx(a.angle,b.angle) and a.depth==b.depth and a.stack_depth==b.stack_depth and a.segments==b.segments and a.symbol==b.symbol
				frame_count+=1
			comparisons+=1
	check("Eight ratio-generation readings match production states and raw endpoints",agree and comparisons==8)
	source.queue_free()
	var variant=load(DIR+"variation/growth.gd").new();host.add_child(variant)
	var v:Dictionary=variant.reading
	check("Actual edited program adds nested branch with five segments",variant.sentence=="F[+F[-F]F]F" and v.ends.size()==10 and v.frames[-1].pos.is_equal_approx(Vector3.UP*1.6))
	check("Inner return restores outer branch; outer return restores trunk",v.frames[8].pos.is_equal_approx(v.frames[4].pos) and v.frames[8].heading.is_equal_approx(v.frames[4].heading) and is_equal_approx(v.frames[8].length,.576) and v.frames[8].stack_depth==1 and v.frames[10].heading.is_equal_approx(Vector3.UP) and is_equal_approx(v.frames[10].length,.8))
	var shared=load(DIR+"mutations/shared_state.gd").new().read(variant.sentence,.72)
	var fifo=load(DIR+"mutations/first_saved.gd").new().read(variant.sentence,.72)
	check("Exercise detects aliasing instead of a state copy",not close(shared.ends,v.ends))
	check("Exercise detects oldest-first instead of last-first restore",not close(fifo.ends,v.ends))
	# Supplied poses exercise actual XRTools; no physical headset claim.
	key(study,KEY_R);await settle()
	check("RESET restores first line and its independent held copy",study.generation==1 and study.cursor==1 and study.held.cursor==1 and is_equal_approx(study.ratio,.72))
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle()
	controller.global_position=study.to_global(Vector3(.525,1.18,2.55));await settle()
	check("XR held point selects1.15 in rotated translated study",study.point.is_picked_up() and is_equal_approx(study.ratio,1.15) and study.cursor==1)
	study.point.action();await settle()
	check("Held action advances exactly one recorded symbol",study.cursor==2 and study.snapshot().frame.symbol=="[" and study.generation==1)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks point without advancing reading",not study.point.held() and study.point.position.is_equal_approx(Vector3(.525,1.18,2.55)) and study.cursor==2)
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"production_comparisons":comparisons,"production_frames":frame_count,"scope":"Author-led exact printed reconstruction and edited nested rule; native XRTools supplied poses, not independent student or headset."},"  "))
	quit(0 if failures.is_empty() else 1)
