# san_michele_mosaic_floor.gd
# Procedural Roman mosaic floor — circular design inspired by Villa San Michele, Capri.
# Concentric zones: circular vine border, square Greek key frame, dark band,
# classical 7-circuit labyrinth, and a central rosette.
# Built as ArrayMesh with dark, light, terracotta, grout surfaces.
#
# @identity
#   essence: a floor that encodes the layered geometry of Roman villa luxury
#   desire: players look down and trace the path from vine border through labyrinth to rosette
#   critical_parameter: floor_radius — controls the overall size of the circular mosaic
#   triggers: instantiation or apply_grid_config
#   emerges: the understanding that Roman floors were concentric cosmograms — border, order, maze, center
#   needs: [implemented] procedural mesh, circular outline, vine border, meander frame, labyrinth, rosette
#   relationships: labyrinth_floor (labyrinth logic), star_rosette_floor (rosette geometry), wave_scale_floor (arc drawing)
#   truth: every Roman mosaic floor is a map of the universe read from outside in

extends Node3D
class_name SanMicheleMosaicFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_radius: float = 0.5
@export var circle_segments: int = 48
@export_range(0.0, 1.0) var wear_level: float = 0.3

## AXIS — WHICH STATE OF THE RECORD this floor is shown in. Tiles repeat; mosaics do not.
## A mosaic is a grid its maker kept deviating from — for the setting-out, for a later
## repair, for the line people walked, for what the ground finally kept — and the floor is
## the document of those deviations, not the pattern. Adopted word for word and value for
## value from [[spiral_mosaic_floor]], so two Roman floors in the same room cannot disagree
## about what state they are in; a room whose spiral is `loss` cannot have a cosmogram that
## still reads `design`.
##
##   design   as set out — the pattern with no deviation admitted. THE LEGACY LINEAGE,
##            byte for byte: this value adds nothing at all.
##   datum    the setting-out struck through — red-ochre construction showing: eight radii
##            from the centre punch, the six circles the compass swung at the zone
##            boundaries, and the inscribed SQUARE that turns the circle into the Greek key
##            frame. The compass-and-straightedge argument the floor is made of, put back
##            on top of it.
##   repair   later hands — a 60-degree sector lifted and relaid in a cool grey that does
##            not match the sand, at four times the tessera size, cutting straight through
##            the labyrinth so the circuit no longer closes. Two small rectangular patches
##            sit elsewhere at their own angles.
##   wear     the line people walked — a broad mottled band of bleached, dished surface
##            crossing the disc, and the ring around the central rosette rubbed out where
##            people stood at the end of the maze. The labyrinth reads THROUGH the scour.
##   loss     as excavated — six irregular lacunae down to the dark bedding, one of them
##            biting the vine border at the rim, each ringed by its own broken edge.
##
## `wear_level` above is the SHADER's weathering (dust, fade, hairline cracks, everywhere at
## once). `wear` here is GEOMETRY in one place: the traffic line. They are orthogonal and
## the default of each is unchanged by the other.
@export var condition: String = "design"
const CONDITIONS: PackedStringArray = ["design", "datum", "repair", "wear", "loss"]

## Seed for the irregularity `repair`, `wear` and `loss` need. NOTHING rolled in this
## artifact before, so the honest default is a fixed number: every render of a value is the
## same picture and the sweep measures the axis, not the noise. -1 randomises per build.
## The stream is a LOCAL RandomNumberGenerator, so the global stream is never touched and
## `design` never draws at all.
@export var condition_seed: int = 20260802

## Condition palette — the tones a conservator would name, not the mosaicist's. Identical
## to [[spiral_mosaic_floor]] so the two floors weather in the same language.
const COND_OCHRE := Color(0.60, 0.24, 0.16)    # sinopia: the red-ochre setting-out line
const COND_STONE := Color(0.50, 0.49, 0.46)    # the wrong stone — a cool grey that does not match
const COND_JOINT := Color(0.26, 0.24, 0.21)    # coarse mortar between relaid tesserae
const COND_PALE := Color(0.91, 0.88, 0.83)     # bleached, dished, walked-out surface
const COND_BED := Color(0.15, 0.13, 0.11)      # the bedding under a floor that is gone
const COND_RUBBLE := Color(0.40, 0.36, 0.30)   # the broken edge around a lacuna

var _mi: MeshInstance3D
var _cond_mi: MeshInstance3D
#var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	floor_radius = float(config.get("floor_radius", floor_radius))
	circle_segments = int(config.get("circle_segments", circle_segments))
	wear_level = float(config.get("wear_level", wear_level))
	# Condition, read the same way station_wall reads upkeep: normalise, and keep the
	# current value on a word the artifact cannot build. An unknown token must never
	# silently become a wildcard.
	var cond: String = str(config.get("condition", condition)).strip_edges().to_lower()
	condition = cond if CONDITIONS.has(cond) else condition
	condition_seed = int(config.get("condition_seed", condition_seed))
	_build()


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	#if _body:
		#_body.queue_free()
		#_body = null

	var R := floor_radius
	var dark_verts := PackedVector3Array()
	var light_verts := PackedVector3Array()
	var terra_verts := PackedVector3Array()
	var grout_verts := PackedVector3Array()

	# Zone radii (fractions of R, from outside in)
	var vine_outer := R
	var vine_inner := R * 0.88
	var meander_outer := R * 0.82
	var meander_inner := R * 0.72
	var dark_band_outer := R * 0.72
	var dark_band_inner := R * 0.64
	var lab_outer := R * 0.64
	var lab_inner := R * 0.10
	var rosette_radius := R * 0.10

	# ── 0. Light circular base (fills the whole circle) ──
	_draw_filled_circle(light_verts, 0.0, 0.0, R, circle_segments)

	# ── 1. Circular vine scroll border (dark on light) ──
	# Draw as a ring of semicircular arcs (wave/scroll pattern)
	var vine_mid := (vine_outer + vine_inner) * 0.5
	var vine_amplitude := (vine_outer - vine_inner) * 0.5
	var num_scrolls := 24  # number of vine scroll arcs around the circle
	var arc_segs := 8  # segments per scroll arc

	for i in range(num_scrolls):
		var angle_start := TAU * float(i) / float(num_scrolls)
		var angle_end := TAU * float(i + 1) / float(num_scrolls)
		var flip := (i % 2 == 0)

		# Draw scroll arc as triangle fan segments
		for seg in range(arc_segs):
			var t0 := float(seg) / float(arc_segs)
			var t1 := float(seg + 1) / float(arc_segs)

			var a0: float = lerp(angle_start, angle_end, t0)
			var a1: float = lerp(angle_start, angle_end, t1)

			# The scroll oscillates between vine_outer and vine_inner
			var scroll_r0: float
			var scroll_r1: float
			if flip:
				scroll_r0 = vine_mid + vine_amplitude * sin(t0 * PI)
				scroll_r1 = vine_mid + vine_amplitude * sin(t1 * PI)
			else:
				scroll_r0 = vine_mid - vine_amplitude * sin(t0 * PI)
				scroll_r1 = vine_mid - vine_amplitude * sin(t1 * PI)

			# Dark arc triangle from vine_inner to scroll curve
			var inner_r := vine_inner
			if flip:
				# Dark fills from inner to the scroll curve (outward bulge)
				dark_verts.append(Vector3(cos(a0) * inner_r, 0.001, sin(a0) * inner_r))
				dark_verts.append(Vector3(cos(a0) * scroll_r0, 0.001, sin(a0) * scroll_r0))
				dark_verts.append(Vector3(cos(a1) * scroll_r1, 0.001, sin(a1) * scroll_r1))
				dark_verts.append(Vector3(cos(a0) * inner_r, 0.001, sin(a0) * inner_r))
				dark_verts.append(Vector3(cos(a1) * scroll_r1, 0.001, sin(a1) * scroll_r1))
				dark_verts.append(Vector3(cos(a1) * inner_r, 0.001, sin(a1) * inner_r))
			else:
				# Dark fills from scroll curve to outer (inward bulge means dark on outer side)
				dark_verts.append(Vector3(cos(a0) * scroll_r0, 0.001, sin(a0) * scroll_r0))
				dark_verts.append(Vector3(cos(a0) * vine_outer, 0.001, sin(a0) * vine_outer))
				dark_verts.append(Vector3(cos(a1) * vine_outer, 0.001, sin(a1) * vine_outer))
				dark_verts.append(Vector3(cos(a0) * scroll_r0, 0.001, sin(a0) * scroll_r0))
				dark_verts.append(Vector3(cos(a1) * vine_outer, 0.001, sin(a1) * vine_outer))
				dark_verts.append(Vector3(cos(a1) * scroll_r1, 0.001, sin(a1) * scroll_r1))

	# ── 2. Square Greek key / meander frame ──
	# Inscribe a square inside the meander zone circle
	var sq_half := meander_outer * 0.7071  # R * cos(45deg) for inscribed square
	var meander_band := (meander_outer - meander_inner) * 0.7071
	var key_outer := sq_half
	var key_inner := sq_half - meander_band

	# Draw the meander frame as 4 bands
	# Outer frame (dark)
	_draw_rect_frame(dark_verts, -key_outer, -key_outer, key_outer * 2.0, key_outer * 2.0, meander_band * 0.3, 0.002)

	# Greek key pattern — draw a simplified meander along each side
	var key_band_w := meander_band * 0.7
	var key_unit := key_band_w * 0.5  # width of each meander unit
	var key_y := 0.002

	# Draw meander keys along each of the 4 sides
	for side in range(4):
		var num_keys := int((key_outer * 2.0) / (key_unit * 4.0))
		if num_keys < 2:
			num_keys = 2
		var actual_unit := (key_outer * 2.0) / float(num_keys * 4)

		for k in range(num_keys):
			var t := -key_outer + k * actual_unit * 4.0
			# Each meander key is a set of right-angle hooks
			# Transform coordinates based on which side
			_draw_meander_key(dark_verts, side, t, key_inner, key_outer, actual_unit, key_y)

	# Inner frame line (dark)
	_draw_rect_frame(dark_verts, -key_inner, -key_inner, key_inner * 2.0, key_inner * 2.0, meander_band * 0.15, 0.002)

	# ── 3. Dark solid band ──
	var band_sq_outer := dark_band_inner / dark_band_outer * sq_half
	var band_sq_inner := lab_outer / dark_band_outer * sq_half
	# Draw dark band as ring between two squares (use the circular zone)
	_draw_ring(dark_verts, 0.0, 0.0, dark_band_outer, dark_band_inner, circle_segments, 0.002)

	# ── 4. Central labyrinth — 7-circuit classical pattern ──
	# Generate labyrinth on a grid, then render cells inside the lab zone
	var lab_grid_size := 33  # odd number for 7-circuit labyrinth
	var lab_grid: Array = _generate_classical_labyrinth(lab_grid_size)

	# Map labyrinth grid to the square area inscribed in lab_outer circle
	var lab_sq_half := lab_outer * 0.7071
	var cell_size := (lab_sq_half * 2.0) / float(lab_grid_size)

	for gy in range(lab_grid_size):
		for gx in range(lab_grid_size):
			var cx := -lab_sq_half + gx * cell_size
			var cz := -lab_sq_half + gy * cell_size

			# Check if cell center is inside the labyrinth circle
			var ccx := cx + cell_size * 0.5
			var ccz := cz + cell_size * 0.5
			var dist := sqrt(ccx * ccx + ccz * ccz)
			if dist > lab_outer * 0.95:
				continue

			var is_path: bool = lab_grid[gy][gx]
			if is_path:
				# Path = dark
				_add_rect_verts(dark_verts, cx, cz, cell_size, cell_size, 0.003)
			else:
				# Wall = light
				_add_rect_verts(light_verts, cx, cz, cell_size, cell_size, 0.003)

	# ── 5. Central rosette — 6-pointed star ──
	var rosette_y := 0.004
	var star_R := rosette_radius * 0.9
	var star_r := star_R * 0.5  # inner radius

	# 6-pointed star (hexagram): 6 outer tips + 6 inner concave
	var outer_pts: Array[Vector3] = []
	var inner_pts: Array[Vector3] = []
	for k in range(6):
		var angle_out := TAU * float(k) / 6.0 - PI / 2.0
		var angle_in := TAU * float(k) / 6.0 + TAU / 12.0 - PI / 2.0
		outer_pts.append(Vector3(star_R * cos(angle_out), rosette_y, star_R * sin(angle_out)))
		inner_pts.append(Vector3(star_r * cos(angle_in), rosette_y, star_r * sin(angle_in)))

	# Spike triangles
	for k in range(6):
		terra_verts.append(outer_pts[k])
		terra_verts.append(inner_pts[k])
		terra_verts.append(inner_pts[(k + 5) % 6])

	# Inner hexagon fill
	var center := Vector3(0.0, rosette_y, 0.0)
	for k in range(6):
		terra_verts.append(center)
		terra_verts.append(inner_pts[k])
		terra_verts.append(inner_pts[(k + 1) % 6])

	# Small dark dot at very center
	_draw_filled_circle(dark_verts, 0.0, 0.0, rosette_radius * 0.2, 12, rosette_y + 0.001)

	# ── Clip everything to the circle ──
	# (The overlapping zones handle this by layering from bottom up at increasing y)


	# ── Z-fighting fix: offset each surface to a distinct Y layer ──
	# Hierarchy: grout(-0.001) < light(0.0) < dark(0.001) < terra/accent(0.002)
	#
	# IMPORTANT — different from pompeii's hierarchy! San Michele draws
	# a FULL circular LIGHT base (Section 0), so light must sit below
	# everything else; otherwise it occludes dark/terra patterns. In
	# pompeii light is only half of each truchet cell (non-overlapping
	# with dark), so the order doesn't matter the same way.
	var _offset_y := func(verts: PackedVector3Array, y_off: float) -> PackedVector3Array:
		for i in verts.size():
			verts[i].y = y_off
		return verts
	light_verts = _offset_y.call(light_verts, 0.0)
	dark_verts = _offset_y.call(dark_verts, 0.001)
	terra_verts = _offset_y.call(terra_verts, 0.002)
	grout_verts = _offset_y.call(grout_verts, -0.001)

	# ── Build ArrayMesh ──
	var arr_mesh := ArrayMesh.new()

	if dark_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = dark_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(MosaicPalette.DARK, wear_level))

	if light_verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = light_verts
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(MosaicPalette.LIGHT, wear_level))

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
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, MosaicPalette.create_material(MosaicPalette.GROUT, wear_level))

	_mi = MeshInstance3D.new()
	_mi.mesh = arr_mesh
	_mi.position = Vector3(0.0, 0.005, 0.0)
	add_child(_mi)

	# ── StaticBody3D + CollisionShape3D ──
	#_body = StaticBody3D.new()
	#var col := CollisionShape3D.new()
	#var box := BoxShape3D.new()
	#box.size = Vector3(R * 2.0, 0.01, R * 2.0)
	#col.shape = box
	#_body.add_child(col)
	#_body.position = Vector3(0.0, 0.005, 0.0)
	#add_child(_body)

	print("[SanMicheleMosaicFloor] Built circular floor R=%.3f (%d dark, %d light, %d terra tris)" % [
		R,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		terra_verts.size() / 3,
	])

	# CONDITION, appended LAST so every vertex, surface, y-offset and child above is
	# untouched on the legacy path. "design" adds no node at all.
	_build_condition()


# ── Helper: draw a filled circle as triangle fan ──
func _draw_filled_circle(verts: PackedVector3Array, cx: float, cz: float, radius: float, segs: int, y: float = 0.0) -> void:
	var center := Vector3(cx, y, cz)
	for i in range(segs):
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		verts.append(center)
		verts.append(Vector3(cx + radius * cos(a0), y, cz + radius * sin(a0)))
		verts.append(Vector3(cx + radius * cos(a1), y, cz + radius * sin(a1)))


# ── Helper: draw a ring (annulus) ──
func _draw_ring(verts: PackedVector3Array, cx: float, cz: float, r_outer: float, r_inner: float, segs: int, y: float = 0.0) -> void:
	for i in range(segs):
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var o0 := Vector3(cx + r_outer * cos(a0), y, cz + r_outer * sin(a0))
		var o1 := Vector3(cx + r_outer * cos(a1), y, cz + r_outer * sin(a1))
		var i0 := Vector3(cx + r_inner * cos(a0), y, cz + r_inner * sin(a0))
		var i1 := Vector3(cx + r_inner * cos(a1), y, cz + r_inner * sin(a1))
		verts.append(o0)
		verts.append(o1)
		verts.append(i1)
		verts.append(o0)
		verts.append(i1)
		verts.append(i0)


# ── Helper: draw a rectangular frame (4 bands) ──
func _draw_rect_frame(verts: PackedVector3Array, x: float, z: float, w: float, h: float, band: float, y: float = 0.0) -> void:
	# Top band
	_add_rect_verts(verts, x, z, w, band, y)
	# Bottom band
	_add_rect_verts(verts, x, z + h - band, w, band, y)
	# Left band
	_add_rect_verts(verts, x, z + band, band, h - band * 2.0, y)
	# Right band
	_add_rect_verts(verts, x + w - band, z + band, band, h - band * 2.0, y)


# ── Helper: add a flat rectangle at given y ──
func _add_rect_verts(verts: PackedVector3Array, x: float, z: float, w: float, h: float, y: float = 0.0) -> void:
	verts.append(Vector3(x, y, z))
	verts.append(Vector3(x + w, y, z))
	verts.append(Vector3(x + w, y, z + h))
	verts.append(Vector3(x, y, z))
	verts.append(Vector3(x + w, y, z + h))
	verts.append(Vector3(x, y, z + h))


# ── Helper: draw a single meander key along one side ──
func _draw_meander_key(verts: PackedVector3Array, side: int, t: float, inner: float, outer: float, unit: float, y: float) -> void:
	# A meander key is a series of right-angle hooks.
	# We draw it as small rectangles forming the key shape.
	var u := unit
	var line_w := u * 0.45

	# The key pattern for one unit (4 units wide):
	# Vertical bar, horizontal hook, vertical return, horizontal bar
	# We transform coordinates based on which side (0=top, 1=right, 2=bottom, 3=left)

	# Generate key quads in local coords (along x-axis, bands along z-axis from inner to outer)
	var quads: Array[Array] = []

	# Bottom horizontal bar
	quads.append([t, inner, u * 4.0, line_w])
	# Left vertical bar going up
	quads.append([t, inner, line_w, outer - inner])
	# Top horizontal bar (partial)
	quads.append([t, outer - line_w, u * 3.0, line_w])
	# Right drop-down
	quads.append([t + u * 3.0 - line_w, inner + line_w, line_w, outer - inner - line_w])
	# Inner horizontal return
	quads.append([t + u, inner + line_w, u * 2.0 - line_w, line_w])
	# Inner vertical stub
	quads.append([t + u, inner + line_w, line_w, (outer - inner) * 0.5])

	for q in quads:
		var qx: float = q[0]
		var qz: float = q[1]
		var qw: float = q[2]
		var qh: float = q[3]

		# Transform based on side
		match side:
			0:  # Top side: meander runs along x, z from -key_outer to -key_inner
				_add_rect_verts(verts, qx, -qz - qh, qw, qh, y)
			1:  # Right side: meander runs along z, x from key_inner to key_outer
				_add_rect_verts(verts, qz, qx, qh, qw, y)
			2:  # Bottom side: mirrored
				_add_rect_verts(verts, -qx - qw, qz, qw, qh, y)
			3:  # Left side
				_add_rect_verts(verts, -qz - qh, -qx - qw, qh, qw, y)


# ── Classical 7-circuit labyrinth generator (from labyrinth_floor.gd) ──
static func _generate_classical_labyrinth(s: int) -> Array:
	if s % 2 == 0:
		s += 1

	var grid: Array = []
	for _y in range(s):
		var row: Array = []
		row.resize(s)
		row.fill(false)
		grid.append(row)

	var cx: int = s / 2
	var cy: int = s / 2

	grid[cy][cx] = true

	var max_r: int = mini(cx, cy) - 1
	var num_circuits: int = 7
	var ring_step: int = 2
	if max_r < num_circuits * ring_step:
		ring_step = maxi(1, max_r / num_circuits)

	var path_radii: Array[int] = []
	for i in range(1, num_circuits + 1):
		path_radii.append(i * ring_step)

	var _draw_ring = func(r_idx: int, gap_bl: bool, gap_br: bool, gap_tl: bool, gap_tr: bool) -> void:
		var r: int = path_radii[r_idx]
		var x0: int = maxi(0, cx - r)
		var x1: int = mini(s - 1, cx + r)
		var y0: int = maxi(0, cy - r)
		var y1: int = mini(s - 1, cy + r)

		if not gap_tl:
			for x in range(x0, cx + 1):
				grid[y0][x] = true
		else:
			for x in range(x0, cx):
				grid[y0][x] = true
		if not gap_tr:
			for x in range(cx, x1 + 1):
				grid[y0][x] = true
		else:
			for x in range(cx + 1, x1 + 1):
				grid[y0][x] = true

		if not gap_bl:
			for x in range(x0, cx + 1):
				grid[y1][x] = true
		else:
			for x in range(x0, cx):
				grid[y1][x] = true
		if not gap_br:
			for x in range(cx, x1 + 1):
				grid[y1][x] = true
		else:
			for x in range(cx + 1, x1 + 1):
				grid[y1][x] = true

		for y_val in range(y0, y1 + 1):
			grid[y_val][x0] = true
		for y_val in range(y0, y1 + 1):
			grid[y_val][x1] = true

	_draw_ring.call(0, false, true, true, false)
	_draw_ring.call(1, true, false, false, true)
	_draw_ring.call(2, false, true, true, false)
	_draw_ring.call(3, true, false, false, true)
	_draw_ring.call(4, false, true, true, false)
	_draw_ring.call(5, true, false, false, true)
	_draw_ring.call(6, false, true, false, false)

	for i in range(num_circuits - 1):
		var r_inner: int = path_radii[i]
		var r_outer: int = path_radii[i + 1]
		var y_bot_inner: int = mini(s - 1, cy + r_inner)
		var y_bot_outer: int = mini(s - 1, cy + r_outer)
		var y_top_inner: int = maxi(0, cy - r_inner)
		var y_top_outer: int = maxi(0, cy - r_outer)

		if i % 2 == 0:
			for y_val in range(y_bot_inner, y_bot_outer + 1):
				grid[y_val][cx] = true
			for y_val in range(y_top_outer, y_top_inner + 1):
				grid[y_val][cx] = true
		else:
			for y_val in range(y_bot_inner, y_bot_outer + 1):
				grid[y_val][cx] = true
			for y_val in range(y_top_outer, y_top_inner + 1):
				grid[y_val][cx] = true

	var r_outer: int = path_radii[num_circuits - 1]
	var y_entrance: int = mini(s - 1, cy + r_outer)
	for y_val in range(y_entrance, s):
		grid[y_val][cx] = true

	var r_inner: int = path_radii[0]
	var y_center_connect: int = maxi(0, cy - r_inner)
	for y_val in range(y_center_connect, cy + 1):
		grid[y_val][cx] = true

	return grid


# ── CONDITION ────────────────────────────────────────────────────────────────
# One axis, five states of the record, all of it drawn into ONE extra MeshInstance3D
# standing 0.008 m above the floor plate — clear of the terracotta layer at 0.007, and
# never outside the disc. That matters twice: the AABB (and so the sweep's framing) is
# identical picture to picture, and the legacy mesh is not touched by a single vertex.

func _build_condition() -> void:
	if _cond_mi:
		_cond_mi.queue_free()
		_cond_mi = null

	var ochre := PackedVector3Array()    # the setting-out struck in red
	var stone := PackedVector3Array()    # relaid tesserae, the wrong stone
	var joint := PackedVector3Array()    # mortar under and between them
	var pale := PackedVector3Array()     # scoured, walked-out surface
	var bed := PackedVector3Array()      # what is under a floor that is gone
	var rubble := PackedVector3Array()   # the broken edge of a lacuna

	var rng := RandomNumberGenerator.new()
	if condition_seed < 0:
		rng.randomize()
	else:
		rng.seed = condition_seed

	match condition:
		"design":
			pass                                  # the legacy lineage — nothing is added
		"datum":
			_cond_datum(ochre)
		"repair":
			_cond_repair(stone, joint, rng)
		"wear":
			_cond_wear(pale, rng)
		"loss":
			_cond_loss(bed, rubble, rng)
		_:
			pass                                  # an unknown word reads as "design"

	var arr := ArrayMesh.new()
	_cond_surface(arr, rubble, COND_RUBBLE)
	_cond_surface(arr, bed, COND_BED)
	_cond_surface(arr, joint, COND_JOINT)
	_cond_surface(arr, stone, COND_STONE)
	_cond_surface(arr, pale, COND_PALE)
	_cond_surface(arr, ochre, COND_OCHRE)
	if arr.get_surface_count() == 0:
		return

	_cond_mi = MeshInstance3D.new()
	_cond_mi.mesh = arr
	_cond_mi.position = Vector3(0, 0.008, 0)
	add_child(_cond_mi)


## DATUM — the compass-and-straightedge argument the floor is made of, struck back over the
## finished work in red ochre. Eight radii from the centre punch, the six circles at the
## zone boundaries the builder swung, and the inscribed SQUARE that turns the circle into
## the Greek key frame — the one construction line that explains why a round floor has a
## square border on it.
func _cond_datum(v: PackedVector3Array) -> void:
	var big_r: float = floor_radius
	var y: float = 0.0009
	var lw: float = maxf(big_r * 0.011, 0.004)

	for k in range(8):
		var a: float = TAU * float(k) / 8.0
		var dir: Vector2 = Vector2(cos(a), sin(a))
		_cond_seg(v, dir * (big_r * 0.06), dir * (big_r * 0.985), lw, y)

	var rings: Array[float] = [big_r * 0.10, big_r * 0.64, big_r * 0.72,
		big_r * 0.82, big_r * 0.88, big_r * 0.985]
	for r in rings:
		_cond_ring(v, r, lw * 0.8, 84, y)

	# The inscribed square at meander_outer * cos(45 deg) — the same number _build uses.
	var sq: float = big_r * 0.82 * 0.7071
	var a0: Vector2 = Vector2(-sq, -sq)
	var b0: Vector2 = Vector2(sq, -sq)
	var c0: Vector2 = Vector2(sq, sq)
	var d0: Vector2 = Vector2(-sq, sq)
	_cond_seg(v, a0, b0, lw * 0.8, y)
	_cond_seg(v, b0, c0, lw * 0.8, y)
	_cond_seg(v, c0, d0, lw * 0.8, y)
	_cond_seg(v, d0, a0, lw * 0.8, y)
	# ...and its diagonals, which is how you find the centre in the first place.
	_cond_seg(v, a0, c0, lw * 0.5, y)
	_cond_seg(v, b0, d0, lw * 0.5, y)

	_cond_disc(v, Vector2.ZERO, maxf(big_r * 0.045, 0.012), 16, y)


## REPAIR — later hands. A 60-degree sector is lifted and relaid in a cool grey that does
## not match the sand, at four times the tessera size, in courses that follow the SECTOR.
## It runs from inside the labyrinth out through the meander frame, so the seven circuits
## no longer close: the patch is legible precisely because it breaks the one thing on this
## floor that has to be continuous.
func _cond_repair(stone: PackedVector3Array, joint: PackedVector3Array,
		rng: RandomNumberGenerator) -> void:
	var big_r: float = floor_radius
	var lim: float = big_r * 0.94

	var a0: float = 0.92
	var a1: float = 1.98
	var r0: float = big_r * 0.14
	var r1: float = lim
	for i in range(22):
		var t0: float = lerpf(a0, a1, float(i) / 22.0)
		var t1: float = lerpf(a0, a1, float(i + 1) / 22.0)
		_cond_quad(joint,
			Vector2(cos(t0) * r0, sin(t0) * r0),
			Vector2(cos(t1) * r0, sin(t1) * r0),
			Vector2(cos(t1) * r1, sin(t1) * r1),
			Vector2(cos(t0) * r1, sin(t0) * r1), 0.0)

	var cell: float = 0.042
	var rows: int = maxi(int((r1 - r0) / cell), 2)
	for ri in range(rows):
		var rr0: float = r0 + (r1 - r0) * float(ri) / float(rows)
		var rr1: float = r0 + (r1 - r0) * float(ri + 1) / float(rows)
		var mid: float = (rr0 + rr1) * 0.5
		var cols: int = maxi(int((a1 - a0) * mid / cell), 2)
		for ci in range(cols):
			var t0: float = lerpf(a0, a1, float(ci) / float(cols))
			var t1: float = lerpf(a0, a1, float(ci + 1) / float(cols))
			_cond_tessera_polar(stone, t0, t1, rr0, rr1, 0.0006)

	_cond_patch_rect(stone, joint, Vector2(-big_r * 0.44, big_r * 0.14),
		Vector2(big_r * 0.36, big_r * 0.24), rng.randf_range(-0.55, 0.55), lim)
	_cond_patch_rect(stone, joint, Vector2(big_r * 0.12, -big_r * 0.54),
		Vector2(big_r * 0.28, big_r * 0.20), rng.randf_range(-0.55, 0.55), lim)


## WEAR — the line people walked. A broad band crossing the disc, mottled rather than
## solid, so the labyrinth reads THROUGH the scour the way a rubbed floor does rather than
## disappearing under a blanket. The ring around the central rosette is rubbed out on its
## own: the end of the maze is where everyone stood.
func _cond_wear(pale: PackedVector3Array, rng: RandomNumberGenerator) -> void:
	var big_r: float = floor_radius
	var lim: float = big_r * 0.95
	var y: float = 0.0003
	var phi: float = 0.62
	var dir: Vector2 = Vector2(cos(phi), sin(phi))
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	var half: float = big_r * 0.30
	var step: float = 0.021
	var tile: float = 0.016
	var n: int = maxi(int(big_r * 2.0 / step), 8)
	for ix in range(-n, n + 1):
		for iz in range(-n, n + 1):
			var p: Vector2 = Vector2(float(ix), float(iz)) * step
			if p.length() > lim:
				continue
			var across: float = absf(p.dot(nrm))
			var along: float = absf(p.dot(dir)) / maxf(lim, 0.01)
			var band: float = half * (1.0 - 0.30 * along)
			var take: float = 0.0
			if across < band:
				take = 1.0 - (across / maxf(band, 0.001)) * 0.75
			if p.length() < big_r * 0.22:
				take = maxf(take, 0.85)
			if take <= 0.02:
				continue
			if rng.randf() > take:
				continue
			var h: float = tile * 0.5
			_cond_quad(pale, p + Vector2(-h, -h), p + Vector2(h, -h),
				p + Vector2(h, h), p + Vector2(-h, h), y)


## LOSS — as excavated. Six irregular lacunae down to the dark bedding, each ringed by the
## broken edge where the tesserae let go, and one more at the rim that has taken a bite out
## of the vine border with it. Everything is clamped to the disc, so the floor loses area
## without the artifact changing size.
func _cond_loss(bed: PackedVector3Array, rubble: PackedVector3Array,
		rng: RandomNumberGenerator) -> void:
	var big_r: float = floor_radius
	var lim: float = big_r * 0.99
	for i in range(6):
		var a: float = rng.randf_range(0.0, TAU)
		var d: float = rng.randf_range(big_r * 0.12, big_r * 0.68)
		var c: Vector2 = Vector2(cos(a), sin(a)) * d
		var rad: float = rng.randf_range(big_r * 0.11, big_r * 0.26)
		_cond_blob(rubble, c, rad * 1.16, 0.26, rng, 0.0, lim)
		_cond_blob(bed, c, rad, 0.22, rng, 0.0006, lim)

	var ra: float = rng.randf_range(0.0, TAU)
	var rc: Vector2 = Vector2(cos(ra), sin(ra)) * (big_r * 0.86)
	_cond_blob(rubble, rc, big_r * 0.34, 0.30, rng, 0.0, lim)
	_cond_blob(bed, rc, big_r * 0.29, 0.26, rng, 0.0006, lim)


# ── condition primitives ─────────────────────────────────────────────────────

func _cond_surface(arr: ArrayMesh, verts: PackedVector3Array, c: Color) -> void:
	if verts.size() == 0:
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr.surface_set_material(arr.get_surface_count() - 1,
		MosaicPalette.create_material(c, wear_level))


func _cond_quad(v: PackedVector3Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2,
		y: float) -> void:
	v.append(Vector3(a.x, y, a.y))
	v.append(Vector3(b.x, y, b.y))
	v.append(Vector3(c.x, y, c.y))
	v.append(Vector3(a.x, y, a.y))
	v.append(Vector3(c.x, y, c.y))
	v.append(Vector3(d.x, y, d.y))


func _cond_seg(v: PackedVector3Array, p0: Vector2, p1: Vector2, half_w: float,
		y: float) -> void:
	var d: Vector2 = p1 - p0
	if d.length() < 0.00001:
		return
	var n: Vector2 = Vector2(-d.y, d.x).normalized() * half_w
	_cond_quad(v, p0 - n, p1 - n, p1 + n, p0 + n, y)


func _cond_ring(v: PackedVector3Array, radius: float, half_w: float, segs: int,
		y: float) -> void:
	var ri: float = maxf(radius - half_w, 0.0)
	var ro: float = radius + half_w
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		_cond_quad(v,
			Vector2(cos(a0) * ri, sin(a0) * ri),
			Vector2(cos(a1) * ri, sin(a1) * ri),
			Vector2(cos(a1) * ro, sin(a1) * ro),
			Vector2(cos(a0) * ro, sin(a0) * ro), y)


func _cond_disc(v: PackedVector3Array, centre: Vector2, radius: float, segs: int,
		y: float) -> void:
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		v.append(Vector3(centre.x, y, centre.y))
		v.append(Vector3(centre.x + cos(a0) * radius, y, centre.y + sin(a0) * radius))
		v.append(Vector3(centre.x + cos(a1) * radius, y, centre.y + sin(a1) * radius))


## An irregular lobe, every rim vertex clamped inside `lim` so a lacuna can eat the border
## without ever growing the artifact's bounding box.
func _cond_blob(v: PackedVector3Array, centre: Vector2, radius: float, jitter: float,
		rng: RandomNumberGenerator, y: float, lim: float) -> void:
	var segs: int = 18
	var rs: Array[float] = []
	for i in range(segs):
		rs.append(radius * (1.0 - jitter + rng.randf() * jitter * 2.0))
	var mid: Vector2 = _cond_clamp(centre, lim)
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		var p0: Vector2 = _cond_clamp(centre + Vector2(cos(a0), sin(a0)) * rs[i], lim)
		var p1: Vector2 = _cond_clamp(
			centre + Vector2(cos(a1), sin(a1)) * rs[(i + 1) % segs], lim)
		v.append(Vector3(mid.x, y, mid.y))
		v.append(Vector3(p0.x, y, p0.y))
		v.append(Vector3(p1.x, y, p1.y))


func _cond_clamp(p: Vector2, lim: float) -> Vector2:
	if p.length() <= lim:
		return p
	return p.normalized() * lim


## One relaid tessera in polar coordinates, inset so the coarse joint shows around it.
func _cond_tessera_polar(v: PackedVector3Array, t0: float, t1: float, r0: float, r1: float,
		y: float) -> void:
	var mid: float = (r0 + r1) * 0.5
	var ang_in: float = 0.006 / maxf(mid, 0.02)
	var ta: float = t0 + ang_in
	var tb: float = t1 - ang_in
	var ra: float = r0 + 0.006
	var rb: float = r1 - 0.006
	if tb <= ta or rb <= ra:
		return
	_cond_quad(v,
		Vector2(cos(ta) * ra, sin(ta) * ra),
		Vector2(cos(tb) * ra, sin(tb) * ra),
		Vector2(cos(tb) * rb, sin(tb) * rb),
		Vector2(cos(ta) * rb, sin(ta) * rb), y)


## A rectangular patch set at its own angle: bedding first, then coarse tesserae inset on
## top. Skipped entirely if any corner would leave the disc.
func _cond_patch_rect(stone: PackedVector3Array, joint: PackedVector3Array, centre: Vector2,
		size: Vector2, rot: float, lim: float) -> void:
	var ca: float = cos(rot)
	var sa: float = sin(rot)
	var hx: float = size.x * 0.5
	var hz: float = size.y * 0.5
	var local: Array[Vector2] = [
		Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	var world: Array[Vector2] = []
	for p in local:
		world.append(centre + Vector2(p.x * ca - p.y * sa, p.x * sa + p.y * ca))
	for w in world:
		if w.length() > lim:
			return
	_cond_quad(joint, world[0], world[1], world[2], world[3], 0.0)

	var cell: float = 0.038
	var nx: int = maxi(int(size.x / cell), 2)
	var nz: int = maxi(int(size.y / cell), 2)
	var inset: float = 0.006
	for ix in range(nx):
		for iz in range(nz):
			var x0: float = -hx + size.x * float(ix) / float(nx) + inset
			var x1: float = -hx + size.x * float(ix + 1) / float(nx) - inset
			var z0: float = -hz + size.y * float(iz) / float(nz) + inset
			var z1: float = -hz + size.y * float(iz + 1) / float(nz) - inset
			if x1 <= x0 or z1 <= z0:
				continue
			_cond_quad(stone,
				centre + Vector2(x0 * ca - z0 * sa, x0 * sa + z0 * ca),
				centre + Vector2(x1 * ca - z0 * sa, x1 * sa + z0 * ca),
				centre + Vector2(x1 * ca - z1 * sa, x1 * sa + z1 * ca),
				centre + Vector2(x0 * ca - z1 * sa, x0 * sa + z1 * ca), 0.0006)
