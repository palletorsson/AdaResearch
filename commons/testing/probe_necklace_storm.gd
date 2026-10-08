extends SceneTree
## probe_necklace_storm.gd — CONTINUOUS SCROLLING, which is the case the shot
## probe does not cover.
##
## probe_necklace_shot.gd prices a notch from a FULLY SETTLED window and settles
## again before the next one. That is the polite case. The hand does not scroll
## politely: a wheel spin is thirty notches with no settle between any of them,
## and it is the case where a build-ahead/pool design either holds or leaks —
## bodies built for windows the curator has already left, scenes cached past the
## cap, memory climbing, or the bead set going out of sync with the window.
##
## FOUR CLAIMS, none of which a still can check:
##   1. the string never loses its beads. Every necklace probe finds beads by node
##      name and add_child defaults to force_readable_name = false, so a bead
##      rebuilt in the same frame as a queue_free of the same name is @Node3D@N
##      and a name-driven probe measures an EMPTY SET and calls it a pass. So the
##      bead count is sampled DURING the storm, not only after it.
##   2. it drains. pending -> 0 within a bounded wait once the scrolling stops.
##   3. it does not leak. live MB and scenes_held after the storm, against the
##      file's own SCENE_CACHE_CAP and LIVE_MEM_CAP_KB.
##   4. the worst single frame during a storm — the number a hand feels.
##
## Windowed, not --headless: --headless has no RenderingDevice and a body that
## never renders is a body whose cost is not the cost being measured.
##
##   "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off \
##     --resolution 1600x900 --script res://commons/testing/probe_necklace_storm.gd \
##     -- --out=<dir>

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_storm_necklace_ops.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	var outdir := ProjectSettings.globalize_path("user://")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--out="):
			outdir = str(a).split("=", true, 1)[1]

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	for i in 30:
		await process_frame

	var R: Dictionary = {"probe": "necklace_storm", "storms": []}

	R["storms"].append(await _storm(n, "spine_30_notches", 30, 1))
	R["storms"].append(await _storm(n, "spine_back_30", 30, -1))
	## LOCALISING THE BACKWARD STALL. spine_back_30 reproduces a ~950 ms single
	## frame; forward over the same beads costs 47 ms. Two things differ and only
	## one of them is "backwards": it also ENDS at the spine head, whose bodies are
	## the dearest in the corpus (folding_past 386 ms, interactive_point_origin_force
	## 310 ms cold). So storm backwards somewhere ORDINARY, and forwards INTO the
	## head, and let the pair say which it is.
	n.call("scroll_to_index", 430)
	n.call("settle_scroll")
	for i in 20:
		await process_frame
	R["storms"].append(await _storm(n, "spine_back_30_midstring", 30, -1))
	## THE PAIR THAT ISOLATES DIRECTION: the same stretch of string, forwards, from
	## the place the backward run above ended. Same beads, same cost, opposite sign.
	n.call("scroll_to_index", 400)
	n.call("settle_scroll")
	for i in 20:
		await process_frame
	R["storms"].append(await _storm(n, "spine_fwd_30_midstring", 30, 1))
	## TEN AT A TIME is the PgUp/PgDn key, and it skips a whole window per step:
	## nothing built for the window just left can be reused for the next.
	R["storms"].append(await _storm(n, "spine_20_pages", 20, 10))

	n.call("set_source", "museum")
	for i in 30:
		await process_frame
	R["storms"].append(await _storm(n, "museum_30_notches", 30, 1))
	R["storms"].append(await _storm(n, "museum_20_pages", 20, 10))

	## AND BACK, because a source switch mid-storm is what a curator actually does
	## and it frees every bead and every body at once.
	n.call("set_source", "spine")
	for i in 30:
		await process_frame
	R["storms"].append(await _storm(n, "spine_after_switch", 20, 1))

	R["final"] = {
		"beads": int(n.call("bead_count")),
		"bodies": int(n.call("live_bodies_in_window")),
		"pending": int(n.call("live_pending_in_window")),
		"mem_mb": snappedf(float(int(n.call("live_mem_kb"))) / 1024.0, 0.1),
		"scenes_held": int(n.call("scene_cache_size")),
		"air_reasserts": int(n.call("air_reasserts")),
		"source": str(n.call("source_name")),
	}
	await _shot(outdir + "/storm_end.png")

	var f := FileAccess.open(outdir + "/necklace_storm.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(R, "  ", false))
		f.close()
	quit(0)


## Scroll `notches` times with NO settle between them, sampling the bead count on
## every frame, then wait for the drain and report what is left standing.
func _storm(n: Node, label: String, notches: int, step: int) -> Dictionary:
	# start from a known-good window so a bad number belongs to the storm
	await _drain(n, 6000)
	var beads_before: int = int(n.call("bead_count"))
	var mem_before: float = float(int(n.call("live_mem_kb"))) / 1024.0

	var worst: float = 0.0
	var min_beads: int = 99
	var prev: int = Time.get_ticks_usec()
	var t0: int = prev
	for k in notches:
		n.call("scroll_by", step)
		# ONE frame between notches. This is the storm: no settle_scroll, no wait.
		await process_frame
		var now: int = Time.get_ticks_usec()
		var dt: float = float(now - prev) / 1000.0
		prev = now
		if dt > worst:
			worst = dt
		min_beads = mini(min_beads, int(n.call("bead_count")))
	var storm_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0

	var drained: Dictionary = await _drain(n, 8000)
	return {
		"label": label, "notches": notches, "step": step,
		"beads_before": beads_before,
		## THE ONE TO READ FIRST. Anything but 10 and nothing else on the row means
		## anything, because a name-driven probe measuring an empty set reports a
		## clean pass.
		"min_beads_during": min_beads,
		"storm_ms": snappedf(storm_ms, 0.1),
		"worst_frame_ms": snappedf(worst, 0.1),
		"drain_ms": drained["ms"],
		"pending_after": drained["pending"],
		"beads_after": int(n.call("bead_count")),
		"bodies_after": int(n.call("live_bodies_in_window")),
		"fitted_after": int(n.call("live_fitted_in_window")),
		"mem_mb_before": snappedf(mem_before, 0.1),
		"mem_mb_after": snappedf(float(int(n.call("live_mem_kb"))) / 1024.0, 0.1),
		"scenes_held": int(n.call("scene_cache_size")),
		"air_reasserts": int(n.call("air_reasserts")),
	}


func _drain(n: Node, max_ms: int) -> Dictionary:
	var t0: int = Time.get_ticks_msec()
	var last: int = -1
	var last_change: int = t0
	while true:
		await process_frame
		var now: int = Time.get_ticks_msec()
		var pend: int = int(n.call("live_pending_in_window"))
		if pend != last:
			last = pend
			last_change = now
		if pend == 0 and (now - last_change) >= 250:
			break
		if (now - last_change) >= 1500 and (now - t0) >= 1000:
			break
		if (now - t0) >= max_ms:
			break
	return {"ms": Time.get_ticks_msec() - t0, "pending": last}


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img != null:
		img.save_png(path)
