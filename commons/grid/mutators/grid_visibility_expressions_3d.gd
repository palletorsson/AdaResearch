# GridVisibilityExpressions3D.gd
# Three 3D-native visibility expression families. Add as a child of (or sibling
# to) a GridVisibilityMutator on a volumetric MultiMesh; on _ready it registers:
#
#   menger_sponge     — recursive ternary mask, the classic hollow sponge
#   sphere_shell      — cubes whose centre lies within a spherical shell
#   bfs_frontier_t1   — \
#   bfs_frontier_t2    \   eight snapshots of breadth-first expansion from a
#   ...                |   seed corner, six-connectivity in the volume.
#   bfs_frontier_t8   /    Cycling them animates the frontier sweeping the box.
#
# Each expression is a pure function (i, row, col, grid_size, t, ctx) -> bool
# but reads ctx.dims, ctx.x, ctx.y, ctx.z to operate volumetrically. ctx is
# provided by GridVisibilityMutator after the grid_dims refactor.
#
# @identity
# essence: bool(x, y, z) -> visibility, three families that actually use y
# desire: to make the y axis carry meaning — fractals that fold through space,
#   shells that surround the player, search frontiers that expand around them
# critical_parameter: which expressions get registered — Menger / shell / BFS-by-step
# triggers: _ready calls register_for(target_mutator)
# emerges: a Menger sponge built of cubes the player walks through; a BFS
#   frontier sweeping the volume one step at a time; a sphere with thickness
# needs: a GridVisibilityMutator on a volumetric MultiMesh [ctx.dims must be set]
# relationships: GridVisibilityMutator (target); GridVisibilityExpressions
#   (sibling — same shape, 2D-only)
# truth: a 3D principle is a function from (x, y, z) to a bool

class_name GridVisibilityExpressions3D
extends Node

@export var target_mutator_path: NodePath = ""

# BFS seed cube. (0, 0, 0) puts it in one corner so frontier sweeps the whole
# box visibly across the eight registered time steps.
@export var bfs_seed: Vector3i = Vector3i(0, 0, 0)
@export var bfs_steps: int = 8


func _ready() -> void:
	var mutator: Node = _resolve_target()
	if not mutator:
		push_warning("GridVisibilityExpressions3D: no GridVisibilityMutator found")
		return
	register_for(mutator)


func register_for(mutator: Node) -> void:
	mutator.register_expression("menger_sponge", Callable(self, "_menger_sponge"))
	mutator.register_expression("sphere_shell", Callable(self, "_sphere_shell"))
	for n in range(1, bfs_steps + 1):
		var name := "bfs_frontier_t%d" % n
		# Capture n by value via a small closure helper.
		mutator.register_expression(name, _bfs_at(n))


func _resolve_target() -> Node:
	if not target_mutator_path.is_empty():
		var n: Node = get_node_or_null(target_mutator_path)
		if n and n.get_script() and n.get_script().get_global_name() == "GridVisibilityMutator":
			return n
	var parent: Node = get_parent()
	if parent:
		for sibling in parent.get_children():
			if sibling.get_script() and sibling.get_script().get_global_name() == "GridVisibilityMutator":
				return sibling
	return null


# --- expressions -----------------------------------------------------------

# Menger sponge: a cube is solid iff at no recursion level does the trit
# tuple (x % 3, y % 3, z % 3) contain two or more 1s. Works on any size by
# recursing while any coord is non-zero.
func _menger_sponge(_i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> bool:
	var x: int = ctx.get("x", 0)
	var y: int = ctx.get("y", 0)
	var z: int = ctx.get("z", 0)
	while x > 0 or y > 0 or z > 0:
		var xc: int = 1 if (x % 3) == 1 else 0
		var yc: int = 1 if (y % 3) == 1 else 0
		var zc: int = 1 if (z % 3) == 1 else 0
		if xc + yc + zc >= 2:
			return false
		x = x / 3
		y = y / 3
		z = z / 3
	return true


# Spherical shell: cubes whose centre lies inside [r - w, r + w] from the
# volume centre. Radius scales with the smallest dimension so the shell fits.
func _sphere_shell(_i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> bool:
	var dims: Vector3i = ctx.get("dims", Vector3i(1, 1, 1))
	var x: int = ctx.get("x", 0)
	var y: int = ctx.get("y", 0)
	var z: int = ctx.get("z", 0)
	var center := Vector3((dims.x - 1) * 0.5, (dims.y - 1) * 0.5, (dims.z - 1) * 0.5)
	var pos := Vector3(float(x), float(y), float(z))
	var r: float = float(min(dims.x, min(dims.y, dims.z))) * 0.4
	var w: float = 0.7
	var d: float = pos.distance_to(center)
	return abs(d - r) <= w


# --- BFS frontier -----------------------------------------------------------
# State is computed once per (dims, seed) and cached; each registered expression
# (bfs_frontier_t1 ... bfs_frontier_tN) reads the same step grid and answers
# "is this cell reached by step n?" in O(1).

var _bfs_steps: PackedInt32Array = PackedInt32Array()
var _bfs_dims: Vector3i = Vector3i.ZERO
var _bfs_seed_cached: Vector3i = Vector3i(-1, -1, -1)


func _ensure_bfs(dims: Vector3i) -> void:
	if dims == _bfs_dims and bfs_seed == _bfs_seed_cached and _bfs_steps.size() > 0:
		return
	_bfs_dims = dims
	_bfs_seed_cached = bfs_seed

	var w: int = max(dims.x, 1)
	var h: int = max(dims.y, 1)
	var d: int = max(dims.z, 1)
	var n: int = w * h * d

	const UNREACHED: int = 0x7FFFFFFF
	_bfs_steps = PackedInt32Array()
	_bfs_steps.resize(n)
	for k in range(n):
		_bfs_steps[k] = UNREACHED

	var seed_x: int = clamp(bfs_seed.x, 0, w - 1)
	var seed_y: int = clamp(bfs_seed.y, 0, h - 1)
	var seed_z: int = clamp(bfs_seed.z, 0, d - 1)
	var seed_idx: int = seed_y * (w * d) + seed_z * w + seed_x
	_bfs_steps[seed_idx] = 0

	var queue: Array = [Vector3i(seed_x, seed_y, seed_z)]
	var head: int = 0
	const DIRS: Array = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]
	while head < queue.size():
		var cell: Vector3i = queue[head]
		head += 1
		var ci: int = cell.y * (w * d) + cell.z * w + cell.x
		var current_step: int = _bfs_steps[ci]
		for dir in DIRS:
			var nx: int = cell.x + dir.x
			var ny: int = cell.y + dir.y
			var nz: int = cell.z + dir.z
			if nx < 0 or nx >= w or ny < 0 or ny >= h or nz < 0 or nz >= d:
				continue
			var ni: int = ny * (w * d) + nz * w + nx
			if _bfs_steps[ni] != UNREACHED:
				continue
			_bfs_steps[ni] = current_step + 1
			queue.append(Vector3i(nx, ny, nz))


func _bfs_at(step_threshold: int) -> Callable:
	# A small adapter that captures step_threshold and answers "step[i] <= threshold".
	return func(i: int, _row: int, _col: int, _grid_size: int, _t: float, ctx: Dictionary) -> bool:
		var dims: Vector3i = ctx.get("dims", Vector3i(1, 1, 1))
		_ensure_bfs(dims)
		if i < 0 or i >= _bfs_steps.size():
			return false
		return _bfs_steps[i] <= step_threshold
