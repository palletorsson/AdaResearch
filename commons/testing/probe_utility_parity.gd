extends SceneTree

## ONE RULE, ONE DOOR - THE GATE (2026-09-05, Palle: "can we either improve the
## utilities so they work similarly as in the grid, or should we change them to
## be artifacts?"). The grid read rc/sc/br/jp cells in GridUtilitiesComponent
## and the endless museum read them again with a copy of its own; a second
## implementation of one rule drifts. Both call UtilityRegistry.apply_params
## now. This probe holds the GRID's old reading as the reference and asks the
## shared rule the same questions, for every distinct form in the corpus:
##
##   1  the grid's old branches, restated, agree with the shared apply on every
##      corpus form and on the documented forms nobody has placed yet - except
##      rc:continuous, where the old grid read the word as 0 degrees and the
##      shared rule follows the registry's grammar (recorded, on purpose)
##   2  the OLD museum copy disagreed, and the probe says where; it must find
##      real disagreements in the corpus or it is not measuring the drift
##   3  a rotation cube and a scale cube configured through the shared apply
##      run in the tree and do what the parameters asked
##   4  transport_span reads a configured cube's travel as cells
##   5  LIVE MAP LOAD: Trans_Introduction in the grid, through the catalog, and
##      its own rc / sc / tc bodies carry what their cells say
##
## Run:  godot --path . --xr-mode off --no-window --script res://commons/testing/probe_utility_parity.gd

const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const LIVE_MAP := "Trans_Introduction"
const CTX := {"cube_size": 1.0, "gutter": 0.0, "landing_y": 2.0}

## Every distinct rc / sc / br / jp form standing in commons/maps on 2026-09-05,
## with its count, plus the three most-placed tc forms and the documented forms
## the corpus does not use yet (count 0).
const CORPUS := [
	["rc:90:y:3:-0.6", 2], ["rc:90:y:4:-0.6", 1], ["rc:continuous:x:30", 0], ["rc:45", 0], ["rc:30:z", 0], ["rc:45:foo", 0],
	["sc:3:-0.5:1:0", 2], ["sc:3:-0.5:1:-1", 1], ["sc:3", 0], ["sc:2:1", 0],
	["br:z:2", 9], ["br:x:6", 4], ["br:5:x", 3], ["br:-x:2", 2], ["br:x:2", 2], ["br:3:z", 2],
	["br:z:3", 1], ["br:z:7", 1], ["br:z:5", 1], ["br:x:7", 1], ["br:x:5", 1], ["br:-z", 0], ["br:z", 0],
	["jp:17:11:8", 2], ["jp:18:16:10", 1], ["jp:6:28:12", 1], ["jp:17:7:10", 1], ["jp:18:14:10", 1],
	["jp:17:3:8", 1], ["jp:4:12:10", 1], ["jp:10:10:8", 1], ["jp:2:2:8", 1], ["jp:6:23:6", 1], ["jp:6:20:6", 1], ["jp:3:4", 0],
	["tc:1:auto:auto", 425], ["tc:3:y", 11], ["tc:4:z:auto", 1],
]

var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("  FAIL ", what)


func _params(token: String) -> Array:
	return UtilityRegistry.parse_utility_cell(token).get("parameters", [])


func _code(token: String) -> String:
	return String(UtilityRegistry.parse_utility_cell(token).get("type", ""))


func _fresh(code: String) -> Node3D:
	var path: String = UtilityRegistry.get_utility_scene_path(code)
	var scene: PackedScene = load(path)
	return scene.instantiate() as Node3D if scene else null


# ---- THE REFERENCE: GridUtilitiesComponent's branches as they stood on 2026-09-05 ----

func _grid_axis(word: String) -> Vector3:
	var axis := Vector3.UP
	match word.to_lower():
		"x": axis = Vector3.RIGHT
		"y": axis = Vector3.UP
		"z": axis = Vector3.BACK
		"-x": axis = Vector3.LEFT
		"-y": axis = Vector3.DOWN
		"-z": axis = Vector3.FORWARD
	return axis


func grid_old(node: Node3D, code: String, p: Array) -> void:
	match code:
		"tc":
			var tcfg: Dictionary = UtilityRegistry.transport_params(p)
			if bool(tcfg["applied"]):
				node.call("set_transport_parameters", float(tcfg["distance"]), tcfg["direction"])
				if bool(tcfg["auto"]):
					node.call("set_auto_start", true)
		"br":
			if p.size() >= 1:
				var axis: String = String(p[0]).strip_edges().to_lower()
				if not (axis in ["x", "z", "-x", "-z"]):
					axis = "x"
				var length := 4
				if p.size() >= 2 and String(p[1]).is_valid_int():
					length = int(String(p[1]))
				node.call("set_bridge_parameters", length, axis)
		"jp":
			if p.size() >= 2:
				var tx: int = int(String(p[0]))
				var tz: int = int(String(p[1]))
				var arc := 6.0
				if p.size() >= 3 and String(p[2]).is_valid_float():
					arc = float(String(p[2]))
				var ts: float = float(CTX["cube_size"]) + float(CTX["gutter"])
				node.call("apply_grid_config", {"target_x": tx, "target_z": tz, "arc_height": arc})
				node.set("target_world_pos", Vector3(tx * ts + ts * 0.5, float(CTX["landing_y"]), tz * ts + ts * 0.5))
				node.call("set_grid_spacing", float(CTX["cube_size"]), float(CTX["gutter"]))
		"rc":
			if p.size() >= 1:
				var angle: float = float(String(p[0]))
				var axis := Vector3.UP
				var pause := 4.0
				var y_off := 0.0
				if p.size() >= 2:
					axis = _grid_axis(String(p[1]))
				if p.size() >= 3:
					pause = float(String(p[2]))
				if p.size() >= 4:
					y_off = float(String(p[3]))
				node.call("set_step_pause_mode", angle, axis, pause)
				node.set("y_offset", y_off)
		"sc":
			if p.size() >= 1:
				var mx: float = float(String(p[0]))
				var mn := 0.5
				var off_x := 1.5
				var y_off := 0.0
				if p.size() >= 2:
					mn = float(String(p[1]))
				if p.size() >= 3:
					off_x = float(String(p[2]))
				if p.size() >= 4:
					y_off = float(String(p[3]))
				node.call("set_scale_range", mn, mx)
				node.call("set_offset", Vector3(off_x, 0, 0))
				node.set("y_offset", y_off)


# ---- THE OLD MUSEUM COPY, kept only so the probe can prove it differed ----

func _museum_axis(a: String) -> Vector3:
	match a.to_lower():
		"x": return Vector3.RIGHT
		"-x": return Vector3.LEFT
		"y": return Vector3.UP
		"-y": return Vector3.DOWN
		"-z": return Vector3.FORWARD
		_: return Vector3.BACK


func museum_old(node: Node3D, code: String, p: Array) -> void:
	match code:
		"tc":
			var tcfg: Dictionary = UtilityRegistry.transport_params(p)
			if bool(tcfg["applied"]):
				node.set("move_distance", float(tcfg["distance"]))
				node.set("move_direction", tcfg["direction"])
				node.set("auto_start", bool(tcfg["auto"]))
		"br":
			var axis2: String = String(p[0]) if p.size() > 0 else "z"
			node.set("bridge_axis", axis2.trim_prefix("-"))
			if p.size() > 1 and String(p[1]).is_valid_int():
				node.set("bridge_length", int(String(p[1])))
		"jp":
			if p.size() > 1:
				node.set("target_x", int(String(p[0])))      # no such property: a silent no-op
				node.set("target_z", int(String(p[1])))
			if p.size() > 2 and String(p[2]).is_valid_float():
				node.set("arc_height", float(String(p[2])))
		"rc":
			if p.size() > 0 and String(p[0]) == "continuous":
				node.set("mode", 1)
				if p.size() > 1:
					node.set("continuous_axis", _museum_axis(String(p[1])))
				if p.size() > 2 and String(p[2]).is_valid_float():
					node.set("continuous_speed", float(String(p[2])))
			elif p.size() > 0 and String(p[0]).is_valid_float():
				node.set("rotation_angle", float(String(p[0])))
				if p.size() > 1:
					node.set("rotation_axis", _museum_axis(String(p[1])))
				if p.size() > 2 and String(p[2]).is_valid_float():
					node.set("pause_duration", float(String(p[2])))
				if p.size() > 3 and String(p[3]).is_valid_float():
					node.set("y_offset", float(String(p[3])))
		"sc":
			if p.size() > 0 and String(p[0]).is_valid_float():
				node.set("max_scale", float(String(p[0])))
			if p.size() > 1 and String(p[1]).is_valid_float():
				node.set("min_scale", float(String(p[1])))
			if p.size() > 2 and String(p[2]).is_valid_float():
				node.set("center_offset", Vector3(float(String(p[2])), 0, 0))
			if p.size() > 3 and String(p[3]).is_valid_float():
				node.set("y_offset", float(String(p[3])))


# ---- what a reading leaves on the scene ----

const PROPS := {
	"tc": ["move_distance", "move_direction", "auto_start"],
	"rc": ["mode", "rotation_angle", "rotation_axis", "pause_duration", "y_offset", "continuous_axis", "continuous_speed"],
	"sc": ["min_scale", "max_scale", "center_offset", "y_offset"],
	"br": ["bridge_axis", "bridge_length"],
	"jp": ["target_grid_x", "target_grid_z", "arc_height", "target_world_pos"],
}


func _state(node: Node3D, code: String) -> Dictionary:
	var out := {}
	for k in PROPS[code]:
		out[k] = node.get(k)
	return out


func _same(a: Dictionary, b: Dictionary) -> bool:
	for k in a.keys():
		var x = a[k]
		var y = b[k]
		if x is Vector3 and y is Vector3:
			if not (x as Vector3).is_equal_approx(y):
				return false
		elif (x is float or x is int) and (y is float or y is int):
			if absf(float(x) - float(y)) > 1e-5:
				return false
		elif x != y:
			return false
	return true


func _diff(a: Dictionary, b: Dictionary) -> String:
	var parts: Array[String] = []
	for k in a.keys():
		var x = a[k]
		var y = b[k]
		var eq: bool = ((x is Vector3 and y is Vector3 and (x as Vector3).is_equal_approx(y))
			or ((x is float or x is int) and (y is float or y is int) and absf(float(x) - float(y)) <= 1e-5)
			or x == y)
		if not eq:
			parts.append("%s: grid %s / other %s" % [k, str(x), str(y)])
	return "; ".join(parts)


func _run() -> void:
	print("[probe_utility_parity]")

	# 1 + 2. every form through the three readers
	var forms := 0
	var agree := 0
	var old_diffs := 0
	var old_corpus_diffs := 0
	var departures: Array[String] = []
	for row in CORPUS:
		var token: String = row[0]
		var n: int = row[1]
		var code := _code(token)
		var p := _params(token)
		var na := _fresh(code)
		var nb := _fresh(code)
		var nc := _fresh(code)
		if na == null or nb == null or nc == null:
			_check(false, "scene for %s loads" % code)
			continue
		forms += 1
		grid_old(na, code, p)
		UtilityRegistry.apply_params(nb, code, p, CTX)
		museum_old(nc, code, p)
		var sa := _state(na, code)
		var sb := _state(nb, code)
		var sc := _state(nc, code)
		if token.begins_with("rc:continuous"):
			# the one intended departure: the old grid read "continuous" as 0 degrees
			var old_broken: bool = int(sa["mode"]) == 0 and absf(float(sa["rotation_angle"])) < 1e-6
			var shared_right: bool = int(sb["mode"]) == 1 and absf(float(sb["continuous_speed"]) - 30.0) < 1e-6 \
				and (sb["continuous_axis"] as Vector3).is_equal_approx(Vector3.RIGHT)
			_check(old_broken and shared_right, "%s: the old grid rotated by 0; the shared rule follows the registry's grammar (continuous on x at 30 deg/s)" % token)
			departures.append(token)
		elif _same(sa, sb):
			agree += 1
		else:
			_check(false, "%s: shared apply differs from the grid's old reading - %s" % [token, _diff(sa, sb)])
		if not _same(sa, sc):
			old_diffs += 1
			if n > 0:
				old_corpus_diffs += 1
				print("     drift %-16s x%-3d %s" % [token, n, _diff(sa, sc)])
		na.free()
		nb.free()
		nc.free()
	_check(agree + departures.size() == forms, "1  %d of %d forms: the shared apply is the grid's reading (%d recorded departure)" % [agree, forms, departures.size()])
	_check(old_corpus_diffs >= 3, "2  the OLD museum copy disagreed on %d forms, %d of them placed in the corpus (the negative test needs at least 3)" % [old_diffs, old_corpus_diffs])

	# 3. live bodies through the shared apply
	var rc_node := _fresh("rc")
	var sc_node := _fresh("sc")
	UtilityRegistry.apply_params(rc_node, "rc", _params("rc:90:y:4:-0.6"), CTX)
	UtilityRegistry.apply_params(sc_node, "sc", _params("sc:3:-0.5:1:0"), CTX)
	rc_node.position = Vector3(2, 0, 2)
	sc_node.position = Vector3(6, 0, 2)
	root.add_child(rc_node)
	root.add_child(sc_node)
	for i in range(40):
		await process_frame
	var turned: float = rc_node.rotation_degrees.y
	_check(int(rc_node.get("mode")) == 0 and absf(float(rc_node.get("rotation_angle")) - 90.0) < 1e-6 and absf(float(rc_node.get("pause_duration")) - 4.0) < 1e-6,
		"3  the rotation cube is in step mode, 90 deg, 4 s pause")
	var mn: float = float(sc_node.get("min_scale"))
	var mx: float = float(sc_node.get("max_scale"))
	var cur: float = float(sc_node.get("current_scale"))
	_check(mn > 0.0 and mn < 0.01 and absf(mx - 3.0) < 1e-6, "3  the scale cube's -0.5 minimum was lifted to %.3f by its own setter, max 3" % mn)
	_check(cur >= mn - 1e-6 and cur <= mx + 1e-6, "3  its live scale %.3f stays inside [%.3f, %.1f]" % [cur, mn, mx])
	print("     (rotation cube turned %.1f deg in 40 frames)" % turned)
	rc_node.queue_free()
	sc_node.queue_free()

	# 4. the span
	var span_cases := [["tc:3:z", Vector2i(4, 10), [Vector2i(4, 10), Vector2i(4, 11), Vector2i(4, 12), Vector2i(4, 13)]],
		["tc:2:-x", Vector2i(4, 10), [Vector2i(4, 10), Vector2i(3, 10), Vector2i(2, 10)]],
		["tc:1:auto:auto", Vector2i(4, 10), [Vector2i(4, 10), Vector2i(5, 10)]]]
	for case in span_cases:
		var cube := _fresh("tc")
		UtilityRegistry.apply_params(cube, "tc", _params(case[0]), CTX)
		var got: Array = UtilityRegistry.transport_span(cube, case[1])
		_check(got == case[2], "4  %s from %s spans %s" % [case[0], str(case[1]), str(got)])
		cube.free()

	# 5. the live map: the grid builds Trans_Introduction through the catalog
	var err: int = change_scene_to_file(CATALOG)
	if err != OK:
		_check(false, "5  the catalog scene loads")
		_finish()
		return
	await process_frame
	await process_frame
	var ok: bool = bool(current_scene.call("load_map_fresh", LIVE_MAP))
	_check(ok, "5  load_map_fresh(%s)" % LIVE_MAP)
	for i in range(180):
		await process_frame
	var cells := _map_cells(LIVE_MAP)
	var found := {"rc": [], "sc": [], "tc": []}
	_collect(root, found)
	print("     %s carries rc %d, sc %d, tc %d bodies; its cells: %s" % [LIVE_MAP, found["rc"].size(), found["sc"].size(), found["tc"].size(), str(cells)])
	_check(found["rc"].size() == cells["rc"].size() and found["sc"].size() == cells["sc"].size() and found["tc"].size() == cells["tc"].size(),
		"5  one body per cell for rc, sc and tc")
	for code in ["rc", "sc", "tc"]:
		if found[code].is_empty() or cells[code].is_empty():
			continue
		var node: Node3D = found[code][0]
		var want := _fresh(code)
		UtilityRegistry.apply_params(want, code, _params(cells[code][0]), CTX)
		var live := _state(node, code)
		var ref := _state(want, code)
		if code == "tc":
			# the live cube normalised its direction in _ready; compare what the cell asked for
			live.erase("move_direction")
			ref.erase("move_direction")
			var dirv: Vector3 = node.get("move_direction")
			_check(dirv.is_equal_approx((want.get("move_direction") as Vector3).normalized()), "5  the live tc rides the direction its cell asked (%s)" % str(dirv))
		_check(_same(ref, live), "5  the live %s carries its cell %s: %s" % [code, cells[code][0], str(live)])
		want.free()
	_finish()


func _collect(n: Node, found: Dictionary) -> void:
	var sp := ""
	if n.get_script() != null:
		sp = str((n.get_script() as Script).resource_path).to_lower()
	if sp.ends_with("/rotation_cube.gd"):
		found["rc"].append(n)
	elif sp.ends_with("/scale_cube.gd"):
		found["sc"].append(n)
	elif sp.ends_with("/transport_cube.gd"):
		found["tc"].append(n)
	for c in n.get_children():
		_collect(c, found)


func _map_cells(map_name: String) -> Dictionary:
	var out := {"rc": [], "sc": [], "tc": []}
	var text := FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_name)
	var doc = JSON.parse_string(text)
	if not (doc is Dictionary):
		return out
	var layers: Dictionary = (doc as Dictionary).get("layers", doc)
	for row in layers.get("utilities", []):
		for cell in row:
			var c := str(cell).strip_edges()
			var code := c.split(":")[0]
			if out.has(code):
				out[code].append(c.split("#")[0])
	return out


func _finish() -> void:
	print("[probe_utility_parity] %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)
