extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-competition-the-next-turn/"
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(title:String,ok:bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("COMPETITION ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	for i in 3:await physics_frame
	await process_frame
func total(field:Array) -> float:
	var s:=0.0
	for row in field:
		for v in row:s+=v
	return s
func equal(a:Array,b:Array) -> bool:
	if a.size()!=b.size():return false
	for z in a.size():
		for x in a[z].size():
			if not is_equal_approx(a[z][x],b[z][x]):return false
	return true
func key(study:Node,code:int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;study._unhandled_key_input(event)
func run() -> void:
	var host:=Node3D.new();host.position=Vector3(4,0,-2);host.rotation.y=.65;root.add_child(host)
	var study=load(DIR+"printed/competition.gd").new();host.add_child(study);await settle()
	check("Printed program creates two stems,400 soil cells,readout and inherited point",study.trees.size()==2 and study.trees[0].sentence=="F" and study.soil.cells.size()==20 and is_equal_approx(total(study.soil.cells),240) and study.point.has_method("pick_up") and study.drawing.get_child_count()==15)
	study.soil.cells[0][0]=.123
	check("Rows have independent storage",is_equal_approx(study.soil.cells[1][0],.6));study.reset()
	var a:Array=study.soil.patch(study.Soil.ROOTS[0]);var b:Array=study.soil.patch(study.Soil.ROOTS[1]);var shared:=0
	for p in a:
		if p in b:shared+=1
	check("Initial25-cell squares overlap at20 addresses",a.size()==25 and b.size()==25 and shared==20)
	check("Patch clips safely at corner and far outside",study.soil.patch(Vector2i.ZERO).size()==9 and study.soil.patch(Vector2i(-10,-10)).is_empty())
	key(study,KEY_ENTER)
	check("First key turn receives2.25 and changes only selected sentence",is_equal_approx(study.trees[0].last,2.25) and study.trees[0].sentence==study.RULE.F and study.trees[1].sentence=="F" and study.next==1)
	var first:Dictionary=study.history[0].duplicate(true)
	key(study,KEY_ENTER)
	check("Second reads depleted cells and receives1.98",is_equal_approx(study.trees[1].last,1.98) and study.next==0 and study.trees[1].generation==1)
	check("Before and after records retain independent field snapshots",study.history[0]==first and is_equal_approx(total(first.before),240) and is_equal_approx(total(first.after),237.75) and equal(study.history[1].before,first.after))
	check("Shared-state accounting balances",is_equal_approx(total(study.soil.cells)+study.trees[0].total+study.trees[1].total,240))
	var opening_pair:Array=study.soil.cells.duplicate(true)
	key(study,KEY_O)
	check("ORDER restores fresh stems soil history and flips first",study.first==1 and study.next==1 and study.history.is_empty() and is_equal_approx(total(study.soil.cells),240) and study.trees.all(func(t):return t.generation==0))
	study.attempt();study.attempt()
	check("Reverse order swaps allocation while completed-pair field agrees",is_equal_approx(study.trees[1].last,2.25) and is_equal_approx(study.trees[0].last,1.98) and equal(opening_pair,study.soil.cells))
	key(study,KEY_W);study.attempt();study.attempt()
	check("Winter retains order,consumes4.23 and refuses both rewrites",study.winter and study.first==1 and study.trees.all(func(t):return t.sentence=="F" and t.generation==0) and is_equal_approx(total(study.soil.cells),235.77))
	study.redraw();await settle()
	check("Drawing and waiting take no extra resource turn",study.history.size()==2 and is_equal_approx(total(study.soil.cells),235.77))
	study.act("RESET")
	for i in 6:study.attempt()
	check("Six spring attempts give both sentences125F and three generations",study.trees.all(func(t):return t.generation==3 and t.sentence.count("F")==125))
	var end:Array=study.soil.cells.duplicate(true);study.attempt();study.attempt()
	check("Generation cap refuses before consuming;no false final uptake",equal(end,study.soil.cells) and study.trees.all(func(t):return t.last==0) and study.history[-1].reason=="generation limit")
	var fixed:=true;var rods:=0
	for n in study.drawing.get_children():
		if n.get_script()!=null and n.get_script().resource_path.ends_with("line_skin.gd"):
			fixed=fixed and n.transform.is_finite();rods+=1
	check("Final drawings finite with250 branches and10 field marks",fixed and rods==260)
	study.act("RESET")
	for row in study.soil.cells:row.fill(0.0)
	study.attempt()
	check("Empty patch records zero,advances turn and keeps sentence",study.trees[0].generation==0 and study.history[-1].uptake==0 and study.history[-1].reason=="uptake too small" and study.next==1)
	for i in 82:study.attempt()
	check("History bounded to80 attempts without losing alternation",study.history.size()==80 and study.next==1)
	study.act("RESET");study.act("SEASON");study.act("ORDER")
	check("ORDER retains winter; RESET restores spring A first",study.winter and study.first==1);study.act("RESET")
	check("RESET clears record and returns supplied starting conditions",not study.winter and study.first==0 and study.history.is_empty())
	var source=load("res://algorithms/lsystems/Ecosystem/ForestCompetition.gd").new();source.simulation_model=true;root.add_child(source)
	var comparisons:=0;var match_source:=true
	for winter in [false,true]:
		for first_index in [0,1]:
			source.reset_lesson_pair(first_index,winter);study.winter=winter;study.first=first_index;study.reset()
			for i in 2:
				source._grow_step();study.attempt()
				var event:Dictionary=source.last_growth_event;var ours:Dictionary=study.history[-1]
				match_source=match_source and event.tree==ours.tree and is_equal_approx(event.uptake,ours.uptake) and event.generation_after==ours.generation_after and equal(source._nutrient_grid,study.soil.cells)
				match_source=match_source and source._trees[event.tree].lsystem.get_sentence()==study.trees[event.tree].sentence
				comparisons+=1
	check("Eight first-round events match actual forest in both orders and seasons",match_source and comparisons==8)
	source.reset_lesson_pair(0,false);study.act("RESET")
	for i in 3:source._grow_step();study.attempt()
	check("Later fixed-area study intentionally diverges from expanding forest patch",not is_equal_approx(source.last_growth_event.uptake,study.history[-1].uptake))
	var variant=load(DIR+"variation/competition.gd").new();host.add_child(variant);variant.attempt();variant.attempt()
	check("Actual edited root program gives2.25 to both disjoint patches",variant.Soil.ROOTS[1]==Vector2i(14,10) and variant.trees.all(func(t):return is_equal_approx(t.last,2.25)) and is_equal_approx(total(variant.soil.cells),235.5))
	variant.act("ORDER");variant.attempt();variant.attempt()
	check("Edited program keeps equal first-round allocation under reversed order",variant.trees.all(func(t):return is_equal_approx(t.last,2.25)))
	var alias=load(DIR+"alias/competition.gd").new();host.add_child(alias);alias.attempt()
	check("Test rejects aliased before-state snapshot",not is_equal_approx(total(alias.history[0].before),240))
	var wrong=load(DIR+"winter_first/competition.gd").new();host.add_child(wrong);wrong.act("SEASON");wrong.attempt()
	check("Test rejects winter gate placed before consumption",not is_equal_approx(wrong.history[0].uptake,2.25))
	study.act("RESET");await settle()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle()
	controller.global_position+=Vector3(.2,.1,-.1);await settle()
	check("Moving held point takes no turn",study.point.is_picked_up() and study.history.is_empty())
	study.point.action();await settle()
	check("Actual XRTools trigger takes exactly one turn in rotated host",study.history.size()==1 and is_equal_approx(study.trees[0].last,2.25))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks familiar point without another attempt",study.point.position.is_equal_approx(Vector3(0,1.2,2.3)) and study.history.size()==1)
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"production_comparisons":comparisons,"scope":"Author-led exact printed reconstruction, executed root edit and two faulty models; native XRTools supplied poses, not independent student or physical headset."},"  "))
	quit(0 if failures.is_empty() else 1)
