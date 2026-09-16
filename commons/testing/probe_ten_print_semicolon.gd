extends SceneTree
## probe_ten_print_semicolon — ten_print's semicolon, when_full, seed and count exports.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_ten_print_semicolon.gd
##
## What it proves, reading the real CSG lines back out of MazeLines (position -> cell,
## rotation -> character) and comparing ACROSS instances, never one instance's own
## bookkeeping against itself:
##   1. one seed prints one stream whatever the layout: semicolon on/off x when_full
##      clear/scroll draw the identical 437 characters, and the stream is a pure function
##      of (seed, index) — a fresh instance that has drawn nothing predicts it;
##   2. semicolon off puts every character in column 0, and its column IS the wrapped
##      field's row turned on end; semicolon on fills row-major;
##   3. when_full clear wipes and the wipe tick prints nothing; when_full scroll keeps the
##      newest rows and drops the oldest, and nothing is ever wiped;
##   4. a default instance (no config) is the artifact as it was: unseeded global randf()
##      against probability, one call per character, row-major 20 x 20, the legacy
##      cell positions and +-45 degree rotations, the wipe, and the live _process tick;
##   5. the config lanes take: before the tree with token strings (the museum), after
##      _ready (the grid's deferred call), an empty config changes nothing, and the DNA
##      fixture (seed 41, count 400, when_full scroll) leaves a full field / full column.
##
## Stepping is driven by calling generate_maze_step() with _process switched off, because
## the live tick rate breathes with wall-clock time and would make the counts a race.

const SCENE := "res://algorithms/randomness/ten_print/ten_print.tscn"
const GRID := 20
const CELL := 0.4

## run() is a coroutine: a runtime error inside it stops it before quit(), and the tree
## would idle until the watchdog kills it with no RESULT line. The timeout turns that
## into a printed result and exit 2, so a crash does not read as a hang.
const TIMEOUT_S := 120.0

var checks := 0
var failures: Array[String] = []
var world: Node3D
var _done := false

func _initialize() -> void:
	create_timer(TIMEOUT_S).timeout.connect(_on_timeout)
	call_deferred("run")

func _on_timeout() -> void:
	if _done:
		return
	_done = true
	print("FAIL probe timed out after %d s: run() stopped before it finished" % int(TIMEOUT_S))
	print("TEN_PRINT_SEMICOLON_RESULT " + JSON.stringify({"checks": checks, "failures": failures, "timeout": true}))
	quit(2)

func check(ok: bool, message: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures.append(message)

## Instantiate the real scene. `props` go through set() before the tree (the sweep's lane);
## `config` goes through apply_grid_config either before the tree (museum) or after
## _ready (the grid defers the call). _process is switched off straight after _ready.
func make(props: Dictionary, config: Dictionary = {}, config_before_tree: bool = true):
	var packed: PackedScene = load(SCENE)
	var inst = packed.instantiate()
	for k in props.keys():
		inst.set(k, props[k])
	if config_before_tree and not config.is_empty():
		inst.apply_grid_config(config)
	world.add_child(inst)
	inst.set_process(false)
	if not config_before_tree and not config.is_empty():
		inst.apply_grid_config(config)
	return inst

func draw_to(inst, n: int) -> void:
	var guard: int = n * 3 + 50
	while int(inst.draw_count) < n and guard > 0:
		inst.generate_maze_step()
		guard -= 1

## Every live line in MazeLines as {Vector2i(col, row): "/" or "\"}, from its transform.
func read_cells(inst) -> Dictionary:
	var cells: Dictionary = {}
	for c in inst.get_node("MazeLines").get_children():
		if c.is_queued_for_deletion():
			continue
		var n3: Node3D = c as Node3D
		var col: int = int(round((n3.position.x + 4.0) / CELL))
		var row: int = int(round((4.0 - n3.position.y) / CELL))
		cells[Vector2i(col, row)] = "/" if n3.rotation_degrees.z > 0.0 else "\\"
	return cells

func live_count(inst) -> int:
	var n := 0
	for c in inst.get_node("MazeLines").get_children():
		if not c.is_queued_for_deletion():
			n += 1
	return n

func stream_text(inst, upto: int) -> String:
	var bytes: PackedByteArray = inst.stream_log
	var s := ""
	for i in range(mini(upto, bytes.size())):
		s += "/" if bytes[i] == 47 else "\\"
	return s

func all_in_column_zero(cells: Dictionary) -> bool:
	for key in cells.keys():
		var k: Vector2i = key
		if k.x != 0:
			return false
	return true

## The column cells (0, r) for r in [0, rows) read top to bottom.
func column_text(cells: Dictionary, rows: int) -> String:
	var s := ""
	for r in range(rows):
		s += str(cells.get(Vector2i(0, r), "?"))
	return s

## The row cells (c, row) for c in [0, GRID) read left to right.
func row_text(cells: Dictionary, row: int) -> String:
	var s := ""
	for c in range(GRID):
		s += str(cells.get(Vector2i(c, row), "?"))
	return s

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var n_draws: int = 437

	# ---------------------------------------------------------------- 1-3: four layouts
	print("-- four layouts, seed 41")
	var on_clear = make({"seed": 41, "semicolon": "on", "when_full": "clear"})
	var off_clear = make({"seed": 41, "semicolon": "off", "when_full": "clear"})
	var on_scroll = make({"seed": 41, "semicolon": "on", "when_full": "scroll"})
	var off_scroll = make({"seed": 41, "semicolon": "off", "when_full": "scroll"})
	check(int(on_clear.seed) == 41 and str(off_clear.semicolon) == "off" \
			and str(on_scroll.when_full) == "scroll" and str(off_scroll.semicolon) == "off",
		"typed exports took their values (read back after set)")
	var four: Array = [on_clear, off_clear, on_scroll, off_scroll]
	for inst in four:
		check(live_count(inst) == 0 and int(inst.draw_count) == 0, "an empty field at build (count 0)")

	for inst in four:
		draw_to(inst, 20)
	var oc: Dictionary = read_cells(on_clear)
	var fc: Dictionary = read_cells(off_clear)
	check(live_count(off_clear) == 20 and fc.size() == 20 and all_in_column_zero(fc),
		"20 draws, semicolon off: twenty lines, every one in column 0, one per row")
	check(live_count(on_clear) == 20 and row_text(oc, 0).find("?") == -1,
		"20 draws, semicolon on: exactly the first row is filled")
	check(column_text(fc, GRID) == row_text(oc, 0),
		"20 draws: off's column read downward IS on's first row read across (from the lines)")

	for inst in four:
		draw_to(inst, 400)
	oc = read_cells(on_clear)
	fc = read_cells(off_clear)
	var ref400: String = stream_text(off_scroll, 400)
	var rowmajor_ok: bool = ref400.length() == 400
	for i in range(400):
		if not rowmajor_ok:
			break
		var key := Vector2i(i % GRID, int(i / GRID))
		if not oc.has(key) or str(oc[key]) != ref400.substr(i, 1):
			rowmajor_ok = false
	check(live_count(on_clear) == 400 and oc.size() == 400 and rowmajor_ok,
		"400 draws, semicolon on: a full field, character i at (i % 20, i / 20), checked against another instance's stream")
	check(live_count(off_clear) == 20 and all_in_column_zero(fc) and column_text(fc, GRID) == row_text(oc, 19),
		"400 draws, semicolon off: the column holds the last twenty characters, which are on's bottom row")
	var sig_clear: String = ""
	var sig_scroll: String = ""
	var os400: Dictionary = read_cells(on_scroll)
	for r in range(GRID):
		sig_clear += row_text(oc, r)
		sig_scroll += row_text(os400, r)
	check(sig_clear == sig_scroll, "400 draws: clear and scroll are the same picture until the field is full")

	var before_wipe: int = int(on_clear.draw_count)
	on_clear.generate_maze_step()
	check(live_count(on_clear) == 0 and int(on_clear.draw_count) == before_wipe,
		"when_full clear: the tick after a full field wipes every line and prints nothing")
	on_clear.generate_maze_step()
	var after_wipe: Dictionary = read_cells(on_clear)
	check(live_count(on_clear) == 1 and after_wipe.has(Vector2i(0, 0)) and int(on_clear.draw_count) == before_wipe + 1,
		"when_full clear: the tick after the wipe prints at (0, 0)")

	for inst in four:
		draw_to(inst, n_draws)
	var s_oc: String = stream_text(on_clear, n_draws)
	check(s_oc.length() == n_draws and s_oc == stream_text(off_clear, n_draws) \
			and s_oc == stream_text(on_scroll, n_draws) and s_oc == stream_text(off_scroll, n_draws),
		"same seed, four layouts, one stream: %d characters identical" % n_draws)
	check(s_oc.contains("/") and s_oc.contains("\\"), "the stream holds both characters")

	var fresh = make({"seed": 41})
	var pure := ""
	for i in range(n_draws):
		pure += "/" if fresh.coin_is_forward(i) else "\\"
	check(pure == s_oc and int(fresh.draw_count) == 0,
		"the stream is a function of (seed, index) alone: an instance that has drawn nothing predicts all %d" % n_draws)
	var other = make({"seed": 42})
	draw_to(other, n_draws)
	check(stream_text(other, n_draws) != s_oc, "a different seed prints a different stream")

	# Clear, on, read back from the LINES against the pure stream, not from its own log:
	# the wipe came after draw 399, so row 0 holds draws 400..419 and row 1 draws 420..436.
	var oc437: Dictionary = read_cells(on_clear)
	var row1_ok := true
	for c in range(17):
		if str(oc437.get(Vector2i(c, 1), "?")) != pure.substr(420 + c, 1):
			row1_ok = false
			break
	check(live_count(on_clear) == n_draws - 400 and oc437.size() == n_draws - 400 \
			and row_text(oc437, 0) == pure.substr(400, 20) and row1_ok and not oc437.has(Vector2i(17, 1)),
		"when_full clear, on: %d lines after the wipe, row 0 holds draws 400..419 and row 1 draws 420..436 (from the lines)" % (n_draws - 400))

	# Scroll, on: scrolls happened at draws 400 and 420, so draws 40..436 are on screen and
	# draw i stands at (i % 20, i / 20 - 2). The oldest forty are gone.
	var ref: String = stream_text(off_clear, n_draws)
	var os_cells: Dictionary = read_cells(on_scroll)
	var scroll_ok := true
	for i in range(40, n_draws):
		var key := Vector2i(i % GRID, int(i / GRID) - 2)
		if not os_cells.has(key) or str(os_cells[key]) != ref.substr(i, 1):
			scroll_ok = false
			break
	check(live_count(on_scroll) == n_draws - 40 and os_cells.size() == n_draws - 40 and scroll_ok,
		"when_full scroll, on: %d lines, draws 40..436 each one row-pitch up per scroll, the oldest 40 dropped" % (n_draws - 40))
	check(row_text(os_cells, 0) == ref.substr(40, 20) and not os_cells.has(Vector2i(17, 19)),
		"when_full scroll, on: the top row now holds draws 40..59 and the bottom row is the newest, still being written")
	var fs_cells: Dictionary = read_cells(off_scroll)
	check(live_count(off_scroll) == 20 and all_in_column_zero(fs_cells) and column_text(fs_cells, GRID) == ref.substr(n_draws - 20, 20),
		"when_full scroll, off: the column holds the newest twenty characters, oldest at the top")
	var fcl: Dictionary = read_cells(off_clear)
	check(live_count(off_clear) == 17 and all_in_column_zero(fcl) and column_text(fcl, 17) == ref.substr(420, 17),
		"when_full clear, off: wiped at every twentieth character, rows 0..16 hold draws 420..436")
	for inst in four + [fresh, other]:
		inst.queue_free()
	await process_frame

	# ---------------------------------------------------------------- 4: the default
	print("-- default instance")
	var d = make({})
	check(int(d.seed) == -1 and str(d.semicolon) == "on" and str(d.when_full) == "clear" and int(d.count) == 0,
		"default: seed -1 (unseeded), semicolon on, when_full clear, count 0")
	check(int(d.grid_size) == 20 and d.grid_nodes.size() == 20 and d.grid_nodes[0].size() == 20 \
			and live_count(d) == 0 and is_equal_approx(float(d.probability), 0.5),
		"default: a 20 x 20 grid of nodes, an empty field, probability 0.5 before the clock runs")
	seed(777)
	var expected := ""
	for i in range(45):
		expected += "/" if randf() < 0.5 else "\\"
	seed(777)
	draw_to(d, 45)
	var dc: Dictionary = read_cells(d)
	var got := ""
	for i in range(45):
		got += str(dc.get(Vector2i(i % GRID, int(i / GRID)), "?"))
	check(got == expected, "default: global randf() < probability, one call per character, row-major")
	draw_to(d, 400)
	var corner: Node3D = null
	for c in d.get_node("MazeLines").get_children():
		var cell: Vector2i = c.get_meta("ten_print_cell", Vector2i(-1, -1))
		if cell == Vector2i(19, 19):
			corner = c as Node3D
	check(corner != null and corner.position.is_equal_approx(Vector3(-4 + 19 * 0.4, 4 - 19 * 0.4, 0.1)) \
			and is_equal_approx(absf(corner.rotation_degrees.z), 45.0),
		"default: cell (19, 19) stands where it always did, at +-45 degrees")
	check(live_count(d) == 400 and int(d.current_row) == 20 and int(d.current_col) == 0,
		"default: 400 characters fill the field and park the cursor past the last row")
	d.set_process(true)
	var deadline: int = Time.get_ticks_msec() + 3000
	while live_count(d) == 400 and Time.get_ticks_msec() < deadline:
		await process_frame
	d.set_process(false)
	check(live_count(d) < 400 and int(d.current_row) < 20,
		"default, live _process: the breathing tick carries the full field through the wipe")
	d.queue_free()
	await process_frame

	# ---------------------------------------------------------------- 5: config lanes
	print("-- config lanes")
	var m = make({}, {"seed": "41", "semicolon": "off", "when_full": "scroll", "count": "30"}, true)
	var mc: Dictionary = read_cells(m)
	check(int(m.seed) == 41 and str(m.semicolon) == "off" and str(m.when_full) == "scroll" \
			and int(m.count) == 30 and int(m.draw_count) == 30,
		"config before the tree, as token strings: every key took and 30 characters were printed at build")
	check(live_count(m) == 20 and all_in_column_zero(mc) and column_text(mc, GRID) == ref.substr(10, 20),
		"config before the tree: the column shows draws 10..29 of seed 41's stream")

	var g = make({}, {"semicolon": "off", "seed": 41}, false)
	check(str(g.semicolon) == "off" and int(g.seed) == 41 and int(g.draw_count) == 0 and live_count(g) == 0,
		"config after _ready (the grid's deferred lane): took, on an empty field")
	draw_to(g, 5)
	var gc: Dictionary = read_cells(g)
	check(all_in_column_zero(gc) and column_text(gc, 5) == ref.substr(0, 5),
		"config after _ready: the column starts the same stream at draw 0")
	g.apply_grid_config({})
	check(int(g.draw_count) == 5 and live_count(g) == 5, "an empty config changes nothing")
	g.apply_grid_config({"semicolon": "false", "when_full": "sideways"})
	check(str(g.semicolon) == "off" and str(g.when_full) == "clear" and int(g.draw_count) == 5,
		"'false' reads as off (no change, no restart); an unknown when_full word is ignored")
	g.apply_grid_config({"semicolon": "on"})
	check(str(g.semicolon) == "on" and int(g.draw_count) == 0 and live_count(g) == 0,
		"a real change after the build restarts the stream on an empty field")

	var dna_on = make({"seed": 41, "when_full": "scroll", "count": 400})
	var dna_off = make({"seed": 41, "when_full": "scroll", "count": 400, "semicolon": "off"})
	var don: Dictionary = read_cells(dna_on)
	var doff: Dictionary = read_cells(dna_off)
	check(live_count(dna_on) == 400 and don.size() == 400 and live_count(dna_off) == 20 \
			and all_in_column_zero(doff) and column_text(doff, GRID) == row_text(don, 19),
		"DNA fixture (seed 41, count 400, scroll): a full field against a full column, and the column is the field's last row")
	for inst in [m, g, dna_on, dna_off]:
		inst.queue_free()
	await process_frame

	if _done:
		return
	_done = true
	print("TEN_PRINT_SEMICOLON_RESULT " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
