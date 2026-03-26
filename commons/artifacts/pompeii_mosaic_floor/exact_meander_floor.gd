# exact_meander_floor.gd
# Exact reproduction of a Pompeii meander floor from a photograph.
# A single continuous dark meander line on a light border band, with a dark
# field interior dotted with white tesserae. The meander is the classic
# Greek key pattern traced as ONE thick line winding back and forth.
#
# @identity
#   essence: a faithful pixel reproduction of a specific Pompeii meander floor
#   desire: players see the exact meander pattern from the original photograph
#   critical_parameter: the hardcoded bitmap — every cell is placed to match the source
#   triggers: instantiation or apply_grid_config
#   emerges: recognition that ancient craftsmen worked in discrete grids too
#   needs: [implemented] hardcoded bitmap, ArrayMesh, MosaicPalette
#   relationships: meander_threshold_floor (similar motif, different proportions)
#   truth: the meander is a space-filling curve disguised as decoration

extends Node3D
class_name ExactMeanderFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

# Grid: 84 wide x 66 tall. Border=12 cells each side.
# Line width L=3 cells. Gap between line runs G=3 cells.
# Key period = 2*(L+G) = 12 cells.
# Top/bottom run: 60 cells -> 5 key units.
# Left/right run: 42 cells -> 3.5 key units.
# This matches the photo proportions: ~3-4 keys per visible edge.
const GW := 84
const GH := 66
const BORDER := 12
const L := 3   # line width (dark meander line)
const G := 3   # gap width (light space between line runs)

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var dot_spacing: int = 4
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.02
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
#var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		_body = null

	var px_m := minf(floor_size.x / float(GW), floor_size.y / float(GH))
	var fw := GW * px_m
	var fh := GH * px_m

	var grid := _build_full_grid()

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	for r in GH:
		for c in GW:
			var in_field := (r >= BORDER and r < GH - BORDER and
							c >= BORDER and c < GW - BORDER)
			var wx := c * px_m
			var wz := r * px_m
			if in_field:
				dark_verts = _add_rect(dark_verts, wx, wz, px_m, px_m)
			elif grid[r][c] == 1:
				dark_verts = _add_rect(dark_verts, wx, wz, px_m, px_m)
			else:
				light_verts = _add_rect(light_verts, wx, wz, px_m, px_m)

	# Scattered white dots in the dark field
	var fx0 := BORDER
	var fy0 := BORDER
	var fx1 := GW - BORDER
	var fy1 := GH - BORDER
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

	# Grout
	if grout_width_fraction > 0.001:
		var grout_w := px_m * grout_width_fraction * 10.0
		var half := grout_w * 0.5
		for gy in range(0, GH + 1):
			grout_verts = _add_rect(grout_verts, 0.0, gy * px_m - half, fw, grout_w)
		for gx in range(0, GW + 1):
			grout_verts = _add_rect(grout_verts, gx * px_m - half, 0.0, grout_w, fh)

	for i in dark_verts.size():
		dark_verts[i].y = 0.0
	for i in light_verts.size():
		light_verts[i].y = 0.001
	for i in grout_verts.size():
		grout_verts[i].y = -0.001

	var arr_mesh := ArrayMesh.new()
	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_dark, wear_level))
	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_light, wear_level))
	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	#add_child(_body)

	print("[ExactMeanderFloor] Built %dx%d grid (%d dark, %d light, %d grout tris)" % [
		GW, GH, dark_verts.size() / 3, light_verts.size() / 3, grout_verts.size() / 3,
	])


## Build the full grid. 1=dark, 0=light. Border region only.
## The meander is ONE continuous thick line (width L=2) that traces the
## classic Greek key pattern around the border.
##
## The key tile is 8 cols x 10 rows (= BORDER height).
## Within the 10-row border depth, the line traces:
##
##   Outer run (rows 0-1): line runs horizontally along outer edge
##   Down-turn (rows 0-7): line drops vertically toward inner edge
##   Inner partial run (rows 6-7): line runs back horizontally (half period)
##   Up-turn (rows 2-7): line rises back toward outer edge
##   ...then connects to next outer run
##
## One period of the key (8 cols x 10 rows), D=dark line, .=light:
##
##   col: 0 1 2 3 4 5 6 7
##   r0:  D D D D D D . .    outer run + connector turns down
##   r1:  D D D D D D . .
##   r2:  . . . . D D . .    connector going down
##   r3:  . . . . D D . .
##   r4:  . . D D D D . .    inner stub turns up from bottom
##   r5:  . . D D . . . .    stub going up
##   r6:  . . D D . . . .
##   r7:  . . D D . . . .
##   r8:  . . D D D D D D    inner run connects to next connector
##   r9:  . . D D D D D D
##
## When tiled: the next tile starts at col+8, its outer run (r0-1, cols 0-5)
## continues from this tile's missing cols 6-7. The inner run (r8-9, cols 2-7)
## connects to the next tile's inner cols 0-1 (which are empty - that's the gap).
## This creates the continuous angular spiral meander.

func _build_full_grid() -> Array:
	var grid := []
	for r in GH:
		var row := []
		row.resize(GW)
		row.fill(0)
		grid.append(row)

	# One key tile period
	var P := 2 * (L + G)  # = 8

	# Classic Greek key tile: the line traces a continuous angular spiral.
	# At the tile boundary, the outer run of tile N connects to the vertical
	# drop that starts the next spiral in tile N+1.
	#
	# The trick: cols 6-7 have the vertical drop that connects the outer run
	# end to the inner run of the NEXT tile. Within one tile period:
	#
	# Path of the dark line (reading left to right, top to bottom):
	#   1. Horizontal outer run: rows 0-1, cols 0-5
	#   2. Vertical drop: rows 2-7, cols 4-5 (connecting outer toward inner)
	#   3. Horizontal hook: rows 4-5, cols 2-3 (inner stub going left)
	#   4. Vertical rise: rows 4-9, cols 2-3 (going up toward inner run)
	#   5. Horizontal inner run: rows 8-9, cols 2-7
	#
	# The vertical drop at cols 6-7 of previous tile IS cols 6-7 of the
	# previous tile, and the outer run at cols 0-5 of THIS tile starts
	# from where the previous drop ended. So the connection is:
	#   prev tile inner run (r8-9, c2-7) -> THIS tile vertical drop end
	#
	# Actually, let me use a tile where:
	# - The left vertical (cols 0-1) connects outer rail to inner run
	# - The right vertical (cols 4-5) is the hook connector
	# This way, tile boundaries naturally connect.

	# 12 wide x 12 tall tile with 3-cell lines, 3-cell gaps
	var key := [
		#  0  1  2  3  4  5  6  7  8  9  10 11
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],  # row 0: outer run (cols 0-8)
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],  # row 1: outer run
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],  # row 2: outer run
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0],  # row 3: left vert + right vert
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0],  # row 4: left vert + right vert
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0],  # row 5: left vert + right vert
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1],  # row 6: left vert + hook bar right
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1],  # row 7: left vert + hook bar
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1],  # row 8: left vert + hook bar
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # row 9: left vert only
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # row 10: left vert only
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # row 11: left vert only
	]

	# ── Top edge: rows 0..9, tile key left to right ──
	var h_start := BORDER  # skip corner zone
	var h_end := GW - BORDER
	var h_run := h_end - h_start
	var n_h := h_run / P

	for k in range(n_h + 1):
		for r in BORDER:
			for c in P:
				var gc := h_start + k * P + c
				if gc >= h_end:
					break
				if r < 10 and c < 8 and key[r][c] == 1:
					grid[r][gc] = 1

	# ── Bottom edge: rows GH-10..GH-1, vertically mirrored ──
	for k in range(n_h + 1):
		for r in BORDER:
			for c in P:
				var gc := h_start + k * P + c
				if gc >= h_end:
					break
				var gr := GH - 1 - r
				if r < 10 and c < 8 and key[r][c] == 1:
					grid[gr][gc] = 1

	# ── Left edge: cols 0..9, key rotated 90 CW ──
	# Rotation 90 CW: key(r,c) -> (c, BORDER-1-r)
	# So key row r, col c -> grid row (v_start + k*P + c), col (BORDER-1-r)
	var v_start := BORDER
	var v_end := GH - BORDER
	var v_run := v_end - v_start
	var n_v := v_run / P

	for k in range(n_v + 1):
		for r in BORDER:
			for c in P:
				var gr := v_start + k * P + c
				var gc := BORDER - 1 - r
				if gr >= v_end:
					break
				if r < 10 and c < 8 and gc >= 0 and key[r][c] == 1:
					grid[gr][gc] = 1

	# ── Right edge: cols GW-10..GW-1, rotated 90 CCW ──
	# Rotation 90 CCW: key(r,c) -> (P-1-c, r)
	# grid row (v_start + k*P + P-1-c), col (GW - BORDER + r)
	for k in range(n_v + 1):
		for r in BORDER:
			for c in P:
				var gr := v_start + k * P + (P - 1 - c)
				var gc := GW - BORDER + r
				if gr >= v_end:
					break
				if r < 10 and c < 8 and gc < GW and key[r][c] == 1:
					grid[gr][gc] = 1

	# ── Corners ──
	# Each corner is BORDER x BORDER (12x12).
	# The meander line bends 90 degrees at each corner.
	# Outer L: the outer run (3px) wraps around the corner
	# Inner L: the inner hook bar wraps around the corner
	_draw_corner_pattern(grid, 0, 0, false, false)
	_draw_corner_pattern(grid, 0, GW - BORDER, false, true)
	_draw_corner_pattern(grid, GH - BORDER, 0, true, false)
	_draw_corner_pattern(grid, GH - BORDER, GW - BORDER, true, true)

	return grid


## Draw a corner pattern at position (r0, c0).
## The corner is BORDER x BORDER. flip_v/flip_h mirror the pattern.
## The corner pattern (12x12, L=3, G=3):
##   Outer L-bend (3px wide) wrapping the outer edge
##   Inner L-bend (3px wide) connecting the inner hook bars
func _draw_corner_pattern(grid: Array, r0: int, c0: int, flip_v: bool, flip_h: bool) -> void:
	# 12x12 corner bitmap (1=dark, 0=light)
	# Outer run wraps: rows 0-2 across + cols 0-2 down
	# Inner hook wraps: rows 6-8 partial + cols 6-8 partial
	var corner := [
		#  0  1  2  3  4  5  6  7  8  9  10 11
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  # row 0: outer run across
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  # row 1: outer run
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  # row 2: outer run
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1],  # row 3: left+right verts
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1],  # row 4
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1],  # row 5
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1],  # row 6: inner L-bend
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1],  # row 7: inner L
		[1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1],  # row 8: inner L
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # row 9: left vert only
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # row 10
		[1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # row 11
	]
	for r in BORDER:
		for c in BORDER:
			var sr := (BORDER - 1 - r) if flip_v else r
			var sc := (BORDER - 1 - c) if flip_h else c
			if sr < 12 and sc < 12:
				grid[r0 + r][c0 + c] = corner[sr][sc]


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
