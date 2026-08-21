extends SceneTree
## THE TRANSPLANT, held to its three promises on primitives · point:
## (1) the purge — every body in the packed hall comes from the grid map,
##     no fillers, no DNA, no guests;
## (2) the constellation — two unobstructed reference bodies stand at the
##     grid's own relative offset, cell for cell;
## (3) the plinth rule — a structure-2 body stands on a plinth.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_transplant.gd

const OUT := "res://ada_run/transplant_probe.txt"
const CTL := "res://ada_run/_doll_trial_control.json"
const MAP := "res://commons/maps/Point_One/map_data.json"
const REF_A := "CoordinateSystem3M"
const REF_B := "fontana_puncture"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "",
		"dollhouse": 0, "grid_pack": 1}, " "))
	f.close()
	# a TRIAL hand with one bead-grain stamp: you_are_here claims [5, 20]
	# ("force stamp mean force stamp for selected artifact at that position")
	var fh := FileAccess.open("res://ada_run/_trial_hand.json", FileAccess.WRITE)
	fh.store_string(JSON.stringify({"halls": {"primitives|point": {"beads": [
		{"token": "you_are_here", "x": 5.5, "z": 20.5, "fp": 1, "count": 1,
		 "plinth": false, "stamp": true}]}}}, " "))
	fh.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_hand.json")
	get_root().add_child(inst)
	await create_timer(1.2).timeout
	for i in range(300):
		if (inst.get("_stamp_queue") as Array).is_empty():
			break
		await process_frame
	await create_timer(1.0).timeout

	# the map's own truth
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP))
	var inter: Array = (doc.get("layers", {}) as Dictionary).get("interactables", [])
	var map_tokens := {}
	var n_bodies := 0
	var ref_cells := {}
	for gz in range(inter.size()):
		var row: Array = inter[gz]
		for gx in range(row.size()):
			var cellv := String(row[gx]).strip_edges()
			if cellv == "" or cellv.begins_with("#"):
				continue
			var tok := cellv.split("#", true, 1)[0].split(":")[0]
			map_tokens[tok] = true
			n_bodies += 1
			if tok == REF_A or tok == REF_B:
				ref_cells[tok] = Vector2i(gx, gz)

	# the packed hall's bodies: records whose seg is segment 0
	var seg0: Node3D = _node((inst.get("_segments") as Array)[0])
	var in_hall: Array = []
	for r_v in (inst.get("_edit_records") as Array):
		var r: Dictionary = r_v
		var kd := String(r.get("kind", ""))
		if kd != "" and kd != "artifact":
			continue
		if r.get("seg") != seg0:
			continue
		in_hall.append(r)

	# (1) THE PURGE
	var guests: Array = []
	for r_v in in_hall:
		var tok := String((r_v as Dictionary).get("token", ""))
		if not map_tokens.has(tok) and not guests.has(tok):
			guests.append(tok)
	if not guests.is_empty():
		fails.append("guests in the packed hall: " + ", ".join(guests))
	if in_hall.size() < int(n_bodies * 0.8):
		fails.append("only %d of the map's %d bodies stand in the hall" % [in_hall.size(), n_bodies])

	# (2) THE CONSTELLATION
	if ref_cells.size() == 2:
		var pa := _pos_of(in_hall, REF_A)
		var pb := _pos_of(in_hall, REF_B)
		if pa == Vector3.INF or pb == Vector3.INF:
			fails.append("a reference body is missing from the hall")
		else:
			var want: Vector2i = ref_cells[REF_B] - ref_cells[REF_A]
			var got := Vector2(pb.x - pa.x, pb.z - pa.z)
			# the contract is verbatim-where-floor-allows, nearest-empty else:
			# a repair slide is at most a few cells, so the delta may breathe
			# by the repair radius — but never by a mis-centring's ten.
			if absf(got.x - float(want.x)) > 2.5 or absf(got.y - float(want.y)) > 2.5:
				fails.append("constellation broke: %s->%s grid delta %s, hall delta (%.1f, %.1f)" % [
					REF_A, REF_B, str(want), got.x, got.y])
	else:
		fails.append("reference bodies not found in the map itself")

	# (2b) THE WALLS — the strong absolute check, learned the hard way: every
	# body must stand INSIDE the built tile (the first two builds centred on
	# plan-space geometry, stamped past the walls without refusal, and every
	# relative check was satisfied on open void). The tile is the ruler.
	var sr: Dictionary = (inst.get("_segments") as Array)[0]
	var seg_w: float = float(sr.get("w", 0))
	var seg_z0: float = float(sr.get("z0", 0))
	var seg_z1: float = float(sr.get("z1", 0))
	for r_v in in_hall:
		var nd: Variant = (r_v as Dictionary).get("node")
		if nd is Node3D and is_instance_valid(nd):
			var gp: Vector3 = (nd as Node3D).global_position
			if gp.x < 0.0 or gp.x > seg_w or gp.z < seg_z0 or gp.z > seg_z1:
				fails.append("%s stands OUTSIDE the tile at (%.1f, %.1f) — tile w=%d z %d..%d" % [
					(r_v as Dictionary).get("token"), gp.x, gp.z, int(seg_w), int(seg_z0), int(seg_z1)])
				break

	# (2c) THE BEAD-GRAIN STAMP: the stamped artifact stands at ITS position;
	# everything else transplants as usual
	var yah := _pos_of(in_hall, "you_are_here")
	if yah == Vector3.INF:
		fails.append("the stamped bead's artifact is missing")
	elif Vector2(yah.x - 5.5, yah.z - 20.5).length() > 1.8:
		fails.append("the stamped bead did not land at its position (got %.1f, %.1f — wanted 5.5, 20.5)" % [yah.x, yah.z])

	# (3) THE PLINTH RULE
	var plinthed := 0
	for r_v in in_hall:
		if String((r_v as Dictionary).get("plinth", "")) != "":
			plinthed += 1
	if plinthed == 0:
		fails.append("no structure-2 body stands on a plinth")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_trial_hand.json"))
	# the ruler, printed every run: the segment's real bounds vs where the
	# bodies actually stand (absolute world cells) — theory got this wrong twice
	var srow: Dictionary = (inst.get("_segments") as Array)[0]
	var bmin := Vector2(1e9, 1e9)
	var bmax := Vector2(-1e9, -1e9)
	for r_v in in_hall:
		var nd: Variant = (r_v as Dictionary).get("node")
		if nd is Node3D and is_instance_valid(nd):
			var gp: Vector3 = (nd as Node3D).global_position
			bmin = Vector2(minf(bmin.x, gp.x), minf(bmin.y, gp.z))
			bmax = Vector2(maxf(bmax.x, gp.x), maxf(bmax.y, gp.z))
	var ruler := "seg w=%d z0=%.0f z1=%.0f · bodies x %.1f..%.1f z %.1f..%.1f" % [
		int(srow.get("w", 0)), float(srow.get("z0", 0)), float(srow.get("z1", 0)),
		bmin.x, bmax.x, bmin.y, bmax.y]
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string(("PASS (%d bodies, %d plinthed)" % [in_hall.size(), plinthed] if fails.is_empty()
		else "FAIL: " + "; ".join(fails)) + "\n" + ruler)
	f3.close()
	print("TRANSPLANT: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)


func _node(sv: Variant) -> Node3D:
	var n: Variant = (sv as Dictionary).get("node")
	return n if (n is Node3D and is_instance_valid(n)) else null


func _pos_of(records: Array, tok: String) -> Vector3:
	for r_v in records:
		if String((r_v as Dictionary).get("token", "")) == tok:
			var n: Variant = (r_v as Dictionary).get("node")
			if n is Node3D and is_instance_valid(n):
				return (n as Node3D).global_position
	return Vector3.INF
