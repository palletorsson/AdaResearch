# GridPartMutator.gd
# Substrate's sixth channel: role-tagging.
#
# The cube doesn't just have a position — it has a name. "petal", "stamen",
# "thorax", "scapular", "wattle". Once a cube knows what it is, every other
# channel can address it by role: paint petals one palette, hide the thorax
# this cycle, attach a label that follows the wattle through morphs.
#
# This is the channel that connects the substrate to the Codex Seraphinianus's
# labelled-diagram tradition. Without role tags, every visualisation is
# anonymous geometry. With them, the substrate produces named anatomy.
#
# Differences from the other mutators:
#   - This one does NOT write to the multimesh. It writes to a per-cube
#     role-table (`Array[StringName]` of size instance_count).
#   - Other channels read the role table via `get_role(i)`,
#     `get_cells_with_role(role)`, `get_role_centroid(role)`.
#   - Compute cost is O(N) per apply — pure tagging, no rendering.
#
# Expression signature: (i, row, col, grid_size, t, ctx) -> StringName
#   Returns the role this cube belongs to. Empty StringName = untagged.
#
# @identity
# essence: per-cube role tagging; the channel that lets every other channel
#   address parts by name
# desire: to give the substrate a vocabulary of *positions with names*, the
#   missing primitive between cube grids and Codex pages
# critical_parameter: the active grammar (`flower_grammar`,
#   `insect_grammar`, `bird_grammar`); the choice of grammar IS the
#   anatomy the map demonstrates
# triggers: auto-cycle from base, or explicit set_pattern_by_index from
#   the runner
# emerges: the foundation for labels (specimen tags), color-by-role,
#   visibility-by-role, decay-by-role, audio-by-role
# needs: GridMultiMesh from the host scene [✓]; expressions registered by
#   GridPartExpressions sibling
# relationships: GridMutatorBase (parent); reads no other channels;
#   queried by labels, color-by-role color expressions, future
#   anatomy-aware decay
# truth: the algorithm produces positions with names, not just positions

class_name GridPartMutator
extends "res://commons/grid/mutators/grid_mutator_base.gd"

# expression registry: name -> Callable(i, row, col, grid_size, t, ctx) -> StringName
var _expressions: Dictionary = {}

# Per-cube role tags. Empty StringName (&"") = untagged.
var _roles: Array[StringName] = []

# Last apply's role distribution (for diagnostics / pretty-printing).
var _last_role_counts: Dictionary = {}


# --- public registration ---------------------------------------------------

func register_expression(name: String, fn: Callable) -> void:
	_expressions[name] = fn
	if not pattern_names.has(name):
		pattern_names.append(name)


func unregister_expression(name: String) -> void:
	_expressions.erase(name)
	pattern_names.erase(name)


# --- public query API ------------------------------------------------------

# Role for one cube. Returns &"" if untagged or out-of-bounds.
func get_role(i: int) -> StringName:
	if i < 0 or i >= _roles.size():
		return &""
	return _roles[i]


# All cube indices currently tagged with the given role.
func get_cells_with_role(role: StringName) -> Array:
	var out: Array = []
	for i in range(_roles.size()):
		if _roles[i] == role:
			out.append(i)
	return out


# World-space centroid of all cells tagged with `role`. Useful for label
# attachment ("draw a leader-arrow pointing at the centroid of the thorax").
# Returns Vector3.ZERO if no cells have this role.
func get_role_centroid(role: StringName) -> Vector3:
	if not multimesh:
		return Vector3.ZERO
	var sum := Vector3.ZERO
	var count: int = 0
	for i in range(_roles.size()):
		if _roles[i] == role:
			sum += multimesh.get_instance_transform(i).origin
			count += 1
	if count == 0:
		return Vector3.ZERO
	return sum / float(count)


# All distinct roles currently in use.
func get_all_roles() -> Array[StringName]:
	var seen: Dictionary = {}
	for r in _roles:
		seen[r] = true
	var out: Array[StringName] = []
	for r in seen.keys():
		out.append(r)
	return out


# Diagnostic count per role, captured on the last apply.
func get_role_counts() -> Dictionary:
	return _last_role_counts


# --- base hooks ------------------------------------------------------------

func _initialize_pattern_names() -> void:
	# Subclass leaves this empty; expressions are registered externally via
	# register_expression() (typically by GridPartExpressions sibling).
	pass


func _post_find_multimesh_setup() -> bool:
	if multimesh and _roles.size() != multimesh.instance_count:
		_roles.resize(multimesh.instance_count)
	return true


func _apply_named_pattern(pattern_name: String) -> void:
	if pattern_name.is_empty() or not _expressions.has(pattern_name):
		_log("GridPartMutator: WARNING - unknown expression '%s'" % pattern_name)
		return
	if not multimesh:
		return
	var fn: Callable = _expressions[pattern_name]
	if not fn.is_valid():
		return

	var instance_count: int = multimesh.instance_count
	var dims: Vector3i = resolve_dims()
	var grid_size: int = legacy_grid_size(dims)
	var t: float = Time.get_ticks_msec() / 1000.0

	if _roles.size() != instance_count:
		_roles.resize(instance_count)

	var ctx: Dictionary = {
		"structure": grid_structure,
		"grid_size": grid_size,
		"dims": dims,
		"instance_count": instance_count,
	}

	var counts: Dictionary = {}
	for i in range(instance_count):
		var xyz: Vector3i = cell_xyz(i, dims)
		ctx["xyz"] = xyz
		ctx["x"] = xyz.x
		ctx["y"] = xyz.y
		ctx["z"] = xyz.z
		var raw = fn.call(i, xyz.z, xyz.x, grid_size, t, ctx)
		var role: StringName = (raw if raw is StringName else StringName(str(raw)))
		_roles[i] = role
		counts[role] = counts.get(role, 0) + 1

	_last_role_counts = counts
	_log("GridPartMutator: '%s' tagged %d cubes across %d roles: %s" % [
		pattern_name, instance_count, counts.size(), str(counts)
	])
