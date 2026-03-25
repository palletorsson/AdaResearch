# dense_carpet_floor.gd
# Procedural Pompeii mosaic floor — dense carpet of small crosses on a dark field.
# Based on Pompeii floors that resemble woven textiles: a dark ground covered in
# hundreds of tiny light cross/plus shapes arranged in a dense, offset grid.
#
# @identity
#   essence: a floor that maps the Roman practice of tessellated textile imitation
#   desire: players look down and see a carpet woven from stone — dense, regular, hypnotic
#   critical_parameter: tiles_short — pixel density of the cross grid
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that repetition at small scale creates textile-like visual texture
#   needs: [implemented] procedural mesh, border bands, cross pixel grid
#   relationships: pompeii_mosaic_floor (sibling pattern), polka_dot_field_floor (simpler scatter)
#   truth: stone can weave a carpet if the pattern is dense enough

extends Node3D
class_name DenseCarpetFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.0, 0.75)
@export var tiles_short: int = 60       ## high count for dense carpet effect
@export var cross_size: int = 3         ## pixels per cross arm (3 = 3x3 cross in 4x4 cell)
@export var border_dark: int = 3        ## outer dark border width in tiles
@export var border_light: int = 2       ## light band width in tiles
@export var border_inner_dark: int = 1  ## inner dark band width in tiles
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terracotta: Color = MosaicPalette.TERRACOTTA
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
	tiles_short = int(config.get("tiles_short", tiles_short))
	cross_size = int(config.get("cross_size", cross_size))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
	if _body:
		_body.queue_free()

	# Grid dimensions — border widths in tiles
	var border_each: int = border_dark + border_light + border_inner_dark

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_each * 2
	var ts := short_m / float(total_short)  # tile size in meters
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long

	var fw := gw * ts
	var fh := gh * ts

	# Field region (inside all borders)
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	var grout_w := ts * grout_width_fraction

	# Vertex arrays for 4 surfaces: dark, light, terracotta, grout
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad in XZ plane at y=0
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Border: dark(3), light(2), dark(1) — simple frame ──
	var inset: int = 0
	# Outer dark band
	for _i in range(border_dark):
		_draw_border_ring(dark_verts, _add_rect, inset, gw, gh, ts)
		inset += 1
	# Light band
	for _i in range(border_light):
		_draw_border_ring(light_verts, _add_rect, inset, gw, gh, ts)
		inset += 1
	# Inner dark band
	for _i in range(border_inner_dark):
		_draw_border_ring(dark_verts, _add_rect, inset, gw, gh, ts)
		inset += 1

	# ── 2. Dense cross carpet field ──
	# Each cross is a 3x3 plus shape:
	#   . X .
	#   X X X
	#   . X .
	# Placed in a 4x4 repeating cell (cross + 1 dark spacer on each side).
	# Alternate rows offset by 2 tiles (half cell) for checkerboard density.

	var cell := cross_size + 1  # 4x4 cell (3x3 cross + 1px dark gap)
	var half_cell := cell / 2   # 2-tile offset for staggered rows

	# Pre-build the cross pattern lookup for the 4x4 cell
	# Center the 3x3 cross in the 4x4 cell (offset 0,0 — top-left aligned)
	# Cross pixels within the cell:
	#   row 0: . X . .
	#   row 1: X X X .
	#   row 2: . X . .
	#   row 3: . . . .

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var lx := tx - fx0  # local x in field
			var ly := ty - fy0  # local y in field

			# Determine which cell row this belongs to
			var cell_row := ly / cell
			# Stagger offset for odd rows
			var x_shift := half_cell if (cell_row % 2 == 1) else 0
			var shifted_lx := lx - x_shift

			# Position within the cell
			var px: int = shifted_lx % cell
			var py: int = ly % cell

			# Handle negative modulo for shifted tiles
			if px < 0:
				px += cell

			# Check if this pixel is part of the cross (3x3 plus in top-left of 4x4 cell)
			var is_cross := false
			if px < cross_size and py < cross_size:
				var center := cross_size / 2  # 1 for cross_size=3
				# Plus/cross shape: center row or center column
				if px == center or py == center:
					is_cross = true
				# But exclude the 4 corners of the 3x3 block
				if px != center and py != center:
					is_cross = false

			var x := tx * ts
			var z := ty * ts

			if is_cross:
				light_verts = _add_rect.call(light_verts, x, z, ts, ts)
			else:
				dark_verts = _add_rect.call(dark_verts, x, z, ts, ts)

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)
	grout_verts = _offset_y.call(grout_verts, -0.001)

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

	if terra_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = terra_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_terracotta, wear_level))

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

	# StaticBody3D with CollisionShape3D for floor collision
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	add_child(_body)

	var field_w := fx1 - fx0
	var field_h := fy1 - fy0
	var cell_count := cell
	var crosses_x := field_w / cell_count
	var crosses_y := field_h / cell_count
	print("[DenseCarpetFloor] Built %dx%d grid, ~%d crosses (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		crosses_x * crosses_y,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])


## Draw one ring of border tiles at the given inset level
func _draw_border_ring(verts: PackedVector3Array, add_fn: Callable, inset_val: int, grid_w: int, grid_h: int, tile_s: float) -> void:
	# Top row
	for tx in range(inset_val, grid_w - inset_val):
		add_fn.call(verts, tx * tile_s, inset_val * tile_s, tile_s, tile_s)
	# Bottom row
	for tx in range(inset_val, grid_w - inset_val):
		add_fn.call(verts, tx * tile_s, (grid_h - 1 - inset_val) * tile_s, tile_s, tile_s)
	# Left column (excluding corners)
	for ty in range(inset_val + 1, grid_h - 1 - inset_val):
		add_fn.call(verts, inset_val * tile_s, ty * tile_s, tile_s, tile_s)
	# Right column (excluding corners)
	for ty in range(inset_val + 1, grid_h - 1 - inset_val):
		add_fn.call(verts, (grid_w - 1 - inset_val) * tile_s, ty * tile_s, tile_s, tile_s)
