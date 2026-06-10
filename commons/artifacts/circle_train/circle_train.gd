extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name CircleTrain

## @identity
## lineage: centripetal force made playable — a = v²/r, F = m v²/r — an intermezzo for
##   the embodied vectors-forces arc: a high-speed maglev loop where the train shows its
##   own force vectors and you dial the speed.
## essence: velocity is always tangent to the ring; the force is always inward; and the
##   trick that makes circular motion feel alive is that the inward force grows with the
##   SQUARE of speed — double the speed, quadruple the pull. The train leans into it.
## truth: going in a circle is constant acceleration toward a centre you never reach —
##   straight-line desire bent by a force that only ever points sideways.
##
## A ToyConsole: the readout lives on the monitor, the SPEED slider drives the demo.
## DNA: speed 0..1 — tangent velocity grows linearly, the inward force quadratically.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var speed: float = 0.7
@export var color_a: Color = Color(0.20, 0.85, 0.95)     # neon track
@export var color_b: Color = Color(0.55, 0.92, 1.0)      # velocity (tangent)
@export var accent: Color = Color(0.98, 0.42, 0.40)      # centripetal force (inward)
@export var train_color: Color = Color(0.85, 0.50, 0.98) # the glowing train cars
@export var complexity: int = 6

const TRACK_R := 1.0
const CARS := 4


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("speed"): speed = clampf(float(config_data["speed"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	train_color = _parse_color(config_data.get("train_color", train_color), train_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "CIRCLE TRAIN", "slider": "SPEED"}

func _param_get() -> float:
	return speed

func _param_set(v: float) -> void:
	speed = v


func _ring_point(phi: float, r: float) -> Vector3:
	return Vector3(cos(phi) * r, 0.0, sin(phi) * r)


func _build_demo() -> void:
	var rig := _fresh_demo_rig("CircleTrainRig")
	_rng.seed = hash(seed)

	# --- the physics ------------------------------------------------------------
	var v: float = lerpf(0.45, 1.5, speed)               # tangential speed
	var a_c: float = v * v / TRACK_R                      # centripetal accel = v²/r
	var run_y: float = 0.16
	var phi: float = _rng.randf_range(0.0, TAU)
	var pos: Vector3 = _ring_point(phi, TRACK_R) + Vector3(0.0, run_y, 0.0)
	var tangent: Vector3 = Vector3(-sin(phi), 0.0, cos(phi))   # CCW direction of travel
	var inward: Vector3 = -Vector3(cos(phi), 0.0, sin(phi))    # toward the centre

	# --- the neon track + hub ---------------------------------------------------
	rig.add_child(_torus(Vector3(0.0, run_y, 0.0), TRACK_R, 0.045, _glow_mat(color_a, 1.6)))
	rig.add_child(_torus(Vector3(0.0, run_y, 0.0), TRACK_R, 0.012, _glow_mat(color_a.lerp(Color.WHITE, 0.4), 2.6)))
	rig.add_child(_cylinder(Vector3(0.0, run_y * 0.5, 0.0), 0.10, run_y, _steel_mat(Color(0.30, 0.32, 0.38))))
	rig.add_child(_sphere(Vector3(0.0, run_y, 0.0), 0.10, _glow_mat(color_a, 1.0)))
	rig.add_child(_dashed(Vector3(0.0, run_y, 0.0), pos, 0.01, _glow_mat(color_a.lerp(Color(0.2, 0.2, 0.25), 0.5), 0.5)))

	# --- the train (cars trailing behind, leaning into the curve) ---------------
	var car_gap: float = 0.34 / TRACK_R
	for i in range(CARS):
		var cphi: float = phi - car_gap * float(i)
		var cpos: Vector3 = _ring_point(cphi, TRACK_R) + Vector3(0.0, run_y, 0.0)
		var fade: float = float(i) / float(CARS)
		var car := _box(cpos, Vector3(0.16, 0.13, 0.30), _glow_mat(train_color.lerp(color_a, fade * 0.5), lerpf(1.8, 0.7, fade)))
		car.rotation.y = -cphi
		car.rotation.z = lerpf(0.0, 0.5, speed) * (1.0 if i == 0 else 0.7)
		rig.add_child(car)

	# --- speed streaks behind the lead car --------------------------------------
	var streaks: int = clampi(int(speed * 9.0) + 1, 1, 10)
	for i in range(streaks):
		var sphi: float = phi - car_gap * (CARS - 0.2) - 0.10 * float(i)
		var sp: Vector3 = _ring_point(sphi, TRACK_R) + Vector3(0.0, run_y, 0.0)
		rig.add_child(_sphere(sp, lerpf(0.05, 0.012, float(i) / float(streaks)), _glow_mat(color_b, lerpf(1.6, 0.3, float(i) / float(streaks)))))

	# --- the two vectors: velocity (tangent ∝v) + centripetal (inward ∝v²) -------
	rig.add_child(_arrow(pos, pos + tangent * (v * 0.62), 0.028, _glow_mat(color_b, 1.6)))
	rig.add_child(_arrow(pos, pos + inward * (a_c * 0.42), 0.030, _glow_mat(accent, 1.4 + speed * 2.2)))

	# --- readout -> the monitor --------------------------------------------------
	set_readout("CENTRIPETAL\n\nv = %.2f\na = v²/r = %.2f\nF = m v²/r" % [v, a_c], Color(0.7, 0.95, 1.0))

	_settle(rig)
