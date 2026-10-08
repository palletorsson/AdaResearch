extends SceneTree
## probe_necklace_jam.gd — THE FRAME THAT NOBODY IS SAMPLING.
##
## probe_necklace_storm.gd measures the worst frame DURING a scroll and reported
## 107 ms for its last storm. The frame it shot at the end of that same run had a
## HUD reading `turing_pattern_generator: building, 5833 ms so far` — a single
## _build_body call that took FIVE POINT EIGHT SECONDS. Both numbers are correct:
## the storm samples the notch loop, and that build happened afterwards, in the
## drain. So the expensive frame is in the blind spot of every timing this scene
## has.
##
## _live_note quotes _build_body's own elapsed time, so it is not proof of a long
## FRAME on its own. This measures the frame directly: park on a chapter, then
## time every frame while the window stands up, and report the longest one
## alongside which token was building when it happened.
##
## LIVE_BUDGET_MS (6 ms) and LIVE_MAX_PER_FRAME (3) cannot help here and the file
## says why at :1644 — no budget can subdivide one _ready(). The question this
## answers is how bad that gets, and on which tokens.
##
##   "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off \
##     --resolution 1600x900 --script res://commons/testing/probe_necklace_jam.gd \
##     -- --out=<dir>

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_jam_necklace_ops.json"

## Where to park. Each is a chapter whose bodies the shot probe never builds.
##   651  softbodies — where the 5833 ms note was caught
##   0    the spine head, the cold-boot case, as a baseline that is known good
##   430  an ordinary mid-string window
const STOPS := [0, 651, 645, 430, 700, 250]


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

	var R: Dictionary = {"probe": "necklace_jam", "stops": []}
	for idx in STOPS:
		R["stops"].append(await _park(n, int(idx)))
	var f := FileAccess.open(outdir + "/necklace_jam.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(R, "  ", false))
		f.close()
	await _shot(outdir + "/jam_end.png")
	quit(0)


## Park at `idx` and time EVERY frame until the window resolves or 25 s passes.
## The note is sampled on the frame the spike happens, so the row names a token.
func _park(n: Node, idx: int) -> Dictionary:
	n.call("scroll_to_index", idx)
	n.call("settle_scroll")
	var t0: int = Time.get_ticks_msec()
	var prev: int = Time.get_ticks_usec()
	var worst: float = 0.0
	var worst_note: String = ""
	var over_100: int = 0
	var over_500: int = 0
	var frames: int = 0
	var last_pend: int = -1
	var last_change: int = t0
	while true:
		await process_frame
		frames += 1
		var now_us: int = Time.get_ticks_usec()
		var dt: float = float(now_us - prev) / 1000.0
		prev = now_us
		if dt > 100.0:
			over_100 += 1
		if dt > 500.0:
			over_500 += 1
		if dt > worst:
			worst = dt
			worst_note = str(n.call("live_note"))
		var now: int = Time.get_ticks_msec()
		var pend: int = int(n.call("live_pending_in_window"))
		if pend != last_pend:
			last_pend = pend
			last_change = now
		if pend == 0 and (now - last_change) >= 300:
			break
		if (now - t0) >= 25000:
			break
	return {
		"index": idx,
		"beads": int(n.call("bead_count")),
		"frames": frames,
		"stand_up_ms": Time.get_ticks_msec() - t0,
		## THE NUMBER. A hand feels the longest single frame, not the total.
		"worst_frame_ms": snappedf(worst, 0.1),
		"worst_frame_note": worst_note,
		"frames_over_100ms": over_100,
		"frames_over_500ms": over_500,
		"pending_left": last_pend,
		"bodies": int(n.call("live_bodies_in_window")),
		"census": str(n.call("live_census")),
	}


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img != null:
		img.save_png(path)
