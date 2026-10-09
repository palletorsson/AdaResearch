extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-a-state-that-lingers/"
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures.append(label)
	print("CA STATES ",label," ",ok)
func frames(n: int=3) -> void:
	for i in n: await physics_frame
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var study=load(OUT+"printed/volume.gd").new();world.add_child(study)
	await frames()
	var centre:=Vector3i(3,3,3);var c: int=study.index(centre)
	check("Exact printed files initialise label, point and 343 addresses",study.point!=null and study.reading.text.contains("GEN 0") and study.current.size()==343)
	check("Authored twelve-cell seed has eleven active neighbours",study.current.count(1)==12 and study.active_neighbours(study.current,centre)==11)
	var indices: Dictionary={}
	for z in 7:
		for y in 7:
			for x in 7: indices[study.index(Vector3i(x,y,z))]=true
	check("343 integer addresses map uniquely into array",indices.size()==343 and indices.has(0) and indices.has(342))
	var full: Array[int]=[];full.resize(343);full.fill(1)
	check("Full surrounding cube counts 26 rather than 27",study.active_neighbours(full,centre)==26)
	full[c]=0
	check("Centre's own state is excluded",study.active_neighbours(full,centre)==26)
	full.fill(2);full[c]=1
	check("Twenty-six visible fading neighbours contribute zero",study.active_neighbours(full,centre)==0)
	var table_ok:=true
	for state in 3:
		for count in 27:
			var expected:=0
			if state!=2:
				if [6,7,8].has(count): expected=1
				elif state==1: expected=2
			table_ok=table_ok and study.next_state(state,count)==expected
	check("All 81 transition-table entries match stated three-state rule",table_ok)
	check("Seven neighbours: empty births, fading empties",study.next_state(0,7)==1 and study.next_state(2,7)==0)
	var saved: Array=study.current.duplicate()
	var next: Array=study.evolve(study.current)
	check("Evolution leaves input intact and returns independent array",study.current==saved and not is_same(study.current,next))
	study.step();check("First update leaves a fading centre",study.current[c]==2 and study.generation==1)
	study.step();check("Second update empties centre",study.current[c]==0 and study.generation==2)
	study.current.fill(0);study.current[c]=1;study.current[c+1]=1;study.redraw()
	study.step();check("Independent adjacent-pair seed produces exactly two fading cells",study.current.count(2)==2 and study.current.count(1)==0)
	study.step();check("Adjacent pair then leaves whole volume empty",study.current.count(0)==343)
	var production=load("res://algorithms/cellularautomata/cellular_automata_3d/CellularAutomata3D_Flexible.gd").new()
	production.grid_size=Vector3i(7,7,7);production.paused=true;production.rule_string="6-8/6-8/3/M";production.center_seed_on_start=false
	world.add_child(production);production.set_process(false)
	check("Ordinary solver instance gains no study or hand control",production.get_node_or_null("StructureStudy")==null)
	var reverse=load(OUT+"variants/reverse/volume.gd").new();world.add_child(reverse)
	var count_fault=load(OUT+"variants/count-fading/volume.gd").new();world.add_child(count_fault)
	var birth_fault=load(OUT+"variants/rebirth-fading/volume.gd").new();world.add_child(birth_fault)
	check("Counter mutation is rejected",count_fault.active_neighbours(full,centre)!=study.active_neighbours(full,centre))
	check("Premature rebirth mutation is rejected",birth_fault.next_state(2,7)!=study.next_state(2,7))
	var parity:=true;var order_ok:=true;var edges_ok:=true
	var rng:=RandomNumberGenerator.new();rng.seed=8419
	for trial in 8:
		study.current.fill(0)
		for z in range(1,6):
			for y in range(1,6):
				for x in range(1,6): study.current[study.index(Vector3i(x,y,z))]=rng.randi_range(0,2)
		production.current_state=PackedByteArray(study.current);production.next_state.fill(0)
		reverse.current=study.current.duplicate()
		for step_number in 8:
			study.step();production._step();reverse.step()
			parity=parity and PackedByteArray(study.current)==production.current_state
			order_ok=order_ok and study.current==reverse.current
			for z in 7:
				for y in 7:
					for x in 7:
						if x==0 or y==0 or z==0 or x==6 or y==6 or z==6: edges_ok=edges_ok and study.current[study.index(Vector3i(x,y,z))]==0
	check("Eight deterministic mixed-state seeds across eight updates match installed solver",parity)
	check("Reverse traversal produces identical volumes",order_ok)
	check("Every outer face stays empty in all trials",edges_ok)
	study.reset();study.position=Vector3(3,0,-2);study.rotation.y=.9
	var origin:=XROrigin3D.new();world.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	controller.global_position=study.point.global_position;study.point.pick_up(hand);await frames()
	controller.global_position+=Vector3(.3,.2,-.2);await frames(6)
	check("Actual XRTools grab/movement does not edit or step cells",study.point.held() and study.current.count(1)==12 and study.generation==0)
	study.point.action();await frames()
	check("Pickable action advances exactly one generation",study.generation==1 and study.current[c]==2)
	study.point.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames()
	check("Release parks in rotated local frame without another update",not study.point.held() and study.point.position.is_equal_approx(Vector3(.8,1.05,.65)) and study.generation==1)
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER
	study._unhandled_key_input(key);key.echo=true;study._unhandled_key_input(key)
	check("Keyboard steps once and ignores repeat",study.generation==2)
	key.echo=false;key.keycode=KEY_R;study._unhandled_key_input(key)
	check("Keyboard replay restores seed and clock",study.generation==0 and study.current==saved)
	var states_saved: Array=study.current.duplicate();study.redraw()
	check("Drawing leaves state unchanged",study.current==states_saved)
	study.step()
	var visible_ok:=true;var colour_ok:=true
	for i in 343:
		var shown: Transform3D=study.cells.get_instance_transform(i)
		visible_ok=visible_ok and ((absf(shown.basis.determinant())>.5)==(study.current[i]>0))
		var expected: Color=study.COLOURS[study.current[i]];var actual: Color=study.cells.get_instance_color(i)
		colour_ok=colour_ok and absf(actual.r-expected.r)<.004 and absf(actual.g-expected.g)<.004 and absf(actual.b-expected.b)<.004
	check("Every occupied cell is drawn and empty cells are hidden",visible_ok)
	check("Stored state selects correct rendered colour",colour_ok)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed code, complete transition table, actual production solver parity, independent seed, reverse traversal, fault rejection and XRTools with supplied poses. No physical headset or human student."},"  "))
	world.queue_free();await frames()
	quit(0 if failures.is_empty() else 1)
