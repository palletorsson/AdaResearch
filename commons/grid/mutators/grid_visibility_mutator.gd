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

# --- walk-path carving -----------------------------------------------------
# When walk_path_enabled, every cube that sits inside the swept corridor along
# the waypoint polyline is forced HIDDEN regardless of what the active
# expression decided. Lets the player walk through any pattern without
# phasing through cubes. Path is in cube coordinates (Vector3i grid cells).
@export var walk_path_enabled: bool = false
@export var walk_path_points: Array[Vector3i] = []
@export var walk_path_width: int = 2  # corridor cross-section, in cubes (horizontal)
@export var walk_path_height: int = 2  # corridor vertical extent, in cubes (head-room)

# Computed once per (dims, path) and reused — 1 byte per instance.
var _walk_path_mask: PackedByteArray = PackedByteArray()
var _walk_path_cached_dims: Vector3i = Vector3i.ZERO
var _walk_path_cached_signature: String = ""


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
	var dims: Vector3i = resolve_dims()
	var grid_size: int = legacy_grid_size(dims)

	var t: float = Time.get_ticks_msec() / 1000.0
	var ctx: Dictionary = {
		"structure": grid_structure,
		"grid_size": grid_size,
		"dims": dims,
		"instance_count": instance_count,
	}

	# Recompute the walk-path corridor mask if enabled and the path/dims changed.
	if walk_path_enabled:
		_ensure_walk_path_mask(dims)

	var visible_count: int = 0
	for i in range(instance_count):
		var xyz: Vector3i = cell_xyz(i, dims)
		ctx["xyz"] = xyz
		ctx["x"] = xyz.x
		ctx["y"] = xyz.y
		ctx["z"] = xyz.z
		# Legacy 2D mapping: row = z, col = x. Old expressions read these.
		var is_visible: bool = bool(fn.call(i, xyz.z, xyz.x, grid_size, t, ctx))
		# Walk-path carve: corridor cubes are forced hidden so the player can pass.
		if walk_path_enabled and i < _walk_path_mask.size() and _walk_path_mask[i] != 0:
			is_visible = false
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


# --- walk-path mask --------------------------------------------------------

func _walk_path_signature() -> String:
	# Build a short signature so we can detect when the path/width/height changed.
	var parts: Array = []
	for p in walk_path_points:
		parts.append("%d,%d,%d" % [p.x, p.y, p.z])
	return "%dx%d|%s" % [walk_path_width, walk_path_height, ";".join(parts)]


func _ensure_walk_path_mask(dims: Vector3i) -> void:
	var sig: String = _walk_path_signature()
	if dims == _walk_path_cached_dims and sig == _walk_path_cached_signature and _walk_path_mask.size() == dims.x * dims.y * dims.z:
		return
	_walk_path_cached_dims = dims
	_walk_path_cached_signature = sig

	var w: int = max(dims.x, 1)
	var h: int = max(dims.y, 1)
	var d: int = max(dims.z, 1)
	_walk_path_mask = PackedByteArray()
	_walk_path_mask.resize(w * h * d)
	for k in range(_walk_path_mask.size()):
		_walk_path_mask[k] = 0

	if walk_path_points.size() < 2:
		return

	var width: int = max(walk_path_width, 1)
	var height: int = max(walk_path_height, 1)
	# Asymmetric half-extents so a width=2 corridor carves exactly 2 cubes
	# (offsets 0..1), width=3 carves 3 (-1..1), width=4 carves 4 (-1..2).
	var left_x: int = -((width - 1) / 2)
	var right_x: int = width / 2
	var left_z: int = -((width - 1) / 2)
	var right_z: int = width / 2

	for seg in range(walk_path_points.size() - 1):
		var a: Vector3i = walk_path_points[seg]
		var b: Vector3i = walk_path_points[seg + 1]
		_carve_segment(a, b, left_x, right_x, left_z, right_z, height, dims)


func _carve_segment(a: Vector3i, b: Vector3i, left_x: int, right_x: int, left_z: int, right_z: int, height: int, dims: Vector3i) -> void:
	# Sample the segment at unit-step density and flood the cross-section at each step.
	var diff: Vector3 = Vector3(b - a)
	var length: float = diff.length()
	var steps: int = max(int(ceil(length)), 1)
	for s in range(steps + 1):
		var ft: float = 0.0 if steps == 0 else float(s) / float(steps)
		var p: Vector3 = Vector3(a) + diff * ft
		var cx: int = int(round(p.x))
		var cy: int = int(round(p.y))
		var cz: int = int(round(p.z))
		# Carve a width × height × width box centred (horizontally) on (cx, cy, cz),
		# rising upward by `height` cubes (vertical headroom for the player).
		for dy in range(height):
			for dz in range(left_z, right_z + 1):
				for dx in range(left_x, right_x + 1):
					var nx: int = cx + dx
					var ny: int = cy + dy
					var nz: int = cz + dz
					if nx < 0 or nx >= dims.x or ny < 0 or ny >= dims.y or nz < 0 or nz >= dims.z:
						continue
					var idx: int = ny * (dims.x * dims.z) + nz * dims.x + nx
					_walk_path_mask[idx] = 1


# Public: clear walk-path cache so it's recomputed on the next apply. Call after
# changing walk_path_points / walk_path_width / walk_path_height at runtime.
func refresh_walk_path() -> void:
	_walk_path_cached_signature = ""
	_walk_path_mask = PackedByteArray()
