extends "res://tools/probes/sine_yoke.gd"
## Focused evidence: no fabricated successes or Cannon/Jolt equivalence.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -18.1;scene.add_child(ground);var hit := CollisionShape3D.new();hit.shape = BoxShape3D.new();hit.shape.size = Vector3(60,.2,30);ground.add_child(hit)
	var Script: GDScript = load("res://commons/artifacts/matter_reference/thresholds.gd")
	if Script.reload()!=OK:quit(1);return
	var work := Node3D.new();work.set_script(Script);work.apply_grid_config({"threshold":"almost","parts":{"TakeLedger":{"position":[2.4,1.1,2],"rotation":[0,15,0]}}});work.position.y = -18;work.rotation.y = .37;scene.add_child(work);await tick(4)
	check("new witness ledger preserves its edited pose",work.get_node("TakeLedger").position.is_equal_approx(Vector3(2.4,1.1,2)) and absf(work.get_node("TakeLedger").rotation_degrees.y-15)<.01)
	work.adjust_height(.001);check("one millimetre adjusts actual release centre using source equation",absf(work.local_position(work.graph.refs.ball).y-1.047)<.00001 and absf(work.graph.params.h-1.047)<.00001)
	work.release_take()
	for n in 2500:
		if not work.running:break
		await tick()
	check("high-water witness follows measured actual maximum",work.result>=0 and work.maximum>0 and absf(work.high_mark.position.y-work.maximum)<.00001)
	check("finished take records measured reading and selected height",work.take_history.size()==1 and absf(work.take_history[0].reading.setting.h-1.047)<.00001 and work.take_history[0].reading.finished)
	var maximum: float = work.maximum;work.repeat_take();check("repeat clears current witness but retains completed comparison",work.running and work.maximum<0 and work.take_history.size()==1)
	for n in 2500:
		if not work.running:break
		await tick()
	check("repeat measures another run instead of copying its first reading",work.take_history.size()==2 and work.maximum>0 and absf(work.maximum-maximum)<.03)
	work.adjust_height(9);check("height fine control clamps to source maximum",is_equal_approx(work.release_height,1.12));work.adjust_height(-9);check("height fine control clamps to source minimum",is_equal_approx(work.release_height,.98))
	work.queue_free();await tick(4)
	work = Node3D.new();work.set_script(Script);work.apply_grid_config({"threshold":"just"});work.position.y = -18;scene.add_child(work);await tick(4);work.release_take()
	await tick(900);check("manual balance waits without silently feeding grains",work.running and work.grain_ids.is_empty() and work.feed_ready)
	for n in 5:work.request_grain()
	await tick(3);check("repeated feed clicks queue one physical grain",work.grain_ids.size()==1 and not work.grain_requested)
	for n in 1200:
		if work.feed_ready or not work.running:break
		await tick()
	check("new grain is counted only after actual landing",work.grain_count()==5 and work.feed_ready and work.result<0)
	work.request_grain()
	for n in 1500:
		if not work.running:break
		await tick()
	check("sixth physical grain tips the balance at native source default",work.result==1 and work.reading.grains==6 and work.take_history.size()==1)
	check("human-readable ledger retains actual grain margin",work.take_history[0].reading.margin>0 and not work.ledger_text.text.contains("position"))
	work.reset_take();check("reset removes added grains but keeps comparison",work.grain_ids.is_empty() and work.take_history.size()==1 and not work.grain_requested)
	work.toggle_feeding();check("automatic source feeding is an explicit selected mode",work.auto_feed and work.pending.auto_feed)
	work.queue_free();await tick(4)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Actual Jolt mechanisms at negative elevation and a rotated Almost placement. Source-equation millimetre release, measured high-water mark/history, manual single-grain balance and explicit optional automatic feeding. No cross-engine threshold guarantee or physical-headset claim."}
	FileAccess.open(out.path_join("threshold-workshop-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
