extends SceneTree

## Do the grey halls get their silhouettes and their gun — and do the others NOT?
## (2026-08-29)
##
## Boots the museum twice, headless, under a trial control so the live walker's
## records survive: first at primitives (grey by soft_stages: no kingdoms, zero
## vegetation), then at color (the first flower). For every hall built it reads
## the segment's children and the museum's own report, and asserts:
##
##   grey hall     foes.per_hall silhouettes, body = silhouette, each standing on
##                 a cell centre that is in the walk map, each spawned at least
##                 clear_m from the save point (read from em_foes.json, since a
##                 body that has noticed the walker may already have stepped),
##                 each holding the WALKER as its player; and a frozen pink gun
##                 on a plinth in the vestibule, its cell out of the walk map
##   not-grey hall zero silhouettes, no gun — the negative that proves the rule
##                 bites and is not "every hall"
##   the report    ada_run/_trial_em_foes.json names every hall with grey right
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_grey_halls.gd

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const TRIAL := "res://ada_run/_trial_foes_control.json"
const REPORT := "res://ada_run/grey_halls_probe.txt"
const FOES_TRIAL := "res://ada_run/_trial_em_foes.json"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var grey: Dictionary = await _boot("primitives")
	var plain: Dictionary = await _boot("color")
	_judge(grey, true)
	_judge(plain, false)
	# the report — as each boot read it, since the second boot rewrites the file
	var n_grey: int = 0
	var n_all: int = 0
	for run in [grey, plain]:
		var sp: Dictionary = run["spawned"]
		for k in sp:
			n_all += 1
			if bool((sp[k] as Dictionary).get("grey", false)):
				n_grey += 1
	_check(n_all >= 2 and n_grey >= 1, "report %s: %d hall row(s) across both boots, %d grey" % [FOES_TRIAL, n_all, n_grey], "no report")
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _boot(chapter: String) -> Dictionary:
	var ctl := FileAccess.open(TRIAL, FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	var inst: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", TRIAL)
	inst.set("_overrides_path", "res://ada_run/_trial_foes_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_foes_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", "")
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	inst.set("MIN_SEGMENTS", 99)
	inst.set("KEEP_AHEAD_M", 99999.0)
	inst.set("KEEP_BEHIND_M", 99999.0)
	for i in range(2):
		if (inst.get("_segments") as Array).size() >= 2:
			break
		inst.call("_build_segment")
		await create_timer(0.3).timeout
	inst.call("flush_stamps")
	await create_timer(0.8).timeout
	var walker: Node = inst.get("_player")
	var walk: Dictionary = inst.get("_walk_cells")
	var erased: Dictionary = inst.get("_walk_erased")
	var clear_m: float = float(inst.call("_L", "foes", "clear_m", 5.0))
	var per_hall: int = int(inst.call("_L", "foes", "per_hall", 3.0))
	var halls: Array = []
	for s_v in (inst.get("_segments") as Array):
		var s: Dictionary = s_v
		var node: Node3D = s.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var rec := {"chapter": String(node.get_meta("em_chapter")) if node.has_meta("em_chapter") else "",
			"pearl": str(node.get_meta("em_pearl")) if node.has_meta("em_pearl") else "",
			"z0": float(s.get("z0", 0.0)), "w": int(s.get("w", 0)),
			"foes": [], "gun": null, "plinth": null, "gun_cell_walkable": false, "gun_cell_prov": ""}
		for c in node.get_children():
			if c.has_meta("em_foe") and c is Node3D:
				var p: Vector3 = (c as Node3D).global_position
				var cell := Vector2i(int(floor(p.x)), int(floor(p.z)))
				rec["foes"].append({"body": str(c.get("body")), "cell": cell, "on_walk": walk.has(cell),
					"centred": absf(fposmod(p.x, 1.0) - 0.5) < 0.01 and absf(fposmod(p.z, 1.0) - 0.5) < 0.01,
					"player_is_walker": c.get("_player_node") == walker and walker != null,
					"statue": bool(c.get("_sil_statue"))})
			if c.has_meta("em_foe_gun") and c is Node3D:
				var gp: Vector3 = (c as Node3D).global_position
				var gcell := Vector2i(int(floor(gp.x)), int(floor(gp.z)))
				rec["gun"] = {"frozen": bool(c.get("freeze")), "y": gp.y, "cell": gcell}
				rec["gun_cell_walkable"] = walk.has(gcell)
				rec["gun_cell_prov"] = str(erased.get(gcell, ""))
			if c.name == "GunPlinth":
				rec["plinth"] = true
		halls.append(rec)
	# the spawn cells as the museum wrote them (the bodies may have stepped since)
	var spawned: Dictionary = {}
	if FileAccess.file_exists(FOES_TRIAL):
		var pv: Variant = JSON.parse_string(FileAccess.get_file_as_string(FOES_TRIAL))
		if pv is Dictionary and (pv as Dictionary).get("halls") is Dictionary:
			spawned = (pv as Dictionary)["halls"]
	inst.queue_free()
	await create_timer(0.5).timeout
	return {"chapter": chapter, "halls": halls, "clear_m": clear_m, "per_hall": per_hall, "spawned": spawned}


func _judge(run: Dictionary, expect_grey: bool) -> void:
	var chapter: String = String(run["chapter"])
	var halls: Array = run["halls"]
	_lines.append("[probe] === %s: %d hall(s) built, expected %s" % [chapter, halls.size(), "GREY" if expect_grey else "not grey"])
	_check(halls.size() >= 1, "%s built %d hall(s)" % [chapter, halls.size()], "no hall built")
	for rec_v in halls:
		var rec: Dictionary = rec_v
		var ch: String = String(rec["chapter"])
		var foes: Array = rec["foes"]
		var tag: String = "%s|%s" % [ch, String(rec["pearl"])]
		if ch != chapter:
			_lines.append("[probe]   %s: another chapter's hall, skipped" % tag)
			continue
		if not expect_grey:
			_check(foes.is_empty() and rec["gun"] == null and rec["plinth"] == null,
				"%s: %d silhouette(s), gun %s" % [tag, foes.size(), "present" if rec["gun"] != null else "none"],
				"a hall that is not grey got dressed")
			continue
		var per_hall: int = int(run["per_hall"])
		_check(foes.size() == per_hall, "%s: %d silhouette(s) (want %d)" % [tag, foes.size(), per_hall], "wrong count")
		var n_sil := 0
		var n_walk := 0
		var n_centred := 0
		var n_walker := 0
		for f_v in foes:
			var f: Dictionary = f_v
			if String(f["body"]) == "silhouette":
				n_sil += 1
			if bool(f["on_walk"]):
				n_walk += 1
			if bool(f["centred"]):
				n_centred += 1
			if bool(f["player_is_walker"]):
				n_walker += 1
		_check(n_sil == foes.size(), "%s: bodies silhouette %d/%d" % [tag, n_sil, foes.size()], "a foe that is not a silhouette")
		_check(n_walk == foes.size(), "%s: standing on walk cells %d/%d" % [tag, n_walk, foes.size()], "a foe off the walk map")
		_check(n_centred == foes.size(), "%s: on cell centres %d/%d" % [tag, n_centred, foes.size()], "a foe that glided")
		_check(n_walker == foes.size(), "%s: player is the walker %d/%d" % [tag, n_walker, foes.size()], "a foe that cannot see the walker")
		# clearance, from the spawn cells the museum wrote
		var sp: Variant = (run["spawned"] as Dictionary).get(tag, null)
		if sp is Dictionary:
			var z0: float = float(rec["z0"])
			var w: int = int(rec["w"])
			var save := Vector2(float(w) / 2.0 + 0.5, z0 + 4.0 - 1.5)
			var min_d: float = 1.0e9
			for c_v in (sp as Dictionary).get("silhouettes", []):
				var c: Array = c_v
				min_d = minf(min_d, Vector2(float(c[0]) + 0.5, float(c[1]) + 0.5).distance_to(save))
			_check(min_d >= float(run["clear_m"]) - 0.01, "%s: nearest spawn %.2f m from the save point (clear_m %.1f)" % [tag, min_d, float(run["clear_m"])], "a foe spawned on the visitor")
		else:
			_check(false, "%s: no row in em_foes.json" % tag, "hall missing from the report")
		# the gun
		var gun: Variant = rec["gun"]
		_check(gun is Dictionary and rec["plinth"] != null, "%s: gun %s, plinth %s" % [tag, "present" if gun is Dictionary else "MISSING", "present" if rec["plinth"] != null else "MISSING"], "no gun")
		if gun is Dictionary:
			_check(bool((gun as Dictionary)["frozen"]), "%s: gun frozen %s at y %.2f" % [tag, str((gun as Dictionary)["frozen"]), float((gun as Dictionary)["y"])], "an unfrozen gun over a plinth with no collider")
			_check(not bool(rec["gun_cell_walkable"]) and String(rec["gun_cell_prov"]) == "prop:pink_gun",
				"%s: gun cell %s out of the walk map (%s)" % [tag, str((gun as Dictionary)["cell"]), String(rec["gun_cell_prov"])], "the gun's cell is still walkable")


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
