extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NoiseCompareBench
## @identity
## lineage: three noise functions side by side — value, simplex, Worley cellular
## essence: same coordinate, three different fields, three different textures of randomness
## truth: chaos has dialects; choose the grain that fits the world

@export var grid: float = 10.0
@export var cell: float = 0.045

var _value := FastNoiseLite.new()
var _simplex := FastNoiseLite.new()
var _worley := FastNoiseLite.new()
var _panels: Array[Node3D] = []
var _zoff: float = 0.0
var _palettes := [Color(0.6, 0.85, 1.0), Color(0.7, 1.0, 0.6), Color(1.0, 0.7, 0.5)]


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_value.noise_type = FastNoiseLite.TYPE_VALUE
	_simplex.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_worley.noise_type = FastNoiseLite.TYPE_CELLULAR
	for nn in [_value, _simplex, _worley]:
		nn.frequency = 0.22
	# bench
	add_child(_box(Vector3(0, 0.75, 0), Vector3(1.9, 0.2, 0.75), _steel_mat(Color(0.2, 0.22, 0.26))))
	add_child(_cylinder(Vector3(0, 0.42, 0), 0.08, 0.66, _steel_mat(Color(0.16, 0.17, 0.2))))
	add_child(_billboard_label("Simplex / Worley / value noise", Vector3(0, 1.62, 0), 26, Color(0.8, 0.9, 1.0)))
	_panels.clear()
	var names := ["value", "simplex", "worley"]
	var xs := [-0.6, 0.0, 0.6]
	for i in range(3):
		var root := Node3D.new()
		root.position = Vector3(xs[i], 0.9, 0)
		add_child(root)
		_panels.append(root)
		add_child(_box(Vector3(xs[i], 0.88, 0), Vector3(0.55, 0.02, 0.55), _matte_mat(Color(0.06, 0.07, 0.09))))
		add_child(_billboard_label(names[i], Vector3(xs[i], 1.0, 0.32), 20, _palettes[i]))
	_paint_all()


func _height_at(nn: FastNoiseLite, gx: int, gz: int) -> float:
	return (nn.get_noise_2d(float(gx), float(gz) + _zoff) + 1.0) * 0.5


func _paint_panel(idx: int, nn: FastNoiseLite) -> void:
	var root: Node3D = _panels[idx]
	for c in root.get_children(): root.remove_child(c); c.queue_free()
	var g: int = int(grid)
	var span: float = 0.5
	var base: Color = _palettes[idx]
	for gx in range(g):
		for gz in range(g):
			var v: float = _height_at(nn, gx, gz)
			var lx: float = (float(gx) / float(g - 1) - 0.5) * span
			var lz: float = (float(gz) / float(g - 1) - 0.5) * span
			var h: float = 0.02 + v * 0.16
			root.add_child(_box(Vector3(lx, h * 0.5, lz), Vector3(cell, h, cell), _glow_mat(base * (0.4 + v * 0.7), 1.0 + v)))


func _paint_all() -> void:
	_paint_panel(0, _value)
	_paint_panel(1, _simplex)
	_paint_panel(2, _worley)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_zoff += delta * 0.7
	_paint_all()
