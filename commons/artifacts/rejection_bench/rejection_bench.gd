extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RejectionBench

## @identity
## lineage: rejection sampling — the bench rung (toy → bench → room)
## essence: darts fill the panel; the kept ones pile into the curve's histogram
## truth: accumulate the accepted and the distribution draws itself.

@export var bins: int = 14
@export var add_period: float = 0.25
@export var darts_per_tick: int = 6

var _darts: Node3D
var _hist: Node3D
var _readout: Label3D
var _accum: float = 0.0
var _bin_counts: PackedInt32Array
var _max_count: int = 1

# panel local frame: x in [-0.45,0.45], y in [0.0,0.9] above panel base y0
const PANEL_X: float = 0.45
const PANEL_H: float = 0.9
const PANEL_Y0: float = 1.0
const PANEL_Z: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("bins"): bins = int(config["bins"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _curve(x: float) -> float:
	var d: float = (x - 0.5) / 0.18
	return 0.85 * exp(-0.5 * d * d)


func _build() -> void:
	_bin_counts = PackedInt32Array()
	_bin_counts.resize(bins)
	_max_count = 1
	# bench base + pillar (top at y ~0.85)
	add_child(_box(Vector3(0.0, 0.75, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(Color(0.22, 0.23, 0.27))))
	add_child(_cylinder(Vector3(0.0, 0.37, 0.0), 0.12, 0.76, _steel_mat(Color(0.4, 0.42, 0.5))))
	# vertical panel
	add_child(_box(Vector3(-0.2, PANEL_Y0 + PANEL_H * 0.5, -0.02), Vector3(0.96, PANEL_H + 0.06, 0.03), _matte_mat(Color(0.08, 0.09, 0.12))))
	# target curve drawn on the panel
	var cmat := _glow_mat(Color(0.95, 0.85, 0.3), 2.0)
	var prev := _panel_pt(0.0, _curve(0.0))
	for i in range(1, 41):
		var x: float = float(i) / 40.0
		var p := _panel_pt(x, _curve(x))
		add_child(_cylinder_between(prev, p, 0.008, cmat))
		prev = p
	# darts container
	_darts = Node3D.new()
	add_child(_darts)
	# histogram container (to the right of the panel)
	_hist = Node3D.new()
	add_child(_hist)
	# readout
	_readout = _billboard_label("REJECTION SAMPLING\nkeep what's under the curve", Vector3(-0.2, 1.6, 0.0), 24, Color(0.85, 0.95, 1.0))
	add_child(_readout)
	# seed a starting fill so capture looks meaningful
	for i in range(90):
		_throw_dart()
	_rebuild_hist()


func _panel_pt(x: float, y: float) -> Vector3:
	return Vector3(-0.2 - PANEL_X + x * PANEL_X * 2.0, PANEL_Y0 + y * PANEL_H, PANEL_Z)


func _throw_dart() -> void:
	var x: float = _rng.randf()
	var y: float = _rng.randf()
	var accepted: bool = y <= _curve(x)
	var col: Color = Color(0.2, 1.0, 0.35) if accepted else Color(0.75, 0.2, 0.2)
	var energy: float = 2.2 if accepted else 0.5
	_darts.add_child(_sphere(_panel_pt(x, y) + Vector3(0, 0, 0.02), 0.012, _glow_mat(col, energy)))
	if accepted:
		var b: int = clampi(int(x * bins), 0, bins - 1)
		_bin_counts[b] += 1
		_max_count = maxi(_max_count, _bin_counts[b])


func _rebuild_hist() -> void:
	for c in _hist.get_children():
		_hist.remove_child(c); c.queue_free()
	var hx: float = 0.36
	var hw: float = 0.5
	var hmat := _glow_mat(Color(0.3, 0.85, 0.5), 1.6)
	for b in range(bins):
		var frac: float = float(_bin_counts[b]) / float(_max_count)
		var h: float = 0.03 + frac * 0.7
		var px: float = hx - hw * 0.5 + (float(b) + 0.5) / float(bins) * hw
		_hist.add_child(_box(Vector3(px, PANEL_Y0 + h * 0.5, 0.0), Vector3(hw / float(bins) * 0.8, h, 0.04), hmat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < add_period:
		return
	_accum = 0.0
	for k in range(darts_per_tick):
		_throw_dart()
	# trim dart count so it doesn't grow unbounded
	while _darts.get_child_count() > 260:
		var old := _darts.get_child(0)
		_darts.remove_child(old); old.queue_free()
	_rebuild_hist()
