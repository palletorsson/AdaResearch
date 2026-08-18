extends SceneTree
## The museum streams as the eye advances — the VR complaint, tested with a
## moving eye rather than a headset: walk the desktop walker forward 400 m and
## count the segments that open. Also proves the gate never stops the stream.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_stream.gd
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(2.0).timeout
	var pl: CharacterBody3D = m.get("_player")
	if pl == null: print("EM STREAM: SKIP — no walker"); quit(0); return
	var built0: int = (m.get("_segments") as Array).size()
	var seen: Array = []
	for step in range(40):
		pl.global_position.z += 12.0          # teleport the eye forward, 12 m a step
		await process_frame
		await process_frame
		var n: int = int(m.get("_seg_index"))
		if not seen.has(n):
			seen.append(n)
		if step % 8 == 0:
			print("[probe] step %2d eye z=%.0f next_z=%.0f segs=%d built=%d" % [step,
				pl.global_position.z, float(m.get("_next_z")), (m.get("_segments") as Array).size(), n])
	var built: int = int(m.get("_seg_index"))
	var gate: Dictionary = m.get("_gate")
	print("[test] eye walked to z=%.0f · segments opened: %d (from %d) · gate %s" % [
		pl.global_position.z, built, built0, "open/none" if gate.is_empty() else "SEALED"])
	if built < 5:
		fails.append("only %d segment(s) opened over 480 m — the museum did not stream" % built)
	if not gate.is_empty():
		fails.append("the gate is still sealed after the walk — it can block a visitor")
	get_root().remove_child(m); m.queue_free()
	if fails.is_empty(): print("EM STREAM: PASS — %d segments opened as the eye advanced" % built)
	else:
		print("EM STREAM: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
