extends SceneTree
## CAN PALLE EDIT A PASSAGE? (2026-08-26, Palle: "I feel like I do not have
## control over the passages, can you give full edit control over them? Like
## the maps?")
##
## The passage rows are APPENDED past an authored hall's last map row, so the
## cell painter's map write refused them: _map_write_cell returns false on
## `cz >= struct.size()`, _rule_cell returns "", and nothing happened at all on
## the one stretch of the museum a visitor crosses every single time.
##
## The negative test for that fix, in three parts, all of which fail on the old
## code:
##   1. a passage cell leaves a RULING behind
##   2. and does NOT touch the map — a passage belongs to no map, which is why
##      it can be a ruling without contradicting ONE TRUTH
##   3. and a SECOND museum, booted on that ruling, builds the changed cell —
##      the half that proves it bites rather than merely being recorded
##
## It writes only to _trial_pe_* files: Palle plays the museum while probes run.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_passage_edit.gd

const OUT := "res://ada_run/passage_edit.txt"
const TRIAL := "res://ada_run/_trial_pe_overrides.json"


func _initialize() -> void:
	call_deferred("_run")


func _museum(overrides: String) -> Node3D:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_pe_control.json")
	inst.set("_overrides_path", overrides)
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("_force_patient", true)
	var ctl := FileAccess.open("res://ada_run/_trial_pe_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "", "first_map": "",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	return inst


func _walk(inst: Node3D, metres: float) -> void:
	await create_timer(3.0).timeout
	var player: Node3D = inst.get("_player") as Node3D
	var z := 0.0
	while z < metres:
		z += 4.0
		if player != null:
			player.position.z = z
		await create_timer(0.12).timeout


## the first authored hall in the built strip that appended passage rows
func _passage_hall(inst: Node3D) -> Dictionary:
	for sv in (inst.get("_segments") as Array):
		var sd: Dictionary = sv
		var n: Node3D = sd.get("node") as Node3D
		if n == null or not is_instance_valid(n):
			continue
		if int(n.get_meta("em_passage_start", -1)) < 0:
			continue
		if String(n.get_meta("em_map", "")) == "":
			continue
		return {"seg": n, "zbase": int(sd.get("z0", 0.0)),
			"start": int(n.get_meta("em_passage_start", -1)),
			"map": String(n.get_meta("em_map"))}
	return {}


func _run() -> void:
	var rep := "CAN PALLE EDIT A PASSAGE?\n\n"
	var fails := 0
	var a: Node3D = _museum(TRIAL)
	var f0 := FileAccess.open(TRIAL, FileAccess.WRITE)
	f0.store_string(JSON.stringify({"overrides": []}, " "))
	f0.close()
	await _walk(a, 280.0)

	var hall: Dictionary = _passage_hall(a)
	if hall.is_empty():
		_finish(rep + "  FAIL no hall in the built strip appended passage rows\n", 1)
		return
	var pass_at: int = int(hall["start"])
	var map_name: String = String(hall["map"])
	rep += "  the hall: %s, passage rows start at tile row %d\n\n" % [map_name, pass_at]

	var VH: int = int(a.get("VESTIBULE_H"))
	var map_path := "res://commons/maps/%s/map_data.json" % map_name
	var map_before := FileAccess.get_file_as_string(map_path)

	# TOGGLE, never paint: _rule_cell is drag-safe and refuses a cell that would
	# not change, so painting a wall onto the chicane's own wall is a no-op that
	# looks exactly like the bug.
	var said := ""
	var hit_x: int = -1
	for px in [2, 3, 1, 4, 5]:
		said = String(a.call("_rule_cell", hall["seg"], int(hall["zbase"]), int(px),
			int(hall["zbase"]) + VH + pass_at + 1, false, ""))
		if said != "":
			hit_x = int(px)
			break
	var rule := {}
	for ov_v in (a.get("_edit_overrides") as Array):
		var ov: Dictionary = ov_v
		if String(ov.get("kind", "")) != "cell":
			continue
		var fr: Array = ov.get("from", [])
		if fr.size() >= 2 and int(fr[1]) >= pass_at:
			rule = ov
	if said == "":
		rep += "  FAIL painting the passage did nothing — the old behaviour\n"
		fails += 1
	elif rule.is_empty():
		rep += "  FAIL the passage cell left no ruling behind\n"
		fails += 1
	else:
		rep += "  ok   1. the passage cell became a ruling: %s [%d,%d] = %s\n" % [
			String(rule.get("pearl", "?")), int((rule["from"] as Array)[0]),
			int((rule["from"] as Array)[1]), String(rule.get("value", "?"))]

	if FileAccess.get_file_as_string(map_path) != map_before:
		rep += "  FAIL 2. the map changed — a passage row exists in no map\n"
		fails += 1
	else:
		rep += "  ok   2. %s is untouched\n" % map_name

	if fails > 0 or rule.is_empty():
		_finish(rep + "\n  %d FAIL(s)\n" % fails, maxi(fails, 1))
		return

	# 3. does it BUILD? A ruling nobody reads is a ruling that does nothing.
	var f := FileAccess.open(TRIAL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"overrides": [rule]}, " "))
	f.close()
	a.queue_free()
	await create_timer(1.0).timeout
	var b: Node3D = _museum(TRIAL)
	await _walk(b, 280.0)
	var hall2: Dictionary = _passage_hall(b)
	if hall2.is_empty() or String(hall2["map"]) != map_name:
		rep += "  FAIL 3. the second museum built a different strip\n"
		fails += 1
	else:
		var tile2: Array = (hall2["seg"] as Node3D).get_meta("em_tile")
		var row: int = int((rule["from"] as Array)[1])
		var got := "?"
		if row < tile2.size() and hit_x < (tile2[row] as Array).size():
			got = String((tile2[row] as Array)[hit_x])
		if got == String(rule.get("value", "")):
			rep += "  ok   3. a second museum built it: tile[%d][%d] = %s\n" % [row, hit_x, got]
		else:
			rep += "  FAIL 3. the ruling did not build: tile[%d][%d] = %s, wanted %s\n" % [
				row, hit_x, got, String(rule.get("value", ""))]
			fails += 1
	rep += "\n  %s\n" % ("PASS" if fails == 0 else "%d FAIL(s)" % fails)
	_finish(rep, fails)


func _finish(rep: String, fails: int) -> void:
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(1 if fails > 0 else 0)
