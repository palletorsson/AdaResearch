extends SceneTree
## probe_necklace_frame.gd — ARE ALL TEN BEADS ACTUALLY IN FRAME?
##
## The scene guarantees ten beads by INDEX. This asks the camera itself, at all
## 801 window positions: unproject each bead's plate centre and its left/right
## edges, and count the ones that fall outside the viewport rectangle.
##
## The suspicion, from arithmetic: a chapter seam adds SEAM_EXTRA (1.5 m) to the
## pitch, the window is anchored at slot 4, so a seam falling to the RIGHT of the
## focus pushes the tenth bead past the frustum edge.

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_audit3_necklace_ops.json"
const PLATE_HALF := 0.66     # the bead plate is 1.32 m wide

var _beat_path := ""
var _last := 0


func _initialize() -> void:
	_run()


func _beat(tag: String) -> void:
	if _beat_path == "":
		return
	var now := Time.get_ticks_msec()
	if now - _last < 900:
		return
	_last = now
	var f := FileAccess.open(_beat_path, FileAccess.WRITE)
	if f != null:
		f.store_string("%d %s\n" % [now, tag])
		f.close()


func _run() -> void:
	var report := ProjectSettings.globalize_path("user://probe_necklace_frame.json")
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--report="):
			report = s.split("=", true, 1)[1]
		elif s.begins_with("--beat="):
			_beat_path = s.split("=", true, 1)[1]

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	await process_frame
	await process_frame
	var size: int = int(n.call("order_size"))

	var cam: Camera3D = null
	for c in n.get_children():
		if c is Camera3D:
			cam = c as Camera3D
			break
	var vp := Vector2(cam.get_viewport().get_visible_rect().size)

	var bad_windows: Array = []
	var worst_over := 0.0
	var worst_at := -1
	var clipped_beads := 0
	var windows := 0
	var centre_off := 0

	for w in range(0, size - 9):
		if int(n.call("focus_index")) != mini(w + 4, size - 1):
			n.call("scroll_by", mini(w + 4, size - 1) - int(n.call("focus_index")))
		n.call("settle_scroll")
		if int(n.call("window_first")) != w:
			continue
		windows += 1
		var offenders: Array = []
		for i in range(w, w + 10):
			var a := _anchor(n, i)
			if a == null or not a.visible:
				offenders.append({"i": i, "why": "not drawn"})
				continue
			var c3: Vector3 = a.global_position + a.global_transform.basis * Vector3(0, -0.80, 0)
			var left: Vector3 = c3 - a.global_transform.basis.x * PLATE_HALF
			var right: Vector3 = c3 + a.global_transform.basis.x * PLATE_HALF
			var pc := cam.unproject_position(c3)
			var pl := cam.unproject_position(left)
			var pr := cam.unproject_position(right)
			var over := maxf(maxf(pr.x - vp.x, pl.x - vp.x), maxf(-pl.x, -pr.x))
			if over > 0.0:
				clipped_beads += 1
				var ctr_off: bool = pc.x < 0.0 or pc.x > vp.x
				if ctr_off:
					centre_off += 1
				offenders.append({
					"i": i, "slot": i - w, "centre_px": snappedf(pc.x, 0.1),
					"left_px": snappedf(pl.x, 0.1), "right_px": snappedf(pr.x, 0.1),
					"over_px": snappedf(over, 0.1), "centre_off_frame": ctr_off,
					"lookup": str(n.call("lookup_at", i)),
					"in_frustum": cam.is_position_in_frustum(c3),
				})
				if over > worst_over:
					worst_over = over
					worst_at = w
		if not offenders.is_empty():
			bad_windows.append({"window_first": w, "focus": int(n.call("focus_index")),
				"offenders": offenders})
		if w % 50 == 0:
			_beat("w %d" % w)
			await process_frame

	var doc := {
		"viewport": [vp.x, vp.y],
		"camera": {"fov": cam.fov, "keep_aspect": cam.keep_aspect,
			"pos": [cam.position.x, cam.position.y, cam.position.z]},
		"windows_tested": windows,
		"windows_with_a_clipped_bead": bad_windows.size(),
		"clipped_bead_instances": clipped_beads,
		"beads_whose_CENTRE_is_off_frame": centre_off,
		"worst_overshoot_px": worst_over,
		"worst_overshoot_pct_of_width": (worst_over / maxf(1.0, vp.x)) * 100.0,
		"worst_window_first": worst_at,
		"examples": bad_windows.slice(0, 8),
		"pass": bad_windows.is_empty(),
	}
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(doc, "  ", false))
		f.close()
	_beat("done")
	quit(0)


func _anchor(n: Node, i: int) -> Node3D:
	for c in n.get_children():
		if c is Node3D and str(c.name).begins_with("bead_%d_" % i):
			return c as Node3D
	return null
