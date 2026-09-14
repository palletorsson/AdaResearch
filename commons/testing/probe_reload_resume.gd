extends SceneTree
## WHERE A RELOAD LANDS (2026-09-14, Palle: "fix the reload and jump bugs").
##
## Every museum reload rebuilds the scene; what it keeps depends on what it writes to
## ada_run/em_control.json and on EM::_start_at_chapter's precedence. Reading the code
## said: F6 and the follow reload keep the chapter but not the HALL, and the J and L jumps
## rank below the Inspector's start_chapter, so they land where the scene says, not where
## the visitor asked. This probe walks each door and records the hall the eye stands in
## afterwards.
##
##   direct lane:  godot --path . --xr-mode off --script res://commons/testing/probe_reload_resume.gd -- --em-quality=perf
##   staged lane:  godot --path . --xr-mode off --script res://commons/testing/probe_reload_resume.gd --em-autostart -- --staged --em-quality=perf
##
## Cases (direct): H toggle into the doll house and back (the control: already names its
## hall), F6 from the second hall, J to a hall in another chapter, L the same through the
## spine strip. Staged: F6 from the second hall must come back to that hall, not the menu,
## and J must land where it was sent.
## Writes <evidence root>/reload-resume/probe_reload_resume[_staged].json; exit 1 on a
## failure. ada_run/em_control.json is restored at the end.

const Evidence := preload("res://commons/testing/evidence_root.gd")
const EM_CONTROL := "res://ada_run/em_control.json"

var staged := false
var failures: PackedStringArray = []
var cases: Array = []
var ctl_backup := ""


func check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		failures.append(what)


func _initialize() -> void:
	staged = OS.get_cmdline_user_args().has("--staged")
	if FileAccess.file_exists(EM_CONTROL):
		ctl_backup = FileAccess.get_file_as_string(EM_CONTROL)
	_run.call_deferred()


## the live museum node, whichever lane built it
func _museum() -> Node:
	for n in root.find_children("*", "Node3D", true, false):
		var s = n.get_script()
		if s != null and str(s.resource_path).ends_with("museum.gd") and n.get("_segments") != null:
			return n
	return null


func _wait_museum(previous_id: int, timeout_s: float = 60.0) -> Node:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < timeout_s * 1000.0:
		await process_frame
		var em := _museum()
		if em != null and em.get_instance_id() != previous_id and bool(em.get("_museum_ready")):
			for i in range(10):
				await process_frame
			return em
	return null


## the hall the eye stands in: {map, chapter, z_local}
func _where(em: Node) -> Dictionary:
	var eye: Vector3 = em.call("_eye_pos")
	for sv in (em.get("_segments") as Array):
		var sd: Dictionary = sv
		if eye.z >= float(sd["z0"]) and eye.z < float(sd["z1"]):
			var node: Node = sd.get("node") if is_instance_valid(sd.get("node")) else null
			return {"map": String(sd.get("map", "")),
				"chapter": String(node.get_meta("em_chapter", "")) if node != null else "",
				"z_local": eye.z - float(sd["z0"]), "eye": [eye.x, eye.y, eye.z]}
	return {"map": "", "chapter": "", "z_local": -1.0, "eye": [eye.x, eye.y, eye.z]}


## the walk cell nearest a world z (optionally inside [z0, z1))
func _cell_near(em: Node, z: float, z0: float = -1e9, z1: float = 1e9):
	var best = null
	var best_d := 1e9
	for k in (em.get("_walk_cells") as Dictionary):
		var c: Vector2i = k
		if float(c.y) < z0 or float(c.y) >= z1:
			continue
		var d := absf(float(c.y) + 0.5 - z)
		if d < best_d:
			best_d = d
			best = c
	return best


## Walk the walker forward until the hall with ordinal `index` exists, then stand it on a
## walk cell in that hall's middle. The stream builds a hall only when the eye nears the
## frontier and frees what is more than keep_ahead_m ahead, so the hall has to be walked to.
func _walk_to_hall(em: Node, index: int) -> Dictionary:
	var p: Node3D = em.get("_player")
	for step in range(600):
		for sv in (em.get("_segments") as Array):
			var sd: Dictionary = sv
			if int(sd.get("index", -1)) != index:
				continue
			var z0: float = float(sd["z0"])
			var z1: float = float(sd["z1"])
			var c = _cell_near(em, (z0 + z1) * 0.5, z0 + 3.0, z1 - 3.0)
			if c != null:
				p.position = Vector3(float(c.x) + 0.5, 1.0, float(c.y) + 0.5)
				for i in range(30):
					await physics_frame
				return {"map": String(sd.get("map", ""))}
		var ahead = _cell_near(em, p.position.z + 3.0)
		if ahead != null:
			p.position = Vector3(float(ahead.x) + 0.5, 1.0, float(ahead.y) + 0.5)
		for i in range(3):
			await physics_frame
	return {}


func _run() -> void:
	if staged:
		var st: PackedScene = load("res://commons/scenes/vr_staging.tscn")
		var n := st.instantiate()
		root.add_child(n)
		current_scene = n
	else:
		var sc: PackedScene = load("res://commons/scenes/endless_museum.tscn")
		var n2 := sc.instantiate()
		root.add_child(n2)
		current_scene = n2
	var em := await _wait_museum(0, 120.0)
	check(em != null, "the museum boots and releases its first hall")
	if em == null:
		_finish()
		return

	if not staged:
		# ── H (control): into the doll house and back, from the second hall ─────────
		var at: Dictionary = await _walk_to_hall(em, 1)
		check(not at.is_empty(), "the walker reaches the second hall (%s)" % at.get("map", "none"))
		var before := _where(em)
		var id := em.get_instance_id()
		em.call("_doll_toggle")
		em = await _wait_museum(id)
		if em != null:
			id = em.get_instance_id()
			em.call("_doll_toggle")                 # back to the walk
			em = await _wait_museum(id)
		var after_h := _where(em) if em != null else {}
		cases.append({"case": "H", "before": before, "after": after_h})
		check(em != null and String(after_h.get("map")) == String(before.get("map")) and String(before.get("map")) != "",
			"H (control): the doll house and back returns to %s (landed in %s)" % [before.get("map"), after_h.get("map")])

	# ── F6: from the second hall ──────────────────────────────────────────────────────
	if em != null:
		var at_f: Dictionary = await _walk_to_hall(em, 1)
		check(not at_f.is_empty(), "F6: the walker reaches the second hall (%s)" % at_f.get("map", "none"))
		var before_f := _where(em)
		var idf := em.get_instance_id()
		em.call("_follow_reload")
		em = await _wait_museum(idf)
		var after_f := _where(em) if em != null else {}
		cases.append({"case": "F6", "before": before_f, "after": after_f})
		check(em != null, "F6: a museum stands after the reload%s" % (" (staged: not the menu)" if staged else ""))
		check(em != null and String(after_f.get("map")) == String(before_f.get("map")) and String(before_f.get("map")) != "",
			"F6: the reload returns to the hall it left, %s (landed in %s)" % [before_f.get("map"), after_f.get("map")])
		check(em != null and absf(float(after_f.get("z_local", -99.0)) - float(before_f.get("z_local", 0.0))) < 3.0,
			"F6: the eye stands where it stood in that hall (z %.1f -> %.1f local)" % [float(before_f.get("z_local", 0.0)), float(after_f.get("z_local", -1.0))])

	if em != null:
		# ── J: a hall in another chapter than the Inspector's (both lanes) ──────────────
		var target := {"chapter": "primitives", "map": "Point_One"}
		if String(_where(em).get("chapter")) == "primitives":
			target = {"chapter": "fractals", "map": "Fractal_Recursion"}
		em.set("_jump_rows", [target])
		var idj := em.get_instance_id()
		em.call("_jump_go", 0)
		em = await _wait_museum(idj)
		var after_j := _where(em) if em != null else {}
		cases.append({"case": "J", "target": target, "after": after_j})
		check(em != null and String(after_j.get("chapter")) == target["chapter"] and String(after_j.get("map")) == target["map"],
			"J: the jump lands in %s · %s (landed in %s · %s)" % [target["chapter"], target["map"], after_j.get("chapter"), after_j.get("map")])

		# ── L: the spine strip to yet another hall (direct lane) ───────────────────────
		if em != null and not staged:
			var target_l := {"chapter": "fractals", "map": "Fractal_RecursiveTrees", "pearl": "fractal recursivetrees"}
			if String(_where(em).get("map")) == "Fractal_RecursiveTrees":
				target_l = {"chapter": "primitives", "map": "Point_One", "pearl": "point one"}
			em.set("_spine_rows", [target_l])
			var idl := em.get_instance_id()
			em.call("_spine_travel", 0)
			em = await _wait_museum(idl)
			var after_l := _where(em) if em != null else {}
			cases.append({"case": "L", "target": target_l, "after": after_l})
			check(em != null and String(after_l.get("chapter")) == target_l["chapter"] and String(after_l.get("map")) == target_l["map"],
				"L: the spine strip lands in %s · %s (landed in %s · %s)" % [target_l["chapter"], target_l["map"], after_l.get("chapter"), after_l.get("map")])
	_finish()


func _finish() -> void:
	if ctl_backup != "":
		var f := FileAccess.open(EM_CONTROL, FileAccess.WRITE)
		if f != null:
			f.store_string(ctl_backup)
			f.close()
	var path: String = Evidence.dir("reload-resume").path_join("probe_reload_resume%s.json" % ("_staged" if staged else ""))
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify({"staged": staged, "cases": cases, "failures": failures}, " "))
	out.close()
	print("RELOAD RESUME%s: %s (%d failure(s)) -> %s" % [" STAGED" if staged else "", "PASS" if failures.is_empty() else "FAIL", failures.size(), path])
	quit(0 if failures.is_empty() else 1)
