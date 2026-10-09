# GridGlyphExpressions.gd
# Three subdivision policies for the glyph channel. Add as a child of (or
# sibling to) a GridGlyphMutator and on _ready it registers:
#
#   subdivide_uniform     — every visible cube subdivides (testing only)
#   subdivide_by_attention — finer where the viewer is, coarse at the horizon
#   subdivide_by_pattern_edge — finer where the active visibility pattern
#     has neighbour-disagreement (the boundary of the algorithm)
#
# Each policy is a pure function (i, row, col, grid_size, t, ctx) -> int
# returning the desired subdivision level for cube i. Same shape as every
# other expression in the substrate.
#
# @identity
# essence: register_expression(name, fn) for each subdivision-policy
# desire: to keep the glyph mutator empty of curriculum logic — it owns
#   the budget and the dispatch; expression files own the decision
# critical_parameter: which policies get registered; pattern_names cycle
# triggers: _ready calls register_for(target_mutator)
# emerges: an unfolding floor — cubes that subdivide where the algorithm's
#   work is, where the player's attention is, or uniformly under test
# needs: a GridGlyphMutator to register against
# relationships: GridGlyphMutator (target); GridVisibilityExpressions and
#   GridVisibilityExpressions3D (siblings; we read their visible/hidden
#   neighbour states for `subdivide_by_pattern_edge`)
# truth: a glyph is a function from coords to a subdivision level, just
#   like every other principle in the substrate

class_name GridGlyphExpressions
extends Node

@export var target_mutator_path: NodePath = ""


func _ready() -> void:
	var mutator: Node = _resolve_target()
	if not mutator:
		push_warning("GridGlyphExpressions: no GridGlyphMutator found")
		return
	register_for(mutator)


func register_for(mutator: Node) -> void:
	mutator.register_expression("subdivide_uniform", Callable(self, "_subdivide_uniform"))
	mutator.register_expression("subdivide_by_attention", Callable(self, "_subdivide_by_attention"))
	mutator.register_expression("subdivide_by_pattern_edge", Callable(self, "_subdivide_by_pattern_edge"))


func _resolve_target() -> Node:
	if not target_mutator_path.is_empty():
		var n: Node = get_node_or_null(target_mutator_path)
		if n and n.get_script() and n.get_script().get_global_name() == "GridGlyphMutator":
			return n
	var parent: Node = get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling.get_script() and sibling.get_script().get_global_name() == "GridGlyphMutator":
				return sibling
	return null


# --- expressions -----------------------------------------------------------

# Uniform: every visible cube wants subdivision. The mutator's compute
# budget will then trim to max_subdivided_cells. Useful for testing —
# you'll see exactly which cubes the budget chose.
func _subdivide_uniform(_i: int, _row: int, _col: int, _grid_size: int, _t: float, _ctx: Dictionary) -> int:
	return 1


# By-attention: subdivision desired wherever the cube is within
# viewer_radius of viewer_position. Outside the radius, level 0. The
# mutator's distance-priority sort + budget cap then keeps the closest
# cubes within viewer_radius and drops the rest if there are too many.
func _subdivide_by_attention(_i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> int:
	var viewer: Vector3 = ctx.get("viewer", Vector3.ZERO)
	var radius: float = ctx.get("viewer_radius", 6.0)
	# We don't have the cube origin in ctx (the mutator iterates after this
	# returns). Approximate via cell coords: cube origin ≈ Vector3(x, y, z).
	# This is correct for the canonical 1.0-unit grid; for other cube_size
	# the runner should set viewer_position in cube-coord space too.
	var x: float = float(ctx.get("x", 0))
	var y: float = float(ctx.get("y", 0))
	var z: float = float(ctx.get("z", 0))
	var dist: float = Vector3(x, y, z).distance_to(viewer)
	return 1 if dist <= radius else 0


# By-pattern-edge: subdivide cubes whose visibility differs from any
# 4-connected neighbour in the floor strata. Reads the multimesh's
# current per-instance basis-scale to determine "visible". This is the
# CA-edge handwriting: the algorithm reveals detail exactly where it's
# changing state.
func _subdivide_by_pattern_edge(_i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> int:
	var multimesh = ctx.get("multimesh", null)
	if not multimesh:
		# Fall back to a structural cue: cubes with at least one zero coord
		# (the boundary of the box) get subdivided.
		var x: int = int(ctx.get("x", 0))
		var z: int = int(ctx.get("z", 0))
		var dims: Vector3i = ctx.get("dims", Vector3i(1, 1, 1))
		if x == 0 or z == 0 or x == dims.x - 1 or z == dims.z - 1:
			return 1
		return 0
	# The mutator doesn't currently put `multimesh` in ctx; this branch is
	# scaffolding for v2 when we wire it. For now, the structural fallback
	# above produces a usable boundary-edge subdivision.
	return 0
