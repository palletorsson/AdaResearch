# GridTransformExpressions.gd
# A registry of Transform3D-valued grid-cube transform expressions. Add as a
# child of (or sibling to) a GridTransformMutator and it will register five
# named expressions on _ready: rotate_by_row, rotate_by_distance, lift_by_row,
# scale_pulse, force_field.
#
# Each expression is a pure function (i, row, col, grid_size, t, ctx) -> Transform3D
# returning a *delta* composed onto the cube's authored transform. Identity =
# no change. Returning a delta with rotation puts spin into the basis;
# returning a delta with non-zero origin shifts the cube by that vector.
#
# @identity
# essence: register_expression(name, fn) for each transform-shaped principle
# desire: to keep the transform mutator empty of curriculum logic — it owns
#   the dispatch and composition, expression files own the math
# critical_parameter: which expressions get registered — adds names to the
#   mutator's pattern_names cycle
# triggers: _ready calls register_for(target_mutator)
# emerges: rotation + lift + scale + radial-push all expressed at the same
#   call site; the curriculum's "transformation" sequence renders any of them
# needs: a GridTransformMutator to register against [provided via export or
#   sibling search]
# relationships: GridTransformMutator (target); GridVisibilityExpressions
#   (sibling — same registration shape, different value type)
# truth: a transform principle is a one-line function from coords to a
#   Transform3D delta

class_name GridTransformExpressions
extends Node

@export var target_mutator_path: NodePath = ""


func _ready() -> void:
	var mutator: Node = _resolve_target()
	if not mutator:
		push_warning("GridTransformExpressions: no GridTransformMutator found")
		return
	register_for(mutator)


func register_for(mutator: Node) -> void:
	mutator.register_expression("rotate_by_row", Callable(self, "_rotate_by_row"))
	mutator.register_expression("rotate_by_distance", Callable(self, "_rotate_by_distance"))
	mutator.register_expression("lift_by_row", Callable(self, "_lift_by_row"))
	mutator.register_expression("scale_pulse", Callable(self, "_scale_pulse"))
	mutator.register_expression("force_field", Callable(self, "_force_field"))


func _resolve_target() -> Node:
	if not target_mutator_path.is_empty():
		var n: Node = get_node_or_null(target_mutator_path)
		if n and n.get_script() and n.get_script().get_global_name() == "GridTransformMutator":
			return n
	# fall back to a sibling search
	var parent: Node = get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling.get_script() and sibling.get_script().get_global_name() == "GridTransformMutator":
				return sibling
	return null


# --- expressions -----------------------------------------------------------

# Rotate cubes in place around Y, with rotation amount increasing per row.
func _rotate_by_row(_i: int, row: int, _col: int, _grid_size: int, _t: float, _ctx: Dictionary) -> Transform3D:
	var angle: float = float(row) * PI / 8.0
	return Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO)


# Rotate cubes around Y, with rotation amount tied to Chebyshev distance from center.
func _rotate_by_distance(_i: int, row: int, col: int, grid_size: int, _t: float, _ctx: Dictionary) -> Transform3D:
	var center: float = (grid_size - 1) / 2.0
	var dr: float = abs(float(row) - center)
	var dc: float = abs(float(col) - center)
	var d: float = max(dr, dc)
	var angle: float = (d / center) * PI / 2.0
	return Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO)


# Lift cubes in Y proportional to row index (creates a tilted plane / staircase).
func _lift_by_row(_i: int, row: int, _col: int, grid_size: int, _t: float, _ctx: Dictionary) -> Transform3D:
	var lift: float = float(row) * 0.5
	return Transform3D(Basis(), Vector3(0.0, lift, 0.0))


# Sinusoidal lift varying with row+col, snapshotted at t.
# (Static across one capture; animates if cycled live.)
func _scale_pulse(_i: int, row: int, col: int, grid_size: int, t: float, _ctx: Dictionary) -> Transform3D:
	var phase: float = float(row + col) / float(grid_size) * TAU
	var pulse: float = 0.4 + 0.4 * sin(phase + t)
	# Scale the basis around its own origin (cube grows/shrinks in place).
	return Transform3D(Basis().scaled(Vector3(pulse, pulse, pulse)), Vector3.ZERO)


# Push cubes radially outward from grid center, with magnitude tied to distance.
func _force_field(_i: int, row: int, col: int, grid_size: int, _t: float, _ctx: Dictionary) -> Transform3D:
	var center: Vector2 = Vector2((grid_size - 1) / 2.0, (grid_size - 1) / 2.0)
	var pos: Vector2 = Vector2(float(col), float(row))
	var dir: Vector2 = pos - center
	var dist: float = dir.length()
	if dist < 0.001:
		return Transform3D.IDENTITY
	var unit: Vector2 = dir / dist
	var push: float = (dist / max(center.x, 1.0)) * 1.5
	return Transform3D(Basis(), Vector3(unit.x * push, 0.0, unit.y * push))
