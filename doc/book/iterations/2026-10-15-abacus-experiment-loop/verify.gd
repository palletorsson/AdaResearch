extends SceneTree
const FOLDER := "res://doc/book/iterations/2026-10-15-abacus-experiment-loop/reconstructed/"
var failures: Array[String] = []
var checks := 0
var recordings: Array[String] = []

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures.append(reason)
		push_error(reason)

func _initialize() -> void: call_deferred("run")

func same_data(a: Variant, b: Variant) -> bool:
	# JSON reads integers as floats. Compare numeric values exactly, without tolerance.
	if (a is int or a is float) and (b is int or b is float): return float(a)==float(b)
	if typeof(a)!=typeof(b): return false
	if a is Array:
		if a.size()!=b.size(): return false
		for i in a.size():
			if not same_data(a[i],b[i]): return false
		return true
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same_data(a[key],b[key]): return false
		return true
	return a==b

func build():
	var scene = load(FOLDER+"random_touch.gd").new()
	var notebook = load(FOLDER+"experiment_notebook.gd").new()
	notebook.name = "Notebook"
	scene.add_child(notebook)
	root.add_child(scene)
	scene.set_physics_process(false)
	return scene

func shortcut(notebook: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	event.ctrl_pressed = true
	event.shift_pressed = true
	notebook._unhandled_key_input(event)

func run() -> void:
	var scene = build()
	var notebook = scene.get_node("Notebook")
	var pointer := Node3D.new()
	root.add_child(pointer)
	check(scene.points.size()==5,"Printed scene builds all five rows")
	check(scene.get_node_or_null("ReplayButton")!=null,"Printed scene retains the room's REPLAY control")
	scene.advance(10)
	check(scene.times==[0.0,0.0,0.0,0.0,0.0] and scene.ink.marks==[[],[],[],[],[]],"Idle scene does not advance or mark")
	scene.points[1].on_desktop_grab(pointer)
	scene._sync_hand()
	scene.advance(10)
	var baseline: Dictionary = scene.capture()
	check(baseline.seed==435 and baseline.distribution=="uniform","Baseline starts with the declared seed and distribution")
	check(baseline.seconds[1]==10 and baseline.ink[1].size()==96,"Row 2 takes ten seconds for eight steps / 96 marks")
	notebook.observation = "A timed scripted observation; no human sensation inferred."
	notebook.next_change = "Compare row 3 at the same number of steps."
	shortcut(notebook,KEY_K)
	var baseline_path: String = notebook.load_path
	recordings.append(baseline_path)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(baseline_path))
	var decoded = bytes_to_var(Marshalls.base64_to_raw(saved.record_bytes))
	check(decoded==baseline,"Save shortcut retains the entire active state exactly through the packed copy")
	check(saved.observation==notebook.observation and saved.next_change==notebook.next_change,"Question and observation travel with the saved state")
	check(scene.active_lane==1 and not scene.paused,"Saving does not stop or change the encounter")
	check(not notebook.load_trial() and scene.capture()==baseline,"Loading while held is refused without changing the current trial")
	scene.points[1].on_desktop_drop()
	scene._sync_hand()
	scene.advance(10)
	check(scene.ink.marks[1]==baseline.ink[1] and scene.times[1]==0,"Empty return resets phase without adding ink")
	scene.get_node("ReplayButton").pressed.emit()
	check(scene.ink.marks==[[],[],[],[],[]] and scene.record.points==baseline.points,"Visible REPLAY clears marks while retaining the path")
	notebook.condition = "comparison-row-3"
	scene.points[2].on_desktop_grab(pointer)
	scene._sync_hand()
	scene.advance(5)
	var comparison: Dictionary = scene.capture()
	var comparison_path: String = notebook.save_trial()
	recordings.append(comparison_path)
	check(comparison_path!=baseline_path and FileAccess.file_exists(baseline_path),"Each save keeps the earlier file")
	check(comparison.points==baseline.points and comparison.seed==baseline.seed,"Comparison uses exactly the same targets and seed")
	check(comparison.seconds[2]==5 and comparison.ink[2]==baseline.ink[1],"Twice the rate produces the identical eight-step ink in half the time")
	scene.points[2].on_desktop_drop()
	scene._sync_hand()
	scene.free()

	# A fresh instance built exclusively from the printed files reopens both recordings.
	scene = build()
	notebook = scene.get_node("Notebook")
	notebook.load_path = baseline_path
	shortcut(notebook,KEY_L)
	check(scene.paused and scene.active_lane==-1 and same_data(scene.capture(),baseline),"Fresh reconstruction reopens the complete baseline paused, without a hand")
	check(notebook.condition=="baseline-row-2" and notebook.observation==saved.observation,"Reopening restores notebook metadata too")
	scene.advance(3)
	check(same_data(scene.capture(),baseline),"A restored paused snapshot does not advance")
	shortcut(notebook,KEY_P)
	scene.advance(3)
	check(not scene.paused and same_data(scene.capture(),baseline),"Resume still waits for contact when no return was recorded")
	scene.points[1].on_desktop_grab(pointer)
	scene._sync_hand()
	scene.advance(1)
	check(scene.times[1]==11,"Recontact continues the stored phase")
	scene.points[1].on_desktop_drop()
	scene._sync_hand()
	notebook.load_path = comparison_path
	check(notebook.load_trial() and same_data(scene.capture(),comparison),"Fresh reconstruction can reopen the second condition")
	scene.get_node("ReplayButton").pressed.emit()
	scene.points[2].on_desktop_grab(pointer)
	scene._sync_hand()
	scene.advance(5)
	check(same_data(scene.capture(),comparison),"Replay from the beginning reconstructs the same saved five-second state")
	# Pausing releases the hand; that snapshot resumes an empty return, as documented.
	shortcut(notebook,KEY_P)
	var paused_return: Dictionary = scene.capture()
	check(scene.paused and scene.active_lane==-1 and paused_return.returning[2],"Pause releases the hand and records an empty return")
	var return_path: String = notebook.save_trial()
	recordings.append(return_path)
	scene.get_node("ReplayButton").pressed.emit()
	check(notebook.load_trial(),"Paused-return recording loads")
	shortcut(notebook,KEY_P)
	scene.advance(10)
	check(scene.times[2]==0 and not scene.returning[2] and scene.ink.marks==paused_return.ink,"Resuming a saved return completes it without adding ink")

	var bad = saved.duplicate(true)
	bad.record.rates[2] = 1.2
	bad.record_bytes = Marshalls.raw_to_base64(var_to_bytes(bad.record))
	var bad_path := "user://abacus-invalid-%d.json" % Time.get_ticks_usec()
	recordings.append(bad_path)
	var file := FileAccess.open(bad_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(bad,"",true,true))
	file.close()
	notebook.load_path = bad_path
	var before: Dictionary = scene.capture()
	check(not notebook.load_trial() and scene.capture()==before,"Changed rate recipe is refused without destroying current work")
	scene.free()
	pointer.free()
	for path in recordings:
		if not path.is_empty(): DirAccess.remove_absolute(path)
	await process_frame
	print("ABACUS PRINTED EXPERIMENT LOOP: ","PASS" if failures.is_empty() else "FAIL"," (",checks," checks)")
	quit(0 if failures.is_empty() else 1)
