# ca_surface_sdf.gd
# SDF subclass for seq 9 — cellular automata. Runs B3/S23 on a 2D lattice,
# then the SDF is "distance to nearest live cell's voxel shape". Live cells
# form cubes at their grid positions.

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")

@export var grid_size: Vector2i = Vector2i(32, 32)
@export var iterations: int = 4
@export var seed_density: float = 0.32
@export var cell_size: float = 0.4
@export var cell_height: float = 0.3
@export var origin: Vector3 = Vector3.ZERO
@export var seed: int = 20260418

## Cached live-cell positions. Built lazily on first signed_distance() call.
var _live_cells: PackedVector2Array = PackedVector2Array()
var _dirty: bool = true


## Rebuild the CA field. Call after changing any parameter.
func rebuild() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	# Seed — 2D boolean grid
	var cells: Array = []
	for x in grid_size.x:
		var col: Array = []
		for z in grid_size.y:
			col.append(1 if rng.randf() < seed_density else 0)
		cells.append(col)

	# Run B3/S23 for `iterations` steps
	for _it in iterations:
		var next: Array = []
		for x in grid_size.x:
			var col: Array = []
			for z in grid_size.y:
				var n: int = _count_neighbors(cells, x, z)
				var alive: bool = cells[x][z] == 1
				var nx: int = 0
				if alive and (n == 2 or n == 3): nx = 1
				elif not alive and n == 3: nx = 1
				col.append(nx)
			next.append(col)
		cells = next

	# Collect live cell positions
	_live_cells.clear()
	var half_x: float = float(grid_size.x) * cell_size * 0.5
	var half_z: float = float(grid_size.y) * cell_size * 0.5
	for x in grid_size.x:
		for z in grid_size.y:
			if cells[x][z] == 1:
				var wx: float = float(x) * cell_size - half_x
				var wz: float = float(z) * cell_size - half_z
				_live_cells.append(Vector2(wx, wz))
	_dirty = false


func signed_distance(p: Vector3) -> float:
	if _dirty:
		rebuild()
	if _live_cells.is_empty():
		return INF
	# SDF = min distance to any live cell's box. Each live cell is a
	# flattened voxel (cell_size × cell_height × cell_size).
	var local: Vector3 = p - origin
	var best: float = INF
	var half_cell: Vector3 = Vector3(cell_size * 0.5, cell_height * 0.5, cell_size * 0.5)
	for lc in _live_cells:
		var rel := Vector3(local.x - lc.x, local.y, local.z - lc.y)
		var d: float = SdfOps.sdf_box(rel, half_cell)
		if d < best:
			best = d
	return best


func get_aabb() -> AABB:
	var half_x: float = float(grid_size.x) * cell_size * 0.5 + cell_size
	var half_z: float = float(grid_size.y) * cell_size * 0.5 + cell_size
	return AABB(
		origin + Vector3(-half_x, -cell_height, -half_z),
		Vector3(half_x * 2.0, cell_height * 2.0, half_z * 2.0)
	)


func _count_neighbors(cells: Array, x: int, z: int) -> int:
	var n: int = 0
	var w: int = grid_size.x
	var d: int = grid_size.y
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0: continue
			var nx: int = (x + dx + w) % w
			var nz: int = (z + dz + d) % d
			n += int(cells[nx][nz])
	return n
