extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LsystemTreeRoom

## @identity
## lineage: L-system trees — Lindenmayer's grammar of growth, the original use that named the field
## essence: a handful of rewrite rules, applied a few times, unfolds into a whole tree you can stand beneath
## truth: "A FEW RULES, A WHOLE TREE" — complexity here is not stored, it is grown; the seed is short, the tree is long
##
## LARGE tier. A room-tall classic L-system plant (~3-4m) you walk under, with leaf
## markers (small glowing spheres) at the * positions returned in walk["leaves"].
## Tubes → one MultiMesh; leaves → one MultiMesh. Static, built once.

const LST := preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

@export var iters: int = 5
@export var angle_deg: float = 22.5
@export var tree_height: float = 3.6
@export var trunk_color: Color = Color(0.40, 0.26, 0.16)
@export var tip_color: Color = Color(0.50, 0.80, 0.35)
@export var leaf_color: Color = Color(0.55, 0.95, 0.45)
@export var floor_color: Color = Color(0.10, 0.12, 0.11)


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
	if config.has("leaf_color"):
		leaf_color = _parse_color(config["leaf_color"], leaf_color)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	# Room floor.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_color, 0.7)))

	# Classic plant, with * leaf markers added at branch tips so walk["leaves"] fills.
	var axiom := "X"
	var rules := {
		"X": "F+[[X]-X]-F[-FX]+X*",
		"F": "FF",
	}
	var grammar := _expand(axiom, rules, iters)
	var walk: Dictionary = LST.walk(grammar, {
		"angle_deg": angle_deg,
		"step_len": 0.06,
		"step_shrink": 0.80,
		"base_width": 0.05,
		"width_shrink": 0.70,
		"seed": 9,
	})

	# Scale factor maps the raw tree height to the desired room height.
	var raw_h: float = _walk_height(walk)
	var s: float = tree_height / maxf(raw_h, 0.001)
	var origin := Vector3(0.0, 0.0, 0.0)

	var tree: MultiMeshInstance3D = LST.to_tubes(walk, trunk_color, tip_color, 6)
	tree.scale = Vector3.ONE * s
	tree.position = origin
	add_child(tree)

	# Leaf markers from walk["leaves"], rendered as one MultiMesh of small spheres.
	_add_leaves(walk.get("leaves", []), s, origin)

	# Base ring so the trunk reads as planted.
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.35, 0.04, _steel_mat(Color(0.28, 0.30, 0.32))))

	add_child(_billboard_label("A FEW RULES, A WHOLE TREE", Vector3(0.0, 3.6, 0.0), 46, tip_color))


func _add_leaves(leaves: Array, s: float, origin: Vector3) -> void:
	if leaves.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sphere := SphereMesh.new()
	sphere.radius = 0.045
	sphere.height = 0.09
	sphere.radial_segments = 6
	sphere.rings = 4
	mm.mesh = sphere
	mm.instance_count = leaves.size()
	for i in range(leaves.size()):
		var p: Vector3 = leaves[i]
		var world: Vector3 = origin + p * s
		mm.set_instance_transform(i, Transform3D(Basis(), world))
	mmi.multimesh = mm
	mmi.material_override = _glow_mat(leaf_color, 1.5)
	add_child(mmi)


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
