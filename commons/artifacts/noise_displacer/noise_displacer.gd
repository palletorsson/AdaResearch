extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NoiseDisplacer
## @identity
## lineage: a displacement tool — simplex field pushes a flat grid into rolling hills
## essence: the surface is already heaving, the dial sets how far the field can lift it
## truth: terrain is just a plane that agreed to remember a function

@export var grid: float = 16.0
@export var amplitude: float = 0.32
@export var cell: float = 0.07

var _noise := FastNoiseLite.new()
var _surface: Node3D
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
	_noise.frequency = 0.14
	_noise.fractal_octaves = 3
	# device base plate
	add_child(_box(Vector3(0, 0.04, 0), Vector3(1.5, 0.08, 1.5), _steel_mat(Color(0.18, 0.2, 0.24))))
	# amplitude dial on a stand beside it
	add_child(_cylinder(Vector3(0.95, 0.25, 0.55), 0.04, 0.5, _steel_mat(Color(0.16, 0.17, 0.2))))
	add_child(_torus(Vector3(0.95, 0.5, 0.55), 0.11, 0.03, _glow_mat(Color(1.0, 0.75, 0.3), 1.8)))
	add_child(_cylinder_between(Vector3(0.95, 0.5, 0.55), Vector3(0.95 + 0.09 * amplitude * 2.0, 0.5, 0.55 + 0.06), 0.012, _glow_mat(Color(1.0, 0.9, 0.5), 2.2)))
	add_child(_billboard_label("amplitude", Vector3(0.95, 0.68, 0.55), 18, Color(1.0, 0.85, 0.5)))
	add_child(_billboard_label("Simplex / Worley / value noise", Vector3(0, 0.95, 0), 24, Color(0.8, 0.95, 0.9)))
	_surface = Node3D.new()
	add_child(_surface)
	_displace()


func _h(gx: int, gz: int) -> float:
	return _noise.get_noise_2d(float(gx) * 1.2, (float(gz) + _zoff) * 1.2) * amplitude


func _displace() -> void:
	for c in _surface.get_children(): _surface.remove_child(c); c.queue_free()
	var g: int = int(grid)
	var span: float = 1.3
	for gx in range(g):
		for gz in range(g):
			var hv: float = _h(gx, gz)
			var lx: float = (float(gx) / float(g - 1) - 0.5) * span
			var lz: float = (float(gz) / float(g - 1) - 0.5) * span
			var t: float = clampf((hv / amplitude) * 0.5 + 0.5, 0.0, 1.0)
			var col: Color = Color(0.2, 0.4, 0.65).lerp(Color(0.55, 0.95, 0.6), t)
			_surface.add_child(_box(Vector3(lx, 0.1 + hv, lz), Vector3(cell, 0.05, cell), _glow_mat(col, 0.8 + t)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_zoff += delta * 0.6
	_displace()
