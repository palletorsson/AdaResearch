extends SceneTree
## ONE POSITION FOR THREE VIEWS (2026-08-25, Palle: "if we scroll in top down
## and go the 3d we should end up in the top down player position in the 3d
## map, the same for iso"). The pan and the wheel already move the WALKER, so
## within a session the three views share a position by construction. What did
## not survive was the toggle, which rebuilds the museum around the eye: it
## recorded the chapter and a z measured from the hall's own start, never WHICH
## hall, so the chapter reopened at its first pearl and the local z landed
## there. This walks the eye into each built hall and asks what the toggle
## would write.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_view_position.gd

const OUT := "res://ada_run/view_position.txt"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_vp_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_vp_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "", "first_map": "",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout

	var rep := "ONE POSITION, THREE VIEWS\n"
	var player: Node3D = inst.get("_player") as Node3D
	# scroll the plan down the museum, the way the wheel does, and let the
	# stream open halls as the eye reaches them
	var pass_n := 0
	var fail_n := 0
	for step in range(12):
		player.position.z = 6.0 + float(step) * 9.0
		await create_timer(0.35).timeout
		var doc: Dictionary = inst.call("_toggle_doc")
		# which hall is the eye actually in, by the segment list?
		var want_map := ""
		var want_local := -1.0
		for s_v in inst.get("_segments"):
			var sd: Dictionary = s_v
			if player.position.z >= float(sd["z0"]) and player.position.z < float(sd["z1"]):
				want_map = String(sd.get("map", ""))
				want_local = player.position.z - float(sd["z0"])
		if want_map == "":
			continue
		var got_map := String(doc.get("first_map", ""))
		var got_local: float = float((doc.get("resume_eye") as Array)[2])
		var ok: bool = got_map == want_map and absf(got_local - want_local) < 0.5
		if ok:
			pass_n += 1
		else:
			fail_n += 1
		rep += "  z %6.1f  in %-26s  toggle says %-26s local %5.1f (want %5.1f)  %s\n" % [
			player.position.z, want_map, got_map if got_map != "" else "(nothing)",
			got_local, want_local, "ok" if ok else "WRONG HALL"]
	rep += "\n  %d ok, %d wrong\n" % [pass_n, fail_n]
	rep += "  %s\n" % ("PASS the toggle names the hall the eye is over" if fail_n == 0
		else "FAIL the walker would land in another hall")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
