extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WorkMeter

## @identity
## lineage: the intimate companion to force_mower for the Work concept — a block on a rail and a
##   force applied at an angle, so you watch only the along-the-ground part do work.
## essence: W = F·d·cosθ. The applied force splits into a useful component along the motion
##   (F cosθ, green) and a wasted component perpendicular to it (F sinθ, grey); raise the angle
##   and the work falls even though you push just as hard.
## truth: the world only feels the part of a force that goes its way.

@export_range(0.0, 80.0, 1.0) var angle: float = 35.0     # degrees above the ground
@export var force_mag: float = 1.2
@export var rail_length: float = 4.0
@export var useful_color: Color = Color(0.55, 0.95, 0.58)
@export var wasted_color: Color = Color(0.72, 0.74, 0.82)
@export var force_color: Color = Color(0.98, 0.72, 0.32)
@export var block_color: Color = Color(0.55, 0.60, 0.72)

var _block: Node3D
var _vectors: Node3D
var _readout: Label3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("angle"): angle = clampf(float(config["angle"]), 0.0, 80.0)
	if config.has("force_mag"): force_mag = float(config["force_mag"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var steel := _steel_mat(Color(0.3, 0.32, 0.38))
	add_child(_box(Vector3(rail_length * 0.5, -0.05, 0), Vector3(rail_length + 0.6, 0.1, 0.8), _matte_mat(Color(0.16, 0.17, 0.2), 0.9)))
	for i in range(int(rail_length) + 1):                      # distance ticks
		add_child(_box(Vector3(float(i), 0.01, 0), Vector3(0.03, 0.05, 0.7), _glow_mat(Color(0.4, 0.42, 0.5), 0.4)))
	_block = Node3D.new(); add_child(_block)
	_block.add_child(_box(Vector3(0, 0.3, 0), Vector3(0.5, 0.6, 0.6), _glow_mat(block_color, 0.6)))
	_vectors = Node3D.new(); add_child(_vectors)
	_readout = _billboard_label("WORK", Vector3(rail_length * 0.5, 1.9, 0), 28, useful_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw(0.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _block == null:
		return
	_t += delta * 0.45
	_redraw(fmod(_t, 1.0))


func _redraw(frac: float) -> void:
	var theta: float = deg_to_rad(angle)
	var x: float = frac * rail_length
	_block.position = Vector3(x, 0, 0)
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var origin := Vector3(x, 0.3, 0)
	var dir := Vector3(cos(theta), sin(theta), 0)
	_vectors.add_child(_arrow(origin, origin + dir * (1.1 * force_mag), 0.05, _glow_mat(force_color, 1.4)))                  # applied force F
	_vectors.add_child(_arrow(origin, origin + Vector3(cos(theta), 0, 0) * (1.1 * force_mag), 0.055, _glow_mat(useful_color, 1.7)))  # useful = F cosθ
	_vectors.add_child(_arrow(origin + Vector3(cos(theta), 0, 0) * (1.1 * force_mag), origin + dir * (1.1 * force_mag), 0.03, _glow_mat(wasted_color, 0.7)))  # wasted = F sinθ
	var W: float = force_mag * cos(theta) * x
	if _readout:
		_readout.text = "WORK\nW = F·d·cosθ\nθ = %d°   cosθ = %.2f   d = %.1f\nW = %.2f" % [int(angle), cos(theta), x, W]
