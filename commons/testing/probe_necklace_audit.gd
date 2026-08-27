extends SceneTree
## probe_necklace_audit.gd — an INDEPENDENT audit of commons/scenes/desktop_necklace.gd.
##
## Written by the reviewing agent, not the building one. It does not reuse
## probe_necklace.gd's assertions; it re-derives every number from the effective
## JSON on disk and compares the scene's behaviour against that.
##
## The 4.6 exe is non-console, so nothing here is printed for diagnosis: every
## finding goes into a JSON report read back off disk, and a heartbeat file is
## rewritten every second so the watchdog's 16 s stall rule sees progress during
## the 810-step sweep.
##
## Run:
##   python tools/godot_watchdog.py --expect=<dir> --grace=120 -- \
##     "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --headless --path . \
##     --xr-mode off --script res://commons/testing/probe_necklace_audit.gd \
##     -- --report=<dir>/audit.json --beat=<dir>/beat.txt

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const EFFECTIVE := "res://commons/data/spine_order_effective.json"
const LIVE_OPS := "res://commons/data/spine_order_ops.json"
const GENERATED := "res://commons/data/spine_artifact_order.json"
const TRIAL_OPS := "user://_audit_necklace_ops.json"

var _checks: Array = []
var _facts: Dictionary = {}
var _beat_path: String = ""
var _last_beat: int = 0


func _initialize() -> void:
	_run()


func _ck(name: String, ok: bool, detail: Variant = "") -> void:
	_checks.append({"check": name, "ok": ok, "detail": str(detail)})


func _beat(tag: String) -> void:
	if _beat_path == "":
		return
	var now := Time.get_ticks_msec()
	if now - _last_beat < 900:
		return
	_last_beat = now
	var f := FileAccess.open(_beat_path, FileAccess.WRITE)
	if f != null:
		f.store_string("%d %s\n" % [now, tag])
		f.close()


func _md5(p: String) -> String:
	if not FileAccess.file_exists(p):
		return "absent"
	return FileAccess.get_md5(p)


func _write(report: String, ok: bool) -> void:
	var failed: Array = []
	for c in _checks:
		if not bool((c as Dictionary)["ok"]):
			failed.append(str((c as Dictionary)["check"]))
	var doc := {
		"pass": ok and failed.is_empty(),
		"checks": _checks.size(),
		"failed": failed,
		"facts": _facts,
		"rows": _checks,
	}
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(doc, "  ", false))
		f.close()


func _run() -> void:
	var report := ProjectSettings.globalize_path("user://probe_necklace_audit.json")
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--report="):
			report = s.split("=", true, 1)[1]
		elif s.begins_with("--beat="):
			_beat_path = s.split("=", true, 1)[1]
	_beat("boot")

	# ── baselines on the files the scene must never write ────────────────────
	var gen_before := _md5(GENERATED)
	var ops_before := _md5(LIVE_OPS)
	var eff_before := _md5(EFFECTIVE)
	if FileAccess.file_exists(TRIAL_OPS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIAL_OPS))

	# ── the truth I compare against, read straight from the JSON ─────────────
	var ef := FileAccess.open(EFFECTIVE, FileAccess.READ)
	if ef == null:
		_ck("effective json readable", false, EFFECTIVE)
		_write(report, false)
		quit(1)
		return
	var raw: Variant = JSON.parse_string(ef.get_as_text())
	ef.close()
	var doc: Dictionary = raw if raw is Dictionary else {}
	var truth: Array = doc.get("order", [])
	var want: PackedStringArray = PackedStringArray()
	for r in truth:
		want.append(str((r as Dictionary).get("lookup", "")))
	_facts["json_order_size"] = want.size()

	# ── load the scene the way a player would ────────────────────────────────
	var t0 := Time.get_ticks_msec()
	if not ResourceLoader.exists(SCENE):
		_ck("scene exists", false, SCENE)
		_write(report, false)
		quit(1)
		return
	_ck("scene exists", true, SCENE)
	var ps := load(SCENE) as PackedScene
	_ck("scene loads as PackedScene", ps != null, SCENE)
	if ps == null:
		_write(report, false)
		quit(1)
		return
	var inst: Node = ps.instantiate()
	_ck("root is a Node3D", inst is Node3D, inst.get_class() if inst != null else "null")
	_ck("root carries a script", inst != null and inst.get_script() != null, "")
	inst.set("ops_path", TRIAL_OPS)
	root.add_child(inst)
	await process_frame
	await process_frame
	await process_frame
	_facts["boot_ms"] = Time.get_ticks_msec() - t0
	_beat("booted")

	var n: Node = inst
	_ck("no fatal on open", str(n.call("fatal_message")) == "", str(n.call("fatal_message")))
	_ck("ops path is the injected trial file",
		str(n.call("resolved_ops_path")) == TRIAL_OPS, str(n.call("resolved_ops_path")))

	var size: int = int(n.call("order_size"))
	_facts["scene_order_size"] = size
	_ck("scene order size == json order size", size == want.size(), "%d vs %d" % [size, want.size()])

	# ── 1. TEN BEADS, AND A HORIZONTAL LINE ──────────────────────────────────
	n.call("settle_scroll")
	await process_frame
	var vis: PackedStringArray = n.call("visible_lookups")
	_ck("ten beads at open", int(n.call("bead_count")) == 10, str(n.call("bead_count")))
	_ck("window_first == 0 at open", int(n.call("window_first")) == 0, str(n.call("window_first")))
	var head: PackedStringArray = PackedStringArray()
	for i in range(0, mini(10, want.size())):
		head.append(want[i])
	_ck("the ten at open are order[0..9]", _same(vis, head), "%s vs %s" % [str(vis), str(head)])

	var geo := _geometry(n)
	_facts["geometry_at_open"] = geo
	_ck("beads march left to right (x strictly increasing)", bool(geo["x_monotonic"]), str(geo["xs"]))
	_ck("x span is metres, not a stack", float(geo["x_span"]) > 15.0, str(geo["x_span"]))
	_ck("y sag is small next to the x span (a necklace, not a column)",
		float(geo["y_span"]) < float(geo["x_span"]) * 0.15,
		"y_span %.2f vs x_span %.2f" % [float(geo["y_span"]), float(geo["x_span"])])
	_ck("z is flat but for the focus step-forward", float(geo["z_span"]) < 0.6, str(geo["z_span"]))

	# ── 2. THE ENDS ──────────────────────────────────────────────────────────
	n.call("scroll_by", 5000)
	n.call("settle_scroll")
	await process_frame
	var tail_vis: PackedStringArray = n.call("visible_lookups")
	var tail: PackedStringArray = PackedStringArray()
	for i in range(maxi(0, want.size() - 10), want.size()):
		tail.append(want[i])
	_facts["end_window_first"] = int(n.call("window_first"))
	_facts["end_focus"] = int(n.call("focus_index"))
	_ck("End: focus is the last bead", int(n.call("focus_index")) == want.size() - 1,
		str(n.call("focus_index")))
	_ck("End: window_first == n-10", int(n.call("window_first")) == want.size() - 10,
		str(n.call("window_first")))
	_ck("End: still ten beads", int(n.call("bead_count")) == 10, str(n.call("bead_count")))
	_ck("End: the ten are the last ten of the order", _same(tail_vis, tail),
		"%s vs %s" % [str(tail_vis), str(tail)])
	var geo_end := _geometry(n)
	_ck("End: still a left-to-right line", bool(geo_end["x_monotonic"]), str(geo_end["xs"]))

	n.call("scroll_by", -5000)
	n.call("settle_scroll")
	await process_frame
	_ck("Home: back to bead 0", int(n.call("focus_index")) == 0 and int(n.call("window_first")) == 0,
		"focus %d win %d" % [int(n.call("focus_index")), int(n.call("window_first"))])
	_ck("Home: still ten beads", int(n.call("bead_count")) == 10, str(n.call("bead_count")))

	# ── 3. EVERY ONE OF THE 810 REACHABLE, ONE NOTCH AT A TIME ───────────────
	var seen: Dictionary = {}
	var short_windows: Array = []
	var step_ms: Array = []
	var worst: int = 0
	for i in range(0, want.size()):
		var s0 := Time.get_ticks_msec()
		n.call("scroll_by", 1)
		n.call("settle_scroll")
		var dt: int = Time.get_ticks_msec() - s0
		step_ms.append(dt)
		worst = maxi(worst, dt)
		var v: PackedStringArray = n.call("visible_lookups")
		if v.size() != 10:
			short_windows.append({"focus": int(n.call("focus_index")), "n": v.size()})
		for t in v:
			seen[t] = true
		if i % 40 == 0:
			_beat("sweep %d" % i)
			await process_frame
	var total := 0
	for m in step_ms:
		total += int(m)
	_facts["sweep_steps"] = step_ms.size()
	_facts["sweep_total_ms"] = total
	_facts["sweep_mean_ms"] = float(total) / maxf(1.0, float(step_ms.size()))
	_facts["sweep_worst_ms"] = worst
	_facts["sweep_seen"] = seen.size()
	_ck("scrolling one notch at a time reaches all %d" % want.size(), seen.size() == want.size(),
		"%d seen" % seen.size())
	_ck("the window is ten wide at EVERY position", short_windows.is_empty(),
		str(short_windows.slice(0, 6)))
	_ck("a scroll notch is under 250 ms even at its worst", worst < 250, "worst %d ms" % worst)

	# ── 4. THE MIDDLE: the focus rides at slot 4 ─────────────────────────────
	n.call("scroll_by", -(want.size()))
	n.call("scroll_by", 400)
	n.call("settle_scroll")
	await process_frame
	_ck("mid-order: window_first == focus - 4",
		int(n.call("window_first")) == int(n.call("focus_index")) - 4,
		"win %d focus %d" % [int(n.call("window_first")), int(n.call("focus_index"))])

	# ── 5. THE UNSHOWABLE: does the bead SAY so? ─────────────────────────────
	var badges: Array = []
	for token in ["gridcolorizer", "boid_flocking", "ecosystem_simulation",
			"synthesis_stand", "coordinate_readout", "box_counting_dimension"]:
		var idx: int = int(n.call("index_of", token))
		if idx < 0:
			badges.append({"token": token, "found": false})
			continue
		n.call("scroll_by", idx - int(n.call("focus_index")))
		n.call("settle_scroll")
		await process_frame
		var sub := _bead_sub(n, idx)
		var cap := _bead_cap(n, idx)
		var tile_on := _bead_tile_visible(n, idx)
		var noimg_on := _bead_noimg_visible(n, idx)
		badges.append({
			"token": token, "found": true, "sub": sub, "cap": cap,
			"tile_visible": tile_on, "token_text_visible": noimg_on,
			"live_refusal": str(n.call("live_refusal_at", idx)),
		})
	_facts["unshowable"] = badges
	for b in badges:
		var bd: Dictionary = b
		if not bool(bd.get("found", false)):
			continue
		var tk := str(bd["token"])
		if tk in ["gridcolorizer", "boid_flocking", "ecosystem_simulation"]:
			_ck("%s bead says NOT A BODY" % tk, str(bd["sub"]).contains("NOT A BODY"), str(bd["sub"]))
			_ck("%s is refused a live body" % tk, str(bd["live_refusal"]) != "", str(bd["live_refusal"]))
		if tk in ["synthesis_stand", "box_counting_dimension"]:
			_ck("%s bead says DEAD" % tk, str(bd["sub"]).contains("DEAD"), str(bd["sub"]))
		if tk == "coordinate_readout":
			_ck("a bead with no capture spells its token instead of showing a hole",
				not bool(bd["tile_visible"]) and bool(bd["token_text_visible"]),
				"tile %s token_text %s" % [str(bd["tile_visible"]), str(bd["token_text_visible"])])
	_beat("badges")

	# ── 6. ADD AT A CHOSEN POSITION ──────────────────────────────────────────
	# four positions, four different landing places, each checked by index.
	var pool: Array = []
	for i in range(0, mini(40, int(n.call("candidate_count")))):
		pool.append(str(n.call("candidate_lookup_at", i)))
	_facts["candidate_count"] = int(n.call("candidate_count"))
	_facts["pool_head"] = pool.slice(0, 5)

	var adds: Array = []
	var modes: Array = ["after", "before", "first_in", "last_in"]
	var mi := 0
	for mode in modes:
		# a fresh focus each time, well inside a chapter
		var anchor_i: int = 300 + mi * 7
		n.call("scroll_by", anchor_i - int(n.call("focus_index")))
		n.call("settle_scroll")
		await process_frame
		var focus_before: int = int(n.call("focus_index"))
		var focus_tok := str(n.call("focus_lookup"))
		var size_before: int = int(n.call("order_size"))
		var tok := ""
		for p in pool:
			if int(n.call("index_of", str(p))) < 0:
				tok = str(p)
				break
		if tok == "":
			break
		var ok: bool = bool(n.call("add_candidate", tok, str(mode)))
		await process_frame
		var landed: int = int(n.call("index_of", tok))
		adds.append({
			"mode": str(mode), "token": tok, "ok": ok,
			"focus_before": focus_before, "focus_token": focus_tok,
			"landed": landed, "size_before": size_before,
			"size_after": int(n.call("order_size")),
			"origin": str(n.call("origin_at", landed)),
			"neighbour_before": str(n.call("lookup_at", landed - 1)),
			"neighbour_after": str(n.call("lookup_at", landed + 1)),
			"visible_now": str(n.call("visible_lookups")),
			"beads_now": int(n.call("bead_count")),
		})
		mi += 1
	_facts["adds"] = adds
	for a in adds:
		var ad: Dictionary = a
		var m2 := str(ad["mode"])
		_ck("add %s: accepted" % m2, bool(ad["ok"]), str(ad))
		_ck("add %s: the order grew by one" % m2,
			int(ad["size_after"]) == int(ad["size_before"]) + 1, str(ad))
		_ck("add %s: the bead is marked as the hand's" % m2, str(ad["origin"]) == "hand", str(ad["origin"]))
		_ck("add %s: still ten on the string" % m2, int(ad["beads_now"]) == 10, str(ad["beads_now"]))
		if m2 == "after":
			_ck("add after: landed immediately AFTER the focus bead",
				int(ad["landed"]) == int(ad["focus_before"]) + 1
					and str(ad["neighbour_before"]) == str(ad["focus_token"]), str(ad))
		elif m2 == "before":
			_ck("add before: landed immediately BEFORE the focus bead",
				int(ad["landed"]) == int(ad["focus_before"])
					and str(ad["neighbour_after"]) == str(ad["focus_token"]), str(ad))
	_ck("add is NOT append-only (four positions gave four landing places)",
		adds.size() == 4 and int((adds[0] as Dictionary)["landed"]) != int((adds[1] as Dictionary)["landed"]),
		str(adds.size()))

	# first_in / last_in land at the chapter edges
	if adds.size() >= 4:
		var fa: Dictionary = adds[2]
		var la: Dictionary = adds[3]
		var fseq := _seq_at(n, int(fa["landed"]))
		_ck("add first_in: the bead before it is a DIFFERENT chapter (or it is bead 0)",
			int(fa["landed"]) == 0 or _seq_at(n, int(fa["landed"]) - 1) != fseq,
			"%s | prev %s" % [fseq, _seq_at(n, maxi(0, int(fa["landed"]) - 1))])
		var lseq := _seq_at(n, int(la["landed"]))
		_ck("add last_in: the bead after it is a DIFFERENT chapter (or it is the last bead)",
			int(la["landed"]) == int(n.call("order_size")) - 1
				or _seq_at(n, int(la["landed"]) + 1) != lseq,
			"%s | next %s" % [lseq, _seq_at(n, mini(int(n.call("order_size")) - 1, int(la["landed"]) + 1))])

	# ── 7. REMOVE TAKES OUT THE RIGHT ONE ────────────────────────────────────
	n.call("scroll_by", 500 - int(n.call("focus_index")))
	n.call("settle_scroll")
	await process_frame
	var target: int = 502
	var doomed := str(n.call("lookup_at", target))
	var left := str(n.call("lookup_at", target - 1))
	var right := str(n.call("lookup_at", target + 1))
	var before_size: int = int(n.call("order_size"))
	var dropped: bool = bool(n.call("drop_bead", target))
	await process_frame
	_facts["remove"] = {
		"target": target, "token": doomed, "ok": dropped,
		"size_before": before_size, "size_after": int(n.call("order_size")),
		"now_at_target": str(n.call("lookup_at", target)),
		"now_before_target": str(n.call("lookup_at", target - 1)),
		"still_present": int(n.call("index_of", doomed)),
	}
	_ck("remove: accepted", dropped, doomed)
	_ck("remove: the order shrank by exactly one",
		int(n.call("order_size")) == before_size - 1, str(n.call("order_size")))
	_ck("remove: THAT token is gone", int(n.call("index_of", doomed)) < 0,
		"%s at %d" % [doomed, int(n.call("index_of", doomed))])
	_ck("remove: its left neighbour survived", int(n.call("index_of", left)) == target - 1,
		"%s at %d" % [left, int(n.call("index_of", left))])
	_ck("remove: its right neighbour closed the gap",
		str(n.call("lookup_at", target)) == right, "%s vs %s" % [str(n.call("lookup_at", target)), right])
	_ck("remove: still ten on the string", int(n.call("bead_count")) == 10, str(n.call("bead_count")))

	# ── 8. WHAT WAS WRITTEN ──────────────────────────────────────────────────
	var of := FileAccess.open(TRIAL_OPS, FileAccess.READ)
	var ops_doc: Dictionary = {}
	if of != null:
		var pr: Variant = JSON.parse_string(of.get_as_text())
		of.close()
		ops_doc = pr if pr is Dictionary else {}
	var ops: Array = ops_doc.get("ops", []) if ops_doc.get("ops") is Array else []
	_facts["ops_written"] = ops
	_facts["ops_meta"] = ops_doc.get("_meta", {})
	_ck("the hand file was written", not ops.is_empty(), str(ops.size()))
	var any_index := false
	var all_anchored := true
	for o in ops:
		var od: Dictionary = o
		if od.has("index"):
			any_index = true
		var pos := 0
		for k in ["after", "before", "first_in", "last_in"]:
			if od.has(k):
				pos += 1
		if str(od.get("op", "")) != "remove" and pos != 1:
			all_anchored = false
	_ck("no op carries an index", not any_index, str(ops))
	_ck("every positioning op names exactly one anchor", all_anchored, str(ops))
	_ck("ops_revision counted the writes",
		int((ops_doc.get("_meta", {}) as Dictionary).get("ops_revision", -1)) == ops.size(),
		str(ops_doc.get("_meta", {})))

	# ── 9. NOTHING LIVE WAS TOUCHED ──────────────────────────────────────────
	_ck("commons/data/spine_artifact_order.json untouched", _md5(GENERATED) == gen_before, gen_before)
	_ck("commons/data/spine_order_ops.json untouched", _md5(LIVE_OPS) == ops_before, ops_before)
	_ck("commons/data/spine_order_effective.json untouched", _md5(EFFECTIVE) == eff_before, eff_before)

	# ── 10. ONE LIVE BODY, MEASURED ──────────────────────────────────────────
	var live_i: int = int(n.call("index_of", "origin"))
	if live_i < 0:
		live_i = 3
	n.call("scroll_by", live_i - int(n.call("focus_index")))
	n.call("settle_scroll")
	n.call("set_live", true)
	var lt0 := Time.get_ticks_msec()
	for f in 90:
		await process_frame
		_beat("live")
		if bool(n.call("live_mounted")) and str(n.call("live_note")).contains("shown at"):
			break
	_facts["live"] = {
		"token": str(n.call("lookup_at", live_i)),
		"mounted": bool(n.call("live_mounted")),
		"scale": float(n.call("live_scale")),
		"note": str(n.call("live_note")),
		"ms": Time.get_ticks_msec() - lt0,
	}
	_ck("a live body mounts at the focus", bool(n.call("live_mounted")), str(n.call("live_note")))
	# and scrolling off it frees the body without taking the process with it
	n.call("scroll_by", 4)
	n.call("settle_scroll")
	for f2 in 40:
		await process_frame
		_beat("live off")
	_facts["live_after_scroll"] = str(n.call("live_note"))
	n.call("set_live", false)
	await process_frame
	_ck("survived building and freeing a live body", true, str(n.call("live_note")))

	_beat("done")
	_write(report, true)
	quit(0)


func _same(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true


func _seq_at(n: Node, i: int) -> String:
	# read the chapter off the bead's own subtitle rather than a private field
	var s := _bead_sub(n, i)
	if s == "":
		return "?"
	return s.split(" ")[0]


func _anchor(n: Node, i: int) -> Node3D:
	for c in n.get_children():
		if not (c is Node3D):
			continue
		if str(c.name).begins_with("bead_%d_" % i):
			return c as Node3D
	return null


func _labels(n: Node, i: int) -> Array:
	var a := _anchor(n, i)
	var out: Array = []
	if a == null:
		return out
	for c in a.get_children():
		if c is Label3D:
			out.append(c)
	return out


func _bead_sub(n: Node, i: int) -> String:
	var l := _labels(n, i)
	if l.size() < 1:
		return ""
	return str((l[l.size() - 1] as Label3D).text)


func _bead_cap(n: Node, i: int) -> String:
	var l := _labels(n, i)
	if l.size() < 2:
		return ""
	return str((l[l.size() - 2] as Label3D).text)


func _bead_tile_visible(n: Node, i: int) -> bool:
	var a := _anchor(n, i)
	if a == null:
		return false
	for c in a.get_children():
		if c is Sprite3D:
			return (c as Sprite3D).visible and (c as Sprite3D).texture != null
	return false


func _bead_noimg_visible(n: Node, i: int) -> bool:
	var l := _labels(n, i)
	if l.size() < 3:
		return false
	return bool((l[0] as Label3D).visible)


## Where the ten beads actually stand, in metres.
func _geometry(n: Node) -> Dictionary:
	var first: int = int(n.call("window_first"))
	var xs: Array = []
	var ys: Array = []
	var zs: Array = []
	for i in range(first, first + 10):
		var a := _anchor(n, i)
		if a == null or not a.visible:
			continue
		xs.append(snappedf(a.position.x, 0.01))
		ys.append(snappedf(a.position.y, 0.01))
		zs.append(snappedf(a.position.z, 0.01))
	var mono := xs.size() > 1
	for i in range(1, xs.size()):
		if float(xs[i]) <= float(xs[i - 1]):
			mono = false
	return {
		"n": xs.size(), "xs": xs, "ys": ys, "zs": zs,
		"x_monotonic": mono,
		"x_span": (float(xs[xs.size() - 1]) - float(xs[0])) if xs.size() > 1 else 0.0,
		"y_span": (_maxa(ys) - _mina(ys)) if not ys.is_empty() else 0.0,
		"z_span": (_maxa(zs) - _mina(zs)) if not zs.is_empty() else 0.0,
		"gaps": _gaps(xs),
	}


func _gaps(xs: Array) -> Array:
	var g: Array = []
	for i in range(1, xs.size()):
		g.append(snappedf(float(xs[i]) - float(xs[i - 1]), 0.01))
	return g


func _mina(a: Array) -> float:
	var m := 1.0e9
	for v in a:
		m = minf(m, float(v))
	return m


func _maxa(a: Array) -> float:
	var m := -1.0e9
	for v in a:
		m = maxf(m, float(v))
	return m
