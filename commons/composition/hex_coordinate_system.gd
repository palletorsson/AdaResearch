## HexCS — Hexagonal coordinate system using offset (col, row) coordinates
## Pointy-top hexagons with odd-row offset.
## Natural for Islamic geometric, honeycomb, hex tessellations.
##
## grid_width  = number of columns
## grid_height = number of rows
##
## cell_size is the circumradius (center to vertex distance) of each hex.
## Pointy-top geometry:
##   horizontal spacing = sqrt(3) * cell_size
##   vertical spacing   = 1.5 * cell_size
##   inradius (center to edge) = sqrt(3)/2 * cell_size

extends "res://commons/composition/coordinate_system.gd"

const SQRT3 := 1.7320508075688772  # sqrt(3)
const SQRT3_HALF := 0.8660254037844386  # sqrt(3) / 2

# Gap factor shrinks each hex slightly so adjacent cells don't overlap visually.
# 0.96 leaves a thin seam; use 1.0 for seamless tiling.
const GAP_FACTOR := 0.96

# ═══════════════════════════════════════════════════════════════════
# NEIGHBOR DIRECTIONS — odd-r offset coordinate system
# ═══════════════════════════════════════════════════════════════════

## Neighbor offsets for even rows (row % 2 == 0)
const NEIGHBORS_EVEN_ROW: Array[Vector2i] = [
	Vector2i( 1,  0),  # East
	Vector2i( 0, -1),  # NE
	Vector2i(-1, -1),  # NW
	Vector2i(-1,  0),  # West
	Vector2i(-1,  1),  # SW
	Vector2i( 0,  1),  # SE
]

## Neighbor offsets for odd rows (row % 2 == 1)
const NEIGHBORS_ODD_ROW: Array[Vector2i] = [
	Vector2i( 1,  0),  # East
	Vector2i( 1, -1),  # NE
	Vector2i( 0, -1),  # NW
	Vector2i(-1,  0),  # West
	Vector2i( 0,  1),  # SW
	Vector2i( 1,  1),  # SE
]

## Axial neighbor directions (for use after offset_to_axial conversion)
const AXIAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i( 1,  0), Vector2i( 1, -1), Vector2i( 0, -1),
	Vector2i(-1,  0), Vector2i(-1,  1), Vector2i( 0,  1),
]

# ═══════════════════════════════════════════════════════════════════
# INIT
# ═══════════════════════════════════════════════════════════════════

func _init(w: int = 20, h: int = 20, cs: float = 1.0) -> void:
	type = Type.HEX
	grid_width = w
	grid_height = h
	cell_size = cs

# ═══════════════════════════════════════════════════════════════════
# COORDINATE SYSTEM INTERFACE
# ═══════════════════════════════════════════════════════════════════

func iterate_cells() -> Array:
	var cells: Array = []
	for r in grid_height:
		for q in grid_width:
			cells.append(Vector2i(q, r))
	return cells

func cell_to_world(cell_key) -> Vector3:
	var col: int = cell_key.x
	var row: int = cell_key.y
	# Pointy-top, odd-row offset:
	#   x = sqrt(3) * (col + 0.5 * (row & 1))
	#   z = 1.5 * row
	var x_offset: float = 0.5 if (row & 1) else 0.0
	var wx: float = (float(col) + x_offset) * SQRT3 * cell_size
	var wz: float = float(row) * 1.5 * cell_size
	# Center the entire grid around the origin
	var total_w: float = get_world_width()
	var total_h: float = get_world_height()
	return Vector3(wx - total_w * 0.5 + SQRT3 * cell_size * 0.5,
				   0.0,
				   wz - total_h * 0.5 + 0.75 * cell_size)

func create_cell_mesh(_cell_key) -> Mesh:
	return _build_hex_mesh()

func cell_to_normalized(cell_key) -> Vector2:
	var col: int = cell_key.x
	var row: int = cell_key.y
	var x_offset: float = 0.5 if (row & 1) else 0.0
	# Map to 0..1 range across the grid extent
	var nx: float = (float(col) + x_offset) / float(grid_width)
	var ny: float = float(row) / float(grid_height)
	# Shift to cell center
	nx += 0.5 / float(grid_width)
	ny += 0.5 / float(grid_height)
	return Vector2(clampf(nx, 0.0, 1.0), clampf(ny, 0.0, 1.0))

func get_world_width() -> float:
	# Full columns plus the half-column offset on odd rows
	return (float(grid_width) + 0.5) * SQRT3 * cell_size

func get_world_height() -> float:
	# Each row after the first adds 1.5 * cell_size; top/bottom caps add 0.5 each
	if grid_height <= 0:
		return 0.0
	return float(grid_height - 1) * 1.5 * cell_size + 2.0 * cell_size

# ═══════════════════════════════════════════════════════════════════
# NEIGHBOR LOOKUP
# ═══════════════════════════════════════════════════════════════════

## Returns the 6 neighbor cell keys (Vector2i) of the given cell.
## Only returns neighbors that are within the grid bounds.
func get_neighbors(cell_key: Vector2i) -> Array[Vector2i]:
	var col: int = cell_key.x
	var row: int = cell_key.y
	var dirs = NEIGHBORS_ODD_ROW if (row & 1) else NEIGHBORS_EVEN_ROW
	var result: Array[Vector2i] = []
	for d in dirs:
		var nc: int = col + d.x
		var nr: int = row + d.y
		if nc >= 0 and nc < grid_width and nr >= 0 and nr < grid_height:
			result.append(Vector2i(nc, nr))
	return result

## Returns all 6 neighbor cell keys including out-of-bounds ones.
## Useful for wrapping grids or boundary detection.
func get_neighbors_unbounded(cell_key: Vector2i) -> Array[Vector2i]:
	var col: int = cell_key.x
	var row: int = cell_key.y
	var dirs = NEIGHBORS_ODD_ROW if (row & 1) else NEIGHBORS_EVEN_ROW
	var result: Array[Vector2i] = []
	for d in dirs:
		result.append(Vector2i(col + d.x, row + d.y))
	return result

## Hex distance between two cells (in offset coords, converted via axial).
func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var aa = offset_to_axial(a)
	var ba = offset_to_axial(b)
	var dq: int = absi(aa.x - ba.x)
	var dr: int = absi(aa.y - ba.y)
	var ds: int = absi((aa.x + aa.y) - (ba.x + ba.y))
	return maxi(dq, maxi(dr, ds))

## Returns all cells within a given hex radius of the center cell.
func get_cells_in_range(center: Vector2i, radius: int) -> Array[Vector2i]:
	var center_axial = offset_to_axial(center)
	var result: Array[Vector2i] = []
	for dq in range(-radius, radius + 1):
		var r_min: int = maxi(-radius, -dq - radius)
		var r_max: int = mini(radius, -dq + radius)
		for dr in range(r_min, r_max + 1):
			var axial = Vector2i(center_axial.x + dq, center_axial.y + dr)
			var offset = axial_to_offset(axial)
			if offset.x >= 0 and offset.x < grid_width and offset.y >= 0 and offset.y < grid_height:
				result.append(offset)
	return result

# ═══════════════════════════════════════════════════════════════════
# COORDINATE CONVERSION — offset <-> axial
# ═══════════════════════════════════════════════════════════════════

## Convert odd-row offset (col, row) to axial (q, r)
static func offset_to_axial(offset: Vector2i) -> Vector2i:
	var q: int = offset.x - (offset.y >> 1)
	var r: int = offset.y
	return Vector2i(q, r)

## Convert axial (q, r) to odd-row offset (col, row)
static func axial_to_offset(axial: Vector2i) -> Vector2i:
	var col: int = axial.x + (axial.y >> 1)
	var row: int = axial.y
	return Vector2i(col, row)

## Convert axial (q, r) to cube (q, r, s) where q + r + s = 0
static func axial_to_cube(axial: Vector2i) -> Vector3i:
	return Vector3i(axial.x, axial.y, -axial.x - axial.y)

# ═══════════════════════════════════════════════════════════════════
# HEX MESH — 6-triangle fan with proper bounding-box UVs
# ═══════════════════════════════════════════════════════════════════

func _build_hex_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	# Circumradius scaled down by gap factor
	var r: float = cell_size * GAP_FACTOR
	# Inradius (center to flat edge) for UV bounding box
	var inradius: float = SQRT3_HALF * r

	# Center vertex
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))

	# 6 outer vertices — pointy-top starts at 90 degrees (top vertex)
	for i in 6:
		var angle: float = PI / 6.0 + float(i) * PI / 3.0  # 30, 90, 150, 210, 270, 330
		var vx: float = r * cos(angle)
		var vz: float = r * sin(angle)
		vertices.append(Vector3(vx, 0.0, vz))
		normals.append(Vector3.UP)
		# Bounding-box UV: map hex extent to 0..1 range
		# Hex width  = 2 * inradius (sqrt(3) * r), height = 2 * r
		# Map x from [-inradius, inradius] -> [0, 1]
		# Map z from [-r, r] -> [0, 1]
		var u: float = 0.5 + vx / (2.0 * inradius)
		var v: float = 0.5 + vz / (2.0 * r)
		uvs.append(Vector2(u, v))

	# Fan triangulation from center: 6 triangles
	for i in 6:
		indices.append(0)
		indices.append(i + 1)
		indices.append((i + 1) % 6 + 1)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
