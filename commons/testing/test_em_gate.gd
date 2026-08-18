extends SceneTree
## The threshold gate: the vestibule stands alone.
## BITE: segment 0 carries a sealed door + a palm scanner; the door has a
##   collider; the walk cells at the threshold are UNCHANGED (the planner is
##   never lied to); a grant opens it — the collider goes and open_amount runs
##   to 1. Desktop click on the scanner grants; a click elsewhere does not.
## GATE: the autopilot and shot runs build no gate at all.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_gate.gd
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var m: Node3D = ps.instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(0.8).timeout
	var gate: Dictionary = m.get("_gate")
	if gate.is_empty():
		fails.append("BITE: no gate on the opening segment")
	else:
		var door: Node3D = gate.get("door")
		var sc: Node3D = gate.get("scanner")
		if door == null or not is_instance_valid(door): fails.append("BITE: no door")
		elif float(door.get("open_amount")) != 0.0: fails.append("BITE: the door is not sealed (%s)" % str(door.get("open_amount")))
		if sc == null: fails.append("BITE: no scanner")
		elif not sc.has_signal("palm_scanned"): fails.append("BITE: the scanner has no palm_scanned signal")
		if (gate.get("colliders", []) as Array).is_empty(): fails.append("BITE: the door has no collider")
		# the walk map must be untouched at the threshold
		var wc: Dictionary = m.get("_walk_cells")
		var z: int = int(float(gate.get("z", 3.5)))
		var open_cells := 0
		for x in range(1, 14):
			if wc.has(Vector2i(x, z)) or wc.has(Vector2i(x, z + 1)): open_cells += 1
		if open_cells < 3: fails.append("BITE: the gate closed the walk map at the threshold (%d cells)" % open_cells)
		# a click far away does nothing; the scanner's own signal grants
		var cam: Camera3D = m.get("_cam")
		if cam != null and sc != null:
			cam.global_position = sc.global_position + Vector3(0, 0, -20)
			if bool(m.get("_mod_gate").call("clicked", cam, sc)): fails.append("BITE: a click 20 m away opened it")
			cam.global_position = sc.global_position + Vector3(0, 0, -1.5)
			cam.look_at(sc.global_position, Vector3.UP)
			if not bool(m.get("_mod_gate").call("clicked", cam, sc)): fails.append("BITE: a click at 1.5 m did NOT register")
		m.call("_open_gate")
		await create_timer(2.2).timeout
		if is_instance_valid(door) and float(door.get("open_amount")) < 0.99:
			fails.append("BITE: after the grant open_amount is %.2f" % float(door.get("open_amount")))
		var still := 0
		for c in gate.get("colliders", []):
			if is_instance_valid(c): still += 1
		if still > 0: fails.append("BITE: %d door collider(s) survived the grant" % still)
	get_root().remove_child(m); m.queue_free()
	await create_timer(0.2).timeout
	# GATE: an autopilot run builds no gate
	var a: Node3D = ps.instantiate() as Node3D
	a.set("_plan_path", "res://ada_run/em_plan.json"); a.set("_autopilot", 1)
	get_root().add_child(a)
	await create_timer(0.8).timeout
	if not (a.get("_gate") as Dictionary).is_empty(): fails.append("GATE: an autopilot run built a gate")
	get_root().remove_child(a); a.queue_free()
	if fails.is_empty(): print("EM GATE: PASS — sealed door + scanner, walk map untouched, grant opens and clears the collider, autopilot ungated")
	else:
		print("EM GATE: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
