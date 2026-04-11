class_name FoldSolver
extends Resource
## Base class for fold deformation solvers.
## Each subclass implements one strategy: bone rotation, chain compression, shell nesting.

## Compute deformed transforms for all segments.
## Returns Dictionary[StringName, Transform3D].
func compute_fold(
	fold_amount: float,
	fold_tension: float,
	segments: Array,
	constraints: Array,
) -> Dictionary:
	return {}

## Optional secondary motion (breathing, idle sway).
func compute_secondary(delta: float, _activity: StringName) -> Dictionary:
	return {}
