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

const BALLS := 5


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("lift"): lift = clampf(float(config_data["lift"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
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
	var ball_mat := _glow_mat(color_b, 0.5)
	for i in range(BALLS):
		var x: float = -half + float(i) * spacing
		var pivot: Vector3 = Vector3(x, top_y, 0.0)
		var ang: float = 0.0
		if i == 0:
			ang = -theta            # left end swings back-left
		elif i == BALLS - 1:
			ang = theta             # right end kicks out
		var ball_pos: Vector3 = pivot + Vector3(sin(ang) * L, -cos(ang) * L, 0.0)
		rig.add_child(_cylinder_between(pivot, ball_pos, 0.006, steel))   # string
		rig.add_child(_sphere(ball_pos, ball_r, ball_mat))
		# momentum arrows on the two end balls (equal & opposite about the line, both +X)
		if (i == 0 or i == BALLS - 1) and lift > 0.04:
			var plen: float = 0.18 + lift * 0.45
			var base: Vector3 = ball_pos + Vector3(0.0, ball_r + 0.06, 0.0)
			rig.add_child(_arrow(base, base + Vector3(plen, 0.0, 0.0), 0.02, _glow_mat(accent, 1.8)))

	set_readout("MOMENTUM\n\np = mv  conserved\n1 in  →  1 out", color_b.lerp(Color.WHITE, 0.2))
	_settle(rig)
