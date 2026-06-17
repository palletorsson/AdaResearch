extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MagnitudeHall

## @identity
## lineage: the room-scale, walk-in end of the Magnitude ladder — a vector arrow that spans the
##   whole hall, its x, y, z components drawn as dashed edges you can pace off along the ground and up.
## essence: |v| = √(x²+y²+z²). The component box is room-sized; walk the x edge, then the y rise, then
##   z, and the diagonal arrow is the length the readout names as the vector slowly sweeps.
## truth: magnitude is how far the arrow would carry you if you walked it.

@export var vcolor: Color = Color(0.55, 0.95, 0.58)
var _rig: Node3D
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
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.08, 7), _matte_mat(Color(0.15, 0.16, 0.2), 0.9)))   # the hall floor
	_rig = Node3D.new(); add_child(_rig)
	_readout = _billboard_label("MAGNITUDE", Vector3(0, 4.2, 0), 30, vcolor.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 0.4
	_redraw()


func _redraw() -> void:
	var v := Vector3(2.6 + sin(_t) * 0.9, 2.0 + sin(_t * 0.8) * 0.8, 2.2 + cos(_t * 0.6) * 0.8)   # room-scale sweep
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	var xc := _glow_mat(Color(0.92, 0.42, 0.42), 1.0)
	var yc := _glow_mat(Color(0.5, 0.92, 0.5), 1.0)
	var zc := _glow_mat(Color(0.5, 0.6, 0.95), 1.0)
	_rig.add_child(_arrow(Vector3.ZERO, v, 0.08, _glow_mat(vcolor, 1.7)))                          # the diagonal you walk
	_rig.add_child(_dashed(Vector3.ZERO, Vector3(v.x, 0, 0), 0.04, xc))                            # x edge along the ground
	_rig.add_child(_dashed(Vector3(v.x, 0, 0), Vector3(v.x, v.y, 0), 0.04, yc))                    # y edge rising
	_rig.add_child(_dashed(Vector3(v.x, v.y, 0), v, 0.04, zc))                                     # z edge to the tip
	if _readout:
		_readout.text = "MAGNITUDE\n|v| = √(x²+y²+z²)\n|v| = %.2f" % v.length()
