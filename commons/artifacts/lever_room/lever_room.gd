extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LeverRoom

## @identity
## lineage: the room-scale, walk-in end of the Lever ladder — a balance beam longer than you are tall
##   on a fulcrum post you stand beside, with a heavy weight near the pivot and a light one far out.
## essence: F₁d₁ = F₂d₂. Distance multiplies force; a small weight far from the pivot balances a big
##   weight close in. The beam tips slowly and settles where the two moments are equal.
## truth: far out, a small weight outweighs a big one near in — a lever is leverage.

@export var f_near: float = 2.2       # heavy weight, near the pivot
@export var d_near: float = 0.9
@export var f_far: float = 0.8        # light weight, far out
@export var d_far: float = 2.5
@export var beam_color: Color = Color(0.62, 0.66, 0.74)
@export var arrow_color: Color = Color(0.55, 0.92, 1.0)
var _beam: Node3D
var _readout: Label3D
var _t: float = 0.0
var _ang: float = 0.0
const PIV_Y := 2.6


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var steel := _steel_mat(Color(0.34, 0.36, 0.42))
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.08, 4), _matte_mat(Color(0.16, 0.17, 0.2), 0.9)))
	add_child(_cylinder(Vector3(0, PIV_Y * 0.5, 0), 0.18, PIV_Y, steel))                  # tall fulcrum post
	add_child(_cylinder(Vector3(0, PIV_Y, 0), 0.16, 0.22, _glow_mat(Color(0.8, 0.82, 0.9), 0.6)))  # pivot hub
	_beam = Node3D.new(); _beam.position = Vector3(0, PIV_Y, 0); add_child(_beam)
	_readout = _billboard_label("BALANCE BEAM", Vector3(0, PIV_Y + 1.6, 0), 30, arrow_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _beam == null:
		return
	_t += delta
	_redraw()


func _redraw() -> void:
	var tau_near: float = f_near * d_near
	var tau_far: float = f_far * d_far
	var imbalance: float = clampf((tau_near - tau_far) * 0.06, -0.22, 0.22)   # tip toward bigger moment
	var target: float = -imbalance + sin(_t * 0.9) * 0.04                    # settle slowly, rock gently
	_ang = lerpf(_ang, target, 0.03)
	_beam.rotation = Vector3(0, 0, _ang)
	for c in _beam.get_children():
		_beam.remove_child(c); c.queue_free()
	_beam.add_child(_cylinder_between(Vector3(-2.9, 0, 0), Vector3(2.9, 0, 0), 0.1, _steel_mat(beam_color)))  # the long beam
	var rope := _steel_mat(Color(0.4, 0.42, 0.48))
	# heavy weight near the pivot, hanging below the beam
	var np := Vector3(-d_near, 0, 0)
	_beam.add_child(_cylinder_between(np, np - Vector3(0, 0.4, 0), 0.03, rope))
	_beam.add_child(_box(np - Vector3(0, 0.65, 0), Vector3(0.45, 0.5, 0.45) * (0.6 + f_near * 0.18), _glow_mat(arrow_color, 1.1)))
	_beam.add_child(_arrow(np - Vector3(0, 0.4, 0), np - Vector3(0, 0.4 + tau_near * 0.2, 0), 0.05, _glow_mat(arrow_color, 1.4)))
	# light weight far out, hanging below the beam
	var fp := Vector3(d_far, 0, 0)
	_beam.add_child(_cylinder_between(fp, fp - Vector3(0, 0.4, 0), 0.03, rope))
	_beam.add_child(_sphere(fp - Vector3(0, 0.6, 0), 0.22 * (0.6 + f_far * 0.5), _glow_mat(arrow_color.lerp(Color.WHITE, 0.2), 1.1)))
	_beam.add_child(_arrow(fp - Vector3(0, 0.4, 0), fp - Vector3(0, 0.4 + tau_far * 0.2, 0), 0.05, _glow_mat(arrow_color.lerp(Color.WHITE, 0.2), 1.4)))
	if _readout:
		_readout.text = "BALANCE BEAM\nF₁d₁ = F₂d₂\n%.1f·%.1f = %.2f   ⇄   %.1f·%.1f = %.2f" % [f_near, d_near, tau_near, f_far, d_far, tau_far]
