extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GroveRoom

## @identity
## name: "Forest & ecology (biome)"
## tier: large
## truth: "many grammars in one world, competing for light — the L-system becomes the biome that plants it"
##
## A room-scale grove. Around eight L-system trees, each from a different seed
## and grown to a different height (2–4m), stand across a soft ground. No single
## plant — a population. The grammar has stopped being one tree and become the
## biome that plants it: walk in and you are inside the forest the rules grew.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 5
@export var angle: float = 25.7
@export var tree_seed: int = 23
@export var tree_count: int = 8
@export var floor_size: float = 7.0
@export var bark_col: Color = Color(0.32, 0.22, 0.14)
@export var canopy_young: Color = Color(0.46, 0.74, 0.34)
@export var canopy_old: Color = Color(0.16, 0.42, 0.20)
@export var ground_col: Color = Color(0.20, 0.30, 0.18)
@export var label_col: Color = Color(0.58, 0.82, 0.44)

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
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
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
	# --- soft ground --------------------------------------------------------
	var ground_mat: StandardMaterial3D = _matte_mat(ground_col, 1.0)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), ground_mat))

	# scatter a few mossy stones / clumps for ground texture
	var stone_mat: StandardMaterial3D = _matte_mat(Color(0.26, 0.30, 0.24), 0.95)
	var srng := RandomNumberGenerator.new()
	srng.seed = tree_seed * 31 + 5
	var half: float = floor_size * 0.5 - 0.4
	for _s in range(10):
		var sx: float = srng.randf_range(-half, half)
		var sz: float = srng.randf_range(-half, half)
		var sr: float = srng.randf_range(0.08, 0.18)
		add_child(_sphere(Vector3(sx, 0.0, sz), sr, stone_mat))

	# --- the grove: a population of grammars --------------------------------
	var n: int = max(tree_count, 4)
	var ring_r: float = floor_size * 0.32
	for i in range(n):
		var seed_i: int = tree_seed + i * 17
		var lrng := RandomNumberGenerator.new()
		lrng.seed = seed_i
		var it: int = iters + (1 if i % 4 == 0 else 0)
		var ang: float = angle + lrng.randf_range(-5.0, 5.0)

		var age: float = lrng.randf()
		var tip_col: Color = canopy_young.lerp(canopy_old, age)

		var walk: Dictionary = LST.walk(
			_expand("X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, it),
			{
				"angle_deg": ang,
				"step_len": 0.07,
				"step_shrink": 0.8,
				"base_width": 0.026,
				"width_shrink": 0.72,
				"seed": seed_i,
			}
		)

		var holder := Node3D.new()
		holder.name = "GroveTree%d" % i
		add_child(holder)
		_trees.append(holder)

		var tree: MultiMeshInstance3D = LST.to_tubes(walk, bark_col, tip_col, 6)
		holder.add_child(tree)

		# leaf clusters at the tips
		var leaf_mat: StandardMaterial3D = _matte_mat(tip_col, 0.7)
		var leaves: Array = walk.get("leaves", [])
		for li in range(leaves.size()):
			if li % 2 != 0:
				continue
			holder.add_child(_sphere(leaves[li], 0.06, leaf_mat))

		# height 2–4m, varied per tree (competing for light)
		var target_h: float = lerpf(2.0, 4.0, age)
		_settle(holder, target_h)

		# place around the room — a loose ring plus jitter, plus one or two near centre
		var px: float
		var pz: float
		if i < 2:
			px = lrng.randf_range(-1.2, 1.2)
			pz = lrng.randf_range(-1.2, 1.2)
		else:
			var theta: float = (float(i) / float(n)) * TAU + lrng.randf_range(-0.25, 0.25)
			var rr: float = ring_r + lrng.randf_range(-0.6, 0.8)
			px = cos(theta) * rr
			pz = sin(theta) * rr
		holder.position = Vector3(px, 0.0, pz)
		holder.rotation.y = lrng.randf_range(-PI, PI)

	add_child(_billboard_label("THE GRAMMAR BECOMES THE BIOME", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for i in range(_trees.size()):
		var tr: Node3D = _trees[i]
		var ph: float = float(i) * 0.9
		tr.rotation.z = sin(_t * 0.5 + ph) * 0.02
		tr.rotation.x = cos(_t * 0.4 + ph) * 0.015
