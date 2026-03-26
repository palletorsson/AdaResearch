# mirror_snake_meander.gd
# Greek key meander via mirrored self-avoiding crossing snakes.
#
# The approach: solve ONE quarter of the border (top-left), then:
#   1. Mirror X to complete the top side
#   2. Mirror Y to create the bottom side (snake B)
#   3. The crossings emerge automatically from the mirroring
#
# Implementation: for each cell in the border zone, compute two coordinates:
#   pos_along = position along the nearest edge (parallel to that edge)
#   depth     = distance from outer edge of meander zone (perpendicular)
#
# Then evaluate a 4-band rule in (pos_along % period, depth) space.
# The Greek key hook pattern emerges from four depth bands where
# bands 0/3 are mirrors and bands 1/2 are mirrors:
#
#   Band 0 (outermost): dark for first 3/4 of period  (wide bar)
#   Band 1:             dark for two pillars           (left + middle)
#   Band 2:             dark for left pillar + hook    (mirror of band 1)
#   Band 3 (innermost): dark for left pillar only      (mirror of band 0)
#
# The corner assignment uses diagonal half-planes so the meander
# turns cleanly at each corner with continuous pos_along wrapping clockwise.
#
# @identity
#   essence: the Greek key as mirrored self-avoiding snakes
#   desire: the definitive Pompeii meander — clean hooks, proper crossings
#   critical_parameter: band_width — controls hook depth and period
#   triggers: instantiation or apply_grid_config
#   emerges: two interlocking snakes from pure mirror symmetry
#   needs: [implemented] per-cell rule, ArrayMesh, MosaicPalette
#   relationships: free_meander_floor (same rule engine), exact_meander_floor (bitmap)
#   truth: mirror the quarter and the Greek key builds itself

extends Node3D
class_name MirrorSnakeMeander

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
#var _body: StaticBody3D


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


## The Greek key rule: given position along border and depth, is this cell dark?
##
## p = position along the border (will be taken mod period)
## d = depth from outer edge of meander zone (0 = outermost)
## b = band_width
##
## The 4-band mirror rule derived from the Pompeii Greek key:
##   Band 0 (d = 0..b-1):    dark for p in [0, 3b)   (wide outer bar)
##   Band 1 (d = b..2b-1):   dark for p in [0, b) and [2b, 3b)   (two vertical pillars)
##   Band 2 (d = 2b..3b-1):  dark for p in [0, b) and [2b, 4b)   (left pillar + hook bar)
##   Band 3 (d = 3b..4b-1):  dark for p in [0, b)   (just left pillar)
##
## Bands 0 and 3 are mirrors. Bands 1 and 2 are mirrors.
## When tiled: the right end of one period's outer bar (band 0) connects
## to the left pillar of the next period, creating the continuous meander.
func _is_dark_cell(p_raw: int, d: int, b: int) -> bool:
	var period := 4 * b
	var p := p_raw % period
	if p < 0:
		p += period

	var band := d / b
	if band > 3:
		band = 3

	if band == 0:
		# Outer bar: dark for first 3/4 of period
		return p < 3 * b
	elif band == 1:
		# Two vertical pillars
		return p < b or (p >= 2 * b and p < 3 * b)
	elif band == 2:
		# Left pillar + hook bar extending right
		return p < b or p >= 2 * b
	else:
		# Just the left pillar (vertical connector to next period's outer bar)
		return p < b


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		#_body = null

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
			# as pos_along. For corners (equidistant from two edges), the
			# meander must turn. We handle this by checking which edge
			# gives min_dist and using the coordinate along that edge.
			#
			# For TOP edge: depth = d_top - ob, pos_along = tx
			# For BOTTOM edge: depth = d_bot - ob, pos_along = gw - 1 - tx (reversed)
			# For LEFT edge: depth = d_left - ob, pos_along = gh - 1 - ty (reversed)
			# For RIGHT edge: depth = d_right - ob, pos_along = ty
			#
			# The pos_along values are arranged so that going clockwise:
			# Top(left to right) -> Right(top to bottom) -> Bottom(right to left) -> Left(bottom to top)
			# We add offsets to make the perimeter continuous.

			var pos_along: int = 0
			var side_w: int = gw - 2 * outer_band  # effective width at outermost meander ring
			var side_h: int = gh - 2 * outer_band  # effective height

			# Find which edge(s) match min_dist
			var on_top := (d_top == min_dist)
			var on_bot := (d_bot == min_dist)
			var on_left := (d_left == min_dist)
			var on_right := (d_right == min_dist)

			# Priority for corners: determine side by which diagonal half
			# In corners, two edges tie. We pick based on which creates
			# the cleanest 90-degree turn. For a clockwise meander:
			# Top-left corner: assign to top (horizontal wins)
			# Top-right corner: assign to right (vertical wins, continues from top)
			# Bottom-right corner: assign to bottom (horizontal wins, continues from right)
			# Bottom-left corner: assign to left (vertical wins, continues from bottom)
			if on_top and on_left:
				# Top-left: top side (so the meander starts from left)
				pos_along = tx - outer_band
			elif on_top and on_right:
				# Top-right: right side
				pos_along = side_w + (ty - outer_band)
			elif on_bot and on_right:
				# Bottom-right: bottom side
				pos_along = side_w + side_h + (gw - 1 - outer_band - tx)
			elif on_bot and on_left:
				# Bottom-left: left side
				pos_along = 2 * side_w + side_h + (gh - 1 - outer_band - ty)
			elif on_top:
				pos_along = tx - outer_band
			elif on_right:
				pos_along = side_w + (ty - outer_band)
			elif on_bot:
				pos_along = side_w + side_h + (gw - 1 - outer_band - tx)
			elif on_left:
				pos_along = 2 * side_w + side_h + (gh - 1 - outer_band - ty)

			var is_dark := _is_dark_cell(pos_along, depth, band_width)

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

	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	#_body.position = Vector3(0, 0.005, 0)
	#add_child(_body)

	print("[MirrorSnakeMeander] Built %dx%d grid, band=%d, border=%d (%d dark, %d light, %d grout tris)" % [
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
