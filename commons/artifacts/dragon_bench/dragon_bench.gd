extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DragonBench

## @identity
## lineage: Dragon & classic curves bench — the Heighway dragon drawn from FX with two
##   rules, on a workbench beside its grammar.
## essence: a tabletop where eleven rewrites of four symbols produce a shape that looks
##   like turbulence but folds from perfect order.
## truth: order that reads as chaos. Every turn is a right angle, fully determined; the
##   apparent randomness is the eye failing to see the rule. Determinism wearing noise.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 11
@export var angle_deg: float = 90.0
@export var trunk_color: Color = Color(1.0, 0.45, 0.25)
@export var tip_color: Color = Color(1.0, 0.85, 0.30)
@export var panel_color: Color = Color(0.10, 0.12, 0.16)


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
	# --- bench base ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.20), 0.85)
	add_child(_box(Vector3(0, 0.42, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	var leg_mat := _steel_mat(Color(0.30, 0.31, 0.34))
	for sx: float in [-0.45, 0.45]:
		for sz: float in [-0.27, 0.27]:
			add_child(_cylinder(Vector3(sx, 0.21, sz), 0.03, 0.42, leg_mat))
	var pillar_mat := _steel_mat(Color(0.34, 0.35, 0.38))
	add_child(_cylinder(Vector3(0, 0.66, 0.1), 0.05, 0.32, pillar_mat))
	add_child(_cylinder(Vector3(0, 0.84, 0.1), 0.10, 0.03, pillar_mat))

	# --- grammar panel ---
	var panel_mat := _glow_mat(panel_color, 0.6)
	add_child(_box(Vector3(0, 1.05, -0.20), Vector3(0.96, 0.30, 0.02), panel_mat))
	add_child(_billboard_label("DRAGON GRAMMAR", Vector3(0, 1.16, -0.18), 20, Color(1.0, 0.75, 0.50)))
	add_child(_billboard_label("X -> X+YF+", Vector3(0, 1.05, -0.18), 18, Color(0.95, 0.95, 0.90)))
	add_child(_billboard_label("Y -> -FX-Y", Vector3(0, 0.96, -0.18), 18, Color(0.95, 0.95, 0.90)))

	# --- the dragon curve, on top, facing +Z ---
	var axiom := "FX"
	var rules := {"X": "X+YF+", "Y": "-FX-Y"}
	var walk: Dictionary = LST.walk(_expand(axiom, rules, iterations), {
		"angle_deg": angle_deg, "step_len": 0.05, "step_shrink": 1.0,
		"base_width": 0.012, "width_shrink": 1.0, "seed": 1,
	})
	var curve: MeshInstance3D = LST.to_lines(walk, trunk_color, tip_color)
	curve.name = "Dragon"
	add_child(curve)
	# the dragon draws in the X/Y plane; keep it upright facing +Z, fit onto the pillar.
	_fit_upright_curve(curve, walk, 0.62, Vector3(0.0, 1.18, 0.10))

	# --- title label ---
	add_child(_billboard_label("DRAGON CURVE / order that reads as chaos", Vector3(0, 1.62, 0.1), 24, Color(0.95, 0.88, 0.80)))


func _fit_upright_curve(curve: MeshInstance3D, walk: Dictionary, target_span: float, anchor: Vector3) -> void:
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
	# centre the X/Y midpoint on the anchor (curve lives in the X/Y plane => world X/Y).
	var cx := (mn.x + mx.x) * 0.5 * s
	var cy := (mn.y + mx.y) * 0.5 * s
	curve.position = Vector3(anchor.x - cx, anchor.y - cy, anchor.z)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var dragon := get_node_or_null("Dragon")
	if dragon:
		dragon.rotation.y = sin(Time.get_ticks_msec() * 0.0006) * 0.25
