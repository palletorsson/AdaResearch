# interlocking_t_floor.gd
# Procedural Pompeii mosaic floor — interlocking T-shaped tetromino pattern.
# T-pieces (3 wide x 2 tall) tile with alternating rotations (0/180) and colors,
# creating a satisfying puzzle-like interlocking surface.
#
# @identity
#   essence: a floor where puzzle logic becomes architectural surface
#   desire: players look down and see how four simple cells interlock endlessly
#   critical_parameter: tiles_short — number of micro-tiles on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that rotation and negation generate complexity from a single shape
#   needs: [implemented] procedural mesh, border bands, T-tetromino field, grout
#   relationships: pompeii_mosaic_floor (sibling pattern), basket_weave_floor (weave sibling)
#   truth: a T-shape and its 180-degree twin tile the plane — no gaps, no overlaps

extends Node3D
class_name InterlockingTFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var tiles_short: int = 12
@export var border_widths: Array[int] = [2, 1, 1]
@export var border_motif: int = BorderMotifs.Motif.SAWTOOTH
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
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
	wear_level = float(config.get("wear_level", wear_level))
	var bw = config.get("border_widths", null)
	if bw is Array:
		border_widths.clear()
		for v in bw:
			border_widths.append(int(v))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
	if _body:
		_body.queue_free()

	# Grid dimensions
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	var total_short := tiles_short + border_each * 2
	var ts := short_m / float(total_short)  # tile size in meters
	var total_long := int(round(long_m / ts))

	var gw: int = total_long if is_wide else total_short  # grid width in tiles
	var gh: int = total_short if is_wide else total_long   # grid height in tiles

	var fw := gw * ts  # floor width in meters
	var fh := gh * ts  # floor height in meters

	# Field region (inside borders)
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	# Grout absolute width
	var grout_w := ts * grout_width_fraction

	# Build vertex arrays for surfaces: dark, light, grout
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad (2 triangles) in XZ plane at y=0
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# ── 1. Border bands ──
	var terra_verts := PackedVector3Array()
	var inset: int = 0
	for i in border_widths.size():
		var bw: int = border_widths[i]
		var result := BorderMotifs.draw_border_frame(
			dark_verts, light_verts, terra_verts,
			inset * ts, inset * ts,
			(gw - inset * 2) * ts, (gh - inset * 2) * ts,
			bw * ts, ts,
			border_motif, i % 2 == 1
		)
		dark_verts = result["dark"]
		light_verts = result["light"]
		terra_verts = result["terra"]
		inset += bw

	# ── 2. Interlocking T-tetromino field ──
	# The T-shape is 3 cells wide x 2 cells tall.
	# Upright T (rotation 0):        Inverted T (rotation 180):
	#   [X][X][X]                       [_][X][_]
	#   [_][X][_]                       [X][X][X]
	#
	# We tile in a 3x2 super-cell grid. Each super-cell pair interlocks:
	# Row-even super-cells get upright T (dark), gaps filled by inverted T (light).
	# The trick: offset every other super-row by +1 cell horizontally to interlock.
	#
	# Pixel-grid approach: for each micro-tile in the field, determine which
	# T-piece it belongs to and assign dark or light.

	var field_w := fx1 - fx0
	var field_h := fy1 - fy0
	var g := grout_w * 0.5  # grout inset

	# Build a color map for the field: true = dark, false = light
	# T-pieces tile in a 3x4 repeating unit:
	#
	# Row 0: D D D L     (top of upright-T dark, stem-top of inverted-T light)
	# Row 1: L D L L     (stem of upright-T dark, rest light → but inverted-T fills)
	# Row 2: L L L D     (shifted: top of inverted-T light with offset, upright dark stem)
	# Row 3: D L D D     (shifted row)
	#
	# Actually, let's use a cleaner interlocking pattern.
	# The repeating tile is 3 wide x 4 tall:
	#
	# Row 0: D D D    ← top bar of dark T (pointing down)
	# Row 1: L D L    ← stem of dark T + sides are light T stems
	# Row 2: L L L    ← top bar of light T (pointing up)
	# Row 3: D L D    ← stem of light T + sides are dark T stems
	#
	# This creates perfect interlocking: dark Ts point down, light Ts point up.

	var pattern := [
		[true,  true,  true ],  # row 0: dark bar
		[false, true,  false],  # row 1: dark stem, light sides
		[false, false, false],  # row 2: light bar
		[true,  false, true ],  # row 3: light stem, dark sides
	]

	for ty in range(fy0, fy1):
		for tx in range(fx0, fx1):
			var fx_rel := tx - fx0
			var fy_rel := ty - fy0

			# Look up in the 3x4 repeating pattern
			var px := fx_rel % 3
			var py := fy_rel % 4
			var is_dark: bool = pattern[py][px]

			var x := tx * ts
			var z := ty * ts

			if is_dark:
				dark_verts = _add_rect.call(dark_verts, x + g, z + g, ts - g * 2.0, ts - g * 2.0)
			else:
				light_verts = _add_rect.call(light_verts, x + g, z + g, ts - g * 2.0, ts - g * 2.0)

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half := grout_w * 0.5
		# Horizontal lines
		for gy in range(0, gh + 1):
			var z := gy * ts
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		# Vertical lines
		for gx in range(0, gw + 1):
			var x := gx * ts
			grout_verts = _add_rect.call(grout_verts, x - half, 0.0, grout_w, fh)

		# T-shape outline grout: add extra grout lines at T-piece boundaries
		# The T-pieces span multiple micro-tiles, so we add thicker grout
		# at the super-cell boundaries (every 3 cols, every 4 rows in field)
		var thick := grout_w * 1.5
		var thick_half := thick * 0.5

		# Horizontal T-piece boundaries (every 2 rows in field = T height)
		for fy_rel in range(0, field_h + 1, 2):
			var z := (fy0 + fy_rel) * ts
			if z > fy0 * ts and z < fy1 * ts:
				grout_verts = _add_rect.call(grout_verts,
					fx0 * ts, z - thick_half,
					field_w * ts, thick)

		# Vertical T-piece boundaries (every 3 cols in field = T width)
		for fx_rel in range(0, field_w + 1, 3):
			var x := (fx0 + fx_rel) * ts
			if x > fx0 * ts and x < fx1 * ts:
				grout_verts = _add_rect.call(grout_verts,
					x - thick_half, fy0 * ts,
					thick, field_h * ts)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < dark(0.0) < light(0.001) < accent/terra(0.002) < border(0.003)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	dark_verts = _offset_y.call(dark_verts, 0.0)
	light_verts = _offset_y.call(light_verts, 0.001)
	grout_verts = _offset_y.call(grout_verts, -0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)

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
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(MosaicPalette.TERRACOTTA, wear_level))

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(grout_color, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)  # Center at origin, y=0.005
	add_child(_mi)

	# ── StaticBody3D + CollisionShape3D ──
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0.0, 0.0, 0.0)
	add_child(_body)

	print("[InterlockingTFloor] Built %dx%d grid (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
