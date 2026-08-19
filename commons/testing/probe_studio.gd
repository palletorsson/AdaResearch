extends SceneTree
## Drive the studio without a hand: open primitives/point, screenshot, move a
## body one cell by the same path a drag takes, check the plan row moved, undo.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var s: Node3D = (load("res://commons/scenes/museum_studio.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(s)
	await create_timer(6.0).timeout
	var img: Image = get_root().get_texture().get_image()
	img.save_png("user://em_studio.png")
	print("STUDIO shot saved; status: %s" % (s.get("_status") as Label).text)
	var recs: Array = s.call("_records")
	print("STUDIO records: %d" % recs.size())
	# pick origin (Point Zero) and move it one cell +x by the drag path
	var target: Dictionary = {}
	for r in recs:
		if String(r.get("token", "")) == "origin": target = r
	if target.is_empty():
		print("STUDIO: no origin record"); quit(1); return
	var before: Array = target.get("tile_cell")
	s.set("_sel", target); s.set("_sel_key", s.call("_key_of", target))
	var n: Node3D = target.get("node")
	n.global_position += Vector3(1, 0, 0)
	s.call("_commit_move")
	await create_timer(6.0).timeout
	var row: Dictionary = s.call("_row")
	var moved: Array = []
	for a in row.get("artifacts", []):
		if String((a as Dictionary).get("token", "")) == "origin": moved = (a as Dictionary).get("tile_cell")
	print("STUDIO origin %s -> %s (hand=%s)" % [str(before), str(moved), str((func(): 
		for a in row.get("artifacts", []):
			if String((a as Dictionary).get("token", "")) == "origin": return (a as Dictionary).get("hand")
		return null).call())])
	var ok: bool = moved.size() == 2 and int(moved[0]) == int(before[0]) + 1
	s.call("_do_undo")
	await create_timer(6.0).timeout
	var back: Array = []
	for a in (s.call("_row") as Dictionary).get("artifacts", []):
		if String((a as Dictionary).get("token", "")) == "origin": back = (a as Dictionary).get("tile_cell")
	print("STUDIO undo -> %s" % str(back))
	ok = ok and int(back[0]) == int(before[0])
	# slice 2: a bench (furniture) offset, a wall variant dropped, a plinth nudged — all plan-row dressing
	var recs2: Array = s.call("_records")
	var bench: Dictionary = {}; var variant: Dictionary = {}; var plinth: Dictionary = {}
	for r in recs2:
		var kd: String = s.call("_kind", r)
		if kd == "furniture" and bench.is_empty(): bench = r
		if kd == "variant" and variant.is_empty(): variant = r
		if kd == "plinth" and plinth.is_empty(): plinth = r
	print("STUDIO kinds: furniture=%s variant=%s plinth=%s" % [not bench.is_empty(), not variant.is_empty(), not plinth.is_empty()])
	if not bench.is_empty():
		s.set("_sel", bench); s.set("_sel_key", s.call("_key_of", bench)); s.set("_drag_start_pos", (bench.get("node") as Node3D).global_position)
		(bench.get("node") as Node3D).global_position += Vector3(0.6, 0, 0)
		s.call("_commit_move")
		await create_timer(6.0).timeout
		var dr: Array = (s.call("_row") as Dictionary).get("dressing", [])
		print("STUDIO dressing rules after bench move: %s" % str(dr))
		ok = ok and dr.size() >= 1 and String((dr[0] as Dictionary).get("kind", "")) == "furniture"
	if not variant.is_empty():
		s.set("_sel", variant); s.set("_sel_key", s.call("_key_of", variant))
		s.call("_write_variants", [{"run": int(variant.get("run")), "vi": int(variant.get("vi")), "drop": true}])
		await create_timer(6.0).timeout
		var runs: Array = (s.call("_row") as Dictionary).get("wall_runs", [])
		var dropped: Array = (runs[int(variant.get("run"))] as Dictionary).get("drop", [])
		print("STUDIO variant run %d drop=%s" % [int(variant.get("run")), str(dropped)])
		ok = ok and dropped.size() == 1
	if not plinth.is_empty():
		# records were rebuilt twice since: fetch the plinth again by key
		var pk: String = s.call("_key_of", plinth)
		plinth = {}
		for r in (s.call("_records") as Array):
			if String(s.call("_key_of", r)) == pk: plinth = r
	if not plinth.is_empty():
		s.set("_sel", plinth); s.set("_sel_key", s.call("_key_of", plinth)); s.set("_drag_start_pos", (plinth.get("node") as Node3D).global_position)
		(plinth.get("node") as Node3D).global_position += Vector3(0, 0, 0.4)
		s.call("_commit_move")
		await create_timer(6.0).timeout
		var dr2: Array = (s.call("_row") as Dictionary).get("dressing", [])
		var kinds2: Array = []
		for d in dr2: kinds2.append((d as Dictionary).get("kind"))
		print("STUDIO dressing after plinth nudge: %d rule(s): %s" % [dr2.size(), str(kinds2)])
		ok = ok and dr2.size() >= 2
	# undo everything back
	for i in range(3):
		s.call("_do_undo"); await create_timer(6.0).timeout
	var row3: Dictionary = s.call("_row")
	print("STUDIO after undos: dressing %d, drops %s" % [(row3.get("dressing", []) as Array).size(), str(((row3.get("wall_runs", []) as Array)[0] as Dictionary).get("drop", [])) if not (row3.get("wall_runs", []) as Array).is_empty() else "-"])
	ok = ok and (row3.get("dressing", []) as Array).is_empty()
	# speak panel: select Point Zero and shoot
	for r in (s.call("_records") as Array):
		if String(r.get("token", "")) == "origin" and String(s.call("_kind", r)) == "body":
			s.set("_sel", r); s.set("_sel_key", s.call("_key_of", r)); s.call("_refresh_marks"); s.call("_refresh_speak")
	await create_timer(0.5).timeout
	img = get_root().get_texture().get_image(); img.save_png("user://em_studio_speak.png")
	print("STUDIO speak panel: %d line(s)" % (s.get("_speak_box") as VBoxContainer).get_child_count())
	img = get_root().get_texture().get_image(); img.save_png("user://em_studio_after.png")
	# the isometric view, zoomed on the first hall
	s.set("_iso", true); s.set("_cam_size", 22.0); s.set("_cam_target", Vector3(7.5, 0, 10.0)); s.call("_apply_cam")
	await create_timer(0.6).timeout
	img = get_root().get_texture().get_image(); img.save_png("user://em_studio_iso.png")
	print("STUDIO iso shot; selection: %s" % (s.get("_sel_label") as Label).text)
	print("STUDIO PROBE: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
