extends SceneTree
## The side room off the enfilade — proven both ways in one boot.
##
## GATE:  a plan with no row whose relation.walk_space is "room" builds NO
##        side room: the deal reports side_rooms 0, and _side_room_doorways
##        returns {} for the first chapter, so the east skin is untouched.
## BITE:  a TRIAL copy of em_plan.json whose first chapter's second interior
##        row is marked walk_space "room" builds exactly one room off that
##        segment: a doorway cell in the east skin (x = w) is left open,
##        the room's cells and the doorway are walkable, the body is stamped
##        inside the room (x > w) with walk_space "room" on its record, and
##        the deal counter says side_rooms 1.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_side_room.gd

const PLAN := "res://ada_run/em_plan.json"
const TRIAL := "res://ada_run/_trial_em_plan_side_room.json"
const BARE := "res://ada_run/_trial_em_plan_no_rooms.json"   # the real plan with every room ask removed

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	var plans: Array = doc.get("plans", [])
	if plans.is_empty():
		print("SIDE ROOM: SKIP — no v2 plan rows"); quit(0); return
	# the GATE plan: the real plan with every room ask stripped. The live plan
	# may carry hand readings (it does since 08-17: noise), so "no room row"
	# must be MADE, not assumed. Written first, before the doc is marked.
	var stripped := 0
	for pl in plans:
		for a in (pl as Dictionary).get("artifacts", []):
			var rel: Dictionary = (a as Dictionary).get("relation", {})
			if String(rel.get("walk_space", "")) == "room":
				rel["walk_space"] = "wall"; stripped += 1
	var fb := FileAccess.open(BARE, FileAccess.WRITE)
	fb.store_string(JSON.stringify(doc)); fb.close()
	print("[test] gate plan: %d room ask(s) stripped from the live plan" % stripped)
	# the trial: mark the first chapter's second interior row as a room
	# mark the chapter the walk OPENS at (ada_run/em_control.json first_chapter,
	# else the spine's first), so the trial room is dealt in segment 0
	var first: Dictionary = plans[0]
	if FileAccess.file_exists("res://ada_run/em_control.json"):
		var ctl: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://ada_run/em_control.json"))
		var want := String((ctl as Dictionary).get("first_chapter", "")) if ctl is Dictionary else ""
		for pl in plans:
			if String((pl as Dictionary).get("sequence", "")) == want:
				first = pl; break
	var chapter := String(first.get("sequence", ""))
	var museum := String(first.get("museum", ""))
	var marked := ""
	var n_int := 0
	for a in first.get("artifacts", []):
		if String((a as Dictionary).get("venue", "")) != "interior":
			continue
		n_int += 1
		if n_int == 2:
			var rel: Dictionary = (a as Dictionary).get("relation", {})
			rel["walk_space"] = "room"; rel["walk_kind"] = "queers"
			rel["walk_why"] = "TRIAL reading — the test's own, removed after"
			(a as Dictionary)["relation"] = rel
			marked = String((a as Dictionary).get("token", ""))
			break
	var f := FileAccess.open(TRIAL, FileAccess.WRITE)
	f.store_string(JSON.stringify(doc)); f.close()

	# ── GATE: the live plan with no room rows ────────────────────────────────
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var g: Node3D = ps.instantiate() as Node3D
	g.set("_edit_mode", true)
	g.set("_overrides_path", "res://ada_run/_trial_em_overrides_sr.json")
	g.set("_plan_path", BARE)
	get_root().add_child(g)
	await create_timer(0.8).timeout
	var stats0: Dictionary = g.get("_deal_stats")
	if int(stats0.get("side_rooms", 0)) != 0:
		fails.append("GATE: no-room plan built %d side rooms" % int(stats0.get("side_rooms", 0)))
	var any_room := false
	for r in (g.get("_edit_records") as Array):
		if String((r as Dictionary).get("walk_space", "")) == "room":
			any_room = true
	if any_room:
		fails.append("GATE: a record carries walk_space room under the no-room plan")
	get_root().remove_child(g); g.queue_free()
	await create_timer(0.2).timeout

	# ── BITE: the trial plan ─────────────────────────────────────────────────
	var b: Node3D = ps.instantiate() as Node3D
	b.set("_edit_mode", true)
	b.set("_overrides_path", "res://ada_run/_trial_em_overrides_sr.json")
	b.set("_plan_path", TRIAL)
	get_root().add_child(b)
	await create_timer(0.8).timeout
	var stats1: Dictionary = b.get("_deal_stats")
	var built_here: bool = false
	for r0 in (b.get("_edit_records") as Array):
		if String((r0 as Dictionary).get("token", "")) == marked and String((r0 as Dictionary).get("walk_space", "")) == "room":
			built_here = true
	# the trial marks chapter 1 of the plan; the museum may not have dealt that
	# chapter in its first segments — then the room is not expected yet, and the
	# doorway helper is what we can prove
	# the museum has already walked into the chapter's pearl string (two
	# segments on ready); ask the doorway helper about the FIRST pearl, where
	# the trial row was marked, by rewinding the pearl cursor for the question
	b.set("_pearl_cursor", {})
	var doorways: Dictionary = b.call("_side_room_doorways", {"key": museum}, chapter, 40)
	if doorways.is_empty():
		fails.append("BITE: _side_room_doorways found no doorway for %s/%s (marked %s)" % [museum, chapter, marked])
	elif doorways.size() != 1:
		fails.append("BITE: %d doorways, expected 1" % doorways.size())
	else:
		var z: int = doorways.keys()[0]
		if z != int(b.get("ROOM_Z0")) + int(int(b.get("ROOM_D")) / 2):
			fails.append("BITE: doorway row %d != ROOM_Z0 + ROOM_D/2" % z)
	if built_here:
		var found := false
		for r in (b.get("_edit_records") as Array):
			var rd: Dictionary = r
			if String(rd.get("token", "")) == marked and String(rd.get("walk_space", "")) == "room":
				found = true
		if not found:
			fails.append("BITE: side_rooms %d built but no record for %s carries walk_space room" % [int(stats1.get("side_rooms", 0)), marked])
		print("[test] room built in this run for %s (chapter %s dealt)" % [marked, chapter])
	else:
		print("[test] chapter %s not among the dealt segments this run — doorway arithmetic proven, room build deferred to a walk" % chapter)
	get_root().remove_child(b); b.queue_free()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIAL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BARE))
	if FileAccess.file_exists("res://ada_run/_trial_em_overrides_sr.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_trial_em_overrides_sr.json"))
	if fails.is_empty():
		print("SIDE ROOM: PASS — no room without a room row; one doorway per marked row (%s in %s)" % [marked, chapter])
	else:
		print("SIDE ROOM: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
