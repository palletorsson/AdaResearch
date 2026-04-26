# GridVisibilityMutator.gd
# Visibility-channel mutator: shows or hides per-instance cubes by collapsing
# their basis scale to zero. Caches the original transforms on first use so
# repeated patterns restore visible cubes to their authored positions exactly.
#
# Expressions are pure functions Callable(i, row, col, grid_size, t, ctx) -> bool.
# Register additional expressions through register_expression(name, fn) — typically
# done by a sibling expression file (e.g. grid_visibility_expressions.gd).
#
# @identity
# essence: visibility(i) -> set_instance_transform(i, scale_or_zero(original))
# desire: to give cellular automata, fractals, and walker trails a place to write
#   without touching color or transform channels
# critical_parameter: pattern_names[current_pattern_index] — drives the
#   bool-per-cube expression dispatched on each cycle tick
# triggers: auto-cycle (base); NextCube (base); register_expression() from a
#   sibling registry file
# emerges: Rule 30, Sierpinski, and concentric-ring masks all expressed as the
#   same shape — a function from grid coords to a bool
# needs: GridMultiMesh with TRANSFORM_3D format [auto]; cached transforms
#   (built lazily on first apply)
# relationships: GridMutatorBase (parent); GridColorMutator (sibling — both
#   write to the same MultiMesh without interference)
# truth: visibility is a function of position, not a property of the cube

class_name GridVisibilityMutator
extends "res://commons/grid/mutators/grid_mutator_base.gd"

# expression registry: name -> Callable(i, row, col, grid_size, t, ctx) -> bool
var _expressions: Dictionary = {}
# original transforms, cached on first apply so 0-scale hides without losing position
var _original_transforms: Array = []
var _transforms_cached: bool = false


# --- public registration ---------------------------------------------------

# Sibling expression files call this to add named functions to the catalogue.
# fn signature: func(i:int, row:int, col:int, grid_size:int, t:float, ctx:Dictionary) -> bool
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
	# _ready or via static hook before this mutator's _ready completes.
	pass


func _post_find_multimesh_setup() -> bool:
	_cache_original_transforms()
	return true


func _apply_named_pattern(pattern_name: String) -> void:
	if pattern_name.is_empty() or not _expressions.has(pattern_name):
		_log("GridVisibilityMutator: WARNING - unknown expression '%s'" % pattern_name)
		return
	if not multimesh:
		return
	if not _transforms_cached:
		_cache_original_transforms()

	var fn: Callable = _expressions[pattern_name]
	if not fn.is_valid():
		return

	var instance_count: int = multimesh.instance_count
	var grid_size: int = int(sqrt(float(instance_count)))
	if grid_size * grid_size < instance_count:
		grid_size += 1
	grid_size = max(grid_size, 1)

	var t: float = Time.get_ticks_msec() / 1000.0
	var ctx: Dictionary = {
		"structure": grid_structure,
		"grid_size": grid_size,
		"instance_count": instance_count,
	}

	var visible_count: int = 0
	for i in range(instance_count):
		var row: int = i / grid_size
		var col: int = i % grid_size
		var is_visible: bool = bool(fn.call(i, row, col, grid_size, t, ctx))
		_apply_visibility(i, is_visible)
		if is_visible:
			visible_count += 1

	_log("GridVisibilityMutator: '%s' showed %d/%d cubes" % [pattern_name, visible_count, instance_count])


# --- visibility plumbing ---------------------------------------------------

func _cache_original_transforms() -> void:
	if not multimesh:
		return
	_original_transforms.clear()
	_original_transforms.resize(multimesh.instance_count)
	for i in range(multimesh.instance_count):
		_original_transforms[i] = multimesh.get_instance_transform(i)
	_transforms_cached = true


func _apply_visibility(i: int, is_visible: bool) -> void:
	if i < 0 or i >= _original_transforms.size():
		return
	var original: Transform3D = _original_transforms[i]
	if is_visible:
		multimesh.set_instance_transform(i, original)
	else:
		# Collapse basis to zero scale; keep origin so future visible-restore lands correctly.
		var hidden_basis := Basis().scaled(Vector3.ZERO)
		multimesh.set_instance_transform(i, Transform3D(hidden_basis, original.origin))


# Public: clear cached transforms and re-cache from current MultiMesh state.
# Useful if the GridSystem rebuilt the MultiMesh between map loads.
func refresh_cached_transforms() -> void:
	_transforms_cached = false
	_cache_original_transforms()
