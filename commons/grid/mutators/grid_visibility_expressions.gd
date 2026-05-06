# GridVisibilityExpressions.gd
# A registry of bool-valued grid-cube visibility expressions. Add this Node as
# a child of (or sibling to) a GridVisibilityMutator and it will register four
# named expressions on _ready: rule_30, sierpinski, checkerboard, rings.
#
# Each expression is a pure function (i, row, col, grid_size, t, ctx) -> bool
# that decides whether instance i should be shown or hidden at the moment the
# pattern is applied. Static masks (deterministic per grid_size) — the mutator's
# auto-cycle just dispatches them in order.
#
# To add a new expression, drop another similar file or call mutator.register_expression(...)
# directly. Future expression files (walker trails, fractal masks, force-field
# masks) follow this pattern.
#
# @identity
# essence: register_expression(name, fn) for each principle-shaped function
# desire: to keep the visibility mutator empty of curriculum logic — it owns
#   the dispatch, expression files own the math
# critical_parameter: which expressions get registered — adds names to the
#   mutator's pattern_names cycle
# triggers: _ready calls register_for(target_mutator)
# emerges: cellular automata, Sierpinski fractals, and modular checker masks
#   all expressed at the same call site
# needs: a GridVisibilityMutator to register against [provided via export or
#   parent search]
# relationships: GridVisibilityMutator (target); future expression files for
#   walkers, fractals, forces follow the same shape
# truth: a principle is a one-line function from coords to a value

class_name GridVisibilityExpressions
extends Node

@export var target_mutator_path: NodePath = ""

# Whether to evolve Rule 30 from a single-cell seed (true) or a random-row seed (false).
@export var rule_30_single_seed: bool = true


func _ready() -> void:
	var mutator: GridVisibilityMutator = _resolve_target()
	if not mutator:
		push_warning("GridVisibilityExpressions: no GridVisibilityMutator found")
		return
	register_for(mutator)


func register_for(mutator: GridVisibilityMutator) -> void:
	mutator.register_expression("rule_30", Callable(self, "_rule_30"))
	mutator.register_expression("sierpinski", Callable(self, "_sierpinski"))
	mutator.register_expression("checkerboard", Callable(self, "_checkerboard"))
	mutator.register_expression("rings", Callable(self, "_rings"))


func _resolve_target() -> GridVisibilityMutator:
	if not target_mutator_path.is_empty():
		var n: Node = get_node_or_null(target_mutator_path)
		if n is GridVisibilityMutator:
			return n
	# fall back to a sibling search
	var parent: Node = get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling is GridVisibilityMutator:
				return sibling
	return null


# --- expressions -----------------------------------------------------------

# Rule 30 evolved row-by-row from a single seed at the top-middle. Caches the
# evolved board on the first call per grid_size so subsequent indices are O(1).
var _rule_30_board: PackedByteArray = PackedByteArray()
var _rule_30_cached_size: int = 0

func _rule_30(i: int, row: int, col: int, grid_size: int, _t: float, _ctx: Dictionary) -> bool:
	if grid_size != _rule_30_cached_size:
		_evolve_rule_30(grid_size)
	if i < 0 or i >= _rule_30_board.size():
		return false
	return _rule_30_board[i] != 0

func _evolve_rule_30(grid_size: int) -> void:
	_rule_30_cached_size = grid_size
	_rule_30_board.resize(grid_size * grid_size)
	for n in range(_rule_30_board.size()):
		_rule_30_board[n] = 0

	# seed
	if rule_30_single_seed:
		_rule_30_board[grid_size / 2] = 1
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = 30
		for c in range(grid_size):
			_rule_30_board[c] = 1 if rng.randf() < 0.5 else 0

	# evolve row by row using rule 30: 30 = 0b00011110
	# (left, center, right) -> next center
	for r in range(1, grid_size):
		for c in range(grid_size):
			var left_idx: int = (r - 1) * grid_size + ((c - 1 + grid_size) % grid_size)
			var center_idx: int = (r - 1) * grid_size + c
			var right_idx: int = (r - 1) * grid_size + ((c + 1) % grid_size)
			var pattern: int = (_rule_30_board[left_idx] << 2) | (_rule_30_board[center_idx] << 1) | _rule_30_board[right_idx]
			# rule 30 lookup: bit `pattern` of 0b00011110 (= 30)
			var next: int = (30 >> pattern) & 1
			_rule_30_board[r * grid_size + c] = next


# Sierpinski triangle mask via the bitwise-AND test:
# (row & col) == 0 generates the classic gasket.
func _sierpinski(_i: int, row: int, col: int, _grid_size: int, _t: float, _ctx: Dictionary) -> bool:
	return (row & col) == 0


func _checkerboard(_i: int, row: int, col: int, _grid_size: int, _t: float, _ctx: Dictionary) -> bool:
	return ((row + col) % 2) == 0


# Concentric-ring mask: visible when Chebyshev distance from center is in an
# odd-numbered ring band.
func _rings(_i: int, row: int, col: int, grid_size: int, _t: float, _ctx: Dictionary) -> bool:
	var center: float = (grid_size - 1) / 2.0
	var dr: float = abs(float(row) - center)
	var dc: float = abs(float(col) - center)
	var d: int = int(max(dr, dc))
	return (d % 2) == 0
