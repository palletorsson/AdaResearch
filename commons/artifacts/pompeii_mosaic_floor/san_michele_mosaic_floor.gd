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

var _mi: MeshInstance3D
#var _body: StaticBody3D


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	floor_radius = float(config.get("floor_radius", floor_radius))
	circle_segments = int(config.get("circle_segments", circle_segments))
	wear_level = float(config.get("wear_level", wear_level))
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
