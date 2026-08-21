extends SceneTree
## THE SPINE STRIP, proven against a TRIAL copy of the book: the strip lists
## the walk order, an edited line lands in the pearl's page as by:hand, the
## merge guard refuses to overwrite a line another hand changed on disk, a
## new line appends, DEL removes, and a travel writes the control file with
## the current view preserved. The real book is never touched.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_spine_strip.gd

const OUT := "res://ada_run/spine_strip_probe.txt"
const CTL := "res://ada_run/_doll_trial_control.json"
const BOOK := "res://ada_run/_trial_book"

func _initialize() -> void:
	call_deferred("_run")


func _read_point_lines() -> Array:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BOOK + "/primitives.json"))
	for pv in (doc.get("pearls", []) as Array):
		if String((pv as Dictionary).get("pearl", "")) == "point":
			return (pv as Dictionary).get("lines", [])
	return []


func _run() -> void:
	var fails: Array = []
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BOOK))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://commons/data/book/primitives.json"),
		ProjectSettings.globalize_path(BOOK + "/primitives.json"))
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 0}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")
	inst.set("_book_dir", BOOK)
	get_root().add_child(inst)
	await create_timer(1.2).timeout
	for i in range(200):
		if (inst.get("_stamp_queue") as Array).is_empty():
			break
		await process_frame

	inst.call("_spine_toggle")
	var slist: ItemList = inst.get("_spine_list")
	if slist == null or slist.item_count == 0:
		fails.append("the strip opened empty")
	var rows: Array = inst.get("_spine_rows")
	var point_i := -1
	for i in range(rows.size()):
		var r: Dictionary = rows[i]
		if String(r.get("chapter", "")) == "primitives" and String(r.get("pearl", "")) == "point":
			point_i = i
			break
	if point_i < 0:
		fails.append("the point pearl is not on the strip")
	else:
		inst.call("_spine_show_pearl", point_i)
		var snap: Array = inst.get("_spine_snapshot")
		var lines_ui: ItemList = inst.get("_spine_lines")
		if snap.is_empty():
			fails.append("point's page loaded no lines")
		elif lines_ui.item_count != snap.size() + 1:
			fails.append("lines pane shows %d rows for %d lines (+1 expected)" % [lines_ui.item_count, snap.size()])
		var n0: int = snap.size()

		# EDIT line 0 → the trial book
		inst.call("_spine_show_line", 0)
		(inst.get("_spine_edit") as TextEdit).text = "PROBE WROTE THIS"
		inst.call("_spine_save")
		var after: Array = _read_point_lines()
		if after.is_empty() or String((after[0] as Dictionary).get("text", "")) != "PROBE WROTE THIS":
			fails.append("the edit did not land in the book")
		elif String((after[0] as Dictionary).get("by", "")) != "hand":
			fails.append("the edited line is not by:hand")

		# THE MERGE GUARD: another hand moves the line on disk; our stale save
		# must be refused
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BOOK + "/primitives.json"))
		for pv in (doc.get("pearls", []) as Array):
			if String((pv as Dictionary).get("pearl", "")) == "point":
				(((pv as Dictionary).get("lines", []) as Array)[0] as Dictionary)["text"] = "MOVED BY ANOTHER HAND"
		var fg := FileAccess.open(BOOK + "/primitives.json", FileAccess.WRITE)
		fg.store_string(JSON.stringify(doc, " ") + "\n")
		fg.close()
		inst.call("_spine_show_line", 0)   # pane still holds its old snapshot
		(inst.get("_spine_edit") as TextEdit).text = "SECOND TRY"
		inst.call("_spine_save")
		var guarded: Array = _read_point_lines()
		if String((guarded[0] as Dictionary).get("text", "")) != "MOVED BY ANOTHER HAND":
			fails.append("the merge guard let a stale save overwrite another hand's line")

		# ADD a line (reopen first — the guard told us to)
		inst.call("_spine_show_pearl", point_i)
		inst.call("_spine_new_line")
		(inst.get("_spine_edit") as TextEdit).text = "A NEW POEM FOR THE PROBE"
		(inst.get("_spine_token") as LineEdit).text = "origin"
		inst.call("_spine_save")
		var added: Array = _read_point_lines()
		if added.size() != n0 + 1:
			fails.append("the new line did not append (%d -> %d)" % [n0, added.size()])
		elif String((added[added.size() - 1] as Dictionary).get("text", "")) != "A NEW POEM FOR THE PROBE":
			fails.append("the appended line carries the wrong text")

		# DEL removes it again
		inst.call("_spine_show_pearl", point_i)
		var lines_ui2: ItemList = inst.get("_spine_lines")
		lines_ui2.select(added.size() - 1)
		lines_ui2.grab_focus()
		inst.call("_spine_del_line")
		if _read_point_lines().size() != n0:
			fails.append("DEL did not remove the appended line")

		# TRAVEL writes the control file, view preserved (walk here)
		inst.call("_spine_travel", point_i)
		var ctl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CTL))
		if String(ctl.get("first_chapter", "")) != "primitives":
			fails.append("travel did not write the chapter")
		if int(ctl.get("dollhouse", -1)) != 0:
			fails.append("travel forgot which view it was made from")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOOK + "/primitives.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOOK))
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f3.close()
	print("SPINE STRIP: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
