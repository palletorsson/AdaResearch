# multi_zone_carpet_floor.gd
# Procedural Pompeii mosaic floor — multi-zone "carpet" composition.
# Nested rectangular bands of distinct motifs surround a central field,
# demonstrating the Roman carpet-composition principle seen in triclinium floors.
#
# @identity
#   essence: a floor that demonstrates how Roman mosaicists composed spatial hierarchy
#   desire: players look down and read nested borders as a lesson in compositional framing
#   critical_parameter: cells_short — controls resolution of the central checkerboard field
#   triggers: instantiation or apply_grid_config
#   emerges: understanding that carpet composition = nested constraint boundaries
#   needs: [implemented] procedural mesh, multi-zone bands, checkerboard field
#   relationships: pompeii_mosaic_floor (parent pattern), border_motifs (shared library)
#   truth: Pompeii's richest floors layer meander, sawtooth, scallop, and field into a single carpet

extends Node3D
class_name MultiZoneCarpetFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")
const BorderMotifs = preload("res://commons/artifacts/pompeii_mosaic_floor/border_motifs.gd")

@export var floor_size: Vector2 = Vector2(1.4, 1.0)
@export var cells_short: int = 6  ## checkerboard cells on short axis inside all bands
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var color_terra: Color = MosaicPalette.TERRACOTTA
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.03
@export_range(0.0, 1.0) var wear_level: float = 0.3

## Band widths (outside-in), in pixel units:
## 1. Dark band (2)
## 2. Sawtooth band (2)
## 3. Light band (1)
## 4. Scallop band (2)
## 5. Dark band (1)
## Total border = 8 per side
const BAND_WIDTHS := [2, 2, 1, 2, 1]

var _mi: MeshInstance3D
var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	cells_short = int(config.get("cells_short", cells_short))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	# Total border width per side (in pixel units)
	var border_each: int = 0
	for bw in BAND_WIDTHS:
		border_each += bw

	# Grid sizing
	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Field is cells_short * 2 pixels (checkerboard cells are 2px each)
	var field_short_px := cells_short * 2
	var total_short_px := field_short_px + border_each * 2
	var px_m := short_m / float(total_short_px)  # meters per pixel

	var total_long_px := int(round(long_m / px_m))
	var field_long_px := total_long_px - border_each * 2
	# Round field to even number for checkerboard
	field_long_px = (field_long_px / 2) * 2
	total_long_px = field_long_px + border_each * 2

	var gw_px: int  # total grid width in pixels
	var gh_px: int
	if is_wide:
		gw_px = total_long_px
		gh_px = total_short_px
	else:
		gw_px = total_short_px
		gh_px = total_long_px

	var fw := gw_px * px_m
	var fh := gh_px * px_m

	# Vertex buffers
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Helper: add a flat quad
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Helper: add a triangle
	var _add_tri := func(verts: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> PackedVector3Array:
		verts.append(a)
		verts.append(b)
		verts.append(c)
		return verts

	# ── Band 1: Dark solid band (2 px) ──
	var inset: int = 0
	var bw1: int = BAND_WIDTHS[0]
	var result := BorderMotifs.draw_border_frame(
		dark_verts, light_verts, terra_verts,
		inset * px_m, inset * px_m,
		(gw_px - inset * 2) * px_m, (gh_px - inset * 2) * px_m,
		bw1 * px_m, px_m,
		BorderMotifs.Motif.SOLID, false
	)
	dark_verts = result["dark"]
	light_verts = result["light"]
	terra_verts = result["terra"]
	inset += bw1

	# ── Band 2: Sawtooth/chevron band (2 px) ──
	var bw2: int = BAND_WIDTHS[1]
	result = BorderMotifs.draw_border_frame(
		dark_verts, light_verts, terra_verts,
		inset * px_m, inset * px_m,
		(gw_px - inset * 2) * px_m, (gh_px - inset * 2) * px_m,
		bw2 * px_m, px_m,
		BorderMotifs.Motif.SAWTOOTH, false
	)
	dark_verts = result["dark"]
	light_verts = result["light"]
	terra_verts = result["terra"]
	inset += bw2

	# ── Band 3: Light solid band (1 px) ──
	var bw3: int = BAND_WIDTHS[2]
	result = BorderMotifs.draw_border_frame(
		dark_verts, light_verts, terra_verts,
		inset * px_m, inset * px_m,
		(gw_px - inset * 2) * px_m, (gh_px - inset * 2) * px_m,
		bw3 * px_m, px_m,
		BorderMotifs.Motif.SOLID, true  # reverse_colors = true -> light band
	)
	dark_verts = result["dark"]
	light_verts = result["light"]
	terra_verts = result["terra"]
	inset += bw3

	# ── Band 4: Scallop/half-circle band (2 px) ──
	# We draw this as a custom band since BorderMotifs doesn't have SCALLOP.
	# Approximate semicircles with fan triangles alternating dark/light.
	var bw4: int = BAND_WIDTHS[3]
	var scallop_inset := inset
	_draw_scallop_frame(dark_verts, light_verts, terra_verts,
		scallop_inset * px_m, scallop_inset * px_m,
		(gw_px - scallop_inset * 2) * px_m, (gh_px - scallop_inset * 2) * px_m,
		bw4 * px_m, px_m, _add_tri)
	inset += bw4

	# ── Band 5: Dark solid band (1 px) ──
	var bw5: int = BAND_WIDTHS[4]
	result = BorderMotifs.draw_border_frame(
		dark_verts, light_verts, terra_verts,
		inset * px_m, inset * px_m,
		(gw_px - inset * 2) * px_m, (gh_px - inset * 2) * px_m,
		bw5 * px_m, px_m,
		BorderMotifs.Motif.SOLID, false
	)
	dark_verts = result["dark"]
	light_verts = result["light"]
	terra_verts = result["terra"]
	inset += bw5

	# ── Central field: checkerboard ──
	var fx0 := inset
	var fy0 := inset
	var fx1 := gw_px - inset
	var fy1 := gh_px - inset
	var check_size := 2  # each checkerboard cell is 2 pixels

	for py in range(fy0, fy1, check_size):
		for px in range(fx0, fx1, check_size):
			var cx := ((px - fx0) / check_size)
			var cy := ((py - fy0) / check_size)
			var is_dark_cell := ((cx + cy) % 2) == 0
			var wx := px * px_m
			var wz := py * px_m
			var cw := minf(check_size, fx1 - px) * px_m
			var ch := minf(check_size, fy1 - py) * px_m
			if is_dark_cell:
				dark_verts = _add_rect.call(dark_verts, wx, wz, cw, ch)
			else:
				light_verts = _add_rect.call(light_verts, wx, wz, cw, ch)

	# ── Grout lines ──
	if grout_width_fraction > 0.001:
		var grout_w := px_m * grout_width_fraction * 2.0
		var half := grout_w * 0.5
		# Horizontal lines
		for gy in range(0, gh_px + 1):
			var z := gy * px_m
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half, fw, grout_w)
		# Vertical lines
		for gx in range(0, gw_px + 1):
			var x := gx * px_m
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
	var surf_idx := 0

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(color_dark, wear_level))
		surf_idx += 1

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(color_light, wear_level))
		surf_idx += 1

	if terra_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = terra_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(color_terra, wear_level))
		surf_idx += 1

	if grout_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = grout_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(surf_idx, MosaicPalette.create_material(grout_color, wear_level))
		surf_idx += 1

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(-fw * 0.5, 0.005, -fh * 0.5)
	add_child(_mi)

	# ── StaticBody3D with box collision ──
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	add_child(_body)

	print("[MultiZoneCarpetFloor] Built %dx%d px grid (%d dark, %d light, %d terra, %d grout tris)" % [
		gw_px, gh_px,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
		grout_verts.size() / 3,
	])


## Draw scallop (half-circle) border frame — semicircles alternating dark/light.
## Each scallop spans one tile_size along the strip, radius = band_w / 2.
func _draw_scallop_frame(
	dark_v: PackedVector3Array,
	light_v: PackedVector3Array,
	_terra_v: PackedVector3Array,
	x0: float, z0: float,
	frame_w: float, frame_h: float,
	band_w: float, tile_size: float,
	add_tri: Callable
) -> void:
	var segments := 8  # arc segments per semicircle
	var scallop_w := tile_size * 2.0  # each scallop spans 2 tiles

	# Corners: solid dark
	dark_v = BorderMotifs._add_rect_verts(dark_v, x0, z0, band_w, band_w)
	dark_v = BorderMotifs._add_rect_verts(dark_v, x0 + frame_w - band_w, z0, band_w, band_w)
	dark_v = BorderMotifs._add_rect_verts(dark_v, x0, z0 + frame_h - band_w, band_w, band_w)
	dark_v = BorderMotifs._add_rect_verts(dark_v, x0 + frame_w - band_w, z0 + frame_h - band_w, band_w, band_w)

	var h_len := frame_w - band_w * 2
	var v_len := frame_h - band_w * 2

	# Top edge scallops (semicircles hanging down from top)
	_draw_scallop_strip(dark_v, light_v, x0 + band_w, z0, h_len, band_w, scallop_w, segments, 0, add_tri)
	# Bottom edge scallops (semicircles hanging up from bottom)
	_draw_scallop_strip(dark_v, light_v, x0 + band_w, z0 + frame_h - band_w, h_len, band_w, scallop_w, segments, 2, add_tri)
	# Left edge scallops (semicircles hanging right)
	_draw_scallop_strip(dark_v, light_v, x0, z0 + band_w, v_len, band_w, scallop_w, segments, 1, add_tri)
	# Right edge scallops (semicircles hanging left)
	_draw_scallop_strip(dark_v, light_v, x0 + frame_w - band_w, z0 + band_w, v_len, band_w, scallop_w, segments, 3, add_tri)


## Draw a strip of scallops (semicircles).
## direction: 0=top (arcs go +Z), 1=left (arcs go +X), 2=bottom (arcs go -Z), 3=right (arcs go -X)
func _draw_scallop_strip(
	dark_v: PackedVector3Array,
	light_v: PackedVector3Array,
	ox: float, oz: float,
	strip_length: float, band_w: float,
	scallop_w: float, segments: int,
	direction: int,
	add_tri: Callable
) -> void:
	var n_scallops := maxi(1, int(round(strip_length / scallop_w)))
	var actual_w := strip_length / float(n_scallops)
	var radius := band_w

	for i in n_scallops:
		var is_dark := (i % 2) == 0
		var v := dark_v if is_dark else light_v
		var bg := light_v if is_dark else dark_v

		# Fill background rectangle for this scallop cell
		match direction:
			0:  # top edge
				bg = BorderMotifs._add_rect_verts(bg, ox + i * actual_w, oz, actual_w, band_w)
			2:  # bottom edge
				bg = BorderMotifs._add_rect_verts(bg, ox + i * actual_w, oz, actual_w, band_w)
			1:  # left edge
				bg = BorderMotifs._add_rect_verts(bg, ox, oz + i * actual_w, band_w, actual_w)
			3:  # right edge
				bg = BorderMotifs._add_rect_verts(bg, ox, oz + i * actual_w, band_w, actual_w)

		# Draw semicircle fan triangles on top
		var cx: float  # center of the arc
		var cz: float
		match direction:
			0:  # top edge, arc center at bottom of band
				cx = ox + (i + 0.5) * actual_w
				cz = oz + band_w
			2:  # bottom edge, arc center at top of band
				cx = ox + (i + 0.5) * actual_w
				cz = oz
			1:  # left edge, arc center at right of band
				cx = ox + band_w
				cz = oz + (i + 0.5) * actual_w
			3:  # right edge, arc center at left of band
				cx = ox
				cz = oz + (i + 0.5) * actual_w

		for s in segments:
			var a0: float
			var a1: float
			match direction:
				0:  # semicircle pointing up (-Z)
					a0 = PI + (PI * s / float(segments))
					a1 = PI + (PI * (s + 1) / float(segments))
				2:  # semicircle pointing down (+Z)
					a0 = PI * s / float(segments)
					a1 = PI * (s + 1) / float(segments)
				1:  # semicircle pointing left (-X)
					a0 = PI * 0.5 + (PI * s / float(segments))
					a1 = PI * 0.5 + (PI * (s + 1) / float(segments))
				3:  # semicircle pointing right (+X)
					a0 = -PI * 0.5 + (PI * s / float(segments))
					a1 = -PI * 0.5 + (PI * (s + 1) / float(segments))

			var p0 := Vector3(cx + cos(a0) * radius, 0, cz + sin(a0) * radius)
			var p1 := Vector3(cx + cos(a1) * radius, 0, cz + sin(a1) * radius)
			var center := Vector3(cx, 0, cz)
			v = add_tri.call(v, center, p0, p1)
