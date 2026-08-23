extends SceneTree
## THE COLLATIONS, TESTED IN THE MUSEUM (2026-08-23, Palle: "rebake and test
## it in the museum") — boots the real endless_museum against the fresh bake
## with TRIAL control/overrides/hand files (the probe-isolation rule: never
## write a file a live session reads), waits for the primitives segments, and
## reads the built halls back:
##   point lines : the 5-laser fan — >=5 laser_measures, >=4 distinct headings
##   point trace : the RGB rank — 3 draw_dots with ink ff0000/00ff00/0000ff,
##                 resolution 10/40/80, retention trace, ON the live nodes
##                 (the typed-set lesson: read the assignment back, not the
##                 token); the whiteboard answers write_surfaces(); and the
##                 pen-to-board wiring END TO END: a museum rank pen shapes a
##                 sample onto the museum board's own plane, board-grid snapped.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_museum_collations.gd

const OUT := "res://ada_run/museum_collations_probe.txt"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_mc_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_mc_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_mc_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_mc_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)

	# wait for the point-lines (Seg1) and point-trace (Seg2) segments
	var seg1: Node3D = null
	var seg2: Node3D = null
	for i in range(60):
		await create_timer(0.5).timeout
		for c in inst.get_children():
			if c is Node3D and str(c.name).begins_with("Seg1_"):
				seg1 = c
			if c is Node3D and str(c.name).begins_with("Seg2_"):
				seg2 = c
		if seg1 != null and seg2 != null:
			break
	await create_timer(1.0).timeout   # settle: deferred config + retention builds

	if seg1 == null:
		fails.append("Seg1 (point lines) never built")
	else:
		# THE FAN: >=5 lasers, >=4 distinct headings
		var rots: Dictionary = {}
		var lasers: int = 0
		for n in seg1.find_children("*", "Node3D", true, false):
			if n.get("laser_thickness") != null and n.has_method("get_distance"):
				lasers += 1
				rots[posmod(roundi((n as Node3D).global_rotation_degrees.y), 360)] = true
		if lasers < 5:
			fails.append("point lines: %d laser_measure(s), wanted >=5" % lasers)
		if rots.size() < 4:
			fails.append("the fan is flat: only %d distinct heading(s): %s" % [rots.size(), str(rots.keys())])

	if seg2 == null:
		fails.append("Seg2 (point trace) never built")
	else:
		# THE RANK: read ink/resolution/retention back off the LIVE nodes
		var want: Dictionary = {"ff0000": 10.0, "00ff00": 40.0, "0000ff": 80.0}
		var seen: Dictionary = {}
		var dots: int = 0
		var green_pen: Node = null
		for n in seg2.find_children("*", "Node3D", true, false):
			if n.get("ink") == null or not n.has_method("_shape_sample"):
				continue
			dots += 1
			var iv := str(n.get("ink"))
			if want.has(iv):
				seen[iv] = true
				if not is_equal_approx(float(n.get("resolution_mm")), float(want[iv])):
					fails.append("rank %s: resolution_mm=%s wanted %s" % [iv, str(n.get("resolution_mm")), str(want[iv])])
				if str(n.get("retention")) != "trace":
					fails.append("rank %s: retention=%s wanted trace" % [iv, str(n.get("retention"))])
				if iv == "00ff00":
					green_pen = n
		if dots < 4:
			fails.append("point trace: %d draw_dot(s), wanted 4 (doorway + rank)" % dots)
		for k in want.keys():
			if not seen.has(k):
				fails.append("rank member %s missing from the hall" % k)
		# THE BOARD: the hall's whiteboard answers, and the green pen writes on it
		var board: Node = null
		for n in seg2.find_children("*", "Node3D", true, false):
			if n.has_method("write_surfaces"):
				board = n
		if board == null:
			fails.append("no whiteboard in point trace")
		elif green_pen == null:
			fails.append("no green pen to write with")
		else:
			var srfs: Array = board.call("write_surfaces")
			var s: Dictionary = srfs[0]
			var o: Vector3 = s["origin"]
			var messy: Vector3 = o + (s["u"] as Vector3) * 0.117 + (s["v"] as Vector3) * -0.073 + (s["normal"] as Vector3) * 0.03
			var rec: Vector3 = green_pen.call("_shape_sample", messy)
			var d: Vector3 = rec - o
			var u: float = d.dot(s["u"] as Vector3)
			var v: float = d.dot(s["v"] as Vector3)
			if absf(u - 0.12) > 0.002 or absf(v - (-0.08)) > 0.002:
				fails.append("museum board write off-grid: u=%.3f v=%.3f (wanted 0.12, -0.08)" % [u, v])
			var lift: float = d.dot(s["normal"] as Vector3)
			if lift <= 0.0 or lift > 0.02:
				fails.append("museum board ink not proud of the face: %.4f" % lift)

	# DIAGNOSIS DUMP — what actually stands (the dead-reading rule: count the
	# thing being measured before believing any null)
	var dump: Array = []
	for c in inst.get_children():
		if not (c is Node3D) or not str(c.name).begins_with("Seg"):
			continue
		var em := str(c.get_meta("em_map")) if c.has_meta("em_map") else "-"
		var found: Array = []
		for n in (c as Node3D).find_children("*", "Node3D", true, false):
			if n.get("ink") != null and n.has_method("_shape_sample"):
				found.append("%s ink=%s res=%s ret=%s" % [str(n.name), str(n.get("ink")),
					str(n.get("resolution_mm")), str(n.get("retention"))])
			elif n.has_method("write_surfaces"):
				found.append("%s (board)" % str(n.name))
		dump.append("%s em_map=%s :: %s" % [str(c.name), em, " | ".join(PackedStringArray(found))])
	for f in ["_trial_mc_control.json", "_trial_mc_overrides.json", "_trial_mc_hand.json"]:
		DirAccess.remove_absolute("res://ada_run/" + f)
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string(("PASS" if fails.is_empty() else "FAIL: " + "; ".join(PackedStringArray(fails)))
		+ "\n" + "\n".join(PackedStringArray(dump)))
	out.close()
	print("MUSEUM COLLATIONS: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(PackedStringArray(fails))))
	quit(0 if fails.is_empty() else 1)
