extends SceneTree
## The Godot stamp editor's write path, held headless: 25 stamps load from
## the data files, the cursor places, a stamp writes floor "1" / wall "2"
## into a 17-wide layers.museum, and erase clears it.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_map_stamp.gd

const OUT := "res://ada_run/map_stamp_probe.txt"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var ed: Node3D = (load("res://commons/scenes/map_tool_editor.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(ed)
	await process_frame
	ed.set("_map", {"layers": {"structure": [["1", "1"], ["1", "1"]]}})
	ed.set("_total", 1.0)
	ed.call("_load_stamps")
	var stamps: Array = ed.get("_stamps")
	if stamps.size() < 10:
		fails.append("expected >10 museum stamps, got %d" % stamps.size())
	ed.call("_stamp_place_cursor")
	await process_frame
	var cur: Node3D = null
	for c in ed.get_children():
		if c.name == "StampCursor":
			cur = c
	if cur == null:
		fails.append("no stamp cursor placed")
	else:
		cur.position = Vector3(0, 0, 3.0)
		ed.call("_stamp_apply")
		var mus: Variant = ((ed.get("_map") as Dictionary).get("layers", {}) as Dictionary).get("museum")
		if not (mus is Array) or (mus as Array).is_empty():
			fails.append("stamp wrote no museum layer")
		else:
			var rows: Array = mus
			if (rows[0] as Array).size() != 17:
				fails.append("layer width %d, wanted 17" % (rows[0] as Array).size())
			var floors := 0
			var walls := 0
			for row in rows:
				for v in row:
					if str(v) == "1":
						floors += 1
					elif str(v) == "2":
						walls += 1
			if floors == 0 or walls == 0:
				fails.append("stamp wrote floors=%d walls=%d" % [floors, walls])
			# origin-anchored: the stamp starts at 0,0 and the layer's
			# length IS the stamp's height (no extra set step)
			var st: Dictionary = stamps[int(ed.get("_stamp_i")) % stamps.size()]
			if rows.size() != (st["tile"] as Array).size():
				fails.append("layer %d row(s), wanted the stamp's %d" % [rows.size(), (st["tile"] as Array).size()])
			var first_content := -1
			for z in range(rows.size()):
				for v in (rows[z] as Array):
					if str(v) != "0":
						first_content = z
						break
				if first_content >= 0:
					break
			if first_content > 0:
				fails.append("first stamped row is %d, wanted 0 (origin anchor)" % first_content)
			ed.call("_stamp_erase")
			var mus2: Array = ((ed.get("_map") as Dictionary).get("layers", {}) as Dictionary).get("museum")
			var left := 0
			for row in mus2:
				for v in row:
					if str(v) != "0":
						left += 1
			if left != 0:
				fails.append("erase left %d cell(s)" % left)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("PASS (%d stamps)" % stamps.size() if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f.close()
	print("MAP STAMP: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
