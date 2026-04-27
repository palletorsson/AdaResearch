# GridGlyphMutator.gd
# Substrate's fifth channel: subdivision (a.k.a. the glyph channel).
#
# The world starts blocky. As the algorithm runs, specific cubes subdivide
# into 2x2x2 sub-cubes; the pattern of subdivision IS the glyph. Selective
# subdivision is bounded by a compute budget so the substrate doesn't drown
# itself in detail. Where the player looks, where the active visibility
# pattern has edges, where the narrative centre lives — those cubes
# subdivide. Everywhere else stays coarse.
#
# Differences from the other mutators:
#   - This one *creates* additional cube instances (a child MultiMesh of
#     sub-cubes) rather than only mutating existing ones.
#   - It composes with visibility / color / transform by reading the
#     parent's current state and respecting "hidden" decisions: only
#     visible parents are eligible for subdivision.
#   - It writes BOTH to the parent multimesh (hides subdivided parents)
#     AND to its own sub-mesh (renders the sub-cubes). Run order in the
#     mutator stack should put glyph LAST so it sees the final visibility
#     of each parent before deciding whether to subdivide.
#
# Expression signature: (i, row, col, grid_size, t, ctx) -> int
#   Returns the desired subdivision level for parent cube i:
#     0 = no subdivision (parent renders normally)
#     1 = subdivide once (parent is hidden, 8 sub-cubes appear at its origin)
#   v1 supports level 0 and 1 only. Level 2+ is queued for v2.
#
# @identity
# essence: per-parent-cube subdivision policy bounded by a compute budget;
#   the substrate's writing system
# desire: to be the channel that lets the world UNFOLD — start blocky,
#   reveal specifics where attention / algorithmic edge / narrative weight
#   ask for them; never exceed budget
# critical_parameter: max_subdivided_cells (compute cap); the policy
#   chosen via set_pattern_by_index (uniform / by_attention / by_edge)
# triggers: auto-cycle from base; or runner sets pattern explicitly per
#   visibility-cycle tick
# emerges: a Codex-page feeling — coarse base, finer detail at the eye's
#   focal points; no separate sprite layer; the glyph IS subdivision
# needs: GridMultiMesh from the host scene [✓]; budget set by author
#   [@export]; runs AFTER visibility in the runner's mutator stack
# relationships: GridMutatorBase (parent); GridVisibilityMutator (sibling
#   that runs first; we read its parent decisions); GridColorMutator
#   (sibling; sub-cubes inherit parent color)
# truth: the world is at level 0 by default; specifics arrive when
#   attention asks for them; compute is honest about itself

class_name GridGlyphMutator
extends "res://commons/grid/mutators/grid_mutator_base.gd"

# expression registry: name -> Callable(i, row, col, grid_size, t, ctx) -> int
var _expressions: Dictionary = {}

# --- compute budget --------------------------------------------------------

# How many parent cubes may be subdivided at once. 8 sub-cubes per parent,
# so total sub-cubes = max_subdivided_cells * 8.
@export var max_subdivided_cells: int = 256

# Cube edge length in world units. Sub-cubes sit at parent.origin ±
# (cube_size * 0.25) along each axis. Default 1.0 matches GridSystem.
@export var cube_size: float = 1.0

# Sub-cube size as a fraction of cube_size. 0.45 leaves a small gap so the
# eight children read as eight, not as one solid replacement.
@export var sub_cube_scale: float = 0.45

# --- attention-based policies ---------------------------------------------

# Position the player / camera is at. Updated by runner each frame for
# `subdivide_by_attention`. World coordinates.
@export var viewer_position: Vector3 = Vector3.ZERO

# Cubes within this radius of viewer_position are eligible for subdivision
# (the priority sort within the budget).
@export var viewer_radius: float = 6.0

# --- internal state --------------------------------------------------------

var _sub_instance: MultiMeshInstance3D = null
var _sub_mesh: MultiMesh = null
var _subdivided: PackedByteArray = PackedByteArray()  # 1 if parent i is subdivided
# Pre-glyph snapshot of every parent's transform (visibility's intent, captured
# right before glyph hid any parent). Restored at the start of every apply so
# subsequent applies see fresh visibility, not glyph's hidden artefacts.
var _pre_glyph_transforms: Array = []
var _has_cached: bool = false


# --- public registration ---------------------------------------------------

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
	# register_expression() (typically by GridGlyphExpressions sibling).
	pass


func _post_find_multimesh_setup() -> bool:
	_ensure_sub_mesh()
	return true


func _apply_named_pattern(pattern_name: String) -> void:
	if pattern_name.is_empty() or not _expressions.has(pattern_name):
		_log("GridGlyphMutator: WARNING - unknown expression '%s'" % pattern_name)
		return
	if not multimesh:
		return
	_ensure_sub_mesh()

	var fn: Callable = _expressions[pattern_name]
	if not fn.is_valid():
		return

	var instance_count: int = multimesh.instance_count
	var dims: Vector3i = resolve_dims()
	var grid_size: int = legacy_grid_size(dims)
	var t: float = Time.get_ticks_msec() / 1000.0

	# Pass 0: restore previously-subdivided parents from the cache so we
	# read fresh visibility (visibility's most recent intent), not glyph's
	# zero-scaled artefacts.
	if _pre_glyph_transforms.size() != instance_count:
		_pre_glyph_transforms.resize(instance_count)
		_has_cached = false
	if _has_cached and _subdivided.size() == instance_count:
		for i in range(instance_count):
			if _subdivided[i] != 0:
				multimesh.set_instance_transform(i, _pre_glyph_transforms[i])

	var ctx: Dictionary = {
		"structure": grid_structure,
		"grid_size": grid_size,
		"dims": dims,
		"instance_count": instance_count,
		"viewer": viewer_position,
		"viewer_radius": viewer_radius,
	}

	# Pass 1: ask the expression for each cube's desired level + read
	# parent visibility (basis scale != 0 => visible).
	var desired: PackedInt32Array = PackedInt32Array()
	desired.resize(instance_count)
	var visible: PackedByteArray = PackedByteArray()
	visible.resize(instance_count)
	for i in range(instance_count):
		var xyz: Vector3i = cell_xyz(i, dims)
		ctx["xyz"] = xyz
		ctx["x"] = xyz.x
		ctx["y"] = xyz.y
		ctx["z"] = xyz.z
		var level: int = int(fn.call(i, xyz.z, xyz.x, grid_size, t, ctx))
		desired[i] = clamp(level, 0, 1)
		var xf: Transform3D = multimesh.get_instance_transform(i)
		var sc: Vector3 = xf.basis.get_scale()
		visible[i] = 1 if sc.length() > 0.01 else 0

	# Pass 2: gather candidates (visible AND desired >= 1), score by
	# distance-to-viewer (closer = higher priority), enforce budget.
	# CRITICAL: skip cubes that PATH_GUARANTEE force-filled — subdividing
	# them would hide the parent, breaking the player's walk route.
	var sibling_vis: Node = _find_sibling_visibility_mutator()
	var protected_fills: PackedByteArray = PackedByteArray()
	if sibling_vis and "_floor_plan_fill_mask" in sibling_vis:
		protected_fills = sibling_vis._floor_plan_fill_mask
	var candidates: Array = []
	for i in range(instance_count):
		if desired[i] >= 1 and visible[i] != 0:
			# Skip path-fill cubes so PATH_GUARANTEE's route stays walkable.
			if i < protected_fills.size() and protected_fills[i] != 0:
				continue
			candidates.append(i)
	if candidates.size() > max_subdivided_cells:
		# Sort by distance-to-viewer ascending; keep the closest budget worth.
		var with_distance: Array = []
		for i in candidates:
			var origin: Vector3 = multimesh.get_instance_transform(i).origin
			var d: float = origin.distance_squared_to(viewer_position)
			with_distance.append([d, i])
		with_distance.sort_custom(func(a, b): return a[0] < b[0])
		candidates.clear()
		for k in range(max_subdivided_cells):
			candidates.append(with_distance[k][1])
	var subdivide_set: Dictionary = {}
	for i in candidates:
		subdivide_set[i] = true

	# Pass 3: rebuild parent + sub-mesh state.
	# - Snapshot pre-glyph parent transforms so the next apply can restore.
	# - For each newly-subdivided parent, hide it and place 8 sub-cubes.
	if _subdivided.size() != instance_count:
		_subdivided.resize(instance_count)
	for i in range(instance_count):
		_pre_glyph_transforms[i] = multimesh.get_instance_transform(i)
	_has_cached = true

	# Clear sub-mesh first (zero all sub-cube transforms).
	for k in range(_sub_mesh.instance_count):
		_sub_mesh.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))

	var sub_index: int = 0
	for i in range(instance_count):
		if subdivide_set.has(i):
			_subdivided[i] = 1
			var parent_xf: Transform3D = multimesh.get_instance_transform(i)
			var parent_origin: Vector3 = parent_xf.origin
			var parent_color: Color = (
				multimesh.get_instance_color(i) if multimesh.use_colors else Color.WHITE
			)
			# Hide parent.
			var hidden_basis: Basis = Basis().scaled(Vector3.ZERO)
			multimesh.set_instance_transform(i, Transform3D(hidden_basis, parent_origin))
			# Write 8 sub-cubes at parent ± (cube_size * 0.25) per axis.
			for sub in range(8):
				if sub_index >= _sub_mesh.instance_count:
					break
				var dx: float = (-0.25 if (sub & 1) == 0 else 0.25) * cube_size
				var dy: float = (-0.25 if (sub & 2) == 0 else 0.25) * cube_size
				var dz: float = (-0.25 if (sub & 4) == 0 else 0.25) * cube_size
				var sub_origin: Vector3 = parent_origin + Vector3(dx, dy, dz)
				_sub_mesh.set_instance_transform(sub_index, Transform3D(Basis(), sub_origin))
				_sub_mesh.set_instance_color(sub_index, parent_color)
				sub_index += 1
		else:
			_subdivided[i] = 0

	_log("GridGlyphMutator: '%s' subdivided %d/%d eligible" % [pattern_name, candidates.size(), instance_count])


# --- sub-mesh setup --------------------------------------------------------

func _find_sibling_visibility_mutator() -> Node:
	# Glyph runs after visibility; both are mounted as children of the same
	# runner Node. Find the sibling whose script's class chain contains
	# GridVisibilityMutator.
	var parent: Node = get_parent()
	if not parent:
		return null
	for sibling in parent.get_children():
		var s: Script = sibling.get_script()
		while s:
			if s.get_global_name() == "GridVisibilityMutator":
				return sibling
			s = s.get_base_script()
	return null


func _ensure_sub_mesh() -> void:
	if _sub_instance and _sub_mesh:
		return
	if not multimesh_instance:
		return

	_sub_instance = MultiMeshInstance3D.new()
	_sub_instance.name = "GlyphSubMesh"
	multimesh_instance.add_sibling(_sub_instance)

	var box := BoxMesh.new()
	box.size = Vector3(cube_size * sub_cube_scale, cube_size * sub_cube_scale, cube_size * sub_cube_scale)

	_sub_mesh = MultiMesh.new()
	_sub_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_sub_mesh.use_colors = true
	_sub_mesh.mesh = box
	_sub_mesh.instance_count = max_subdivided_cells * 8

	# All hidden initially.
	for k in range(_sub_mesh.instance_count):
		_sub_mesh.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		_sub_mesh.set_instance_color(k, Color.WHITE)

	_sub_instance.multimesh = _sub_mesh

	# Inherit material from parent so sub-cubes match the host's shader.
	if multimesh_instance.material_override:
		_sub_instance.material_override = multimesh_instance.material_override
