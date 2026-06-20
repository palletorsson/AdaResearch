extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TurtleRoom

## @identity
## lineage: Turtle interpretation room — a room-scale L-system curve laid on the floor,
##   a Sierpinski arrowhead you trace on foot.
## essence: the drawing is the architecture. You become the turtle, walking the same
##   forward/turn the grammar dictates.
## truth: the turtle draws the grammar. A handful of symbols, parallel-rewritten, fills
##   a whole room with a single unbroken edge that never crosses itself.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var iterations: int = 5
@export var angle_deg: float = 60.0
@export var trunk_color: Color = Color(0.40, 0.85, 1.0)
@export var tip_color: Color = Color(0.65, 0.55, 1.0)


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
	# --- room floor ---
	var floor_mat := _matte_mat(Color(0.10, 0.11, 0.13), 0.92)
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.1, 7), floor_mat))

	# --- the big curve: Sierpinski arrowhead (A and B both draw, 60° turns) ---
	# axiom "A", A -> B-A-B, B -> A+B+A — a single self-similar edge filling a triangle.
	var axiom := "A"
	var rules := {"A": "B-A-B", "B": "A+B+A"}
	var expanded := _expand(axiom, rules, iterations)
	# A and B are both "draw" symbols for this curve; the turtle treats them as F.
	var draw_string := expanded.replace("A", "F").replace("B", "F")
	var walk: Dictionary = LST.walk(draw_string, {
		"angle_deg": angle_deg, "step_len": 0.10, "step_shrink": 1.0,
		"base_width": 0.02, "width_shrink": 1.0, "seed": 1,
	})
	# the turtle draws in the X/Y plane; lay it flat on the floor and scale to ~4m.
	var curve: MeshInstance3D = LST.to_lines(walk, trunk_color, tip_color)
	curve.rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # X/Y plane -> floor (X/Z)
	curve.name = "Curve"
	add_child(curve)
	_fit_floor_curve(curve, walk, 4.4, 0.08)

	# --- corner markers so the form reads as a triangle ---
	var node_mat := _glow_mat(Color(1.0, 0.80, 0.35), 0.9)
	for ang: float in [90.0, 210.0, 330.0]:
		var r := deg_to_rad(ang)
		add_child(_sphere(Vector3(cos(r) * 2.3, 0.08, sin(r) * 2.3), 0.10, node_mat))

	# --- overhead label ---
	add_child(_billboard_label("THE TURTLE DRAWS THE GRAMMAR", Vector3(0, 3.6, 0.0), 34, Color(0.88, 0.94, 1.0)))


func _fit_floor_curve(curve: MeshInstance3D, walk: Dictionary, target_span: float, lift: float) -> void:
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
	# centre the curve's local X/Y midpoint over the room origin (post -90° X rotation,
	# local +Y maps to world -Z).
	var cx := (mn.x + mx.x) * 0.5 * s
	var cy := (mn.y + mx.y) * 0.5 * s
	curve.position = Vector3(-cx, lift, cy)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# room curve is static; nothing to animate.
	pass
