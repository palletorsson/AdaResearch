extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CurvePlotter

## @identity
## lineage: Dragon & classic curves, applied — a plotter that cycles the canon: Heighway
##   dragon, Lévy C, Gosper (flowsnake), one every couple of seconds.
## essence: a single machine loaded with a library of grammars. Swap the production
##   rules and the same turtle draws an entirely different classic curve.
## truth: the turtle is universal; the curve lives in the rules. Three famous fractals
##   are three short strings fed to one interpreter — change the seed-grammar, change
##   the world it draws.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cycle_seconds: float = 2.0
@export var ink_color: Color = Color(0.35, 0.75, 1.0)
@export var ink_tip_color: Color = Color(0.70, 0.95, 1.0)

var _curve_index: int = 0
var _timer: float = 0.0

# Each entry: name, axiom, rules, angle_deg, iters, and the draw-symbol map.
# "draw" lists symbols the turtle should treat as F (some grammars use A/B as draw).
const CURVES := [
	{
		"name": "DRAGON",
		"axiom": "FX",
		"rules": {"X": "X+YF+", "Y": "-FX-Y"},
		"angle": 90.0, "iters": 11, "draw": ["F"],
	},
	{
		"name": "LEVY C",
		"axiom": "F",
		"rules": {"F": "+F--F+"},
		"angle": 45.0, "iters": 12, "draw": ["F"],
	},
	{
		"name": "GOSPER",
		"axiom": "A",
		"rules": {"A": "A-B--B+A++AA+B-", "B": "+A-BB--B-A++A+B"},
		"angle": 60.0, "iters": 4, "draw": ["A", "B"],
	},
]


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _expand(axiom: String, rules: Dictionary, iters: int) -> String:
	var s := axiom
	for _i in range(iters):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	# --- plotter body: a ~1m device with a square plate ---
	var body_mat := _matte_mat(Color(0.17, 0.18, 0.21), 0.8)
	add_child(_box(Vector3(0, 0.06, 0), Vector3(0.95, 0.12, 0.95), body_mat))
	var plate_mat := _matte_mat(Color(0.08, 0.09, 0.12), 0.6)
	add_child(_box(Vector3(0, 0.125, 0), Vector3(0.80, 0.02, 0.80), plate_mat))
	var rail_mat := _steel_mat(Color(0.55, 0.57, 0.60))
	for sx: float in [-0.42, 0.42]:
		add_child(_cylinder_between(Vector3(sx, 0.20, -0.42), Vector3(sx, 0.20, 0.42), 0.012, rail_mat))
	# arm pivot post in a corner — the swinging turtle arm
	add_child(_cylinder(Vector3(0.0, 0.22, 0.0), 0.025, 0.20, rail_mat))

	# --- readout label panel ---
	add_child(_box(Vector3(0.0, 0.40, -0.50), Vector3(0.6, 0.18, 0.02), _glow_mat(Color(0.07, 0.10, 0.14), 0.6)))
	var name_label := _billboard_label("DRAGON", Vector3(0.0, 0.40, -0.48), 22, Color(0.70, 0.95, 1.0))
	name_label.name = "CurveName"
	add_child(name_label)
	add_child(_billboard_label("CURVE PLOTTER", Vector3(0, 0.66, 0), 26, Color(0.85, 0.95, 1.0)))

	# --- the current curve, drawn flat on the plate ---
	_draw_current_curve()


func _draw_current_curve() -> void:
	# remove only the previous curve, keep the device.
	var old := get_node_or_null("Curve")
	if old:
		remove_child(old)
		old.queue_free()

	var spec: Dictionary = CURVES[_curve_index]
	var rules: Dictionary = spec["rules"]
	var expanded := _expand(String(spec["axiom"]), rules, int(spec["iters"]))
	# map every draw symbol to F so the turtle draws it.
	var draw_string := expanded
	for sym: String in spec["draw"]:
		draw_string = draw_string.replace(sym, "F")
	# strip any non-turtle symbols that are pure rewrite variables (X, Y, A, B left over).
	for stray: String in ["X", "Y", "A", "B"]:
		draw_string = draw_string.replace(stray, "")

	var walk: Dictionary = LST.walk(draw_string, {
		"angle_deg": float(spec["angle"]), "step_len": 0.05, "step_shrink": 1.0,
		"base_width": 0.012, "width_shrink": 1.0, "seed": 1,
	})
	var curve: MeshInstance3D = LST.to_lines(walk, ink_color, ink_tip_color)
	curve.rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # draw plane -> plate
	curve.name = "Curve"
	add_child(curve)
	_fit_plate_curve(curve, walk, 0.7, 0.138)

	var name_label := get_node_or_null("CurveName")
	if name_label and name_label is Label3D:
		(name_label as Label3D).text = String(spec["name"])


func _fit_plate_curve(curve: MeshInstance3D, walk: Dictionary, target_span: float, lift: float) -> void:
	var segments: Array = walk["segments"]
	if segments.is_empty():
		return
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for seg: Array in segments:
		for k: int in [0, 1]:
			var p: Vector3 = seg[k]
			mn = Vector3(minf(mn.x, p.x), minf(mn.y, p.y), minf(mn.z, p.z))
			mx = Vector3(maxf(mx.x, p.x), maxf(mx.y, p.y), maxf(mx.z, p.z))
	var span := maxf(mx.x - mn.x, mx.y - mn.y)
	var s := target_span / maxf(span, 0.001)
	curve.scale = Vector3.ONE * s
	var cx := (mn.x + mx.x) * 0.5 * s
	var cy := (mn.y + mx.y) * 0.5 * s
	curve.position = Vector3(-cx, lift, cy)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# rebuild to the next curve only on the timer — NOT every frame.
	_timer += delta
	if _timer >= cycle_seconds:
		_timer = 0.0
		_curve_index = (_curve_index + 1) % CURVES.size()
		_draw_current_curve()
