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
## NO TILING. NO fmod. NO period.
##
## Instead: the side length determines how many hooks fit.
## Each hook adapts its width to fill the side evenly.
## No two hooks need be identical — they stretch to fit.
##
## side_length: total length of this border side in cells
## pos: position along this side (0 to side_length)
## depth: distance from outer edge into the border
## b: band width (line thickness)
func _is_dark_cell_distributed(pos: float, depth: float, b: float, side_length: float) -> bool:
	var max_d: float = 4.0 * b
	var ideal_period: float = 4.0 * b

	# How many hooks fit along this side? ROUND to nearest integer.
	# This means each hook stretches or compresses slightly to fill exactly.
	var num_hooks: int = maxi(1, int(round(side_length / ideal_period)))
	var actual_period: float = side_length / float(num_hooks)

	# Where in the current hook are we? (NOT fmod — distributed evenly)
	var hook_index: int = clampi(int(pos / actual_period), 0, num_hooks - 1)
	var hook_start: float = hook_index * actual_period
	var p: float = pos - hook_start  # position within THIS hook

	# Scale the phase boundaries to this hook's actual width
	var q1: float = actual_period * 0.25  # was: b
	var q2: float = actual_period * 0.50  # was: 2b
	var q3: float = actual_period * 0.75  # was: 3b

	# Boundary: how deep does dark territory extend?
	var boundary: float = 0.0
	if p < q1:
		boundary = max_d
	elif p < q2:
		boundary = b
	elif p < q3:
		boundary = 3.0 * b
	else:
		boundary = b

	return depth < boundary


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

	var stone_verts := PackedVector3Array()  # ALL stones in one mesh
	var stone_colors := PackedColorArray()   # per-vertex color
	var grout_verts := PackedVector3Array()
	var walk_verts := PackedVector3Array()
	var walk_colors := PackedColorArray()

	# ── Random walk over ALL tiles ──
	# Proves we can touch every stone independently
	var walk_visited := {}
	var walk_x: int = gw / 2
	var walk_y: int = gh / 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _step in 800:
		walk_visited[walk_x * 10000 + walk_y] = true
		# Random direction: 0=right, 1=down, 2=left, 3=up
		var dir: int = rng.randi_range(0, 3)
		match dir:
			0: walk_x = mini(walk_x + 1, gw - 1)
			1: walk_y = mini(walk_y + 1, gh - 1)
			2: walk_x = maxi(walk_x - 1, 0)
			3: walk_y = maxi(walk_y - 1, 0)

	for ty in gh:
		for tx in gw:
			# ── MOSAIC STONE placement ──
			# Each stone is jittered in position and size.
			# CRUCIALLY: the pattern decision (dark/light) is made at the
			# JITTERED position, not the grid position. This means the
			# pattern boundary wobbles with the stones — like real mosaic
			# where the craftsman places each stone and THEN decides its color
			# based on where it actually landed.
			var hash_val: float = _hash_2d(tx, ty)
			var hash_val2: float = _hash_2d(tx + 73, ty + 31)
			var jx: float = (hash_val - 0.5) * cs * 0.5  # position jitter +-25%
			var jz: float = (hash_val2 - 0.5) * cs * 0.5
			var size_jitter: float = 0.7 + hash_val * 0.6  # size 70%-130%
			var tile_size: float = cs * size_jitter
			# Stone center in WORLD coordinates (jittered)
			var wx := tx * cs + jx
			var wz := ty * cs + jz
			# Use the JITTERED world position for the pattern decision
			# Convert back to grid-like coordinates for the rule
			var rule_tx: float = wx / cs
			var rule_ty: float = wz / cs

			# CONTINUOUS coordinates — no grid snapping
			var rx: float = rule_tx
			var ry: float = rule_ty
			var d_top: float = ry
			var d_bot: float = float(gh - 1) - ry
			var d_left: float = rx
			var d_right: float = float(gw - 1) - rx
			var min_dist: float = minf(minf(d_top, d_bot), minf(d_left, d_right))

			# Per-stone color: base color + unique jitter
			var color_jitter: float = (_hash_2d(tx + 137, ty + 211) - 0.5) * 0.08
			var dark_c := Color(color_dark.r + color_jitter, color_dark.g + color_jitter, color_dark.b + color_jitter * 0.5)
			var light_c := Color(color_light.r + color_jitter, color_light.g + color_jitter * 0.8, color_light.b + color_jitter * 0.6)

			# Outer solid dark band
			if min_dist < float(outer_band):
				var r := _add_colored_rect(stone_verts, stone_colors, wx, wz, tile_size, tile_size, dark_c)
				stone_verts = r[0]; stone_colors = r[1]
				continue

			# Interior field
			if min_dist >= float(total_border):
				var r := _add_colored_rect(stone_verts, stone_colors, wx, wz, tile_size, tile_size, dark_c)
				stone_verts = r[0]; stone_colors = r[1]
				continue

			# Meander zone — FLOAT depth, no integer snapping
			var depth: float = min_dist - float(outer_band)

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
			var d_h: float = minf(d_top, d_bot)
			var d_v: float = minf(d_left, d_right)
			if d_h < float(total_border) and d_v < float(total_border) and absf(d_h - d_v) < 0.5:
				in_corner = true

			var is_dark: bool
			var ob_f: float = float(outer_band)
			var sw_f: float = float(side_w)
			var sh_f: float = float(side_h)
			var bw_f: float = float(band_width)

			if in_corner:
				var depth_h: float = d_h - ob_f
				var depth_v: float = d_v - ob_f
				var pos_h: float
				var pos_v: float
				var len_h: float  # length of the horizontal side
				var len_v: float  # length of the vertical side

				if d_top <= d_bot:
					pos_h = rx - ob_f
					len_h = sw_f
				else:
					pos_h = float(gw - 1) - ob_f - rx
					len_h = sw_f

				if d_right <= d_left:
					pos_v = ry - ob_f
					len_v = sh_f
				else:
					pos_v = float(gh - 1) - ob_f - ry
					len_v = sh_f

				var dark_h := _is_dark_cell_distributed(pos_h, depth_h, bw_f, len_h)
				var dark_v := _is_dark_cell_distributed(pos_v, depth_v, bw_f, len_v)
				is_dark = dark_h or dark_v
			else:
				var pos_along: float = 0.0
				var side_len: float = sw_f  # default

				if d_top == min_dist:
					pos_along = rx - ob_f
					side_len = sw_f
				elif d_right == min_dist:
					pos_along = ry - ob_f
					side_len = sh_f
				elif d_bot == min_dist:
					pos_along = float(gw - 1) - ob_f - rx
					side_len = sw_f
				else:
					pos_along = float(gh - 1) - ob_f - ry
					side_len = sh_f

				is_dark = _is_dark_cell_distributed(pos_along, depth, bw_f, side_len)

			# Check if random walk visited this cell
			var walk_key: int = tx * 10000 + ty
			if walk_visited.has(walk_key):
				var walk_c := Color(MosaicPalette.TERRACOTTA.r + color_jitter, MosaicPalette.TERRACOTTA.g + color_jitter, MosaicPalette.TERRACOTTA.b + color_jitter * 0.5)
				var r := _add_colored_rect(walk_verts, walk_colors, wx, wz, tile_size, tile_size, walk_c)
				walk_verts = r[0]; walk_colors = r[1]
			elif is_dark:
				var r := _add_colored_rect(stone_verts, stone_colors, wx, wz, tile_size, tile_size, dark_c)
				stone_verts = r[0]; stone_colors = r[1]
			else:
				var r := _add_colored_rect(stone_verts, stone_colors, wx, wz, tile_size, tile_size, light_c)
				stone_verts = r[0]; stone_colors = r[1]

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
			var dot_jitter: float = (_hash_2d(dx + 200, dz + 300) - 0.5) * 0.06
			var dot_c := Color(color_light.r + dot_jitter, color_light.g + dot_jitter, color_light.b + dot_jitter)
			var r := _add_colored_rect(stone_verts, stone_colors, px_x * cs, px_z * cs, cs, cs, dot_c)
			stone_verts = r[0]; stone_colors = r[1]

	# Grout lines
	if grout_width_fraction > 0.001:
		var grout_w := cs * grout_width_fraction * 10.0
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			grout_verts = _add_rect(grout_verts, 0.0, gy * cs - half, fw, grout_w)
		for gx in range(0, gw + 1):
			grout_verts = _add_rect(grout_verts, gx * cs - half, 0.0, grout_w, fh)

	# Y offsets for z-fighting prevention
	for i in stone_verts.size():
		stone_verts[i].y = 0.0
	for i in walk_verts.size():
		walk_verts[i].y = 0.003
	for i in grout_verts.size():
		grout_verts[i].y = -0.001

	# Build ArrayMesh — ONE surface with vertex colors for per-stone variation
	var arr_mesh := ArrayMesh.new()

	# Stone surface: all stones in one mesh with per-vertex color
	if stone_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = stone_verts
		arrays[Mesh.ARRAY_COLOR] = stone_colors
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		# Material that reads vertex colors
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.85
		arr_mesh.surface_set_material(0, mat)

	# Walk trail surface
	if walk_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = walk_verts
		arrays[Mesh.ARRAY_COLOR] = walk_colors
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.75
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, mat)

	# Grout surface (uniform color, no per-stone variation needed)
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

	print("[FreeMeanderFloor] Built %dx%d grid, band=%d, border=%d (%d stone, %d walk, %d grout tris)" % [
		gw, gh, band_width, border_depth,
		stone_verts.size() / 3, walk_verts.size() / 3, grout_verts.size() / 3,
	])


func _add_rect(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z + h))
	return verts


## Add a rect with per-stone color. Each stone gets 6 vertices (2 tris)
## all sharing the same color — but different stones get different colors.
func _add_colored_rect(verts: PackedVector3Array, colors: PackedColorArray,
		x: float, z: float, w: float, h: float, color: Color) -> Array:
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z))
	verts.append(Vector3(x + w, 0, z + h))
	verts.append(Vector3(x, 0, z + h))
	for _i in 6:
		colors.append(color)
	return [verts, colors]


func _hash_2d(x: int, y: int) -> float:
	var n := x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7FFFFFFF) / float(0x7FFFFFFF)
