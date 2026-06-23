extends Node3D
class_name TestHarness

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the TEST SUITE as a wall of small lights — a grid of test cases (default 5x4 = 20) that glow GREEN when they pass and RED when they fail. A function f(x) feeds the board. It runs three acts on a loop: all green (everything works), a BUG INTRODUCED (a deterministic band of cells flips red), then FIXED (the reds heal back to green one by one, left to right). A test is a claim about the future; the board is that claim made visible the instant it breaks.
# desire: to make correctness a thing you can SEE go and come back — to turn the invisible promise of "this still works" into a field of lights, so a viewer feels the jolt of a regression (a stripe of red appearing) and the relief of a green suite, and learns why a test you can watch is worth writing.
# critical_parameter: bug_fraction — how much of the suite the injected bug breaks. It IS the lesson: one bad change rarely breaks one test, it breaks a BAND of them at once (a regression has blast radius); a good suite makes that radius visible and a fix shrinks it back to zero.
# triggers: _ready/_read_overrides/_build; _process drives the pass/bug/fix phases by swapping emission colour+energy on cell materials (never rebuilding meshes); apply_grid_config rebuilds.
# emerges: PHASE 1 a calm green wall + "PASS"; PHASE 2 a red stripe punches through + "BUG INTRODUCED"; PHASE 3 the stripe heals cell-by-cell + "FIXED". For stills, freeze_phase pins any single act.
# needs: a backing board [present]; a grid of pass/fail cells with baked t01.. labels [present]; an f(x) function block + feed line [present]; baked state captions + title [present].
# relationships: the verification sibling of the resourcemanagement sequence — where big_o_complexity shows what an algorithm COSTS, this shows whether it is even CORRECT; the green/red board is the everyday face of "a test is a falsifiable claim".
# truth: a test is a claim about the future, written down so the machine can check it for you. You do not trust code because it is clever — you trust it because the lights are green, and you watch them, because the moment they go red is the moment you learn you were wrong.

@export var cols: int = 5
@export var rows: int = 4
@export var cycle_seconds: float = 10.0
@export var bug_fraction: float = 0.3
@export var animate: bool = true
## -1 = animate; 0 = all green, 1 = bug/reds, 2 = fixing (for stills/captures).
@export var freeze_phase: int = -1
@export var emissive: bool = true

const PASS_COLOR := Color(0.24, 0.80, 0.42)
const FAIL_COLOR := Color(0.90, 0.24, 0.28)
const CELL_W := 0.30
const CELL_GAP := 0.08

var _cells: Array = []          # MeshInstance3D per test cell
var _cell_pass_mat: Array = []  # cached green material per cell
var _cell_fail_mat: Array = []  # cached red material per cell
var _bug_set: Array = []        # bool per cell: is this cell broken by the bug
var _caption_pass: MeshInstance3D = null
var _caption_bug: MeshInstance3D = null
var _caption_fixed: MeshInstance3D = null
var _built := false
var _t := 0.0
var _last_phase := -99
var _last_fixed := -1

func _ready() -> void:
	_read_overrides()
	_build()
	set_process(animate and freeze_phase < 0 and not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_cells.clear(); _cell_pass_mat.clear(); _cell_fail_mat.clear(); _bug_set.clear()
		_caption_pass = null; _caption_bug = null; _caption_fixed = null
		_last_phase = -99; _last_fixed = -1
		_built = false
		_build()
		set_process(animate and freeze_phase < 0 and not Engine.is_editor_hint())


func _read_overrides() -> void:
	if has_meta("config_cols"): cols = int(str(get_meta("config_cols")))
	if has_meta("config_rows"): rows = int(str(get_meta("config_rows")))
	if has_meta("config_cycle_seconds"): cycle_seconds = float(str(get_meta("config_cycle_seconds")))
	if has_meta("config_bug_fraction"): bug_fraction = float(str(get_meta("config_bug_fraction")))
	if has_meta("config_animate"): animate = str(get_meta("config_animate")).to_lower() in ["true", "1", "yes", "on"]
	if has_meta("config_freeze_phase"): freeze_phase = int(str(get_meta("config_freeze_phase")))
	if has_meta("config_emissive"): emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


func _cell_count() -> int:
	return maxi(cols, 1) * maxi(rows, 1)


# Deterministic bug set: spread the broken indices across the suite (a regression
# touches a BAND, not one cell). No RNG — chosen by stride over the index space.
func _compute_bug_set() -> void:
	_bug_set.clear()
	var total: int = _cell_count()
	for i in total:
		_bug_set.append(false)
	var n_bug: int = clampi(int(round(float(total) * clampf(bug_fraction, 0.0, 1.0))), 0, total)
	if n_bug <= 0:
		return
	var stride: float = float(total) / float(n_bug)
	for k in n_bug:
		var idx: int = clampi(int(floor(float(k) * stride)), 0, total - 1)
		_bug_set[idx] = true


func _build() -> void:
	_built = true
	_compute_bug_set()
	var c: int = maxi(cols, 1)
	var r: int = maxi(rows, 1)
	var step: float = CELL_W + CELL_GAP
	var grid_w: float = float(c) * step - CELL_GAP
	var grid_h: float = float(r) * step - CELL_GAP
	var board_w: float = grid_w + 0.5
	var board_h: float = grid_h + 0.5
	var x0: float = -grid_w * 0.5 + CELL_W * 0.5
	var y0: float = grid_h * 0.5 - CELL_W * 0.5  # top row first

	# Backing board (wall-mounted, slightly behind the cells).
	add_child(_box(Vector3(0, 0, -0.06), Vector3(board_w, board_h, 0.05), _mat(Color(0.13, 0.14, 0.17))))

	# Grid of test cells (row-major, top-left = t01).
	for row in r:
		for col in c:
			var i: int = row * c + col
			var x: float = x0 + float(col) * step
			var y: float = y0 - float(row) * step
			var pass_mat: StandardMaterial3D = _emi(PASS_COLOR, 0.9) if emissive else _mat(PASS_COLOR)
			var fail_mat: StandardMaterial3D = _emi(FAIL_COLOR, 1.3) if emissive else _mat(FAIL_COLOR)
			_cell_pass_mat.append(pass_mat)
			_cell_fail_mat.append(fail_mat)
			var cell := _box(Vector3(x, y, 0.02), Vector3(CELL_W, CELL_W, 0.06), pass_mat)
			add_child(cell)
			_cells.append(cell)
			var tag: MeshInstance3D = BakedText.make_label_mesh("t%02d" % (i + 1), Color(0.95, 0.95, 0.97), Vector2(CELL_W * 0.95, CELL_W * 0.42), 1400, true)
			if tag:
				tag.position = Vector3(x, y, 0.06)
				add_child(tag)

	# Function-under-test block, below the grid, with a feed line up to the board.
	var fx_y: float = -grid_h * 0.5 - 0.55
	add_child(_box(Vector3(0, fx_y, 0.02), Vector3(0.95, 0.5, 0.12), _emi(Color(0.30, 0.55, 0.92), 0.8) if emissive else _mat(Color(0.30, 0.55, 0.92))))
	var fx_lbl: MeshInstance3D = BakedText.make_label_mesh("f(x)", Color(0.96, 0.97, 1.0), Vector2(0.7, 0.26), 1400, true)
	if fx_lbl:
		fx_lbl.position = Vector3(0, fx_y, 0.10)
		add_child(fx_lbl)
	# Thin feed line from f(x) up to the bottom of the grid.
	var line_top: float = -grid_h * 0.5
	var line_bot: float = fx_y + 0.25
	var line_h: float = maxf(line_top - line_bot, 0.02)
	add_child(_box(Vector3(0, (line_top + line_bot) * 0.5, 0.0), Vector3(0.04, line_h, 0.02), _emi(Color(0.40, 0.60, 0.95), 0.7)))

	# Title above the board.
	var title: MeshInstance3D = BakedText.make_label_mesh("TESTING & DEBUGGING", Color(0.95, 0.95, 0.97), Vector2(board_w * 0.82, 0.24), 1400, true)
	if title:
		title.position = Vector3(0, board_h * 0.5 + 0.28, 0)
		add_child(title)

	# State captions (pre-baked, toggled — never re-baked per frame).
	var cap_y: float = grid_h * 0.5 + 0.06
	_caption_pass = BakedText.make_label_mesh("PASS  %d/%d" % [_cell_count(), _cell_count()], PASS_COLOR, Vector2(board_w * 0.55, 0.2), 1400, true)
	if _caption_pass:
		_caption_pass.position = Vector3(0, cap_y, 0.06)
		add_child(_caption_pass)
	var n_bug: int = _bug_count()
	_caption_bug = BakedText.make_label_mesh("BUG INTRODUCED  %d/%d FAIL" % [n_bug, _cell_count()], FAIL_COLOR, Vector2(board_w * 0.78, 0.2), 1400, true)
	if _caption_bug:
		_caption_bug.position = Vector3(0, cap_y, 0.06)
		_caption_bug.visible = false
		add_child(_caption_bug)
	_caption_fixed = BakedText.make_label_mesh("FIXED  %d/%d" % [_cell_count(), _cell_count()], PASS_COLOR, Vector2(board_w * 0.55, 0.2), 1400, true)
	if _caption_fixed:
		_caption_fixed.position = Vector3(0, cap_y, 0.06)
		_caption_fixed.visible = false
		add_child(_caption_fixed)

	# Initial paint.
	if freeze_phase >= 0:
		_apply_phase(freeze_phase, float(_cell_count()))
	else:
		_apply_phase(0, 0.0)


func _bug_count() -> int:
	var n: int = 0
	for b in _bug_set:
		if b:
			n += 1
	return n


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var phase01: float = fmod(_t, cycle_seconds) / cycle_seconds
	# 3 acts: [0, 0.4) all pass, [0.4, 0.7) bug, [0.7, 1.0) fixing.
	if phase01 < 0.4:
		_apply_phase(0, 0.0)
	elif phase01 < 0.7:
		_apply_phase(1, 0.0)
	else:
		# Heal fraction across the fixing window.
		var f: float = (phase01 - 0.7) / 0.3
		_apply_phase(2, f * float(_cell_count()))


# phase 0 = all pass, 1 = bug (reds shown), 2 = fixing (heal `fixed_count` reds, left->right by index).
func _apply_phase(phase: int, fixed_count: float) -> void:
	var fixed_n: int = clampi(int(floor(fixed_count)), 0, _cell_count())
	# Only repaint cells when phase or heal-progress changed (cheap swaps, no rebuild).
	if phase == _last_phase and (phase != 2 or fixed_n == _last_fixed):
		return
	for i in _cells.size():
		var cell: MeshInstance3D = _cells[i]
		var fail: bool = false
		match phase:
			0:
				fail = false
			1:
				fail = _bug_set[i]
			2:
				# A broken cell is still red until the heal sweep reaches its index.
				fail = _bug_set[i] and (i >= fixed_n)
		cell.material_override = _cell_fail_mat[i] if fail else _cell_pass_mat[i]
	# Captions.
	if _caption_pass: _caption_pass.visible = (phase == 0)
	if _caption_bug: _caption_bug.visible = (phase == 1)
	if _caption_fixed: _caption_fixed.visible = (phase == 2)
	_last_phase = phase
	_last_fixed = fixed_n


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m


func _emi(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	m.roughness = 0.5
	return m


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
