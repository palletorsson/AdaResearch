extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-08-ca-two-ways-to-make/"
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(label:String,ok:bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("CA COMPARISON ",label," ",ok)
func frames(n:int=3) -> void:
	for i in n:await physics_frame
func row_with(sites:Array) -> Array[bool]:
	var row:Array[bool]=[];row.resize(32);row.fill(false)
	for i in sites:row[posmod(i,32)]=true
	return row
func occupied(row:Array) -> Array:
	var sites:Array=[]
	for i in row.size():
		if row[i]:sites.append(i)
	return sites
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var methods=load(OUT+"printed/procedures.gd").new()
	var production=load("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd").new();production.cells_x=32;production.rows_visible=24;production.rule=90
	var truth:=true
	for l in [false,true]:
		for c in [false,true]:
			for r in [false,true]:
				var row:Array[bool]=row_with([]);row[14]=l;row[15]=c;row[16]=r
				truth=truth and methods.next_row(row)[15]==production._apply_rule(l,c,r)
	check("Boolean inequality matches all eight installed Rule90 cases",truth)
	var row:=row_with([16]);var original:=row.duplicate();var next:Array[bool]=methods.next_row(row)
	check("Single seed yields two separated neighbours and preserves old row",occupied(next)==[15,17] and row==original and not is_same(row,next))
	check("Periodic edge gives neighbours 31 and 1",occupied(methods.next_row(row_with([0])))==[1,31])
	check("Three alternate seeds cancel shared neighbours",occupied(methods.next_row(row_with([14,16,18])))==[13,19])
	var rng:=RandomNumberGenerator.new();rng.seed=81008;var parity:=true
	for trial in 10:
		row=row_with([])
		for i in 32:row[i]=rng.randf()<.4
		production._current_row=row.duplicate();production._grid.clear();production._grid.append(row.duplicate());production.generation=0
		for i in 24:
			row=methods.next_row(row);production._advance();parity=parity and row==production._current_row
	check("240 mixed-start updates match the general installed evaluator",parity);production.free()
	row=row_with([16]);var before_finite:Array[bool]
	for gen in 16:
		if gen==15:before_finite=row.duplicate()
		row=methods.next_row(row)
	check("Single-seed generation15 has sixteen cells; generation16 is empty",before_finite.count(true)==16 and row.count(true)==0)
	check("An empty row stays empty",methods.next_row(row)==row)
	var recurse=load("res://tools/probes/ca_pyramid_positions.gd").new();var recipes:=true;var counts:=true
	for depth in 5:
		recurse.recorded.clear();recurse.leaf_count=0;recurse._recursive_build(Vector3.ZERO,pow(2,depth-1),depth)
		var points:Array[Vector3]=methods.copy_positions(Vector3.ZERO,pow(2,depth-1),depth)
		recipes=recipes and points==recurse.recorded;counts=counts and points.size()==int(pow(6,depth))
	check("Depth0 through4 positions exactly match production recursion",recipes)
	check("Recipe returns one entry per leaf call: six to each depth",counts)
	var one:Array[Vector3]=methods.copy_positions(Vector3.ZERO,1.0,1)
	check("One copy level includes extra crown and four lower corners",one.size()==6 and one[0]==Vector3(0,.5,0) and one[1]==Vector3(0,.25,0) and one[2]==Vector3(-.25,-.25,-.25))
	recurse.free()
	var or_fault=load(OUT+"variants/or-fault/procedures.gd").new()
	check("Replacing XOR with OR fails shared-neighbour cancellation",occupied(or_fault.next_row(row_with([14,16,18])))!=[13,19])
	var scan=load(OUT+"variants/in-place/procedures.gd").new()
	check("Writing into old row fails single-seed answer",occupied(scan.next_row(row_with([16])))!=[15,17])
	var study=load(OUT+"printed/comparison.gd").new();world.add_child(study);await frames()
	check("Complete printed construction has history, point, readout and216 cube instances",study.history.size()==1 and study.copies.instance_count==216 and study.point!=null and study.reading.text.contains("GEN 0"))
	var transforms:Array=[]
	for i in study.copies.instance_count:transforms.append(study.copies.get_instance_transform(i))
	study.step();study.step()
	check("Every stored row remains its own answer",occupied(study.history[0])==[16] and occupied(study.history[1])==[15,17] and occupied(study.history[2])==[14,18])
	var displayed:=true
	for y in 24:
		for x in 32:
			var xf:Transform3D=study.cells.get_instance_transform(y*32+x)
			if y<study.history.size():displayed=displayed and xf.basis.is_equal_approx(Basis.IDENTITY) and xf.origin.is_equal_approx(study.at(x,y))
			else:displayed=displayed and is_zero_approx(xf.basis.determinant())
	check("Recorded rows occupy fixed places; future rows have zero scale",displayed)
	check("Spatial columns and temporal rows have distinct axes",is_equal_approx(study.at(17,0).x-study.at(16,0).x,.05) and is_equal_approx(study.at(16,1).z-study.at(16,0).z,-.05))
	var space=world.get_world_3d().direct_space_state;var support:=true
	for col in [15,16]:
		var at:Vector3=study.at(col,0);var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*.2,1));support=support and not hit.is_empty() and is_equal_approx(hit.position.y,1.0)
	check("Native table supports both occupied and empty drawn cells",support)
	study.change_seed();study.step()
	check("Changing seed resets history and builds the adjacent-pair answer",study.seed_sites==[16,17] and study.history.size()==2 and occupied(study.history[1])==[15,16,17,18])
	var untouched:=true
	for i in transforms.size():untouched=untouched and study.copies.get_instance_transform(i)==transforms[i]
	check("Seed and clock operations leave every cube transform untouched",untouched)
	var transfer=load(OUT+"variants/three-seeds/comparison.gd").new();world.add_child(transfer);transfer.step()
	check("Printed independent seed edit yields only13 and19 withsame216positions",occupied(transfer.history[1])==[13,19] and transfer.positions==study.positions)
	transfer.reset();check("Replay retains the student's edited seed",occupied(transfer.history[0])==[14,16,18]);transfer.queue_free();await frames()
	study.seed_sites.assign([16]);study.reset();study.position=Vector3(3,0,-2);study.rotation.y=.7
	var origin:=XROrigin3D.new();world.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await frames()
	controller.global_position=study.to_global(Vector3(-1.15+(15-15.5)*.05,1.2,.85));await frames(6)
	check("Held world position selects local address15 in rotated study",study.point.held() and study.selected==15)
	check("Inspection predicts next1 without editing seed or time",study.history.size()==1 and occupied(study.history[0])==[16] and study.reading.text.contains("NEXT 1"))
	study.point.action();await frames();check("Held trigger appends exactly one Rule90 generation",study.history.size()==2 and occupied(study.history[1])==[15,17])
	controller.global_position=study.to_global(Vector3(5,1.2,.85));await frames(6);check("Inspector clamps beyond rail to last address",study.selected==31)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await frames()
	check("Release parks at selected address without stepping",not study.point.held() and study.history.size()==2 and study.point.position.is_equal_approx(Vector3(-1.15+(31-15.5)*.05,1.15,.85)))
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER;study._unhandled_key_input(key);key.echo=true;study._unhandled_key_input(key)
	check("Enter steps once and ignores key repeat",study.history.size()==3)
	key.echo=false;key.keycode=KEY_C;study._unhandled_key_input(key);key.keycode=KEY_R;study._unhandled_key_input(key)
	check("C chooses pair; R retains it while replaying",study.history.size()==1 and study.seed_sites==[16,17])
	for i in 30:study.step()
	check("Learner display holds at24rows without losing beginning",study.history.size()==24 and occupied(study.history[0])==[16,17])
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed scripts; allRule90cases,240mixedupdates; actualpyramidrecursionrecorded atdepth0..4; nativegeometry/collision; suppliedXRToolspose; independentseededit andtwofaults. No physical headset or independent student."},"  "))
	world.queue_free();await frames();quit(0 if failures.is_empty() else 1)
