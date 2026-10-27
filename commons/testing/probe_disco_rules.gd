extends SceneTree
## disco_controls' RULES button, headless, in a room of its own (a floor and the console):
##   at load the floor shows the console's CHECKER, tile for tile;
##   RULES changes the floor; PATTERN puts the console's pattern back;
##   each RULES pattern's states for beats 0..24 are written to ada_run/address_rules/disco_gd.json
##   for tools/address_rules_crosscheck.py --disco to compare with the lab's disco floor.
## Mode (mono / colour) from the user args, default mono. Exit 1 when a check fails.

const BEATS := 25


func _init() -> void:
	var mode := "colour" if "colour" in OS.get_cmdline_user_args() else "mono"
	var report := {"mode": mode, "checks": [], "pass": true, "patterns": []}
	var room := Node3D.new()
	room.name = "Room"
	root.add_child(room)
	var scene: Node3D = load("res://commons/context/discofloor/standalone_disco_floor.tscn").instantiate()
	room.add_child(scene)
	var console: Node3D = load("res://commons/artifacts/regularity/disco_controls.tscn").instantiate()
	console.set_meta("config_mode", mode)
	room.add_child(console)
	for i in 4:
		await process_frame
	console.set("running", false)
	# the floor script sits below the scene's root: use the floor the console found, as it does
	var floor_node: Node3D = console.get("floor_node")
	_check(report, "the console found its floor", is_instance_valid(floor_node))
	if not is_instance_valid(floor_node):
		_write(report)
		quit(1)
		return
	var w: int = floor_node.get("grid_width")
	var d: int = floor_node.get("grid_depth")
	report["width"] = w   # the lab's floor is built at the hall floor's real size, read here
	report["depth"] = d
	_check(report, "RULES is off at load", int(console.get("rule_mode")) == -1)
	var at_load: Array = floor_node.get("tile_colors").duplicate()
	var expected: Array = []
	for z in d:
		for x in w:
			expected.append(_floor_colour(floor_node, console.call("tile_colour", x, z, w, d)))
	_check(report, "at load the floor shows the console's own pattern, tile for tile", at_load == expected)
	console.call("cycle_rules")
	_check(report, "RULES changes the floor", floor_node.get("tile_colors") != at_load)
	# without #automata:on, RULES offers only the address rules (the automata belong to a later sequence)
	var visited: Array = [int(console.get("rule_mode"))]
	for k in 6:
		console.call("cycle_rules")
		visited.append(int(console.get("rule_mode")))
	_check(report, "without #automata:on RULES offers only the three address rules (visited %s)" % str(visited), visited.all(func(i): return i < 3) and visited.has(0) and visited.has(1) and visited.has(2))
	console.call("apply_grid_config", {"automata": "on"})
	var patterns: Array = console.get_script().get_script_constant_map()["RULE_PATTERNS"]   # a constant is not a property
	for i in patterns.size():
		while int(console.get("rule_mode")) != i:
			console.call("cycle_rules")
		var beats: Array = []
		for t in BEATS:
			console.set("phase", t)
			var rows: Array = []
			for z in d:
				var row: Array = []
				for x in w:
					row.append(int(console.call("rule_state", x, z, w, d)))
				rows.append(row)
			beats.append(rows)
		report["patterns"].append({"name": patterns[i][0], "beats": beats})
	console.set("phase", 0)
	console.call("cycle_pattern")
	_check(report, "PATTERN returns to the console's pattern and the floor it painted", int(console.get("rule_mode")) == -1 and floor_node.get("tile_colors") == at_load)
	_write(report)
	quit(0 if report["pass"] else 1)


func _write(report: Dictionary) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path("res://ada_run/address_rules/disco_gd.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report))
	f.close()


## What the floor stores for a colour: the black-and-white floor keeps the luminance as grey.
func _floor_colour(floor_node: Node3D, c: Color) -> Color:
	if floor_node.get("monochrome"):
		var g := c.get_luminance()
		return Color(g, g, g, c.a)
	return c


func _check(report: Dictionary, what: String, ok: bool) -> void:
	report["checks"].append({"check": what, "pass": ok})
	if not ok:
		report["pass"] = false
