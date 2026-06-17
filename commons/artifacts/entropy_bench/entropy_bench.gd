extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EntropyBench
## @identity
## lineage: Shannon's bit on a bench — surprise made measurable
## essence: a bias dial sweeps p; H peaks at the fair coin and drains toward the certain
## truth: the most honest signal is the one you cannot predict

@export var bias: float = 0.5

var _bars_group: Node3D
var _readout: Label3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("bias"): bias = clampf(float(config["bias"]), 0.02, 0.98)
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _entropy(p: float) -> float:
	var q: float = 1.0 - p
	if p <= 0.0 or q <= 0.0: return 0.0
	return -(p * (log(p) / log(2.0)) + q * (log(q) / log(2.0)))


func _build() -> void:
	add_child(_box(Vector3(0, 0.75, 0), Vector3(1.1, 0.2, 0.5), _matte_mat(Color(0.2, 0.22, 0.26))))
	add_child(_cylinder(Vector3(0, 0.42, 0), 0.07, 0.66, _steel_mat(Color(0.4, 0.43, 0.5))))
	add_child(_billboard_label("ENTROPY / bits of surprise", Vector3(0, 1.6, -0.22), 22, Color(0.9, 0.95, 1.0)))
	# Bias dial on the left of the top.
	add_child(_torus(Vector3(-0.42, 1.0, 0), 0.09, 0.016, _steel_mat(Color(0.55, 0.6, 0.7))))
	var ang: float = (bias - 0.5) * 3.4
	add_child(_cylinder_between(Vector3(-0.42, 1.0, 0), Vector3(-0.42 + sin(ang) * 0.08, 1.0 + cos(ang) * 0.08, 0), 0.009, _glow_mat(Color(1.0, 0.75, 0.2), 2.2)))
	add_child(_billboard_label("bias p", Vector3(-0.42, 1.14, 0), 14, Color(0.8, 0.85, 0.9)))
	_readout = _billboard_label("", Vector3(0.3, 1.32, 0), 20, Color(0.4, 1.0, 0.7))
	add_child(_readout)
	_bars_group = Node3D.new()
	add_child(_bars_group)
	_draw_bars()


func _draw_bars() -> void:
	# Two bars for p0 / p1, plus an H meter rising behind them.
	for c in _bars_group.get_children(): _bars_group.remove_child(c); c.queue_free()
	var p0: float = 1.0 - bias
	var p1: float = bias
	_bars_group.add_child(_box(Vector3(-0.02, 1.0 + p0 * 0.18, 0.14), Vector3(0.12, p0 * 0.36, 0.05), _glow_mat(Color(0.3, 0.9, 1.0), 1.6)))
	_bars_group.add_child(_box(Vector3(0.16, 1.0 + p1 * 0.18, 0.14), Vector3(0.12, p1 * 0.36, 0.05), _glow_mat(Color(1.0, 0.6, 0.3), 1.6)))
	_bars_group.add_child(_billboard_label("p0", Vector3(-0.02, 0.98, 0.16), 13, Color(0.8, 0.9, 1.0)))
	_bars_group.add_child(_billboard_label("p1", Vector3(0.16, 0.98, 0.16), 13, Color(1.0, 0.85, 0.8)))
	var h: float = _entropy(bias)
	_bars_group.add_child(_box(Vector3(0.42, 1.0 + h * 0.18, 0.1), Vector3(0.07, h * 0.36, 0.05), _glow_mat(Color(0.4, 1.0, 0.7), 1.9)))
	if _readout != null:
		_readout.text = "H = %.2f bits" % h


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_t += delta * 0.4
	# Slowly sweep p back and forth across the full range.
	bias = 0.5 + 0.46 * sin(_t)
	_draw_bars()
	var ang: float = (bias - 0.5) * 3.4
	for c in get_children():
		if c is MeshInstance3D and c.mesh is CylinderMesh and (c.mesh as CylinderMesh).top_radius < 0.01:
			c.transform = Transform3D(_basis_y_to(Vector3(sin(ang), cos(ang), 0)), Vector3(-0.42, 1.0, 0) + Vector3(sin(ang), cos(ang), 0) * 0.04)
