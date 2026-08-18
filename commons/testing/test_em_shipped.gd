extends SceneTree
## GATE: the museum finds its plan, bake and control through the SHIPPED
## copies (commons/data/museum/) when ada_run/ is absent — the export case.
## Simulated by pointing the plan at a path that does not exist under
## ada_run/ but does under the shipped dir.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var why: Array = []
	if not FileAccess.file_exists("res://commons/data/museum/em_plan.json"): why.append("no shipped plan — run python tools/em_ship.py")
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	# an ada_run path that does not exist; the same basename exists in the shipped dir
	m.set("_plan_path", "res://ada_run/_missing_/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var resolved: String = String(m.get("_plan_path"))
	if not resolved.begins_with("res://commons/data/museum/"): why.append("plan did not fall back to the shipped copy: %s" % resolved)
	if not bool(m.get("_replay")): why.append("bake did not load (replay off)")
	var built: Array = m.get("_built")
	if built.is_empty(): why.append("nothing built")
	elif String((built[0] as Dictionary).get("pearl", "")) == "": why.append("segment 0 has no pearl — the plan was not read")
	print("EM SHIPPED: plan=%s replay=%s seg0=%s/%s" % [resolved, m.get("_replay"), (built[0] as Dictionary).get("chapter", "?") if not built.is_empty() else "?", (built[0] as Dictionary).get("pearl", "?") if not built.is_empty() else "?"])
	for w in why: print("EM SHIPPED: " + String(w))
	print("EM SHIPPED: %s" % ("PASS" if why.is_empty() else "FAIL"))
	quit(0 if why.is_empty() else 1)
