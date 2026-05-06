# GridTransformMutator.gd
# Transform-channel mutator: applies a per-instance Transform3D delta on top of
# each cube's authored origin. Caches the original transforms on first use so
# expressions return relative offsets and rotations without needing to know
# absolute grid positions.
#
# Expressions are pure functions Callable(i, row, col, grid_size, t, ctx) -> Transform3D.
# The returned transform's basis is composed onto the original transform's basis,
# and its origin is added to the original's origin. This lets one expression
# rotate cubes in place, another scale them, another translate them up — all on
# the same MultiMesh, alongside color and visibility mutators.
#
# Register additional expressions via register_expression(name, fn) — typically
# done by a sibling registry file (grid_transform_expressions.gd).
#
# @identity
# essence: transform_delta(i) composed onto cached_transform(i)
# desire: to give rotation, scaling, force-field, and walker-trail expressions
#   one place to write without colliding with color or visibility
# critical_parameter: pattern_names[current_pattern_index] — drives the
#   Transform3D-per-cube expression dispatched on each cycle tick
# triggers: auto-cycle (base); NextCube (base); register_expression() from a
#   sibling registry file
# emerges: rotate_by_row + force_field + scale_by_distance all expressed as
#   the same shape — a function from grid coords to a Transform3D
# needs: GridMultiMesh with TRANSFORM_3D format [auto]; cached transforms
#   (built lazily on first apply)
# relationships: GridMutatorBase (parent); GridColorMutator and
#   GridVisibilityMutator (siblings — three channels on one MultiMesh)
# truth: a transform is a function of position and time, not a property of
#   the cube

class_name GridTransformMutator
extends "res://commons/grid/mutators/grid_mutator_base.gd"

# expression registry: name -> Callable(i, row, col, grid_size, t, ctx) -> Transform3D
var _expressions: Dictionary = {}
# original authored transforms, cached on first apply so deltas compose correctly
var _original_transforms: Array = []
var _transforms_cached: bool = false


# --- public registration ---------------------------------------------------

# Sibling expression files call this to add named functions to the catalogue.
# fn signature: func(i:int, row:int, col:int, grid_size:int, t:float, ctx:Dictionary) -> Transform3D
# Return Transform3D.IDENTITY for "no change". The basis composes onto the
# cached basis, the origin adds to the cached origin.
func register_expression(name: String, fn: Callable) -> void:
	_expressions[name] = fn
	if not pattern_names.has(name):
		pattern_names.append(name)


func unregister_expression(name: String) -> void:
	_expressions.erase(name)
	pattern_names.erase(name)


# --- base hooks ------------------------------------------------------------

func _initialize_pattern_names() -> void:
	# Subclass leaves this empty; expressions are registered externally via
	# register_expression(). Sibling expression file calls registration in its
	# _ready or before this mutator's _ready completes.
	pass


func _post_find_multimesh_setup() -> bool:
	_cache_original_transforms()
	return true


func _apply_named_pattern(pattern_name: String) -> void:
	if pattern_name.is_empty() or not _expressions.has(pattern_name):
		_log("GridTransformMutator: WARNING - unknown expression '%s'" % pattern_name)
		return
	if not multimesh:
		return
	if not _transforms_cached:
		_cache_original_transforms()

	var fn: Callable = _expressions[pattern_name]
	if not fn.is_valid():
		return

	var instance_count: int = multimesh.instance_count
	var dims: Vector3i = resolve_dims()
	var grid_size: int = legacy_grid_size(dims)

	var t: float = Time.get_ticks_msec() / 1000.0
	var ctx: Dictionary = {
		"structure": grid_structure,
		"grid_size": grid_size,
		"dims": dims,
		"instance_count": instance_count,
	}

	for i in range(instance_count):
		var xyz: Vector3i = cell_xyz(i, dims)
		ctx["xyz"] = xyz
		ctx["x"] = xyz.x
		ctx["y"] = xyz.y
		ctx["z"] = xyz.z
		var delta_value = fn.call(i, xyz.z, xyz.x, grid_size, t, ctx)
		if delta_value is Transform3D:
			_apply_delta(i, delta_value)

	_log("GridTransformMutator: applied '%s' to %d instances" % [pattern_name, instance_count])


# --- transform plumbing ---------------------------------------------------

func _cache_original_transforms() -> void:
	if not multimesh:
		return
	_original_transforms.clear()
	_original_transforms.resize(multimesh.instance_count)
	for i in range(multimesh.instance_count):
		_original_transforms[i] = multimesh.get_instance_transform(i)
	_transforms_cached = true


func _apply_delta(i: int, delta: Transform3D) -> void:
	if i < 0 or i >= _original_transforms.size():
		return
	var original: Transform3D = _original_transforms[i]
	# Compose delta onto original: delta basis multiplies into the basis,
	# delta origin adds onto the origin (relative offset from authored cell).
	var composed_basis: Basis = original.basis * delta.basis
	var composed_origin: Vector3 = original.origin + delta.origin
	multimesh.set_instance_transform(i, Transform3D(composed_basis, composed_origin))


# Public: clear cached transforms and re-cache from current MultiMesh state.
# Call after a sibling mutator (e.g. visibility) restores transforms, so the
# next transform pattern composes onto the now-current state.
func refresh_cached_transforms() -> void:
	_transforms_cached = false
	_cache_original_transforms()
