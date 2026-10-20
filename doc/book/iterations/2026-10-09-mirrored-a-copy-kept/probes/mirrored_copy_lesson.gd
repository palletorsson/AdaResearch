extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-mirrored-a-copy-kept/"
const Source = preload("res://algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirrored_cellular_automata.gd")
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
func settle()->void:
	await process_frame;await physics_frame;await process_frame
func oracle(field:Array,axes:bool)->Array:
	var n:=field.size();var out:Array=[]
	for y in n:
		var row:Array=[]
		for x in n:
			var cross:bool=n%2==1 and (x==n/2 or y==n/2)
			row.append(field[y][x] if cross and not axes else field[mini(y,n-1-y)][mini(x,n-1-x)])
		out.append(row)
	return out
func symmetric(field:Array)->bool:
	var n:=field.size()
	for y in n:
		for x in n:
			if field[y][x]!=field[y][n-1-x] or field[y][x]!=field[n-1-y][x]:return false
	return true
func ones(field:Array)->int:
	var count:=0
	for row in field:count+=row.count(1)
	return count
func run()->void:
	var G=load(DIR+"printed/reflection.gd");var V=load(DIR+"variation/reflection.gd");var m=G.new();var v=V.new();var source=Source.new()
	var matches:=true;var oracle_ok:=true;var unchanged:=true;var edit_ok:=true;var repeat_ok:=true;var comparisons:=0
	for n in [1,2,3,4,5,6,7,31]:
		for variant in 4:
			var field:Array=[]
			for y in n:
				var row:Array=[]
				for x in n:row.append(x+y*n if variant==0 else int((x*13+y*7+x*y+variant)%11<3))
				field.append(row)
			var witness:Array=field.duplicate(true);m.hold(field);m.reflect();source.grid_size=n;source.half_size=n/2;var expected:Array=field.duplicate(true);source.apply_quad_symmetry(expected)
			matches=matches and m.result==expected;comparisons+=1
			oracle_ok=oracle_ok and m.result==oracle(field,false)
			unchanged=unchanged and m.held==witness and field==witness
			var first:Array=m.result.duplicate(true);m.reflect();repeat_ok=repeat_ok and first==m.result
			v.hold(field);v.reflect();edit_ok=edit_ok and v.result==oracle(field,true) and symmetric(v.result) and v.held==witness
	check("32 complete fields match the production quadrant operation",matches)
	check("Every destination agrees with independent address oracle",oracle_ok)
	check("Both caller and held rows remain unchanged",unchanged)
	check("Repeated reflection is idempotent",repeat_ok)
	check("Edited rule includes axes and mirrors every address",edit_ok)
	source.free()
	var field:Array=[[1,0,1,0,0],[0,1,0,1,0],[0,1,1,0,1],[1,0,1,0,0],[0,1,0,0,1]]
	m.hold(field);field[0][0]=0;check("Holding deep-copies caller rows",m.held[0][0]==1)
	field[0][0]=1;m.hold(field);m.result[2][4]=0;check("Result edit cannot mutate held cross",m.held[2][4]==1)
	m.reflect();check("Reflect discards unheld result edit",m.result==oracle(field,false))
	check("Baseline cross is retained and not fully symmetric",m.result[2]==field[2] and not symmetric(m.result))
	check("Baseline has thirteen lit cells",ones(m.result)==13)
	var base:Array=m.result.duplicate(true);v.hold(field);v.reflect();var difference:=0
	for y in 5:
		for x in 5:if base[y][x]!=v.result[y][x]:difference+=1
	check("Axis edit changes exactly four cells but retains thirteen ones",difference==4 and ones(v.result)==13)
	check("Edited centre row and column match predictions",v.result[2]==[0,1,1,1,0] and [v.result[0][2],v.result[1][2],v.result[2][2],v.result[3][2],v.result[4][2]]==[1,0,1,0,1])
	m.result[2][4]=0;var held_edit:Array=m.result.duplicate(true);m.hold(m.result);m.reflect();check("Explicit hold commits a result as independent input",m.held==held_edit and m.result[2][4]==0)
	m.result[0][0]=0;check("A committed hold still has independent result rows",m.held[0][0]==1)
	m.original();check("Original view restores the current held input",m.result==m.held)
	var host:=Node3D.new();host.position=Vector3(4,0,-3);host.rotation.y=.6;root.add_child(host)
	var study=load(DIR+"printed/panels.gd").new();host.add_child(study);await settle()
	check("Complete host constructs fifty cells and inherited point",study.cells[0].size()==25 and study.cells[1].size()==25 and study.point.has_method("pick_up"))
	check("Host begins with two equal independent fields",study.model.held==field and study.model.result==field)
	study.act("REFLECT");var display_ok:=true
	for side in 2:
		for y in 5:
			for x in 5:
				var input:Array=study.model.held if side==0 else study.model.result;var axis:=2 if x==2 or y==2 else 0
				display_ok=display_ok and study.cells[side][y*5+x].material_override==study.finishes[axis+input[y][x]]
	check("Both displayed arrays match cell values and cross colours",display_ok)
	study.act("MARK");check("Mark edits only the right tip of result",study.model.result[2][4]==0 and study.model.held[2][4]==1)
	study.act("HOLD");study.act("REFLECT");check("Host HOLD makes mark persist",study.model.held[2][4]==0 and study.model.result[2][4]==0)
	study.act("RESET");check("Reset restores declared input",study.model.held==field and study.model.result==field)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();hand.global_position+=Vector3(.2,.1,0);await settle()
	check("Moving the held point does not reflect",study.point.is_picked_up() and study.model.result==field)
	study.point.action();await settle();check("Held action reflects while keeping input",study.model.result==base and study.model.held==field)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle();check("Release parks point in rotated host frame",study.point.position.is_equal_approx(Vector3(0,1.1,1.2)))
	var event:=InputEventKey.new();event.keycode=KEY_V;event.pressed=true;study._unhandled_key_input(event);check("Keyboard restores held input",study.model.result==field)
	var edited=load(DIR+"variation/panels.gd").new();host.add_child(edited);await settle();edited.act("REFLECT")
	check("Complete axis-edit program is symmetric with unchanged input",symmetric(edited.model.result) and edited.model.held==field and edited.model.result==oracle(field,true))
	for folder in ["wrong_alias","wrong_address","wrong_input"]:
		var bad=load(DIR+folder+"/panels.gd").new();host.add_child(bad);await settle();bad.act("MARK");bad.act("REFLECT")
		check("Reject complete faulty program "+folder,bad.model.held!=field or bad.model.result!=base)
		bad.queue_free();await settle()
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_comparisons":comparisons,"scope":"Exact printed three-file program, whole axis edit, independent oracle and faulty hosts; supplied XRTools poses, not physical headset."},"  "))
	origin.queue_free();host.queue_free();await settle();quit(0 if failures.is_empty() else 1)
