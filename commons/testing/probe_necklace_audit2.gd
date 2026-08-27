extends SceneTree
## probe_necklace_audit2.gd — the three questions probe_necklace_audit.gd left open:
##   1. what a WARM scroll notch costs, separated from the cold PNG load
##   2. what the tool does when its order file is missing — a sentence, or a blank stage
##   3. whether the HUD actually says the edit is not yet derived
##
## Writes a JSON report; nothing is printed, because the 4.6 exe is non-console.

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_audit2_necklace_ops.json"
const LIVE_OPS := "res://commons/data/spine_order_ops.json"

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


func _run() -> void:
	var report := ProjectSettings.globalize_path("user://probe_necklace_audit2.json")
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--report="):
			report = s.split("=", true, 1)[1]
		elif s.begins_with("--beat="):
			_beat_path = s.split("=", true, 1)[1]
	_beat("boot")
	var ops_before := FileAccess.get_md5(LIVE_OPS) if FileAccess.file_exists(LIVE_OPS) else "absent"
	if FileAccess.file_exists(TRIAL_OPS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIAL_OPS))

	var ps := load(SCENE) as PackedScene

	# ── 2. THE MISSING ORDER ────────────────────────────────────────────────
	var broken: Node = ps.instantiate()
	broken.set("effective_path", "res://commons/data/_no_such_order.json")
	broken.set("ops_path", TRIAL_OPS)
	root.add_child(broken)
	await process_frame
	await process_frame
	var fm := str(broken.call("fatal_message"))
	_facts["fatal_message"] = fm
	_facts["fatal_hud"] = _find_hud_text(broken)
	_facts["fatal_panel_labels"] = _panel_texts(broken)
	_ck("a missing order file is fatal, not silent", fm != "", fm.substr(0, 80))
	_ck("the fatal sentence names the file", fm.contains("_no_such_order.json"), fm.substr(0, 120))
	_ck("the fatal sentence names the command that fixes it",
		fm.contains("necklace_order.py"), fm.substr(0, 200))
	_ck("something is on screen saying so", _panel_texts(broken).size() > 0,
		str(_panel_texts(broken).size()))
	_ck("no beads are drawn over a missing order", int(broken.call("bead_count")) == 0,
		str(broken.call("bead_count")))
	# a key press into a fatal scene must not crash it
	broken.call("scroll_by", 5)
	broken.call("settle_scroll")
	await process_frame
	_ck("a fatal scene survives a scroll", true, "")
	broken.queue_free()
	await process_frame
	_beat("fatal done")

	# ── 1. WARM VS COLD SCROLL ──────────────────────────────────────────────
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	await process_frame
	await process_frame
	var size: int = int(n.call("order_size"))

	var cold := _sweep(n, size, "cold")
	await process_frame
	# home, then the SAME walk again with every texture already in the cache
	n.call("scroll_by", -size * 2)
	n.call("settle_scroll")
	await process_frame
	var warm := _sweep(n, size, "warm")
	_facts["cold_sweep"] = cold
	_facts["warm_sweep"] = warm
	_ck("a warm scroll notch is under 25 ms", float(warm["mean_ms"]) < 25.0, str(warm))
	_ck("the worst warm notch is under 120 ms", float(warm["worst_ms"]) < 120.0, str(warm))
	_ck("PgDn (ten at once) is under 200 ms", float(warm["page_ms"]) < 200.0, str(warm))

	# ── 3. THE STALENESS SENTENCE ───────────────────────────────────────────
	var hud_before := _find_hud_text(n)
	var tok := ""
	for i in range(0, 60):
		var c := str(n.call("candidate_lookup_at", i))
		if c != "" and int(n.call("index_of", c)) < 0:
			tok = c
			break
	var added: bool = bool(n.call("add_candidate", tok, "after"))
	await process_frame
	var hud_after := _find_hud_text(n)
	_facts["hud_before_edit"] = hud_before
	_facts["hud_after_edit"] = hud_after
	_ck("an edit was accepted for the staleness test", added, tok)
	_ck("the HUD says the edit is written but NOT yet derived",
		hud_after.contains("SAVED") and hud_after.contains("necklace_order.py --apply"),
		hud_after)
	_ck("the HUD carries the plan-mode caveat verbatim",
		hud_after.contains("plan mode") or hud_after.contains("em_plan.json"), hud_after)
	_ck("the HUD counts the hand's edits", hud_after.contains("1 added"), hud_after)

	# ── and the live hand file is still untouched ───────────────────────────
	var ops_after := FileAccess.get_md5(LIVE_OPS) if FileAccess.file_exists(LIVE_OPS) else "absent"
	_ck("commons/data/spine_order_ops.json untouched", ops_after == ops_before, ops_before)

	_beat("done")
	var failed: Array = []
	for c in _checks:
		if not bool((c as Dictionary)["ok"]):
			failed.append(str((c as Dictionary)["check"]))
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"pass": failed.is_empty(), "checks": _checks.size(),
			"failed": failed, "facts": _facts, "rows": _checks,
		}, "  ", false))
		f.close()
	quit(0)


func _sweep(n: Node, size: int, tag: String) -> Dictionary:
	var ms: Array = []
	var worst := 0
	for i in range(0, size):
		var t0 := Time.get_ticks_msec()
		n.call("scroll_by", 1)
		n.call("settle_scroll")
		var dt: int = Time.get_ticks_msec() - t0
		ms.append(dt)
		worst = maxi(worst, dt)
		if i % 60 == 0:
			_beat("%s %d" % [tag, i])
			await_frame()
	var total := 0
	for v in ms:
		total += int(v)
	# and one page jump, which is what PgDn does
	n.call("scroll_by", -size)
	n.call("settle_scroll")
	var p0 := Time.get_ticks_msec()
	n.call("scroll_by", 10)
	n.call("settle_scroll")
	var page := Time.get_ticks_msec() - p0
	return {
		"steps": ms.size(), "total_ms": total,
		"mean_ms": float(total) / maxf(1.0, float(ms.size())),
		"worst_ms": worst, "page_ms": page,
	}


func await_frame() -> void:
	pass


## The HUD is a Label under a CanvasLayer. Read it off the tree rather than
## through an accessor, so what the probe reads is what a person would see.
func _find_hud_text(n: Node) -> String:
	var best := ""
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for g in c.get_children():
			stack.append(g)
		if c is Label:
			var t := str((c as Label).text)
			if t.contains("[NECKLACE]") and t.length() > best.length():
				best = t
	return best


## Every Label on screen, for the fatal case where the HUD is not the message.
func _panel_texts(n: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for g in c.get_children():
			stack.append(g)
		if c is Label and str((c as Label).text).strip_edges() != "":
			out.append(str((c as Label).text))
	return out
