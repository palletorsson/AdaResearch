extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TenPrintBench
## @identity
## lineage: 10 PRINT CHR$(205.5+RND(1)); — the bias knob behind the coin
## essence: turn the dial and watch a one-line program grow a different country
## truth: probability is a landscape; every threshold is a different world

@export var cols: int = 16
@export var rows: int = 12
@export var slash_bias: float = 0.5

var _grid: Node3D
var _bars: Array = []
var _dial: MeshInstance3D
var _step := 0.0

func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("slash_bias"): slash_bias = float(config["slash_bias"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	_bars.clear()
	var steel := _steel_mat(Color(0.4, 0.42, 0.5))
	add_child(_box(Vector3(0, 0.75, 0), Vector3(1.1, 0.2, 0.5), steel))
	add_child(_cylinder(Vector3(-0.3, 0.85, 0), 0.05, 0.18, steel))
	# Standing 10 PRINT panel on the bench.
	var pw := 0.9
	var ph := pw * float(rows) / float(cols)
	var base_y := 1.0
	add_child(_box(Vector3(-0.3, base_y + ph * 0.5, -0.02), Vector3(pw + 0.04, ph + 0.04, 0.02), _matte_mat(Color(0.06, 0.07, 0.1), 0.7)))
	_grid = Node3D.new()
	_grid.position = Vector3(-0.3, base_y, 0)
	add_child(_grid)
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(_make_cell(r, c, pw, ph))
		_bars.append(row)
	# Probability dial.
	add_child(_cylinder(Vector3(0.45, 0.92, 0.0), 0.13, 0.05, steel))
	_dial = _box(Vector3(0.45, 0.95, 0.0), Vector3(0.02, 0.16, 0.02), _glow_mat(Color(1.0, 0.7, 0.2), 3.0))
	_dial.rotation.z = lerpf(1.2, -1.2, slash_bias)
	add_child(_dial)
	add_child(_billboard_label("10 PRINT / one line of chance per cell", Vector3(0, 1.6, 0), 26, Color(0.7, 0.9, 1.0)))

func _make_cell(r: int, c: int, pw: float, ph: float) -> MeshInstance3D:
	var sx := pw / float(cols)
	var sy := ph / float(rows)
	var cx := -pw * 0.5 + (float(c) + 0.5) * sx
	var cy := ph - (float(r) + 0.5) * sy
	var slash := _rng.randf() < slash_bias
	var mat := _glow_mat(Color.from_hsv(0.52 if slash else 0.92, 0.55, 1.0), 2.4)
	var bar := _box(Vector3(cx, cy, 0.01), Vector3(sx * 0.84, sy * 0.16, 0.02), mat)
	bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
	_grid.add_child(bar)
	return bar

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	# Bias drifts slowly so the maze's character visibly shifts.
	slash_bias = 0.5 + sin(Time.get_ticks_msec() * 0.0003) * 0.35
	if _dial: _dial.rotation.z = lerpf(1.2, -1.2, slash_bias)
	_step += delta
	if _step < 0.4: return
	_step = 0.0
	# Re-roll the whole field honoring the current bias.
	for r in range(rows):
		for c in range(cols):
			var bar: MeshInstance3D = _bars[r][c]
			var slash := _rng.randf() < slash_bias
			bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
			bar.material_override = _glow_mat(Color.from_hsv(0.52 if slash else 0.92, 0.55, 1.0), 2.4)
