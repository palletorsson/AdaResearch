extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LeverToy

## @identity
## lineage: the tabletop-toy end of the Lever ladder — a little seesaw on a triangular fulcrum with
##   a weight on each side, so the abstract moment becomes a thing you watch rock and settle.
## essence: τ = F·d. Each weight makes a turning effort equal to its force times its distance from
##   the pivot; the beam tilts toward the bigger moment and rests where F₁d₁ meets F₂d₂.
## truth: a lever trades force for distance and never gets something for nothing.

@export var f_left: float = 1.0       # left weight (heavier)
@export var d_left: float = 0.45
@export var f_right: float = 0.6      # right weight (lighter, farther)
@export var d_right: float = 0.6
@export var beam_color: Color = Color(0.62, 0.66, 0.74)
@export var torque_color: Color = Color(0.98, 0.72, 0.32)
var _beam: Node3D
var _readout: Label3D
var _t: float = 0.0
var _ang: float = 0.0
const PIV_Y := 0.55


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, PIV_Y - 0.46, 0), Vector3(1.6, 0.12, 0.7), _matte_mat(Color(0.15, 0.16, 0.2), 0.85)))
	# triangular fulcrum (a thin pyramid box stack) under the pivot
	add_child(_box(Vector3(0, PIV_Y - 0.2, 0), Vector3(0.36, 0.1, 0.18), _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_box(Vector3(0, PIV_Y - 0.08, 0), Vector3(0.18, 0.14, 0.12), _steel_mat(Color(0.34, 0.36, 0.42))))
	add_child(_cylinder(Vector3(0, PIV_Y, 0), 0.06, 0.1, _glow_mat(Color(0.8, 0.82, 0.9), 0.6)))   # pivot hub
	_beam = Node3D.new(); _beam.position = Vector3(0, PIV_Y, 0); add_child(_beam)
	_readout = _billboard_label("LEVER", Vector3(0, PIV_Y + 0.95, 0), 22, torque_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _beam == null:
		return
	_t += delta
	_redraw()


func _redraw() -> void:
	var tau_l: float = f_left * d_left
	var tau_r: float = f_right * d_right
	var imbalance: float = clampf((tau_l - tau_r) * 1.2, -0.5, 0.5)   # tilt toward bigger moment
	var target: float = -imbalance + sin(_t * 2.2) * 0.06            # rock gently, settle near balance
	_ang = lerpf(_ang, target, 0.06)
	_beam.rotation = Vector3(0, 0, _ang)
	for c in _beam.get_children():
		_beam.remove_child(c); c.queue_free()
	_beam.add_child(_cylinder_between(Vector3(-0.7, 0, 0), Vector3(0.7, 0, 0), 0.035, _steel_mat(beam_color)))  # the beam
	# left weight (box) + its torque down-arrow scaled by F·d
	var lp := Vector3(-d_left, 0.04, 0)
	_beam.add_child(_box(lp + Vector3(0, 0.08, 0), Vector3(0.16, 0.16, 0.16) * (0.7 + f_left * 0.5), _glow_mat(torque_color, 1.2)))
	_beam.add_child(_arrow(lp, lp - Vector3(0, 0.18 + tau_l * 0.4, 0), 0.025, _glow_mat(torque_color, 1.4)))
	# right weight (sphere) + its torque down-arrow
	var rp := Vector3(d_right, 0.04, 0)
	_beam.add_child(_sphere(rp + Vector3(0, 0.08, 0), 0.08 * (0.7 + f_right * 0.5), _glow_mat(torque_color.lerp(Color.WHITE, 0.2), 1.2)))
	_beam.add_child(_arrow(rp, rp - Vector3(0, 0.18 + tau_r * 0.4, 0), 0.025, _glow_mat(torque_color.lerp(Color.WHITE, 0.2), 1.4)))
	if _readout:
		_readout.text = "LEVER\nτ = F·d\nF₁d₁ = %.2f  ⇄  F₂d₂ = %.2f" % [tau_l, tau_r]
