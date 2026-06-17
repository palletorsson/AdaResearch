extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NoiseDunesBench
## @identity
## lineage: FastNoiseLite height field → tabletop dunes diorama
## essence: noise read as elevation builds drifting sand ridges on the bench
## truth: the same number that was static becomes a hill, then a wind.

@export var cols: int = 20
@export var rows: int = 14
@export var dune_height: float = 0.26
@export var noise_scale: float = 0.18

var _noise := FastNoiseLite.new()
var _scroll: float = 0.0
var _field: Node3D


func _ready() -> void:
	_rng.randomize()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = noise_scale
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	# Bench: base box ~1.1 wide, top at y≈0.85, short pillar.
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.15, 0.2, 0.9), _matte_mat(Color(0.16, 0.15, 0.18))))
	add_child(_cylinder(Vector3(0, 0.5, 0), 0.07, 0.6, _steel_mat(Color(0.4, 0.42, 0.46))))
	add_child(_box(Vector3(0, 0.83, 0), Vector3(1.0, 0.04, 0.78), _matte_mat(Color(0.22, 0.2, 0.24))))
	# Two little dials suggesting scale + height.
	add_child(_cylinder(Vector3(-0.42, 0.9, 0.3), 0.05, 0.04, _steel_mat(Color(0.6, 0.62, 0.66))))
	add_child(_cylinder(Vector3(-0.42, 0.92, 0.3), 0.012, 0.05, _glow_mat(Color(0.9, 0.7, 0.3), 2.0)))
	add_child(_cylinder(Vector3(0.42, 0.9, 0.3), 0.05, 0.04, _steel_mat(Color(0.6, 0.62, 0.66))))
	add_child(_cylinder(Vector3(0.42, 0.92, 0.3), 0.012, 0.05, _glow_mat(Color(0.4, 0.8, 0.9), 2.0)))
	# The landscape of small boxes, height from noise, faces +Z.
	_field = Node3D.new()
	add_child(_field)
	_render_dunes()
	add_child(_billboard_label("noise = height", Vector3(0, 1.62, 0), 30, Color(0.95, 0.85, 0.6)))


func _render_dunes() -> void:
	for c in _field.get_children(): _field.remove_child(c); c.queue_free()
	var top_y: float = 0.86
	var sx: float = 0.85 / float(cols)
	var sz: float = 0.66 / float(rows)
	for ix in range(cols):
		for iz in range(rows):
			var x: float = (float(ix) - float(cols) * 0.5 + 0.5) * sx
			var z: float = (float(iz) - float(rows) * 0.5 + 0.5) * sz
			var h: float = (_noise.get_noise_2d(float(ix) + _scroll, float(iz)) * 0.5 + 0.5)
			var col_h: float = 0.03 + h * dune_height
			var sand := Color(0.78, 0.66, 0.42).lerp(Color(0.95, 0.92, 0.82), h)
			_field.add_child(_box(Vector3(x, top_y + col_h * 0.5, z), Vector3(sx * 0.92, col_h, sz * 0.92), _matte_mat(sand, 0.9)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_scroll += delta * 0.6
	_render_dunes()
