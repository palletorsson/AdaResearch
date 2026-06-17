extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ThrottleGain

## @identity
## lineage: the applied face of Scaling — a throttle. One base thrust, and a knob that multiplies it
##   by a factor k; the output is the same direction, a different size.
## essence: a scalar × vector keeps the line and changes the length. Open the throttle and the thrust
##   arrow grows along its own axis; close it and it shrinks — never turning, only scaling.
## truth: a scalar is a volume knob for a direction.

@export var thrust_dir: Vector3 = Vector3(0.30, 0.95, 0.0)
@export var base_color: Color = Color(0.55, 0.6, 0.72)
@export var out_color: Color = Color(0.98, 0.72, 0.32)
var _vectors: Node3D
var _dial: Node3D
var _readout: Label3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var steel := _steel_mat(Color(0.32, 0.34, 0.4))
	add_child(_box(Vector3(0, 0.1, 0), Vector3(0.9, 0.2, 0.9), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))   # thruster base
	add_child(_cylinder(Vector3(0, 0.35, 0), 0.18, 0.4, steel))
	add_child(_arrow(Vector3(0, 0.55, 0), Vector3(0, 0.55, 0) + thrust_dir.normalized() * 1.0, 0.03, _glow_mat(base_color, 0.8)))  # base unit thrust (ghost)
	_dial = Node3D.new(); _dial.position = Vector3(1.4, 0.4, 0); add_child(_dial)                            # the throttle knob
	_dial.add_child(_cylinder(Vector3.ZERO, 0.3, 0.12, steel))
	_dial.add_child(_box(Vector3(0, 0.08, 0.22), Vector3(0.06, 0.04, 0.18), _glow_mat(out_color, 1.4)))      # the pointer
	_vectors = Node3D.new(); add_child(_vectors)
	_readout = _billboard_label("THROTTLE", Vector3(0, 2.2, 0), 26, out_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _vectors == null:
		return
	_t += delta
	_redraw()


func _redraw() -> void:
	var k: float = 1.5 + sin(_t * 0.8) * 1.1        # throttle 0.4 .. 2.6
	if _dial: _dial.rotation.y = (k - 1.5) * 1.4
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var o := Vector3(0, 0.55, 0)
	_vectors.add_child(_arrow(o, o + thrust_dir.normalized() * k, 0.055, _glow_mat(out_color, 1.7)))   # output = k × thrust
	if _readout:
		_readout.text = "THROTTLE\noutput = k × thrust\nk = %.2f   (same line, new length)" % k
