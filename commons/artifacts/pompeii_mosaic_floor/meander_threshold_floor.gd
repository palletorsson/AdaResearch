# meander_threshold_floor.gd
# Procedural Pompeii mosaic floor — Greek key meander border framing a dark
# field with scattered white tesserae.  Common Roman threshold pattern placed
# at doorways between rooms.
#
# @identity
#   essence: a floor that marks the liminal space of doorways with meander geometry
#   desire: players step across a threshold and recognise the oldest border ornament
#   critical_parameter: meander_width — pixel rows consumed by the meander band
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that a threshold is a frame, and a frame is a pattern
#   needs: [implemented] procedural mesh, meander pixel grid, polka dot field
#   relationships: swastika_meander_floor (sibling meander), polka_dot_field_floor (dot logic)
#   truth: the meander has guarded doorways for three thousand years

extends Node3D
class_name MeanderThresholdFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.8)  # wider than tall, threshold proportions
@export var meander_width: int = 10  # pixels for the meander band
@export var dot_spacing: int = 4     # pixels between dot centres in field
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.02
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
var _body: StaticBody3D

## The meander repeat tile is 10 pixels wide.  Band width = 3px.
const TW := 10
const B := 3


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	meander_width = int(config.get("meander_width", meander_width))
	dot_spacing = int(config.get("dot_spacing", dot_spacing))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	var border_px := meander_width
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var field_short_px := maxi(TW, int(short_m * 40) - border_px * 2)
	var total_short_px := field_short_px + border_px * 2
	var px_m := short_m / float(total_short_px)
	var total_long_px := int(round(long_m / px_m))

	var gw_px: int
	var gh_px: int
	if is_wide:
		gw_px = total_long_px
		gh_px = total_short_px
	else:
		gw_px = total_short_px
		gh_px = total_long_px

	var fw := gw_px * px_m
	var fh := gh_px * px_m

	# Build pixel grid with meander border
	var grid := _build_meander_grid(gw_px, gh_px, border_px)

	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Border from bitmap ──
	for r in gh_px:
		for c in gw_px:
			var in_border := (r < border_px or r >= gh_px - border_px or
							  c < border_px or c >= gw_px - border_px)
			if not in_border:
				continue
			var wx := c * px_m
			var wz := r * px_m
			if grid[r][c] == 1:
				dark_verts = _add_rect.call(dark_verts, wx, wz, px_m, px_m)
			else:
				light_verts = _add_rect.call(light_verts, wx, wz, px_m, px_m)

	# ── 2. Dark field ──
	var fx0 := border_px
	var fy0 := border_px
	var fx1 := gw_px - border_px
	var fy1 := gh_px - border_px
	for r in range(fy0, fy1):
		for c in range(fx0, fx1):
			dark_verts = _add_rect.call(dark_verts, c * px_m, r * px_m, px_m, px_m)

	# ── 3. Scattered light dots ──
	var field_w_px := fx1 - fx0
	var field_h_px := fy1 - fy0
	var dots_x := int(field_w_px / dot_spacing)
	var dots_z := int(field_h_px / dot_spacing)
	var margin_x := (field_w_px - dots_x * dot_spacing) * 0.5
	var margin_z := (field_h_px - dots_z * dot_spacing) * 0.5
	for dz in range(dots_z):
		for dx in range(dots_x):
			var base_px := margin_x + (dx + 0.5) * dot_spacing
			var base_pz := margin_z + (dz + 0.5) * dot_spacing
			var jx := (_hash_2d(dx, dz) - 0.5) * 0.8
			var jz := (_hash_2d(dx + 97, dz + 53) - 0.5) * 0.8
			var px_x := clampf(fx0 + base_px + jx, fx0 + 0.5, fx1 - 1.5)
			var px_z := clampf(fy0 + base_pz + jz, fy0 + 0.5, fy1 - 1.5)
			var wx := px_x * px_m
			var wz := px_z * px_m
			light_verts.append(Vector3(wx, 0.0005, wz))
			light_verts.append(Vector3(wx + px_m, 0.0005, wz))
			light_verts.append(Vector3(wx + px_m, 0.0005, wz + px_m))
			light_verts.append(Vector3(wx, 0.0005, wz))
			light_verts.append(Vector3(wx + px_m, 0.0005, wz + px_m))
			light_verts.append(Vector3(wx, 0.0005, wz + px_m))

	# ── 4. Grout ──
	if grout_width_fraction > 0.001:
		var grout_w := px_m * grout_width_fraction * float(TW)
		var half := grout_w * 0.5
		for gy in range(0, gh_px + 1):
			grout_verts = _add_rect.call(grout_verts, 0.0, gy * px_m - half, fw, grout_w)
		for gx in range(0, gw_px + 1):
			grout_verts = _add_rect.call(grout_verts, gx * px_m - half, 0.0, grout_w, fh)

	# ── Build ArrayMesh ──
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

	print("[MeanderThresholdFloor] Built %dx%d px grid, %d dots (%d dark tris, %d light tris, %d grout tris)" % [
		gw_px, gh_px, dots_x * dots_z,
		dark_verts.size() / 3, light_verts.size() / 3, grout_verts.size() / 3,
	])


## Build pixel grid with Greek key meander in the border region.
## Approach: draw the meander as concentric rectangular tracks.
## The outermost and innermost rows of the border are solid dark rails.
## Between them, a repeating Greek key spiral pattern is drawn.
func _build_meander_grid(gw: int, gh: int, border: int) -> Array:
	var grid := []
	for r in gh:
		var row := []
		for c in gw:
			row.append(0)
		grid.append(row)

	# The border is `border` pixels wide on each side.
	# We draw:
	#   - Outer dark rail: 1 px at very outside
	#   - Inner dark rail: 1 px at border-1
	#   - Between them (8 px): the meander key pattern

	# Outer rail (1px)
	_fill_rect(grid, gw, gh, 0, 0, 1, gw)          # top
	_fill_rect(grid, gw, gh, gh - 1, 0, 1, gw)      # bottom
	_fill_rect(grid, gw, gh, 0, 0, gh, 1)            # left
	_fill_rect(grid, gw, gh, 0, gw - 1, gh, 1)       # right

	# Inner rail (1px)
	_fill_rect(grid, gw, gh, border - 1, 0, 1, gw)
	_fill_rect(grid, gw, gh, gh - border, 0, 1, gw)
	_fill_rect(grid, gw, gh, 0, border - 1, gh, 1)
	_fill_rect(grid, gw, gh, 0, gw - border, gh, 1)

	# The meander zone is rows 1..(border-2) and (gh-border+1)..(gh-2)
	# for top/bottom, and cols 1..(border-2) and (gw-border+1)..(gw-2)
	# for left/right.  That's 8 pixels of pattern space.

	# Greek key meander: repeating unit is 10 cols wide, 8 rows tall
	# (the 8 rows between the two rails).
	# Designed so that when tiled, it creates the classic angular spiral.
	#
	# Key unit (8 rows x 10 cols), D=dark, .=light:
	# Row 0: DDDDDDDDDD   <- connects to outer rail above
	# Row 1: DDDDDDDDDD
	# Row 2: DDD....DDD.   <- spiral gap
	# Row 3: DDD.DD.DDD.   <- inner spiral nub
	# Row 4: DDD.DD.....   <- inner nub, right opens
	# Row 5: DDD.DDDDDDD   <- bottom of spiral
	# Row 6: DDD........   <- space
	# Row 7: DDDDDDDDDD   <- connects to inner rail below

	var mh := border - 2  # meander zone height (between rails)
	if mh < 4:
		# Not enough room for meander; just fill solid
		_fill_rect(grid, gw, gh, 0, 0, border, gw)
		_fill_rect(grid, gw, gh, gh - border, 0, border, gw)
		_fill_rect(grid, gw, gh, 0, 0, gh, border)
		_fill_rect(grid, gw, gh, 0, gw - border, gh, border)
		return grid

	# Build the 8x10 key unit
	var key := _make_key_8x10()

	# ── Top edge meander ──
	var run_w := gw - 2  # between left/right outer rail cols
	var num_h := run_w / TW
	var off_x := 1  # start after outer rail column
	for k in num_h:
		for r in mini(mh, 8):
			for c in TW:
				var gr := 1 + r
				var gc := off_x + k * TW + c
				if gc < gw - 1 and key[r][c] == 1:
					grid[gr][gc] = 1

	# ── Bottom edge meander (mirrored vertically) ──
	for k in num_h:
		for r in mini(mh, 8):
			for c in TW:
				var gr := gh - 2 - r
				var gc := off_x + k * TW + c
				if gc < gw - 1 and key[r][c] == 1:
					grid[gr][gc] = 1

	# ── Left edge meander (rotated 90 CW) ──
	var run_h := gh - 2
	var num_v := run_h / TW
	var off_y := 1
	for k in num_v:
		for r in mini(mh, 8):
			for c in TW:
				# 90 CW: key(r,c) -> grid(off_y + k*TW + c, mh - r)
				var gr := off_y + k * TW + c
				var gc := mh - r  # mh=8, so gc goes from 8 down to 1
				if gr < gh - 1 and gc < gw and key[r][c] == 1:
					grid[gr][gc] = 1

	# ── Right edge meander (rotated 90 CCW) ──
	for k in num_v:
		for r in mini(mh, 8):
			for c in TW:
				# 90 CCW: key(r,c) -> grid(off_y + k*TW + TW-1-c, gw-1-mh+r)
				var gr := off_y + k * TW + (TW - 1 - c)
				var gc := gw - 1 - mh + r
				if gr < gh - 1 and gc >= 0 and gc < gw and key[r][c] == 1:
					grid[gr][gc] = 1

	# ── Corner fills: solid dark in the 4 corner squares ──
	_fill_rect(grid, gw, gh, 0, 0, border, border)                  # top-left
	_fill_rect(grid, gw, gh, 0, gw - border, border, border)        # top-right
	_fill_rect(grid, gw, gh, gh - border, 0, border, border)        # bottom-left
	_fill_rect(grid, gw, gh, gh - border, gw - border, border, border)  # bottom-right

	return grid


## Create the 8x10 Greek key meander unit.
## This sits between the outer and inner 1px rails.
## When tiled horizontally, produces the classic angular spiral / Greek key.
static func _make_key_8x10() -> Array:
	# 8 rows x 10 cols
	# The pattern: outer 2 rows connect to rail, inner shows spiral
	return [
		[1,1,1,1,1,1,1,1,1,1],  # row 0: second outer rail row
		[1,1,1,1,1,1,1,1,1,1],  # row 1: third outer rail row
		[1,1,1,0,0,0,0,1,1,1],  # row 2: pillars with void
		[1,1,1,0,1,1,0,1,1,1],  # row 3: inner spiral nub
		[1,1,1,0,1,1,0,0,0,0],  # row 4: nub extends, right opens
		[1,1,1,0,1,1,1,1,1,1],  # row 5: bottom of spiral
		[1,1,1,0,0,0,0,0,0,0],  # row 6: gap
		[1,1,1,1,1,1,1,1,1,1],  # row 7: pre-inner-rail row
	]


func _fill_rect(grid: Array, gw: int, gh: int, r0: int, c0: int, h: int, w: int) -> void:
	for r in range(maxi(0, r0), mini(r0 + h, gh)):
		for c in range(maxi(0, c0), mini(c0 + w, gw)):
			grid[r][c] = 1


func _hash_2d(x: int, y: int) -> float:
	var n := x * 374761393 + y * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7FFFFFFF) / float(0x7FFFFFFF)
