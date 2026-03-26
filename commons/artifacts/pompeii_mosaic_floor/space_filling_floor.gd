# space_filling_floor.gd
# Procedural mosaic floor demonstrating the connection between ancient meanders
# and modern space-filling curves. Four modes show different answers to:
# HOW DO YOU FILL A BOUNDED AREA WITH A PATH?
#
# Mode 0: Greek key meander — bitmap-tiled classical squared spiral border
# Mode 1: Hilbert curve — recursive space-filling curve in the border zone
# Mode 2: Peano curve — recursive space-filling curve in the border zone
# Mode 3: Penrose-inspired — aperiodic 5-fold quasicrystal pattern
#
# @identity
#   essence: a floor that shows space-filling is an ancient idea with modern math
#   desire: players see the same question answered four ways across millennia
#   critical_parameter: mode — switches between meander, Hilbert, Peano, Penrose
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that filling a border with a path is the origin of algorithms
#   needs: [implemented] bitmap meander, turtle curves, Penrose quasicrystal
#   relationships: turtle_meander_floor (sibling — turtle approach), labyrinth_floor (cousin)
#   truth: the Greek key is the first space-filling curve

extends Node3D
class_name SpaceFillingFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

## 0 = Greek Key Meander, 1 = Hilbert Curve, 2 = Peano Curve, 3 = Penrose-ish
@export var mode: int = 0
@export var floor_size: Vector2 = Vector2(1.2, 1.2)
@export var grid_cells: int = 48
@export var border_depth: int = 8
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
@export_range(0.0, 1.0) var wear_level: float = 0.3
@export var dot_spacing: int = 4
@export var dot_size_fraction: float = 0.15

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	grid_cells = int(config.get("grid_cells", grid_cells))
	mode = int(config.get("mode", mode))
	border_depth = int(config.get("border_depth", border_depth))
	wear_level = float(config.get("wear_level", wear_level))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	dot_size_fraction = float(config.get("dot_size_fraction", dot_size_fraction))
	_build()


# ── Turtle Engine ─────────────────────────────────────────────────────────

class PathTurtle:
	var x: int = 0
	var y: int = 0
	var dir: int = 0  # 0=right, 1=down, 2=left, 3=up
	var trail: Array = []

	func reset(sx: int, sy: int, sdir: int = 0) -> void:
		x = sx; y = sy; dir = sdir
		trail = [Vector2i(x, y)]

	func forward(steps: int) -> void:
		for _i in steps:
			match dir:
				0: x += 1
				1: y += 1
				2: x -= 1
				3: y -= 1
			trail.append(Vector2i(x, y))

	func turn_right() -> void:
		dir = (dir + 1) % 4

	func turn_left() -> void:
		dir = (dir + 3) % 4

	func turn(angle: int) -> void:
		if angle > 0: turn_right()
		else: turn_left()

	func hilbert(level: int, angle: int) -> void:
		if level <= 0: return
		turn(angle)
		hilbert(level - 1, -angle)
		forward(1)
		turn(-angle)
		hilbert(level - 1, angle)
		forward(1)
		hilbert(level - 1, angle)
		turn(-angle)
		forward(1)
		hilbert(level - 1, -angle)
		turn(angle)

	func peano(level: int, angle: int) -> void:
		if level <= 0: return
		turn(angle)
		peano(level - 1, -angle)
		forward(1)
		peano(level - 1, angle)
		forward(1)
		peano(level - 1, -angle)
		turn(-angle)
		forward(1)
		turn(-angle)
		peano(level - 1, angle)
		forward(1)
		peano(level - 1, -angle)
		forward(1)
		peano(level - 1, angle)
		turn(angle)


# ── Greek Key Meander (line-segment bitmap) ───────────────────────────────

## Generate one Greek key tile as a d-tall, (2*d)-wide boolean grid.
## The path enters at bottom-left and exits at bottom-right.
static func _make_key_bitmap(d: int) -> Array:
	var w: int = 2 * d
	var tile: Array = []
	for y in d:
		var row: Array = []
		row.resize(w)
		row.fill(false)
		tile.append(row)

	# Helper: draw a horizontal or vertical line on the tile
	var _hline := func(y: int, x0: int, x1: int) -> void:
		var lo: int = mini(x0, x1)
		var hi: int = maxi(x0, x1)
		for x in range(lo, hi + 1):
			if x >= 0 and x < w and y >= 0 and y < d:
				tile[y][x] = true

	var _vline := func(x: int, y0: int, y1: int) -> void:
		var lo: int = mini(y0, y1)
		var hi: int = maxi(y0, y1)
		for y in range(lo, hi + 1):
			if x >= 0 and x < w and y >= 0 and y < d:
				tile[y][x] = true

	# Trace the squared spiral via line segments.
	# Start at (0, d-1). The spiral goes:
	#   UP left edge -> RIGHT top -> DOWN right (partial) -> LEFT (partial)
	#   -> DOWN to bottom -> RIGHT to exit
	# Each inner ring shrinks by 2 in each dimension.
	var cx: int = 0
	var cy: int = d - 1
	var top: int = 0
	var bot: int = d - 1
	var lft: int = 0
	var rgt: int = w - 1

	# Seg 1: Up the left edge
	_vline.call(cx, cy, top)
	cy = top

	# Seg 2: Right along the top
	_hline.call(cy, cx, rgt)
	cx = rgt

	# Spiral inward
	while true:
		# Seg 3: Down the right edge, stop 2 from bottom
		var down_to: int = bot - 2
		if down_to <= top:
			# No room for more spiral — just go to bottom and exit
			_vline.call(cx, cy, bot)
			cy = bot
			break
		_vline.call(cx, cy, down_to)
		cy = down_to

		# Seg 4: Left, stop 2 from left edge
		var left_to: int = lft + 2
		if left_to > rgt:
			break
		_hline.call(cy, cx, left_to)
		cx = left_to

		# Seg 5: Up to inner top (top + 2)
		var up_to: int = top + 2
		if up_to >= cy:
			# Exit: go down and right
			_vline.call(cx, cy, bot)
			cy = bot
			break
		_vline.call(cx, cy, up_to)
		cy = up_to

		# Seg 6: Right to inner right (rgt - 2)
		var right_to: int = rgt - 2
		if right_to <= cx:
			break
		_hline.call(cy, cx, right_to)
		cx = right_to

		# Shrink bounds
		top += 2
		bot -= 2
		lft += 2
		rgt -= 2
		if bot - top < 2 or rgt - lft < 2:
			break

	# Exit: go down to bottom row, then right to exit
	if cy < d - 1:
		_vline.call(cx, cy, d - 1)
		cy = d - 1
	if cx < w - 1:
		_hline.call(cy, cx, w - 1)

	return tile


static func _paint_meander_border(grid: Array, gw: int, gh: int,
		zone_start: int, zone_end_x: int, zone_end_y: int, depth: int) -> void:
	if depth < 2:
		depth = 2
	var key_tile: Array = _make_key_bitmap(depth)
	var tile_w: int = 2 * depth
	var tile_h: int = depth

	# ── Bottom border ──
	var bx: int = zone_start
	while bx + tile_w <= zone_end_x:
		for ty in tile_h:
			for tx in tile_w:
				if key_tile[ty][tx]:
					var gx: int = bx + tx
					var gy: int = zone_end_y - tile_h + ty
					if gx >= 0 and gx < gw and gy >= 0 and gy < gh:
						grid[gy][gx] = true
		bx += tile_w
	# Fill remainder on bottom edge
	for rx in range(bx, zone_end_x):
		if rx < gw:
			grid[zone_end_y - 1][rx] = true

	# ── Top border (flip vertically) ──
	bx = zone_start
	while bx + tile_w <= zone_end_x:
		for ty in tile_h:
			for tx in tile_w:
				if key_tile[tile_h - 1 - ty][tx]:
					var gx: int = bx + tx
					var gy: int = zone_start + ty
					if gx >= 0 and gx < gw and gy >= 0 and gy < gh:
						grid[gy][gx] = true
		bx += tile_w
	for rx in range(bx, zone_end_x):
		if rx < gw:
			grid[zone_start][rx] = true

	# ── Left border (rotate 90 CCW) ──
	var by: int = zone_start
	while by + tile_w <= zone_end_y:
		for ty in tile_w:
			for tx in tile_h:
				# 90 CCW: new(tx, ty) reads from tile(tile_h-1-tx, ty)
				if key_tile[tile_h - 1 - tx][ty]:
					var gx: int = zone_start + tx
					var gy: int = by + ty
					if gx >= 0 and gx < gw and gy >= 0 and gy < gh:
						grid[gy][gx] = true
		by += tile_w
	for ry in range(by, zone_end_y):
		if ry < gh:
			grid[ry][zone_start] = true

	# ── Right border (rotate 90 CW) ──
	by = zone_start
	while by + tile_w <= zone_end_y:
		for ty in tile_w:
			for tx in tile_h:
				# 90 CW: new(tx, ty) reads from tile(tx, tile_w-1-ty)
				if key_tile[tx][tile_w - 1 - ty]:
					var gx: int = zone_end_x - tile_h + tx
					var gy: int = by + ty
					if gx >= 0 and gx < gw and gy >= 0 and gy < gh:
						grid[gy][gx] = true
		by += tile_w
	for ry in range(by, zone_end_y):
		if ry < gh:
			grid[ry][zone_end_x - 1] = true


# ── Hilbert border ────────────────────────────────────────────────────────

static func _paint_hilbert_border(grid: Array, gw: int, gh: int,
		zone_start: int, zone_end_x: int, zone_end_y: int, bd: int) -> void:
	var turtle := PathTurtle.new()
	var zone_w: int = zone_end_x - zone_start
	var zone_h: int = zone_end_y - zone_start

	var level: int = 1
	while (1 << (level + 1)) <= bd:
		level += 1
	var curve_size: int = 1 << level

	# Trace Hilbert segments along each side
	turtle.reset(0, 0, 0)
	@warning_ignore("integer_division")
	var segs_x: int = maxi(1, zone_w / curve_size)
	@warning_ignore("integer_division")
	var segs_y: int = maxi(1, zone_h / curve_size)

	for _seg in segs_x:
		turtle.hilbert(level, 1)
		turtle.forward(1)
	turtle.turn_right()
	for _seg in segs_y:
		turtle.hilbert(level, 1)
		turtle.forward(1)
	turtle.turn_right()
	for _seg in segs_x:
		turtle.hilbert(level, 1)
		turtle.forward(1)
	turtle.turn_right()
	for _seg in segs_y:
		turtle.hilbert(level, 1)
		turtle.forward(1)

	# Paint, clipping to the border ring
	for pt in turtle.trail:
		var px: int = zone_start + pt.x
		var py: int = zone_start + pt.y
		if px >= 0 and px < gw and py >= 0 and py < gh:
			if not (px >= zone_start + bd and px < zone_end_x - bd and \
					py >= zone_start + bd and py < zone_end_y - bd):
				grid[py][px] = true


# ── Peano border ──────────────────────────────────────────────────────────

static func _paint_peano_border(grid: Array, gw: int, gh: int,
		zone_start: int, zone_end_x: int, zone_end_y: int, bd: int) -> void:
	var turtle := PathTurtle.new()
	var zone_w: int = zone_end_x - zone_start
	var zone_h: int = zone_end_y - zone_start

	var level: int = 1
	while int(pow(3, level + 1)) <= bd:
		level += 1
	var curve_size: int = int(pow(3, level))

	turtle.reset(0, 0, 0)
	@warning_ignore("integer_division")
	var segs_x: int = maxi(1, zone_w / curve_size)
	@warning_ignore("integer_division")
	var segs_y: int = maxi(1, zone_h / curve_size)

	for _seg in segs_x:
		turtle.peano(level, 1)
		turtle.forward(1)
	turtle.turn_right()
	for _seg in segs_y:
		turtle.peano(level, 1)
		turtle.forward(1)
	turtle.turn_right()
	for _seg in segs_x:
		turtle.peano(level, 1)
		turtle.forward(1)
	turtle.turn_right()
	for _seg in segs_y:
		turtle.peano(level, 1)
		turtle.forward(1)

	for pt in turtle.trail:
		var px: int = zone_start + pt.x
		var py: int = zone_start + pt.y
		if px >= 0 and px < gw and py >= 0 and py < gh:
			if not (px >= zone_start + bd and px < zone_end_x - bd and \
					py >= zone_start + bd and py < zone_end_y - bd):
				grid[py][px] = true


# ── Penrose-inspired Aperiodic ────────────────────────────────────────────

static func _paint_penrose_border(grid: Array, _gw: int, _gh: int,
		zone_start: int, zone_end_x: int, zone_end_y: int, bd: int) -> void:
	var scale: float = float(bd) * 0.7
	if scale < 2.0:
		scale = 2.0
	var cx_f: float = (zone_start + zone_end_x) * 0.5
	var cy_f: float = (zone_start + zone_end_y) * 0.5

	var cos_a: Array = []
	var sin_a: Array = []
	for k in 5:
		var a: float = k * PI / 5.0
		cos_a.append(cos(a))
		sin_a.append(sin(a))

	for py in range(zone_start, zone_end_y):
		for px in range(zone_start, zone_end_x):
			if px >= zone_start + bd and px < zone_end_x - bd and \
			   py >= zone_start + bd and py < zone_end_y - bd:
				continue
			var fx: float = (px - cx_f) / scale
			var fy: float = (py - cy_f) / scale
			var val: float = 0.0
			for k in 5:
				val += cos(fx * cos_a[k] + fy * sin_a[k])
			if val > 2.0 or val < -3.5:
				grid[py][px] = true


# ── Build ─────────────────────────────────────────────────────────────────

func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	var outer_band: int = 1
	var light_band: int = 1
	var ts_depth: int = border_depth
	var inner_light: int = 1
	var inner_band: int = 1
	var border_each: int = outer_band + light_band + ts_depth + inner_light + inner_band

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := grid_cells + border_each * 2
	var ts := short_m / float(total_short)
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long

	var fw := gw * ts
	var fh := gh * ts

	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	var grout_w := ts * grout_width_fraction

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()
	var pattern_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Outer dark band ──
	for i in outer_band:
		for tx in range(i, gw - i):
			dark_verts = _add_rect.call(dark_verts, tx * ts, i * ts, ts, ts)
		for tx in range(i, gw - i):
			dark_verts = _add_rect.call(dark_verts, tx * ts, (gh - 1 - i) * ts, ts, ts)
		for ty in range(i + 1, gh - 1 - i):
			dark_verts = _add_rect.call(dark_verts, i * ts, ty * ts, ts, ts)
		for ty in range(i + 1, gh - 1 - i):
			dark_verts = _add_rect.call(dark_verts, (gw - 1 - i) * ts, ty * ts, ts, ts)

	# ── 2. Light gap (outer) ──
	var gap1 := outer_band
	for tx in range(gap1, gw - gap1):
		light_verts = _add_rect.call(light_verts, tx * ts, gap1 * ts, ts, ts)
	for tx in range(gap1, gw - gap1):
		light_verts = _add_rect.call(light_verts, tx * ts, (gh - 1 - gap1) * ts, ts, ts)
	for ty in range(gap1 + 1, gh - 1 - gap1):
		light_verts = _add_rect.call(light_verts, gap1 * ts, ty * ts, ts, ts)
	for ty in range(gap1 + 1, gh - 1 - gap1):
		light_verts = _add_rect.call(light_verts, (gw - 1 - gap1) * ts, ty * ts, ts, ts)

	# ── 3. Space-filling pattern zone (light background) ──
	var zone_start := outer_band + light_band
	var zone_end_x := gw - zone_start
	var zone_end_y := gh - zone_start

	for ty in range(zone_start, zone_end_y):
		for tx in range(zone_start, zone_end_x):
			if tx >= zone_start + ts_depth and tx < zone_end_x - ts_depth and \
			   ty >= zone_start + ts_depth and ty < zone_end_y - ts_depth:
				continue
			light_verts = _add_rect.call(light_verts, tx * ts, ty * ts, ts, ts)

	# Generate the space-filling pattern as a boolean grid
	var pattern_grid: Array = []
	for y in gh:
		var row: Array = []
		row.resize(gw)
		row.fill(false)
		pattern_grid.append(row)

	match mode:
		0:  # Greek Key Meander (bitmap tile)
			_paint_meander_border(pattern_grid, gw, gh, zone_start, zone_end_x, zone_end_y, ts_depth)
		1:  # Hilbert Curve
			_paint_hilbert_border(pattern_grid, gw, gh, zone_start, zone_end_x, zone_end_y, ts_depth)
		2:  # Peano Curve
			_paint_peano_border(pattern_grid, gw, gh, zone_start, zone_end_x, zone_end_y, ts_depth)
		3:  # Penrose-inspired
			_paint_penrose_border(pattern_grid, gw, gh, zone_start, zone_end_x, zone_end_y, ts_depth)

	# Paint the pattern onto the pattern layer (only within border ring)
	for ty in range(zone_start, zone_end_y):
		for tx in range(zone_start, zone_end_x):
			if tx >= zone_start + ts_depth and tx < zone_end_x - ts_depth and \
			   ty >= zone_start + ts_depth and ty < zone_end_y - ts_depth:
				continue
			if pattern_grid[ty][tx]:
				pattern_verts = _add_rect.call(pattern_verts, tx * ts, ty * ts, ts, ts)

	# ── 4. Light gap (inner) ──
	var gap2 := zone_start + ts_depth
	for tx in range(gap2, gw - gap2):
		light_verts = _add_rect.call(light_verts, tx * ts, gap2 * ts, ts, ts)
	for tx in range(gap2, gw - gap2):
		light_verts = _add_rect.call(light_verts, tx * ts, (gh - 1 - gap2) * ts, ts, ts)
	for ty in range(gap2 + 1, gh - 1 - gap2):
		light_verts = _add_rect.call(light_verts, gap2 * ts, ty * ts, ts, ts)
	for ty in range(gap2 + 1, gh - 1 - gap2):
		light_verts = _add_rect.call(light_verts, (gw - 1 - gap2) * ts, ty * ts, ts, ts)

	# ── 5. Inner dark band ──
	var inner_start := gap2 + inner_light
	for i in inner_band:
		var ii := inner_start + i
		for tx in range(ii, gw - ii):
			dark_verts = _add_rect.call(dark_verts, tx * ts, ii * ts, ts, ts)
		for tx in range(ii, gw - ii):
			dark_verts = _add_rect.call(dark_verts, tx * ts, (gh - 1 - ii) * ts, ts, ts)
		for ty in range(ii + 1, gh - 1 - ii):
			dark_verts = _add_rect.call(dark_verts, ii * ts, ty * ts, ts, ts)
		for ty in range(ii + 1, gh - 1 - ii):
			dark_verts = _add_rect.call(dark_verts, (gw - 1 - ii) * ts, ty * ts, ts, ts)

	# ── 6. Interior: dark field with polka dots ──
	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			dark_verts = _add_rect.call(dark_verts, tx * ts, ty * ts, ts, ts)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var field_w := fx1 - fx0
	var field_h := fy1 - fy0
	if dot_spacing > 0 and field_w > 0 and field_h > 0:
		@warning_ignore("integer_division")
		var dot_cols := field_w / dot_spacing
		@warning_ignore("integer_division")
		var dot_rows := field_h / dot_spacing
		var dot_size := ts * dot_size_fraction * dot_spacing
		for row in dot_rows:
			for col in dot_cols:
				@warning_ignore("integer_division")
				var dcx := fx0 + col * dot_spacing + dot_spacing / 2
				@warning_ignore("integer_division")
				var dcy := fy0 + row * dot_spacing + dot_spacing / 2
				var jx := rng.randf_range(-0.15, 0.15) * dot_spacing
				var jy := rng.randf_range(-0.15, 0.15) * dot_spacing
				var dx := (dcx + jx) * ts - dot_size * 0.5
				var dz := (dcy + jy) * ts - dot_size * 0.5
				light_verts = _add_rect.call(light_verts, dx, dz, dot_size, dot_size)

	# ── 7. Grout lines ──
	if grout_w > 0.0005:
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

	# ── Z-fighting fix ──
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	grout_verts = _offset_y.call(grout_verts, -0.001)
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	pattern_verts = _offset_y.call(pattern_verts, 0.002)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(0, MosaicPalette.create_material(color_dark, wear_level))

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_light, wear_level))

	if pattern_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = pattern_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_dark, wear_level))

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

	var mode_names: Array[String] = ["Greek Key Meander", "Hilbert Curve", "Peano Curve", "Penrose-ish"]
	var mode_name: String = mode_names[clampi(mode, 0, 3)]
	print("[SpaceFillingFloor] Built %dx%d, mode=%s, border_depth=%d (%d dark, %d light, %d pattern, %d grout tris)" % [
		gw, gh, mode_name, border_depth,
		dark_verts.size() / 3, light_verts.size() / 3,
		pattern_verts.size() / 3, grout_verts.size() / 3,
	])
