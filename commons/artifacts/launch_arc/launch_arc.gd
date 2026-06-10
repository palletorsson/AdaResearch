extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name LaunchArc

## @identity
## lineage: projectile motion made playable — a launch velocity bent into a parabola by
##   gravity — the F=ma / launch toy for the embodied vectors-forces arc (the pad that
##   throws you). Range = v² sin(2θ) / g; the arc is what F=ma does to a thrown vector.
## essence: a launch pad fires at angle θ with speed v; gravity pulls the path into a
##   parabola. The launch velocity decomposes into a horizontal vx and a vertical vy —
##   vx carries you, vy fights gravity, the trade between them sets the range.
## truth: you only ever launch a straight vector; the curve is the world's answer.
##
## A ToyConsole: the readout lives on the monitor, the ANGLE slider drives the demo.
## DNA: angle 0..1 sets the launch angle (flat → steep); power 0..1 the launch speed.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var angle: float = 0.5
@export_range(0.0, 1.0, 0.01) var power: float = 0.6
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # pad + component arrows
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the arc + launch vector
@export var accent: Color = Color(0.98, 0.72, 0.30)      # pad glow + apex / range
@export var complexity: int = 6

const GRAVITY := 3.0


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("angle"): angle = clampf(float(config_data["angle"]), 0.0, 1.0)
	if config_data.has("power"): power = clampf(float(config_data["power"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "LAUNCH ARC", "slider": "ANGLE"}

func _param_get() -> float:
	return angle

func _param_set(v: float) -> void:
	angle = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("LaunchArcRig")
	_rng.seed = hash(seed)

	# --- the launch -------------------------------------------------------------
	var theta: float = deg_to_rad(lerpf(22.0, 70.0, angle))
	var v0: float = lerpf(2.0, 3.4, power)
	var vx: float = v0 * cos(theta)
	var vy: float = v0 * sin(theta)
	var t_land: float = 2.0 * vy / GRAVITY
	var rng_x: float = vx * t_land                       # range
	var apex_t: float = vy / GRAVITY
	var apex: Vector3 = Vector3(vx * apex_t, vy * apex_t - 0.5 * GRAVITY * apex_t * apex_t, 0.0)
	var pad_y: float = 0.06
	var origin: Vector3 = Vector3(0.0, pad_y, 0.0)

	# --- the launch pad (echoes force_pad) --------------------------------------
	var pad := _box(origin, Vector3(0.42, 0.07, 0.42), _glow_mat(accent, 1.4 + power * 1.6))
	pad.rotation.z = theta * 0.5
	rig.add_child(pad)
	rig.add_child(_box(Vector3(0.0, pad_y - 0.06, 0.0), Vector3(0.5, 0.06, 0.5), _steel_mat(color_a)))
	var ground_len: float = rng_x + 0.5
	rig.add_child(_box(Vector3(ground_len * 0.5, -0.02, 0.0), Vector3(ground_len, 0.04, 0.6), _steel_mat(color_a)))

	# --- the trajectory (parabola of stroboscopic projectiles) ------------------
	var steps: int = clampi(complexity + 8, 12, 26)
	for i in range(steps + 1):
		var t: float = t_land * float(i) / float(steps)
		var py: float = pad_y + vy * t - 0.5 * GRAVITY * t * t
		rig.add_child(_sphere(Vector3(vx * t, py, 0.0), 0.05, _glow_mat(color_b, lerpf(1.4, 0.5, float(i) / float(steps)))))

	# --- the launch velocity vector + its vx / vy components --------------------
	var vis: float = 0.62
	var lv: Vector3 = origin + Vector3(cos(theta), sin(theta), 0.0) * v0 * vis
	rig.add_child(_arrow(origin, lv, 0.03, _glow_mat(color_b, 1.6)))
	var corner: Vector3 = origin + Vector3(vx * vis, 0.0, 0.0)
	rig.add_child(_dashed(origin, corner, 0.018, _glow_mat(color_a, 0.8)))
	rig.add_child(_dashed(corner, lv, 0.018, _glow_mat(color_a, 0.8)))

	# --- apex + range markers ---------------------------------------------------
	rig.add_child(_sphere(apex + Vector3(0.0, pad_y, 0.0), 0.075, _glow_mat(accent, 2.6)))
	rig.add_child(_sphere(Vector3(rng_x, pad_y, 0.0), 0.085, _glow_mat(accent, 2.8)))
	rig.add_child(_dashed(Vector3(apex.x, pad_y, 0.0), apex + Vector3(0.0, pad_y, 0.0), 0.01,
		_glow_mat(accent.lerp(Color(0.2, 0.2, 0.24), 0.4), 0.4)))

	# --- readout -> the monitor --------------------------------------------------
	set_readout("LAUNCH  proj.\n\nv₀ = %.1f  θ = %d°\nrange = %.2f" % [v0, int(roundf(rad_to_deg(theta))), rng_x],
		Color(1.0, 0.82, 0.5))

	_settle(rig)
