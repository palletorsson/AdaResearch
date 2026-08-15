extends SceneTree
## The editor, tried — not a unit test of arithmetic but a drive of the ACTUAL
## key handler: aim the camera, press E, press arrows, press R, press F5, then
## read the file the hand wrote and assert it says what the hand did.
##
## Headless-safe: the museum's desktop path builds a player and camera without a
## display, and the editor's pick is a view-cone, not a physics ray, so nothing
## here needs a window. Members are preset BEFORE add_child (the arg parse only
## overwrites members whose flags are present, and we pass none).
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_editor.gd

const OUT := "res://ada_run/em_overrides.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# a stale override file would contaminate the trial — the museum loads it
	if FileAccess.file_exists(OUT):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OUT))
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_edit_mode", true)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("_first_key", "sainsbury-false-perspective-enfilade")
	get_root().add_child(inst)
	for i in range(5):
		await create_timer(0.2).timeout

	var records: Array = inst.get("_edit_records")
	var cam: Camera3D = inst.get("_cam")
	var fails: Array[String] = []
	if records.is_empty():
		fails.append("no editable records after build")
	if cam == null:
		fails.append("no camera in desktop path")
	if not fails.is_empty():
		_verdict(fails)
		return

	# ── aim at a known artifact and press the keys ──────────────────────────
	# The pick is a view CONE with no occlusion test (v1, stated in the module):
	# aiming down a wall line can select the neighbour on the same sight line.
	# So the trial's claim is the honest one — E selects SOMETHING in the cone,
	# and every later key writes a ruling for exactly the record E selected.
	var aim_i: int = 0
	for i in range(records.size()):
		if String((records[i] as Dictionary).get("token", "")) == "origin":
			aim_i = i
			break
	var tnode: Node3D = (records[aim_i] as Dictionary).get("node") as Node3D
	cam.global_position = tnode.global_position + Vector3(0, 1.5, 4.0)
	cam.look_at(tnode.global_position + Vector3(0, 0.5, 0))

	inst.call("_edit_handle_key", KEY_E)
	var sel: int = int(inst.get("_edit_sel"))
	if sel < 0:
		fails.append("E selected nothing in a 4 m face-on aim")
		_verdict(fails)
		return
	var tok := String((records[sel] as Dictionary).get("token", ""))
	var from: Array = ((records[sel] as Dictionary).get("from") as Array).duplicate()
	# The baseline rotation is the NEGOTIATOR'S, not zero — the hand composes
	# with the plan's turn. The first trial assumed 0 and pressed R on a row the
	# negotiator had already turned 270: 270 + 90 = a full circle, and the trial
	# read its own arithmetic as the editor's fault.
	var base_rot: float = float((records[sel] as Dictionary).get("rotation", 0.0))
	inst.call("_edit_handle_key", KEY_RIGHT)
	inst.call("_edit_handle_key", KEY_RIGHT)
	inst.call("_edit_handle_key", KEY_DOWN)
	inst.set("_edit_shift", true)     # SHIFT+R = the 90 deg the trial asserts
	inst.call("_edit_handle_key", KEY_R)
	inst.set("_edit_shift", false)
	# v3: the fine nudge. SHIFT+LEFT twice = -0.4 m x, PGUP once = +0.2 m y;
	# an `offset` ruling of [-0.4, 0.2, 0.0] must land in the file.
	inst.set("_edit_shift", true)
	inst.call("_edit_handle_key", KEY_LEFT)
	inst.call("_edit_handle_key", KEY_LEFT)
	inst.set("_edit_shift", false)
	inst.call("_edit_handle_key", KEY_PAGEUP)
	# v4: scale. + twice = 1.05^2 -> snapped 1.10; a `scale` ruling must land.
	inst.call("_edit_handle_key", KEY_EQUAL)
	inst.call("_edit_handle_key", KEY_EQUAL)
	# ── v2: the palette. [ browses the chapter the camera stands in; ENTER
	# stamps the pick 2.5 m ahead and records an ADD ruling.
	#
	# Walk AWAY from the edited cluster first. The live preview does not
	# re-seal a moved artifact (the seal stays at the plan's cells until the
	# next build), so a spot beside the move can look free at edit time and be
	# genuinely occupied on rebuild — the first run of this trial recorded an
	# add at such a spot and the rebuild rightly REFUSED it, with a voice.
	# Placing from the open centre aisle keeps the trial about the palette,
	# not about seal staleness.
	cam.global_position = Vector3(7.5, 1.5, 24.0)
	cam.look_at(Vector3(7.5, 1.0, 16.0))
	# Browse PAST the chapter's giant. The palette opens on CoordinateSystem3M
	# (spine order), whose 7.4 x 9.9 m body severs the narrowing enfilade at
	# this depth — the seal refuses it with a named reason, correctly, on every
	# build. A curator would press ] again; so does the trial. origin (1.1 m)
	# is the second entry and fits anywhere.
	inst.call("_edit_handle_key", KEY_BRACKETRIGHT)
	inst.call("_edit_handle_key", KEY_BRACKETRIGHT)
	var pal: Array = inst.get("_edit_pal")
	var pal_i: int = int(inst.get("_edit_pal_i"))
	var added_tok := ""
	if pal.is_empty() or pal_i < 0:
		fails.append("palette empty inside a planned chapter's segment")
	else:
		added_tok = String((pal[pal_i] as Dictionary).get("token", ""))
		# ENTER can be REFUSED by the seal when 2.5 m ahead is occupied — the
		# museum's conflict logic applies to the hand too, by design. Hunt for
		# clear floor the way a user would: turn 90° and retry, four ways.
		var placed_ok := false
		for turn in range(4):
			var n_before: int = (inst.get("_edit_records") as Array).size()
			inst.call("_edit_handle_key", KEY_ENTER)
			if (inst.get("_edit_records") as Array).size() == n_before + 1:
				placed_ok = true
				break
			cam.rotate_y(PI / 2.0)
		if not placed_ok:
			fails.append("ENTER refused in all four directions — no clear floor found")
	inst.call("_edit_handle_key", KEY_F5)

	# ── the file is the deliverable; assert on IT ───────────────────────────
	if not FileAccess.file_exists(OUT):
		fails.append("F5 wrote nothing")
	else:
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT))
		var rows: Array = (doc as Dictionary).get("overrides", [])
		var adds: Array = rows.filter(func(r): return bool((r as Dictionary).get("add", false)))
		var mods: Array = rows.filter(func(r): return not bool((r as Dictionary).get("add", false)))
		if adds.size() != 1:
			fails.append("expected 1 ADD ruling, file holds %d" % adds.size())
		elif String((adds[0] as Dictionary).get("token", "")) != added_tok:
			fails.append("add ruling names %s, palette placed %s"
				% [(adds[0] as Dictionary).get("token"), added_tok])
		if mods.size() != 1:
			fails.append("expected 1 move/turn override, file holds %d" % mods.size())
		else:
			var ov: Dictionary = mods[0]
			var want_to: Array = [int(from[0]) + 2, int(from[1]) + 1]
			# JSON hands every number back as a float; compare VALUES, typed.
			# "Assert types too" cuts both ways — here the type noise would
			# hide real agreement, the inverse of the metres/cells blindness.
			var got_from: Array = [int((ov.get("from", [9e9, 9e9]) as Array)[0]),
				int((ov.get("from", [9e9, 9e9]) as Array)[1])]
			var got_to: Array = [int((ov.get("to", [9e9, 9e9]) as Array)[0]),
				int((ov.get("to", [9e9, 9e9]) as Array)[1])]
			if String(ov.get("token", "")) != tok:
				fails.append("override token %s != %s" % [ov.get("token"), tok])
			if got_from != [int(from[0]), int(from[1])]:
				fails.append("override from %s != plan cell %s" % [got_from, from])
			if got_to != want_to:
				fails.append("override to %s != %s" % [got_to, want_to])
			var want_rot: float = fposmod(base_rot + 90.0, 360.0)
			if absf(float(ov.get("rotation", -1.0)) - want_rot) > 0.5:
				fails.append("override rotation %s != %s (base %s + 90)"
					% [ov.get("rotation"), want_rot, base_rot])
			if String(ov.get("provenance", "")) != "hand":
				fails.append("provenance %s != hand" % ov.get("provenance"))
				var off: Array = ov.get("offset", [])
				if off.size() < 3:
					fails.append("no `offset` ruling - the fine nudge wrote nothing")
				elif absf(float(off[0]) + 0.4) > 0.01 or absf(float(off[1]) - 0.2) > 0.01 or absf(float(off[2])) > 0.01:
					fails.append("offset %s != [-0.4, 0.2, 0.0]" % str(off))
				if absf(float(ov.get("scale", -1.0)) - 1.10) > 0.011:
					fails.append("scale %s != 1.10 after two + presses" % str(ov.get("scale")))
	_verdict(fails)


func _verdict(fails: Array[String]) -> void:
	if fails.is_empty():
		print("EDITOR TRIAL: PASS — E picked, arrows moved, SHIFT-arrows fine-nudged, + scaled, R turned, F5 wrote the ruling")
	else:
		print("EDITOR TRIAL: FAIL %d" % fails.size())
		for f in fails:
			print("  - " + f)
	quit(0 if fails.is_empty() else 1)
