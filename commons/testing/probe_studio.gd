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
	img = get_root().get_texture().get_image(); img.save_png("user://em_studio_after.png")
	print("STUDIO PROBE: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
