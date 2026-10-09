# GridMapAwareExpressions.gd
# Visibility expressions that read the host map's STRUCTURE (heights of
# the cells around them) — not just abstract row/col coordinates. Drop
# this as a child of (or sibling to) a GridVisibilityMutator. On _ready
# it registers the map-aware expression set.
#
# Pattern matches GridVisibilityExpressions exactly: each expression is a
# Callable(i, row, col, grid_size, t, ctx) -> bool. The difference is
# what they read from `ctx`:
#
#   abstract expressions: only use (i, row, col, grid_size, t)
#                         e.g. rule_30, sierpinski, checkerboard
#
#   map-aware expressions: use ctx["structure"].get_height_at(col, row)
#                          e.g. atop_plinths, walkable_floor
#
# This is the missing channel — the substrate becomes legible against
# the actual map it's dropped into. Same artifact, different visible
# pattern depending on whether it's placed in a Soane plinth field, a
# walled room, or a drunkard cave.
#
# @identity
# essence: visibility patterns that read map heights, not abstract grid
# desire: a substrate cartridge that adapts to whichever shell it's
#         placed in — same code, different appearance per host map
# critical_parameter: ctx["structure"] — the GridStructureComponent that
#         carries the host map's heights
# triggers: _ready calls register_for(target_mutator)
# emerges: substrate-cartridge factoring at the map level — the shell
#         is the map's structure layer, the cartridge is one of these
#         expressions, the runner cycles them
# needs: ctx["structure"] passed in by GridVisibilityMutator [yes, line 148]
# relationships: GridVisibilityExpressions sibling (abstract); shares
#         the same registration pattern
# truth: a pattern only becomes context-aware when it reads context

class_name GridMapAwareExpressions
extends Node

@export var target_mutator_path: NodePath = ""

# Threshold heights for "atop plinths" and "low floor" expressions.
@export var plinth_min_height: int = 2     # cubes here count as plinth
@export var floor_height: int = 1           # cubes here count as walkable floor

# Stride for array_stride expression (every Nth cell).
@export var array_stride: int = 3


func _ready() -> void:
	var mutator: Node = _resolve_target()
	if not mutator:
		push_warning("GridMapAwareExpressions: no GridVisibilityMutator found")
		return
	register_for(mutator)


func register_for(mutator: Node) -> void:
	mutator.register_expression("atop_plinths",       Callable(self, "_atop_plinths"))
	mutator.register_expression("walkable_floor",     Callable(self, "_walkable_floor"))
	mutator.register_expression("array_stride",       Callable(self, "_array_stride"))
	mutator.register_expression("perimeter_of_mass",  Callable(self, "_perimeter_of_mass"))
	mutator.register_expression("array_filled",       Callable(self, "_array_filled"))


func _resolve_target() -> Node:
	if not target_mutator_path.is_empty():
		var n: Node = get_node_or_null(target_mutator_path)
		if n: return n
	# Auto-find: look for a sibling GridVisibilityMutator first.
	var p: Node = get_parent()
	if p:
		for c in p.get_children():
			if c.get_script() and "GridVisibilityMutator" in str(c.get_script().get_path()):
				return c
	return null


# ── Helpers ──────────────────────────────────────────────────────

func _height_at(ctx: Dictionary, col: int, row: int) -> int:
	# col → x, row → z in GridStructureComponent's coord scheme.
	var s = ctx.get("structure", null)
	if s == null: return 0
	if not s.has_method("get_height_at"): return 0
	return int(s.get_height_at(col, row))


# ── Expressions ──────────────────────────────────────────────────

# Visible only on cubes that sit on a plinth cell (h >= plinth_min_height).
# Buren-on-Soane: striped columns appear ONLY where the structure layer
# already has a plinth. Drop the same runner in any plinth-based shell
# and you get this pattern automatically.
func _atop_plinths(_i: int, row: int, col: int, _g: int, _t: float, ctx: Dictionary) -> bool:
	return _height_at(ctx, col, row) >= plinth_min_height


# The complement: visible only on walkable floor (h == floor_height).
# Reveals the *plaza* — the spaces between plinths, the path the player walks.
func _walkable_floor(_i: int, row: int, col: int, _g: int, _t: float, ctx: Dictionary) -> bool:
	return _height_at(ctx, col, row) == floor_height


# Every Nth walkable cell, indexed diagonally. Same idea as the Buren array
# (one column every 3 cells along both axes) but constrained to the floor —
# columns rise where the shell is open, skipped where it's already plinth.
func _array_stride(_i: int, row: int, col: int, _g: int, _t: float, ctx: Dictionary) -> bool:
	if _height_at(ctx, col, row) != floor_height: return false
	var stride: int = max(2, array_stride)
	return (row % stride == 1) and (col % stride == 1)


# The boundary between walkable floor and high mass — visible on floor cells
# that sit adjacent to a plinth. The "skirt" around dense regions.
func _perimeter_of_mass(_i: int, row: int, col: int, _g: int, _t: float, ctx: Dictionary) -> bool:
	if _height_at(ctx, col, row) != floor_height: return false
	for dr in [-1, 0, 1]:
		for dc in [-1, 0, 1]:
			if dr == 0 and dc == 0: continue
			if _height_at(ctx, col + dc, row + dr) >= plinth_min_height:
				return true
	return false


# Visible on every walkable cell — the "everything fills" pattern.
# Sets up the contrast against the stride/perimeter cartridges by being
# the dense one.
func _array_filled(_i: int, row: int, col: int, _g: int, _t: float, ctx: Dictionary) -> bool:
	return _height_at(ctx, col, row) == floor_height
