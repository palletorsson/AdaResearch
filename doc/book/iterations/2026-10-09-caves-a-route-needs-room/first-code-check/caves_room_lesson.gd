extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-caves-a-route-needs-room/"
const Source = preload("res://algorithms/proceduralgeneration/growth_systems/caverandomwalk/caverandomwalk.gd")
var checks:Array=[]
var failures:Array=[]
func _initialize()->void: run.call_deferred()
func check(title:String,ok:bool)->void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
func settle()->void:
	await process_frame;await physics_frame;await process_frame
func run()->void:
	var G=load(DIR+"printed/carver.gd")
	var m=G.new();m.reset()
	check("Reset supplies 196 solid bytes",m.solid.size()==196 and m.solid.count(1)==196 and m.history.is_empty())
	var addresses:Dictionary={}
	for y in 4:
		for z in 7:
			for x in 7:addresses[m.index(Vector3i(x,y,z))]=true
	check("Every volume address maps to a distinct valid slot",addresses.size()==196 and addresses.keys().min()==0 and addresses.keys().max()==195)
	check("Index strides are x1 z7 y49",m.index(Vector3i.RIGHT)==1 and m.index(Vector3i(0,0,1))==7 and m.index(Vector3i.UP)==49)
	m.carve(Vector3i(3,0,3))
	check("One interior centre clears five cells in two layers",m.air_count()==10)
	check("Footprint excludes diagonal corners",m.solid[m.index(Vector3i(4,0,4))]==1 and m.solid[m.index(Vector3i(4,1,3))]==0)
	check("Two layers leave the third layer solid",m.solid[m.index(Vector3i(3,2,3))]==1)
	var kept:PackedByteArray=m.solid.duplicate();m.carve(Vector3i(3,0,3))
	check("Repeat changes history but not carved volume",m.solid==kept and m.history.size()==2)
	m.reset();m.carve(Vector3i(3,0,6));check("Boundary clips footprint to eight cells",m.air_count()==8)
	m.reset();m.carve(Vector3i(3,3,3));check("Top boundary clips headroom to one layer",m.air_count()==5)
	m.reset();m.carve(Vector3i(-20,0,3));check("Distant outside centre records event without writing array",m.air_count()==0 and m.history.size()==1 and m.solid.size()==196)
	var source=Source.new();source.grid_size=G.SIZE
	var agreement:=true;var comparisons:=0
	var fixtures=[Vector3i(3,0,3),Vector3i(0,0,0),Vector3i(6,3,6),Vector3i(0,-1,3),Vector3i(-1,0,3),Vector3i(7,2,3)]
	for fixture in fixtures:
		m.reset();source._init_grid();source.carve_history.clear()
		for at in [fixture,fixture,fixture+Vector3i.RIGHT]:
			m.carve(at);source._carve_ball(at);comparisons+=1
			agreement=agreement and m.solid==source._solid and m.history==source.carve_history
	check("Eighteen source-kernel comparisons include repeats and clipping",agreement and comparisons==18)
	source.free()
	var host:=Node3D.new();host.position=Vector3(4,0,-3);host.rotation.y=.8;root.add_child(host)
	var study=load(DIR+"printed/cave.gd").new();host.add_child(study);await settle()
	check("Complete program creates solid display and inherited point",study.drawing.get_child_count()==196 and study.point is XRToolsPickable and study.caption.text.contains("0 / 9"))
	study.act("FINISH");await settle()
	var final_air:int=study.model.air_count();var record:Array=study.model.history.duplicate();var cells:PackedByteArray=study.model.solid.duplicate()
	check("Finish records all nine centres including repeated entry",record==Array(study.ROUTE) and record.size()==9 and record[2]==record[3] and study.cursor==9)
	var oracle_ok:=true
	for y in 4:
		for z in 7:
			for x in 7:
				var air:=false
				for c in study.ROUTE:air=air or (y>=c.y and y<c.y+2 and (x-c.x)*(x-c.x)+(z-c.z)*(z-c.z)<=1)
				oracle_ok=oracle_ok and (study.model.solid[study.model.index(Vector3i(x,y,z))]==0)==air
	check("Independent union-of-footprints oracle matches every cell",oracle_ok)
	check("Full display includes all remaining cubes and recorded marks",study.drawing.get_child_count()==196-final_air+9)
	var display_ok:=true
	for child in study.drawing.get_children():
		if child.mesh is BoxMesh:
			var addr:=Vector3i(((child.position-Vector3(0,.89,0))/.28).round())+Vector3i(3,0,3)
			display_ok=display_ok and study.model.inside(addr) and study.model.solid[study.model.index(addr)]==1 and child.mesh.size.is_equal_approx(Vector3.ONE*.28)
	check("Rendered cubes follow data addresses and edge size",display_ok)
	study.act("STEP");check("Finished route does not overrun",study.cursor==9 and study.model.history==record)
	study.act("CUT");await settle()
	check("Cutaway hides exactly upper-layer solids and preserves data",study.cutaway and study.model.solid==cells and study.model.history==record and study.drawing.get_child_count()==98-final_air+9)
	study.act("RESET");await settle();check("Reset refills volume and resets cursor without changing route",study.model.air_count()==0 and study.cursor==0 and study.model.history.is_empty() and Array(study.ROUTE)==record)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await settle();hand.global_position+=Vector3(.2,.1,0);await settle()
	check("Moving held point alone does not carve",study.point.is_picked_up() and study.cursor==0)
	study.point.action();await settle();check("Point action carves exactly one centre",study.cursor==1 and study.model.air_count()==8)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle();check("Release returns point to its local place",study.point.position.is_equal_approx(Vector3(0,1.1,1.45)))
	var key:=InputEventKey.new();key.keycode=KEY_F;key.pressed=true;study._unhandled_key_input(key);await settle()
	check("Desktop finish produces same record and volume",study.model.history==record and study.model.solid==cells)
	var edited=load(DIR+"variation/cave.gd").new();host.add_child(edited);await settle();edited.act("FINISH");await settle()
	var added:int=edited.model.air_count()-final_air
	check("Complete headroom edit retains exact route and history",edited.model.history==record and edited.ROUTE==study.ROUTE and edited.model.HEADROOM==3)
	var superset:=true;var roof:=true
	for i in 196: superset=superset and (cells[i]!=0 or edited.model.solid[i]==0)
	for x in 7:
		for z in 7:roof=roof and edited.model.solid[edited.model.index(Vector3i(x,3,z))]==1
	check("Third layer clears same footprint while keeping top roof",superset and roof and added*2==final_air)
	var v=load(DIR+"variation/carver.gd").new();v.reset();v.carve(Vector3i(3,0,3));var fifteen:bool=v.air_count()==15;v.reset();v.carve(Vector3i(3,0,6))
	check("Edited interior and boundary predictions hold",fifteen and v.air_count()==12)
	for folder in ["wrong_square","wrong_height","wrong_history"]:
		var bad=load(DIR+folder+"/carver.gd").new();bad.reset();bad.carve(Vector3i(3,0,3));bad.carve(Vector3i(3,0,3))
		check("Reject faulty program: "+folder,not (bad.air_count()==10 and bad.history.size()==2))
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_comparisons":comparisons,"counts":{"baseline_air":final_air,"edited_air":edited.model.air_count(),"centres":record.size()},"scope":"Exact printed programs; source-kernel comparisons; full edit; three fault oracles; supplied XRTools poses, not headset or independent student."}
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	origin.queue_free();host.queue_free();await settle();quit(0 if failures.is_empty() else 1)
