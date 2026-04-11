# herringbone_floor.gd
# Procedural Pompeii mosaic floor — herringbone / opus spicatum pattern.
# Rectangular 2:1 bricks laid at 45-degree angles in alternating zigzag rows.
# Adjacent bricks point in opposite directions creating the V/chevron pattern.
# Classic Roman and medieval floor technique.
#
# @identity
#   essence: a floor encoding the oldest structural bond pattern in Western masonry
#   desire: players look down and see bricks angled like ears of wheat (spica)
#   critical_parameter: tiles_short — number of herringbone units on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: the insight that alternating a single rotation produces global zigzag order
#   needs: [implemented] procedural mesh, border bands, herringbone field, grout
#   relationships: pompeii_mosaic_floor (sibling pattern), basket_weave_floor (cousin bond)
#   truth: the same brick rotated 90 degrees, row after row, becomes a chevron field

extends Node3D
class_name HerringboneFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.0, 0.75)
@export var tiles_short: int = 8
@export var border_widths: Array[int] = [2, 1, 1]
@export var border_motif: int = BorderMotifs.Motif.SAWTOOTH
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.06
@export_range(0.0, 1.0) var wear_level: float = 0.3

var _mi: MeshInstance3D
#var _body: StaticBody3D


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
	#if _body:
		#_body.queue_free()

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

	# Helper: add a quad from 4 explicit XZ points at y=0
	var _add_quad := func(verts: PackedVector3Array,
			p0x: float, p0z: float, p1x: float, p1z: float,
			p2x: float, p2z: float, p3x: float, p3z: float) -> PackedVector3Array:
		verts.append(Vector3(p0x, 0, p0z))
		verts.append(Vector3(p1x, 0, p1z))
		verts.append(Vector3(p2x, 0, p2z))
		verts.append(Vector3(p0x, 0, p0z))
		verts.append(Vector3(p2x, 0, p2z))
		verts.append(Vector3(p3x, 0, p3z))
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

	# ── 2. Herringbone field ──
	# True herringbone (opus spicatum): rectangular bricks at 45-degree angles.
	#
	# Layout on a sub-grid of half-cells (unit = ts/2 = "u"):
	# Each brick is 2u long x 1u wide (2:1 ratio).
	# The pattern unit cell is 2u x 2u. Within each unit cell:
	#   - Brick A: horizontal 2u x 1u at top    (occupies cols 0-1, row 0)
	#   - Brick B: vertical   1u x 2u at right  (occupies col 1, rows 0-1)
	# This creates the classic L-shaped interlock. However, for a diagonal
	# herringbone we rotate the entire sub-grid 45 degrees.
	#
	# Simpler direct approach: draw each brick as an axis-aligned rectangle on a
	# staggered sub-grid. The "herringbone" effect comes from alternating
	# horizontal (2:1 wide) and vertical (1:2 tall) bricks in a checkerboard.
	# This is the classic basket-weave variant. For TRUE herringbone at 45 degrees,
	# we shear the grid.
	#
	# TRUE 45-degree herringbone approach:
	# Use a diamond (45-deg rotated) coordinate system.
	# u = ts / 2 (half-cell = brick short side)
	# In diamond coords, each brick is 2u x u.
	# Diamond basis vectors: e1 = (u, u) and e2 = (-u, u) in world XZ.
	# Brick centers are placed at integer multiples of e1 and e2.

	var g := grout_w * 0.5

	# Fill field background with grout
	var field_x := fx0 * ts
	var field_z := fy0 * ts
	var field_w := (fx1 - fx0) * ts
	var field_h := (fy1 - fy0) * ts
	grout_verts = _add_rect.call(grout_verts, field_x, field_z, field_w, field_h)

	# Sub-cell unit
	var u := ts * 0.5

	# Diamond basis vectors (45-degree rotation)
	# e1 points down-right: (+u, +u)
	# e2 points down-left:  (-u, +u)
	# A brick aligned with e1 has corners offset by +-1*e1 (long) and +-0.5*e2 (short)
	# A brick aligned with e2 has corners offset by +-1*e2 (long) and +-0.5*e1 (short)

	# Grout inset along each basis direction
	var gi := g * 0.7071  # grout inset projected onto basis vector (g / sqrt(2) per component)

	# Field bounds
	var fx_min := fx0 * ts
	var fz_min := fy0 * ts
	var fx_max := fx1 * ts
	var fz_max := fy1 * ts
	var fcx := (fx_min + fx_max) * 0.5
	var fcz := (fz_min + fz_max) * 0.5

	# We need enough rows/cols in diamond coords to cover the field.
	# In diamond coords, one step in i moves (u, u) in world.
	# Range needed: from field corner to field corner.
	var diag_range := int(ceil((field_w + field_h) / u)) + 2

	for di in range(-diag_range, diag_range):
		for dj in range(-diag_range, diag_range):
			# Center of this cell in diamond coords (di, dj)
			# World position = origin + di * e1 + dj * e2
			var wx := fcx + float(di) * u - float(dj) * u
			var wz := fcz + float(di) * u + float(dj) * u

			# Skip if center is outside field (with margin)
			if wx < fx_min - ts or wx > fx_max + ts:
				continue
			if wz < fz_min - ts or wz > fz_max + ts:
				continue

			# Herringbone pattern: in the unit cell (2x2 in diamond coords),
			# alternate between e1-aligned and e2-aligned bricks.
			# Use checkerboard on (di + dj) to alternate orientation.
			var is_e1_aligned: bool = ((di + dj) % 2) == 0

			# Compute brick corners
			# For e1-aligned brick: long axis along e1, short axis along e2
			#   corners = center +- e1 (long) +- 0.5*e2 (short), with grout inset
			# For e2-aligned brick: long axis along e2, short axis along e1

			var p0x: float
			var p0z: float
			var p1x: float
			var p1z: float
			var p2x: float
			var p2z: float
			var p3x: float
			var p3z: float

			if is_e1_aligned:
				# Long axis along e1 = (u, u), short axis along e2 = (-u, u)
				# Half-long = (u - gi, u - gi), half-short = (-0.5u + gi, 0.5u - gi)
				var lx := u - gi  # long half in x
				var lz := u - gi  # long half in z
				var sx := (u * 0.5 - gi)  # short half magnitude in x
				var sz := (u * 0.5 - gi)  # short half magnitude in z
				# p0 = center - long - short  (top vertex)
				p0x = wx - lx + sx;  p0z = wz - lz - sz
				# p1 = center + long - short  (right vertex)
				p1x = wx + lx + sx;  p1z = wz + lz - sz
				# p2 = center + long + short  (bottom vertex)
				p2x = wx + lx - sx;  p2z = wz + lz + sz
				# p3 = center - long + short  (left vertex)
				p3x = wx - lx - sx;  p3z = wz - lz + sz
			else:
				# Long axis along e2 = (-u, u), short axis along e1 = (u, u)
				var lx := u - gi
				var lz := u - gi
				var sx := (u * 0.5 - gi)
				var sz := (u * 0.5 - gi)
				# p0 = center - long_e2 - short_e1
				p0x = wx + lx - sx;  p0z = wz - lz - sz
				# p1 = center - long_e2 + short_e1
				p1x = wx + lx + sx;  p1z = wz - lz + sz
				# p2 = center + long_e2 + short_e1
				p2x = wx - lx + sx;  p2z = wz + lz + sz
				# p3 = center + long_e2 - short_e1
				p3x = wx - lx - sx;  p3z = wz + lz - sz

			# Clip: skip bricks whose center is clearly outside the field
			if wx < fx_min - u * 0.5 or wx > fx_max + u * 0.5:
				continue
			if wz < fz_min - u * 0.5 or wz > fz_max + u * 0.5:
				continue

			# Alternate dark/light
			var use_dark: bool = (di % 2) == 0
			var target_verts: PackedVector3Array = dark_verts if use_dark else light_verts
			target_verts = _add_quad.call(target_verts, p0x, p0z, p1x, p1z, p2x, p2z, p3x, p3z)

			if use_dark:
				dark_verts = target_verts
			else:
				light_verts = target_verts

	# ── 3. Grout lines ──
	# Border grid grout (outer frame lines)
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
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	#col.shape = box
	#_body.add_child(col)
	#_body.position = Vector3(0.0, 0.0, 0.0)  # Centered since mesh is centered
	#add_child(_body)

	print("[HerringboneFloor] Built %dx%d grid (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
