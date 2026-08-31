extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EpicycleDesk

## @identity
## lineage: the Sum hero — a draughtsman's desk with a brass machine of circles
##   riding circles (harmonics 1, 3, 5 at amplitudes 1, 1/3, 1/5), a pen at the last
##   rim, and a paper strip carrying what the pen actually drew: a square wave with
##   rounded shoulders and a visible wobble, because three terms is not infinity.
## essence: Fourier - any signal is a sum of sines. The epicycles are the theorem
##   made brass: each circle spins alone and knows nothing, and their added heights
##   draw a shape none of them contains. The wobble in the trace is the honest
##   remainder of the terms not yet hired.
## truth: a square corner costs infinitely many circles. The desk has three, and you
##   can see exactly what three buys.
##
## The 2026-08-29 category-heroes pass, wavefunctions.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 4
## Frozen angle of the base circle, radians.
@export var theta: float = 1.15
@export var base_r: float = 0.30

func _partial(t: float) -> float:
	# 3-term Fourier square wave, normalized to base_r
	return base_r * (sin(t) + sin(3.0 * t) / 3.0 + sin(5.0 * t) / 5.0)

func _ready() -> void:
	_rng.seed = seed
	_build_desk()
	_build_machine()
	_build_trace()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "theta", "base_r"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_desk() -> void:
	# a drafting desk: slightly raked top on trestle legs
	var top := _box(Vector3(0.0, 0.86, 0.0), Vector3(1.7, 0.05, 1.0), _matte_mat(Color(0.42, 0.28, 0.16), 0.75))
	top.rotation.x = -0.1
	add_child(top)
	for sx in [-0.72, 0.72]:
		for sz in [-0.38, 0.38]:
			var leg := _cylinder(Vector3(sx, 0.42, sz), 0.03, 0.84, _matte_mat(Color(0.3, 0.2, 0.12), 0.8))
			add_child(leg)
		add_child(_box(Vector3(sx, 0.2, 0.0), Vector3(0.06, 0.04, 0.8), _matte_mat(Color(0.3, 0.2, 0.12), 0.8)))

func _build_machine() -> void:
	# the epicycle train stands on the desk, wheels vertical so the trace reads
	# from the front: circle 1 carries circle 3 carries circle 5, pen at the tip
	var org := Vector3(-0.45, 1.32, 0.12)
	var brass := _steel_mat(Color(0.72, 0.58, 0.26))
	add_child(_cylinder_between(Vector3(org.x, 0.9, org.z), org, 0.02, brass))
	var radii := [base_r, base_r / 3.0, base_r / 5.0]
	var harmonics := [1.0, 3.0, 5.0]
	var c := org
	var tip := org
	for i in range(3):
		var r: float = radii[i]
		var h: float = harmonics[i]
		var ring := _torus(Vector3.ZERO, r, 0.012, brass)
		ring.rotation.x = PI * 0.5
		ring.position = c
		add_child(ring)
		var a := h * theta
		tip = c + Vector3(cos(a) * r, sin(a) * r, 0.0)
		add_child(_cylinder_between(c, tip, 0.010, brass))
		add_child(_sphere(c, 0.022, _matte_mat(Color(0.25, 0.2, 0.12), 0.4, 0.7)))
		c = tip
	# the pen at the last rim, and its horizontal reach to the paper
	var pen := _cylinder_between(tip, tip + Vector3(0.0, 0.09, 0.0), 0.012, _matte_mat(Color(0.1, 0.1, 0.12), 0.4))
	add_child(pen)
	add_child(_dashed(tip, Vector3(0.42, tip.y, tip.z), 0.006, _glow_mat(Color(0.9, 0.75, 0.4), 1.1)))
	add_child(_sphere(Vector3(0.42, tip.y, tip.z), 0.028, _glow_mat(Color(1.0, 0.55, 0.3), 2.2)))

func _build_trace() -> void:
	# the paper strip on the desk's right half, carrying the drawn history:
	# y(t) for one and a half periods, ending at the pen's current height
	var paper := _box(Vector3(0.72, 1.2, 0.12), Vector3(0.55, 0.85, 0.02), _matte_mat(Color(0.94, 0.92, 0.86), 0.9))
	add_child(paper)
	var n := 48
	var pts: Array[Vector3] = []
	for i in range(n + 1):
		var u := float(i) / float(n)
		var t := theta - TAU * 1.5 * (1.0 - u)
		pts.append(Vector3(0.72 - 0.24 + 0.48 * u - 0.06, 1.2 + _partial(t) * 0.8, 0.135))
	for i in range(n):
		add_child(_cylinder_between(pts[i], pts[i + 1], 0.006, _matte_mat(Color(0.15, 0.15, 0.2), 0.5)))
	# the ideal square wave, faint behind the drawn one: what infinity would buy
	for half in range(3):
		var t0 := theta - TAU * 1.5 + TAU * 0.5 * float(half)
		var lvl := base_r * 0.785 * (1.0 if sin(t0 + 0.1) > 0.0 else -1.0)
		var x0 := 0.42 + 0.48 * (float(half) / 3.0)
		var x1 := 0.42 + 0.48 * (float(half + 1) / 3.0)
		add_child(_dashed(Vector3(x0, 1.2 + lvl * 0.8, 0.13), Vector3(x1, 1.2 + lvl * 0.8, 0.13), 0.004, _glass_mat(Color(0.4, 0.6, 0.9), 0.5)))

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "EpicyclePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.15, 0.24, 0.85)
	ts.rotation.y = deg_to_rad(10.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("EPICYCLE DESK - the sum",
			"Three brass circles, each spinning alone, each knowing nothing.\nTheir added heights draw a square wave with rounded shoulders - the wobble\nis the honest remainder of the circles not yet hired. Corners cost infinity.")
