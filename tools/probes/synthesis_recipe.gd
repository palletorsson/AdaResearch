extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok});print("RECIPE ",title," ",ok)
	if not ok:failures.append(title)
func frames(n: int) -> void:
	for i in n:await physics_frame
func same_intervals(a: Array, b: Array) -> bool:
	if a.size()!=b.size():return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):return false
	return true
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var study=load("res://ada_run/synthesis_student/recipe.gd").new();world.add_child(study)
	var variant=load("res://ada_run/synthesis_student/four_cuts.gd").new();variant.position.x=10;world.add_child(variant)
	var fixture=load("res://commons/artifacts/timing_machines/machine_stage.gd").new();world.add_child(fixture)
	var installed=load("res://commons/artifacts/fractal_recipe_table/museum_recipe_table.gd").new();installed.fixture=fixture;installed.position=Vector3(-10,0,4);installed.rotation.y=1.2;world.add_child(installed)
	var grammar=load("res://commons/artifacts/lsystem_editor/lsystem_editor.gd").new();grammar.position.x=25;world.add_child(grammar);grammar.preset=7
	await frames(3)
	check("Exact printed code creates point and two eight-piece rows",study.point is RigidBody3D and study.point.has_method("pick_up") and study.live.size()==8 and study.kept.size()==8 and study.drawing.get_child_count()==16)
	check("PointBody carried unchanged from Golden Spiral",FileAccess.get_file_as_string("res://ada_run/synthesis_student/point_body.gd").replace("\r","")==FileAccess.get_file_as_string("res://commons/artifacts/golden_mapping_lesson/point_body.gd").replace("\r",""))
	check("Independent four-cut script executes sixteen pieces and 32/27 metres",variant.live.size()==16 and absf(variant.total(variant.live)-32.0/27.0)<0.00001)
	for f in study.FRACTIONS:
		for depth in range(6):
			var settings:Dictionary={"seed":Vector2(0,6),"fraction":f,"steps":depth}
			var result:Array=study.build(settings)
			var ordered:=true;var end:=0.0
			for interval:Vector2 in result:
				ordered=ordered and interval.x>=end-0.00001 and interval.y>0 and interval.x+interval.y<=6.00001
				end=interval.x+interval.y
			check("Fraction %.5f depth %d: count, length, ordered bounds"%[f,depth],result.size()==int(pow(2,depth)) and absf(study.total(result)-6*pow(2*f,depth))<0.00001 and ordered)
	var input:Array[Vector2]=[Vector2(10,6)]
	check("Replacement uses start and leaves input untouched",study.replace_intervals(input,0.25)==[Vector2(10,1.5),Vector2(14.5,1.5)] and input==[Vector2(10,6)])
	var empty:Array[Vector2]=[]
	check("Empty generation stays empty",study.replace_intervals(empty,0.25).is_empty())
	var kept:Array=study.kept.duplicate();var original:Dictionary=study.kept_recipe.duplicate(true)
	study.choose(0)
	check("Live quarter edit preserves independently kept thirds",study.kept==kept and study.kept_recipe==original and not is_same(study.recipe,study.kept_recipe) and is_equal_approx(study.total(study.live),0.75))
	study.keep_current();study.choose(2)
	check("KEEP replaces snapshot; subsequent live edit stays independent",is_equal_approx(study.kept_recipe.fraction,0.25) and is_equal_approx(study.total(study.kept),0.75) and is_equal_approx(study.total(study.live),3.072))
	study.restore();study.advance()
	check("RESTORE also copies before next edit",study.recipe.steps==4 and study.kept_recipe.steps==3 and is_equal_approx(study.recipe.fraction,0.25))
	study.reset_live()
	check("RESET changes live only",study.recipe==original and is_equal_approx(study.kept_recipe.fraction,0.25))
	for i in 10:study.advance()
	check("NEXT caps at five and rebuilds from seed",study.recipe.steps==5 and study.live.size()==32 and same_intervals(study.live,study.build(study.recipe)))
	study.reset_live();study.choose(2)
	var mesh_ok:=true
	for i in study.drawing.get_child_count():
		var surface:MeshInstance3D=study.drawing.get_child(i)
		var row:Array=study.live if i<study.live.size() else study.kept
		var j:int=i if i<study.live.size() else i-study.live.size()
		mesh_ok=mesh_ok and is_equal_approx(surface.mesh.size.x,row[j].y*0.34) and is_equal_approx(surface.position.x,(row[j].x+row[j].y/2-3)*0.34)
	check("Both actual mesh rows use fixed common scale and positions",mesh_ok)
	check("Interval drawings are non-colliding views",study.drawing.find_children("*","CollisionObject3D",true,false).is_empty())
	# Compare the next laboratory's actual rewrite and turtle, not a second test implementation.
	for depth in range(6):
		grammar.generations=depth;await frames(1)
		var lines:Array=grammar.fitted_lines
		var normalized:Array[Vector2]=[]
		for i in range(0,lines.size(),2):normalized.append(Vector2(lines[i].y,lines[i+1].y-lines[i].y)*6.0/(grammar.display_size*0.8))
		var expected:Array=study.build({"seed":Vector2(0,6),"fraction":1.0/3.0,"steps":depth})
		check("Actual Cantor grammar matches thirds at depth %d"%depth,same_intervals(normalized,expected) and grammar.get_string().count("F")==int(pow(2,depth)))
	check("Other fractions are not that same grammar",not same_intervals(study.build({"seed":Vector2(0,6),"fraction":0.25,"steps":5}),study.build({"seed":Vector2(0,6),"fraction":1.0/3.0,"steps":5})))
	var origin:=XROrigin3D.new();world.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=installed.point.global_position;installed.point.pick_up(pickup);await frames(4)
	controller.global_position=installed.to_global(Vector3(-0.35,1.15,0.55));await frames(6)
	check("XRTools hand chooses quarter in rotated local frame",installed.point.is_picked_up() and is_equal_approx(installed.recipe.fraction,0.25))
	installed.point.action();await frames(2)
	check("Held trigger keeps actual selected recipe",installed.kept_recipe==installed.recipe and not is_same(installed.recipe,installed.kept_recipe))
	controller.global_position=installed.to_global(Vector3(0.35,1.15,0.55));await frames(6)
	check("Hand can vary live without changing kept",is_equal_approx(installed.recipe.fraction,0.4) and is_equal_approx(installed.kept_recipe.fraction,0.25))
	var held_state:Dictionary=installed.recipe.duplicate(true)
	for id in ["NEXT","RESTORE","RESET"]:installed.act(id)
	check("Controls that would displace held point refuse edits",installed.recipe==held_state)
	installed.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await frames(4)
	check("Released point parks at selected fraction",installed.point.position.is_equal_approx(Vector3(0.35,1.15,0.55)))
	installed.act("RESTORE");await frames(2)
	check("Released restore recovers quarter",installed.recipe==installed.kept_recipe and installed.point.position.is_equal_approx(Vector3(-0.35,1.15,0.55)))
	study.point.on_desktop_grab(world);study.point.position=Vector3(-0.35,1.15,0.55);await frames(3)
	check("Printed desktop-held point selects same quarter",is_equal_approx(study.recipe.fraction,0.25))
	study.point.on_desktop_drop(world);await frames(2)
	study.choose(2)
	var key:=InputEventAction.new();key.action="ui_accept";key.pressed=true;Input.parse_input_event(key);Input.flush_buffered_events();await process_frame;await process_frame
	key.pressed=false;Input.parse_input_event(key);Input.flush_buffered_events();await process_frame
	check("Named Enter keeps printed example",is_equal_approx(study.kept_recipe.fraction,0.4))
	check("Installed artifact ignores global Enter",is_equal_approx(installed.kept_recipe.fraction,0.25))
	var out:=FileAccess.open("res://ada_run/synthesis_recipe_tests.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "));out.close()
	world.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
