extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ForestBench

## @identity
## name: "Forest & ecology (biome)"
## tier: medium
## truth: "many grammars in one world, competing for light — the L-system becomes the biome that plants it"
##
## A bench-top stand: four-to-five small L-system trees, each from a different
## seed, crowded onto one surface and competing for space. Tinted from
## sapling-green to mature so the stand reads as a population at different ages —
## the same grammar, run with different parameters, becomes a forest.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 4
@export var angle: float = 24.0
@export var tree_seed: int = 11
@export var tree_count: int = 5
@export var bark_col: Color = Color(0.34, 0.24, 0.15)
@export var sapling_green: Color = Color(0.55, 0.83, 0.40)
@export var mature_green: Color = Color(0.20, 0.46, 0.22)
@export var bench_col: Color = Color(0.30, 0.32, 0.34)
@export var label_col: Color = Color(0.62, 0.84, 0.46)

var _t: float = 0.0
var _trees: Array[Node3D] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("iters"):
		iters = int(config["iters"])
	if config.has("angle"):
		angle = float(config["angle"])
	if config.has("tree_seed"):
		tree_seed = int(config["tree_seed"])
	if config.has("tree_count"):
		tree_count = int(config["tree_count"])
	if config.has("bark_col"):
		bark_col = _parse_color(config["bark_col"], bark_col)
	for c in get_children():
		c.queue_free()
	_trees.clear()
	_build()


func _expand(axiom: String, rules: Dictionary, n: int) -> String:
	var s := axiom
	for _i in range(n):
		var out := ""
		for ch: String in s:
			out += String(rules.get(ch, ch))
		s = out
	return s


func _build() -> void:
	# --- bench base ---------------------------------------------------------
	var top_y: float = 0.85
	var top_mat: StandardMaterial3D = _matte_mat(bench_col, 0.6, 0.1)
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.1, 0.08, 0.55), top_mat))
	# soil tray on top so the trees read as planted in a shared bed
	var soil_mat: StandardMaterial3D = _matte_mat(Color(0.20, 0.15, 0.10), 1.0)
	add_child(_box(Vector3(0.0, top_y + 0.05, 0.0), Vector3(1.0, 0.04, 0.46), soil_mat))
	# central pillar / leg
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.22, 0.23, 0.25))
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.07, top_y, leg_mat))
	add_child(_cylinder(Vector3(0.0, 0.02, 0.0), 0.22, 0.04, leg_mat))

	# --- the stand: many grammars, one world --------------------------------
	var surface_y: float = top_y + 0.07
	var n: int = max(tree_count, 3)
	for i in range(n):
		var seed_i: int = tree_seed + i * 13
		var lrng := RandomNumberGenerator.new()
		lrng.seed = seed_i
		var it: int = iters + (1 if i % 3 == 0 else 0)
		var ang: float = angle + lrng.randf_range(-4.0, 4.0)

		# tint each tree somewhere on the sapling→mature axis (age in the stand)
		var age: float = float(i) / float(max(n - 1, 1))
		var tip_col: Color = sapling_green.lerp(mature_green, age)

		var walk: Dictionary = LST.walk(
			_expand("X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, it),
			{
				"angle_deg": ang,
				"step_len": 0.07,
				"step_shrink": 0.8,
				"base_width": 0.022,
				"width_shrink": 0.72,
				"seed": seed_i,
			}
		)

		var holder := Node3D.new()
		holder.name = "BenchTree%d" % i
		add_child(holder)
		_trees.append(holder)

		var tree: MultiMeshInstance3D = LST.to_tubes(walk, bark_col, tip_col, 6)
		holder.add_child(tree)

		# a few leaf buds for the younger ones
		if age < 0.6:
			var leaf_mat: StandardMaterial3D = _matte_mat(tip_col, 0.7)
			var leaves: Array = walk.get("leaves", [])
			for li in range(leaves.size()):
				if li % 3 != 0:
					continue
				holder.add_child(_sphere(leaves[li], 0.012, leaf_mat))

		# normalize each tree to ~0.7m, then crowd them across the bed competing
		_settle(holder, 0.6 + age * 0.18)
		var spread_x: float = lerpf(-0.42, 0.42, float(i) / float(max(n - 1, 1)))
		var spread_z: float = lrng.randf_range(-0.16, 0.16)
		holder.position = Vector3(spread_x, surface_y, spread_z)
		holder.rotation.y = lrng.randf_range(-PI, PI)

	add_child(_billboard_label("MANY GRAMMARS, ONE WORLD", Vector3(0.0, 1.6, 0.0), 18, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for i in range(_trees.size()):
		var tr: Node3D = _trees[i]
		var ph: float = float(i) * 0.7
		tr.rotation.z = sin(_t * 0.9 + ph) * 0.025
		tr.rotation.x = cos(_t * 0.7 + ph) * 0.02
