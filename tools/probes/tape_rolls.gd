extends SceneTree
var checks: Array = []
var failures: Array = []
var out := "res://ada_run/matter-reference"
class Hand extends Node3D:
	var picked_up_ranged := false
func _initialize() -> void:run.call_deferred()
func frames(n := 4) -> void:
	for i in n:await physics_frame
func check(name: String,ok: bool) -> void:
	checks.append({"name":name,"passed":ok});print("TAPE ",ok," ",name)
	if not ok:failures.append(name)
func fire(roll: Node3D) -> void:
	roll.action();await frames(2);roll.action_release();await frames(2)
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	var world := Node3D.new();root.add_child(world);current_scene = world
	var work: Node3D = load("res://commons/artifacts/tape_roll/station.tscn").instantiate();world.add_child(work)
	if work.get_script()==null:quit(1);return
	var camera := Camera3D.new();world.add_child(camera);camera.position = Vector3(0,1.6,3);camera.make_current()
	var hand := Hand.new();world.add_child(hand);hand.position = Vector3(.6,1.25,2)
	await frames(12)
	check("Three distinct native rolls and eleven editable members",work.rolls.size()==3 and work.part_defaults.size()==11)
	if work.rolls.size()!=3:quit(1);return
	var board: Node3D = work.get_node("SampleBoard")
	for roll in work.rolls:
		check(roll.kind+" listeners exist before pickup",not roll.action_pressed.get_connections().is_empty())
		await fire(roll);check(roll.kind+" cannot draw while unheld",roll.start_anchor.is_empty())
		roll.pick_up(hand);await frames(10)
		check(roll.kind+" native XRTools pickup",roll.is_picked_up())
		camera.look_at(Vector3(-.5,1.65,-.36));await frames()
		roll.action();await frames()
		check(roll.kind+" first fire attaches A to actual board collider",not roll.start_anchor.is_empty() and roll.start_anchor.body.get_ref()==board)
		camera.look_at(Vector3(.1,1.55,-.36));await frames(24)
		camera.look_at(Vector3(0,4,-.36));await frames(12)
		camera.look_at(Vector3(.5,1.65,-.36));await frames(24)
		check(roll.kind+" long held click and missed rays do not paint fragments",not roll.freehand_draw and roll.drag_points.size()==1 and roll.segments.is_empty() and roll.remaining==roll.roll_length)
		roll.action();await frames();check(roll.kind+" held trigger does not finish a strip",roll.segments.is_empty())
		roll.action_release();camera.look_at(Vector3(.5,1.65,-.36));await frames(8)
		check(roll.kind+" release keeps the start without placing tape",not roll.start_anchor.is_empty() and roll.segments.is_empty())
		check(roll.kind+" moving aim stretches a live preview",roll.preview.visible and roll.preview.mesh!=null)
		await fire(roll)
		check(roll.kind+" second fire finishes one strip",roll.segments.size()==1 and roll.start_anchor.is_empty())
		if roll.segments.size()==1:
			var strip: Node3D = roll.segments[0]
			check(roll.kind+" placed tape has exactly two endpoints and no breaks",strip.anchors.size()==2 and not strip.anchors.any(func(a):return a.get("break_before",false)))
			check(roll.kind+" width belongs to roll",is_equal_approx(strip.tape_width,roll.WIDTHS[roll.TYPES.find(roll.kind)]))
			check(roll.kind+" only committed length is consumed",absf(roll.remaining+strip.paid_length-roll.roll_length)<.0001)
			var record: Dictionary = strip.anchors[0];board.position.x += .2;board.rotation.y += .15;board.scale = Vector3(1.1,1.05,.8);await frames(6)
			check(roll.kind+" tape follows translated rotated scaled target",strip.cached[0].distance_to(board.to_global(record.point))<.0001)
			board.position = Vector3(0,1.38,-.36);board.rotation = Vector3.ZERO;board.scale = Vector3.ONE;await frames(5)
		camera.look_at(Vector3(-.5,1.65,-.36));await frames();await fire(roll)
		camera.look_at(Vector3(0,4,-.36));await frames();var count: int = roll.segments.size();await fire(roll)
		check(roll.kind+" missed end shot retains A and consumes nothing",not roll.start_anchor.is_empty() and roll.segments.size()==count)
		roll.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames(5)
		check(roll.kind+" dropping cancels unfinished tape",roll.start_anchor.is_empty() and not roll.preview.visible)
		check(roll.kind+" remains pickable after release",roll.collision_layer==5)
	work.undo();await frames();check("Undo removes last strip and refunds its roll",work.rolls[2].remaining==30 and work.rolls[2].segments[0]==null)
	work.tidy();await frames();check("Tidy clears committed tape and refills all rolls",work.rolls.all(func(roll):return roll.segments.is_empty() and roll.remaining==30))
	var pink: Node3D = work.rolls[1];pink.pick_up(hand);await frames()
	camera.look_at(Vector3(-.5,1.65,-.36));await frames();await fire(pink)
	var obstruction := StaticBody3D.new();obstruction.position = Vector3(0,1.65,-.30);world.add_child(obstruction)
	var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(.10,.3,.2);obstruction.add_child(shape);await frames()
	camera.look_at(Vector3(.5,1.65,-.36));await frames();await fire(pink)
	check("Solid object between endpoints refuses tape through it",pink.segments.is_empty() and not pink.start_anchor.is_empty())
	obstruction.free();await frames();pink.max_span = .4;await fire(pink)
	check("Excess span is refused without losing the starting point",pink.segments.is_empty() and not pink.start_anchor.is_empty())
	pink.max_span = 8;pink.remaining = .01;await fire(pink)
	check("An empty roll refuses a new strip",pink.segments.is_empty())
	pink.clear_tape();await frames()
	board.collision_layer = 1<<12;await frames()
	camera.look_at(Vector3(-.5,1.65,-.36));await frames();await fire(pink)
	camera.look_at(Vector3(.5,1.65,-.36));await frames();await fire(pink)
	var orphan: Node3D = pink.segments[0] if not pink.segments.is_empty() else null
	check("Non-default solid collision layers also accept tape",is_instance_valid(orphan) and orphan.anchors[0].body.get_ref()==board)
	var board_parent := board.get_parent()
	board_parent.remove_child(board);await frames(3)
	check("Transiently reparented targets keep their tape record",is_instance_valid(orphan))
	board_parent.add_child(board);await frames(4)
	board.hide();await frames(3);check("Hidden floors do not leave floating tape",not orphan.visible)
	board.show();await frames(3);check("Tape returns with its visible target",orphan.visible)
	board.free();await frames(8);check("Removing a touched object removes dangling tape",not is_instance_valid(orphan))
	pink.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	for row in [["MaskingRoll","masking"],["PinkRoll","pink"],["BarrierRoll","barrier"]]:
		var copy: Node3D = load("res://commons/artifacts/tape_roll/station.tscn").instantiate()
		copy.apply_grid_config({"only_parts":[row[0]],"parts":{row[0]:{"position":[0,0,0],"rotation":[0,0,0]}}})
		copy.position = Vector3(10,0,0);world.add_child(copy);await frames(3)
		check("Source-backed "+row[1]+" copy contains only its own editable roll",copy.get_child_count()==1 and copy.part_defaults.size()==1 and copy.rolls.size()==1 and copy.rolls[0].kind==row[1] and copy.rolls[0].position==Vector3.ZERO)
		copy.prepare_editor_preview();copy.free();await frames(2)
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Actual physics rays and native XRTools held-action API; all roll skins, local anchors, missed/blocked shots, budgets, undo and cleanup. Player-input receipt is separate."}
	FileAccess.open(out.path_join("tape-rolls-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
