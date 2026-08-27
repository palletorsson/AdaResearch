extends SceneTree
## probe_necklace_shot.gd — LOOK AT IT. One windowed run, seven PNGs, then quit.
##
## Two defects were measured geometrically (the tenth bead leaving the frustum at
## a chapter seam; both captions rendering under the stage floor). Arithmetic is
## not a picture, and this repo's own memory says to open the PNG. So: run
## windowed (NOT --headless, which has no renderer), grab the viewport after
## frame_post_draw, save, quit.
##
## 2026-08-27: it now shoots BOTH strings. The scene grew a source switch — TAB
## swaps the spine's 810-bead dealing order for the museum's 1,633 beads as they
## stand from 0 m to 4,270 m — and the museum half has four claims a still can
## check and arithmetic cannot: the metre mark and the hall replacing the index,
## the state, the nth-of-N on a repeating token, and a bead in an unbuilt chapter
## not looking like one that stands.
##
## EVERY NUMBER IN THE REPORT IS READ BACK OFF THE NODES, not recomputed. A probe
## that re-derives the caption it is checking proves the derivation, not the draw.
## bead_lines(i) returns the four Label3D texts of a bead as the engine holds them,
## and it returns them only for a bead that was actually BUILT and VISIBLE.
##
##   "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off \
##     --resolution 1600x900 --script res://commons/testing/probe_necklace_shot.gd \
##     -- --out=<dir>

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_audit5_necklace_ops.json"

## The museum stops, and why each one is here rather than a round number.
##   0     the head. Bead one is folding_past at 4 m — the first thing a visitor
##         meets through the front door.
##   25    Point_Lines, a BUILT hall, and the densest evidence in the string: the
##         window holds laser_measure #4 and #5 of 5, science_screen #1 of 26,
##         three beads slid by a ring search, and station_barrier, which stands in
##         the hall and is in NO curriculum.
##   538   Ribbon_Formfinding_02, an UNBUILT chapter. Ten beads that must not look
##         like the ten above.
##   -1    End: the orphan band, 50 artifacts the curriculum names that stand in
##         no hall at all and have no metre mark.
const MUSEUM_STOPS := [
	["museum_head", 0],
	["museum_built", 25],
	["museum_unbuilt", 538],
	["museum_orphans", -1],
]


func _initialize() -> void:
	_run()


func _run() -> void:
	var outdir := ProjectSettings.globalize_path("user://")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--out="):
			outdir = str(a).split("=", true, 1)[1]

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	for i in 20:
		await process_frame

	var report: Dictionary = {"ok": true, "shots": [], "viewport": [
		root.get_visible_rect().size.x, root.get_visible_rect().size.y]}

	# ── THE SPINE, unchanged. It is the regression half: the source switch must
	#    not have moved anything on the string that was already right.
	report["spine_source"] = str(n.call("source_name"))
	report["spine_size"] = int(n.call("order_size"))
	report["spine_read_only"] = bool(n.call("is_read_only"))
	await _shot(outdir + "/shot_head.png")
	report["shots"].append(_survey(n, "spine_head"))

	# a window with a chapter seam to the RIGHT of the focus — the frustum case.
	# window_first 64 was the worst overshoot the frustum probe measured.
	n.call("scroll_to_index", 68)
	n.call("settle_scroll")
	for i in 8:
		await process_frame
	await _shot(outdir + "/shot_seam.png")
	report["shots"].append(_survey(n, "spine_seam"))

	n.call("scroll_by", 5000)
	n.call("settle_scroll")
	for i in 8:
		await process_frame
	await _shot(outdir + "/shot_tail.png")
	report["shots"].append(_survey(n, "spine_tail"))

	# ── TAB, THROUGH THE REAL INPUT PIPELINE, WITH A CONTROL HOLDING FOCUS.
	#    This is the claim that made _input rather than _unhandled_input the right
	#    place for the key: Godot runs Control focus navigation BEFORE
	#    _shortcut_input and _unhandled_input, and ui_focus_next is bound to Tab,
	#    so a bound-downstream Tab works until the moment somebody clicks in the
	#    add list and then silently stops. Calling set_source() directly would
	#    never have found that. So: open the palette, hand a real Control the
	#    keyboard focus, and send a real key event.
	_key(KEY_A)
	for i in 6:
		await process_frame
	var focus_ctl: Control = n.call("first_focusable")
	report["tab_focus_owner"] = "none" if focus_ctl == null else focus_ctl.get_class()
	if focus_ctl != null:
		focus_ctl.grab_focus()
		await process_frame
	_key(KEY_TAB)
	for i in 8:
		await process_frame
	report["tab_with_focus_lands_on"] = str(n.call("source_name"))
	_key(KEY_TAB)
	for i in 8:
		await process_frame
	report["tab_back_lands_on"] = str(n.call("source_name"))

	# ── THE MUSEUM
	n.call("set_source", "museum")
	# the switch frees every bead and builds ten new ones with new textures; 20
	# frames is what the opening load took and there is no reason to be meaner
	for i in 20:
		await process_frame
	report["museum_source"] = str(n.call("source_name"))
	report["museum_size"] = int(n.call("order_size"))
	report["museum_read_only"] = bool(n.call("is_read_only"))
	report["museum_is_museum"] = bool(n.call("is_museum"))
	report["museum_neutral_origin"] = str(n.call("neutral_origin"))
	report["museum_bands"] = int(n.call("band_count"))

	# THE READ-ONLY VERBS, DRIVEN THROUGH THE SAME FUNCTIONS THE KEYS CALL. A
	# refusal that only exists in the input handler is a refusal a probe cannot
	# see, and this project has shipped one of those before.
	report["refusals"] = {
		"add": bool(n.call("add_candidate", "grey_point", "after")),
		"add_notice": str(n.call("notice")),
		"drop": bool(n.call("drop_bead", 25)),
		"drop_notice": str(n.call("notice")),
		"move": bool(n.call("move_focus", 1)),
		"move_notice": str(n.call("notice")),
		"undo": bool(n.call("undo_last")),
		"undo_notice": str(n.call("notice")),
		"size_after": int(n.call("order_size")),
	}

	for stop in MUSEUM_STOPS:
		var name := str((stop as Array)[0])
		var idx: int = int((stop as Array)[1])
		if idx < 0:
			idx = int(n.call("order_size")) - 1
		n.call("scroll_to_index", idx)
		n.call("settle_scroll")
		for i in 10:
			await process_frame
		await _shot("%s/%s.png" % [outdir, name])
		report["shots"].append(_survey(n, name))

	# R — the string's own _report, verbatim. A panel that throws on open is a live
	# bug the still would never show, because nobody would have opened it.
	n.call("show_why", true)
	for i in 8:
		await process_frame
	report["why_rows"] = int(n.call("why_lines"))
	await _shot(outdir + "/museum_why.png")
	n.call("show_why", false)
	for i in 4:
		await process_frame

	# back to the spine, because a switch that only works one way is half a switch
	n.call("set_source", "spine")
	for i in 12:
		await process_frame
	report["back_to"] = str(n.call("source_name"))
	report["back_size"] = int(n.call("order_size"))
	report["back_read_only"] = bool(n.call("is_read_only"))
	report["back_beads"] = int(n.call("bead_count"))

	var f := FileAccess.open(outdir + "/shot_report.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ", false))
		f.close()
	quit(0)


## What the frame actually holds, read off the built nodes.
##   THE BEAD COUNT COMES FIRST AND ON PURPOSE. Every necklace probe finds beads
## by node name, and add_child defaults to force_readable_name = false, so a bead
## rebuilt in the same frame as a queue_free of the same name is called
## @Node3D@N. In that state a name-driven probe measures an EMPTY SET and reports
## a clean pass. If `beads` is not 10 here, nothing else on the row means anything.
func _survey(n: Node, label: String) -> Dictionary:
	var out: Dictionary = {
		"label": label,
		"beads": int(n.call("bead_count")),
		"window_first": int(n.call("window_first")),
		"focus": int(n.call("focus_index")),
		"band": str(n.call("band_label_at", int(n.call("focus_index")))),
		"lines": [],
	}
	var first: int = int(n.call("window_first"))
	for k in 10:
		var i: int = first + k
		var lines: PackedStringArray = n.call("bead_lines", i)
		out["lines"].append({
			"i": i,
			"at": str(n.call("identity_at", i)),
			"state": str(n.call("state_at", i)),
			"metre": int(n.call("metre_at", i)),
			"mark": lines[0], "place": lines[1], "cap": lines[2], "sub": lines[3],
		})
	return out


## A real key event down the real pipeline — Input.parse_input_event, not a
## direct call to the handler. The whole point of the two TAB checks is that they
## exercise the stage a direct call skips.
func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img != null:
		img.save_png(path)
