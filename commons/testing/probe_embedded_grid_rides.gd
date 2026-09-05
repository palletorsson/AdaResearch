extends SceneTree

## THE EMBEDDED GRID CARRIES (2026-09-05, Palle: "improve the utilities so they
## work similarly as in the grid"). Trans_Translation, Trans_AxisDecomposition
## and Trans_Rotation embed the REAL GridSystem in their museum hall
## (map_info.museum.simulation.grid). The grid's own transport cubes watch
## layer 20, the grid's player layer, while the museum's walker stands on layer
## 1 - so the ferry ran with nobody aboard - and their spans were never told to
## the museum's walk map. UtilityRegistry.carry_embedded_rides is the museum's
## remedy (_sim_grid_carry calls it); this probe holds it against a real grid
## of Trans_Translation without booting a museum (a museum boot writes the
## ada_run files a live session reads).
##
##   1  the real grid builds Trans_Translation with one transport cube per tc cell
##   2  as shipped, none of them sees layer 1 - the walker's layer
##   3  after carry_embedded_rides every one does, and the ride cells it reports
##      are exactly each cube's cell plus its travel, in the frame it was given
##   4  a second call widens nothing more and reports the same cells
##
## Run:  godot --path . --xr-mode off --no-window --script res://commons/testing/probe_embedded_grid_rides.gd

const MAP := "Trans_Translation"
const ZBASE := 100
const OFF := Vector3(0.0, -0.5, 3.0)   # the museum stands its grid at (0, -0.5, VESTIBULE_H); three rows here

var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("  FAIL ", what)


func _cubes(gs: Node) -> Array:
	var out: Array = []
	for n in gs.find_children("*", "Node3D", true, false):
		if n.get_script() != null and str((n.get_script() as Script).resource_path).to_lower().contains("transport_cube"):
			out.append(n)
	return out


func _sees_layer1(cube: Node) -> bool:
	for a_v in cube.find_children("*", "Area3D", true, false):
		if ((a_v as Area3D).collision_mask & 1) != 0:
			return true
	return false


## the map's tc cells: [ {x, z, token} ]
func _tc_cells(map_name: String) -> Array:
	var out: Array = []
	var doc = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_name))
	if not (doc is Dictionary):
		return out
	var layers: Dictionary = (doc as Dictionary).get("layers", doc)
	var utils: Array = layers.get("utilities", [])
	for z in range(utils.size()):
		var row: Array = utils[z]
		for x in range(row.size()):
			var c := str(row[x]).strip_edges()
			if c == "tc" or c.begins_with("tc:"):
				out.append({"x": x, "z": z, "token": c.split("#")[0]})
	return out


func _run() -> void:
	print("[probe_embedded_grid_rides]")
	var cells := _tc_cells(MAP)
	print("     %s places %d transport cube(s): %s" % [MAP, cells.size(), str(cells)])

	# the museum's way of standing a real grid inside a hall
	var seg := Node3D.new()
	seg.name = "Seg"
	root.add_child(seg)
	var gs: Node3D = (load("res://commons/grid/grid_system.tscn") as PackedScene).instantiate() as Node3D
	gs.name = "SimGrid_" + MAP
	gs.set("map_name", MAP)
	gs.set("bare_world", true)
	gs.set("skip_player_spawn", true)
	gs.position = OFF
	seg.add_child(gs)
	var waited := 0
	while waited < 600 and _cubes(gs).size() < cells.size():
		await process_frame
		waited += 1
	for i in range(30):
		await process_frame
	var cubes := _cubes(gs)
	_check(cubes.size() == cells.size() and cells.size() > 0, "1  the real grid built %d transport cube(s) for %d cells after %d frames" % [cubes.size(), cells.size(), waited + 30])

	# 2. as shipped: blind to the walker
	var blind := 0
	for c in cubes:
		if not _sees_layer1(c):
			blind += 1
	_check(blind == cubes.size(), "2  as shipped, %d of %d cubes cannot see layer 1" % [blind, cubes.size()])

	# 3. the remedy, and what it reports
	var r: Dictionary = UtilityRegistry.carry_embedded_rides(gs, seg, ZBASE)
	var seeing := 0
	for c in cubes:
		if _sees_layer1(c):
			seeing += 1
	_check(int(r["cubes"]) == cubes.size() and int(r["carried"]) == cubes.size() and seeing == cubes.size(),
		"3  carry_embedded_rides widened %d of %d; %d now see the walker" % [int(r["carried"]), cubes.size(), seeing])
	# expected: each cell's start in the segment frame plus its travel, per the shared rule
	var want := {}
	for cell in cells:
		var fresh: Node3D = (load(UtilityRegistry.get_utility_scene_path("tc")) as PackedScene).instantiate() as Node3D
		UtilityRegistry.apply_params(fresh, "tc", UtilityRegistry.parse_utility_cell(cell["token"]).get("parameters", []))
		var start := Vector2i(int(cell["x"]) + int(floor(OFF.x)), ZBASE + int(cell["z"]) + int(floor(OFF.z)))
		for c_v in UtilityRegistry.transport_span(fresh, start):
			want[c_v] = true
		fresh.free()
	var got := {}
	for c_v in (r["cells"] as Array):
		got[c_v] = true
	var missing: Array = []
	var extra: Array = []
	for k in want.keys():
		if not got.has(k):
			missing.append(k)
	for k in got.keys():
		if not want.has(k):
			extra.append(k)
	_check(missing.is_empty() and extra.is_empty() and got.size() > cells.size(),
		"3  the ride cells are each cube's cell plus its travel: %d cells (missing %s, extra %s)" % [got.size(), str(missing), str(extra)])

	# 4. idempotent
	var r2: Dictionary = UtilityRegistry.carry_embedded_rides(gs, seg, ZBASE)
	_check(int(r2["carried"]) == 0 and (r2["cells"] as Array).size() == (r["cells"] as Array).size(),
		"4  a second call widens nothing more and reports the same %d cells" % (r2["cells"] as Array).size())

	print("[probe_embedded_grid_rides] %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)
