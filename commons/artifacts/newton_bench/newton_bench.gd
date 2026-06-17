extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NewtonBench

## @identity
## lineage: the bench-scale middle of the General force ladder — a mass on a table, a force pushing
##   it, and the acceleration it produces. Newton's second law you can dial.
## essence: F = m·a, so a = F/m. Push the same mass harder and it accelerates more; the output arrow
##   tracks the input divided by the mass. The cleanest statement of what a force *does*.
## truth: a force is a vector applied to a mass — and the mass answers with acceleration.

@export var mass: float = 1.4
@export var force_color: Color = Color(0.98, 0.72, 0.32)
@export var accel_color: Color = Color(0.55, 0.95, 0.58)
@export var mass_color: Color = Color(0.6, 0.64, 0.76)
var _vectors: Node3D
var _readout: Label3D
var _t: float = 0.0
const BASE_Y := 0.9


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("mass"): mass = maxf(0.3, float(config["mass"]))
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, BASE_Y - 0.1, 0), Vector3(2.6, 0.2, 1.6), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))
	add_child(_cylinder(Vector3(0, BASE_Y * 0.5, 0), 0.12, BASE_Y - 0.2, _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_box(Vector3(0, BASE_Y + 0.3, 0), Vector3(0.6, 0.6, 0.6), _glow_mat(mass_color, 0.6)))   # the mass
	add_child(_billboard_label("m", Vector3(0, BASE_Y + 0.3, 0), 22, Color(0.85, 0.88, 0.95)))
	_vectors = Node3D.new(); add_child(_vectors)
	_readout = _billboard_label("FORCE", Vector3(0, BASE_Y + 1.7, 0), 25, accel_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _vectors == null:
		return
	_t += delta
	_redraw()


func _redraw() -> void:
	var F: float = 1.3 + sin(_t * 0.9) * 0.9        # the applied force breathes
	var a: float = F / mass
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var o := Vector3(0, BASE_Y + 0.3, 0)
	_vectors.add_child(_arrow(o - Vector3(0.3, 0, 0), o - Vector3(0.3, 0, 0) + Vector3(F * 0.7, 0, 0), 0.05, _glow_mat(force_color, 1.5)))   # F (input)
	_vectors.add_child(_arrow(o + Vector3(0.3, 0.5, 0), o + Vector3(0.3, 0.5, 0) + Vector3(a * 0.7, 0, 0), 0.05, _glow_mat(accel_color, 1.7)))  # a = F/m (output)
	if _readout:
		_readout.text = "FORCE\nF = m · a   →   a = F/m\nF = %.2f   m = %.1f   →   a = %.2f" % [F, mass, a]
