extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MagnitudeBench

## @identity
## lineage: the bench-scale middle of the Magnitude ladder — a tabletop vector whose x, y, z
##   components draw the box whose diagonal is its length.
## essence: |v| = √(x²+y²+z²). The three component edges build a box; the arrow is its space
##   diagonal, and the readout is that diagonal's length as the components breathe.
## truth: magnitude is the Pythagorean diagonal of the components.

@export var vec: Vector3 = Vector3(1.5, 1.0, 0.9)
@export var vcolor: Color = Color(0.55, 0.95, 0.58)
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
	_rig = Node3D.new(); _rig.position = Vector3(0, BASE_Y, 0); add_child(_rig)
	_readout = _billboard_label("MAGNITUDE", Vector3(0, BASE_Y + 2.0, 0), 25, vcolor.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 0.6
	_redraw()


func _redraw() -> void:
	var v := Vector3(1.4 + sin(_t) * 0.5, 1.0 + sin(_t * 0.8) * 0.4, 0.9 + cos(_t * 0.6) * 0.4)
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	var xc := _glow_mat(Color(0.92, 0.42, 0.42), 1.0)
	var yc := _glow_mat(Color(0.5, 0.92, 0.5), 1.0)
	var zc := _glow_mat(Color(0.5, 0.6, 0.95), 1.0)
	_rig.add_child(_arrow(Vector3.ZERO, v, 0.05, _glow_mat(vcolor, 1.7)))                          # the vector (space diagonal)
	_rig.add_child(_dashed(Vector3.ZERO, Vector3(v.x, 0, 0), 0.02, xc))                            # x edge
	_rig.add_child(_dashed(Vector3(v.x, 0, 0), Vector3(v.x, v.y, 0), 0.02, yc))                    # y edge
	_rig.add_child(_dashed(Vector3(v.x, v.y, 0), v, 0.02, zc))                                     # z edge
	if _readout:
		_readout.text = "MAGNITUDE\n|v| = √(x²+y²+z²)\n(%.1f, %.1f, %.1f)  →  |v| = %.2f" % [v.x, v.y, v.z, v.length()]
