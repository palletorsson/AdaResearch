extends SceneTree
## Rulings save themselves, and a save is a MERGE.
## BITE 1: an edit with no F5 lands in the file within a second.
## BITE 2: a ruling written to the file by SOMEONE ELSE after this session
##   loaded survives the save; the session's own row wins for its own key.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_autosave.gd
const P := "res://ada_run/_trial_em_overrides_autosave.json"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	if FileAccess.file_exists(P): DirAccess.remove_absolute(ProjectSettings.globalize_path(P))
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_overrides_path", P)
	m.set("_edit_mode", true)
	get_root().add_child(m)
	await create_timer(1.2).timeout
	var recs: Array = m.get("_edit_records")
	var idx := -1
	for i in range(recs.size()):
		if String((recs[i] as Dictionary).get("kind", "artifact")) in ["artifact", ""]:
			idx = i; break
	if idx < 0: print("EM AUTOSAVE: SKIP — no editable body"); quit(0); return
	m.set("_edit_sel", idx)
	var tok := String((recs[idx] as Dictionary).get("token", ""))
	# BITE 1: one arrow key, no F5
	m.call("_edit_handle_key", KEY_RIGHT)
	await create_timer(1.2).timeout
	if not FileAccess.file_exists(P):
		fails.append("BITE 1: nothing was written without F5")
	else:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P))
		if (d.get("overrides", []) as Array).is_empty(): fails.append("BITE 1: the file is empty")
	# BITE 2: someone else writes a ruling into the file behind our back
	var d2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P))
	var rows: Array = d2.get("overrides", [])
	rows.append({"chapter": "someone_else", "token": "a_third_party_body", "from": [99, 99],
		"to": [99, 99], "rotation": 0.0, "remove": false, "provenance": "hand"})
	var f := FileAccess.open(P, FileAccess.WRITE); f.store_string(JSON.stringify({"overrides": rows}, "\t")); f.close()
	# now this session rules again and saves
	m.call("_edit_handle_key", KEY_RIGHT)
	await create_timer(1.2).timeout
	var d3: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P))
	var toks: Array = []
	for r in (d3.get("overrides", []) as Array): toks.append(String((r as Dictionary).get("token", "")))
	if not toks.has("a_third_party_body"):
		fails.append("BITE 2: the other writer's ruling was clobbered (%s)" % str(toks))
	if not toks.has(tok):
		fails.append("BITE 2: this session's own ruling is missing (%s)" % str(toks))
	var mine := 0
	for t in toks: if String(t) == tok: mine += 1
	if mine != 1: fails.append("BITE 2: %d copies of this session's ruling — a merge must not duplicate" % mine)
	get_root().remove_child(m); m.queue_free()
	if FileAccess.file_exists(P): DirAccess.remove_absolute(ProjectSettings.globalize_path(P))
	if fails.is_empty(): print("EM AUTOSAVE: PASS — an edit writes itself; a save merges and keeps another writer's ruling")
	else:
		print("EM AUTOSAVE: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
