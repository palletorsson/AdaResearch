extends SceneTree
## probe_necklace_verify.gd — INDEPENDENT VERIFICATION of the necklace repairs.
##
## Written by the verifying agent, not the repairing one. It deliberately does
## NOT reuse probe_necklace_frame.gd's measurement, because that probe measures
## the bead PLATE (+/-0.66 m) and the repair report itself flagged that the
## caption is wider (0.825 m of layout) and therefore untested.
##
## Three questions the existing probes do not answer:
##
##   A  CAPTIONS IN FRAME. Not the plate. Every Label3D's REAL extent, read off
##      its own get_aabb() (the generated text quad, not an assumed constant),
##      unprojected corner by corner, at all 801 window positions.
##
##   B  TEN BEADS, ALL 810, CLEAN ENDS. Walk every window; assert ten drawn
##      beads each time and collect the union of what was shown.
##
##   C  THE PANEL OVER THE BEADS. The detail panel is anchored at a FRACTION of
##      viewport height (0.44). That is only safe if the bead band starts below
##      it at EVERY aspect, so this measures both rects at five viewport sizes.
##
## Also reports the on-screen pixel height of each caption, because "is it in
## frame" and "can it be read" are different questions and only one of them has
## ever been measured.

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_verify_necklace_ops.json"


func _initialize() -> void:
	_run()


func _anchor(n: Node, i: int) -> Node3D:
	for c in n.get_children():
		if c is Node3D and str(c.name).begins_with("bead_%d_" % i):
			return c as Node3D
	return null


## Screen-space rect of a VisualInstance3D's real AABB. Returns an empty
## dictionary when any corner is behind the camera (unproject is meaningless
## there and a silent garbage number is worse than a gap).
func _screen_rect(vi: VisualInstance3D, cam: Camera3D) -> Dictionary:
	var ab: AABB = vi.get_aabb()
	if ab.size.length() <= 0.0:
		return {"why": "empty_aabb"}
	var gx: Transform3D = vi.global_transform
	var minx := 1.0e18
	var maxx := -1.0e18
	var miny := 1.0e18
	var maxy := -1.0e18
	for corner in 8:
		var local: Vector3 = ab.position + Vector3(
			ab.size.x * float(corner & 1),
			ab.size.y * float((corner >> 1) & 1),
			ab.size.z * float((corner >> 2) & 1))
		var world: Vector3 = gx * local
		if cam.is_position_behind(world):
			return {"why": "behind_camera"}
		var s: Vector2 = cam.unproject_position(world)
		minx = minf(minx, s.x)
		maxx = maxf(maxx, s.x)
		miny = minf(miny, s.y)
		maxy = maxf(maxy, s.y)
	return {"min_x": minx, "max_x": maxx, "min_y": miny, "max_y": maxy}


func _run() -> void:
	var report := ProjectSettings.globalize_path("user://probe_necklace_verify.json")
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--report="):
			report = s.split("=", true, 1)[1]

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	await process_frame
	await process_frame

	var cam: Camera3D = null
	for c in n.get_children():
		if c is Camera3D:
			cam = c as Camera3D
			break

	var size: int = int(n.call("order_size"))
	var vp := Vector2(cam.get_viewport().get_visible_rect().size)

	# ------------------------------------------------------------------ A + B
	var seen: Dictionary = {}
	var windows := 0
	var windows_not_ten := 0
	var caption_clipped := 0
	var plate_clipped := 0
	var worst_cap_over := 0.0
	var worst_cap_at := -1
	var worst_cap_who := ""
	var examples: Array = []
	var px_heights: Array = []
	var behind := 0
	var empty_aabb := 0
	var labels_measured := 0
	var labels_unmeasured := 0

	for w in range(0, size - 9):
		var want: int = mini(w + 4, size - 1)
		if int(n.call("focus_index")) != want:
			n.call("scroll_by", want - int(n.call("focus_index")))
		n.call("settle_scroll")
		if int(n.call("window_first")) != w:
			continue
		windows += 1
		var drawn := 0
		for i in range(w, w + 10):
			var anc := _anchor(n, i)
			if anc == null or not anc.visible:
				continue
			drawn += 1
			seen[str(n.call("lookup_at", i))] = true
			for g in anc.get_children():
				if not (g is VisualInstance3D):
					continue
				var vi := g as VisualInstance3D
				var is_label: bool = g is Label3D
				var r := _screen_rect(vi, cam)
				if r.has("why"):
					if str(r["why"]) == "behind_camera":
						behind += 1
					else:
						empty_aabb += 1
					if is_label:
						labels_unmeasured += 1
					continue
				if is_label:
					labels_measured += 1
				var over: float = maxf(-float(r["min_x"]), float(r["max_x"]) - vp.x)
				if over > 0.0:
					if is_label:
						caption_clipped += 1
						if over > worst_cap_over:
							worst_cap_over = over
							worst_cap_at = w
							worst_cap_who = str(n.call("lookup_at", i))
						if examples.size() < 8:
							examples.append({
								"window_first": w, "bead": i,
								"lookup": str(n.call("lookup_at", i)),
								"text": str((g as Label3D).text).replace("\n", " ").substr(0, 30),
								"min_x": snappedf(float(r["min_x"]), 0.1),
								"max_x": snappedf(float(r["max_x"]), 0.1),
								"over_px": snappedf(over, 0.1),
								"viewport_w": vp.x})
					else:
						plate_clipped += 1
				# legibility: how tall is this caption on screen, in pixels
				if is_label and w == 0:
					px_heights.append({
						"bead": i,
						"text": str((g as Label3D).text).replace("\n", " ").substr(0, 34),
						"px_h": snappedf(float(r["max_y"]) - float(r["min_y"]), 0.1),
						"px_w": snappedf(float(r["max_x"]) - float(r["min_x"]), 0.1)})
		if drawn != 10:
			windows_not_ten += 1
			if examples.size() < 12:
				examples.append({"window_first": w, "drawn_beads": drawn})
		if w % 60 == 0:
			await process_frame

	# ------------------------------------------------------------------ ends
	# ONE FRAME BETWEEN THE JUMPS, AND IT IS LOAD-BEARING. queue_free() keeps a
	# freed bead in the tree, holding its NAME, until the end of the frame; a
	# rebuild in that same frame hits add_child's duplicate-name path, which with
	# force_readable_name false hands out a dummy "@Node3D@N" instead. Every
	# probe here finds beads by the "bead_%d_" prefix, so without this await the
	# anchors are all still there, correctly placed and visible, and the search
	# quietly matches none of them - a pass measured over an empty set.
	n.call("scroll_by", -size)
	n.call("settle_scroll")
	var head_first: int = int(n.call("window_first"))
	var head_n: int = int(n.call("bead_count"))
	await process_frame
	await process_frame
	n.call("scroll_by", size)
	n.call("settle_scroll")
	await process_frame
	await process_frame
	var tail_first: int = int(n.call("window_first"))
	var tail_n: int = int(n.call("bead_count"))
	var tail_last: String = str(n.call("lookup_at", size - 1))

	# ------------------------------------------------------------------- C
	var aspects: Array = []
	# [0,0] is a SENTINEL: measure once WITHOUT resizing. If the beads are found
	# here and vanish on the next entry, the resize is what removes them and the
	# zero is a fact about this probe, not about the panel.
	for wh in [[0, 0], [1600, 900], [1920, 1080], [1280, 720], [1024, 768], [1280, 1024]]:
		var pair: Array = wh
		if int(pair[0]) > 0:
			root.size = Vector2i(int(pair[0]), int(pair[1]))
		# The scene builds only SLACK_BUILD (3) beads per frame, so a window that
		# has just been rebuilt is half-empty for several frames. Settle the
		# scroll and then give it far more frames than it can need: a zero
		# measurement here would otherwise read as "the panel covers nothing".
		n.call("settle_scroll")
		for _f in 30:
			await process_frame
		var panel: Control = n.get("_detail_panel") as Control
		var vs := Vector2(cam.get_viewport().get_visible_rect().size)
		var prect := Rect2(0, 0, 0, 0)
		if panel != null:
			prect = panel.get_global_rect()
		# top of the bead band, and the rightmost pixel any bead part reaches
		var band_top := 1.0e18
		var band_right := -1.0e18
		var overlap := 0
		var measured2 := 0
		var anchors2 := 0
		# INDEX-FREE. Take every bead anchor that is actually in the tree, so a
		# window-index mismatch cannot masquerade as "the panel covers nothing".
		var live_anchors: Array = []
		var child_names: Array = []
		var total_children := 0
		var named_bead := 0
		var named_bead_visible := 0
		var kids: Array = n.get_children()
		for ci in range(kids.size()):
			var c2: Node = kids[ci] as Node
			total_children += 1
			# Print the TAIL of the child list verbatim, whatever it is named -
			# a prefix test that quietly matches nothing is how a probe reports
			# "the panel covers no beads" about a scene it never found.
			if ci >= kids.size() - 15:
				child_names.append("%d:%s:%s" % [ci, str(c2.name), c2.get_class()])
			if str(c2.name).begins_with("bead_"):
				named_bead += 1
				if c2 is Node3D and (c2 as Node3D).visible:
					named_bead_visible += 1
					live_anchors.append(c2)
		for anc2v in live_anchors:
			var anc2: Node3D = anc2v as Node3D
			anchors2 += 1
			for g2 in anc2.get_children():
				if not (g2 is VisualInstance3D):
					continue
				var r2 := _screen_rect(g2 as VisualInstance3D, cam)
				if r2.has("why"):
					continue
				measured2 += 1
				band_top = minf(band_top, float(r2["min_y"]))
				band_right = maxf(band_right, float(r2["max_x"]))
				if panel != null:
					var br := Rect2(Vector2(float(r2["min_x"]), float(r2["min_y"])),
						Vector2(float(r2["max_x"]) - float(r2["min_x"]),
							maxf(1.0, float(r2["max_y"]) - float(r2["min_y"]))))
					if prect.intersects(br):
						overlap += 1
		aspects.append({
			"viewport": [vs.x, vs.y],
			"aspect": snappedf(vs.x / maxf(1.0, vs.y), 0.001),
			"panel_rect": [snappedf(prect.position.x, 0.1), snappedf(prect.position.y, 0.1),
				snappedf(prect.size.x, 0.1), snappedf(prect.size.y, 0.1)],
			"panel_bottom_px": snappedf(prect.end.y, 0.1),
			"panel_bottom_frac_of_height": snappedf(prect.end.y / maxf(1.0, vs.y), 0.001),
			"panel_right_px": snappedf(prect.end.x, 0.1),
			"panel_inside_viewport": prect.end.x <= vs.x + 0.5 and prect.position.x >= -0.5,
			"bead_band_top_px": snappedf(band_top, 0.1),
			"bead_band_top_frac_of_height": snappedf(band_top / maxf(1.0, vs.y), 0.001),
			"bead_band_right_px": snappedf(band_right, 0.1),
			"gap_panel_to_beads_px": snappedf(band_top - prect.end.y, 0.1),
			"bead_parts_the_panel_covers": overlap,
			"anchors_found": anchors2,
			"bead_parts_measured": measured2,
			"window_first": int(n.call("window_first")),
			"bead_count_api": int(n.call("bead_count")),
			"total_children": total_children,
			"children_named_bead": named_bead,
			"children_named_bead_visible": named_bead_visible,
			"sample_bead_names": child_names,
		})

	var doc := {
		"order_size": size,
		"probe_viewport_for_A_B": [vp.x, vp.y],
		"camera_fov": cam.fov,
		"camera_keep_aspect": cam.keep_aspect,
		"A_captions": {
			"windows_tested": windows,
			"caption_instances_clipped": caption_clipped,
			"plate_instances_clipped": plate_clipped,
			"worst_caption_overshoot_px": snappedf(worst_cap_over, 0.1),
			"worst_at_window_first": worst_cap_at,
			"worst_lookup": worst_cap_who,
			"parts_skipped_corner_behind_camera": behind,
			"parts_skipped_empty_aabb": empty_aabb,
			"LABELS_ACTUALLY_MEASURED": labels_measured,
			"labels_skipped": labels_unmeasured,
			"pass": caption_clipped == 0 and plate_clipped == 0 and labels_measured > 0,
		},
		"B_reachability": {
			"windows_tested": windows,
			"windows_not_showing_ten_beads": windows_not_ten,
			"distinct_beads_ever_shown": seen.size(),
			"head_window_first": head_first, "head_beads": head_n,
			"tail_window_first": tail_first, "tail_beads": tail_n,
			"tail_last_lookup": tail_last,
			"pass": windows_not_ten == 0 and seen.size() == size
				and head_first == 0 and head_n == 10
				and tail_first == size - 10 and tail_n == 10,
		},
		"C_panel": aspects,
		"caption_pixel_sizes_at_window_0": px_heights,
		"examples": examples,
	}
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(doc, "  ", false))
		f.close()
	quit(0)
