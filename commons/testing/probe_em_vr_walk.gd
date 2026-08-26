extends SceneTree
## THE VR WALK, ON THE DESKTOP (2026-08-26, Palle: "can we test simulate the vr
## on the computer to test loading times and map progression").
##
## What this DOES simulate: every millisecond the museum spends in GDScript —
## opening a hall, draining its exhibit blueprints, promoting and demoting the
## three-shell window, freeing what falls behind. That is where the museum's
## own boot and streaming cost lives, and it is the same code on both machines.
##
## What it CANNOT simulate, and must not be read as: the Quest's GPU, the XR
## compositor, shader pipeline compilation on Adreno, or the hand rig. A
## headless run uses the dummy renderer. A stall reported here is a REAL stall;
## the absence of one here does not mean the headset is smooth.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_em_vr_walk.gd -- --metres=420 --step=2

var _met: Dictionary = {}
const OUT := "res://ada_run/vr_walk.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var metres := float(_arg("metres", "420"))
	var step := float(_arg("step", "2"))
	# THE RIG FIRST. --em-vr sets _vr, but with no XRCamera3D the museum's
	# _process returns early waiting for one and nothing streams at all. Give
	# it an origin and an eye and it runs the REAL VR lane — build ahead, free
	# behind, three-shell ownership, the one-hall render window — with the
	# probe doing nothing but walking the rig forward.
	var lane_pre := _arg("lane", "vr")
	var origin := XROrigin3D.new()
	origin.name = "ProbeXROrigin"
	origin.current = true
	var eye := XRCamera3D.new()
	eye.name = "ProbeXRCamera"
	eye.position = Vector3(0, 1.65, 0)
	origin.add_child(eye)
	if lane_pre != "vr":
		origin.current = false          # a desktop walk must not find an eye
	get_root().add_child(origin)

	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	# --lane=desktop walks the SAME route with the VR lane off, so the two
	# as-built records can be diffed: does the headset build the same hall?
	var frames_per_step := maxi(1, int(_arg("frames", "8")))
	var lane := _arg("lane", "vr")
	if lane == "vr":
		inst.set("_force_vr", true)
	# THE PATIENT STAMP IS OFF HEADLESS (2026-08-26). _stamp defers into the
	# frame-budgeted queue only when (_force_patient or not _headless) - so a
	# headless probe measures the ONE-PASS path that no real run takes, and
	# every transplant number in this file was measured with the museum's own
	# frame budget switched off. _force_patient exists for exactly this; the
	# comment on it says "probes set this to measure the deferred path
	# headless". --patient=0 restores the old, unreal reading.
	inst.set("_force_patient", _arg("patient", "1") != "0")
	inst.set("EM_CONTROL", "res://ada_run/_trial_vw_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_vw_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "", "first_map": "",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	var t_boot := Time.get_ticks_msec()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	var boot_ms := Time.get_ticks_msec() - t_boot

	var rep := "THE VR WALK — %d m in %.1f m steps (headless: GDScript cost only, no GPU)\n" % [int(metres), step]
	rep += "  museum stood up in %d ms\n\n" % boot_ms
	rep += "  lane=%s, patient=%s, %d frame(s) per step; the museum reports vr=%s
" % [
		lane, _arg("patient", "1"), frames_per_step, str(inst.get("_vr"))]
	rep += "  (times below are the WORST FRAME in each step, not the sum)

"
	var player: Node3D = inst.get("_player") as Node3D
	var halls: Array = []          # one row per hall as it opens
	var stalls: Array = []         # every step over 40 ms
	var seen := 0
	var z := 0.0
	var steps := 0
	var total_us := 0
	var vr_us := 0
	while z < metres:
		z += step
		origin.position.z = z              # the rig walks; the museum follows the eye
		if lane != "vr" and player != null:
			player.position.z = z
		if player != null:
			player.position.z = z          # keep the desktop body in step, as the death does
		# FRAMES PER STEP (2026-08-26). A walker covers 2 m in about a second,
		# which at 90 Hz is ninety frames for the patient stamp to drain into.
		# This probe was giving it ONE - so the queue could never show its
		# benefit and the deferred path measured WORSE than the blocking one.
		# The worst FRAME is what matters in a headset, so the loop times each
		# frame separately and keeps the peak rather than the sum.
		var t0 := Time.get_ticks_usec()
		var peak := 0
		for _fi in range(frames_per_step):
			var fa := Time.get_ticks_usec()
			await process_frame
			await physics_frame
			peak = maxi(peak, int(Time.get_ticks_usec() - fa))
		var t1 := t0 + peak
		var t2 := t1                       # the museum ran its own VR pass inside _process
		steps += 1
		total_us += t1 - t0
		vr_us += t2 - t1
		var segs: Array = inst.get("_segments")
		for s_v0 in segs:
			var sd0: Dictionary = s_v0
			var nm: String = String(sd0.get("map", sd0.get("pearl", "?")))
			if nm == "" or _met.has(nm):
				continue
			_met[nm] = true
			halls.append({"z": z, "map": nm, "ms": float(t1 - t0) / 1000.0,
				"resident": segs.size()})
		seen = segs.size()
		if (t1 - t0) > 40000:
			var here := ""
			for s_v in segs:
				var sd: Dictionary = s_v
				if z >= float(sd["z0"]) and z < float(sd["z1"]):
					here = String(sd.get("map", "?"))
			stalls.append({"z": z, "ms": float(t1 - t0) / 1000.0, "where": here})
	rep += "  MAP PROGRESSION — %d hall(s) opened over %d m\n" % [halls.size(), int(metres)]
	for h_v in halls:
		var h: Dictionary = h_v
		rep += "    z %6.1f  %-28s opened in %7.1f ms   %d resident\n" % [
			h["z"], h["map"], h["ms"], h["resident"]]
	# THE CENSUS AT THE END OF THE WALK (2026-08-26, Palle: "so now in vr is
	# that the same hall as in desktop?"). The as-built record is written when a
	# segment FINISHES BUILDING, so a VR shell records zero bodies and then fills
	# on promotion - the file cannot tell "never drained" from "drained after the
	# record was written". This asks the live tree instead.
	rep += "
  AT THE END OF THE WALK - what is actually in each resident hall
"
	for s_v9 in inst.get("_segments"):
		var sd9: Dictionary = s_v9
		var sn9: Node3D = sd9.get("node")
		if sn9 == null or not is_instance_valid(sn9):
			continue
		var bodies := 0
		for n9 in sn9.find_children("*", "Node3D", true, false):
			if n9.has_meta("artifact_lookup_name"):
				bodies += 1
		var here: bool = z >= float(sd9["z0"]) and z < float(sd9["z1"])
		rep += "    %-26s %3d bodies  shell=%s%s
" % [
			String(sd9.get("map", sd9.get("pearl", "?"))), bodies,
			str(sn9.get_meta("em_vr_shell", false)), "   <- the walker is here" if here else ""]

	rep += "\n  LOADING — %d steps, %.1f ms mean, VR ownership pass %.2f ms mean\n" % [
		steps, float(total_us) / 1000.0 / maxf(1.0, float(steps)), float(vr_us) / 1000.0 / maxf(1.0, float(steps))]
	stalls.sort_custom(func(a, b): return float(a["ms"]) > float(b["ms"]))
	rep += "  %d step(s) over 40 ms — in a headset every one of these is a visible hitch:\n" % stalls.size()
	for k in range(mini(10, stalls.size())):
		var s2: Dictionary = stalls[k]
		rep += "    z %6.1f  %8.1f ms  %s\n" % [s2["z"], s2["ms"], s2["where"]]
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
