extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok}); print("KOCH ", title, " ", ok)
	if not ok: failures.append(title)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	var study = load("res://ada_run/koch_student/koch.gd").new()
	study.position = Vector3(12,0,-5); study.rotation.y = 1.8; world.add_child(study)
	await frames(4)
	check("Printed example constructs a point and one drawn segment", study.point != null and study.drawing.get_child_count() == 1)
	check("Four metre seed and independent current array", study.path_length(study.current) == 4.0 and not is_same(study.current, study.original))
	var original: Array = study.original.duplicate()
	for n in range(1,5):
		study.advance()
		var expected: int = int(pow(4,n))
		check("Printed step %d: positions, segments and length" % n, study.current.size() == expected+1 and study.drawing.get_child_count() == expected and absf(study.path_length(study.current) - 4.0 * pow(4.0/3.0,n)) < 0.0001)
		check("Printed step %d: seed and endpoints preserved" % n, study.original == original and study.current[0] == original[0] and study.current[-1] == original[-1])
		var lengths := true
		for i in expected: lengths = lengths and absf(study.current[i].distance_to(study.current[i+1])-4.0/pow(3,n)) < 0.00001
		check("Printed step %d: every child has correct length" % n, lengths)
	var finished: Array = study.current.duplicate(); study.advance()
	check("Printed study stops at four without altering current", study.generation == 4 and study.current == finished)
	var first: Array = study.replace_path(study.original)
	check("First five positions include the equilateral peak", first.size() == 5 and first[1].is_equal_approx(Vector3(-2.0/3.0,0,0)) and first[2].is_equal_approx(Vector3(0,2.0*sqrt(3.0)/3.0,0)) and first[3].is_equal_approx(Vector3(2.0/3.0,0,0)))
	var mirrored: Array = study.replace_path(study.original,-1.0)
	check("Independent turn reversal preserves length and mirrors the peak", absf(study.path_length(mirrored)-16.0/3.0) < 0.00001 and mirrored[2].is_equal_approx(Vector3(first[2].x,-first[2].y,0)))
	var tilted: Array[Vector3] = [Vector3(-1,-1,0),Vector3(1,1,0)]
	var turned: Array = study.replace_path(tilted)
	check("Tilted seed is replaced in its own direction within XY", turned[0] == tilted[0] and turned[-1] == tilted[-1] and absf(study.path_length(turned)-sqrt(8.0)*4.0/3.0) < 0.00001)
	study.current.assign(first); study.generation = 1; study.redraw(); await frames(3)
	var peak: Dictionary = study.nearest_on_path(first[2])
	check("Reader returns known peak at half the first path length", peak.point.is_equal_approx(first[2]) and absf(peak.along-8.0/3.0) < 0.00001)
	var origin := XROrigin3D.new(); world.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	controller.global_position = study.point.global_position; study.point.pick_up(hand); await frames(4)
	controller.global_position = study.to_global(study.display(first[2])); await frames(8)
	check("Actual XR pickup reads path in a rotated study frame", study.point.held() and study.cursor.is_equal_approx(first[2]) and absf(study.along-8.0/3.0)<0.001)
	study.point.action(); await frames(4)
	check("Actual pickable action requests one replacement", study.generation == 2 and study.current.size() == 17)
	study.point.let_go(hand,Vector3.ZERO,Vector3.ZERO); await frames(4)
	check("Release parks at represented point without another step", study.generation == 2 and study.to_local(study.point.global_position).is_equal_approx(study.display(study.cursor)))
	study.point.on_desktop_grab(world); study.point.global_position = study.to_global(study.display(study.current[-1])); await frames(4)
	check("Desktop hook reads last endpoint and full path", absf(study.along-study.path_length(study.current))<0.001)
	study.point.on_desktop_drop(world); await frames(2)
	Input.action_press("ui_accept"); await process_frame; await process_frame; Input.action_release("ui_accept"); await frames(2)
	check("Named desktop action advances once",study.generation==3)
	var source = load("res://algorithms/fractals/example_8_5_koch_curve_vr.tscn").instantiate()
	source.animate_growth = false; world.add_child(source); source.apply_grid_config({"lesson":"true"}); await frames(5)
	var desk = source.get_node("FractalLesson"); var reader = desk.path_reader
	check("Production desk installs one reader and three nearby controls", reader != null and reader.buttons.size() == 3)
	for n in range(5):
		desk.set_stage(n)
		var expected: Array[Vector3] = study.original.duplicate()
		for j in n: expected = study.replace_path(expected)
		var same: bool = reader.points.size() == expected.size()
		for i in expected.size(): same = same and (reader.points[i]*5.0).distance_to(expected[i])<0.00001
		check("Production/printed endpoints agree at step %d" % n, same and absf(reader.total-study.path_length(expected)) < 0.0001)
	var before: Array = reader.points.duplicate(); var length: float = reader.total
	desk.act("TURN")
	check("Production TURN keeps length and reverses geometry", reader.points != before and absf(reader.total-length)<0.00001)
	desk.act("RESET"); desk.act("FORM"); desk.act("NEXT")
	check("Closed comparison has 12 segments and 14 metre perimeter", reader.points.size()==13 and reader.points[0].is_equal_approx(reader.points[-1]) and absf(reader.total-14.0)<0.0001)
	desk.act("RESET"); source.rotation.y = -1.2; source.position = Vector3(-5,0,2); await frames(3)
	controller.global_position = reader.grip.global_position; reader.grip.pick_up(hand); await frames(4)
	reader.grip.action(); await frames(3)
	var tip: Vector3 = reader.points[2]
	controller.global_position = reader.model.to_global(reader.MINI_ORIGIN + reader.flat(tip)*reader.MINI_SCALE); await frames(8)
	check("Production XR trigger and hand read the same peak", source._current_depth==1 and reader.cursor.distance_to(tip)<0.0001 and absf(reader.along-8.0/3.0)<0.001)
	check("Floor receiver follows the exact selected data point", reader.floor_mark.position.is_equal_approx(reader.FLOOR_ORIGIN + reader.flat(reader.cursor)*5.0+Vector3.UP*0.085))
	reader.grip.let_go(hand,Vector3.ZERO,Vector3.ZERO); await frames(4)
	check("Production release keeps reading without moving source endpoints", reader.model.to_local(reader.grip.global_position).is_equal_approx(reader.MINI_ORIGIN+reader.flat(tip)*reader.MINI_SCALE) and reader.points[0].is_equal_approx(Vector3(-0.4,0,0)))
	check("Floor drawing has no additional collision",reader.floor_path.get_child_count()==0 and reader.floor_mark.get_child_count()==0)
	for i in 5: desk.act("NEXT")
	check("Production keeps bounded 256-segment open path", source._current_depth==4 and reader.points.size()==257)
	desk.act("BACK"); check("BACK restores previous generation",source._current_depth==3 and reader.points.size()==65)
	desk.act("RESET"); check("RESET restores seed and zero reading", source._current_depth==0 and reader.points.size()==2 and reader.along==0)
	FileAccess.open("res://ada_run/koch_hand_tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact three printed scripts; production source/receiver and XRTools supplied poses. No physical headset or learning claim."},"  "))
	quit(0 if failures.is_empty() else 1)
