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
##
## REPAIRED 2026-09-14 (Palle: "fix probe_view_resume too"). It printed RESUMED or BACK AT
## THE BEGINNING and always exited 0, so it could never fail a run; it stood the walker at a
## guessed point that could be a wall or a hall with no map (no hall can be named then);
## it left its trial control file behind; and 7 SCRIPT ERRORs came from the probe itself —
## the museum was never the tree's current_scene, which GridSystem._update_player_bounds
## reads in every simulation-grid hall. Now: the deepest MAP-AUTHORED hall of the first
## boot, a walk cell inside it, the writer checked against that hall, F6's document
## (EM::_resume_doc) checked to name the same hall, boot 2 awaited on _museum_ready, exit 1
## on any failure, the REAL ada_run/em_control.json checked untouched, trial files removed,
## the report written to the evidence root.

const Evidence := preload("res://commons/testing/evidence_root.gd")
const CTL := "res://ada_run/_trial_resume_control.json"
const TRIAL_OVERRIDES := "res://ada_run/_trial_resume_overrides.json"
const TRIAL_HAND := "res://ada_run/_trial_resume_hand.json"
const REAL_CTL := "res://ada_run/em_control.json"

var rep := ""
var fails: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func check(ok: bool, what: String) -> void:
	rep += ("  ok   " if ok else "  FAIL ") + what + "\n"
	if not ok:
		fails.append(what)


func _new_museum() -> Node3D:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", TRIAL_OVERRIDES)
	inst.set("_hand_path", TRIAL_HAND)
	return inst


func _boot(chapter: String, first_map: String) -> Node3D:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": chapter, "first_map": first_map,
		"dollhouse": 0, "grid_pack": 1}, " "))
	f.close()
	var inst := _new_museum()
	inst.set("start_chapter", chapter)
	inst.set("start_map", first_map)
	get_root().add_child(inst)
	current_scene = inst            # as in the game: grid halls read the current scene
	return inst


func _wait_ready(inst: Node3D, timeout_s: float = 90.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < timeout_s * 1000.0:
		await process_frame
		if bool(inst.get("_museum_ready")):
			return true
	return false


## the walk cell nearest (x, z) inside [z0, z1)
func _walk_cell(inst: Node3D, x: float, z: float, z0: float, z1: float):
	var best = null
	var bd := 1e18
	for k in (inst.get("_walk_cells") as Dictionary):
		var c: Vector2i = k
		if float(c.y) < z0 or float(c.y) >= z1:
			continue
		var d := Vector2(float(c.x) + 0.5 - x, float(c.y) + 0.5 - z).length_squared()
		if d < bd:
			bd = d
			best = c
	return best



## Walk the walker forward, hall by hall, until the hall with ordinal `upto` exists; return
## the deepest MAP-AUTHORED hall of `chapter` past the first that was reached ({} if none).
func _walk_deep(inst: Node3D, chapter: String, upto: int) -> Dictionary:
	var p: Node3D = inst.get("_player") as Node3D
	var best: Dictionary = {}
	for step in range(900):
		var deepest := -1
		for sv in (inst.get("_segments") as Array):
			var sd: Dictionary = sv
			var idx := int(sd.get("index", -1))
			deepest = maxi(deepest, idx)
			var node: Node = sd.get("node") if is_instance_valid(sd.get("node")) else null
			var ch := String(node.get_meta("em_chapter", "")) if node != null else ""
			if idx >= 1 and String(sd.get("map", "")) != "" and ch == chapter and idx > int(best.get("index", 0)):
				best = sd
		if deepest >= upto:
			break
		var ahead = _walk_cell(inst, p.position.x, p.position.z + 3.0, -1e9, 1e9)
		if ahead != null:
			p.position = Vector3(float(ahead.x) + 0.5, 1.0, float(ahead.y) + 0.5)
		for i in range(3):
			await physics_frame
	return best


func _run() -> void:
	var real_before := FileAccess.get_file_as_string(REAL_CTL) if FileAccess.file_exists(REAL_CTL) else ""
	var chapter := _arg("chapter", "color")
	var inst := _boot(chapter, "")
	check(await _wait_ready(inst), "boot 1 releases its first hall in %s" % chapter)
	inst.call("flush_stamps")

	# walk forward into the deepest map-authored hall of the chapter the walker can reach in
	# three halls. WALKED, not built: the stream frees any hall more than keep_ahead_m (30 m in
	# em_layout.json) ahead of the eye, so halls built in one go from the door are gone a
	# second later (the 2026-08 version built three and found one).
	var target: Dictionary = await _walk_deep(inst, chapter, 2)
	var segs: Array = inst.get("_segments")
	rep += "BOOT 1 — walked to hall %s; %d segment(s) standing:\n" % [str(target.get("index", "?")), segs.size()]
	for sv in segs:
		var sd: Dictionary = sv
		rep += "   z %6.1f..%-6.1f  pearl=%-22s map=%s\n" % [float(sd.get("z0", 0)),
			float(sd.get("z1", 0)), String(sd.get("pearl", "?")), String(sd.get("map", "(none)"))]
	check(not target.is_empty(), "boot 1 reaches a map-authored hall of %s past the first one" % chapter)
	if target.is_empty():
		await _finish(real_before)
		return
	var z0 := float(target["z0"])
	var z1 := float(target["z1"])
	var cell = _walk_cell(inst, float(target.get("w", 10)) / 2.0, z0 + 6.0, z0 + 1.0, z1 - 1.0)
	check(cell != null, "%s has a walk cell to stand on" % target.get("map"))
	if cell == null:
		await _finish(real_before)
		return
	var stand := Vector3(float(cell.x) + 0.5, 0.2, float(cell.y) + 0.5)
	var player: Node3D = inst.get("_player") as Node3D
	player.position = stand
	await create_timer(0.5).timeout
	rep += "\n  stood the walker at %s — inside %s\n" % [str(stand), String(target.get("map", "?"))]

	var doc: Dictionary = inst.call("_toggle_doc")
	rep += "\n  _toggle_doc() would write:\n"
	for k in ["first_chapter", "first_map", "_resume_hall", "dollhouse", "resume_eye", "resume_yaw"]:
		rep += "     %-16s %s\n" % [k, str(doc.get(k))]
	# THE WRITER: names the hall the eye is in, in the right chapter
	check(String(doc.get("_resume_hall", "")) == String(target.get("map")),
		"the toggle names the hall the eye is in (%s)" % doc.get("_resume_hall"))
	check(String(doc.get("first_chapter", "")) == chapter, "the toggle keeps the chapter (%s)" % doc.get("first_chapter"))
	check(doc.get("resume_eye") is Array, "the toggle records the eye")
	# F6 and the follow write the same document with the doll house kept (EM::_resume_doc)
	var doc_f6: Dictionary = inst.call("_resume_doc", 0)
	check(String(doc_f6.get("_resume_hall", "")) == String(doc.get("_resume_hall", "")) and str(doc_f6.get("resume_eye")) == str(doc.get("resume_eye")),
		"F6's document names the same hall and eye as the toggle's")

	# write it exactly as _doll_toggle would, then boot a second museum from it
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify(doc, " "))
	f.close()
	current_scene = null
	inst.queue_free()
	await create_timer(1.0).timeout

	var inst2 := _new_museum()
	get_root().add_child(inst2)
	current_scene = inst2
	check(await _wait_ready(inst2), "boot 2 releases its first hall")
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
	var re: Array = doc.get("resume_eye", [0.0, 0.0, 0.0]) if doc.get("resume_eye") is Array else [0.0, 0.0, 0.0]
	var want_local := float(re[2])
	var got_local: float = p2.position.z - base2 if p2 != null else -999.0
	var dz: float = absf(got_local - want_local)
	var dx: float = absf((p2.position.x if p2 != null else -999.0) - float(re[0]))
	if p2 != null:
		rep += "\n  the walker stands at %s\n" % str(p2.position)
	rep += "  %s opens at z %.1f, so local z %.2f — wanted %.2f\n" % [want_hall, base2, got_local, want_local]
	rep += "  x %.2f — wanted %.2f\n" % [p2.position.x if p2 != null else -999.0, float(re[0])]
	check(in_hall, "boot 2 built the hall it was asked to resume (%s)" % want_hall)
	check(in_hall and dz < 2.0, "the walker stands where it stood in that hall along z (%.2f m out)" % dz)
	check(dx < 2.0, "the walker stands where it stood across x (%.2f m out)" % dx)
	rep += "\n  %s (%.2f m out, in the right hall: %s)\n" % [
		"RESUMED" if (in_hall and dz < 2.0) else "BACK AT THE BEGINNING", dz, str(in_hall)]
	await _finish(real_before)


func _finish(real_before: String) -> void:
	var real_after := FileAccess.get_file_as_string(REAL_CTL) if FileAccess.file_exists(REAL_CTL) else ""
	check(real_after == real_before, "the REAL control file is untouched (%s)" % REAL_CTL)
	for p in [CTL, TRIAL_OVERRIDES, TRIAL_HAND]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	rep += "\nVIEW RESUME: %s (%d failure(s))\n" % ["PASS" if fails.is_empty() else "FAIL", fails.size()]
	var out_path: String = Evidence.dir("view-resume").path_join("view_resume.txt")
	var fo := FileAccess.open(out_path, FileAccess.WRITE)
	fo.store_string(rep)
	fo.close()
	print(rep)
	# A CLEAN EXIT: quitting the instant boot 2 released crashed Godot while that museum was
	# still building (rc 139 after PASS). Free the museums and let their work drain first.
	current_scene = null
	for n in get_root().get_children():
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("endless_museum.gd"):
			n.queue_free()
	for i in range(30):
		await process_frame
	await create_timer(1.0).timeout
	quit(0 if fails.is_empty() else 1)
