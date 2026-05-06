# GridPartExpressions.gd
# Three part-grammars for the role-tagging channel. Add as a child of (or
# sibling to) a GridPartMutator and on _ready it registers:
#
#   flower_grammar — sepals / petals / stamens / pistil
#       (concentric rings around the volume's xz centre)
#   insect_grammar — head / thorax / abdomen
#       (longitudinal bands along z)
#   bird_grammar  — head / throat / breast / belly / back / flanks /
#                  wing / tail / vent
#       (axis-aware decomposition; simplified from the 23-region taxonomy)
#
# Each expression is (i, row, col, grid_size, t, ctx) -> StringName
# returning the role of cube i. Same shape as every other expression in
# the substrate.
#
# @identity
# essence: register_expression(name, fn) for each anatomical grammar
# desire: to make the substrate able to speak in named-parts vocabulary
# critical_parameter: the grammar registered defines the anatomy's vocabulary
# triggers: _ready calls register_for(target_mutator)
# emerges: the connection between cube-grids and Codex labelled diagrams
# needs: a GridPartMutator to register against
# relationships: GridPartMutator (target); other channels (color, label,
#   visibility) READ this channel's roles
# truth: a part-grammar is a function from coords to a name

class_name GridPartExpressions
extends Node

@export var target_mutator_path: NodePath = ""


func _ready() -> void:
	var mutator: Node = _resolve_target()
	if not mutator:
		push_warning("GridPartExpressions: no GridPartMutator found")
		return
	register_for(mutator)


func register_for(mutator: Node) -> void:
	mutator.register_expression("flower_grammar", Callable(self, "_flower_grammar"))
	mutator.register_expression("insect_grammar", Callable(self, "_insect_grammar"))
	mutator.register_expression("bird_grammar", Callable(self, "_bird_grammar"))


func _resolve_target() -> Node:
	if not target_mutator_path.is_empty():
		var n: Node = get_node_or_null(target_mutator_path)
		if n and n.get_script() and n.get_script().get_global_name() == "GridPartMutator":
			return n
	var parent: Node = get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling.get_script() and sibling.get_script().get_global_name() == "GridPartMutator":
				return sibling
	return null


# --- expressions -----------------------------------------------------------

# Flower: concentric rings on the xz plane around the volume's centre.
#   pistil (innermost) / stamens / petals / sepals (outermost)
# Y is mostly ignored (a flower is flat-ish from above).
func _flower_grammar(_i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> StringName:
	var dims: Vector3i = ctx.get("dims", Vector3i(1, 1, 1))
	var x: int = ctx.get("x", 0)
	var z: int = ctx.get("z", 0)
	var center := Vector2((dims.x - 1) * 0.5, (dims.z - 1) * 0.5)
	var d: float = Vector2(float(x), float(z)).distance_to(center)
	var r: float = max(min(dims.x, dims.z) * 0.5, 1.0)
	var nd: float = d / r  # 0 at centre, 1 at edge

	if nd <= 0.18:
		return &"pistil"
	if nd <= 0.42:
		return &"stamen"
	if nd <= 0.78:
		return &"petal"
	return &"sepal"


# Insect: longitudinal bands along the z axis.
#   head (front third) / thorax (middle) / abdomen (back third)
func _insect_grammar(_i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> StringName:
	var dims: Vector3i = ctx.get("dims", Vector3i(1, 1, 1))
	var z: int = ctx.get("z", 0)
	var nz: float = float(z) / max(float(dims.z - 1), 1.0)
	if nz < 0.33:
		return &"head"
	if nz < 0.66:
		return &"thorax"
	return &"abdomen"


# Bird: axis-aware decomposition. Z = body axis (head front, tail back).
# Y = dorsal/ventral. X = lateral (wings at extremes).
# Simplified from the 23-region taxonomy in EDGES_OF_ALGORITHM_VISUAL_SEEDS.
# Sub-divisions can extend later (eyestripe, scapular, primaries, ...).
func _bird_grammar(_i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> StringName:
	var dims: Vector3i = ctx.get("dims", Vector3i(1, 1, 1))
	var x: int = ctx.get("x", 0)
	var y: int = ctx.get("y", 0)
	var z: int = ctx.get("z", 0)

	var nx_offset: float = abs(float(x) - (dims.x - 1) * 0.5) / max((dims.x - 1) * 0.5, 1.0)
	var ny: float = float(y) / max(float(dims.y - 1), 1.0)
	var nz: float = float(z) / max(float(dims.z - 1), 1.0)

	# Wings extend laterally on the middle third of the body.
	if nx_offset > 0.7 and nz > 0.25 and nz < 0.75:
		return &"wing"

	# Head + neck (front).
	if nz < 0.18:
		return &"head"
	if nz < 0.30:
		if ny < 0.45:
			return &"throat"
		return &"head"

	# Tail + vent (back).
	if nz > 0.85:
		return &"tail"
	if nz > 0.75 and ny < 0.30:
		return &"vent"

	# Trunk: dorsal/ventral split on y.
	if ny > 0.65:
		return &"back"
	if ny < 0.35:
		if nz < 0.5:
			return &"breast"
		return &"belly"
	return &"flanks"
