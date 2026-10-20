extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-curves-one-sentence-three-readers/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void:run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("CURVES ","PASS " if ok else "FAIL ",title)
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
	var study=load(DIR+"printed/readers.gd").new();host.add_child(study);await settle()
	var model=study.model
	check("Printed program creates point, labels and three initial drawings",study.point.has_method("pick_up") and study.captions.size()==3 and study.drawing.get_child_count()==12 and study.cursor==1)
	check("Parallel rewrite reads the previous sentence",model.rewrite("AB",{"A":"B","B":"AA"}).text=="BAA")
	check("Inherited whole-generation budget accepts4096 and refuses4098",model.rewrite("F".repeat(2048),{"F":"FF"}).accepted and not model.rewrite("F".repeat(2049),{"F":"FF"}).accepted)
	check("Generation1 has20 symbols8 segments and21 frames",study.sentence.length()==20 and study.readings[0].ends.size()==16 and study.readings[0].frames.size()==21)
	var saved:Dictionary=study.readings[0].duplicate(true);var sentence:String=study.sentence
	study.choose(2)
	check("Angle changes only middle interpretation, keeping sentence cursor and reference",study.angle==90 and study.cursor==1 and study.sentence==sentence and study.readings[0]==saved and study.readings[2]==saved and not close(study.readings[1].ends,saved.ends))
	key(study,KEY_SPACE)
	check("Blue first F moves right while its heading remains up",study.sideways and study.readings[2].frames[1].pos.is_equal_approx(Vector3.RIGHT*.32) and study.readings[2].frames[1].heading==Vector3.UP and study.readings[2].frames[1].direction==Vector3.RIGHT)
	var reflected:=true
	for i in saved.frames.size():
		var a:Dictionary=saved.frames[i];var b:Dictionary=study.readings[2].frames[i]
		reflected=reflected and b.pos.is_equal_approx(Vector3(a.pos.y,a.pos.x,0)) and b.heading.is_equal_approx(a.heading) and b.stack_depth==a.stack_depth and b.segments==a.segments
	check("Component exchange reflects complete path while retaining logical headings",reflected)
	var sample:=Vector3(.3,.8,0)
	check("Exchange preserves length and is its own inverse",is_equal_approx(model.direction(sample,true).length(),sample.length()) and model.direction(model.direction(sample,true),true)==sample)
	var turn:Dictionary=model.read("F+F",90,false)
	check("Plus follows source convention: up then left without drawing a turn",turn.frames[2].pos.is_equal_approx(Vector3.UP*.32) and turn.frames[2].segments==1 and turn.frames[3].pos.is_equal_approx(Vector3(-.32,.32,0)))
	var branch:Dictionary=model.read("F[+F[-F]F]F",90,false)
	check("Nested returns restore position and heading, preserving drawn branches",branch.ends.size()==10 and branch.frames[8].pos.is_equal_approx(branch.frames[4].pos) and branch.frames[8].heading.is_equal_approx(branch.frames[4].heading) and branch.frames[-1].pos.is_equal_approx(Vector3.UP*.64))
	check("Unbalanced branches are rejected before geometry",not model.read("F]F",25,false).accepted and not model.read("F[+F",25,false).accepted and not model.read("F]F",25,false).has("ends"))
	check("Empty input has START; this five-symbol reader leaves G f X undrawn",model.read("",25,false).frames.size()==1 and model.read("GfX",25,false).ends.is_empty())
	study.cursor=study.sentence.length();key(study,KEY_ENTER)
	check("STEP wraps complete reading to START with no drawn segments",study.cursor==0 and study.drawing.get_child_count()==9)
	key(study,KEY_T)
	check("TREE2 builds172 symbols64 segments per reader",study.generation==2 and study.sentence.length()==172 and study.readings[0].ends.size()==128 and study.cursor==172 and study.drawing.get_child_count()==201)
	var lengths:=true
	for reading in study.readings:
		for i in range(0,reading.ends.size(),2):lengths=lengths and is_equal_approx(reading.ends[i].distance_to(reading.ends[i+1]),.32)
	check("All readers retain actual0.32m strides, no fitting",lengths and study.drawing.get_children().all(func(n):return n.transform.is_finite()))
	var source=load("res://commons/artifacts/the_believing_turtle/the_believing_turtle.gd").new()
	var comparisons:=0;var frame_count:=0;var agree:=true
	for angle in [25.0,45.0,90.0]:
		for sideways in [false,true]:
			for generation in [1,2]:
				var text:String=source._rewrite("F",study.RULE.F,generation)
				var actual:Dictionary=source.interpret(text,angle,.32,sideways)
				var expected:Dictionary=model.read(text,angle,sideways)
				var ends:Array=[]
				for segment in actual.segments:ends.append(segment[0]);ends.append(segment[1])
				agree=agree and close(ends,expected.ends) and actual.frames.size()==expected.frames.size()
				for i in actual.frames.size():
					var a:Dictionary=actual.frames[i];var b:Dictionary=expected.frames[i]
					var heading:=Vector3(cos(a.heading),sin(a.heading),0)
					agree=agree and a.pos.is_equal_approx(b.pos) and heading.is_equal_approx(b.heading) and a.count==b.segments and a.stack==b.stack_depth and a.symbol==b.symbol
					frame_count+=1
				comparisons+=1
	check("Twelve source readings match every frame and raw segment endpoint",agree and comparisons==12)
	source.free()
	var variant=load(DIR+"variation/readers.gd").new();host.add_child(variant);variant.exchange()
	check("Actual student-edited program rotates first blue stride left",variant.sideways and variant.readings[2].frames[1].pos.is_equal_approx(Vector3.LEFT*.32))
	var rotated:=true
	for i in variant.readings[0].frames.size():
		var a:Dictionary=variant.readings[0].frames[i];var b:Dictionary=variant.readings[2].frames[i]
		rotated=rotated and b.pos.is_equal_approx(Vector3(-a.pos.y,a.pos.x,0)) and b.heading.is_equal_approx(a.heading) and b.segments==a.segments
	check("Student edit rotates whole path while sentence and logical heading stay intact",rotated and variant.sentence==sentence)
	var twice:Vector3=variant.model.direction(variant.model.direction(sample,true),true)
	check("Student rotation twice reverses; four times restores; reflection changes handedness",twice.is_equal_approx(-sample) and variant.model.direction(variant.model.direction(twice,true),true).is_equal_approx(sample) and model.direction(Vector3.RIGHT,true).cross(model.direction(Vector3.UP,true)).z<0 and variant.model.direction(Vector3.RIGHT,true).cross(variant.model.direction(Vector3.UP,true)).z>0)
	var wrong=load(DIR+"mutations/changed_heading.gd").new().read(sentence,25,true)
	check("Tests reject mutating heading when only drawing direction should change",not close(wrong.ends,model.read(sentence,25,true).ends) and not wrong.frames[1].heading.is_equal_approx(Vector3.UP))
	key(study,KEY_R);await settle()
	check("RESET restores initial shared reading",study.cursor==1 and study.generation==1 and study.angle==25 and not study.sideways and study.readings[0]==study.readings[2])
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle()
	controller.global_position=study.to_global(Vector3(.35,1.18,2.55));await settle()
	check("XR held point selects90 in rotated translated study",study.point.is_picked_up() and study.angle==90 and study.cursor==1)
	study.point.action();await settle()
	check("Held trigger changes blue readF only",study.sideways and study.cursor==1 and study.generation==1 and study.angle==90)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks same point at selected angle",not study.point.held() and study.point.position.is_equal_approx(Vector3(.35,1.18,2.55)))
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"production_comparisons":comparisons,"production_frames":frame_count,"scope":"Author-led printed reconstruction, actual student edit and mutation check; real XRTools with supplied poses, no physical headset or independent student."},"  "))
	quit(0 if failures.is_empty() else 1)
