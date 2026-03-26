# free_meander_floor.gd
# Rule-based Greek key meander — no tiles, no turtle, no bitmap.
# Each cell decides its own color from a mathematical rule
# applied to its global position, exactly as a Roman mosaicist
# would place each stone independently.
#
# The approach: for each cell in the border zone, compute two coordinates:
#   pos_along = position along the nearest edge (the coordinate parallel to that edge)
#   depth = distance from outer edge of meander zone (perpendicular to that edge)
#
# Then evaluate a 2D rule in (pos_along % period, depth) space that
# produces the Greek key hook pattern. The key is four depth bands,
# each with a different dark/light split that creates the spiral hook.
#
# For corners: the cell is equidistant from two edges. We pick the edge
# that gives the most continuous pattern by using a consistent tie-breaking
# rule (horizontal edges win over vertical).
#
# @identity
#   essence: the Greek key as a per-cell mathematical rule, not a repeated tile
#   desire: players see the cleanest meander yet — because it IS the rule
#   critical_parameter: band_width — controls the hook depth and period
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that all Greek key patterns emerge from four band rules
#   needs: [implemented] per-cell rule evaluation, ArrayMesh, MosaicPalette
#   relationships: exact_meander_floor (bitmap approach), double_snake_meander (walk approach)
#   truth: Roman mosaicists thought in rules, not tiles

extends Node3D
class_name FreeMeanderFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var grid_cells: int = 160          ## cells along the long axis
@export var border_depth: int = 16         ## total border depth in cells (should be 4 * band_width)
@export var band_width: int = 4            ## width of each concentric ring
@export var outer_band: int = 1            ## solid dark frame outside the meander
@export var dot_spacing: int = 5           ## cells between interior polka dots
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
	grid_cells = int(config.get("grid_cells", grid_cells))
	border_depth = int(config.get("border_depth", border_depth))
	band_width = int(config.get("band_width", band_width))
	outer_band = int(config.get("outer_band", outer_band))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


## The Greek key as a BOUNDARY FUNCTION.
##
## Instead of 4 band rules, define a single boundary line that zigzags
## between top and bottom of the border strip. Each cell asks one question:
## "Am I above or below the boundary?" — that's it.
##
## The boundary is a stepped function of position along the border:
##
##   depth
##   ↑ b ┌───┐       ┌───┐
##   │   │   │       │   │
##   │ 0 ┘   └───────┘   └───
##   └─────────────────────────-> pos_along
##       0   b  2b  3b  4b
##
## Dark territory = cells where depth < boundary(pos)
## Light territory = cells where depth >= boundary(pos)
##
## The boundary function creates the Greek key hook:
## - At phase [0, b): boundary is HIGH (=border_depth) -> dark column going full depth
## - At phase [b, 2b): boundary is LOW (=b) -> only top band is dark
## - At phase [2b, 3b): boundary is HIGH again -> dark column
## - At phase [3b, 4b): boundary is LOW -> only top band
## But the HIGH columns alternate between connecting to top and bottom,
## creating the interlocking hook pattern.
func _is_dark_cell(p_raw: int, d: int, b: int) -> bool:
	var period := 4 * b
	var p := p_raw % period
	if p < 0:
		p += period

	var max_d: int = 4 * b  # total meander depth

	# The boundary zigzags: define how deep the dark territory extends
	# at each position along the border
	var boundary: int = 0

	if p < b:
		# Phase 0: dark goes full depth (left vertical bar of the key)
		boundary = max_d
	elif p < 2 * b:
		# Phase 1: dark only at the top (top horizontal bar)
		boundary = b
	elif p < 3 * b:
		# Phase 2: dark goes to depth 3b (inner hook going back down)
		boundary = 3 * b
	else:
		# Phase 3: dark only at the top (connecting to next key)
		boundary = b

	return d < boundary


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	# Grid dimensions
	var is_wide := floor_size.x >= floor_size.y
	var long_m := maxf(floor_size.x, floor_size.y)
	var short_m := minf(floor_size.x, floor_size.y)
	var cell_size := long_m / float(grid_cells)
	var gw: int = grid_cells if is_wide else int(round(short_m / cell_size))
	var gh: int = int(round(short_m / cell_size)) if is_wide else grid_cells
	var cs := cell_size
	var fw := gw * cs
	var fh := gh * cs

	var total_border: int = outer_band + border_depth

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	for ty in gh:
		for tx in gw:
			var wx := tx * cs
			var wz := ty * cs

			var d_top := ty
			var d_bot := gh - 1 - ty
			var d_left := tx
			var d_right := gw - 1 - tx
			var min_dist := mini(mini(d_top, d_bot), mini(d_left, d_right))

			# Outer solid dark band
			if min_dist < outer_band:
				dark_verts = _add_rect(dark_verts, wx, wz, cs, cs)
				continue

			# Interior field
			if min_dist >= total_border:
				dark_verts = _add_rect(dark_verts, wx, wz, cs, cs)
				continue

			# Meander zone
			var depth: int = min_dist - outer_band

			# Determine which edge is nearest and use its parallel coordinate
			# as pos_along. For corners (equidistant from two edges), we
			# evaluate the rule from BOTH adjacent sides and AND the results,
			# creating a natural L-bend where the two dark regions overlap.
			#
			# For TOP edge: depth = d_top - ob, pos_along = tx - ob
			# For RIGHT edge: depth = d_right - ob, pos_along = ty - ob
			# For BOTTOM edge: depth = d_bot - ob, pos_along = gw - 1 - ob - tx
			# For LEFT edge: depth = d_left - ob, pos_along = gh - 1 - ob - ty
			#
			# Perimeter offsets make it continuous clockwise:
			# Top -> Right -> Bottom -> Left

			var side_w: int = gw - 2 * outer_band
			var side_h: int = gh - 2 * outer_band

			# Check if cell is in a corner zone (equidistant from two edges)
			var in_corner := false
			var d_h := mini(d_top, d_bot)  # nearest horizontal edge distance
			var d_v := mini(d_left, d_right)  # nearest vertical edge distance
			if d_h < total_border and d_v < total_border and d_h == d_v:
				in_corner = true

			var is_dark: bool

			if in_corner:
				# Corner zone: AND the rules from both adjacent edges.
				# This creates the L-bend where meander turns the corner.
				var depth_h: int = d_h - outer_band
				var depth_v: int = d_v - outer_band
				var pos_h: int  # pos_along for the horizontal edge
				var pos_v: int  # pos_along for the vertical edge

				if d_top <= d_bot:
					pos_h = tx - outer_band
				else:
					pos_h = side_w + side_h + (gw - 1 - outer_band - tx)

				if d_right <= d_left:
					pos_v = side_w + (ty - outer_band)
				else:
					pos_v = 2 * side_w + side_h + (gh - 1 - outer_band - ty)

				var dark_h := _is_dark_cell(pos_h, depth_h, band_width)
				var dark_v := _is_dark_cell(pos_v, depth_v, band_width)
				is_dark = dark_h or dark_v
			else:
				# Straight edge: use nearest edge
				var pos_along: int = 0

				if d_top == min_dist:
					pos_along = tx - outer_band
				elif d_right == min_dist:
					pos_along = side_w + (ty - outer_band)
				elif d_bot == min_dist:
					pos_along = side_w + side_h + (gw - 1 - outer_band - tx)
				else:
					pos_along = 2 * side_w + side_h + (gh - 1 - outer_band - ty)

				is_dark = _is_dark_cell(pos_along, depth, band_width)

			if is_dark:
				dark_verts = _add_rect(dark_verts, wx, wz, cs, cs)
			else:
				light_verts = _add_rect(light_verts, wx, wz, cs, cs)

	# Interior polka dots
	var field_x0 := total_border
	var field_y0 := total_border
	var field_x1 := gw - total_border
	var field_y1 := gh - total_border
	var field_w := field_x1 - field_x0
	var field_h := field_y1 - field_y0
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
			var px_x := clampf(field_x0 + base_px + jx, field_x0 + 0.5, field_x1 - 1.5)
			var px_z := clampf(field_y0 + base_pz + jz, field_y0 + 0.5, field_y1 - 1.5)
			light_verts = _add_rect(light_verts, px_x * cs, px_z * cs, cs, cs)

	# Grout lines
	if grout_width_fraction > 0.001:
		var grout_w := cs * grout_width_fraction * 10.0
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			grout_verts = _add_rect(grout_verts, 0.0, gy * cs - half, fw, grout_w)
		for gx in range(0, gw + 1):
			grout_verts = _add_rect(grout_verts, gx * cs - half, 0.0, grout_w, fh)

	# Y offsets for z-fighting prevention
	for i in dark_verts.size():
		dark_verts[i].y = 0.0
	for i in light_verts.size():
		light_verts[i].y = 0.001
	for i in grout_verts.size():
		grout_verts[i].y = -0.001

	# Build ArrayMesh
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

	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	add_child(_body)

	print("[FreeMeanderFloor] Built %dx%d grid, band=%d, border=%d (%d dark, %d light, %d grout tris)" % [
		gw, gh, band_width, border_depth,
		dark_verts.size() / 3, light_verts.size() / 3, grout_verts.size() / 3,
	])


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
