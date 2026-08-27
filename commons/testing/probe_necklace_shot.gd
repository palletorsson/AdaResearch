extends SceneTree
## probe_necklace_shot.gd — LOOK AT IT. One windowed run, seven PNGs, then quit.
##
## Two defects were measured geometrically (the tenth bead leaving the frustum at
## a chapter seam; both captions rendering under the stage floor). Arithmetic is
## not a picture, and this repo's own memory says to open the PNG. So: run
## windowed (NOT --headless, which has no renderer), grab the viewport after
## frame_post_draw, save, quit.
##
## 2026-08-27, second pass: THE BEADS ARE LIVE BODIES NOW, and a probe that
## shoots 20 frames after a scroll photographs an EMPTY STRING and reports it as
## a refusal. Bodies arrive over several frames on purpose (LIVE_BUDGET_MS per
## frame, LIVE_MAX_PER_FRAME beads) and each is normalised into the bead volume
## LIVE_SETTLE later still, so every shot now waits on live_fitted_in_window()
## going quiet rather than on a frame count. It also prices a scroll notch with
## vsync OFF, because with vsync on every frame reads as 16.7 ms and the one
## number worth having — does a notch BLOCK? — is invisible.
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

	## VSYNC OFF. With it on, every frame measures 16.7 ms and a notch that blocks
	## for 200 ms is indistinguishable from one that costs nothing.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	for i in 20:
		await process_frame
	var first_settle: Dictionary = await _settle_bodies(n)

	var report: Dictionary = {"ok": true, "shots": [], "viewport": [
		root.get_visible_rect().size.x, root.get_visible_rect().size.y]}

	# ── THE SPINE, unchanged. It is the regression half: the source switch must
	#    not have moved anything on the string that was already right.
	report["spine_source"] = str(n.call("source_name"))
	report["spine_size"] = int(n.call("order_size"))
	report["spine_read_only"] = bool(n.call("is_read_only"))
	report["first_settle"] = first_settle
	report["bodies_default_on"] = bool(n.call("live_is_on"))
	await _shot(outdir + "/shot_head.png")
	await _shot(outdir + "/bodies_spine.png")
	report["shots"].append(_survey(n, "spine_head"))

	## THE SAME WINDOW WITH THE BODIES OFF — the like-for-like control. Two things
	## changed in this pass (the light and the beads) and without this frame there
	## is no way to tell which of them a difference belongs to.
	n.call("set_live", false)
	for i in 10:
		await process_frame
	await _shot(outdir + "/tiles_spine.png")
	report["tiles_census"] = str(n.call("live_census"))
	n.call("set_live", true)
	## await into a Dictionary subscript is a coinflip on the parser; the temp
	## var is not style, it is the safe form.
	var cost_spine: Dictionary = await _scroll_cost(n, 6)
	report["scroll_cost_spine"] = cost_spine
	await _settle_bodies(n)

	# a window with a chapter seam to the RIGHT of the focus — the frustum case.
	# window_first 64 was the worst overshoot the frustum probe measured.
	n.call("scroll_to_index", 68)
	n.call("settle_scroll")
	for i in 8:
		await process_frame
	await _settle_bodies(n)
	await _shot(outdir + "/shot_seam.png")
	report["shots"].append(_survey(n, "spine_seam"))

	## THE GPU RUN, AND IT IS THE ONE WINDOW THE WHOLE REFUSAL EXISTS FOR. The path
	## predicate matches 25 tokens on the spine and 20 of them are contiguous at
	## 654-673, so a ten-wide window anchored at 660 holds TEN OF TEN refusals. The
	## claim this frame checks is that the necklace has no HOLE there: ten capture
	## tiles, each badged, and not ten empty plates.
	n.call("scroll_to_index", 664)
	n.call("settle_scroll")
	for i in 8:
		await process_frame
	await _settle_bodies(n)
	await _shot(outdir + "/bodies_spine_gpu.png")
	report["shots"].append(_survey(n, "spine_gpu_run"))

	n.call("scroll_by", 5000)
	n.call("settle_scroll")
	for i in 8:
		await process_frame
	await _settle_bodies(n)
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

	var mset: Dictionary = await _settle_bodies(n)
	report["museum_first_settle"] = mset
	var cost_museum: Dictionary = await _scroll_cost(n, 6)
	report["scroll_cost_museum"] = cost_museum
	## THE CONTROL, AND WITHOUT IT THE HEADLINE NUMBER IS UNATTRIBUTABLE. A museum
	## notch measured a ~80 ms worst frame. Some of that is a body arriving and some
	## of it is the bead itself: every new bead decodes a capture PNG off disk
	## through Image.load_from_file, which this pass did not touch and which happens
	## in tiles mode too. So price a notch with the bodies OFF and subtract.
	n.call("set_live", false)
	for i3 in 20:
		await process_frame
	var cost_tiles: Dictionary = await _scroll_cost(n, 6)
	report["scroll_cost_museum_tiles_only"] = cost_tiles
	n.call("set_live", true)
	var reset: Dictionary = await _settle_bodies(n)
	report["museum_resettle"] = reset
	for stop in MUSEUM_STOPS:
		var name := str((stop as Array)[0])
		var idx: int = int((stop as Array)[1])
		if idx < 0:
			idx = int(n.call("order_size")) - 1
		n.call("scroll_to_index", idx)
		n.call("settle_scroll")
		for i in 10:
			await process_frame
		await _settle_bodies(n)
		await _shot("%s/%s.png" % [outdir, name])
		if name == "museum_head":
			await _shot(outdir + "/bodies_museum.png")
		elif name == "museum_unbuilt":
			await _shot(outdir + "/bodies_museum_unbuilt.png")
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
		## THE BODIES, AND THE BEAD COUNT IS STILL THE THING TO READ FIRST. If
		## `beads` is not 10 nothing else on the row means anything, and if
		## `bodies` is 0 with `beads` at 10 the string is showing photographs.
		"bodies": int(n.call("live_bodies_in_window")),
		"fitted": int(n.call("live_fitted_in_window")),
		"mem_mb": snappedf(float(int(n.call("live_mem_kb"))) / 1024.0, 0.1),
		"scenes_held": int(n.call("scene_cache_size")),
		"census": str(n.call("live_census")),
		"body_rows": n.call("live_body_rows"),
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


## WAIT FOR THE WINDOW TO STAND UP, and wait on the COUNT rather than a frame
## budget. Bounded at `cap` frames so a string that never stands cannot hang the
## run, and it returns what it waited for so a short wait can be told from a
## refusal.
## WAIT ON WALL TIME AND ON live_pending_in_window(), NEVER ON A FRAME COUNT.
## The first version of this helper counted 70 stable frames and broke — which at
## vsync-off is 102 MILLISECONDS, against a LIVE_SETTLE of 350 ms. It duly
## photographed three windows with 0 or 1 of ten bodies standing and reported
## them as settled. Pending == 0 means every bead has resolved into either a body
## or a badged tile.
func _settle_bodies(n: Node, max_ms: int = 12000) -> Dictionary:
	var t0: int = Time.get_ticks_msec()
	var last: int = -1
	var last_change: int = t0
	var f: int = 0
	while true:
		await process_frame
		f += 1
		var now: int = Time.get_ticks_msec()
		var pend: int = int(n.call("live_pending_in_window"))
		if pend != last:
			last = pend
			last_change = now
		if pend == 0 and (now - last_change) >= 250:
			break
		# nothing has moved for a second and a half: whatever is left is stuck
		if (now - last_change) >= 1500 and (now - t0) >= 1000:
			break
		if (now - t0) >= max_ms:
			break
	return {
		"frames": f, "ms": Time.get_ticks_msec() - t0, "pending": last,
		"fitted": int(n.call("live_fitted_in_window")),
		"bodies": int(n.call("live_bodies_in_window")),
		"census": str(n.call("live_census")),
	}


## WHAT A NOTCH COSTS, and the number that matters is the WORST SINGLE FRAME, not
## the total: a notch that spends 300 ms spread over twenty frames is a necklace
## that keeps moving, and one that spends 200 ms in a single frame is a hitch the
## hand feels. Both are reported.
## WHAT A NOTCH COSTS, from a FULLY SETTLED window, and the two numbers mean
## different things:
##   wait_ms          wall clock until the window stands again. Dominated by the
##                    DELIBERATE LIVE_SETTLE of 350 ms, so it is a latency, not a
##                    load. The string keeps moving throughout.
##   worst_frame_ms   the longest single frame during the notch. THIS is the
##                    number a hand feels, and it is bounded by one _ready(),
##                    because LIVE_BUDGET_MS can stop the NEXT body starting but
##                    cannot subdivide one that has.
func _scroll_cost(n: Node, notches: int) -> Dictionary:
	await _settle_bodies(n)
	var waits: Array = []
	var worsts: Array = []
	var pend: Array = []
	for k in notches:
		var t0: int = Time.get_ticks_usec()
		var prev: int = t0
		var worst: float = 0.0
		n.call("scroll_by", 1)
		n.call("settle_scroll")
		var f: int = 0
		while f < 900:
			await process_frame
			f += 1
			var now: int = Time.get_ticks_usec()
			var dt: float = float(now - prev) / 1000.0
			prev = now
			if dt > worst:
				worst = dt
			if f >= 4 and int(n.call("live_pending_in_window")) == 0:
				break
		waits.append(snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.1))
		worsts.append(snappedf(worst, 0.1))
		pend.append(int(n.call("live_pending_in_window")))
	return {"wait_ms": waits, "worst_frame_ms": worsts, "pending_after": pend}


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
