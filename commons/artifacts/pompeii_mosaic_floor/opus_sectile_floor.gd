# opus_sectile_floor.gd
# Procedural opus sectile floor — large cut marble pieces forming geometric patterns.
# Grid of circles inscribed in squares with triangular corner fills. Cosmatesque style.
#
# @identity
#   essence: a floor of luxury marble cut into bold geometric shapes
#   desire: players see the audacity of Roman stone-cutting — circles from straight cuts
#   critical_parameter: cells_short — number of circle-in-square cells on the short axis
#   triggers: instantiation or apply_grid_config
#   emerges: understanding that opus sectile is marble painting with geometry
#   needs: [implemented] procedural mesh, border bands, circle approximation
#   relationships: pompeii_mosaic_floor (sibling), pattern_maker_station (web editor)
#   truth: the Pantheon floor proves that simple geometry in rich materials transcends time

extends Node3D
class_name OpusSectileFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

## Opus sectile extended palette — adds green and deep red marble
const MARBLE_GREEN := Color(0.176, 0.353, 0.239)   # #2D5A3D — serpentine / verde antico
const MARBLE_DEEP_RED := Color(0.420, 0.102, 0.102) # #6B1A1A — porphyry / rosso antico

## Circle disc colors — cycle through these for each cell
const DISC_COLORS: Array[Color] = [
	Color(0.24, 0.22, 0.20),      # DARK (basalt)
	Color(0.69, 0.47, 0.31),      # TERRACOTTA
	Color(0.176, 0.353, 0.239),   # GREEN (serpentine)
	Color(0.420, 0.102, 0.102),   # DEEP RED (porphyry)
]

## Corner triangle colors — contrasting pairs
const CORNER_COLORS: Array[Color] = [
	Color(0.83, 0.79, 0.71),      # LIGHT (limestone)
	Color(0.420, 0.102, 0.102),   # DEEP RED
	Color(0.83, 0.79, 0.71),      # LIGHT
	Color(0.176, 0.353, 0.239),   # GREEN
]

@export var floor_size: Vector2 = Vector2(1.2, 0.9)
@export var cells_short: int = 4
@export var border_bands: int = 2
@export var circle_segments: int = 32
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.04
@export_range(0.0, 1.0) var wear_level: float = 0.25

var _mi: MeshInstance3D
#var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	var fs = config.get("floor_size", null)
	if fs is Array and fs.size() >= 2:
		floor_size = Vector2(float(fs[0]), float(fs[1]))
	cells_short = int(config.get("cells_short", cells_short))
	border_bands = int(config.get("border_bands", border_bands))
	wear_level = float(config.get("wear_level", wear_level))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		#_body = null

	var short_m := minf(floor_size.x, floor_size.y)
	var long_m := maxf(floor_size.x, floor_size.y)
	var is_wide := floor_size.x >= floor_size.y

	# Total cells including border
	var total_short := cells_short + border_bands * 2
	var cs := short_m / float(total_short)  # cell size in meters
	var total_long := int(round(long_m / cs))

	var gw: int = total_long if is_wide else total_short
	var gh: int = total_short if is_wide else total_long

	var fw := gw * cs
	var fh := gh * cs

	# Field region (inside borders)
	var fx0 := border_bands
	var fy0 := border_bands
	var fx1 := gw - border_bands
	var fy1 := gh - border_bands

	var grout_w := cs * grout_width_fraction

	# We build separate vertex arrays per color, then assign materials
	# Key: Color -> PackedVector3Array
	var color_verts: Dictionary = {}
	var grout_verts := PackedVector3Array()

	var _get_verts := func(c: Color) -> PackedVector3Array:
		if not color_verts.has(c):
			color_verts[c] = PackedVector3Array()
		return color_verts[c]

	# Helper: add a flat quad at y=0
	var _add_rect := func(verts: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z))
		verts.append(Vector3(x + w, 0, z + h))
		verts.append(Vector3(x, 0, z + h))
		return verts

	# Helper: add a triangle at y=0
	var _add_tri := func(verts: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> PackedVector3Array:
		verts.append(a)
		verts.append(b)
		verts.append(c)
		return verts

	# Helper: add a filled circle (disc) as triangle fan at y=0
	var _add_disc := func(verts: PackedVector3Array, cx: float, cz: float, radius: float, segs: int) -> PackedVector3Array:
		var center := Vector3(cx, 0, cz)
		for i in segs:
			var a0 := TAU * float(i) / float(segs)
			var a1 := TAU * float(i + 1) / float(segs)
			verts.append(center)
			verts.append(Vector3(cx + cos(a0) * radius, 0, cz + sin(a0) * radius))
			verts.append(Vector3(cx + cos(a1) * radius, 0, cz + sin(a1) * radius))
		return verts

	# ── 1. Border bands ──
	# Alternating dark/light concentric rectangular frames
	var border_colors: Array[Color] = [MosaicPalette.DARK, MosaicPalette.LIGHT]
	for band_i in border_bands:
		var band_color: Color = border_colors[band_i % 2]
		var bv: PackedVector3Array = _get_verts.call(band_color)
		var inset := band_i * cs
		var outer_w := gw * cs - inset * 2
		var outer_h := gh * cs - inset * 2
		var inner_w := outer_w - cs * 2
		var inner_h := outer_h - cs * 2

		var ox := inset
		var oz := inset
		var ix := inset + cs
		var iz := inset + cs

		# Top strip
		bv = _add_rect.call(bv, ox, oz, outer_w, cs)
		# Bottom strip
		bv = _add_rect.call(bv, ox, oz + outer_h - cs, outer_w, cs)
		# Left strip (between top and bottom)
		bv = _add_rect.call(bv, ox, iz, cs, inner_h)
		# Right strip
		bv = _add_rect.call(bv, ox + outer_w - cs, iz, cs, inner_h)

		color_verts[band_color] = bv

	# ── 2. Opus sectile field: circles inscribed in squares ──
	var cell_idx: int = 0
	for cy in range(fy0, fy1):
		for cx_i in range(fx0, fx1):
			var x := cx_i * cs
			var z := cy * cs
			var half := cs * 0.5
			var center_x := x + half
			var center_z := z + half

			# Circle radius: half the cell minus grout margin
			var radius := half - grout_w * 2.0

			# Pick colors based on cell index
			var disc_color: Color = DISC_COLORS[cell_idx % DISC_COLORS.size()]
			var corner_color: Color = CORNER_COLORS[cell_idx % CORNER_COLORS.size()]

			# Draw the circle disc
			var dv: PackedVector3Array = _get_verts.call(disc_color)
			dv = _add_disc.call(dv, center_x, center_z, radius, circle_segments)
			color_verts[disc_color] = dv

			# Draw 4 corner triangles (square corners outside the circle)
			# Each corner triangle: square corner + two adjacent circle tangent points
			var cv: PackedVector3Array = _get_verts.call(corner_color)

			# Inset the corner points slightly for grout gap
			var g := grout_w
			var corners := [
				Vector3(x + g, 0, z + g),                   # top-left
				Vector3(x + cs - g, 0, z + g),              # top-right
				Vector3(x + cs - g, 0, z + cs - g),         # bottom-right
				Vector3(x + g, 0, z + cs - g),              # bottom-left
			]
			# Angles for circle points near each corner
			var corner_angles := [
				[PI, PI * 1.5],        # top-left: left(PI) to top(3PI/2)
				[PI * 1.5, TAU],       # top-right: top(3PI/2) to right(TAU)
				[0.0, PI * 0.5],       # bottom-right: right(0) to bottom(PI/2)
				[PI * 0.5, PI],        # bottom-left: bottom(PI/2) to left(PI)
			]

			for ci in 4:
				var corner_pt: Vector3 = corners[ci]
				var a_start: float = corner_angles[ci][0]
				var a_end: float = corner_angles[ci][1]

				# Build a fan from the corner point through arc segments
				var arc_segs := circle_segments / 4
				for si in arc_segs:
					var aa := a_start + (a_end - a_start) * float(si) / float(arc_segs)
					var ab := a_start + (a_end - a_start) * float(si + 1) / float(arc_segs)
					var p1 := Vector3(center_x + cos(aa) * radius, 0, center_z + sin(aa) * radius)
					var p2 := Vector3(center_x + cos(ab) * radius, 0, center_z + sin(ab) * radius)
					cv = _add_tri.call(cv, corner_pt, p1, p2)

			color_verts[corner_color] = cv
			cell_idx += 1

	# ── 3. Grout lines ──
	if grout_w > 0.001:
		var half_g := grout_w * 0.5
		# Horizontal grid lines
		for gy in range(0, gh + 1):
			var z := gy * cs
			grout_verts = _add_rect.call(grout_verts, 0.0, z - half_g, fw, grout_w)
		# Vertical grid lines
		for gx in range(0, gw + 1):
			var x := gx * cs
			grout_verts = _add_rect.call(grout_verts, x - half_g, 0.0, grout_w, fh)

		# Circle outlines as thin ring quads in field
		for cy in range(fy0, fy1):
			for cx_i in range(fx0, fx1):
				var x := cx_i * cs
				var z := cy * cs
				var half := cs * 0.5
				var center_x := x + half
				var center_z := z + half
				var radius := half - grout_w * 2.0
				var r_inner := radius - half_g
				var r_outer := radius + half_g

				for si in circle_segments:
					var a0 := TAU * float(si) / float(circle_segments)
					var a1 := TAU * float(si + 1) / float(circle_segments)
					var c0 := cos(a0)
					var s0 := sin(a0)
					var c1 := cos(a1)
					var s1 := sin(a1)
					# Quad as 2 triangles
					var p0i := Vector3(center_x + c0 * r_inner, 0.001, center_z + s0 * r_inner)
					var p0o := Vector3(center_x + c0 * r_outer, 0.001, center_z + s0 * r_outer)
					var p1i := Vector3(center_x + c1 * r_inner, 0.001, center_z + s1 * r_inner)
					var p1o := Vector3(center_x + c1 * r_outer, 0.001, center_z + s1 * r_outer)
					grout_verts.append(p0i); grout_verts.append(p0o); grout_verts.append(p1o)
					grout_verts.append(p0i); grout_verts.append(p1o); grout_verts.append(p1i)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < corners(0.0) < discs(0.001) < border(0.002)
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	grout_verts = _offset_y.call(grout_verts, -0.001)

	# Offset color_verts: border colors at 0.0, corner colors at 0.001, disc colors at 0.002
	var border_color_set: Array[Color] = [MosaicPalette.DARK, MosaicPalette.LIGHT]
	for color_key in color_verts:
		var verts: PackedVector3Array = color_verts[color_key]
		var y_off: float = 0.001  # default for corner/pattern surfaces
		if color_key in border_color_set:
			y_off = 0.0  # border bands at base level
		elif color_key in DISC_COLORS:
			y_off = 0.002  # disc circles above corners
		color_verts[color_key] = _offset_y.call(verts, y_off)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()

	for color_key in color_verts:
		var verts: PackedVector3Array = color_verts[color_key]
		if verts.size() > 0:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(color_key, wear_level))

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

	# StaticBody3D for collision
	#_body = StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(fw, 0.01, fh)
	col_shape.shape = box
	#_body.add_child(col_shape)
	#_body.position = Vector3(0, 0.0, 0)
	#add_child(_body)

	var total_tris: int = 0
	for cv_key in color_verts:
		total_tris += color_verts[cv_key].size() / 3
	total_tris += grout_verts.size() / 3

	print("[OpusSectileFloor] Built %dx%d grid, %d cells, %d total tris" % [
		gw, gh, (fx1 - fx0) * (fy1 - fy0), total_tris
	])
