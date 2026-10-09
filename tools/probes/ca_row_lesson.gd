extends SceneTree
var checks: Array = []
var failures: Array = []
const OUT := "res://doc/book/iterations/2026-10-08-ca-a-row-with-neighbours/"
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures.append(label)
	print("CA ROW ", label, " ", ok)
func frames(n: int = 4) -> void:
	for i in n: await physics_frame
func active(row: Array) -> Array:
	var result := []
	for i in row.size():
		if row[i]: result.append(i)
	return result
func run() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	var study = load(OUT + "printed/row.gd").new()
	study.position = Vector3(8,0,-3); study.rotation.y = 1.3; world.add_child(study)
	await frames()
	check("Printed files build point, label and only one visible generation", study.point != null and study.reading.text.contains("GEN 0") and study.tiles.visible_instance_count == 32 and active(study.current) == [16])
	check("Recorded seed is an independent array", not is_same(study.current,study.history[0]))
	var first: Array = study.current.duplicate()
	study.step(); check("Rule 90 first row has the two neighbouring cells", active(study.current) == [15,17] and study.history[1] == first)
	study.step(); check("Second row cancels the middle and moves two cells outward", active(study.current) == [14,18])
	var production = load("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd").new()
	production.set_meta("config_study","neighbours"); production.set_meta("config_room","ring")
	world.add_child(production); await frames()
	check("Existing museum explorer installs exactly one hand reader", production.get_node("NeighbourStudy/HandPoint") != null)
	var reader = production.get_node("NeighbourStudy/HandPoint")
	for rule_number in [90,30]:
		for i in 8: study.answers[i] = ((rule_number >> i) & 1) == 1
		production.rule = rule_number; production._reset(); study.reset()
		var truth_ok := true
		for i in 8:
			var l := (i & 4) != 0; var c := (i & 2) != 0; var r := (i & 1) != 0
			truth_ok = truth_ok and study.answer(l,c,r) == production._apply_rule(l,c,r)
		check("Eight explicit answers agree with installed Rule %d" % rule_number,truth_ok)
		var rows_ok := true
		for i in 40:
			study.step(); production.step()
			rows_ok = rows_ok and study.current == production._current_row and study.history == production._grid
		check("Forty generations and retained history agree for Rule %d" % rule_number,rows_ok)
	check("History truncates at 24 while generation continues to 40",study.generation == 40 and study.history.size() == 24 and study.tiles.visible_instance_count == 768)
	for i in 8: study.answers[i] = ((90 >> i) & 1) == 1
	study.seeds.assign([15,16]); study.reset(); study.step()
	check("Independent adjacent-seed variation gives four active addresses",active(study.current)==[14,15,16,17])
	study.seeds.assign([0]); study.reset(); study.step()
	check("A boundary seed affects 31 and 1 without adding cells",active(study.current)==[1,31] and study.current.size()==32)
	var reversed_study = load(OUT+"variants/reverse/row.gd").new(); world.add_child(reversed_study)
	var mutation = load(OUT+"variants/in-place/row.gd").new(); world.add_child(mutation)
	study.seeds.assign([16]); study.reset()
	var traversal_ok := true
	for i in 30:
		study.step(); reversed_study.step()
		traversal_ok = traversal_ok and study.current == reversed_study.current
	check("Reversed traversal preserves all thirty generations",traversal_ok)
	study.reset(); study.step(); mutation.step()
	check("The checker rejects an in-place update fault",study.current != mutation.current)
	var old: Array[bool] = study.current.duplicate(); var saved := old.duplicate()
	var result: Array = study.evolve(old)
	check("Evolution neither changes nor aliases its input",old == saved and not is_same(old,result))
	var record: Array = study.history[0].duplicate(); study.current[0] = not study.current[0]
	check("Editing current cannot rewrite a recorded generation",study.history[0] == record)
	study.reset(); check("Reset keeps the chosen seed and discards prior history",study.generation==0 and study.history.size()==1 and active(study.current)==[16])
	var origin := XROrigin3D.new(); world.add_child(origin)
	var controller := XRController3D.new(); origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(hand)
	controller.global_position = study.point.global_position; study.point.pick_up(hand); await frames()
	controller.global_position = study.to_global(Vector3(study.cell_x(4),1.3,.9)); await frames(8)
	check("Actual XRTools pickup selects cell 4 in a rotated local frame",study.point.held() and study.selected==4)
	check("Selection does not change the seed or advance time",study.generation==0 and active(study.current)==[16])
	study.point.action(); await frames()
	check("Pickable trigger makes one generation",study.generation==1 and active(study.current)==[15,17])
	study.point.let_go(hand,Vector3.ZERO,Vector3.ZERO); await frames()
	check("Release parks reader without another generation",not study.point.held() and study.generation==1 and study.point.position.is_equal_approx(Vector3(study.cell_x(4),1.15,.9)))
	study.point.on_desktop_grab(world); study.point.global_position=study.to_global(Vector3(-5,1,.9)); await frames()
	check("Desktop reader clamps to first address",study.selected==0)
	study.point.global_position=study.to_global(Vector3(5,1,.9)); await frames()
	check("Desktop reader clamps to last address",study.selected==31)
	study.point.on_desktop_drop(world); await frames()
	var key := InputEventKey.new(); key.keycode=KEY_ENTER; key.pressed=true
	study._unhandled_key_input(key); key.echo=true; study._unhandled_key_input(key)
	check("Enter steps once and key repeat is ignored",study.generation==2)
	var rendered_ok := true
	for row in study.history.size():
		for col in 32:
			var expected := Color("87dca5") if study.history[row][col] else Color("243238")
			var got: Color = study.tiles.get_instance_color(row*32+col)
			if row==0 and col==0: print("COLOUR STORAGE ",got," / ",expected)
			rendered_ok = rendered_ok and absf(got.r-expected.r)<0.004 and absf(got.g-expected.g)<0.004 and absf(got.b-expected.b)<0.004 and absf(got.a-expected.a)<0.004
	check("Every visible tile displays its stored state",rendered_ok)
	production.rule=90; production._reset(); production.position=Vector3(-3,0,2); production.rotation.y=-1.1
	await frames()
	controller.global_position=reader.point.global_position; reader.point.pick_up(hand); await frames()
	controller.global_position=reader.to_global(Vector3(-.8,.2,1.45)); await frames(8)
	check("Installed reader selects the boundary in its rotated hall frame",production.sample_cell==0 and production.generation==0)
	reader.point.action(); await frames(10)
	check("Installed trigger steps existing explorer and its same history receiver",production.generation==1 and production.get_node("NeighbourStudy").room_ring.rendered==production._grid)
	reader.point.let_go(hand,Vector3.ZERO,Vector3.ZERO); await frames()
	check("Installed release parks at selected address",reader.point.position.is_equal_approx(Vector3(-.775,.2,1.45)))
	var other = load("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd").new()
	other.set_meta("config_study","neighbours"); world.add_child(other); await frames()
	check("Other explorer configurations retain their existing interface",other.get_node("NeighbourStudy").get_node_or_null("HandPoint")==null)
	FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Exact printed scripts, independent variations, mutation rejection, installed source parity and actual XRTools with synthetic poses. No physical headset or human learner test."},"  "))
	world.queue_free(); await frames(3)
	quit(0 if failures.is_empty() else 1)
