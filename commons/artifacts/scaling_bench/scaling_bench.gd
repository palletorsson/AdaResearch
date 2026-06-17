extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ScalingBench

## @identity
## lineage: the bench-scale middle of the Scaling ladder — a fixed ghost vector and a live output
##   arrow that is k times it, so you watch length change while the line stays put.
## essence: output = k·v. Scaling a vector only stretches or shrinks it along its own line; the
##   direction never moves. A dial tracks k so the knob and the arrow tell the same story.
## truth: a scalar is a volume knob for a direction.

@export var base_vec: Vector3 = Vector3(0.9, 0, 0.6)
@export var vcolor: Color = Color(0.98, 0.78, 0.42)
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
	add_child(_box(Vector3(0, BASE_Y - 0.1, 0), Vector3(2.2, 0.2, 2.2), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))   # the bench
	add_child(_cylinder(Vector3(0, BASE_Y * 0.5, 0), 0.12, BASE_Y - 0.2, _steel_mat(Color(0.3, 0.32, 0.38))))
	_rig = Node3D.new(); _rig.position = Vector3(0, BASE_Y + 0.12, 0); add_child(_rig)
	_readout = _billboard_label("SCALING", Vector3(0, BASE_Y + 1.9, 0), 25, vcolor.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 0.7
	_redraw()


func _redraw() -> void:
	var k: float = 1.45 + sin(_t) * 1.15                         # k oscillates ~0.3..2.6
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	_rig.add_child(_arrow(Vector3.ZERO, base_vec, 0.04, _glow_mat(Color(0.55, 0.58, 0.66), 0.4)))   # faint ghost base v
	_rig.add_child(_arrow(Vector3.ZERO, base_vec * k, 0.05, _glow_mat(vcolor, 1.7)))                 # output = k·v, same line
	var dial := Vector3(-0.85, 0, -0.7)
	_rig.add_child(_cylinder(dial, 0.16, 0.06, _steel_mat(Color(0.32, 0.34, 0.4))))                  # the dial
	var pdir := Vector3(cos(k * 1.6), 0, sin(k * 1.6))
	_rig.add_child(_box(dial + pdir * 0.1, Vector3(0.14, 0.05, 0.03), _glow_mat(vcolor, 1.5)))       # pointer tracks k
	if _readout:
		_readout.text = "SCALING\noutput = k × v\nk = %.2f  (same line, new length)" % k
