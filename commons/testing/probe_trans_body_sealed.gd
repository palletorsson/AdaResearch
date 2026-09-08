extends SceneTree

## IS THERE A WAY ROUND ANY OF THE THREE THRESHOLDS?
##
## 2026-09-08. Trans_Body cuts three throats and stands one artifact in each: a
## wall of slats that opens where you are, a lattice you cut a tunnel through, a
## field of blocks that shrinks as you come. Each throat is meant to be sealed by
## the thing standing in it, so that meeting the artifact is the only way past.
##
## THE SILENT FAILURE THIS ROOM HAS IS A GAP. Every artifact is narrower than some
## number of whole cells, the grid seats it at a cell centre, and if the arithmetic
## is out by twenty centimetres on either side the visitor simply walks round the
## wall and the room becomes a corridor with sculpture in it. Nothing errors.
## The pathfinder cannot see it either: it reads the map's structure layer, where
## the throat is plain floor, and knows nothing about artifact colliders. So a
## green pathfinder run is not evidence about this room, and this probe is.
##
## IT ASKS THE PHYSICS WORLD, NOT THE ARITHMETIC. A sphere of shoulder radius is
## stepped across each throat at standing height, in the artifact's own z, and
## every position must hit something. A run of free positions wider than a pair of
## shoulders is a way round, and the probe prints where it is in map cells so it
## can be closed.
##
## THE NEGATIVE IS BUILT IN: the same sweep is run one row BEFORE each artifact,
## where the throat is open floor and must be almost entirely free. Without it a
## probe that always found the world solid — a bad shape, a wrong mask, a query
## against the wrong space — would report a beautifully sealed room.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_trans_body_sealed.gd

const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const MAP := "Trans_Body"
const REPORT := "res://ada_run/trans_body_sealed_probe.txt"

## Half a pair of shoulders. A gap narrower than SHOULDER_M is not a way past.
const SHOULDER_M := 0.52
const PROBE_R := SHOULDER_M * 0.5
## Where a standing body's middle is, above the floor.
const CHEST_Y := 0.95
const STEP_M := 0.05

## row, and the label. The row is the artifact's own cell row in map_data.json.
const GATES := [
	{"row": 6, "open_row": 3, "what": "approach_wall"},
	{"row": 12, "open_row": 9, "what": "carve_grid"},
	{"row": 18, "open_row": 15, "what": "approach_scale"},
]

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if change_scene_to_file(CATALOG) != OK:
		_check(false, "the catalog loads", "catalog scene would not load")
		_finish()
		return
	await process_frame
	await process_frame
	var ok: bool = bool(current_scene.call("load_map_fresh", MAP))
	_check(ok, "%s loads" % MAP, "%s did not load" % MAP)
	if not ok:
		_finish()
		return
	# the artifacts build procedurally and the lattice seats several hundred shape
	# owners; give the whole room time to become solid before asking it anything
	for i in range(240):
		await process_frame

	var space: PhysicsDirectSpaceState3D = _space()
	if space == null:
		_check(false, "a physics space to ask", "no 3D space state — the query below would answer nothing")
		_finish()
		return

	# The grid seats cell (row, col) at world (col * cube, y, row * cube) with
	# cube_size 1.0. Read it rather than assume it: a map is authored in cells and
	# this probe is the only thing here that has to speak metres.
	var cube: float = _cube_size()
	_say("cube_size %.2f m, probe sphere r=%.2f m at y=%.2f" % [cube, PROBE_R, CHEST_Y])

	for g in GATES:
		var what: String = str(g["what"])
		# THE NEGATIVE FIRST, so a query that can only ever say "solid" is caught
		# before it is trusted to say "sealed".
		var open_free: float = _widest_free(space, float(g["open_row"]) * cube, cube)
		_check(open_free > SHOULDER_M,
			"  open floor before %-14s widest free run %.2f m" % [what, open_free],
			"the open floor before %s reads as solid — the sweep is measuring nothing" % what)
		var gate_free: float = _widest_free(space, float(g["row"]) * cube, cube)
		_check(gate_free < SHOULDER_M,
			"  %-24s widest free run %.2f m (must be < %.2f)" % [what, gate_free, SHOULDER_M],
			"there is a %.2f m way round %s — the throat is wider than the artifact" % [gate_free, what])

	_finish()


## The widest continuous run of positions across the hall, at this z, where a
## shoulder-wide body meets nothing. Returned in metres.
func _widest_free(space: PhysicsDirectSpaceState3D, z: float, cube: float) -> float:
	var shape := SphereShape3D.new()
	shape.radius = PROBE_R
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_bodies = true
	q.collide_with_areas = false
	# Everything solid in this room is on layer 1 — the grid's floors and walls,
	# and all three artifacts' own bodies, which say so in their headers.
	q.collision_mask = 0xFFFFFFFF
	var best := 0.0
	var run := 0.0
	var x: float = 0.0
	var x_end: float = 11.0 * cube
	while x <= x_end:
		q.transform = Transform3D(Basis.IDENTITY, Vector3(x, CHEST_Y, z))
		if space.intersect_shape(q, 1).is_empty():
			run += STEP_M
			best = maxf(best, run)
		else:
			run = 0.0
		x += STEP_M
	return best


func _space() -> PhysicsDirectSpaceState3D:
	var w: World3D = root.world_3d
	return w.direct_space_state if w != null else null


func _cube_size() -> float:
	var gs: Node = _find_grid(root)
	if gs != null and "cube_size" in gs:
		return float(gs.get("cube_size"))
	return 1.0


func _find_grid(n: Node) -> Node:
	if "cube_size" in n and "gutter" in n:
		return n
	for c in n.get_children():
		var f: Node = _find_grid(c)
		if f != null:
			return f
	return null


func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
