extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name SlingshotPull

## @identity
## lineage: the slingshot as stored energy — PE = ½kx², the elastic pull that becomes a
##   launch — the console rebuild of the old slingshot launcher, for the embodied
##   vectors-forces arc.
## essence: draw the pouch back and the band stores energy as the square of the pull; let
##   go and that energy becomes launch speed, the projectile arcing away. Pull twice as far
##   and you store four times the energy.
## truth: a stretched band is a promise — the further you pull, the more the world owes the
##   stone, paid back as the square of your patience.
##
## A ToyConsole: the readout lives on the monitor, the DRAW slider drives the demo.
## DNA: draw 0..1 — how far the pouch is pulled (stored energy ∝ draw²).

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var draw: float = 0.6
@export var color_a: Color = Color(0.46, 0.34, 0.24)     # wooden fork
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # launch vector + arc
@export var accent: Color = Color(0.92, 0.30, 0.34)      # the elastic band / energy
@export var complexity: int = 6

const GRAVITY := 3.0


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("draw"): draw = clampf(float(config_data["draw"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "SLINGSHOT", "slider": "DRAW"}

func _param_get() -> float:
	return draw

func _param_set(v: float) -> void:
	draw = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("SlingshotPullRig")
	_rng.seed = hash(seed)

	var wood := _steel_mat(color_a)
	var fork_top: float = 0.62
	var prong_z: float = 0.2
	var tip_l := Vector3(0.0, 0.78, prong_z)
	var tip_r := Vector3(0.0, 0.78, -prong_z)

	# --- the Y-fork -------------------------------------------------------------
	rig.add_child(_box(Vector3(0.0, 0.25, 0.0), Vector3(0.07, 0.5, 0.07), wood))                 # handle
	rig.add_child(_cylinder_between(Vector3(0.0, fork_top - 0.12, 0.0), tip_l, 0.025, wood))     # left prong
	rig.add_child(_cylinder_between(Vector3(0.0, fork_top - 0.12, 0.0), tip_r, 0.025, wood))     # right prong

	# --- the pulled pouch -------------------------------------------------------
	var draw_dist: float = lerpf(0.12, 0.72, draw)
	var pouch: Vector3 = Vector3(-draw_dist, 0.68, 0.0)
	# elastic band, two strands, thicker / hotter the more it is drawn
	var band := _glow_mat(accent, 1.2 + draw * 2.5)
	rig.add_child(_cylinder_between(tip_l, pouch, 0.012 + 0.01 * draw, band))
	rig.add_child(_cylinder_between(tip_r, pouch, 0.012 + 0.01 * draw, band))
	rig.add_child(_sphere(pouch, 0.07, _glow_mat(color_b.lerp(Color.WHITE, 0.2), 1.0)))          # projectile

	# --- the launch vector + predicted parabola ---------------------------------
	var v: float = lerpf(1.1, 3.0, draw)             # launch speed ∝ draw
	var theta: float = deg_to_rad(20.0)
	var dir: Vector3 = Vector3(cos(theta), sin(theta), 0.0)
	rig.add_child(_arrow(pouch, pouch + dir * (v * 0.38), 0.026, _glow_mat(color_b, 1.7)))
	var t_land: float = 2.0 * (v * sin(theta)) / GRAVITY + 0.4
	var steps: int = clampi(complexity + 8, 12, 24)
	for i in range(steps + 1):
		var t: float = t_land * float(i) / float(steps)
		var p: Vector3 = pouch + dir * v * t - Vector3(0.0, 0.5 * GRAVITY * t * t, 0.0)
		if p.y < 0.0:
			break
		rig.add_child(_sphere(p, 0.028, _glow_mat(color_b, lerpf(1.3, 0.4, float(i) / float(steps)))))

	# --- energy bar (PE ∝ draw²) ------------------------------------------------
	var pe: float = draw * draw
	rig.add_child(_box(Vector3(-0.1, -0.06, 0.0), Vector3(0.7, 0.03, 0.05), _steel_mat(Color(0.2, 0.2, 0.24))))
	rig.add_child(_box(Vector3(-0.1 - 0.35 + 0.35 * pe, -0.06, 0.0), Vector3(maxf(0.7 * pe, 0.01), 0.045, 0.06), _glow_mat(accent, 1.6)))

	set_readout("ELASTIC\n\nPE = ½kx²\ndraw = %.2f" % draw, color_b.lerp(Color.WHITE, 0.2))
	_settle(rig)
