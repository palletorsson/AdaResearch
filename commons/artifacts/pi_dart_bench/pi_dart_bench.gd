extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PiDartBench

## @identity
## lineage: Monte Carlo — the bench rung (toy → bench)
## essence: a dense dart field plus a convergence line creeping toward 3.14159
## truth: more throws, less wobble — the estimate walks home to pi.

@export var add_period: float = 0.22
@export var darts_per_tick: int = 12

var _darts: Node3D
var _line: Node3D
var _readout: Label3D
var _inside: int = 0
var _total: int = 0
var _accum: float = 0.0
var _history: Array[float] = []

# panel: square shown at x in [px-PS, px+PS], y in [PY0, PY0+PS]
const PS: float = 0.42
const PY0: float = 1.0
const PANEL_X: float = -0.24
# convergence plot, to the right
const PLOT_X: float = 0.34
const PLOT_W: float = 0.46
const PLOT_H: float = 0.7
const MAX_HIST: int = 60


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("darts_per_tick"): darts_per_tick = int(config["darts_per_tick"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_inside = 0
	_total = 0
	_history.clear()
	# bench base + pillar (top ~0.85)
	add_child(_box(Vector3(0.0, 0.75, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(Color(0.22, 0.23, 0.27))))
	add_child(_cylinder(Vector3(0.0, 0.37, 0.0), 0.12, 0.76, _steel_mat(Color(0.4, 0.42, 0.5))))
	# panel backboard
	add_child(_box(Vector3(0.0, PY0 + PS * 0.5, -0.02), Vector3(1.0, PS + 0.1, 0.03), _matte_mat(Color(0.08, 0.09, 0.12))))
	# square frame + quarter circle on the panel
	var fmat := _steel_mat(Color(0.6, 0.62, 0.7))
	add_child(_cylinder_between(_panel_pt(0, 0), _panel_pt(1, 0), 0.007, fmat))
	add_child(_cylinder_between(_panel_pt(0, 1), _panel_pt(1, 1), 0.007, fmat))
	add_child(_cylinder_between(_panel_pt(0, 0), _panel_pt(0, 1), 0.007, fmat))
	add_child(_cylinder_between(_panel_pt(1, 0), _panel_pt(1, 1), 0.007, fmat))
	var amat := _glow_mat(Color(0.95, 0.85, 0.3), 2.2)
	var prev := _panel_pt(1, 0)
	for i in range(1, 33):
		var a: float = (PI * 0.5) * float(i) / 32.0
		var p := _panel_pt(cos(a), sin(a))
		add_child(_cylinder_between(prev, p, 0.006, amat))
		prev = p
	# the 3.14159 target line on the plot
	add_child(_cylinder_between(_plot_pt(0.0, PI), _plot_pt(1.0, PI), 0.006, _glow_mat(Color(0.95, 0.4, 0.4), 1.6)))
	add_child(_billboard_label("π", _plot_pt(1.04, PI), 16, Color(0.95, 0.55, 0.55)))
	# containers
	_darts = Node3D.new()
	add_child(_darts)
	_line = Node3D.new()
	add_child(_line)
	# readout
	_readout = _billboard_label("MONTE CARLO π", Vector3(0.0, 1.62, 0.0), 24, Color(0.85, 0.95, 1.0))
	add_child(_readout)
	# seed a dense field + history so the capture is meaningful
	for i in range(380):
		_throw_dart()
	for i in range(MAX_HIST):
		# pre-fill history with the current estimate so a line already exists
		_history.append(_estimate())
	_rebuild_line()
	_update_readout()


func _panel_pt(x: float, y: float) -> Vector3:
	return Vector3(PANEL_X - PS + x * PS * 2.0, PY0 + y * PS, 0.0)


# map t in [0,1] (history axis) and value v (0..4) onto the plot rect
func _plot_pt(t: float, v: float) -> Vector3:
	var vy: float = clampf((v - 2.4) / 1.4, 0.0, 1.0)   # zoom around pi (2.4..3.8)
	return Vector3(PLOT_X - PLOT_W * 0.5 + t * PLOT_W, PY0 + vy * PLOT_H, 0.0)


func _estimate() -> float:
	return 4.0 * float(_inside) / float(maxi(_total, 1))


func _throw_dart() -> void:
	var x: float = _rng.randf()
	var y: float = _rng.randf()
	var inside: bool = (x * x + y * y) <= 1.0
	_total += 1
	if inside:
		_inside += 1
	var col: Color = Color(0.2, 1.0, 0.35) if inside else Color(0.55, 0.57, 0.62)
	var energy: float = 2.0 if inside else 0.4
	_darts.add_child(_sphere(_panel_pt(x, y) + Vector3(0, 0, 0.015), 0.009, _glow_mat(col, energy)))


func _rebuild_line() -> void:
	for c in _line.get_children():
		_line.remove_child(c); c.queue_free()
	if _history.size() < 2:
		return
	var lmat := _glow_mat(Color(0.3, 0.8, 1.0), 2.0)
	var n: int = _history.size()
	var prev := _plot_pt(0.0, _history[0])
	for i in range(1, n):
		var t: float = float(i) / float(n - 1)
		var p := _plot_pt(t, _history[i])
		_line.add_child(_cylinder_between(prev, p, 0.006, lmat))
		prev = p


func _update_readout() -> void:
	_readout.text = "MONTE CARLO π ≈ %.5f\n%d / %d inside" % [_estimate(), _inside, _total]


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < add_period:
		return
	_accum = 0.0
	for k in range(darts_per_tick):
		_throw_dart()
	# trim dart visuals
	while _darts.get_child_count() > 520:
		var old := _darts.get_child(0)
		_darts.remove_child(old); old.queue_free()
	_history.append(_estimate())
	while _history.size() > MAX_HIST:
		_history.remove_at(0)
	_rebuild_line()
	_update_readout()
