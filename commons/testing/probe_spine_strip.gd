extends SceneTree
## THE SPINE STRIP under the new contract — the web is the editor: the strip
## lists the walk order and the open pearl's lines, the URL builder aims at
## chapter · pearl · token, the watcher folds a disk-side (web) save into the
## open pane within a tick, O's focus resolver finds the held body or the
## nearest artifact to the eye, and a travel writes the control file with the
## current view preserved. Runs against a TRIAL copy of the book and a trial
## control file — the real ones are never touched.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_spine_strip.gd

const OUT := "res://ada_run/spine_strip_probe.txt"
const CTL := "res://ada_run/_doll_trial_control.json"
const BOOK := "res://ada_run/_trial_book"

func _initialize() -> void:
	call_deferred("_run")


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

	# the URL builder is pure and exact
	var url := String(inst.call("_web_url", "primitives", "point", "you_are_here"))
	if url != "http://localhost:3003/lines?chapter=primitives&pearl=point&token=you_are_here":
		fails.append("the web url is wrong: " + url)
	if String(inst.call("_web_url", "primitives", "point", "")).contains("token"):
		fails.append("an empty token leaked into the url")

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
		elif lines_ui.item_count != snap.size():
			fails.append("lines pane shows %d rows for %d lines (no editor rows expected)" % [lines_ui.item_count, snap.size()])

		# THE WATCHER: a save made in the web editor lands in the open pane
		# within a tick (mtime has 1 s grain, so the baseline is forced old)
		var docw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BOOK + "/primitives.json"))
		for pv in (docw.get("pearls", []) as Array):
			if String((pv as Dictionary).get("pearl", "")) == "point":
				(((pv as Dictionary).get("lines", []) as Array)[0] as Dictionary)["text"] = "HOT FROM THE WEB"
		var fw := FileAccess.open(BOOK + "/primitives.json", FileAccess.WRITE)
		fw.store_string(JSON.stringify(docw, " ") + "\n")
		fw.close()
		inst.set("_spine_mtime", 1)
		await create_timer(1.5).timeout
		var snapw: Array = inst.get("_spine_snapshot")
		if snapw.is_empty() or String((snapw[0] as Dictionary).get("text", "")) != "HOT FROM THE WEB":
			fails.append("the watcher did not reload the web editor's save")

		# TRAVEL writes the control file, view preserved (walk here)
		inst.call("_spine_travel", point_i)
		var ctl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CTL))
		if String(ctl.get("first_chapter", "")) != "primitives":
			fails.append("travel did not write the chapter")
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
		inst.set("_edit_sel", near)
		if int(inst.call("_web_focus_record")) != near:
			fails.append("a held body did not outrank the nearest")
		inst.set("_edit_sel", -1)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOOK + "/primitives.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BOOK))
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f3.close()
	print("SPINE STRIP: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)


func _rec_node(r_v: Variant) -> Node3D:
	var n: Variant = (r_v as Dictionary).get("node")
	if n is Node3D and is_instance_valid(n):
		return n
	return null
