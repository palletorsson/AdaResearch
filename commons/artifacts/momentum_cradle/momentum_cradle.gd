extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name MomentumCradle

## @identity
## lineage: momentum conservation made playable — p = mv, and in a line of equal balls one
##   in means one out — the console rebuild of Newton's cradle for the embodied
##   vectors-forces arc.
## essence: lift the end ball and let it fall; the blow travels through the still middle
##   balls untouched and kicks the far ball out to the same height. The momentum you put in
##   comes straight out the other side — nothing lost in the balls between.
## truth: momentum is a debt the world always repays in full — what passes in must pass
##   out, and the quiet middle is just the courier.
##
## A ToyConsole: the readout lives on the monitor, the LIFT slider drives the demo.
## DNA: lift 0..1 sets how high the end balls swing (the momentum carried).

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var lift: float = 0.6
@export var color_a: Color = Color(0.55, 0.58, 0.64)     # frame
@export var color_b: Color = Color(0.78, 0.80, 0.86)     # the steel balls
@export var accent: Color = Color(0.98, 0.72, 0.30)      # momentum arrows
@export var complexity: int = 6

## AXIS — HOW MANY BALLS THE BLOW CARRIES. The whole demonstration is that the number
## going in comes back out: lift one and one leaves, lift two and TWO leave, and the
## still balls between are only the courier. The console could draw exactly one of those
## sentences — `if i == 0` on the left end and `elif i == BALLS - 1` on the right.
##
##   one   the shipped pose: one ball back, one kicked out, three hanging still.
##   two   two back, two out, and the courier line is down to a single ball.
##   all   every ball lifted together. Nobody is left standing still to be the courier,
##         so nothing is transmitted at all — the cradle is just a five-ball pendulum,
##         and the readout says 5 in, 0 out.
##
## Photographable BECAUSE this console draws the pose instead of simulating it. Its
## sibling [[newton_cradle]] considered the same axis, named it `lift`, and refused it
## on the record: there the swing is integrated in _physics_process and the lifted ball
## is at the bottom of its arc before a capture settles. Same claim, opposite condition.
@export_enum("one", "two", "all") var carried: String = "one"
const CARRIEDS: PackedStringArray = ["one", "two", "all"]

const BALLS := 5


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("lift"): lift = clampf(float(config_data["lift"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("carried"):
		var _c: String = String(config_data["carried"]).strip_edges().to_lower()
		carried = _c if CARRIEDS.has(_c) else carried
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "MOMENTUM CRADLE", "slider": "LIFT"}

func _param_get() -> float:
	return lift

func _param_set(v: float) -> void:
	lift = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("MomentumCradleRig")
	_rng.seed = hash(seed)

	var ball_r: float = 0.12
	var spacing: float = ball_r * 2.0
	var width: float = float(BALLS - 1) * spacing
	var half: float = width * 0.5
	var L: float = 0.62                # string length
	var top_y: float = L + ball_r + 0.18
	var theta: float = lift * deg_to_rad(52.0)

	var steel := _steel_mat(color_a)

	# --- frame ------------------------------------------------------------------
	rig.add_child(_box(Vector3(0.0, 0.03, 0.0), Vector3(width + 0.7, 0.06, 0.5), steel))           # base
	for sx in [-1.0, 1.0]:
		rig.add_child(_box(Vector3(sx * (half + 0.22), top_y * 0.5, 0.0), Vector3(0.06, top_y, 0.06), steel))
	rig.add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(width + 0.5, 0.06, 0.06), steel))         # top bar

	# --- the balls on their strings ---------------------------------------------
	# CARRIED — how many balls go in, and therefore how many come out. At the shipped
	# "one" this is the old `i == 0` / `i == BALLS - 1` pair exactly: n_in and n_out are
	# both 1, so ball 0 takes -theta, ball 4 takes +theta and the middle three hang.
	var n_in: int = _carried_in()
	var n_out: int = 0 if n_in >= BALLS else n_in
	var ball_mat := _glow_mat(color_b, 0.5)
	for i in range(BALLS):
		var x: float = -half + float(i) * spacing
		var pivot: Vector3 = Vector3(x, top_y, 0.0)
		var ang: float = 0.0
		if i < n_in:
			ang = -theta            # the lifted end swings back-left
		elif n_out > 0 and i >= BALLS - n_out:
			ang = theta             # the far end kicks out
		var ball_pos: Vector3 = pivot + Vector3(sin(ang) * L, -cos(ang) * L, 0.0)
		rig.add_child(_cylinder_between(pivot, ball_pos, 0.006, steel))   # string
		rig.add_child(_sphere(ball_pos, ball_r, ball_mat))
		# momentum arrows on every ball that is carrying (equal & opposite about the line,
		# both +X). At "one" that is the two end balls, which is what shipped.
		if lift > 0.04 and not is_zero_approx(ang):
			var plen: float = 0.18 + lift * 0.45
			var base: Vector3 = ball_pos + Vector3(0.0, ball_r + 0.06, 0.0)
			rig.add_child(_arrow(base, base + Vector3(plen, 0.0, 0.0), 0.02, _glow_mat(accent, 1.8)))

	set_readout("MOMENTUM\n\np = mv  conserved\n%d in  →  %d out" % [n_in, n_out],
		color_b.lerp(Color.WHITE, 0.2))
	_settle(rig)


# --- CARRIED ----------------------------------------------------------------

func _carried_value() -> String:
	var c: String = String(carried).strip_edges().to_lower()
	return c if CARRIEDS.has(c) else "one"


func _carried_in() -> int:
	match _carried_value():
		"two":
			return 2
		"all":
			return BALLS
		_:
			return 1
