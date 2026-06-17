extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ProjectionToy

## @identity
## lineage: the small, hand-scale end of the Projection ladder — a vector v and a rail along n̂, with
##   v's shadow lying on the rail and the perpendicular gap drawn dashed back up to v's tip.
## essence: proj = (v · n̂) n̂. The green arrow is the part of v that lies along the line; the grey
##   dashes are the rejection, the part that doesn't; swing v and watch the shadow grow and shrink.
## truth: projection is the part of you that lives along someone else's line.

@export var ncolor: Color = Color(0.5, 0.6, 0.95)
var _rig: Node3D
var _readout: Label3D
var _t: float = 0.0
const RAIL := 1.4


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, -0.05, 0), Vector3(2, 0.08, 2), _matte_mat(Color(0.15, 0.16, 0.2), 0.9)))   # small base
	_rig = Node3D.new(); _rig.position = Vector3(0, 0.1, 0); add_child(_rig)
	_readout = _billboard_label("PROJECTION", Vector3(0, 1.9, 0), 22, Color(0.5, 0.92, 0.5).lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 0.7
	_redraw()


func _redraw() -> void:
	var nhat := Vector3(1, 0, 0)                                        # the rail direction n̂
	var ang: float = lerpf(deg_to_rad(85.0), deg_to_rad(8.0), 0.5 + 0.5 * sin(_t))   # v swings toward the rail
	var v := Vector3(cos(ang), sin(ang), 0) * RAIL
	var s: float = v.dot(nhat)                                          # scalar projection
	var proj: Vector3 = nhat * s                                        # the shadow on the rail
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	_rig.add_child(_cylinder_between(Vector3(-RAIL, 0, 0), Vector3(RAIL, 0, 0), 0.012, _glow_mat(ncolor, 0.9)))   # the rail (line along n̂)
	_rig.add_child(_arrow(Vector3.ZERO, v, 0.03, _glow_mat(Color(0.4, 0.9, 0.95), 1.7)))               # v (cyan)
	_rig.add_child(_arrow(Vector3.ZERO, proj, 0.03, _glow_mat(Color(0.5, 0.92, 0.5), 1.7)))            # projection (green shadow)
	_rig.add_child(_dashed(proj, v, 0.02, _glow_mat(Color(0.7, 0.7, 0.7), 0.6)))                       # rejection (grey perpendicular)
	if _readout:
		_readout.text = "PROJECTION\nproj = (v · n̂) n̂\nthe part of v along the line = %.2f" % s
