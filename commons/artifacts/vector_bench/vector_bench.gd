extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VectorBench

## @identity
## lineage: the bench-scale opening of the Vector ladder — a tabletop arrow that sweeps both its
##   direction and its length so you read the two facts of a vector at once.
## essence: a vector carries exactly two things — where it points and how far it reaches. The x and
##   y component segments draw the journey; the arrow is the journey itself; the readout is both facts.
## truth: a vector is a journey with no starting address — only a direction and a length.

@export var vcolor: Color = Color(0.55, 0.85, 0.98)
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
	_readout = _billboard_label("VECTOR", Vector3(0, BASE_Y + 1.9, 0), 25, vcolor.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 0.5
	_redraw()


func _redraw() -> void:
	var ang: float = _t                                          # direction sweeps
	var mag: float = 1.0 + (sin(_t * 0.7) + 1.0) * 0.45          # length breathes ~1.0..1.9
	var v := Vector3(cos(ang), 0, sin(ang)) * mag
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	var xc := _glow_mat(Color(0.92, 0.42, 0.42), 1.0)
	var yc := _glow_mat(Color(0.5, 0.92, 0.5), 1.0)
	_rig.add_child(_arrow(Vector3.ZERO, v, 0.05, _glow_mat(vcolor, 1.7)))           # the vector — a direction and a length
	_rig.add_child(_dashed(Vector3.ZERO, Vector3(v.x, 0, 0), 0.02, xc))            # x component
	_rig.add_child(_dashed(Vector3(v.x, 0, 0), v, 0.02, yc))                       # y component
	var deg: int = int(rad_to_deg(fposmod(ang, TAU)))
	if _readout:
		_readout.text = "VECTOR\n|v| = %.2f   ∠%d°\n(%.1f, %.1f)" % [v.length(), deg, v.x, v.z]
