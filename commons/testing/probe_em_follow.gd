extends SceneTree
## ONE ENDLESS MUSEUM, proven headless: (a) a resume_eye in em_control stands
## the walker at the nearest walkable cell and is CONSUMED; (b) touching
## em_plan.json on disk arms the follow, and the settle window fires it (the
## reload itself is guarded off under a probe — current_scene is null — so
## the pending flag falling is the proof the trigger ran).
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_em_follow.gd

const OUT := "res://ada_run/em_follow_probe.txt"
const CTL := "res://ada_run/em_control.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var ctl_before := FileAccess.get_file_as_string(CTL)
	# ── (a) the resume ───────────────────────────────────────────────────────
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "",
		"resume_eye": [7.5, 0.0, 21.0], "resume_yaw": 1.57}, " "))
	f.close()
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	await create_timer(0.5).timeout
	var pl: CharacterBody3D = inst.get("_player")
	if pl == null:
		fails.append("no player")
	else:
		var dz: float = absf(pl.position.z - 21.0)
		if dz > 3.0:
			fails.append("resume missed: stood at z %.1f, asked 21.0" % pl.position.z)
		if absf(float(inst.get("_yaw")) - 1.57) > 0.05:
			fails.append("resume yaw not applied (_yaw %.2f)" % float(inst.get("_yaw")))
	var ctl_after: Variant = JSON.parse_string(FileAccess.get_file_as_string(CTL))
	if ctl_after is Dictionary and (ctl_after as Dictionary).has("resume_eye"):
		fails.append("resume_eye was not consumed — every fresh launch would teleport")
	# ── (b) the watcher ──────────────────────────────────────────────────────
	for i in range(3):
		await create_timer(1.0).timeout   # first checks adopt the baseline mtime
	var plan_txt := FileAccess.get_file_as_string("res://ada_run/em_plan.json")
	var f2 := FileAccess.open("res://ada_run/em_plan.json", FileAccess.WRITE)
	f2.store_string(plan_txt)
	f2.close()
	var armed := false
	for i in range(8):
		await create_timer(1.0).timeout
		if bool(inst.get("_follow_pending")):
			armed = true
			break
	if not armed:
		fails.append("touching the plan never armed the follow")
	var fired := false
	for i in range(8):
		await create_timer(1.0).timeout
		if not bool(inst.get("_follow_pending")):
			fired = true
			break
	if armed and not fired:
		fails.append("the follow armed but never fired after the settle window")
	# restore the control file exactly
	var f3 := FileAccess.open(CTL, FileAccess.WRITE)
	f3.store_string(ctl_before)
	f3.close()
	var f4 := FileAccess.open(OUT, FileAccess.WRITE)
	f4.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f4.close()
	if fails.is_empty():
		print("EM FOLLOW: PASS — resume stands the walker and is consumed; a plan touch arms and fires the follow")
	else:
		print("EM FOLLOW: FAIL %d" % fails.size())
		for x in fails:
			print("  - " + str(x))
	quit(0 if fails.is_empty() else 1)
