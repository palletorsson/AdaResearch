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

# --- STAGE-2 DNA (promoted 2026-08-05) ---------------------------------------
#
# TWO THINGS WERE WELDED SHUT, and they are the two symbols in a = v²/r.
#
# `turn` is the r. TRACK_R was a const 1.0 and the slider only ever moved v, so
# the exhibit could dial one half of its own law and not the other — which is the
# half that is easier to feel and harder to draw. The code was already written as
# if r varied (car_gap = 0.34 / TRACK_R keeps the coupling ARC-LENGTH constant, so
# the cars stay the same size on any ring), so the constant was a parameter that
# had simply never been given a name. And _settle() rescales the demo to a fixed
# span, which is exactly what makes this measurable rather than decorative: the
# ring is renormalised to the same width in every frame, so what the picture shows
# is the RATIO of the inward arrow to the circle it is bending. At the shipped
# speed that arrow is 0.59 against a 1.00 radius on `standard`, 0.35 against 1.80
# on `wide`, and 1.07 against 0.55 on `tight` — where the pull is longer than the
# radius and the arrow runs clean through the hub and out the far side.
#
# `workings` is the shared bench word — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS
# — taken character for character (and value for value, in order) from
# [[transform_composition_workbench]] and its bench-mates [[dot_aligner]],
# [[projection_shadow]], [[torque_crank]], [[bounce_well]] and [[launch_arc]].
# The four values are not borrowed empty; each names something this object has:
#
#   outcome     the pull alone. The train, its streaks, the velocity arrow and
#               the dashed spoke leave the render layers; a ring, a hub and one
#               arrow aimed at the centre remain. Circular motion as its force,
#               with nothing in frame going round.
#   trace       the legacy lineage, byte for byte — the maglev loop, four banking
#               cars, the speed streaks, both vectors. The force as an EVENT you
#               watch happen to something.
#   operands    the ingredients answer instead. r is redrawn as a solid measured
#               spoke from hub to train, the tangent is extended forward AND back
#               through the train as the straight line it would have taken, and a
#               right-angle gnomon is planted between that line and the inward
#               arrow. This is the claim a still can actually carry: the force is
#               PERPENDICULAR to the motion, always, and r is what it divides by.
#   expression  the algebra promoted over the geometry — a light board above the
#               ring writing a = v²/r with the numbers substituted, between two
#               emissive rules in the accent colour.
#
# Both matches sit AFTER _settle(rig), so the fit, the scale and the placement of
# every legacy piece are computed from exactly the geometry that shipped.
const TRACK_R := 1.0
const CARS := 4
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]
const TURNS: PackedStringArray = ["standard", "wide", "tight"]

## How tight the curve is — the r in a = v²/r. standard IS the shipped TRACK_R.
@export_enum("standard", "wide", "tight") var turn: String = "standard"
## How much of the arithmetic the bench draws. trace = the shipped lineage.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("speed"): speed = clampf(float(config_data["speed"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("turn"):
		var _t: String = String(config_data["turn"]).strip_edges().to_lower()
		turn = _t if TURNS.has(_t) else turn
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
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


## The r in a = v²/r. `standard` SHORT-CIRCUITS to the shipped const rather than
## re-deriving it, so nothing about the legacy ring is recomputed at the default.
func _track_radius() -> float:
	match _turn_value():
		"wide":
			return 1.80
		"tight":
			return 0.55
	return TRACK_R


func _turn_value() -> String:
	var t: String = String(turn).strip_edges().to_lower()
	return t if TURNS.has(t) else "standard"


func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _build_demo() -> void:
	var rig := _fresh_demo_rig("CircleTrainRig")
	_rng.seed = hash(seed)

	# --- the physics ------------------------------------------------------------
	var r: float = _track_radius()                        # the turn radius (TRACK_R by default)
	var v: float = lerpf(0.45, 1.5, speed)               # tangential speed
	var a_c: float = v * v / r                            # centripetal accel = v²/r
	var run_y: float = 0.16
	var phi: float = _rng.randf_range(0.0, TAU)
	var pos: Vector3 = _ring_point(phi, r) + Vector3(0.0, run_y, 0.0)
	var tangent: Vector3 = Vector3(-sin(phi), 0.0, cos(phi))   # CCW direction of travel
	var inward: Vector3 = -Vector3(cos(phi), 0.0, sin(phi))    # toward the centre

	# --- the neon track + hub ---------------------------------------------------
	rig.add_child(_torus(Vector3(0.0, run_y, 0.0), r, 0.045, _glow_mat(color_a, 1.6)))
	rig.add_child(_torus(Vector3(0.0, run_y, 0.0), r, 0.012, _glow_mat(color_a.lerp(Color.WHITE, 0.4), 2.6)))
	rig.add_child(_cylinder(Vector3(0.0, run_y * 0.5, 0.0), 0.10, run_y, _steel_mat(Color(0.30, 0.32, 0.38))))
	rig.add_child(_sphere(Vector3(0.0, run_y, 0.0), 0.10, _glow_mat(color_a, 1.0)))
	# The spoke and the train are held under identity Node3Ds so WORKINGS can reach
	# each of them at once. The holders sit at the rig origin and their children keep
	# the absolute rig-local positions the helpers already gave them, so _subtree_aabb
	# and _settle see exactly the box they always did.
	var spoke: Node3D = _dashed(Vector3(0.0, run_y, 0.0), pos, 0.01, _glow_mat(color_a.lerp(Color(0.2, 0.2, 0.25), 0.5), 0.5))
	rig.add_child(spoke)

	# --- the train (cars trailing behind, leaning into the curve) ---------------
	var train := Node3D.new()
	train.name = "Train"
	rig.add_child(train)
	var car_gap: float = 0.34 / r
	for i in range(CARS):
		var cphi: float = phi - car_gap * float(i)
		var cpos: Vector3 = _ring_point(cphi, r) + Vector3(0.0, run_y, 0.0)
		var fade: float = float(i) / float(CARS)
		var car := _box(cpos, Vector3(0.16, 0.13, 0.30), _glow_mat(train_color.lerp(color_a, fade * 0.5), lerpf(1.8, 0.7, fade)))
		car.rotation.y = -cphi
		car.rotation.z = lerpf(0.0, 0.5, speed) * (1.0 if i == 0 else 0.7)
		train.add_child(car)

	# --- speed streaks behind the lead car --------------------------------------
	var wake := Node3D.new()
	wake.name = "Streaks"
	rig.add_child(wake)
	var streaks: int = clampi(int(speed * 9.0) + 1, 1, 10)
	for i in range(streaks):
		var sphi: float = phi - car_gap * (CARS - 0.2) - 0.10 * float(i)
		var sp: Vector3 = _ring_point(sphi, r) + Vector3(0.0, run_y, 0.0)
		wake.add_child(_sphere(sp, lerpf(0.05, 0.012, float(i) / float(streaks)), _glow_mat(color_b, lerpf(1.6, 0.3, float(i) / float(streaks)))))

	# --- the two vectors: velocity (tangent ∝v) + centripetal (inward ∝v²) -------
	var vel_arrow: Node3D = _arrow(pos, pos + tangent * (v * 0.62), 0.028, _glow_mat(color_b, 1.6))
	rig.add_child(vel_arrow)
	rig.add_child(_arrow(pos, pos + inward * (a_c * 0.42), 0.030, _glow_mat(accent, 1.4 + speed * 2.2)))

	# --- readout -> the monitor --------------------------------------------------
	set_readout("CENTRIPETAL\n\nv = %.2f\na = v²/r = %.2f\nF = m v²/r" % [v, a_c], Color(0.7, 0.95, 1.0))

	_settle(rig)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today — nothing above this line moves. "trace" falls
	# through and adds nothing at all.
	match _workings_value():
		"outcome":
			_workings_outcome(train, wake, vel_arrow, spoke)
		"operands":
			_workings_operands(rig, pos, tangent, inward, r, run_y)
		"expression":
			_workings_expression(rig, r, v, a_c, run_y)
		_:
			pass                                   # "trace" — the legacy lineage


# --- WORKINGS ---------------------------------------------------------------
# Removal is always `layers = 0` on the MeshInstance3D leaves — never
# `visible = false`, which in Godot takes a holder's whole subtree with it.

func _unlayer(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OUTCOME — the pull alone. The train, the streaks, the velocity arrow and the dashed
## spoke leave the render layers. What is left is the neon ring, the hub and one arrow
## aimed at the centre: circular motion stated as its force, with nothing in frame
## actually going round. The ring stays because it is the geometry the answer is stated
## in — and because it is the widest MeshInstance3D here, so the capture keeps a stable
## box to fit across the whole sweep.
func _workings_outcome(train: Node3D, wake: Node3D, vel_arrow: Node3D, spoke: Node3D) -> void:
	_unlayer(train)
	_unlayer(wake)
	_unlayer(vel_arrow)
	_unlayer(spoke)


## OPERANDS — the ingredients answer instead of the spectacle. r is redrawn as a solid
## spoke from the hub with a tick at each end; the tangent is extended forward AND back
## through the train as the straight line the train would take if the force stopped; and
## a right-angle gnomon is planted between that line and the inward arrow. Perpendicular
## is the whole claim: the force never speeds the train up, it only turns it, and the
## amount of turning is the r it divides by.
func _workings_operands(rig: Node3D, pos: Vector3, tangent: Vector3, inward: Vector3,
		r: float, run_y: float) -> void:
	var hub: Vector3 = Vector3(0.0, run_y, 0.0)
	var r_mat := _glow_mat(color_a.lerp(Color.WHITE, 0.35), 1.6)
	rig.add_child(_arrow(hub, pos, 0.020, r_mat))
	rig.add_child(_sphere(hub, 0.055, r_mat))

	# the straight line desire: the tangent through the train, both ways
	var reach: float = r * 1.15
	var line_mat := _glow_mat(color_b.lerp(Color(0.20, 0.20, 0.24), 0.45), 0.7)
	rig.add_child(_dashed(pos - tangent * reach, pos + tangent * reach, 0.012, line_mat))

	# the right-angle gnomon between the tangent and the inward pull
	var g: float = clampf(r * 0.16, 0.09, 0.26)
	var gm := _glow_mat(Color(0.90, 0.93, 1.0), 1.4)
	var a: Vector3 = pos + tangent * g
	var b: Vector3 = pos + inward * g
	rig.add_child(_cylinder_between(a, a + inward * g, 0.010, gm))
	rig.add_child(_cylinder_between(b, b + tangent * g, 0.010, gm))


## EXPRESSION — the algebra promoted over the geometry. A light Braun plate stands above
## the ring and writes a = v²/r out with the numbers substituted, held between two
## emissive rules in the accent colour so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, r: float, v: float, a_c: float, run_y: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(0.0, run_y + r * 0.85 + 0.55, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(2.10, 0.58, 0.03), _panel_mat(PANEL_LIGHT)))
	board.add_child(_box(Vector3(0.0, 0.29, 0.02), Vector3(2.10, 0.032, 0.02), _glow_mat(accent, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.29, 0.02), Vector3(2.10, 0.032, 0.02), _glow_mat(accent, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "a  =  v² / r\n%.2f² / %.2f  =  %.2f" % [v, r, a_c]
	l.font_size = 40
	l.pixel_size = 0.0038
	l.modulate = TEXT_DARK
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)
