extends SceneTree
## THE VIEW TOGGLE'S MEMORY (2026-08-25, Palle: "when changing view in endless
## museum between 3d, iso and topdown we want the layer to be in the same spot
## as in the view we are coming from... Now I'm back at the beginning").
##
## Reproduces the whole round trip in one headless boot: stand the walker deep
## in a chapter, ask _toggle_doc() what it would write, write exactly that, boot
## a SECOND museum from it, and report where the walker actually lands. If the
## writer is honest and the reader still opens at the door, the fault is in the
## reader — and the other way round.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_view_resume.gd -- --chapter=color

const CTL := "res://ada_run/_trial_resume_control.json"
const OUT := "res://ada_run/view_resume.txt"

var rep := ""


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _boot(chapter: String, first_map: String) -> Node3D:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": chapter, "first_map": first_map,
		"dollhouse": 0, "grid_pack": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_trial_resume_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_resume_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", first_map)
	get_root().add_child(inst)
	return inst


func _run() -> void:
	var chapter := _arg("chapter", "color")
	var inst := _boot(chapter, "")
	await create_timer(3.0).timeout
	inst.call("flush_stamps")
	await create_timer(1.0).timeout

	# walk forward: build a few halls and stand in the THIRD one
	for _i in range(3):
		inst.call("_build_segment")
	await create_timer(1.0).timeout
	var segs: Array = inst.get("_segments")
	rep += "BOOT 1 — %d segment(s):\n" % segs.size()
	for sv in segs:
		var sd: Dictionary = sv
		rep += "   z %6.1f..%-6.1f  pearl=%-22s map=%s\n" % [float(sd.get("z0", 0)),
			float(sd.get("z1", 0)), String(sd.get("pearl", "?")), String(sd.get("map", "(none)"))]
	if segs.size() < 3:
		rep += "  only %d halls — cannot test a deep resume\n" % segs.size()
	var target: Dictionary = segs[mini(2, segs.size() - 1)]
	var stand := Vector3(float(target.get("w", 10)) / 2.0,
		0.2, float(target["z0"]) + 4.0)
	var player: Node3D = inst.get("_player") as Node3D
	player.position = stand
	await create_timer(0.5).timeout
	rep += "\n  stood the walker at %s — inside %s\n" % [str(stand), String(target.get("map", "?"))]

	var doc: Dictionary = inst.call("_toggle_doc")
	rep += "\n  _toggle_doc() would write:\n"
	for k in ["first_chapter", "first_map", "_resume_hall", "dollhouse", "resume_eye", "resume_yaw"]:
		rep += "     %-16s %s\n" % [k, str(doc.get(k))]

	# write it exactly as _doll_toggle would, then boot a second museum from it
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify(doc, " "))
	f.close()
	inst.queue_free()
	await create_timer(1.0).timeout

	var inst2: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst2.set("EM_CONTROL", CTL)
	inst2.set("_overrides_path", "res://ada_run/_trial_resume_overrides.json")
	inst2.set("_hand_path", "res://ada_run/_trial_resume_hand.json")
	get_root().add_child(inst2)
	await create_timer(4.0).timeout
	var p2: Node3D = inst2.get("_player") as Node3D
	var segs2: Array = inst2.get("_segments")
	rep += "\nBOOT 2 — resumed from that file, %d segment(s):\n" % segs2.size()
	for sv in segs2:
		var sd: Dictionary = sv
		rep += "   z %6.1f..%-6.1f  map=%s\n" % [float(sd.get("z0", 0)), float(sd.get("z1", 0)),
			String(sd.get("map", "(none)"))]
	# LOCAL z, not absolute. The resumed walk reopens AT that chapter, so the
	# hall sits at a different offset than it did before — comparing world z
	# across two builds reports a correct resume as a failure, and did once.
	var want_hall := String(doc.get("_resume_hall", "?"))
	var base2 := 0.0
	var in_hall := false
	for sv2 in segs2:
		var sd2: Dictionary = sv2
		if String(sd2.get("map", "")) == want_hall:
			base2 = float(sd2["z0"])
			in_hall = true
	var re: Array = doc.get("resume_eye", [0.0, 0.0, 0.0])
	var want_local := float(re[2])
	var got_local: float = p2.position.z - base2
	var dz: float = absf(got_local - want_local)
	rep += "\n  the walker stands at %s\n" % str(p2.position)
	rep += "  %s opens at z %.1f, so local z %.2f — wanted %.2f\n" % [want_hall, base2, got_local, want_local]
	rep += "  x %.2f — wanted %.2f\n" % [p2.position.x, float(re[0])]
	rep += "\n  %s (%.2f m out, in the right hall: %s)\n" % [
		"RESUMED" if (in_hall and dz < 2.0) else "BACK AT THE BEGINNING", dz, str(in_hall)]
	var fo := FileAccess.open(OUT, FileAccess.WRITE)
	fo.store_string(rep)
	fo.close()
	print(rep)
	quit(0)
