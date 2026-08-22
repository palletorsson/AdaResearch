extends SceneTree
## Collections in the Godot map tool, held headless: a run of 3 identical
## tokens folds into ONE master (count 3, two copy boxes as children), any
## member cell selects the master, and a lone token stays single.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_collections.gd

const OUT := "res://ada_run/collections_probe.txt"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var ed: Node3D = (load("res://commons/scenes/map_tool_editor.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(ed)
	await process_frame
	ed.set("_total", 1.0)
	ed.set("_width", 10)
	ed.set("_depth", 10)
	ed.set("_map", {"layers": {"structure": []}})
	# the scene file ships with saved markers from real sessions — clear
	# them so the fold is judged on this probe's grid alone
	for c in [] + ed.get_children():
		if c is Node3D and (c as Node).has_meta("token"):
			c.free()
	await process_frame
	var grid: Array = []
	for z in range(10):
		var row: Array = []
		for x in range(10):
			row.append(" ")
		grid.append(row)
	grid[2][1] = "laser_point"
	grid[2][2] = "laser_point"
	grid[2][3] = "laser_point"
	grid[5][5] = "pick_up_cube"
	# a BOUND SERIES: same base, config differing in exactly one key
	grid[7][1] = "accord_swarm:0#accord:school"
	grid[7][2] = "accord_swarm:0#accord:orb"
	grid[7][3] = "accord_swarm:0#accord:lane"
	# NOT a series: two keys differ — must stay individual
	grid[9][1] = "adder_board:0#workings:trace#extra:a"
	grid[9][2] = "adder_board:0#workings:outcome#extra:b"
	ed.call("_spawn", grid, "interactable", Color(1, 1, 1), null)
	await process_frame
	var masters: Array = []
	for c in ed.get_children():
		if c is Node3D and (c as Node).has_meta("token"):
			masters.append(c)
	# laser master + lone cube + bound accord master + 2 unfoldable adders = 5
	if masters.size() != 5:
		fails.append("expected 5 markers after fold, got %d" % masters.size())
	var bound: Node3D = null
	var adders := 0
	for m in masters:
		if str((m as Node).get_meta("bound_axis", "")) == "accord":
			bound = m
		if str((m as Node).get_meta("token")).begins_with("adder_board"):
			adders += 1
	if bound == null:
		fails.append("no master bound to the accord axis")
	else:
		if int(bound.get_meta("count", 0)) != 3:
			fails.append("bound master count %s, wanted 3" % str(bound.get_meta("count")))
		var vals: Array = bound.get_meta("bound_values", [])
		if str("|".join(PackedStringArray(vals))) != "school|orb|lane":
			fails.append("bound values wrong: %s" % str(vals))
	if adders != 2:
		fails.append("two-key-diff run folded anyway (%d adder markers)" % adders)
	var fam: Node3D = null
	for m in masters:
		if int((m as Node).get_meta("count", 1)) == 3 and str((m as Node).get_meta("token")).begins_with("laser_point"):
			fam = m
	if fam == null:
		fails.append("no marker carries count 3")
	else:
		if str(fam.get_meta("spread", "")) != "x" or int(fam.get_meta("gap", 0)) != 1:
			fails.append("fold meta wrong: spread=%s gap=%s" % [fam.get_meta("spread"), fam.get_meta("gap")])
		var copies := 0
		for c in fam.get_children():
			if str(c.name).begins_with("CollectionCopy"):
				copies += 1
		if copies != 2:
			fails.append("master has %d copy boxes, wanted 2" % copies)
		var hit: Node3D = ed.call("marker_at_cell", 2, 2)
		if hit != fam:
			fails.append("member cell x=2,z=2 did not select the master")
		var hit_end: Node3D = ed.call("marker_at_cell", 3, 2)
		if hit_end != fam:
			fails.append("member cell x=3,z=2 did not select the master")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f.close()
	print("COLLECTIONS: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
