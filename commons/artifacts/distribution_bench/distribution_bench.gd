extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DistributionBench
## @identity
## lineage: the bell curve — Galton's board, the central limit theorem made visible
## essence: outcomes are not equal; the middle is crowded, the edges are lonely
## truth: pile enough chances together and they confess a shape

@export var drop_time: float = 0.18
@export var bins: int = 12

var _bars: Node3D
var _beads: Node3D
var _heights: Array[float] = []
var _bar_w: float = 0.07
var _span: float = 0.9
var _base_y: float = 0.22
var _t: float = 0.0

func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), _steel_mat(Color(0.28, 0.3, 0.36))))
	add_child(_cylinder(Vector3(0, -0.25, 0), 0.08, 0.5, _steel_mat(Color(0.22, 0.24, 0.28))))
	add_child(_box(Vector3(0, 1.05, -0.32), Vector3(1.1, 0.85, 0.04), _matte_mat(Color(0.1, 0.11, 0.14))))
	# seed a bell shape
	_heights.clear()
	var mid: float = (bins - 1) * 0.5
	for i in range(bins):
		var d: float = (i - mid) / (bins * 0.32)
		_heights.append(exp(-d * d))
	_normalize()
	_bars = Node3D.new()
	add_child(_bars)
	_redraw_bars()
	_beads = Node3D.new()
	add_child(_beads)
	# a few beads already mid-fall above their bins
	for _i in range(4):
		var b: int = _bell_pick()
		_beads.add_child(_sphere(_bin_top(b) + Vector3(0, 0.3 + _rng.randf() * 0.4, 0), 0.025, _glow_mat(Color(0.5, 1.0, 0.7), 1.6)))
	add_child(_billboard_label("not all outcomes equal", Vector3(0, 1.6, -0.3), 36, Color(0.95, 0.95, 1.0)))

func _normalize() -> void:
	var mx: float = 0.0
	for h in _heights:
		mx = maxf(mx, h)
	if mx <= 0.0: return
	for i in range(_heights.size()):
		_heights[i] = _heights[i] / mx

func _bin_x(i: int) -> float:
	return -_span * 0.5 + (i + 0.5) * (_span / bins)

func _bin_top(i: int) -> Vector3:
	return Vector3(_bin_x(i), _base_y + _heights[i] * 0.5 + 0.5, -0.29)

func _bell_pick() -> int:
	# sample weighted by current heights (the bell)
	var total: float = 0.0
	for h in _heights:
		total += h
	var r: float = _rng.randf() * total
	for i in range(bins):
		r -= _heights[i]
		if r <= 0.0:
			return i
	return bins / 2

func _redraw_bars() -> void:
	for c in _bars.get_children():
		_bars.remove_child(c); c.queue_free()
	for i in range(bins):
		var h: float = clampf(_heights[i], 0.03, 1.0) * 0.5
		var hue: float = 0.55 - _heights[i] * 0.25
		_bars.add_child(_box(Vector3(_bin_x(i), _base_y + h * 0.5 + 0.5, -0.29), Vector3(_bar_w, h, 0.04), _glow_mat(Color.from_hsv(hue, 0.7, 1.0), 1.4)))

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	# beads fall toward their bar, then vanish and nudge it
	var bead_mat := _glow_mat(Color(0.5, 1.0, 0.7), 1.6)
	for b in _beads.get_children():
		var mi := b as MeshInstance3D
		mi.position.y -= delta * 0.9
		if mi.position.y <= _base_y + 0.55:
			_beads.remove_child(mi); mi.queue_free()
	_t += delta
	if _t < drop_time: return
	_t = 0.0
	var bin: int = _bell_pick()
	_heights[bin] = minf(_heights[bin] + 0.06, 1.4)
	_normalize()
	_redraw_bars()
	if _beads.get_child_count() < 8:
		_beads.add_child(_sphere(_bin_top(bin) + Vector3(0, 0.45, 0), 0.025, bead_mat))
