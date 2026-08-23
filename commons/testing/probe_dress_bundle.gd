extends SceneTree
## THE DRESS BUNDLE, held in the museum (2026-08-23, Palle: "plinth height,
## rotate, offset connected to the artifact — drag the bundle dressing with
## the artifact"). The probe dresses the green rank pen with #plinth:0.6 in
## the REAL Point_Trace map, boots the real museum with trial control files,
## and asserts:
##   1. the pen stands ON a plinth at its deck (~0.6 m), hover consumed
##   2. the record carries the BUNDLE BOND (plinth_node)
##   3. THE DRAG: _edit_nudge moves pen AND plinth together — the dress
##      travels with the artifact
## Then the map is RESTORED byte-for-byte (20-retry, the editor-lock rule).
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_dress_bundle.gd

const OUT := "res://ada_run/dress_bundle_probe.txt"
const MAP := "res://commons/maps/Point_Trace/map_data.json"
const GREEN := "draw_dot:0:1#retention:trace#resolution:40#ink:00ff00"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var original := FileAccess.get_file_as_string(MAP)
	if original.find(GREEN) < 0:
		fails.append("fixture missing: green rank token not in the map")
	else:
		# dress the green pen: a 0.6 m plinth, plus a fine offset to prove the key
		var dressed := original.replace(GREEN, GREEN + "#plinth:0.6")
		var wf := FileAccess.open(MAP, FileAccess.WRITE)
		wf.store_string(dressed)
		wf.close()

		var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
		inst.set("EM_CONTROL", "res://ada_run/_trial_db_control.json")
		inst.set("_overrides_path", "res://ada_run/_trial_db_overrides.json")
		inst.set("_hand_path", "res://ada_run/_trial_db_hand.json")
		var ctl := FileAccess.open("res://ada_run/_trial_db_control.json", FileAccess.WRITE)
		ctl.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 0, "grid_pack": 1}, " "))
		ctl.close()
		get_root().add_child(inst)
		var seg2: Node3D = null
		for i in range(60):
			await create_timer(0.5).timeout
			for c in inst.get_children():
				if c is Node3D and str(c.name).begins_with("Seg2_"):
					seg2 = c
			if seg2 != null:
				break
		await create_timer(1.0).timeout
		if seg2 == null:
			fails.append("Seg2 (point trace) never built")
		else:
			# find the green pen and its record
			var pen: Node3D = null
			for n in seg2.find_children("*", "Node3D", true, false):
				if str(n.get("ink")) == "00ff00":
					pen = n
			if pen == null:
				fails.append("green pen not in the hall")
			else:
				# 1. standing ON the deck, hover consumed. The stamp seats a
				# LIFTED artifact by its MEASURED FLOOR, not its origin — the
				# pen's origin rides ~0.62 above its base — so the honest
				# band is deck < y < deck + origin-height. With the hover NOT
				# consumed it would stand at ~2.2 (deck + 1 m + seat).
				var py := pen.global_position.y
				if py < 0.55 or py > 1.9:
					fails.append("pen not seated on the deck: y=%.2f (wanted 0.6..1.9; ~2.2 means hover stacked on the plinth)" % py)
				# 2. the bundle bond on the record
				var recs: Array = inst.get("_edit_records")
				var ri := -1
				for i2 in range(recs.size()):
					var r: Dictionary = recs[i2]
					if r.get("node") == pen or (r.get("node") != null and is_instance_valid(r.get("node")) \
							and (r.get("node") as Node).is_ancestor_of(pen)):
						ri = i2
				if ri < 0:
					fails.append("no edit record for the green pen")
				else:
					var rec: Dictionary = recs[ri]
					var pl: Node3D = rec.get("plinth_node") if rec.get("plinth_node") is Node3D else null
					if pl == null or not is_instance_valid(pl):
						fails.append("record carries no plinth_node — the bond is missing")
					else:
						# 3. THE DRAG: nudge +1x, both must travel
						var pen_root: Node3D = rec.get("node")
						var px0: float = pen_root.position.x
						var plx0: float = pl.position.x
						inst.set("_edit_sel", ri)
						inst.call("_edit_nudge", 1, 0)
						if absf(pen_root.position.x - (px0 + 1.0)) > 0.01:
							fails.append("nudge did not move the artifact: %.2f -> %.2f" % [px0, pen_root.position.x])
						if absf(pl.position.x - (plx0 + 1.0)) > 0.01:
							fails.append("THE DRESS STAYED BEHIND: plinth %.2f -> %.2f (wanted +1)" % [plx0, pl.position.x])

		for f in ["_trial_db_control.json", "_trial_db_overrides.json", "_trial_db_hand.json"]:
			DirAccess.remove_absolute("res://ada_run/" + f)

	# RESTORE the map byte-for-byte (retry: an open editor's rescans hold files)
	var rf: FileAccess = null
	for attempt in range(20):
		rf = FileAccess.open(MAP, FileAccess.WRITE)
		if rf != null:
			break
		OS.delay_msec(100)
	if rf == null:
		fails.append("RESTORE FAILED — map left dirty, git checkout it")
	else:
		rf.store_string(original)
		rf.close()

	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(PackedStringArray(fails)))
	out.close()
	print("DRESS BUNDLE: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(PackedStringArray(fails))))
	quit(0 if fails.is_empty() else 1)
