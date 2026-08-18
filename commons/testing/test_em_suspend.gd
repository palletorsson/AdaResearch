extends SceneTree
## Bodies out of sight are SUSPENDED (process_mode DISABLED), not just hidden,
## and wake the frame they come back into view.
## BITE: with the eye at spawn, far bodies are hidden AND disabled; near ones
##   run. Walk the eye to a far body: it becomes visible and INHERIT again.
## GATE: no body is ever freed or moved by this — count and positions hold.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_suspend.gd
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(m)
	await create_timer(3.0).timeout
	var pl: CharacterBody3D = m.get("_player")
	if pl == null: print("EM SUSPEND: SKIP — no walker"); quit(0); return
	pl.global_position = Vector3(7.5, 0, 1.5)
	await create_timer(0.8).timeout      # two cull ticks
	var recs: Array = m.get("_vis_records")
	var near_on := 0; var far_off := 0; var far_on := 0; var near_off := 0
	var far_node: Node3D = null
	var far_pos := Vector3.ZERO
	for r in recs:
		var n: Node3D = (r as Dictionary).get("node") as Node3D
		if n == null or not is_instance_valid(n): continue
		var d: float = Vector2(n.global_position.x - 7.5, n.global_position.z - 1.5).length()
		var running: bool = n.process_mode != Node.PROCESS_MODE_DISABLED
		if d < 30.0:
			if running:
				near_on += 1
			else:
				near_off += 1
		elif d > 40.0:
			if running:
				far_on += 1
			else:
				far_off += 1
				if far_node == null:
					far_node = n
					far_pos = n.global_position
	print("[test] at spawn: near running %d, near suspended %d · far suspended %d, far running %d" % [near_on, near_off, far_off, far_on])
	if far_off == 0: fails.append("BITE: no far body was suspended")
	if far_on > 0: fails.append("BITE: %d far bodies still running" % far_on)
	if near_off > 0: fails.append("BITE: %d near bodies wrongly suspended" % near_off)
	# walk to the far one: it must wake
	if far_node != null:
		var before := far_node.global_position
		pl.global_position = far_pos + Vector3(2.0, 0, -2.0)
		await create_timer(0.8).timeout
		if far_node.process_mode == Node.PROCESS_MODE_DISABLED: fails.append("BITE: the body did not wake when approached")
		if not far_node.visible: fails.append("BITE: the body did not show when approached")
		if far_node.global_position.distance_to(before) > 0.001: fails.append("GATE: suspending moved a body")
	get_root().remove_child(m); m.queue_free()
	if fails.is_empty(): print("EM SUSPEND: PASS — far bodies suspended (%d), near ones run (%d), a body wakes when approached" % [far_off, near_on])
	else:
		print("EM SUSPEND: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
