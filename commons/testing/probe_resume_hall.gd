extends SceneTree
## THE OTHER HALF OF THE TOGGLE (2026-08-25, Palle: "when I shift to 3d I
## always end up in map one"). probe_view_position proved the toggle WRITES the
## right hall. This boots a museum from such a control and asks where the
## walker actually stands — the half that was never tested, and the half the
## complaint is about.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_resume_hall.gd -- --map=Point_Line_Grid --chapter=primitives --local=11

const OUT := "res://ada_run/resume_hall.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var want_map := _arg("map", "Point_Line_Grid")
	var chapter := _arg("chapter", "primitives")
	var local := float(_arg("local", "11"))
	# exactly what _doll_toggle writes when the eye is over that hall
	var ctl := FileAccess.open("res://ada_run/_trial_rh_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "first_map": want_map,
		"dollhouse": 0, "grid_pack": 0, "gate_open": 1,
		"resume_eye": [7.5, 0.0, local], "resume_yaw": 3.14}, " "))
	ctl.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_rh_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	get_root().add_child(inst)
	await create_timer(3.5).timeout

	var rep := "THE RESUME\n  asked for %s · %s at local z %.1f\n" % [chapter, want_map, local]
	var segs: Array = inst.get("_segments")
	var first_map := ""
	var first_pearl := ""
	if not segs.is_empty():
		var s0: Dictionary = segs[0]
		first_map = String(s0.get("map", ""))
		first_pearl = String(s0.get("pearl", ""))
	rep += "  the museum opened at %s (%s)\n" % [first_map if first_map != "" else "?", first_pearl]
	var player: Node3D = inst.get("_player") as Node3D
	rep += "  the walker stands at %s\n" % str(player.position)
	# WHICH HALL THE WALKER IS IN, not which one opened first: the pearl's head
	# is built first by design, and the named page sits a few segments in
	var stands_in := ""
	for s_v in segs:
		var sd2: Dictionary = s_v
		if player.position.z >= float(sd2["z0"]) and player.position.z < float(sd2["z1"]):
			stands_in = String(sd2.get("map", ""))
	rep += "  the walker is in %s
" % (stands_in if stands_in != "" else "(no hall)")
	var hall_ok: bool = stands_in == want_map
	var base_z := 0.0
	for s_v2 in segs:
		var sd3: Dictionary = s_v2
		if String(sd3.get("map", "")) == want_map:
			base_z = float(sd3["z0"])
	var z_ok: bool = absf(player.position.z - (local + base_z)) < 3.0
	rep += "  hall: %s   z: %s (%.1f vs %.1f)\n" % ["ok" if hall_ok else "WRONG",
		"ok" if z_ok else "WRONG", player.position.z, local]
	rep += "  %s\n" % ("PASS" if hall_ok and z_ok else "FAIL — this is the map-one complaint")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
