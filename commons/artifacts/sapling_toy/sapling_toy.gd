extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SaplingToy

## @identity
## name: "Forest & ecology (biome)"
## tier: small
## truth: "many grammars in one world, competing for light — the L-system becomes the biome that plants it"
##
## A single young sapling, held in the hand. Low iterations: the very start of a
## forest. One grammar, just beginning to express itself as biology — a rule set
## unfolding into a living shape that will, given more iterations and more seeds,
## become a whole stand.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var emissive_label: bool = true
@export var iters: int = 3
@export var angle: float = 22.5
@export var tree_seed: int = 7
@export var bark_col: Color = Color(0.36, 0.26, 0.16)
@export var leaf_col: Color = Color(0.45, 0.72, 0.32)
@export var sapling_green: Color = Color(0.55, 0.82, 0.40)

var _t: float = 0.0
var _sway_root: Node3D = null


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
	if config.has("bark_col"):
		bark_col = _parse_color(config["bark_col"], bark_col)
	if config.has("leaf_col"):
		leaf_col = _parse_color(config["leaf_col"], leaf_col)
	for c in get_children():
		c.queue_free()
	_sway_root = null
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
	# Held toy — no table, no housing. Just the sapling near origin, ~0.4m tall.
	var root := Node3D.new()
	root.name = "SaplingSway"
	add_child(root)
	_sway_root = root

	var walk: Dictionary = LST.walk(
		_expand("X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, iters),
		{
			"angle_deg": angle,
			"step_len": 0.07,
			"step_shrink": 0.8,
			"base_width": 0.022,
			"width_shrink": 0.72,
			"seed": tree_seed,
		}
	)

	var tree: MultiMeshInstance3D = LST.to_tubes(walk, bark_col, sapling_green, 6)
	root.add_child(tree)

	# Young sapling tips — a few soft green leaf buds.
	var leaf_mat: StandardMaterial3D = _matte_mat(leaf_col, 0.7)
	var leaves: Array = walk.get("leaves", [])
	for i in range(leaves.size()):
		if i % 2 != 0:
			continue
		var p: Vector3 = leaves[i]
		root.add_child(_sphere(p, 0.015, leaf_mat))

	# Tiny soil clod at the base so it reads as "just pulled up to be planted".
	var soil_mat: StandardMaterial3D = _matte_mat(Color(0.22, 0.16, 0.11), 1.0)
	root.add_child(_sphere(Vector3(0.0, -0.01, 0.0), 0.03, soil_mat))

	# Scale the whole grammar down to a held ~0.4m sapling.
	_settle(root, 0.4)

	add_child(_billboard_label("SAPLING", Vector3(0.0, 0.5, 0.0), 22, leaf_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway_root != null:
		_sway_root.rotation.z = sin(_t * 1.1) * 0.03
		_sway_root.rotation.x = cos(_t * 0.8) * 0.02
