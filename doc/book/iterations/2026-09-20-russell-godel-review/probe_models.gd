extends SceneTree
const OUT := "res://doc/book/iterations/2026-09-20-russell-godel-review/"
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void: checks.append({"ok":ok,"message":message})
func run() -> void:
	var bench: Node = load("res://commons/artifacts/russell_paradox_workbench/russell_paradox_workbench.tscn").instantiate()
	bench.apply_grid_config({"membership_controls":"on","initial_cell":5})
	root.add_child(bench)
	bench.set_process(false)
	await process_frame
	check(bench._cell==4 and bench._membership_buttons!=null,"pre-ready configuration starts at unrestricted question")
	check(bench._attempt==-1 and not bench._arrows_visible,"question precedes the animated contradiction")
	for choice in [true,false]:
		var button: Node=bench._membership_buttons.get_node(("IN" if choice else "OUT")+"/InteractableAreaButton")
		button.button_pressed.emit(null)
		check(bench._attempt==int(choice),"physical button forwards assumed answer %s"%choice)
		check(not bench._last_result.agrees and bench._arrows_visible,"unrestricted answer %s contradicts itself"%choice)
	# Independent finite set oracle: bitmask i encodes the elements of ordinal i.
	var ordinals: Array[int] = [0,1,3,7]
	var kept: Array[int]=[]
	for i in 4:
		if (ordinals[i] & (1<<i))==0: kept.append(i)
	check(bench.restricted_members()==kept,"finite filter agrees with independent bitmask membership")
	check(not ordinals.has(15),"result mask 1111 is not a member of the four-element domain")
	bench._slider.set_normalized_value(1.0)
	bench._slider.slider_moved.emit(1.0)
	bench._process(0.2)
	check(bench._cell==5 and bench._attempt==-1,"physical slider reaches restricted case and resets prediction")
	for choice in [true,false]:
		bench._membership_buttons.get_node(("IN" if choice else "OUT")+"/InteractableAreaButton").button_pressed.emit(null)
		check(bench._last_result.agrees==not choice,"restricted case accepts OUT only")
		check(not bench._arrows_visible and bench._zfc_card_alpha_t==1.0,"restricted case stops contradiction orbit and explains domain")
	bench._slider.set_normalized_value(0.8)
	bench._slider.slider_moved.emit(0.8)
	bench._process(0.2)
	check(bench._cell==4 and bench._attempt==-1 and bench._zfc_card_alpha_t==0.0,"return hides explanation and asks afresh")
	for i in 6:
		bench._apply_cell(i)
		check(bench._cell==i and bench._membership_buttons.visible==(i>=4),"definition %d shows appropriate controls"%(i+1))
		if i==3: check(bench._dot_root.get_child_count()==0,"Foundation example is empty, not a fictitious self-member")
	var count: int=bench.get_child_count()
	for i in 10: bench.apply_grid_config({"membership_controls":"on","initial_cell":5+i%2})
	await process_frame
	check(bench.get_child_count()==count and bench._membership_buttons.get_child_count()==4,"reconfiguration does not duplicate controls")
	var legacy: Node=load("res://commons/artifacts/russell_paradox_workbench/russell_paradox_workbench.tscn").instantiate()
	root.add_child(legacy)
	check(legacy._membership_buttons==null,"other placements have no added buttons unless enabled")
	legacy._apply_cell(4)
	check(legacy._arrows_visible,"legacy slider still illustrates Russell contradiction")
	legacy._apply_cell(5)
	check(legacy._last_result.agrees and not legacy._arrows_visible,"legacy sixth cell now illustrates separation")
	var failures: Array=[]
	for row in checks:
		if not row.ok: failures.append(row.message)
	var f=FileAccess.open(OUT+"model-checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));f.close()
	print("RUSSELL_MODELS ",checks.size()," checks; failures ",failures)
	for i in 6: await process_frame
	bench.free();legacy.free()
	quit(0 if failures.is_empty() else 1)
