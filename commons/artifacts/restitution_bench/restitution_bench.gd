extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RestitutionBench

## @identity
## lineage: the bench-scale middle of the Restitution ladder — a strobe of one ball's bounces, each
##   peak a fixed fraction of the last, with a live ball bouncing through them.
## essence: h' = e·h. The coefficient of restitution e ∈ [0,1] is the tax on every fall; the peaks
##   form a geometric decay, and the ball never returns to where it began.
## truth: every bounce is a tax on a fall.

@export_range(0.3, 0.95, 0.01) var e: float = 0.72
@export var ball_color: Color = Color(0.82, 0.5, 0.98)
@export var mark_color: Color = Color(0.55, 0.95, 0.58)
var _ball: Node3D
var _t: float = 0.0
const BASE_Y := 0.9
const H0 := 1.4


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("e"): e = clampf(float(config["e"]), 0.3, 0.95)
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(2.0, BASE_Y - 0.1, 0), Vector3(5.0, 0.2, 1.2), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))
	for i in range(5):                                                  # strobe: each peak a fraction of the last
		var h: float = H0 * pow(e, i)
		var x: float = i * 1.0
		add_child(_dashed(Vector3(x, BASE_Y, 0), Vector3(x, BASE_Y + h, 0), 0.012, _glow_mat(mark_color, 0.5)))
		add_child(_sphere(Vector3(x, BASE_Y + h, 0), 0.1, _glow_mat(ball_color.darkened(0.1), 0.5)))
	_ball = Node3D.new(); add_child(_ball)
	_ball.add_child(_sphere(Vector3.ZERO, 0.14, _glow_mat(ball_color, 1.3)))
	add_child(_billboard_label("RESTITUTION\nh' = e · h\ne = %.2f   each bounce a fraction of the last" % e, Vector3(2.0, BASE_Y + 2.0, 0), 24, mark_color.lerp(Color.WHITE, 0.3)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _ball == null:
		return
	_t += delta * 1.6
	var n: int = int(_t) % 5                                            # which bounce
	var ph: float = _t - floor(_t)
	var h: float = H0 * pow(e, n)
	var y: float = BASE_Y + 4.0 * h * ph * (1.0 - ph)                   # a parabolic hop to peak h
	_ball.position = Vector3(float(n), y, 0)
