extends SceneTree

## GATE — Randomness_10_PRINT_Algorithm: what the hall's printer and floor actually do.
##
## The chapter is being rewritten around the two works a visitor can use — the printer's
## panel and the floor it prints onto — instead of the upright maze, which a body cannot
## enter. Every claim the new prose makes about them is checked here first, with the
## hall's own configuration:
##   ten_print   #semicolon:on #when_full:scroll #seed:1982 #count:400 #controls:panel #channel:hall
##   structure   #form:floor #rows:7 #channel:hall #plate:none
##
##   A  the link         -> the floor finds the printer on channel "hall" and fills
##   B  the screen laid  -> every floor cell matches the screen cell it came from
##      down
##   C  the line         -> the console reads the book's line: 205.5, with the semicolon
##   D  SEMICOLON off    -> the ";" leaves the line and the floor collapses to ONE column
##   E  SEMICOLON on     -> the plane comes back
##   F  BIAS             -> the constant in the line moves, and the next characters lean
##   G  it breathes      -> this hall's default coin is NOT fair: forward-heavy, then not
##   H  the next tile    -> the bright tile stands where the next character will land
##   I  no collider      -> the ridges do not stop a body; the floor is a venue
##   J  the upright maze -> no collider anywhere, walls in the Y-Z plane: a body cannot enter

const PRINTER := "res://algorithms/randomness/ten_print/ten_print.tscn"
const FLOOR := "res://commons/artifacts/ten_print_structure/ten_print_structure.tscn"
const MAZE := "res://algorithms/randomness/generative/tenprintantmaze/ten_print_maze_3d.tscn"

var _fails: Array = []
var _finished: bool = false
var _checks: int = 0


func _initialize() -> void:
	await _run()
	if not _finished:
		_fails.append("the probe aborted before the last case — the checks after it never ran")
	if _fails.is_empty():
		print("\nprobe_ten_print_hall: ALL %d CHECKS PASS (cases A-J)" % _checks)
		quit(0)
	else:
		print("\nprobe_ten_print_hall: %d FAILED" % _fails.size())
		for f in _fails:
			print("  FAIL  %s" % f)
		quit(1)


func _check(label: String, ok: bool, detail: String = "") -> void:
	_checks += 1
	var line: String = "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	if ok:
		print("  ok    %s" % line)
	else:
		_fails.append(line)
		print("  FAIL  %s" % line)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _columns(cells: Dictionary) -> Dictionary:
	var cols: Dictionary = {}
	for c in cells.keys():
		cols[(c as Vector2i).x] = true
	return cols


func _forward_fraction(printer: Node, from_i: int, to_i: int) -> float:
	var fwd: int = 0
	for i in range(from_i, to_i):
		if printer.coin_is_forward(i):
			fwd += 1
	return float(fwd) / float(to_i - from_i)


func _run() -> void:
	print("probe_ten_print_hall")

	# One hall: em_map meta makes this node the boundary of the floor's scoped search.
	var hall := Node3D.new()
	hall.name = "Randomness_10_PRINT_Algorithm"
	hall.set_meta("em_map", "Randomness_10_PRINT_Algorithm")
	root.add_child(hall)

	var printer: Node3D = load(PRINTER).instantiate()
	printer.apply_grid_config({"semicolon": "on", "when_full": "scroll", "seed": 1982,
		"count": 400, "controls": "panel", "channel": "hall"})
	hall.add_child(printer)

	var floor_: Node3D = load(FLOOR).instantiate()
	floor_.apply_grid_config({"form": "floor", "rows": 7, "channel": "hall", "plate": "none"})
	hall.add_child(floor_)
	await _frames(20)

	# --- A ---
	var cells: Dictionary = floor_.get_cells()
	var screen: Dictionary = printer.get_field()
	_check("A the floor links to the printer and fills", cells.size() > 0 and screen.size() > 0,
		"%d floor cells from a %d-cell screen" % [cells.size(), screen.size()])

	# --- B: the screen laid down ---
	var off: int = floor_.row_offset()
	var mismatch: int = 0
	for c in cells.keys():
		var sc := Vector2i((c as Vector2i).x, (c as Vector2i).y + off)
		if not screen.has(sc) or bool(screen[sc]) != bool(cells[c]):
			mismatch += 1
	_check("B every floor ridge matches the character it came from", mismatch == 0,
		"%d of %d cells disagree (window offset %d rows)" % [mismatch, cells.size(), off])

	# --- C: the book's line ---
	var line0: String = printer.program_line()
	_check("C the console reads the book's line", line0 == "10 PRINT CHR$(205.5+RND(1)); : GOTO 10",
		line0)

	# --- D: take the semicolon away ---
	var cols_before: int = _columns(cells).size()
	printer.press_control("semicolon")
	await _frames(4)
	var line_off: String = printer.program_line()
	var cells_off: Dictionary = floor_.get_cells()
	var cols_off: Dictionary = _columns(cells_off)
	_check("D SEMICOLON removes the ; from the line", not line_off.contains(";"), line_off)
	_check("D and the floor collapses to a single file",
		cols_off.size() == 1 and cols_off.has(0) and cells_off.size() > 1,
		"%d columns before, %d after; %d ridges now, all in column %s" %
			[cols_before, cols_off.size(), cells_off.size(), str(cols_off.keys())])

	# --- E: and back ---
	printer.press_control("semicolon")
	await _frames(4)
	var cols_on: int = _columns(floor_.get_cells()).size()
	_check("E SEMICOLON again brings the plane back", cols_on > 1,
		"%d columns" % cols_on)

	# --- F: bias. From breathing the first press starts at 0.5; four more reach 0.9.
	for i in 4:
		printer.press_control("bias_plus")
	var line_hi: String = printer.program_line()
	var start_i: int = printer.draw_count
	for i in 200:
		printer.step_once()
	var hi: float = _forward_fraction(printer, start_i, start_i + 200)
	_check("F BIAS moves the famous constant", line_hi.contains("CHR$(205.1+RND(1))"), line_hi)
	for i in 8:
		printer.press_control("bias_minus")
	var line_lo: String = printer.program_line()
	var start_j: int = printer.draw_count
	for i in 200:
		printer.step_once()
	var lo: float = _forward_fraction(printer, start_j, start_j + 200)
	_check("F and the field leans with it", hi > 0.75 and lo < 0.25,
		"bias 0.9 -> %.2f forward; bias 0.1 (%s) -> %.2f forward" % [hi, line_lo, lo])

	# --- G: the hall's default coin breathes. Fresh printer, same seed, no bias key.
	var fresh: Node3D = load(PRINTER).instantiate()
	fresh.apply_grid_config({"seed": 1982})
	hall.add_child(fresh)
	await _frames(2)
	var early: float = _forward_fraction(fresh, 0, 270)
	var late: float = _forward_fraction(fresh, 270, 400)
	_check("G the default coin is not fair: it breathes",
		early > 0.55 and late < 0.45,
		"characters 0-269: %.2f forward; 270-399: %.2f forward; threshold %.2f at 135, %.2f at 405" %
			[early, late, fresh.threshold_at(135), fresh.threshold_at(405)])
	fresh.queue_free()

	# --- H: the next tile ---
	var marker: MeshInstance3D = floor_.marker_node()
	var next_cell: Vector2i = printer.get_next_cell()
	_check("H a bright tile marks where the next character lands",
		marker != null and marker.visible,
		"next cell on screen %s; marker %s" % [str(next_cell), "visible" if marker and marker.visible else "missing"])

	# --- I: the floor is a venue ---
	var body: StaticBody3D = floor_.solid_body()
	var shapes: int = floor_.find_children("*", "CollisionShape3D", true, false).size()
	_check("I the ridges do not stop a body", body == null and shapes == 0,
		"solid body %s, %d collision shapes" % ["none" if body == null else "present", shapes])

	# --- J: the upright maze ---
	var maze: Node3D = load(MAZE).instantiate()
	hall.add_child(maze)
	await _frames(6)
	var maze_shapes: int = maze.find_children("*", "CollisionShape3D", true, false).size()
	var maze_bodies: int = maze.find_children("*", "StaticBody3D", true, false).size()
	# Orientation, measured rather than asserted: merge every mesh AABB in the maze and
	# compare its extents. An earlier version of this check matched no nodes by name and
	# passed on an empty set. This one fails if it measures nothing.
	var box := AABB()
	var meshes: int = 0
	for n in maze.find_children("*", "MeshInstance3D", true, false):
		if n.mesh == null or not n.is_visible_in_tree():
			continue
		var b: AABB = (maze.global_transform.affine_inverse() * n.global_transform) * n.mesh.get_aabb()
		box = b if meshes == 0 else box.merge(b)
		meshes += 1
	_check("J the upright maze has no collider a body could meet",
		maze_shapes == 0 and maze_bodies == 0,
		"%d collision shapes, %d static bodies" % [maze_shapes, maze_bodies])
	_check("J and it stands upright: thin in x, broad in y and z",
		meshes > 0 and box.size.x < 0.25 * minf(box.size.y, box.size.z),
		"%d meshes; extent x %.2f m, y %.2f m, z %.2f m" % [meshes, box.size.x, box.size.y, box.size.z])

	hall.queue_free()
	await _frames(2)
	_finished = true
