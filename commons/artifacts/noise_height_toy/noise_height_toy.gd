extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NoiseHeightToy
## @identity
## lineage: the smallest terrain — an 8×8 heightfield you could cup in one hand
## essence: noise read straight as elevation, a palmful of hills breathing slowly
## truth: a landscape is the shortest sentence chaos knows how to write

@export var grid: float = 8.0
@export var amplitude: float = 0.14
@export var cell: float = 0.04

var _noise := FastNoiseLite.new()
var _field: Node3D
var _zoff: float = 0.0


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("amplitude"): amplitude = float(config["amplitude"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.28
	_noise.fractal_octaves = 2
	# tiny base tray
	add_child(_box(Vector3(0, 0.02, 0), Vector3(0.42, 0.04, 0.42), _steel_mat(Color(0.16, 0.18, 0.22))))
	_field = Node3D.new()
	add_child(_field)
	_grow()


func _h(gx: int, gz: int) -> float:
	return (_noise.get_noise_2d(float(gx), float(gz) + _zoff) + 1.0) * 0.5 * amplitude


func _grow() -> void:
	for c in _field.get_children(): _field.remove_child(c); c.queue_free()
	var g: int = int(grid)
	var span: float = 0.36
	for gx in range(g):
		for gz in range(g):
			var hv: float = _h(gx, gz)
			var lx: float = (float(gx) / float(g - 1) - 0.5) * span
			var lz: float = (float(gz) / float(g - 1) - 0.5) * span
			var t: float = clampf(hv / maxf(amplitude, 0.0001), 0.0, 1.0)
			var col: Color = Color(0.25, 0.45, 0.7).lerp(Color(0.6, 1.0, 0.65), t)
			_field.add_child(_box(Vector3(lx, 0.04 + hv, lz), Vector3(cell, 0.03, cell), _glow_mat(col, 0.9 + t)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_zoff += delta * 0.4
	_grow()
