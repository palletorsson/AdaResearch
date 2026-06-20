extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TreeNursery

## @identity
## lineage: L-system trees as a parameter family — one grammar, many trees, tuned by angle and depth
## essence: a row of pots, each running the same rules with different knobs, so you read the rule by its variations
## truth: "TREE NURSERY" — the rule is the species; angle and iteration are the weather and the age that vary the individual
##
## APPLIED tier. A nursery device: a row of ~4 pots, each growing a different L-system
## tree by varying angle / iters per pot. Each tree is its own MultiMesh (one draw call
## per pot). Built once, static.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var pot_count: int = 4
@export var pot_spacing: float = 0.32
@export var pot_tree_height: float = 0.55
@export var trunk_color: Color = Color(0.42, 0.28, 0.17)
@export var tip_color: Color = Color(0.50, 0.85, 0.38)
@export var bench_color: Color = Color(0.16, 0.17, 0.20)
@export var pot_color: Color = Color(0.55, 0.35, 0.25)


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
	if config.has("pot_count"):
		pot_count = int(config["pot_count"])
	if config.has("pot_tree_height"):
		pot_tree_height = float(config["pot_tree_height"])
	if config.has("trunk_color"):
		trunk_color = _parse_color(config["trunk_color"], trunk_color)
	if config.has("tip_color"):
		tip_color = _parse_color(config["tip_color"], tip_color)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	pot_count = clampi(pot_count, 1, 8)
	var total_w: float = pot_spacing * float(pot_count) + 0.18

	# Nursery bench (long, low device).
	add_child(_box(Vector3(0.0, 0.40, 0.0), Vector3(total_w, 0.80, 0.34), _matte_mat(bench_color, 0.7)))
	add_child(_box(Vector3(0.0, 0.81, 0.0), Vector3(total_w + 0.02, 0.04, 0.36), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))

	# Per-pot parameter variations of the same grammar.
	var rules := {
		"X": "F+[[X]-X]-F[-FX]+X",
		"F": "FF",
	}
	# Each entry: [angle_deg, iters, seed].
	var variants: Array = [
		[18.0, 4, 11],
		[22.5, 4, 12],
		[28.0, 5, 13],
		[35.0, 3, 14],
	]

	var start_x: float = -pot_spacing * float(pot_count - 1) * 0.5
	var pot_mat := _matte_mat(pot_color, 0.7)
	var soil_mat := _matte_mat(Color(0.12, 0.09, 0.07), 0.9)
	var rod_mat := _steel_mat(Color(0.4, 0.42, 0.45))

	for i in range(pot_count):
		var px: float = start_x + pot_spacing * float(i)
		var v: Array = variants[i % variants.size()]
		var ang: float = float(v[0])
		var it: int = int(v[1])
		var sd: int = int(v[2])

		# Pot + soil.
		add_child(_cylinder(Vector3(px, 0.88, 0.0), 0.07, 0.10, pot_mat))
		add_child(_cylinder(Vector3(px, 0.93, 0.0), 0.065, 0.012, soil_mat))

		# Grow the tree for this pot.
		var grammar := _expand("X", rules, it)
		var walk: Dictionary = LST.walk(grammar, {
			"angle_deg": ang,
			"step_len": 0.05,
			"step_shrink": 0.80,
			"base_width": 0.015,
			"width_shrink": 0.72,
			"seed": sd,
		})
		var tree: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
		var raw_h: float = _walk_height(walk)
		var s: float = pot_tree_height / maxf(raw_h, 0.001)
		tree.scale = Vector3.ONE * s
		tree.position = Vector3(px, 0.935, 0.0)
		add_child(tree)

		# Tiny label tag on the pot showing the angle (the varied knob).
		add_child(_billboard_label("%d" % int(ang) + "°", Vector3(px, 0.82, 0.20), 12, tip_color))

	# Front rail.
	add_child(_cylinder_between(Vector3(start_x - 0.1, 0.84, 0.18), Vector3(start_x + pot_spacing * float(pot_count - 1) + 0.1, 0.84, 0.18), 0.006, rod_mat))

	add_child(_billboard_label("TREE NURSERY", Vector3(0.0, 1.35, 0.0), 22, tip_color))


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
