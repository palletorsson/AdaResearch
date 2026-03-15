## CoordinateSystem — Abstract base for tiling coordinate systems
## Each implementation defines how cells are laid out in space,
## what shape they have, and how they map to world coordinates.
##
## Implementations: RectangularCS, HexCS, PolarCS, TruchetCS, VoronoiCS

extends RefCounted

enum Type { RECTANGULAR, HEX, POLAR, TRUCHET, VORONOI }

var type: int = Type.RECTANGULAR
var grid_width: int = 20
var grid_height: int = 20
var cell_size: float = 1.0  # World units per cell

# ═══════════════════════════════════════════════════════════════════
# ABSTRACT INTERFACE — override in subclasses
# ═══════════════════════════════════════════════════════════════════

## Returns array of cell keys. Each key uniquely identifies a cell.
## For rect/truchet: Vector2i(gx, gy)
## For hex: Vector2i(q, r) in axial coords
## For polar: Vector2i(ring, sector)
## For voronoi: int index
func iterate_cells() -> Array:
	return []

## Returns the world-space center position of a cell
func cell_to_world(cell_key) -> Vector3:
	return Vector3.ZERO

## Creates the mesh geometry for a single cell
func create_cell_mesh(cell_key) -> Mesh:
	return null

## Normalizes a cell position to fractional (0..1, 0..1) coordinates
## Used by SpatialComposition's region hit-testing
func cell_to_normalized(cell_key) -> Vector2:
	return Vector2(0.5, 0.5)

## Returns the bounding size in world units
func get_world_width() -> float:
	return float(grid_width) * cell_size

func get_world_height() -> float:
	return float(grid_height) * cell_size

# ═══════════════════════════════════════════════════════════════════
# FACTORY
# ═══════════════════════════════════════════════════════════════════

static var _scripts: Dictionary = {}

static func create_rectangular(w: int, h: int, cs: float = 1.0):
	return _create_impl("rectangular_coordinate_system", w, h, cs)

static func create_hex(w: int, h: int, cs: float = 1.0):
	return _create_impl("hex_coordinate_system", w, h, cs)

static func create_polar(num_rings: int, sectors: int, cs: float = 1.0):
	return _create_impl("polar_coordinate_system", num_rings, sectors, cs)

static func create_truchet(w: int, h: int, cs: float = 1.0):
	return _create_impl("truchet_coordinate_system", w, h, cs)

static func create_voronoi(seed_count: int, w: int, cs: float = 1.0):
	return _create_impl("voronoi_coordinate_system", seed_count, w, cs)

static func _create_impl(script_name: String, p1, p2, p3):
	var path := "res://commons/composition/%s.gd" % script_name
	if not _scripts.has(script_name):
		_scripts[script_name] = load(path)
	var inst = _scripts[script_name].new(p1, p2, p3)
	return inst
