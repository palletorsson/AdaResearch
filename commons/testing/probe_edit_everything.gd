extends SceneTree
## THE FULL EDIT SWEEP (Palle: "test it until it works — all platforms and
## all object, walls, artifact and props"). One boot, every object class
## through its real edit path, every claim asserted, the maps restored
## byte-for-byte. Trial control/hand/overrides — the rulings lanes write to
## a trial file; the map lane writes the REAL maps and restores them.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_edit_everything.gd

const OUT := "res://ada_run/edit_everything_verdict.json"
const MAP1 := "res://commons/maps/Point_One/map_data.json"
const TRIAL_OVR := "res://ada_run/_trial_sweep_overrides.json"

var checks: Dictionary = {}
var fails: Array = []


func _initialize() -> void:
	call_deferred("_run")


func say(name: String, ok: bool, why: String = "") -> void:
	checks[name] = ok
	if not ok:
		fails.append(name + (": " + why if why != "" else ""))


func _run() -> void:
	var original1 := FileAccess.get_file_as_string(MAP1)
	for pth in [TRIAL_OVR, "res://ada_run/_trial_sweep_control.json", "res://ada_run/_trial_map_hand.json"]:
		var fw := FileAccess.open(pth, FileAccess.WRITE)
		if pth == TRIAL_OVR:
			fw.store_string(JSON.stringify({"schema": "adaresearch.em_overrides.v1", "overrides": []}, " "))
		elif pth.ends_with("hand.json"):
			fw.store_string(JSON.stringify({"halls": {}}, " "))
		else:
			fw.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 1, "grid_pack": 0}, " "))
		fw.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", "res://ada_run/_trial_sweep_control.json")
	inst.set("_overrides_path", TRIAL_OVR)
	inst.set("_hand_path", "res://ada_run/_trial_map_hand.json")
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	var seg0: Node3D = null
	for c in inst.get_children():
		if c is Node3D and str(c.name).begins_with("Seg0_"):
			seg0 = c
	if seg0 == null:
		say("boot", false, "no Seg0")
		return _finish(original1)
	say("boot", true)

	# ── WALLS (map lane) ──────────────────────────────────────────────
	var tile: Array = seg0.get_meta("em_tile")
	var floor_c := Vector2i(-1, -1)
	var wall_c := Vector2i(-1, -1)
	for tz in range(1, tile.size() - 1):
		for tx in range(1, (tile[tz] as Array).size() - 1):
			var v := String((tile[tz] as Array)[tx])
			if floor_c.x < 0 and v == "1":
				floor_c = Vector2i(tx, tz)
			if wall_c.x < 0 and v.begins_with("4"):
				wall_c = Vector2i(tx, tz)
	var m1: String = inst.call("_rule_cell", seg0, 0, floor_c.x, floor_c.y + 4, false)
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
	var sv := str((((doc as Dictionary)["layers"] as Dictionary)["structure"][floor_c.y] as Array)[floor_c.x])
	say("wall_build", m1 != "" and sv == "2", "msg=%s cell=%s" % [m1, sv])
	var m2: String = inst.call("_rule_cell", seg0, 0, wall_c.x, wall_c.y + 4, false)
	doc = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
	sv = str((((doc as Dictionary)["layers"] as Dictionary)["structure"][wall_c.y] as Array)[wall_c.x])
	say("wall_open", m2 != "" and sv == "1", "msg=%s cell=%s" % [m2, sv])
	# the wall_c cell is a MERGED built wall — before 2026-08-23 only
	# session-built walls opened live and this toast said "F6 rebuilds"
	say("wall_open_live", m2.contains("OPENED"), "msg=%s" % m2)
	inst.call("_rule_undo_pop")
	inst.call("_rule_undo_pop")
	doc = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
	var sv_f := str((((doc as Dictionary)["layers"] as Dictionary)["structure"][floor_c.y] as Array)[floor_c.x])
	var sv_w := str((((doc as Dictionary)["layers"] as Dictionary)["structure"][wall_c.y] as Array)[wall_c.x])
	say("wall_undo", int(sv_f) <= 1 and int(sv_w) >= 2, "floor=%s wall=%s" % [sv_f, sv_w])

	# ── HOLES (value 0, 2026-08-23): dig through the floor, then lay it back
	var m3: String = inst.call("_rule_cell", seg0, 0, floor_c.x, floor_c.y + 4, false, "0")
	doc = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
	sv = str((((doc as Dictionary)["layers"] as Dictionary)["structure"][floor_c.y] as Array)[floor_c.x])
	say("hole_dig", m3.contains("HOLE") and sv == "0", "msg=%s cell=%s" % [m3, sv])
	var m4: String = inst.call("_rule_cell", seg0, 0, floor_c.x, floor_c.y + 4, false, "1")
	doc = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
	sv = str((((doc as Dictionary)["layers"] as Dictionary)["structure"][floor_c.y] as Array)[floor_c.x])
	say("hole_fill", m4.contains("LAID") and sv == "1", "msg=%s cell=%s" % [m4, sv])

	# ── ARTIFACTS (map lane): move, rotate, delete ───────────────────
	var recs: Array = inst.get("_edit_records")
	var art_i := -1
	for i in range(recs.size()):
		var r: Dictionary = recs[i]
		if String(r.get("token", "")) == "you_are_here" and r.get("seg") == seg0:
			art_i = i
	if art_i < 0:
		say("artifact_record", false, "no you_are_here")
	else:
		say("artifact_record", true)
		inst.set("_edit_sel", art_i)
		var tc_b: Array = ((recs[art_i] as Dictionary).get("tile_cell", []) as Array).duplicate()
		inst.call("_edit_nudge", 1, 0)
		var tc_a: Array = (recs[art_i] as Dictionary).get("tile_cell", [])
		doc = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
		var inter: Array = ((doc as Dictionary)["layers"] as Dictionary)["interactables"]
		var at_new := str((inter[int(tc_a[1])] as Array)[int(tc_a[0])])
		say("artifact_move", int(tc_a[0]) == int(tc_b[0]) + 1 and at_new.begins_with("you_are_here"),
			"tile_cell %s->%s tok=%s" % [str(tc_b), str(tc_a), at_new])
		inst.call("_edit_rotate", 90.0)
		doc = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
		inter = ((doc as Dictionary)["layers"] as Dictionary)["interactables"]
		var tok_r := str((inter[int(tc_a[1])] as Array)[int(tc_a[0])])
		say("artifact_rotate", tok_r.split("#")[0].split(":").size() > 1 \
			and str(tok_r.split("#")[0].split(":")[1]).is_valid_int() \
			and int(tok_r.split("#")[0].split(":")[1]) % 360 != int((recs[art_i] as Dictionary).get("rotation", -1.0)) - int((recs[art_i] as Dictionary).get("rotation", 0.0)), "tok=%s" % tok_r)
		say("artifact_rotate_enc", int(tok_r.split("#")[0].split(":")[1]) == int((recs[art_i] as Dictionary).get("rotation", -1.0)), "tok=%s rec_rot=%s" % [tok_r, str((recs[art_i] as Dictionary).get("rotation"))])
		inst.call("_edit_handle_key", KEY_DELETE)
		doc = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
		inter = ((doc as Dictionary)["layers"] as Dictionary)["interactables"]
		say("artifact_delete", str((inter[int(tc_a[1])] as Array)[int(tc_a[0])]).strip_edges() == "", "cell=%s" % str((inter[int(tc_a[1])] as Array)[int(tc_a[0])]))

	# ── THE SLID BODY (Palle's field case: "still get the map refuses —
	# no artifact at the source cell"): a record whose tile_cell sits
	# BESIDE its map token (the stamp slid it) must still encode, resolved
	# to the nearest occurrence
	var slid_i := -1
	for i3 in range(recs.size()):
		var r3: Dictionary = recs[i3]
		if String(r3.get("token", "")) == "fontana_puncture" and r3.get("seg") == seg0:
			slid_i = i3
	if slid_i < 0:
		say("slid_record", false, "no fontana_puncture")
	else:
		say("slid_record", true)
		var real_tc: Array = ((recs[slid_i] as Dictionary).get("tile_cell", []) as Array).duplicate()
		# falsify the record by one cell — the slide, simulated
		(recs[slid_i] as Dictionary)["tile_cell"] = [int(real_tc[0]) + 1, int(real_tc[1])]
		inst.set("_edit_sel", slid_i)
		inst.call("_edit_nudge", 0, 1)
		var tc_s: Array = (recs[slid_i] as Dictionary).get("tile_cell", [])
		var doc_s: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP1))
		var inter_s: Array = ((doc_s as Dictionary)["layers"] as Dictionary)["interactables"]
		var moved_ok := int(tc_s[0]) == int(real_tc[0]) and int(tc_s[1]) == int(real_tc[1]) + 1 			and str((inter_s[int(tc_s[1])] as Array)[int(tc_s[0])]).begins_with("fontana")
		say("slid_move_resolved", moved_ok, "record %s (real was %s)" % [str(tc_s), str(real_tc)])

	# ── PROPS / FURNITURE (rulings lane) ─────────────────────────────
	var fur_i := -1
	var show_i := -1
	for i2 in range(recs.size()):
		var r2: Dictionary = recs[i2]
		if fur_i < 0 and String(r2.get("kind", "")) in ["furniture", "prop"]:
			var fn: Node3D = inst.call("_node_or_null", r2.get("node"))
			if fn != null:
				fur_i = i2
		if show_i < 0 and String(r2.get("kind", "")) == "showing":
			var sn: Node3D = inst.call("_node_or_null", r2.get("node"))
			if sn != null:
				show_i = i2
	if fur_i < 0:
		say("prop_record", false, "no prop/furniture record")
	else:
		say("prop_record", true)
		inst.set("_edit_sel", fur_i)
		inst.call("_edit_fine", 0.2, 0.0, 0.0)
		inst.call("_edit_rotate", 15.0)
		inst.call("_edit_handle_key", KEY_DELETE)
		var ovs: Array = inst.get("_edit_overrides")
		var has_off := false
		var has_rot := false
		var has_rem := false
		for o in ovs:
			var od: Dictionary = o
			if String(od.get("kind", "")) in ["furniture", "prop"]:
				if od.get("offset") is Array:
					has_off = true
				if od.has("rotation"):
					has_rot = true
				if bool(od.get("remove", false)):
					has_rem = true
		say("prop_offset", has_off)
		say("prop_rotate", has_rot)
		say("prop_remove", has_rem)
	if show_i < 0:
		say("frame_record", false, "no showing record")
	else:
		inst.set("_edit_sel", show_i)
		inst.call("_edit_fine", 0.0, 0.2, 0.0)
		var ovs2: Array = inst.get("_edit_overrides")
		var frame_ok := false
		for o2 in ovs2:
			if String((o2 as Dictionary).get("kind", "")) == "showing" and (o2 as Dictionary).get("offset") is Array:
				frame_ok = true
		say("frame_offset", frame_ok)

	# ── ENTER ROOM (rulings lane, negative z) ────────────────────────
	var mv: String = inst.call("_rule_cell", seg0, 0, 3, 1, false)
	var vest_ok := false
	for o3 in (inst.get("_edit_overrides") as Array):
		var o3d: Dictionary = o3
		if String(o3d.get("kind", "")) == "cell" and (o3d.get("from", []) as Array).size() >= 2 \
				and int((o3d.get("from") as Array)[1]) < 0:
			vest_ok = true
	say("enter_room_cell", mv != "" and vest_ok, "msg=%s" % mv)

	# ── SAVE (the rulings flush to the trial file) ───────────────────
	inst.set("_edit_dirty", true)
	inst.call("_edit_flush")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRIAL_OVR))
	say("save_flush", saved is Dictionary and ((saved as Dictionary).get("overrides", []) as Array).size() > 0)

	_finish(original1)


func _finish(original1: String) -> void:
	# RESTORE the map byte-for-byte, retrying past editor scan locks
	var f: FileAccess = null
	for attempt in range(20):
		f = FileAccess.open(MAP1, FileAccess.WRITE)
		if f != null:
			break
		OS.delay_msec(100)
	if f == null:
		say("map_restored", false, "LOCKED — git checkout it")
	else:
		f.store_string(original1)
		f.close()
		say("map_restored", FileAccess.get_file_as_string(MAP1) == original1)
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks": checks, "fails": fails,
		"at": Time.get_datetime_string_from_system(false, true)}, " "))
	out.close()
	print("EDIT SWEEP: %d check(s), %d fail(s)%s" % [checks.size(), fails.size(),
		("" if fails.is_empty() else " — " + "; ".join(fails))])
	quit(0 if fails.is_empty() else 1)
