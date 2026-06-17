extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NoiseTerrainForge
## @identity
## lineage: noise field → stamping head → freshly-pressed walkable heightfield
## essence: a tool that presses noise down into ground, caught mid-stamp
## truth: terrain is not found, it is forged — one stamp of pure number.

@export var grid: int = 14
@export var tile_span: float = 1.0
@export var max_height: float = 0.45

var _noise := FastNoiseLite.new()
var _scroll: float = 0.0
var _rise: float = 0.0
var _patch: Node3D
var _emitter: MeshInstance3D


func _ready() -> void:
	_rng.randomize()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.16
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_rise = 0.55
	# Arm + glowing emitter head pressing down toward the patch.
	add_child(_box(Vector3(-0.7, 0.05, -0.3), Vector3(0.3, 0.1, 0.3), _matte_mat(Color(0.18, 0.18, 0.2))))
	add_child(_cylinder(Vector3(-0.7, 0.55, -0.3), 0.05, 1.0, _steel_mat(Color(0.45, 0.47, 0.5))))
	add_child(_cylinder_between(Vector3(-0.7, 1.0, -0.3), Vector3(0.0, 0.95, 0.0), 0.045, _steel_mat(Color(0.5, 0.52, 0.55))))
	add_child(_box(Vector3(0.0, 0.78, 0.0), Vector3(0.5, 0.14, 0.5), _steel_mat(Color(0.35, 0.36, 0.4))))
	_emitter = _box(Vector3(0.0, 0.68, 0.0), Vector3(0.42, 0.05, 0.42), _glow_mat(Color(1.0, 0.55, 0.2), 4.0))
	add_child(_emitter)
	# The freshly-stamped heightfield patch in front, mid-generation.
	_patch = Node3D.new()
	add_child(_patch)
	_render_patch()
	add_child(_billboard_label("forge: noise → ground", Vector3(0, 1.35, 0), 26, Color(1.0, 0.7, 0.4)))


func _render_patch() -> void:
	for c in _patch.get_children(): _patch.remove_child(c); c.queue_free()
	var s: float = tile_span / float(grid)
	for ix in range(grid):
		for iz in range(grid):
			var x: float = (float(ix) - float(grid) * 0.5 + 0.5) * s
			var z: float = (float(iz) - float(grid) * 0.5 + 0.5) * s
			var h: float = (_noise.get_noise_2d(float(ix) + _scroll, float(iz)) * 0.5 + 0.5)
			# Cells nearer the emitter centre still rising via _rise gate.
			var d: float = clampf(1.0 - Vector2(x, z).length() * 1.4, 0.0, 1.0)
			var grown: float = clampf(_rise + (1.0 - d), 0.0, 1.0)
			var col_h: float = 0.02 + h * max_height * grown
			var ground := Color(0.3, 0.45, 0.28).lerp(Color(0.62, 0.7, 0.5), h)
			if grown < 0.98:
				ground = ground.lerp(Color(1.0, 0.6, 0.25), 0.5 * (1.0 - grown))
			_patch.add_child(_box(Vector3(x, 0.03 + col_h * 0.5, z), Vector3(s * 0.92, col_h, s * 0.92), _matte_mat(ground, 0.85)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_rise = minf(_rise + delta * 0.3, 1.0)
	_scroll += delta * 0.35
	if _rise >= 1.0:
		_rise = 0.45
		_scroll += 3.0
	if _emitter:
		_emitter.position.y = 0.66 + sin(Time.get_ticks_msec() * 0.004) * 0.02
	_render_patch()
