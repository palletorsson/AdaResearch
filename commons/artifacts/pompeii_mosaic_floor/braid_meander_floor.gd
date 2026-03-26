# braid_meander_floor.gd
# Greek key meander generated TOP-DOWN from braid topology.
#
# THE INSIGHT: The meander is a BRAID projected onto a 2D surface.
# Two strands (A and B) run along the border, crossing at regular intervals.
# Between crossings each strand occupies a "lane" (outer half or inner half).
# At each crossing point the strands swap lanes — the swap creates the "hook."
#
# ALGORITHM:
#   1. Define the braid abstractly: two strands, N crossings per border side
#   2. At each crossing, strand in OUTER lane spirals inward (the key hook)
#      while strand in INNER lane spirals outward (the counter-hook)
#   3. Project both strand paths onto a 2D cell grid
#   4. Flood-fill to determine territories: cells enclosed by strand A = dark,
#      cells enclosed by strand B = light
#   5. The boundary between territories IS the meander line
#
# The braid has a crossing number: how many times the strands swap per period.
# Classic Greek key = crossing number 1 (one swap per key unit).
# Higher crossing numbers produce double/triple meanders.
#
# @identity
#   essence: the Greek key derived from first principles — braid topology projected onto tiles
#   desire: players see that the meander encodes a mathematical braid
#   critical_parameter: band_width (b) — controls strand thickness; crossing_depth = 4*b
#   triggers: instantiation or apply_grid_config
#   emerges: understanding that ancient decorative patterns encode topological invariants
#   needs: [implemented] braid-to-tile projection, ArrayMesh, MosaicPalette
#   relationships: double_snake_meander (dual-walk approach), exact_meander_floor (bitmap approach)
#   truth: the meander is a braid with crossing number 1

extends Node3D
class_name BraidMeanderFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var band_width: int = 3          ## Strand thickness in cells
@export var grid_cells: int = 100        ## Cells along short axis
@export var dot_spacing: int = 4         ## White dot spacing in dark field
@export var crossing_number: int = 1     ## Braid crossings per key unit (1=classic)
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.02
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	band_width = int(config.get("band_width", band_width))
	grid_cells = int(config.get("grid_cells", grid_cells))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	crossing_number = int(config.get("crossing_number", crossing_number))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	var b := band_width
	# Border depth = 4*b (fits one full braid crossing cycle)
	# Period = 4*b (one key unit width = one braid period)
	var border_depth := 4 * b
	var period := 4 * b
	var d := border_depth

	var aspect := floor_size.x / floor_size.y
	var gh := grid_cells
	var gw := int(round(gh * aspect))
	if gw < d * 2 + period:
		gw = d * 2 + period
	if gh < d * 2 + period:
		gh = d * 2 + period

	var px_m := floor_size.y / float(gh)
	var fw := gw * px_m
	var fh := gh * px_m

	# ── Step 1: Build the braid tile ──
	# The braid has two strands. In one period (4b cells wide, 4b cells tall):
	#   - Strand A occupies a spiral territory
	#   - Strand B occupies the complement
	# The crossing topology determines the spiral shape.
	var tile := _braid_to_tile(d, b, crossing_number)

	# ── Step 2: Build the full pixel grid ──
	var grid := []
	for r in gh:
		var row := []
		row.resize(gw)
		row.fill(0)
		grid.append(row)

	# Tile each border edge
	_tile_bottom(grid, gw, gh, d, period, tile)
	_tile_top(grid, gw, gh, d, period, tile)
	_tile_left(grid, gw, gh, d, period, tile)
	_tile_right(grid, gw, gh, d, period, tile)

	# Corners: fill with the braid corner pattern
	_fill_corner(grid, 0, 0, d, b, false, false)             # top-left
	_fill_corner(grid, 0, gw - d, d, b, false, true)         # top-right
	_fill_corner(grid, gh - d, 0, d, b, true, false)         # bottom-left
	_fill_corner(grid, gh - d, gw - d, d, b, true, true)     # bottom-right

	# ── Step 3: Render as mesh ──
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Border cells
	for r in gh:
		for c in gw:
			var in_border := (r < d or r >= gh - d or c < d or c >= gw - d)
			if not in_border:
				continue
			var wx := c * px_m
			var wz := r * px_m
			if grid[r][c] == 2:
				light_verts = _add_rect(light_verts, wx, wz, px_m, px_m)
			else:
				dark_verts = _add_rect(dark_verts, wx, wz, px_m, px_m)

	# Dark interior field
	var fx0 := d
	var fy0 := d
	var fx1 := gw - d
	var fy1 := gh - d
	for r in range(fy0, fy1):
		for c in range(fx0, fx1):
			dark_verts = _add_rect(dark_verts, c * px_m, r * px_m, px_m, px_m)

	# Scattered white dots in the dark field
	var field_w := fx1 - fx0
	var field_h := fy1 - fy0
	var dots_x := int(field_w / dot_spacing)
	var dots_z := int(field_h / dot_spacing)
	var margin_x := (field_w - dots_x * dot_spacing) * 0.5
	var margin_z := (field_h - dots_z * dot_spacing) * 0.5
	for dz in range(dots_z):
		for dx in range(dots_x):
			var base_px := margin_x + (dx + 0.5) * dot_spacing
			var base_pz := margin_z + (dz + 0.5) * dot_spacing
			var jx := (_hash_2d(dx, dz) - 0.5) * 0.8
			var jz := (_hash_2d(dx + 97, dz + 53) - 0.5) * 0.8
			var px_x := clampf(fx0 + base_px + jx, fx0 + 0.5, fx1 - 1.5)
			var px_z := clampf(fy0 + base_pz + jz, fy0 + 0.5, fy1 - 1.5)
			light_verts = _add_rect(light_verts, px_x * px_m, px_z * px_m, px_m, px_m)

	# Grout lines
	if grout_width_fraction > 0.001:
		var grout_w := px_m * grout_width_fraction * 10.0
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			grout_verts = _add_rect(grout_verts, 0.0, gy * px_m - half, fw, grout_w)
		for gx in range(0, gw + 1):
			grout_verts = _add_rect(grout_verts, gx * px_m - half, 0.0, grout_w, fh)

	# Y offsets for layering
	for i in dark_verts.size():
		dark_verts[i].y = 0.0
	for i in light_verts.size():
		light_verts[i].y = 0.001
	for i in grout_verts.size():
		grout_verts[i].y = -0.001

	# Assemble ArrayMesh
	var arr_mesh := ArrayMesh.new()
	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1,
			MosaicPalette.create_material(color_dark, wear_level))
	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1,
			MosaicPalette.create_material(color_light, wear_level))
	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1,
			MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	add_child(_body)

	print("[BraidMeanderFloor] Built %dx%d grid, border=%d, band=%d, crossings=%d" % [
		gw, gh, d, b, crossing_number,
	])


# ──────────────────────────────────────────────────────────────────────────────
# BRAID-TO-TILE PROJECTION
# ──────────────────────────────────────────────────────────────────────────────
#
# The braid has two strands running along the border strip.
# At position 0, strand A is in the OUTER lane (rows 0..2b-1),
#                 strand B is in the INNER lane (rows 2b..4b-1).
#
# At each crossing point (every 4b/crossing_number cells along the strip),
# the strands swap lanes. The swap is realized as a spiral hook:
# the outer strand spirals inward while the inner strand spirals outward.
#
# For crossing_number=1 (classic Greek key), one crossing per period:
#
# The outer strand (A) must travel from the outer lane to the inner lane.
# It does this by:
#   1. Running horizontally along the outer edge (rows 0..b-1)
#   2. Turning down the right side (cols 2b..3b-1)
#   3. Running back along the inner edge (rows 2b..3b-1) — the HOOK
#   4. Continuing along the inner edge to the end of the period
#
# The inner strand (B) fills the complement — and its shape is automatically
# the mirror spiral (the counter-hook).
#
# The result: one period of the tile is a square (4b x 4b) where A's territory
# forms the classic angular spiral and B's territory is the complement spiral.

func _braid_to_tile(d: int, b: int, crossings: int) -> Array:
	var period := 4 * b

	# Start with all cells as strand B territory (value 2)
	var tile := []
	for r in d:
		var row := []
		row.resize(period)
		row.fill(2)
		tile.append(row)

	if crossings == 1:
		# ── Classic Greek key: one crossing per period ──
		#
		# Strand A starts in OUTER lane, crosses to INNER lane.
		# The crossing creates the characteristic hook shape.
		#
		# Braid diagram (reading left to right):
		#   Position:  [0..b-1]  [b..2b-1]  [2b..3b-1]  [3b..4b-1]
		#   Strand A:  OUTER     crossing    INNER       INNER
		#   Strand B:  INNER     crossing    OUTER       OUTER
		#
		# Projecting A's crossing onto the grid:
		#   A enters from left in outer lane (rows 0..b-1)
		#   A spirals inward: right along outer, down right wall,
		#                     left along inner, creating the hook
		#   A exits right in inner lane (rows 3b..4b-1)
		#
		# A's territory (the angular spiral):
		#   Left vertical bar: cols 0..b-1, ALL rows (the "stem")
		#   Outer horizontal:  rows 0..b-1, cols b..3b-1
		#   Right descender:   rows b..3b-1, cols 2b..3b-1
		#   Inner hook bar:    rows 2b..3b-1, cols 3b..4b-1

		# Left vertical bar — the continuous stem connecting periods
		for r in range(d):
			for c in range(b):
				tile[r][c] = 1

		# Outer horizontal run — strand A runs along outer edge
		for r in range(b):
			for c in range(b, 3 * b):
				tile[r][c] = 1

		# Right descender — strand A turns inward at the crossing point
		for r in range(b, 3 * b):
			for c in range(2 * b, 3 * b):
				tile[r][c] = 1

		# Inner hook bar — strand A continues along inner edge after crossing
		for r in range(2 * b, 3 * b):
			for c in range(3 * b, 4 * b):
				tile[r][c] = 1

	elif crossings == 2:
		# ── Double meander: two crossings per period ──
		# Strand A crosses to inner lane at 1/4 period, back to outer at 3/4.
		# This creates TWO hooks per unit — the double-return meander.
		# Each crossing uses half the depth (2b instead of 4b).

		# Left vertical bar
		for r in range(d):
			for c in range(b):
				tile[r][c] = 1

		# First crossing: outer to inner (first half of period)
		# Outer run
		for r in range(b):
			for c in range(b, 2 * b):
				tile[r][c] = 1

		# First descender (half depth)
		for r in range(b, 2 * b):
			for c in range(b, 2 * b):
				tile[r][c] = 1

		# Inner run first half
		for r in range(2 * b, 3 * b):
			for c in range(b, 3 * b):
				tile[r][c] = 1

		# Second crossing: inner back to outer (second half)
		# Second ascender
		for r in range(b, 2 * b):
			for c in range(2 * b, 3 * b):
				tile[r][c] = 1

		# Outer run second half
		for r in range(b):
			for c in range(2 * b, 3 * b):
				tile[r][c] = 1

		# Bottom continuation
		for r in range(3 * b, 4 * b):
			for c in range(b, 2 * b):
				tile[r][c] = 1

	else:
		# Fallback for higher crossing numbers: use classic pattern
		# (could be extended for triple/quadruple meanders)
		return _braid_to_tile(d, b, 1)

	return tile


# ──────────────────────────────────────────────────────────────────────────────
# BORDER TILING — project braid tile onto each edge
# ──────────────────────────────────────────────────────────────────────────────

func _tile_bottom(grid: Array, gw: int, gh: int, d: int, period: int, tile: Array) -> void:
	# Bottom border: outer edge = row gh-1 (bottom).
	# tile[0] (outer) -> grid[gh-1], tile[d-1] (inner) -> grid[gh-d]
	var c_start := d
	var c_end := gw - d
	for c_off in range(c_end - c_start):
		var tc := c_off % period
		var gc := c_start + c_off
		for r in range(d):
			var gr := gh - 1 - r
			grid[gr][gc] = tile[r][tc]


func _tile_top(grid: Array, gw: int, gh: int, d: int, period: int, tile: Array) -> void:
	# Top border: outer edge = row 0. Vertical mirror with A<->B swap.
	var c_start := d
	var c_end := gw - d
	for c_off in range(c_end - c_start):
		var tc := c_off % period
		var gc := c_start + c_off
		for r in range(d):
			var gr := r
			var src: int = tile[d - 1 - r][tc]
			grid[gr][gc] = 3 - src  # swap 1<->2


func _tile_left(grid: Array, gw: int, gh: int, d: int, period: int, tile: Array) -> void:
	# Left border: outer edge = col 0. Rotate tile 90 CW.
	var r_start := d
	var r_end := gh - d
	for r_off in range(r_end - r_start):
		var tc := r_off % period
		var gr := r_start + r_off
		for r in range(d):
			var gc := r
			grid[gr][gc] = tile[r][tc]


func _tile_right(grid: Array, gw: int, gh: int, d: int, period: int, tile: Array) -> void:
	# Right border: outer edge = col gw-1. Rotate + mirror.
	var r_start := d
	var r_end := gh - d
	for r_off in range(r_end - r_start):
		var tc := r_off % period
		var gr := r_end - 1 - r_off
		for r in range(d):
			var gc := gw - 1 - r
			var src: int = tile[r][tc]
			grid[gr][gc] = 3 - src  # swap 1<->2


# ──────────────────────────────────────────────────────────────────────────────
# CORNER FILLS — braid strands must turn 90 degrees at corners
# ──────────────────────────────────────────────────────────────────────────────
#
# At each corner, the braid from one edge must connect seamlessly to the braid
# on the adjacent edge. The outer strand wraps around the outside of the corner
# (an L-bend), and the inner strand wraps around the inside.
#
# Corner pattern (d x d, b=band_width):
#   Outer L-bend: rows 0..b-1 across + cols 0..b-1 down = strand A (dark)
#   Inner L-bend: connecting inner hooks from both edges = strand A (dark)
#   Gap between them: strand B (light)

func _fill_corner(grid: Array, r0: int, c0: int, d: int, b: int,
		flip_v: bool, flip_h: bool) -> void:
	# Build corner bitmap: d x d
	# Default orientation: top-left corner where top edge meets left edge.
	# Outer L: rows 0..b-1 (top bar) + cols 0..b-1 (left bar)
	# Inner L: connects the inner hooks — rows 2b..3b-1 x cols 2b..3b-1 block
	#          plus extensions toward each edge
	var corner := []
	for r in d:
		var row := []
		row.resize(d)
		row.fill(2)  # default = strand B (light)
		corner.append(row)

	# Outer L-bend (strand A): wraps the outside corner
	# Top bar: rows 0..b-1, all cols
	for r in range(b):
		for c in range(d):
			corner[r][c] = 1
	# Left bar: all rows, cols 0..b-1
	for r in range(b, d):
		for c in range(b):
			corner[r][c] = 1

	# Inner L-bend (strand A): connects the inner hooks from both edges
	# The hook from the top edge enters at rows 2b..3b-1 from the right
	# The hook from the left edge enters at cols 2b..3b-1 from the bottom
	# They meet at the inner corner block
	# Inner horizontal: rows 2b..3b-1, cols 2b..d-1
	for r in range(2 * b, 3 * b):
		for c in range(2 * b, d):
			corner[r][c] = 1
	# Inner vertical: rows 2b..d-1, cols 2b..3b-1
	for r in range(3 * b, d):
		for c in range(2 * b, 3 * b):
			corner[r][c] = 1

	# Apply flips and write to grid
	for r in range(d):
		for c in range(d):
			var sr := (d - 1 - r) if flip_v else r
			var sc := (d - 1 - c) if flip_h else c
			grid[r0 + r][c0 + c] = corner[sr][sc]


# ──────────────────────────────────────────────────────────────────────────────
# GEOMETRY HELPERS
# ──────────────────────────────────────────────────────────────────────────────

func _add_rect(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z + h))
	return verts


func _hash_2d(x: int, y: int) -> float:
	var n := x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7FFFFFFF) / float(0x7FFFFFFF)
