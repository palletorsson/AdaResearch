extends SceneTree
## Pressing Play must use the plan. The scene carries plan_file, so a run with
## NO command line reads ada_run/em_plan.json — the fault that made every plan
## edit invisible ("still no change when I run endless_museum.tscn").
## GATE: clearing plan_file gives back v1 pool dealing, and it SAYS so.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_plan_default.gd
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var a: Node3D = ps.instantiate() as Node3D
	get_root().add_child(a)                     # no flags at all
	await create_timer(1.5).timeout
	if String(a.get("_plan_path")) == "":
		fails.append("BITE: a plain run has no plan path")
	if (a.get("_plan_by_chapter") as Dictionary).is_empty():
		fails.append("BITE: a plain run loaded no plan rows")
	var hand := 0
	for r in (a.get("_edit_records") as Array):
		var tc: Array = (r as Dictionary).get("tile_cell", [])
		if String((r as Dictionary).get("token", "")) == "fontana_puncture" and tc.size() >= 2:
			hand += 1
	get_root().remove_child(a); a.queue_free()
	await create_timer(0.3).timeout
	var b: Node3D = ps.instantiate() as Node3D
	b.set("plan_file", "")                      # the opt-out
	get_root().add_child(b)
	await create_timer(1.5).timeout
	if String(b.get("_plan_path")) != "":
		fails.append("GATE: clearing plan_file still loaded a plan")
	get_root().remove_child(b); b.queue_free()
	if fails.is_empty(): print("EM PLAN DEFAULT: PASS — Play uses the plan; clearing plan_file gives back pool dealing")
	else:
		print("EM PLAN DEFAULT: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
