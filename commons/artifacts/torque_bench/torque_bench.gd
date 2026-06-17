extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TorqueBench

## @identity
## lineage: the bench-scale middle of the Cross product / torque ladder — a lever on a pivot and a
##   force at its end, so you watch the turning depend on the angle.
## essence: τ = r × F = |r||F| sin θ. Push along the arm and nothing turns; push across it and it
##   spins hardest. Only the perpendicular part of the force makes torque.
## truth: the cross product is the turn left over when two directions disagree.

@export var arm: float = 1.3
@export var arm_color: Color = Color(0.62, 0.66, 0.74)
@export var force_color: Color = Color(0.98, 0.72, 0.32)
@export var perp_color: Color = Color(0.55, 0.95, 0.58)
var _rig: Node3D
var _readout: Label3D
var _t: float = 0.0
const BASE_Y := 0.9


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, BASE_Y - 0.1, 0), Vector3(2.4, 0.2, 2.0), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))
	add_child(_cylinder(Vector3(0, BASE_Y * 0.5, 0), 0.12, BASE_Y - 0.2, _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_cylinder(Vector3(0, BASE_Y, 0), 0.1, 0.16, _glow_mat(Color(0.8, 0.82, 0.9), 0.6)))   # pivot hub
	_rig = Node3D.new(); _rig.position = Vector3(0, BASE_Y + 0.12, 0); add_child(_rig)
	_readout = _billboard_label("TORQUE", Vector3(0, BASE_Y + 1.9, 0), 25, force_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 0.7
	_redraw()


func _redraw() -> void:
	var theta: float = deg_to_rad(40.0 + sin(_t) * 45.0)        # the force angle to the arm sweeps
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	var end := Vector3(arm, 0, 0)
	_rig.add_child(_cylinder_between(Vector3.ZERO, end, 0.045, _steel_mat(arm_color)))               # the arm r
	var fdir := Vector3(cos(theta), 0, sin(theta))
	_rig.add_child(_arrow(end, end + fdir * 1.0, 0.05, _glow_mat(force_color, 1.5)))                  # force F at angle θ
	_rig.add_child(_arrow(end, end + Vector3(0, 0, sin(theta)) * 1.0, 0.05, _glow_mat(perp_color, 1.7)))  # perpendicular part = F sinθ (makes torque)
	var tau: float = arm * 1.0 * abs(sin(theta))
	if _readout:
		_readout.text = "TORQUE\nτ = |r||F| sin θ\nθ = %d°   →   τ = %.2f" % [int(rad_to_deg(theta)), tau]
