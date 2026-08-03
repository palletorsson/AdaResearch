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

## AXIS — HOW MUCH OF THE ARITHMETIC THE BENCH DRAWS. Adopted word for word (and value
## for value, in order) from [[transform_composition_workbench]] and shared across the
## whole vector subject.
##
##   outcome     where it lands. The stroboscopic parabola and the faint vx/vy legs leave
##               the render layers; the pad, the launch vector, the apex ball and the
##               range ball remain. A throw is a destination — the flight is not shown.
##   trace       the legacy lineage, byte for byte — the whole flight strobed as a run of
##               fading spheres. The answer is a path you can count frames along.
##   operands    the two components that make the arc, promoted from dashed guides to
##               solid arrows standing at the origin with a right-angle marker between
##               them, plus a ground rule under the range. vx carries you, vy fights
##               gravity; the parabola above is what they make together.
##   expression  the algebra promoted over the geometry — a light board writing
##               R = v₀² sin 2θ / g with the numbers substituted, between two emissive
##               rules in the accent colour.
##
## The strobe is the pivot: 12–26 emissive spheres are the brightest mass in any frame,
## and outcome is the only value that takes them out.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "trace"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

const GRAVITY := 3.0


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("angle"): angle = clampf(float(config_data["angle"]), 0.0, 1.0)
	if config_data.has("power"): power = clampf(float(config_data["power"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("workings"):
		var _w: String = String(config_data["workings"]).strip_edges().to_lower()
		workings = _w if WORKINGS.has(_w) else workings
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
	var strobe := Node3D.new()
	strobe.name = "Strobe"
	rig.add_child(strobe)
	var steps: int = clampi(complexity + 8, 12, 26)
	for i in range(steps + 1):
		var t: float = t_land * float(i) / float(steps)
		var py: float = pad_y + vy * t - 0.5 * GRAVITY * t * t
		strobe.add_child(_sphere(Vector3(vx * t, py, 0.0), 0.05, _glow_mat(color_b, lerpf(1.4, 0.5, float(i) / float(steps)))))

	# --- the launch velocity vector + its vx / vy components --------------------
	var vis: float = 0.62
	var lv: Vector3 = origin + Vector3(cos(theta), sin(theta), 0.0) * v0 * vis
	rig.add_child(_arrow(origin, lv, 0.03, _glow_mat(color_b, 1.6)))
	var corner: Vector3 = origin + Vector3(vx * vis, 0.0, 0.0)
	var leg_x: Node3D = _dashed(origin, corner, 0.018, _glow_mat(color_a, 0.8))
	var leg_y: Node3D = _dashed(corner, lv, 0.018, _glow_mat(color_a, 0.8))
	rig.add_child(leg_x)
	rig.add_child(leg_y)

	# --- apex + range markers ---------------------------------------------------
	rig.add_child(_sphere(apex + Vector3(0.0, pad_y, 0.0), 0.075, _glow_mat(accent, 2.6)))
	rig.add_child(_sphere(Vector3(rng_x, pad_y, 0.0), 0.085, _glow_mat(accent, 2.8)))
	rig.add_child(_dashed(Vector3(apex.x, pad_y, 0.0), apex + Vector3(0.0, pad_y, 0.0), 0.01,
		_glow_mat(accent.lerp(Color(0.2, 0.2, 0.24), 0.4), 0.4)))

	# --- readout -> the monitor --------------------------------------------------
	set_readout("LAUNCH  proj.\n\nv₀ = %.1f  θ = %d°\nrange = %.2f" % [v0, int(roundf(rad_to_deg(theta))), rng_x],
		Color(1.0, 0.82, 0.5))

	_settle(rig)

	# WORKINGS dressing, appended AFTER _settle so the legacy geometry keeps the exact
	# fit and placement it has today. "trace" falls through and adds nothing.
	match _workings_value():
		"outcome":
			_workings_outcome(strobe, leg_x, leg_y)
		"operands":
			_workings_operands(rig, origin, corner, lv, rng_x, pad_y, leg_x, leg_y)
		"expression":
			_workings_expression(rig, v0, theta, rng_x, apex.y + pad_y)
		_:
			pass                                   # "trace" — the legacy lineage


# --- WORKINGS ---------------------------------------------------------------
# One axis, four values, shared word for word with the rest of the vector subject.
# Removal is always `layers = 0` on the MeshInstance3D leaves — never `visible = false`,
# which in Godot takes a holder's whole subtree with it.

func _workings_value() -> String:
	var w: String = String(workings).strip_edges().to_lower()
	return w if WORKINGS.has(w) else "trace"


func _unlayer(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).layers = 0
	for child in n.get_children():
		_unlayer(child)


## OUTCOME — where it lands. The whole strobed flight and both faint component legs leave
## the render layers; the pad, the launch vector, the apex ball and the range ball stay.
## You are handed the two numbers a ballistics table would give you and nothing else.
func _workings_outcome(strobe: Node3D, leg_x: Node3D, leg_y: Node3D) -> void:
	_unlayer(strobe)
	_unlayer(leg_x)
	_unlayer(leg_y)


## OPERANDS — the ingredients laid out. The dashed guides are retired and vx and vy stand
## as solid arrows at the origin with a square right-angle marker between them, and a rule
## runs along the ground under the range. The parabola above still shows what they make.
func _workings_operands(rig: Node3D, origin: Vector3, corner: Vector3, lv: Vector3,
		rng_x: float, pad_y: float, leg_x: Node3D, leg_y: Node3D) -> void:
	_unlayer(leg_x)
	_unlayer(leg_y)
	var mat_x := _glow_mat(color_a.lerp(color_b, 0.45), 1.5)
	var mat_y := _glow_mat(accent, 1.5)
	rig.add_child(_arrow(origin, corner, 0.026, mat_x))                       # vx — carries you
	rig.add_child(_arrow(origin, Vector3(origin.x, lv.y, 0.0), 0.026, mat_y))  # vy — fights gravity
	rig.add_child(_dashed(Vector3(origin.x, lv.y, 0.0), lv, 0.012, mat_x))
	rig.add_child(_dashed(corner, lv, 0.012, mat_y))
	# the square that says "these two are perpendicular"
	var q: float = 0.11
	rig.add_child(_box(Vector3(origin.x + q * 0.5, origin.y + q, 0.0), Vector3(q, 0.012, 0.012), mat_y))
	rig.add_child(_box(Vector3(origin.x + q, origin.y + q * 0.5, 0.0), Vector3(0.012, q, 0.012), mat_y))
	# a measured rule along the ground under the range
	rig.add_child(_box(Vector3(rng_x * 0.5, pad_y - 0.13, 0.0), Vector3(rng_x, 0.02, 0.02), _glow_mat(accent, 1.2)))
	for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
		rig.add_child(_box(Vector3(rng_x * f, pad_y - 0.09, 0.0), Vector3(0.02, 0.09, 0.02), _glow_mat(accent, 1.2)))


## EXPRESSION — the algebra promoted over the geometry. A light Braun plate above the arc
## writes the range identity out with the numbers substituted, held between two emissive
## rules so the writing owns hot pixels of its own.
func _workings_expression(rig: Node3D, v0: float, theta: float, rng_x: float, apex_y: float) -> void:
	var board := Node3D.new()
	board.name = "WorkingsBoard"
	board.position = Vector3(rng_x * 0.5, apex_y + 0.62, 0.0)
	rig.add_child(board)
	board.add_child(_box(Vector3.ZERO, Vector3(2.05, 0.52, 0.03), _panel_mat(PANEL_LIGHT)))
	board.add_child(_box(Vector3(0.0, 0.26, 0.02), Vector3(2.05, 0.030, 0.02), _glow_mat(accent, 1.9)))
	board.add_child(_box(Vector3(0.0, -0.26, 0.02), Vector3(2.05, 0.030, 0.02), _glow_mat(accent, 1.9)))
	var l := Label3D.new()
	l.name = "Algebra"
	l.text = "R  =  v₀² sin 2θ / g\n%.1f² × sin %d°  /  %.1f  =  %.2f" % [
		v0, int(roundf(rad_to_deg(theta) * 2.0)), GRAVITY, rng_x]
	l.font_size = 40
	l.pixel_size = 0.0034
	l.modulate = TEXT_DARK
	l.outline_size = 6
	l.outline_modulate = Color(0.90, 0.88, 0.84, 0.9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector3(0.0, 0.0, 0.03)
	board.add_child(l)
