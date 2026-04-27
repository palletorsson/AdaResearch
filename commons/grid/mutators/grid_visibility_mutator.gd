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

# --- walk-path carving (manual) -------------------------------------------
# When walk_path_enabled, every cube inside the swept corridor along the
# waypoint polyline is forced HIDDEN. Use this for explicitly-authored routes
# through the volume; for pattern-driven routes, see floor_plan_mode below.
@export var walk_path_enabled: bool = false
@export var walk_path_points: Array[Vector3i] = []
@export var walk_path_width: int = 2  # corridor cross-section, in cubes (horizontal)
@export var walk_path_height: int = 2  # corridor vertical extent, in cubes (head-room)

# Computed once per (dims, path) and reused — 1 byte per instance.
var _walk_path_mask: PackedByteArray = PackedByteArray()
var _walk_path_cached_dims: Vector3i = Vector3i.ZERO
var _walk_path_cached_signature: String = ""


# --- floor-plan carving (pattern-driven) ----------------------------------
# Treats the bottom `floor_plan_layers` levels as the player's stratum and
# uses the active expression's natural empty cells there as walkable space.
# Pathfinding ensures the empty cells are connected.
#
#   DISABLED        — no floor-plan logic; pattern controls everything.
#   SPAWN_LARGEST   — identify the largest connected empty component on the
#                     floor; pattern unchanged, walkable cells exposed via
#                     get_walkable_floor_cells() / get_recommended_spawn().
#   AUTO_STITCH     — find disconnected empty regions and carve minimum
#                     doors between them so the whole floor is one component.
#   ALGORITHM_PATH  — if a sibling registry has provided a BFS route via
#                     set_algorithm_steps(), carve along that route. Falls
#                     back to AUTO_STITCH when no route is registered.
enum FloorPlanMode {
	DISABLED,
	SPAWN_LARGEST,
	AUTO_STITCH,
	ALGORITHM_PATH,
	# PATH_GUARANTEE: the inverse of AUTO_STITCH for floor-walking maps.
	# Treats visible cubes as the walkable surface (player walks on cube tops),
	# runs pathfinding from path_seed to path_target through visible cubes,
	# and FILLS empty cells along the cheapest connecting route so the player
	# can always traverse from spawn to teleporter regardless of which CA
	# pattern is active. Use for floor-as-CA maps where holes break the game.
	PATH_GUARANTEE,
}

@export_enum("disabled", "spawn_largest", "auto_stitch", "algorithm_path")
var floor_plan_mode: int = 0
@export var floor_plan_layers: int = 2

# Optional override start / end for ALGORITHM_PATH and PATH_GUARANTEE.
# (-1, -1, -1) = use the defaults the registry/runner provides.
@export var floor_plan_seed: Vector3i = Vector3i(-1, -1, -1)
@export var floor_plan_target: Vector3i = Vector3i(-1, -1, -1)

# State filled by _compute_floor_plan and exposed for downstream use.
var _floor_plan_mask: PackedByteArray = PackedByteArray()  # 1 = stitched-open (carved)
var _floor_plan_fill_mask: PackedByteArray = PackedByteArray()  # 1 = force-visible (filled)
var _floor_plan_walkable_cells: Array = []  # cells in the largest component
var _floor_plan_recommended_spawn: Vector3i = Vector3i.ZERO

# Optional algorithm route handed in by an expression registry that knows
# how to find paths through its own state (e.g. GridVisibilityExpressions3D).
var _algorithm_steps: PackedInt32Array = PackedInt32Array()
var _algorithm_seed: Vector3i = Vector3i(-1, -1, -1)
var _algorithm_target: Vector3i = Vector3i(-1, -1, -1)


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

	# Pass 1: ask the expression for visibility per cube; cache as bytes.
	var pattern_visible := PackedByteArray()
	pattern_visible.resize(instance_count)
	for i in range(instance_count):
		var xyz: Vector3i = cell_xyz(i, dims)
		ctx["xyz"] = xyz
		ctx["x"] = xyz.x
		ctx["y"] = xyz.y
		ctx["z"] = xyz.z
		var v: bool = bool(fn.call(i, xyz.z, xyz.x, grid_size, t, ctx))
		pattern_visible[i] = 1 if v else 0

	# Pass 2: floor-plan analysis (uses the cached pattern).
	if floor_plan_mode != FloorPlanMode.DISABLED:
		_compute_floor_plan(dims, pattern_visible)
	else:
		_floor_plan_mask = PackedByteArray()
		_floor_plan_fill_mask = PackedByteArray()
		_floor_plan_walkable_cells.clear()

	# Pass 3: apply final visibility:
	#   visible = (pattern OR fill) AND NOT walk_path AND NOT floor_plan_carve
	# fill_mask wins over the original pattern's "hidden" decision (used by
	# PATH_GUARANTEE to put cubes back in so the player has a floor).
	var visible_count: int = 0
	for i in range(instance_count):
		var is_visible: bool = pattern_visible[i] != 0
		if i < _floor_plan_fill_mask.size() and _floor_plan_fill_mask[i] != 0:
			is_visible = true
		if walk_path_enabled and i < _walk_path_mask.size() and _walk_path_mask[i] != 0:
			is_visible = false
		if i < _floor_plan_mask.size() and _floor_plan_mask[i] != 0:
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


# --- floor-plan analysis ---------------------------------------------------

# Provided by an external registry that has computed a BFS route through the
# pattern (typically GridVisibilityExpressions3D). When floor_plan_mode is
# ALGORITHM_PATH, the carve uses this route.
func set_algorithm_steps(steps: PackedInt32Array, seed: Vector3i, target: Vector3i) -> void:
	_algorithm_steps = steps
	_algorithm_seed = seed
	_algorithm_target = target


func get_walkable_floor_cells() -> Array:
	return _floor_plan_walkable_cells


func get_recommended_spawn() -> Vector3i:
	return _floor_plan_recommended_spawn


# Find connected components of empty cells in the bottom `floor_plan_layers`
# strata, then carve doors between them per `floor_plan_mode`.
func _compute_floor_plan(dims: Vector3i, pattern_visible: PackedByteArray) -> void:
	var w: int = max(dims.x, 1)
	var h: int = max(dims.y, 1)
	var d: int = max(dims.z, 1)
	var n_layers: int = clamp(floor_plan_layers, 1, h)
	var total: int = w * h * d

	_floor_plan_mask = PackedByteArray()
	_floor_plan_mask.resize(total)
	for k in range(total):
		_floor_plan_mask[k] = 0
	_floor_plan_fill_mask = PackedByteArray()
	_floor_plan_fill_mask.resize(total)
	for k in range(total):
		_floor_plan_fill_mask[k] = 0
	_floor_plan_walkable_cells.clear()

	# PATH_GUARANTEE inverts the empty-cell analysis: the player walks on
	# visible cubes, so we BFS through visible cubes from seed to target and
	# fill the cheapest cubes needed to make them connected.
	if floor_plan_mode == FloorPlanMode.PATH_GUARANTEE:
		_carve_walkable_path(dims, pattern_visible)
		var fc: int = 0
		for k in range(_floor_plan_fill_mask.size()):
			if _floor_plan_fill_mask[k] != 0:
				fc += 1
		_log("GridVisibilityMutator: PATH_GUARANTEE filled %d cubes (seed=%s target=%s dims=%s)" % [
			fc, floor_plan_seed, floor_plan_target, dims
		])
		return

	# Flood-fill empty cells in the floor strata.
	var visited := PackedByteArray()
	visited.resize(total)
	var components: Array = []
	const DIRS: Array = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	for y in range(n_layers):
		for z in range(d):
			for x in range(w):
				var i: int = y * (w * d) + z * w + x
				if pattern_visible[i] != 0 or visited[i] != 0:
					continue
				# BFS within the floor strata only.
				var component: Array = []
				var queue: Array = [Vector3i(x, y, z)]
				visited[i] = 1
				while not queue.is_empty():
					var c: Vector3i = queue.pop_back()
					component.append(c)
					for dir in DIRS:
						var nx: int = c.x + dir.x
						var ny: int = c.y + dir.y
						var nz: int = c.z + dir.z
						if nx < 0 or nx >= w or ny < 0 or ny >= n_layers or nz < 0 or nz >= d:
							continue
						var ni: int = ny * (w * d) + nz * w + nx
						if pattern_visible[ni] != 0 or visited[ni] != 0:
							continue
						visited[ni] = 1
						queue.append(Vector3i(nx, ny, nz))
				components.append(component)

	if components.is_empty():
		return
	components.sort_custom(func(a, b): return a.size() > b.size())
	_floor_plan_walkable_cells = components[0].duplicate()
	_floor_plan_recommended_spawn = components[0][0] if components[0].size() > 0 else Vector3i.ZERO

	if floor_plan_mode == FloorPlanMode.SPAWN_LARGEST:
		return

	if floor_plan_mode == FloorPlanMode.ALGORITHM_PATH and _algorithm_steps.size() == total:
		_carve_algorithm_path(dims, pattern_visible)
		# Re-flood the largest component now that the algorithm path is open.
		_recompute_walkable_after_carve(dims, pattern_visible)
		return

	# AUTO_STITCH (or ALGORITHM_PATH fallback): connect every smaller component
	# to the main one by carving the cheapest cube wall between them.
	if components.size() <= 1:
		return
	var main: Array = components[0]
	for ci in range(1, components.size()):
		var other: Array = components[ci]
		_stitch_components(main, other, dims, pattern_visible)
	_recompute_walkable_after_carve(dims, pattern_visible)


# BFS from any cell of `from` to any cell of `to` through the FULL volume,
# treating empty cells as cost 0 and visible cells as cost 1. The cheapest
# path's cost-1 cubes get marked in _floor_plan_mask (i.e., carved open).
func _stitch_components(from_comp: Array, to_comp: Array, dims: Vector3i, pattern_visible: PackedByteArray) -> void:
	var w: int = dims.x
	var h: int = dims.y
	var d: int = dims.z
	var total: int = w * h * d
	const INF: int = 0x7FFFFFFF
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(total)
	for k in range(total):
		dist[k] = INF
	var prev: PackedInt32Array = PackedInt32Array()
	prev.resize(total)
	for k in range(total):
		prev[k] = -1
	# 0/1-BFS via deque so cost-0 (empty) edges go to front, cost-1 (cube wall) to back.
	# Restrict expansion to the floor strata so doors stay at floor level.
	var n_layers: int = clamp(floor_plan_layers, 1, h)
	var deque: Array = []
	var to_set: Dictionary = {}
	for c in to_comp:
		to_set[c.y * (w * d) + c.z * w + c.x] = true
	for c in from_comp:
		var idx: int = c.y * (w * d) + c.z * w + c.x
		dist[idx] = 0
		deque.append(idx)
	const DIRS: Array = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	var found: int = -1
	while not deque.is_empty():
		var u: int = deque.pop_front()
		if to_set.has(u):
			found = u
			break
		var uy: int = u / (w * d)
		var uz: int = (u / w) % d
		var ux: int = u % w
		for dir in DIRS:
			var nx: int = ux + dir.x
			var ny: int = uy + dir.y
			var nz: int = uz + dir.z
			if nx < 0 or nx >= w or ny < 0 or ny >= n_layers or nz < 0 or nz >= d:
				continue
			var ni: int = ny * (w * d) + nz * w + nx
			# Cost: 0 if cell is empty (or already carved), 1 if visible.
			var carved_already: bool = (_floor_plan_mask[ni] != 0)
			var cost: int = 0 if (pattern_visible[ni] == 0 or carved_already) else 1
			var nd: int = dist[u] + cost
			if nd < dist[ni]:
				dist[ni] = nd
				prev[ni] = u
				if cost == 0:
					deque.push_front(ni)
				else:
					deque.push_back(ni)
	if found < 0:
		return
	# Walk back from `found` to a from-comp cell, carving cost-1 cubes.
	var cur: int = found
	while cur != -1:
		if pattern_visible[cur] != 0:
			_floor_plan_mask[cur] = 1
		cur = prev[cur]


# Use the registry's BFS step grid to walk from target back to seed and carve
# the resulting path. Path is the canonical algorithm-as-route: the player's
# corridor is literally what BFS computed.
func _carve_algorithm_path(dims: Vector3i, pattern_visible: PackedByteArray) -> void:
	var w: int = dims.x
	var h: int = dims.y
	var d: int = dims.z
	var seed: Vector3i = floor_plan_seed if floor_plan_seed.x >= 0 else _algorithm_seed
	var target: Vector3i = floor_plan_target if floor_plan_target.x >= 0 else _algorithm_target
	if seed.x < 0 or target.x < 0:
		return
	# Walk from target down the BFS gradient (decreasing step values) to seed.
	# At each step, carve the cube and pick a neighbour with step value one less.
	const DIRS: Array = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	var cur: Vector3i = target
	var safety: int = w * h * d  # cap iterations to avoid pathological loops
	while cur != seed and safety > 0:
		var idx: int = cur.y * (w * d) + cur.z * w + cur.x
		# Carve the visible cube at the current cell so the route is open.
		if idx >= 0 and idx < pattern_visible.size() and pattern_visible[idx] != 0:
			_floor_plan_mask[idx] = 1
		var step: int = _algorithm_steps[idx]
		var moved: bool = false
		for dir in DIRS:
			var nx: int = cur.x + dir.x
			var ny: int = cur.y + dir.y
			var nz: int = cur.z + dir.z
			if nx < 0 or nx >= w or ny < 0 or ny >= h or nz < 0 or nz >= d:
				continue
			var ni: int = ny * (w * d) + nz * w + nx
			if _algorithm_steps[ni] == step - 1:
				cur = Vector3i(nx, ny, nz)
				moved = true
				break
		if not moved:
			break
		safety -= 1
	# Carve the seed cell too.
	var seed_idx: int = seed.y * (w * d) + seed.z * w + seed.x
	if seed_idx >= 0 and seed_idx < pattern_visible.size() and pattern_visible[seed_idx] != 0:
		_floor_plan_mask[seed_idx] = 1


# PATH_GUARANTEE: BFS from path_seed to path_target through VISIBLE cubes
# (cost 0) and EMPTY cubes (cost 1). The cheapest path's cost-1 cubes get
# marked in _floor_plan_fill_mask — they'll be force-rendered visible at
# Pass 3 so the player has an unbroken walkable surface from spawn to goal.
# Restricted to the floor strata so the route stays at floor level.
func _carve_walkable_path(dims: Vector3i, pattern_visible: PackedByteArray) -> void:
	var w: int = max(dims.x, 1)
	var h: int = max(dims.y, 1)
	var d: int = max(dims.z, 1)
	var total: int = w * h * d
	var n_layers: int = clamp(floor_plan_layers, 1, h)

	# Resolve seed/target. Default to corners on the floor if unset.
	var seed: Vector3i = floor_plan_seed
	var target: Vector3i = floor_plan_target
	if seed.x < 0:
		seed = Vector3i(0, 0, 0)
	if target.x < 0:
		target = Vector3i(w - 1, 0, d - 1)
	# Clamp into the floor strata.
	seed = Vector3i(clamp(seed.x, 0, w - 1), clamp(seed.y, 0, n_layers - 1), clamp(seed.z, 0, d - 1))
	target = Vector3i(clamp(target.x, 0, w - 1), clamp(target.y, 0, n_layers - 1), clamp(target.z, 0, d - 1))

	const INF: int = 0x7FFFFFFF
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(total)
	for k in range(total):
		dist[k] = INF
	var prev: PackedInt32Array = PackedInt32Array()
	prev.resize(total)
	for k in range(total):
		prev[k] = -1

	var seed_idx: int = seed.y * (w * d) + seed.z * w + seed.x
	var target_idx: int = target.y * (w * d) + target.z * w + target.x
	dist[seed_idx] = 0
	var deque: Array = [seed_idx]
	const DIRS: Array = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]

	while not deque.is_empty():
		var u: int = deque.pop_front()
		if u == target_idx:
			break
		if dist[u] == INF:
			continue
		var uy: int = u / (w * d)
		var uz: int = (u / w) % d
		var ux: int = u % w
		for dir in DIRS:
			var nx: int = ux + dir.x
			var ny: int = uy + dir.y
			var nz: int = uz + dir.z
			if nx < 0 or nx >= w or ny < 0 or ny >= n_layers or nz < 0 or nz >= d:
				continue
			var ni: int = ny * (w * d) + nz * w + nx
			if ni < 0 or ni >= pattern_visible.size():
				continue
			# Cost: 0 if cell already has a visible cube (player can walk on it),
			# 1 if empty (we'd need to fill the cell to make it walkable).
			var cost: int = 0 if pattern_visible[ni] != 0 else 1
			var nd: int = dist[u] + cost
			if nd < dist[ni]:
				dist[ni] = nd
				prev[ni] = u
				if cost == 0:
					deque.push_front(ni)
				else:
					deque.push_back(ni)

	if dist[target_idx] == INF:
		return  # nothing we can do; no route within the floor strata

	# Walk back from target → seed; mark every empty cell on the path for fill.
	var cur: int = target_idx
	while cur != -1:
		if pattern_visible[cur] == 0:
			_floor_plan_fill_mask[cur] = 1
		if cur == seed_idx:
			break
		cur = prev[cur]

	# Record walkable component for downstream queries.
	_floor_plan_recommended_spawn = seed
	_floor_plan_walkable_cells = [seed, target]


# After stitching/path-carving, re-flood the floor strata to capture the now-
# unified largest component (so get_walkable_floor_cells reflects post-carve).
func _recompute_walkable_after_carve(dims: Vector3i, pattern_visible: PackedByteArray) -> void:
	var w: int = dims.x
	var d: int = dims.z
	var h: int = dims.y
	var n_layers: int = clamp(floor_plan_layers, 1, h)
	var total: int = w * h * d
	var visited := PackedByteArray()
	visited.resize(total)
	var biggest: Array = []
	const DIRS: Array = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	for y in range(n_layers):
		for z in range(d):
			for x in range(w):
				var i: int = y * (w * d) + z * w + x
				var blocked: bool = pattern_visible[i] != 0 and _floor_plan_mask[i] == 0
				if blocked or visited[i] != 0:
					continue
				var comp: Array = []
				var queue: Array = [Vector3i(x, y, z)]
				visited[i] = 1
				while not queue.is_empty():
					var c: Vector3i = queue.pop_back()
					comp.append(c)
					for dir in DIRS:
						var nx: int = c.x + dir.x
						var ny: int = c.y + dir.y
						var nz: int = c.z + dir.z
						if nx < 0 or nx >= w or ny < 0 or ny >= n_layers or nz < 0 or nz >= d:
							continue
						var ni: int = ny * (w * d) + nz * w + nx
						var nblocked: bool = pattern_visible[ni] != 0 and _floor_plan_mask[ni] == 0
						if nblocked or visited[ni] != 0:
							continue
						visited[ni] = 1
						queue.append(Vector3i(nx, ny, nz))
				if comp.size() > biggest.size():
					biggest = comp
	_floor_plan_walkable_cells = biggest
	if biggest.size() > 0:
		_floor_plan_recommended_spawn = biggest[0]
