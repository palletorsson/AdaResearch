extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VelocityBench

## @identity
## lineage: the bench-scale middle of the Motion / velocity ladder — a puck crossing a table with
##   its velocity drawn and split into the part that carries it across and the part that lifts it.
## essence: velocity is a vector; vx and vy are its components, the speed is their diagonal, and the
##   heading is their angle. Motion is just a vector the world keeps re-applying each tick.
## truth: motion is a vector the world keeps editing.

@export var heading: float = 28.0          # degrees
@export var speed: float = 1.3
@export var vel_color: Color = Color(0.55, 0.92, 1.0)
@export var comp_color: Color = Color(0.62, 0.66, 0.78)
@export var puck_color: Color = Color(0.82, 0.5, 0.98)
var _puck: Node3D
var _vectors: Node3D
var _t: float = 0.0
const BASE_Y := 0.92


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("speed"): speed = float(config["speed"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, BASE_Y - 0.1, 0), Vector3(3.4, 0.2, 2.4), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))
	var gm := _glow_mat(Color(0.3, 0.32, 0.4), 0.3)
	for i in range(-1, 2):
		add_child(_box(Vector3(i, BASE_Y, 0), Vector3(0.01, 0.01, 2.0), gm))
		add_child(_box(Vector3(0, BASE_Y, i), Vector3(3.0, 0.01, 0.01), gm))
	_puck = Node3D.new(); add_child(_puck)
	_puck.add_child(_sphere(Vector3.ZERO, 0.13, _glow_mat(puck_color, 1.2)))
	_vectors = Node3D.new(); add_child(_vectors)
	add_child(_billboard_label("VELOCITY\nv = (vx, vy)   speed = |v|\nthe part that carries + the part that lifts", Vector3(0, BASE_Y + 1.8, 0), 23, vel_color.lerp(Color.WHITE, 0.3)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _puck == null:
		return
	_t += delta * 0.5
	var th: float = deg_to_rad(heading)
	var dir := Vector3(cos(th), 0, sin(th))
	var frac: float = fmod(_t, 1.0)
	var pos := Vector3(-1.3, BASE_Y, -0.7) + dir * (frac * 2.6)         # the puck crosses the table
	_puck.position = pos
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var v := dir * speed
	_vectors.add_child(_arrow(pos, pos + v, 0.05, _glow_mat(vel_color, 1.7)))                          # velocity
	_vectors.add_child(_arrow(pos, pos + Vector3(v.x, 0, 0), 0.035, _glow_mat(comp_color, 0.9)))       # vx
	_vectors.add_child(_arrow(pos + Vector3(v.x, 0, 0), pos + v, 0.035, _glow_mat(comp_color, 0.9)))   # vy
