extends SceneTree
## ONE-TRUTH encode path, held headless: _map_write_cell and _map_move_token
## against the real Point_One map — executed, verified, then the file is
## RESTORED byte-for-byte. Prints the refusal reason when a step fails.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_map_encode.gd

const OUT := "res://ada_run/map_encode_probe.txt"
const MAP := "res://commons/maps/Point_One/map_data.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var original := FileAccess.get_file_as_string(MAP)
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", "res://ada_run/_trial_encode_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_encode_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_map_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_encode_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 1, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	# the point one segment
	var seg0: Node3D = null
	for c in inst.get_children():
		if c is Node3D and str(c.name).begins_with("Seg0_"):
			seg0 = c
	if seg0 == null:
		fails.append("no Seg0")
	else:
		if not seg0.has_meta("em_map") or String(seg0.get_meta("em_map")) == "":
			fails.append("Seg0 carries no em_map meta (authored wiring broken)")
		# 1. wall encode: write cell [5,9] as wall, read the file back
		var ok1: bool = inst.call("_map_write_cell", "Point_One", 5, 9, true)
		if not ok1:
			fails.append("_map_write_cell REFUSED (open/parse/bounds)")
		else:
			var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP))
			var sv := str((((doc as Dictionary)["layers"] as Dictionary)["structure"][9] as Array)[5])
			if sv != "2":
				fails.append("wall encode wrote '%s', wanted '2'" % sv)
		# 2. artifact move: find origin's ACTUAL cell (the curator moves it —
		# a fixed fixture went stale the first time), then shift it one cell
		var odoc: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP))
		var ointer: Array = ((odoc as Dictionary)["layers"] as Dictionary)["interactables"]
		var ox := -1
		var oz := -1
		for rr in range(ointer.size()):
			for cc in range((ointer[rr] as Array).size()):
				if str((ointer[rr] as Array)[cc]).begins_with("origin"):
					ox = cc
					oz = rr
		if ox < 0:
			fails.append("origin not found in the map at all")
		var tx3 := ox + 1
		var tz3 := oz
		if tx3 < (ointer[oz] as Array).size() and str((ointer[oz] as Array)[tx3]).strip_edges() != "":
			tx3 = ox - 1
		var why: String = inst.call("_map_move_token", "Point_One", ox, oz, tx3, tz3)
		if why != "":
			fails.append("_map_move_token REFUSED: " + why)
		else:
			var doc2: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP))
			var inter: Array = ((doc2 as Dictionary)["layers"] as Dictionary)["interactables"]
			if not str((inter[tz3] as Array)[tx3]).begins_with("origin"):
				fails.append("moved token not at its target")
		# 3. full edit path: _rule_cell on the authored segment
		var msg: String = inst.call("_rule_cell", seg0, 0, 6, 10, false)
		if msg == "":
			fails.append("_rule_cell returned '' (the editing-refused symptom)")
	# RESTORE the map byte-for-byte
	var f := FileAccess.open(MAP, FileAccess.WRITE)
	f.store_string(original)
	f.close()
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	out.close()
	print("MAP ENCODE: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
