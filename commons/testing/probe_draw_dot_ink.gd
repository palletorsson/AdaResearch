extends SceneTree
## draw_dot's ink + grain HANDOFF, read back (2026-08-23). The typed-set()
## lesson: a config that four green gates say works can still be refused in
## silence — so this probe sets the metas a map token would set, boots the
## scene, and READS the assignments back off the live node and its material.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_draw_dot_ink.gd

const OUT := "res://ada_run/draw_dot_ink_probe.txt"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var scene := load("res://commons/primitives/point/draw_dot.tscn") as PackedScene

	# 1. meta path — the bricolage pattern a map token rides in on
	var a: Node = scene.instantiate()
	a.set_meta("config_ink", "cyan")
	a.set_meta("config_grain", "coarse")
	get_root().add_child(a)
	await process_frame
	var inks: Dictionary = a.get("INKS")
	if str(a.get("ink")) != "cyan":
		fails.append("meta ink refused: ink=%s" % str(a.get("ink")))
	if a.get("trail_color") != inks["cyan"]:
		fails.append("meta ink did not reach trail_color: %s" % str(a.get("trail_color")))
	if not is_equal_approx(float(a.get("min_segment_distance")), 0.03):
		fails.append("meta grain refused: %s" % str(a.get("min_segment_distance")))

	# 2. numeric grain
	a.call("apply_grid_config", {"grain": "0.02"})
	if not is_equal_approx(float(a.get("min_segment_distance")), 0.02):
		fails.append("numeric grain refused: %s" % str(a.get("min_segment_distance")))

	# 2b. resolution — the grid the line snaps onto (mm), meta + runtime
	var c: Node = scene.instantiate()
	c.set_meta("config_resolution", "40")
	get_root().add_child(c)
	await process_frame
	if not is_equal_approx(float(c.get("resolution_mm")), 40.0):
		fails.append("meta resolution refused: %s" % str(c.get("resolution_mm")))
	c.call("apply_grid_config", {"resolution": "80"})
	if not is_equal_approx(float(c.get("resolution_mm")), 80.0):
		fails.append("runtime resolution refused: %s" % str(c.get("resolution_mm")))
	if not is_equal_approx(float(c.call("_res_step")), 0.08):
		fails.append("_res_step wrong: %s" % str(c.call("_res_step")))
	c.queue_free()

	# 2c. HEX ink — the RGB escape hatch past the palette (bare hex, no '#')
	var d: Node = scene.instantiate()
	d.set_meta("config_ink", "00ff00")
	get_root().add_child(d)
	await process_frame
	if d.get("trail_color") != Color.html("00ff00"):
		fails.append("hex meta ink refused: %s" % str(d.get("trail_color")))
	d.call("apply_grid_config", {"ink": "0000ff"})
	if d.get("trail_color") != Color.html("0000ff"):
		fails.append("hex runtime ink refused: %s" % str(d.get("trail_color")))
	d.call("apply_grid_config", {"ink": "not_a_colour"})
	if d.get("trail_color") != Color.html("0000ff"):
		fails.append("invalid ink should be refused, got: %s" % str(d.get("trail_color")))
	d.queue_free()

	# 3. runtime ink change re-tints the LIVE trail material
	a.call("apply_grid_config", {"ink": "amber"})
	if a.get("trail_color") != inks["amber"]:
		fails.append("runtime ink refused: %s" % str(a.get("trail_color")))
	var ti: Node = a.get("_trail_instance")
	if ti != null:
		var m := (ti as GeometryInstance3D).material_override as StandardMaterial3D
		if m == null or m.albedo_color != inks["amber"]:
			fails.append("trail material not re-tinted")
		# dots, not a line: the trail is a MultiMesh dot pool
		if not (ti is MultiMeshInstance3D) or (ti as MultiMeshInstance3D).multimesh == null \
				or (ti as MultiMeshInstance3D).multimesh.instance_count <= 0:
			fails.append("trail is not a dot pool")
	else:
		fails.append("no _trail_instance on the live node")

	# 3b. PEN ON THE WHITEBOARD — a board in the tree, a sample near its face:
	# the dot must land ON the plane, snapped in BOARD space, inside bounds
	var wb: Node3D = (load("res://commons/artifacts/whiteboard/whiteboard.tscn") as PackedScene).instantiate()
	wb.position = Vector3(5, 0, 0)
	get_root().add_child(wb)
	var pen: Node = scene.instantiate()
	pen.set_meta("config_resolution", "40")
	get_root().add_child(pen)
	await process_frame
	await process_frame
	var srfs: Array = wb.call("write_surfaces")
	if srfs.size() != 1:
		fails.append("wall board should answer ONE face, got %d" % srfs.size())
	else:
		var s: Dictionary = srfs[0]
		var o: Vector3 = s["origin"]
		var n: Vector3 = s["normal"]
		var u_ax: Vector3 = s["u"]
		var v_ax: Vector3 = s["v"]
		# a messy point 3 cm off the face, off-grid in u/v
		var probe_p: Vector3 = o + u_ax * 0.137 + v_ax * -0.093 + n * 0.03
		var rec: Vector3 = pen.call("_shape_sample", probe_p)
		var db: Vector3 = rec - o
		if absf(db.dot(u_ax) - 0.12) > 0.001 or absf(db.dot(v_ax) - (-0.08)) > 0.001:
			fails.append("board snap wrong: u=%.3f v=%.3f (wanted 0.12, -0.08)" % [db.dot(u_ax), db.dot(v_ax)])
		if db.dot(n) <= 0.0 or db.dot(n) > 0.05:
			fails.append("dot not lifted off the face: %.4f" % db.dot(n))
		# far from any board: free-space world snap still rules
		var free_rec: Vector3 = pen.call("_shape_sample", Vector3(0.501, 1.013, 0.497))
		if free_rec != Vector3(0.52, 1.0, 0.48):
			fails.append("free-space snap broken: %s" % str(free_rec))
	wb.queue_free()
	pen.queue_free()

	# 4. defaults sacred — an untouched instance keeps the legacy colour
	var b: Node = scene.instantiate()
	get_root().add_child(b)
	await process_frame
	if b.get("trail_color") != Color(1.0, 0.4, 0.9, 1.0):
		fails.append("default trail_color drifted: %s" % str(b.get("trail_color")))
	if str(b.get("ink")) != "magenta":
		fails.append("default ink drifted: %s" % str(b.get("ink")))
	if float(b.get("resolution_mm")) != 0.0:
		fails.append("default resolution drifted: %s" % str(b.get("resolution_mm")))

	a.queue_free()
	b.queue_free()
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(PackedStringArray(fails)))
	out.close()
	print("DRAW_DOT INK: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(PackedStringArray(fails))))
	quit(0 if fails.is_empty() else 1)
