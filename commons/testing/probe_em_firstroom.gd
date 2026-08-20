extends SceneTree
## WHAT EATS THE FIRST ROOM — per-token accounting of segment 0, plus the
## cost of each opening _build_segment call (the hitches Palle feels as
## "the world jumps until it settles").
##
## Counts, not guesses: for every artifact root in segment 0 — mesh instances,
## vertices (est. KB on GPU), lights, RigidBody3D, AudioStreamPlayer3D,
## Camera3D, SubViewport, GPUParticles3D — grouped by token. Plus: how many
## roots the near-artifact cull actually shows from the spawn standpoint.
##
##   python tools/godot_watchdog.py --expect=ada_run/em_firstroom_report.json -- \
##     <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_em_firstroom.gd

const OUT := "res://ada_run/em_firstroom_report.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var mem0 := OS.get_static_memory_usage()
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("_force_patient", true)   # measure the deferred path even headless
	get_root().add_child(inst)   # _ready: plan parse + segment 0, synchronous
	var t_seg0 := Time.get_ticks_msec() - t0
	var mem_seg0 := OS.get_static_memory_usage()
	await process_frame
	# the owed segments, timed one by one — each of these is ONE FRAME live
	var seg_times: Array = [t_seg0]
	for i in range(2):
		var ta := Time.get_ticks_msec()
		inst.call("_build_segment")
		seg_times.append(Time.get_ticks_msec() - ta)
		await process_frame
	var mem_all := OS.get_static_memory_usage()
	# the patient stamp: report the queue as built, the near-drain, then widen
	# the horizon and drain everything so the per-token table stays complete
	var q: Array = inst.get("_stamp_queue")
	var queued_after_build: int = q.size()
	var t_drain0 := Time.get_ticks_msec()
	var frames_near := 0
	while frames_near < 600:
		await process_frame
		frames_near += 1
		if (inst.get("_stamp_queue") as Array).size() == 0:
			break
		if frames_near > 4 and (inst.get("_stamp_queue") as Array).size() == queued_after_build:
			break   # distance gate holds: nothing near is left to build
	var queued_far: int = (inst.get("_stamp_queue") as Array).size()
	var mem_near := OS.get_static_memory_usage()
	inst.set("INSTANTIATE_AHEAD_M", 100000.0)
	var frames_full := 0
	while (inst.get("_stamp_queue") as Array).size() > 0 and frames_full < 3000:
		await process_frame
		frames_full += 1
	var t_drain := Time.get_ticks_msec() - t_drain0
	var mem_full := OS.get_static_memory_usage()
	for i in range(4):
		await process_frame

	var segs: Array = inst.get("_segments")
	var vis: Array = inst.get("_vis_records")
	var seg0: Dictionary = segs[0]
	var z1: float = float(seg0["z1"])

	# ── group segment-0 artifact roots by token ──────────────────────────────
	var groups: Dictionary = {}
	var roots_in_seg0 := 0
	var shown := 0
	var spawn := Vector3(7.5, 0.0, 1.5)
	for r in vis:
		var n: Node3D = (r as Dictionary).get("node") as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var p: Vector3 = (r as Dictionary).get("p")
		if p.z >= z1:
			continue
		roots_in_seg0 += 1
		if Vector2(p.x - spawn.x, p.z - spawn.z).length() < 32.0:
			shown += 1
		var tok := _token_of(n)
		if not groups.has(tok):
			groups[tok] = {"count": 0, "meshes": 0, "verts": 0, "lights": 0,
				"rigid": 0, "audio": 0, "cams": 0, "viewports": 0, "particles": 0,
				"nodes": 0, "uniq": {}}
		var g: Dictionary = groups[tok]
		g["count"] += 1
		_walk(n, g)
	var mem_walked := OS.get_static_memory_usage()

	var rows: Array = []
	for tok in groups:
		var g: Dictionary = groups[tok]
		# est GPU bytes: vertex (pos+nrm+tan+uv ~= 44 B) + index (~6 B/vert avg)
		g["est_kb"] = int(float(g["verts"]) * 50.0 / 1024.0)
		g["uniq_meshes"] = (g["uniq"] as Dictionary).size()
		g.erase("uniq")
		g["token"] = tok
		rows.append(g)
	rows.sort_custom(func(a, b): return int(a["est_kb"]) > int(b["est_kb"]))

	print("FIRST ROOM  z 0..%.0f  roots=%d  (shown at spawn: %d, hidden: %d)" % [
		z1, roots_in_seg0, shown, roots_in_seg0 - shown])
	print("build times ms per segment: %s" % [seg_times])
	print("static mem: boot->seg0 %+d MB, ->3 segs %+d MB, walk overhead %+d MB" % [
		(mem_seg0 - mem0) / 1048576, (mem_all - mem_seg0) / 1048576, (mem_walked - mem_all) / 1048576])
	print("%-34s %5s %6s %9s %7s %5s %5s %5s %4s %4s" % [
		"token", "n", "meshes", "verts", "estKB", "light", "rigid", "audio", "cam", "vp"])
	for row in rows.slice(0, 30):
		print("%-34s %5d %6d %9d %7d %5d %5d %5d %4d %4d" % [
			row["token"], row["count"], row["meshes"], row["verts"], row["est_kb"],
			row["lights"], row["rigid"], row["audio"], row["cams"], row["viewports"]])
	var chapters: Array = []
	for sv in segs:
		var sn: Node3D = (sv as Dictionary).get("node") as Node3D
		chapters.append(String(sn.get_meta("em_chapter")) if sn != null and sn.has_meta("em_chapter") else "?")
	var totals := {"roots": roots_in_seg0, "shown_at_spawn": shown,
		"chapters": chapters, "first_chapter_var": String(inst.get("_first_chapter")),
		"seg_build_ms": seg_times, "mem_seg0_mb": (mem_seg0 - mem0) / 1048576,
		"mem_3segs_mb": (mem_all - mem0) / 1048576,
		"queued_after_build": queued_after_build, "queued_beyond_horizon": queued_far,
		"drain_frames": [frames_near, frames_full], "drain_ms": t_drain,
		"mem_near_drained_mb": (mem_near - mem0) / 1048576,
		"mem_fully_drained_mb": (mem_full - mem0) / 1048576}
	print("patient stamp: %d queued at build, %d beyond the 50 m horizon after near-drain (%d + %d frames, %d ms total)" % [
		queued_after_build, queued_far, frames_near, frames_full, t_drain])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"totals": totals, "tokens": rows}, " "))
	f.close()
	print("report -> %s" % OUT)
	quit(0)


func _token_of(n: Node3D) -> String:
	for meta in ["artifact_lookup_name", "config_lookup", "em_token"]:
		if n.has_meta(meta):
			return String(n.get_meta(meta))
	var nm := String(n.name)
	# strip Godot's uniquifier suffixes (@X@Y, trailing digits)
	var out := ""
	for i in range(nm.length()):
		var ch: String = nm[i]
		if ch == "@" or (ch >= "0" and ch <= "9" and i > 0 and nm[i - 1] in ["_", "@"]):
			break
		out += ch
	return out.trim_suffix("_")


func _walk(n: Node, g: Dictionary) -> void:
	g["nodes"] += 1
	if n is MeshInstance3D:
		g["meshes"] += 1
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			var uniq: Dictionary = g["uniq"]
			if not uniq.has(mi.mesh.get_instance_id()):
				uniq[mi.mesh.get_instance_id()] = true
				for s in range(mi.mesh.get_surface_count()):
					var arr: Array = mi.mesh.surface_get_arrays(s)
					if arr.size() > Mesh.ARRAY_VERTEX and arr[Mesh.ARRAY_VERTEX] != null:
						g["verts"] += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	elif n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm != null and mm.mesh != null:
			var uniq2: Dictionary = g["uniq"]
			if not uniq2.has(mm.mesh.get_instance_id()):
				uniq2[mm.mesh.get_instance_id()] = true
				for s2 in range(mm.mesh.get_surface_count()):
					var arr2: Array = mm.mesh.surface_get_arrays(s2)
					if arr2.size() > Mesh.ARRAY_VERTEX and arr2[Mesh.ARRAY_VERTEX] != null:
						g["verts"] += (arr2[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() * mm.instance_count
	elif n is Light3D:
		g["lights"] += 1
	elif n is RigidBody3D:
		g["rigid"] += 1
	elif n is AudioStreamPlayer3D:
		g["audio"] += 1
	elif n is Camera3D:
		g["cams"] += 1
	elif n is SubViewport:
		g["viewports"] += 1
	elif n is GPUParticles3D:
		g["particles"] += 1
	for c in n.get_children():
		_walk(c, g)
