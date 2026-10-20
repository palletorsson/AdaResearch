extends SceneTree
const DIR:="res://doc/book/iterations/2026-10-09-living-a-design-kept/"
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(title:String,ok:bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("LIVING ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	for i in 3:await physics_frame
	await process_frame
func same(a:Array,b:Array) -> bool:
	if a.size()!=b.size():return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):return false
	return true
func key(study:Node,code:int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;study._unhandled_key_input(event)
func run() -> void:
	var host:=Node3D.new();host.position=Vector3(5,0,-2);host.rotation.y=.7;root.add_child(host)
	var study=load(DIR+"printed/living.gd").new();host.add_child(study);await settle()
	check("Printed script creates opening body point and readout",study.preview.accepted and study.preview.parameters.generations==2 and study.preview.requested==8 and study.point.has_method("pick_up") and study.held.is_empty() and study.planted.is_empty())
	key(study,KEY_H);var original:Dictionary=study.preview.duplicate(true)
	var unchanged:=true
	for i in 4:
		key(study,KEY_RIGHT);unchanged=unchanged and same(original.ends,study.preview.ends) and study.preview.sentence==original.sentence
	check("Four depth edits reach4.8 with unchanged sentence and endpoints",unchanged and is_equal_approx(study.editing.depth,4.8))
	key(study,KEY_RIGHT)
	check("Fifth edit crosses rounding boundary to three generations",is_equal_approx(study.editing.depth,5) and study.preview.parameters.generations==3 and study.preview.requested==22 and not same(original.ends,study.preview.ends))
	check("Held recipe and its rebuilt geometry stay independent",study.held.depth==4 and same(study.model.build(study.held).ends,original.ends))
	key(study,KEY_P);var planted:Dictionary=study.planted.duplicate(true)
	key(study,KEY_G);key(study,KEY_G);var sentence:String=study.preview.sentence;var ends:Array=study.preview.ends.duplicate();key(study,KEY_RIGHT)
	check("Angle edit changes endpoints without changing sentence",study.preview.sentence==sentence and not same(ends,study.preview.ends) and study.preview.parameters.generations==3)
	check("Plant keeps its recipe through a later edit",study.planted==planted and study.editing!=planted)
	key(study,KEY_R)
	check("Reset editing preserves held and planted recipes",study.editing==study.START and study.held.depth==4 and study.planted==planted)
	key(study,KEY_P)
	check("Plant replaces only its own slot",study.planted==study.START and study.held.depth==4)
	study.set_normalized(-2);check("Input clamp enforces low raw depth",study.editing.depth==2)
	study.set_normalized(3);check("Input clamp enforces high raw depth",study.editing.depth==10)
	var bounds:Dictionary=study.model.parameters({"depth":-20.0,"forks":100.0,"angle":200.0})
	check("Compiled counts and angle remain bounded",bounds.generations==2 and bounds.forks==5 and bounds.angle==90)
	var agree:=true;var comparisons:=0
	for depth in [2.0,4.0,4.8,5.0,7.0,10.0]:
		for forks in [1.0,2.0,2.49,2.5,5.0,8.0]:
			for angle in [15.0,30.0,90.0]:
				var dna:=CritterDNA.new();dna.segments=depth;dna.symmetry=forks;dna.branch_angle=angle;dna.phyllotaxis=.5
				var params:=TreeMorphology._dna_to_lsystem_params(dna);var source:=TreeMorphology._create_lsystem_from_dna(dna,params)
				var ours:Dictionary=study.model.build({"depth":depth,"forks":forks,"angle":angle})
				agree=agree and ours.accepted and ours.parameters.generations==params.generations and ours.parameters.forks==params.fork_count and ours.parameters.angle==params.angle_deg and ours.sentence==source.get_sentence();comparisons+=1
	check("108 settings match source counts angles and complete sentences",agree and comparisons==108)
	var big:Dictionary=study.model.build({"depth":10.0,"forks":8.0,"angle":30.0})
	check("Max design requests4964 commands but reads only200",big.requested==4964 and big.drawn_commands==200 and big.ends.size()<=400)
	check("Known rewrite stays parallel and refuses whole oversized result",study.model.rewrite("AB",{"A":"B","B":"AA"}).text=="BAA" and not study.model.rewrite("F".repeat(16385),{"F":"FF"}).accepted)
	var short:Dictionary=study.model.read("SF",30)
	check("S uses.72m then F1.2m before taper",short.ends[1].is_equal_approx(Vector3(0,.72,0)) and short.ends[3].is_equal_approx(Vector3(0,1.92,0)))
	var branch:Dictionary=study.model.read("F[+F]F",90)
	check("Bracket restores position frame and current length",branch.ends[3].is_equal_approx(Vector3(.816,1.2,0)) and branch.ends[4].is_equal_approx(Vector3(0,1.2,0)) and branch.ends[5].is_equal_approx(Vector3(0,2.016,0)))
	var rolled:Dictionary=study.model.read("/+F",90)
	check("Roll makes the next turn leave the original plane",rolled.ends[1].is_equal_approx(Vector3(0,0,1.2)))
	var variant=load(DIR+"variation/living.gd").new();host.add_child(variant)
	check("Full student-edited45degree program keeps sentence but changes geometry",variant.editing.angle==45 and variant.preview.sentence==original.sentence and not same(variant.preview.ends,original.ends))
	variant.keep("held");var kept:Array=variant.preview.ends.duplicate();variant.selected=2;variant.set_normalized(1)
	check("Edited study reconstructs kept body after changing angle",same(variant.model.build(variant.held).ends,kept) and not same(variant.preview.ends,kept))
	var alias=load(DIR+"alias/living.gd").new();host.add_child(alias);alias.keep("held");alias.set_normalized(.375)
	check("Test rejects reference in place of snapshot",alias.held.depth!=4)
	var wrong=load(DIR+"wrong_round/design.gd").new()
	check("Test rejects flooring at the5.0 threshold",wrong.parameters({"depth":5.0,"forks":2.0,"angle":30.0}).generations!=3)
	key(study,KEY_R);await settle()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle()
	check("Pickup leaves raw design unchanged",study.editing==study.START and study.point.is_picked_up())
	controller.global_position=study.to_global(Vector3(-.1,1.18,2.55));await settle()
	check("Held motion selects raw5 on translated rotated host",is_equal_approx(study.editing.depth,5) and study.preview.parameters.generations==3)
	study.point.action();await settle()
	check("Held trigger keeps current design immediately",study.held==study.editing and study.held.depth==5)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks at selected value",not study.point.held() and study.point.position.is_equal_approx(Vector3(-.1,1.18,2.55)))
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"production_comparisons":comparisons,"scope":"Author-led exact printed reconstruction; actual edited program, two faulty programs, supplied XRTools poses. Not independent student or headset."},"  "))
	quit(0 if failures.is_empty() else 1)
