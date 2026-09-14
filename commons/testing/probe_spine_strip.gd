extends SceneTree
## THE SPINE STRIP under the new contract — the web is the editor: the strip
## lists the walk order and the open pearl's lines, the URL builder aims at
## chapter · pearl · token, the watcher folds a disk-side (web) save into the
## open pane within a tick, O's focus resolver finds the held body or the
## nearest artifact to the eye, and a travel writes the control file with the
## current view preserved. Runs against a TRIAL copy of the book and a trial
## control file — the real ones are never touched, and the probe checks that.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_spine_strip.gd
##
## REPAIRED 2026-09-14 (Palle: "fix the spine strip probe"). Written 2026-08-21; four things
## moved under it:
## - the plan names a map-authored hall for its map ("point one", Point_One) while the book
##   keeps its short name ("point"): the probe looked for "point" on the strip and found
##   nothing, and the strip itself could not open the book's page — a museum bug, fixed with
##   the probe (EM::_book_pearl_is, the same bridge EM::_speak_for uses for wall text)
## - the book watch moved into EM::_edit_watch (2026-08-26): _spine_mtime is write-only,
##   the baseline to force is _edit_watch_mt[path], and a refresh re-opens the strip's
##   SELECTED row, so the row is selected the way a click would
## - a control file ranks below the scene's Inspector start_chapter; the trial control is a
##   one-shot travel so the museum really opens in primitives
## - a travel now writes first_map and travel: 1 as well

const Evidence := preload("res://commons/testing/evidence_root.gd")
const CTL := "res://ada_run/_doll_trial_control.json"
const BOOK := "res://ada_run/_trial_book"
const REAL_CTL := "res://ada_run/em_control.json"
const TRIAL_OVERRIDES := "res://ada_run/_doll_trial_overrides.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var real_before := FileAccess.get_file_as_string(REAL_CTL) if FileAccess.file_exists(REAL_CTL) else ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BOOK))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://commons/data/book/primitives.json"),
		ProjectSettings.globalize_path(BOOK + "/primitives.json"))
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "Point_One", "travel": 1, "dollhouse": 0}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", TRIAL_OVERRIDES)
	inst.set("_book_dir", BOOK)
	get_root().add_child(inst)
	await create_timer(1.2).timeout
	for i in range(200):
		if (inst.get("_stamp_queue") as Array).is_empty():
			break
		await process_frame
	if String(inst.get("_first_chapter")) != "primitives":
		fails.append("the trial travel did not open primitives (opened %s)" % inst.get("_first_chapter"))

	# the URL builder is pure and exact
	var url := String(inst.call("_web_url", "primitives", "point", "you_are_here"))
	if url != "http://localhost:3003/lines?chapter=primitives&pearl=point&token=you_are_here":
		fails.append("the web url is wrong: " + url)
	if String(inst.call("_web_url", "primitives", "point", "")).contains("token"):
		fails.append("an empty token leaked into the url")

	# THE BRIDGE: a book pearl answers to its own name and to its map's name, and no other
	var point_page := {"pearl": "point", "map": "Point_One"}
	if not bool(inst.call("_book_pearl_is", point_page, "point")):
		fails.append("a book pearl does not answer to its own name")
	if not bool(inst.call("_book_pearl_is", point_page, "point one")):
		fails.append("a book pearl does not answer to its map's name (point one)")
	if bool(inst.call("_book_pearl_is", {"pearl": "lines", "map": "Point_Lines"}, "point one")):
		fails.append("the bridge matched the wrong pearl (lines for point one)")

	inst.call("_spine_toggle")
	var slist: ItemList = inst.get("_spine_list")
	if slist == null or slist.item_count == 0:
		fails.append("the strip opened empty")
	var rows: Array = inst.get("_spine_rows")
	var point_i := -1
	for i in range(rows.size()):
		var r: Dictionary = rows[i]
		if String(r.get("chapter", "")) == "primitives" and String(r.get("map", "")) == "Point_One":
			point_i = i
			break
	if point_i < 0:
		fails.append("Point_One's pearl is not on the strip")
	else:
		slist.select(point_i)                     # what a click does before item_selected
		inst.call("_spine_show_pearl", point_i)
		var snap: Array = inst.get("_spine_snapshot")
		var lines_ui: ItemList = inst.get("_spine_lines")
		var cur: Dictionary = inst.get("_spine_cur")
		if snap.is_empty():
			fails.append("Point_One's page loaded no lines (the strip row is '%s', the book says 'point')" % String((rows[point_i] as Dictionary).get("pearl", "")))
		elif lines_ui.item_count != snap.size():
			fails.append("lines pane shows %d rows for %d lines (no editor rows expected)" % [lines_ui.item_count, snap.size()])
		if String(cur.get("pearl", "")) != "point":
			fails.append("the open pearl does not carry the book's name for /lines (%s)" % cur.get("pearl"))

		# THE WATCHER: a save made in the web editor lands in the open pane within a
		# tick. mtime has 1 s grain, so the baseline the watcher compares against is
		# forced old.
		var docw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BOOK + "/primitives.json"))
		for pv in (docw.get("pearls", []) as Array):
			if String((pv as Dictionary).get("pearl", "")) == "point":
				(((pv as Dictionary).get("lines", []) as Array)[0] as Dictionary)["text"] = "HOT FROM THE WEB"
		var fw := FileAccess.open(BOOK + "/primitives.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(docw, " ") + "\n")
		fw.close()
		var watch_mt: Dictionary = inst.get("_edit_watch_mt")
		watch_mt[BOOK + "/primitives.json"] = 1
		await create_timer(1.5).timeout
		var snapw: Array = inst.get("_spine_snapshot")
		if snapw.is_empty() or String((snapw[0] as Dictionary).get("text", "")) != "HOT FROM THE WEB":
			fails.append("the watcher did not reload the web editor's save")

		# TRAVEL writes the control file, view preserved (walk here). The probe's museum
		# is not the tree's current scene, so the travel writes and does not reload.
		inst.call("_spine_travel", point_i)
		var ctl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CTL))
		if String(ctl.get("first_chapter", "")) != "primitives":
			fails.append("travel did not write the chapter")
		if String(ctl.get("first_map", "")) != "Point_One":
			fails.append("travel did not write the map")
		if int(ctl.get("travel", 0)) != 1:
			fails.append("travel did not mark itself (travel: 1), so the Inspector would outrank it")
		if int(ctl.get("dollhouse", -1)) != 0:
			fails.append("travel forgot which view it was made from")

	inst.call("_spine_toggle")   # close, so the focus test stands in the walk

	# O'S FOCUS: held body first, else the nearest artifact to the eye
	var records: Array = inst.get("_edit_records")
	var near := -1
	for i in range(records.size()):
		var nd: Node3D = _rec_node(records[i])
		if nd != null and nd.global_position.z > 6.0:
			near = i
			break
	if near < 0:
		fails.append("no artifact to focus")
	else:
		var nd2: Node3D = _rec_node(records[near])
		var pl: CharacterBody3D = inst.get("_player")
		pl.position = Vector3(nd2.global_position.x + 0.5, 0.0, nd2.global_position.z)
		inst.set("_edit_sel", -1)
		var got: int = int(inst.call("_web_focus_record"))
		if got < 0:
			fails.append("the focus resolver found nothing beside a body")
		else:
			var gn: Node3D = _rec_node(records[got])
			if gn == null or Vector2(gn.global_position.x - pl.position.x, gn.global_position.z - pl.position.z).length() > 8.0:
				fails.append("the focus resolver picked a body out of reach")
			# what O would open: the hall's plan name bridged to the book's pearl name
			var target: Dictionary = inst.call("_web_focus_target", got)
			var bk: Dictionary = inst.call("_book_pearl", String(target.get("chapter", "")), String(target.get("pearl", "")))
			if String(target.get("chapter", "")) == "primitives" and (bk.is_empty() or String((bk["pearl"] as Dictionary).get("pearl", "")) != String(target.get("pearl", ""))):
				fails.append("O would open a pearl /lines cannot find: %s · %s" % [target.get("chapter"), target.get("pearl")])
		inst.set("_edit_sel", near)
		if int(inst.call("_web_focus_record")) != near:
			fails.append("a held body did not outrank the nearest")
		inst.set("_edit_sel", -1)

	var real_after := FileAccess.get_file_as_string(REAL_CTL) if FileAccess.file_exists(REAL_CTL) else ""
	if real_after != real_before:
		fails.append("the REAL control file was written (%s)" % REAL_CTL)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIAL_OVERRIDES))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOOK + "/primitives.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOOK))
	var out_path: String = Evidence.dir("spine-strip").path_join("spine_strip_probe.txt")
	var f3 := FileAccess.open(out_path, FileAccess.WRITE)
	f3.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f3.close()
	print("SPINE STRIP: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)


func _rec_node(r_v: Variant) -> Node3D:
	var n: Variant = (r_v as Dictionary).get("node")
	if n is Node3D and is_instance_valid(n):
		return n
	return null
