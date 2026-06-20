extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BracketRoom

## @identity
## lineage: bracketed branching at room scale — Lindenmayer's stack grown until it is architecture
## essence: every "[" is a push, every "]" a pop; nest them and a single rule erupts into a canopy of branches
## truth: "PUSH, BRANCH, POP" — the whole tree is one string read by a turtle that remembers and returns
##
## LARGE tier. A room-scale bracketed tree, tall (~3-4m), many branches, that you can
## stand beneath. Tubes → one MultiMesh, one draw call. Higher iters = denser canopy.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 5
@export var angle_deg: float = 24.0
@export var tree_height: float = 3.6
@export var trunk_color: Color = Color(0.40, 0.26, 0.16)
@export var tip_color: Color = Color(0.45, 0.85, 0.40)
@export var floor_color: Color = Color(0.10, 0.11, 0.13)


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
	if config.has("tree_height"):
		tree_height = float(config["tree_height"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	# Room floor.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_color, 0.7)))

	# A bracketed tree with a 3D twist (roll on each branch) so the canopy has depth.
	var axiom := "X"
	var rules := {
		"X": "F[+X][-X][/X][\\X]FX",
		"F": "FF",
	}
	var grammar := _expand(axiom, rules, iters)
	var walk: Dictionary = LST.walk(grammar, {
		"angle_deg": angle_deg,
		"step_len": 0.06,
		"step_shrink": 0.80,
		"base_width": 0.05,
		"width_shrink": 0.70,
		"seed": 7,
	})

	var tree: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
	var raw_h: float = _walk_height(walk)
	var s: float = tree_height / maxf(raw_h, 0.001)
	tree.scale = Vector3.ONE * s
	tree.position = Vector3(0.0, 0.0, 0.0)
	add_child(tree)

	# A low ring at the base so the trunk reads as planted.
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.35, 0.04, _steel_mat(Color(0.30, 0.32, 0.35))))

	add_child(_billboard_label("PUSH, BRANCH, POP", Vector3(0.0, 3.6, 0.0), 48, tip_color))


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


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	pass
