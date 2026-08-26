extends SceneTree
## SLOW TO OPEN, OR SLOW TO STAND IN? (2026-08-26, Palle: "some hall still
## rendering slow like in Point_Animatedcube"). Opening cost and steady-state
## cost are different faults with different fixes: one is loading and building,
## the other is what the hall does every frame afterwards. This builds a hall,
## stands still in it, and times frames once nothing more is arriving.
##
## Headless: GDScript and physics only, no GPU. A hall that is quiet here and
## heavy in the headset is a RENDER cost, which is itself the answer.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_hall_dwell.gd -- --chapter=primitives --map=Point_Animatedcube

const OUT := "res://ada_run/hall_dwell.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var map_name := _arg("map", "Point_Animatedcube")
	var chapter := _arg("chapter", "primitives")
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_hd_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", chapter)
	if _arg("walk", "1") == "0":
		inst.set("start_map", map_name)
	inst.set("_force_patient", true)
	var ctl := FileAccess.open("res://ada_run/_trial_hd_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": chapter,
		"first_map": (map_name if _arg("walk", "1") == "0" else ""),
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	var t0 := Time.get_ticks_msec()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	inst.call("flush_stamps")
	await create_timer(2.5).timeout
	var open_ms := Time.get_ticks_msec() - t0
	# WALK TO IT. The hall must be reached the way a visitor reaches it, or the
	# lobby's dressing is counted against it.
	var seg_found: Node3D = null
	var zz := 0.0
	if _arg("walk", "1") != "0":
		var pl: Node3D = inst.get("_player") as Node3D
		while zz < 600.0 and seg_found == null:
			zz += 4.0
			if pl != null:
				pl.position.z = zz
			await create_timer(0.22).timeout
			for s_w in inst.get("_segments"):
				var sw: Dictionary = s_w
				if String(sw.get("map", "")) == map_name and zz >= float(sw["z0"]) and zz < float(sw["z1"]):
					seg_found = sw.get("node")
		if seg_found == null:
			print("[dwell] never reached %s in 600 m" % map_name)

	# stand in the middle of the hall and let it settle
	var seg: Node3D = null
	var z0 := 0.0
	var z1 := 24.0
	for s_v in inst.get("_segments"):
		var sd: Dictionary = s_v
		if String(sd.get("map", "")) == map_name:
			seg = sd.get("node")
			z0 = float(sd["z0"]); z1 = float(sd["z1"])
	var player: Node3D = inst.get("_player") as Node3D
	if player != null:
		player.position = Vector3(7.5, 0.1, (z0 + z1) * 0.5)
	for _s in range(30):
		await process_frame                     # settle: let arrivals finish
	# WALL TIME IS THE CLOCK, NOT THE WORK (2026-08-26). This loop awaited a
	# process frame AND a physics frame, so every reading was a 60 Hz tick -
	# 16.67 ms - and three halls with quite different contents all measured
	# 15.45-15.51 ms, which looked like a flat museum overhead and was really
	# the pacing. Godot's own monitors know the difference: TIME_PROCESS is the
	# seconds spent in idle logic, TIME_PHYSICS in the physics step.
	var frames: Array = []
	var proc_ms := 0.0
	var phys_ms := 0.0
	for _f in range(150):
		var a := Time.get_ticks_usec()
		await process_frame
		frames.append(Time.get_ticks_usec() - a)
		proc_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		phys_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	frames.sort()
	var n := frames.size()
	var sum := 0
	for v in frames:
		sum += int(v)
	var bodies := 0
	var meshes := 0
	var mm := 0
	if seg != null:
		for x in seg.find_children("*", "Node3D", true, false):
			if x.has_meta("artifact_lookup_name"):
				bodies += 1
		meshes = seg.find_children("*", "MeshInstance3D", true, false).size()
		mm = seg.find_children("*", "MultiMeshInstance3D", true, false).size()
	var rep := "STANDING IN %s · %s\n" % [chapter, map_name]
	rep += "  the museum opened in %d ms (boot + this hall)\n" % open_ms
	rep += "  the hall holds %d artifact(s), %d MeshInstance3D, %d MultiMesh\n" % [bodies, meshes, mm]
	rep += "  standing still, 150 frames:\n"
	rep += "    median %6.2f ms\n" % (float(frames[n / 2]) / 1000.0)
	rep += "    mean   %6.2f ms\n" % (float(sum) / float(n) / 1000.0)
	rep += "    p95    %6.2f ms\n" % (float(frames[int(n * 0.95)]) / 1000.0)
	rep += "    worst  %6.2f ms\n" % (float(frames[n - 1]) / 1000.0)
	rep += "  the WORK inside those frames, from Godot's own monitors:
"
	# A MONITOR THAT EXCEEDS ITS OWN FRAME IS NOT A MEASUREMENT. TIME_PROCESS
	# read this way came back at 140 ms inside a 6.9 ms frame, so the accounting
	# is wrong somewhere and the number must not be quoted. Said out loud rather
	# than printed as fact - a wrong number nobody flags is how three earlier
	# readings in this session became wrong conclusions.
	var idle: float = proc_ms / float(n)
	var frame_mean: float = float(sum) / float(n) / 1000.0
	if idle > frame_mean:
		rep += "    idle logic   UNUSABLE (%.1f ms claimed inside a %.2f ms frame)
" % [idle, frame_mean]
	else:
		rep += "    idle logic   %6.2f ms/frame
" % idle
	rep += "    physics      %6.2f ms/frame
" % (phys_ms / float(n))
	rep += "    nodes in the tree %d
" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	rep += "  %s\n" % ("a frame budget at 90 Hz is 11.1 ms; at 72 Hz it is 13.9 ms")
	# WHO OWNS THE MESHES, AND WHO TICKS. 453 MeshInstance3D in one hall is a
	# draw call each, and a node with _process is GDScript every frame. Both are
	# steady-state costs that no build-time budget can reach.
	if seg != null:
		var owners: Array = []
		for a_v in seg.find_children("*", "Node3D", true, false):
			var an := a_v as Node3D
			if not an.has_meta("artifact_lookup_name"):
				continue
			var mi: int = an.find_children("*", "MeshInstance3D", true, false).size()
			var proc := 0
			if an.is_processing() or an.is_physics_processing():
				proc += 1
			for c_v in an.find_children("*", "Node", true, false):
				var c := c_v as Node
				if c.is_processing() or c.is_physics_processing():
					proc += 1
			owners.append({"tok": String(an.get_meta("artifact_lookup_name")), "mi": mi, "proc": proc})
		owners.sort_custom(func(a, b): return int(a["mi"]) > int(b["mi"]))
		rep += "
  what the hall is made of, most meshes first:
"
		rep += "    %-32s %7s %8s
" % ["artifact", "meshes", "ticking"]
		var claimed := 0
		var ticking := 0
		for k in range(owners.size()):
			var o: Dictionary = owners[k]
			claimed += int(o["mi"])
			ticking += int(o["proc"])
			if k < 8:
				rep += "    %-32s %7d %8d
" % [o["tok"], o["mi"], o["proc"]]
		rep += "    %-32s %7d %8d
" % ["- the artifacts together -", claimed, ticking]
		rep += "    %-32s %7d
" % ["- the museum's own dressing -", meshes - claimed]
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
