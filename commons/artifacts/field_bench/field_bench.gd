extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FieldBench

## @identity
## lineage: the bench-scale opening of the Force field ladder — a 4×4 lattice of little arrows on a
##   tabletop, all pointing one slowly-turning direction, with a test dot that drifts and wraps.
## essence: a field assigns a vector to every point of space. Here every cell carries the same arrow,
##   and a free dot obeys it — the field is the rule, the dot is what the rule does.
## truth: a field is force that has decided to be everywhere at once.

@export var fcolor: Color = Color(0.55, 0.88, 0.72)
var _rig: Node3D
var _readout: Label3D
var _dot: Vector2 = Vector2(-0.7, -0.7)
var _t: float = 0.0
const BASE_Y := 0.9
const HALF := 0.78


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
	_rig = Node3D.new(); _rig.position = Vector3(0, BASE_Y + 0.06, 0); add_child(_rig)
	_readout = _billboard_label("FORCE FIELD", Vector3(0, BASE_Y + 1.9, 0), 25, fcolor.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 0.4
	_dot += Vector2(cos(_t), sin(_t)) * delta * 0.5
	_dot.x = wrapf(_dot.x, -HALF, HALF)
	_dot.y = wrapf(_dot.y, -HALF, HALF)
	_redraw()


func _redraw() -> void:
	var f := Vector3(cos(_t), 0, sin(_t))                        # field direction slowly rotates
	for c in _rig.get_children():
		_rig.remove_child(c); c.queue_free()
	var amat := _glow_mat(fcolor, 1.3)
	for ix in range(4):
		for iz in range(4):
			var p := Vector3(lerpf(-HALF, HALF, ix / 3.0), 0, lerpf(-HALF, HALF, iz / 3.0))
			_rig.add_child(_arrow(p, p + f * 0.28, 0.018, amat))           # a vector at every point
	_rig.add_child(_sphere(Vector3(_dot.x, 0.04, _dot.y), 0.06, _glow_mat(Color(0.98, 0.6, 0.4), 1.8)))   # test dot drifts in the field
	if _readout:
		_readout.text = "FORCE FIELD\nfield = (%.1f, %.1f)\na vector at every point" % [f.x, f.z]
