extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WorkToy

## @identity
## lineage: the hand-scale toy on the Work ladder — a little block on a short rail and a force
##   tugged at an angle, so you watch only the along-the-ground part actually do the pushing.
## essence: W = F·d·cosθ. The applied force (orange) splits into a useful component along the
##   ground (F cosθ, green) and a wasted vertical part (F sinθ, grey); the readout counts the
##   work the block earns as it slides, all of it from the green part alone.
## truth: the world only feels the part of a force that goes its way.

@export_range(0.0, 80.0, 1.0) var angle: float = 30.0     # degrees above the ground
@export var force_mag: float = 0.55
@export var rail_length: float = 1.0
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
	var half: float = rail_length * 0.5
	add_child(_box(Vector3(0, -0.04, 0), Vector3(rail_length + 0.3, 0.08, 0.4), _matte_mat(Color(0.16, 0.17, 0.2), 0.9)))
	for i in range(3):                                          # short distance ticks
		var tx: float = lerpf(-half, half, float(i) / 2.0)
		add_child(_box(Vector3(tx, 0.01, 0), Vector3(0.02, 0.04, 0.36), _glow_mat(Color(0.4, 0.42, 0.5), 0.4)))
	_block = Node3D.new(); add_child(_block)
	_block.add_child(_box(Vector3(0, 0.14, 0), Vector3(0.26, 0.28, 0.3), _glow_mat(block_color, 0.6)))
	_vectors = Node3D.new(); add_child(_vectors)
	_readout = _billboard_label("WORK", Vector3(0, 0.85, 0), 26, useful_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _block == null:
		return
	_t += delta * 0.4
	_redraw()


func _redraw() -> void:
	var frac: float = fmod(_t, 1.0)
	var half: float = rail_length * 0.5
	var theta: float = deg_to_rad(angle)
	var x: float = lerpf(-half, half, frac)
	_block.position = Vector3(x, 0, 0)
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var origin := Vector3(x, 0.14, 0)
	var dir := Vector3(cos(theta), sin(theta), 0)
	var tip: Vector3 = origin + dir * force_mag
	var useful: Vector3 = origin + Vector3(cos(theta), 0, 0) * force_mag
	_vectors.add_child(_arrow(origin, tip, 0.025, _glow_mat(force_color, 1.4)))                      # applied force F
	_vectors.add_child(_arrow(origin, useful, 0.028, _glow_mat(useful_color, 1.7)))                 # useful = F cosθ
	_vectors.add_child(_arrow(useful, tip, 0.016, _glow_mat(wasted_color, 0.7)))                    # wasted = F sinθ
	var W: float = force_mag * cos(theta) * (x + half)
	if _readout:
		_readout.text = "WORK\nW = F·d·cosθ\nθ = %d°   cosθ = %.2f\nW = %.2f" % [int(angle), cos(theta), W]
