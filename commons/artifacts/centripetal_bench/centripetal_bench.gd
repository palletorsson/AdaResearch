extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CentripetalBench

## @identity
## lineage: the bench-scale middle of the Centripetal ladder — a tabletop turntable, a mass on a
##   tether circling a hub, sized to stand at rather than walk inside (that is centrifuge_ring).
## essence: velocity is always tangent, the force always inward; a = v²/r. The inward arrow is the
##   only thing bending the straight line into a circle.
## truth: going in a circle is constant acceleration toward a centre you never reach.

@export var radius: float = 0.9
@export var track_color: Color = Color(0.20, 0.85, 0.95)
@export var vel_color: Color = Color(0.55, 0.92, 1.0)
@export var force_color: Color = Color(0.98, 0.42, 0.40)
var _rig: Node3D
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
	add_child(_box(Vector3(0, BASE_Y - 0.1, 0), Vector3(2.4, 0.2, 2.4), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))
	add_child(_cylinder(Vector3(0, BASE_Y * 0.5, 0), 0.12, BASE_Y - 0.2, _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_torus(Vector3(0, BASE_Y, 0), radius, 0.03, _glow_mat(track_color, 1.4)))
	add_child(_sphere(Vector3(0, BASE_Y, 0), 0.1, _glow_mat(track_color, 1.0)))   # hub
	_rig = Node3D.new(); add_child(_rig)
	_rig.add_child(_sphere(Vector3.ZERO, 0.13, _glow_mat(Color(0.82, 0.5, 0.98), 1.2)))   # the mass
	add_child(_billboard_label("CENTRIPETAL\na = v²/r\nvelocity tangent · force inward", Vector3(0, BASE_Y + 1.7, 0), 24, track_color.lerp(Color.WHITE, 0.3)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _rig == null:
		return
	_t += delta * 1.2
	var pos := Vector3(cos(_t) * radius, BASE_Y, sin(_t) * radius)
	for c in _rig.get_children():
		if c is Node3D and c.name == "vec": _rig.remove_child(c); c.queue_free()
	_rig.get_child(0).position = pos
	var tangent := Vector3(-sin(_t), 0, cos(_t))
	var inward := -Vector3(cos(_t), 0, sin(_t))
	var vw := _arrow(pos, pos + tangent * 0.7, 0.04, _glow_mat(vel_color, 1.6)); vw.name = "vec"; _rig.add_child(vw)
	var fw := _arrow(pos, pos + inward * 0.6, 0.045, _glow_mat(force_color, 1.6)); fw.name = "vec"; _rig.add_child(fw)
