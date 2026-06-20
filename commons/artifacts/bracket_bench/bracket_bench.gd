extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BracketBench

## @identity
## lineage: bracketed L-systems → Lindenmayer's [ ] notation, the stack that turns a path into a plant
## essence: "[" remembers where the turtle was, "]" returns it there — so a branch can grow and the trunk resume
## truth: "[ ] = THE TREE TRICK" — branching is just a saved-and-restored state; the bracket is where the line becomes a tree
##
## MEDIUM tier. A bench showing a bracketed plant plus the bracket stack visualised:
## a small vertical stack of state markers beside it. Each push deepens the stack;
## each pop restores it. The markers make the invisible recursion stack visible.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 4
@export var angle_deg: float = 22.5
@export var plant_height: float = 0.7
@export var trunk_color: Color = Color(0.45, 0.30, 0.18)
@export var tip_color: Color = Color(0.40, 0.85, 0.35)
@export var bench_color: Color = Color(0.18, 0.19, 0.22)
@export var stack_color: Color = Color(0.95, 0.70, 0.25)


func _expand(axiom: String, rules: Dictionary, iter_count: int) -> String:
	var s := axiom
	for _i in range(iter_count):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("angle_deg"):
		angle_deg = float(config["angle_deg"])
	if config.has("plant_height"):
		plant_height = float(config["plant_height"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	# Bench base.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.1, 0.84, 0.7), _matte_mat(bench_color, 0.7)))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.12, 0.04, 0.72), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))
	add_child(_cylinder(Vector3(0.0, 0.20, 0.0), 0.05, 0.40, _steel_mat(Color(0.35, 0.37, 0.4))))

	# Classic bracketed plant. axiom "X", the [ ] are the branch trick.
	var axiom := "X"
	var rules := {
		"X": "F+[[X]-X]-F[-FX]+X",
		"F": "FF",
	}
	var grammar := _expand(axiom, rules, iters)
	var walk: Dictionary = LST.walk(grammar, {
		"angle_deg": angle_deg,
		"step_len": 0.05,
		"step_shrink": 0.82,
		"base_width": 0.018,
		"width_shrink": 0.74,
		"seed": 3,
	})

	var plant: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
	var raw_h: float = _walk_height(walk)
	var s: float = plant_height / maxf(raw_h, 0.001)
	plant.scale = Vector3.ONE * s
	plant.position = Vector3(-0.18, 0.88, 0.0)
	add_child(plant)

	# Bracket stack visualisation: a vertical stack of state markers beside the plant.
	# Count the maximum nesting depth of [ ] in the grammar to size the stack.
	var max_depth: int = _max_bracket_depth(grammar)
	max_depth = clampi(max_depth, 3, 7)
	var stack_x := 0.40
	var plate_mat := _glow_mat(stack_color, 1.3)
	var rod_mat := _steel_mat(Color(0.4, 0.42, 0.45))
	add_child(_cylinder_between(Vector3(stack_x, 0.88, 0.0), Vector3(stack_x, 0.88 + 0.06 * float(max_depth) + 0.06, 0.0), 0.006, rod_mat))
	for d in range(max_depth):
		var y := 0.90 + 0.06 * float(d)
		var w := 0.12 - 0.012 * float(d)
		add_child(_box(Vector3(stack_x, y, 0.0), Vector3(w, 0.018, 0.06), plate_mat))
	add_child(_billboard_label("STACK", Vector3(stack_x, 0.90 + 0.06 * float(max_depth) + 0.10, 0.0), 16, stack_color))

	add_child(_billboard_label("[ ] = THE TREE TRICK", Vector3(0.0, 1.6, 0.0), 28, tip_color))


func _walk_height(walk: Dictionary) -> float:
	var segments: Array = walk["segments"]
	var min_y := 1e9
	var max_y := -1e9
	for seg: Array in segments:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		min_y = minf(min_y, minf(a.y, b.y))
		max_y = maxf(max_y, maxf(a.y, b.y))
	if max_y <= min_y:
		return 1.0
	return max_y - min_y


func _max_bracket_depth(grammar: String) -> int:
	var depth := 0
	var best := 0
	for ch: String in grammar:
		if ch == "[":
			depth += 1
			best = maxi(best, depth)
		elif ch == "]":
			depth = maxi(0, depth - 1)
	return best


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	pass
