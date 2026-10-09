extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading/"
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("GRAMMAR ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame
func fitted(ends: Array[Vector3]) -> Array[Vector3]:
	if ends.is_empty():return []
	var low:=ends[0];var high:=ends[0]
	for p in ends:low=low.min(p);high=high.max(p)
	var s:=2.72/maxf((high-low).x,(high-low).y)
	var anchor:=Vector3((low.x+high.x)*.5,low.y,0)
	var output:Array[Vector3]=[]
	for p in ends:output.append((p-anchor)*s)
	return output
func close(a:Array,b:Array) -> bool:
	if a.size()!=b.size():return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):return false
	return true
func key(study:Node, code:int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	study._unhandled_key_input(event)
func run() -> void:
	var host:=Node3D.new();host.position=Vector3(4,0,-2);host.rotation.y=.65;root.add_child(host)
	var study=load(DIR+"printed/sentence.gd").new();host.add_child(study);await settle()
	var model=study.model
	check("Printed complete program constructs both lines and carried point",study.drawing.get_child_count()==2 and study.point is XRToolsPickable and study.held.text=="F")
	check("Simultaneous pass reads only old F",model.rewrite("F",study.CURVE).text=="F+F-F-F+F")
	check("Unmatched symbols pass through and inputs stay unchanged",model.rewrite("XF?",{"F":"FF"}).text=="XFF?" and study.CURVE=={"F":"F+F-F-F+F"})
	check("Different rules act on old AB together",model.rewrite("AB",{"A":"B","B":"AA"}).text=="BAA")
	check("An explicit empty production erases its symbol",model.rewrite("AFX",{"F":""}).text=="AX")
	check("Empty sentence stays valid and draws nothing",model.rewrite("",study.CURVE).accepted and model.read("",90).is_empty())
	check("Undrawn X is still rewritten",model.read("X",90).is_empty() and model.rewrite("X",{"X":"F"}).text=="F")
	check("Budget permits exactly4096 symbols",model.rewrite("F".repeat(2048),{"F":"FF"}).text.length()==4096)
	var refused:Dictionary=model.rewrite("F".repeat(2049),{"F":"FF"})
	check("Budget rejects whole generation retaining original",not refused.accepted and refused.text=="F".repeat(2049))
	for n in 5:
		check("Generation%d count and retained signs"%n,study.sentence.count("F")==int(pow(5,n)) and study.sentence.length()==2*int(pow(5,n))-1 and study.model.read(study.sentence,90).size()==2*int(pow(5,n)))
		study.advance()
	var at_cap:String=study.sentence;study.advance()
	check("Four generation cap holds data and counter",study.generation==4 and study.sentence==at_cap)
	study.reset_live();study.advance();study.keep()
	var kept:Dictionary=study.held.duplicate(true);var old_ends:Array=model.read(study.sentence,90)
	study.choose(3)
	check("Turn changes endpoints without changing sentence or held reading",study.angle==120 and study.sentence==kept.text and study.held==kept and not close(old_ends,model.read(study.sentence,120)))
	check("Both visual views reconstruct five finite cylinders",study.drawing.get_child_count()==10 and study.drawing.get_children().all(func(n):return n.transform.is_finite() and n.mesh.height>0))
	study.advance();check("Next can change live while held remains",study.sentence.length()==49 and study.held==kept)
	study.reset_live();check("Reset restarts live while retaining angle and kept reading",study.sentence=="F" and study.angle==120 and study.held==kept)
	key(study,KEY_C);for i in 3:study.advance()
	var ends:Array=model.read(study.sentence,90)
	check("Cantor three generations27 advances8 intervals",study.generation==3 and study.sentence.length()==27 and ends.size()==16)
	var expected:=[0,1,2,3,6,7,8,9,18,19,20,21,24,25,26,27]
	var exact:=true
	for i in expected.size():exact=exact and ends[i].is_equal_approx(Vector3.UP*expected[i])
	check("Cantor addresses match the previous thirds construction",exact)
	check("No turn commands makes the angle idle",close(ends,model.read(study.sentence,120)))
	key(study,KEY_H);check("H stores current sentence and reading",study.held.text==study.sentence and study.held.angle==study.angle)
	key(study,KEY_ENTER);check("Enter adds one Cantor generation",study.generation==4 and study.sentence.length()==81 and model.read(study.sentence,120).size()==32)
	# Compare normalized output to the existing museum generator, not to copied geometry.
	var editor=load("res://commons/artifacts/lsystem_editor/lsystem_editor.gd").new()
	editor._create_display();editor._create_labels();editor._built=true;editor.display_size=3.4
	root.add_child(editor);editor.set_process(false)
	var comparisons:=0;var agree:=true
	for r in [study.CURVE,study.CANTOR]:
		var sentence:="F"
		for depth in 5:
			for angle in [30.0,60.0,90.0,120.0]:
				editor.set_rules("F",r,angle,depth)
				agree=agree and editor.get_string()==sentence and close(fitted(model.read(sentence,angle)),editor.fitted_lines)
				comparisons+=1
			sentence=model.rewrite(sentence,r).text
	check("Forty rule-depth-angle readings match production endpoints after fitting",agree and comparisons==40)
	editor.queue_free()
	var variant=load(DIR+"variation/sentence.gd").new();host.add_child(variant)
	variant.advance();variant.advance()
	var square:Array=variant.model.read(variant.sentence,90)
	check("Independent printed edit FplusF makes four sides",variant.sentence=="F+F+F+F" and square.size()==8 and square[-1].is_equal_approx(Vector3.ZERO))
	check("Same altered sentence need not close at120",not variant.model.read(variant.sentence,120)[-1].is_equal_approx(Vector3.ZERO))
	# Actual XRTools pickup with supplied poses: no human headset claim.
	key(study,KEY_C);study.choose(2);await settle()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle()
	controller.global_position=study.to_global(Vector3(.525,1.15,.55));await settle()
	check("XR hand chooses120 in rotated translated study",study.point.is_picked_up() and study.angle==120 and study.generation==0)
	study.point.action();await settle()
	check("Actual held action rewrites once",study.generation==1 and study.sentence.length()==9)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks point and keeps sentence",not study.point.held() and study.point.position.is_equal_approx(Vector3(.525,1.15,.55)) and study.generation==1)
	study.generation=0;study.sentence="F".repeat(2049);study.rules={"F":"FF"};study.advance()
	check("Rejected construction preserves generation and names limit",study.limited and study.generation==0 and study.title.text.contains("previous complete"))
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"production_comparisons":comparisons,"scope":"Author-led native reconstruction of exact printed files; artificial XR poses, no headset or independent student."},"  "))
	quit(0 if failures.is_empty() else 1)
