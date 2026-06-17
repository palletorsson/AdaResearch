extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PerlinBench
## @identity
## lineage: gradient noise on a bench — Ken Perlin's smooth scalar field, sampled along one line
## essence: a coherent 1D curve flows across a panel, a marker riding its crest
## truth: between order and chaos the gradient remembers its neighbours

@export var octaves: float = 3.0
@export var segments: float = 48.0
@export var amplitude: float = 0.35

var _noise := FastNoiseLite.new()
var _ribbon: Node3D
var _marker: MeshInstance3D
var _offset: float = 0.0
var _ribbon_mat: StandardMaterial3D
var _marker_mat: StandardMaterial3D


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("octaves"): octaves = float(config["octaves"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.16
	_noise.fractal_octaves = int(octaves)
	_ribbon_mat = _glow_mat(Color(0.45, 0.8, 1.0), 1.6)
	_marker_mat = _glow_mat(Color(1.0, 0.7, 0.25), 2.4)
	# bench
	add_child(_box(Vector3(0, 0.75, 0), Vector3(1.7, 0.2, 0.7), _steel_mat(Color(0.2, 0.22, 0.26))))
	add_child(_cylinder(Vector3(0, 0.42, 0), 0.08, 0.66, _steel_mat(Color(0.16, 0.17, 0.2))))
	# back panel the curve flows across
	add_child(_box(Vector3(0, 1.2, -0.28), Vector3(1.5, 0.7, 0.04), _matte_mat(Color(0.07, 0.08, 0.11))))
	# octave dial + label
	add_child(_torus(Vector3(-0.62, 1.2, -0.24), 0.1, 0.025, _glow_mat(Color(0.6, 1.0, 0.7), 1.2)))
	add_child(_billboard_label("octaves %d" % int(octaves), Vector3(-0.62, 1.42, -0.2), 22, Color(0.7, 1.0, 0.8)))
	add_child(_billboard_label("Perlin noise", Vector3(0, 1.62, -0.2), 30, Color(0.7, 0.9, 1.0)))
	_ribbon = Node3D.new()
	add_child(_ribbon)
	_marker = _sphere(Vector3(0, 1.2, -0.24), 0.05, _marker_mat)
	add_child(_marker)
	_rebuild_ribbon()


func _sample(x: float) -> float:
	return _noise.get_noise_2d((x + _offset) * 3.0, 0.0) * amplitude


func _rebuild_ribbon() -> void:
	for c in _ribbon.get_children(): _ribbon.remove_child(c); c.queue_free()
	var n: int = int(segments)
	var half: float = 0.7
	var prev := Vector3(-half, 1.2 + _sample(-half), -0.24)
	for i in range(1, n + 1):
		var t: float = float(i) / float(n)
		var x: float = -half + t * (half * 2.0)
		var p := Vector3(x, 1.2 + _sample(x), -0.24)
		_ribbon.add_child(_cylinder_between(prev, p, 0.018, _ribbon_mat))
		prev = p
	if _marker:
		var mx: float = -half + (fmod(_offset * 0.5, 1.0)) * (half * 2.0)
		_marker.position = Vector3(mx, 1.2 + _sample(mx) + 0.04, -0.22)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_offset += delta * 0.25
	_rebuild_ribbon()
