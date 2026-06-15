extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CentrifugeRing

## @identity
## lineage: the walk-in twin of circle_train — a body-scale centripetal ring. A pod laps a
##   big neon loop while the velocity (tangent) and the centripetal force (inward, ∝ v²/r)
##   ride it at your own scale, so you watch the inward pull grow with the square of speed.
## essence: velocity is always tangent to the ring; the force is always toward the centre you
##   never reach. Crank the speed and the velocity arrow stretches while the inward arrow
##   explodes — a = v²/r is why fast turns throw you.
## truth: going in a circle is constant acceleration toward a centre you never reach.
##
## The large half of the circle_train pair: a ridden loop you stand inside, the pod circling
## live in _process with its two vectors.

@export var radius: float = 3.4
@export_range(0.0, 1.0, 0.01) var speed: float = 0.62
@export var track_color: Color = Color(0.20, 0.85, 0.95)
@export var vel_color: Color = Color(0.55, 0.92, 1.0)
@export var force_color: Color = Color(0.98, 0.42, 0.40)
@export var pod_color: Color = Color(0.82, 0.50, 0.98)

const TRACK_Y := 0.7
var _pod: Node3D
var _vectors: Node3D
var _t: float = 0.0
var _omega: float = 1.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("radius"): radius = float(config["radius"])
	if config.has("speed"): speed = clampf(float(config["speed"]), 0.0, 1.0)
	if config.has("emissive"): emissive = bool(config["emissive"])
	track_color = _parse_color(config.get("track_color", track_color), track_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_omega = lerpf(0.35, 1.5, speed)
	var steel := _steel_mat(Color(0.32, 0.34, 0.4))
	# the neon ring track + a bright inner line
	add_child(_torus(Vector3(0, TRACK_Y, 0), radius, 0.09, _glow_mat(track_color, 1.6)))
	add_child(_torus(Vector3(0, TRACK_Y, 0), radius, 0.025, _glow_mat(track_color.lerp(Color.WHITE, 0.4), 2.6)))
	# central hub + tower + spokes
	add_child(_cylinder(Vector3(0, TRACK_Y * 0.5, 0), 0.28, TRACK_Y, steel))
	add_child(_sphere(Vector3(0, TRACK_Y, 0), 0.3, _glow_mat(track_color, 1.2)))
	for i in range(6):
		var a := TAU * float(i) / 6.0
		add_child(_cylinder_between(Vector3(0, TRACK_Y, 0), Vector3(cos(a) * radius, TRACK_Y, sin(a) * radius), 0.02, _glow_mat(track_color.lerp(Color(0.2,0.2,0.25),0.4), 0.5)))
	# legs under the ring
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var foot := Vector3(cos(a) * radius, 0, sin(a) * radius)
		add_child(_cylinder_between(foot, foot + Vector3(0, TRACK_Y, 0), 0.04, steel))

	# the pod (laps the ring in _process)
	_pod = Node3D.new(); add_child(_pod)
	_pod.add_child(_box(Vector3(0, 0, 0), Vector3(0.5, 0.42, 0.78), _glow_mat(pod_color, 0.9)))
	_pod.add_child(_box(Vector3(0, 0.26, 0), Vector3(0.4, 0.12, 0.5), _glow_mat(pod_color.lerp(Color.WHITE, 0.3), 0.6)))
	_vectors = Node3D.new(); add_child(_vectors)

	var v: float = lerpf(2.0, 9.0, speed)
	add_child(_billboard_label("CENTRIPETAL\na = v²/r\nv = %.1f  r = %.1f\na = %.1f  (F = m·a, inward)" % [v, radius, v * v / radius],
		Vector3(0, TRACK_Y + 2.0, 0), 30, track_color.lerp(Color.WHITE, 0.3)))
	_advance()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _pod == null:
		return
	_t += delta
	_advance()


func _advance() -> void:
	var theta: float = _t * _omega
	var pos := Vector3(cos(theta) * radius, TRACK_Y, sin(theta) * radius)
	_pod.position = pos
	_pod.rotation.y = -theta
	# the two vectors, body-scale
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var tangent := Vector3(-sin(theta), 0, cos(theta))
	var inward := Vector3(-cos(theta), 0, -sin(theta))
	var v: float = lerpf(2.0, 9.0, speed)
	_vectors.add_child(_arrow(pos, pos + tangent * (v * 0.18), 0.05, _glow_mat(vel_color, 1.6)))                 # velocity (tangent, ∝v)
	_vectors.add_child(_arrow(pos, pos + inward * (v * v / radius * 0.10), 0.055, _glow_mat(force_color, 1.4 + speed * 2.0)))  # centripetal (inward, ∝v²/r)
