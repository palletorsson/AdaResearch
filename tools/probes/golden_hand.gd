extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok});print("GOLDEN ",title," ",ok)
	if not ok:failures.append(title)
func frames(n: int) -> void:
	for i in n:await physics_frame
func bars(study: Node3D) -> Array:
	return study.drawing.get_children().filter(func(n):return n is MeshInstance3D)
func run() -> void:
	var world:=Node3D.new();root.add_child(world);current_scene=world
	var study=load("res://ada_run/golden_student/sum_points.gd").new();world.add_child(study)
	var variant=load("res://ada_run/golden_student/different_seeds.gd").new();variant.position.x=10;world.add_child(variant)
	var source=load("res://algorithms/fractals/fibonacci_sequences/fibonacci_sequences.tscn").instantiate()
	source.lesson_enabled=true;source.position.x=-20;world.add_child(source);source.apply_grid_config({"lesson":"true"})
	var rectangle=load("res://algorithms/fractals/golden_rectangle/golden_rectangle.tscn").instantiate()
	rectangle.animate=false;rectangle.position.x=25;world.add_child(rectangle);rectangle.apply_grid_config({"lesson":"true"})
	await frames(3)
	var desk=source.get_node("GoldenLesson");var hand=desk.hand_sum
	var rect_desk=rectangle.get_node("GoldenLesson")
	check("Printed example creates two points and four seeded bars",study.points.size()==2 and bars(study).size()==4 and study.values==[1,1])
	check("PointBody is carried unchanged",FileAccess.get_file_as_string("res://ada_run/golden_student/point_body.gd").replace("\r","")==FileAccess.get_file_as_string("res://doc/book/studies/fractals-through-the-hands/Fractal_MengerSponge/point_body.gd").replace("\r",""))
	var expected: Array=[1,1,2,3,5,8,13,21,34,55]
	for n in range(2,10):
		var earlier: Array=study.values.duplicate();study.advance();desk.act("NEXT");variant.advance()
		check("Term %d appends a sum without replacing earlier entries"%(n+1),study.values==expected.slice(0,n+1) and study.values.slice(0,n)==earlier and study.values==hand.values and study.values==source.fibonacci_numbers.slice(0,n+1))
	check("Executed [1,2] variation reaches89 with same recurrence",variant.values==[1,2,3,5,8,13,21,34,55,89])
	study.advance();desk.act("NEXT")
	check("Both installed and printed versions stop at ten",study.values==expected and desk.term_count==10 and hand.values==expected)
	var meshes: Array=bars(study)
	var geometry_ok:=meshes.size()==20
	for row in 2:
		for i in 10:
			var m:MeshInstance3D=meshes[row*10+i]
			geometry_ok=geometry_ok and is_equal_approx(m.mesh.size.y,study.height_for(expected[i],row==0)*0.2) and is_equal_approx(m.position.y-m.mesh.size.y*0.5,1.02)
	check("Two actual mesh rows have declared heights and aligned bases",geometry_ok)
	check("Linear unit and compressed endpoint match text",is_equal_approx(meshes[0].mesh.size.y,0.01) and is_equal_approx(meshes[9].mesh.size.y,0.55) and absf(meshes[19].mesh.size.y-0.5007333)<0.00001)
	check("Drawings have no collision bodies",study.drawing.find_children("*","CollisionObject3D",true,false).is_empty())
	var original: Array=source.fibonacci_numbers.duplicate();var record: Array=hand.values.duplicate()
	desk.act("HEIGHT");desk.act("SUM")
	check("View changes preserve both records",source.fibonacci_numbers==original and hand.values==record and desk.sum_view.visible)
	check("Installed large mapping retains five-centimetre units",is_equal_approx(desk.height_values[-1],2.75))
	var tops: Array=[]
	for n in desk.sum_view.get_children():
		if n is MeshInstance3D:tops.append(n.position.y+n.mesh.size.y*0.5)
	check("Fixed-unit SUM reaches2.75m",tops.size()==110 and is_equal_approx(tops.max(),2.75))
	check("Logarithmic height does not preserve this addition",not is_equal_approx(study.height_for(21,false)+study.height_for(34,false),study.height_for(55,false)))
	# Real pickable hand with supplied pose: bringing one point to its parked partner.
	desk.act("RESET");source.rotation.y=0.6
	var origin:=XROrigin3D.new();world.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.points[0].global_position;hand.points[0].pick_up(pickup);await frames(3)
	controller.global_position=hand.points[1].global_position;await frames(5)
	check("One held point joined to resting partner requests one sum in rotated frame",hand.values==[1,1,2] and desk.term_count==3 and hand.latched)
	check("Joined operands retain labels until release",hand.names[0].text=="1" and hand.names[1].text=="1" and hand.readout.text.begins_with("1 + 1 = 2"))
	await frames(12);hand.points[0].action()
	check("Continued contact and trigger cannot repeat the held request",desk.term_count==3)
	hand.points[0].let_go(pickup,Vector3.ZERO,Vector3.ZERO);await frames(4)
	check("Release rearms and presents next pair",not hand.latched and hand.names[0].text=="1" and hand.names[1].text=="2" and hand.points[0].position.is_equal_approx(hand.home(0)))
	controller.global_position=hand.points[0].global_position;hand.points[0].pick_up(pickup);await frames(3)
	hand.points[0].action();await frames(3)
	check("Fresh trigger requests the following sum",hand.values==[1,1,2,3])
	desk.act("BACK");await frames(3)
	check("Desk edit during hold does not create an extra sum",desk.term_count==3 and hand.latched)
	hand.points[0].let_go(pickup,Vector3.ZERO,Vector3.ZERO);await frames(3)
	check("Adapter stores a separate prefix, preserving source",not is_same(hand.values,source.fibonacci_numbers) and source.fibonacci_numbers==original)
	# Exact printed contact code via supplied desktop hooks, including two-held rearming.
	var fresh=load("res://ada_run/golden_student/sum_points.gd").new();fresh.position.z=8;world.add_child(fresh)
	fresh.points[0].on_desktop_grab(world);fresh.points[1].on_desktop_grab(world)
	fresh.points[0].position=fresh.points[1].position;await frames(3)
	check("Printed example has same join behaviour",fresh.values==[1,1,2] and fresh.latched)
	fresh.points[0].on_desktop_drop(world);await frames(3)
	check("One of two held points released does not rearm",fresh.latched)
	fresh.points[1].on_desktop_drop(world);await frames(3)
	check("Both released rearm",not fresh.latched)
	var key:=InputEventAction.new();key.action="ui_accept";key.pressed=true;Input.parse_input_event(key);Input.flush_buffered_events();await process_frame;await process_frame
	key.pressed=false;Input.parse_input_event(key);Input.flush_buffered_events();await process_frame
	check("Named Enter action advances printed study",fresh.values==[1,1,2,3])
	check("Installed artifact ignores global Enter",desk.term_count==3)
	for n in range(9):
		if n>0:rect_desk.act("NEXT")
		var r:Dictionary=rectangle.rectangles.back()
		var area:float=r.width*r.height
		for part in rectangle.rectangles:
			if part.get("is_square",false):area+=part.width*part.height
		check("Rectangle cut%d preserves area and proportion"%n,absf(area-25.0/rectangle.PHI)<0.00001 and absf(maxf(r.width,r.height)/minf(r.width,r.height)-rectangle.PHI)<0.00001)
	var parts:Array=rectangle.rectangles.duplicate(true);rect_desk.act("ARC");rect_desk.act("MEASURE")
	check("Arc and measurement add views without changing partition",rectangle.rectangles==parts and rectangle.spiral_mesh.visible)
	var out:=FileAccess.open("res://ada_run/golden_hand_tests.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "));out.close()
	world.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
