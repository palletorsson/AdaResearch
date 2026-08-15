extends SceneTree
## Furniture rulings, tried end to end: in a built museum, the editor holds
## records of kind furniture / plinth / showing; nudging one writes a ruling
## with the right key; F5 saves; and a SECOND build reads the ruling back and
## places the thing at the ruled offset. Overrides file backed up + restored.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_furniture.gd

const OUT := "res://ada_run/em_overrides.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var backup: String = FileAccess.get_file_as_string(OUT) if FileAccess.file_exists(OUT) else ""
	if FileAccess.file_exists(OUT):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OUT))

	# ── build 1: pick one of each kind and rule it ───────────────────────────
	var inst: Node3D = await _museum()
	var records: Array = inst.get("_edit_records")
	var kinds: Dictionary = {}
	for i in range(records.size()):
		var k := String((records[i] as Dictionary).get("kind", "artifact"))
		if not kinds.has(k):
			kinds[k] = i
	print("[trial] record kinds present: %s" % str(kinds.keys()))
	for k in ["furniture", "plinth", "showing"]:
		if not kinds.has(k):
			fails.append("no %s record in the first two segments" % k)
	if not fails.is_empty():
		_verdict(fails, backup, inst)
		return

	var expect: Dictionary = {}   # kind -> {key fields, pos before, want}
	for k in ["furniture", "plinth", "showing"]:
		var i: int = int(kinds[k])
		var r: Dictionary = records[i]
		var node: Node3D = r.get("node") as Node3D
		var p0: Vector3 = node.position
		inst.set("_edit_sel", i)
		inst.set("_edit_shift", true)
		inst.call("_edit_handle_key", KEY_RIGHT)      # +0.2 x
		inst.call("_edit_handle_key", KEY_RIGHT)      # +0.4 x
		inst.set("_edit_shift", false)
		inst.call("_edit_handle_key", KEY_PAGEUP)     # +0.2 y
		if k != "showing":
			var p1: Vector3 = node.position
			if (p1 - p0 - Vector3(0.4, 0.2, 0.0)).length() > 0.01:
				fails.append("%s live preview moved %s, expected (0.4, 0.2, 0)" % [k, str(p1 - p0)])
		expect[k] = {"token": String(r.get("token", "")), "index": int(r.get("index", -1)),
			"from": (r.get("from", []) as Array).duplicate(), "chapter": String(r.get("chapter", "")),
			"p0": p0}
	# furniture may also turn: 15 deg
	inst.set("_edit_sel", int(kinds["furniture"]))
	inst.call("_edit_handle_key", KEY_R)
	inst.call("_edit_handle_key", KEY_F5)

	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT))
	var rows: Array = (doc as Dictionary).get("overrides", [])
	var by_kind: Dictionary = {}
	for row in rows:
		var kk := String((row as Dictionary).get("kind", ""))
		if kk != "":
			by_kind[kk] = row
	for k in ["furniture", "plinth", "showing"]:
		if not by_kind.has(k):
			fails.append("F5 wrote no %s ruling" % k)
			continue
		var row: Dictionary = by_kind[k]
		var off: Array = row.get("offset", [])
		if off.size() < 3 or absf(float(off[0]) - 0.4) > 0.01 or absf(float(off[1]) - 0.2) > 0.01:
			fails.append("%s offset %s != [0.4, 0.2, 0]" % [k, str(off)])
		if String(row.get("chapter", "")) != String((expect[k] as Dictionary)["chapter"]):
			fails.append("%s ruling chapter %s != %s" % [k, row.get("chapter"), (expect[k] as Dictionary)["chapter"]])
	if by_kind.has("furniture") and absf(fposmod(float((by_kind["furniture"] as Dictionary).get("rotation", -99.0)), 360.0)
			- fposmod(float((records[int(kinds["furniture"])] as Dictionary).get("rotation", 0.0)) + 15.0, 360.0)) > 0.5:
		fails.append("furniture rotation ruling != base + 15")

	get_root().remove_child(inst)
	inst.queue_free()
	await create_timer(0.3).timeout

	# ── build 2: the rulings must be APPLIED where each thing is built ───────
	var inst2: Node3D = await _museum()
	var records2: Array = inst2.get("_edit_records")
	for k in ["furniture", "plinth", "showing"]:
		var e: Dictionary = expect[k]
		var found := false
		for r_v in records2:
			var r: Dictionary = r_v
			if String(r.get("kind", "")) != k or String(r.get("chapter", "")) != String(e["chapter"]):
				continue
			var same: bool = false
			if k == "plinth":
				same = String(r.get("token", "")) == String(e["token"]) and r.get("from", []) == e["from"]
			else:
				same = String(r.get("token", "")) == String(e["token"]) and int(r.get("index", -1)) == int(e["index"])
			if not same:
				continue
			found = true
			var node2: Node3D = r.get("node") as Node3D
			var want: Vector3 = (e["p0"] as Vector3) + Vector3(0.4, 0.2, 0.0)
			if k == "showing":
				# the proxy is placed from the SHIFTED mount transform, so it too
				# reads the ruling; the picture's meshes moved with it
				pass
			if (node2.position - want).length() > 0.02:
				fails.append("%s rebuilt at %s, ruling says %s" % [k, str(node2.position), str(want)])
			break
		if not found:
			fails.append("%s record not found again on rebuild (key drifted?)" % k)
	_verdict(fails, backup, inst2)


func _museum() -> Node3D:
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_edit_mode", true)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("_first_key", "sainsbury-false-perspective-enfilade")
	get_root().add_child(inst)
	for i in range(5):
		await create_timer(0.2).timeout
	return inst


func _verdict(fails: Array[String], backup: String, inst: Node3D) -> void:
	if inst != null and is_instance_valid(inst):
		get_root().remove_child(inst)
		inst.queue_free()
	if backup != "":
		var f := FileAccess.open(OUT, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	elif FileAccess.file_exists(OUT):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OUT))
	if fails.is_empty():
		print("FURNITURE RULINGS: PASS — furniture / plinth / showing ruled, saved, and rebuilt at the ruling")
	else:
		print("FURNITURE RULINGS: FAIL %d" % fails.size())
		for f2 in fails:
			print("  - " + f2)
	quit(0 if fails.is_empty() else 1)
