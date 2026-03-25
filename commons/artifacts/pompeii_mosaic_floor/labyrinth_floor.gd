# labyrinth_floor.gd
# Procedural Roman labyrinth mosaic floor — classical 7-circuit single-path labyrinth.
# Renders on a grid: dark cells = path, light cells = walls, with grout lines.
# Based on the labyrinth mosaics found in Pompeii, Knossos, and Chartres predecessors.
#
# @identity
#   essence: a floor that traces the oldest algorithmic path in architecture
#   desire: players look down and follow a single unbroken path to the center
#   critical_parameter: grid_cells — resolution of the labyrinth grid
#   triggers: instantiation or apply_grid_config
#   emerges: the realization that a labyrinth is not a maze — there are no choices, only the walk
#   needs: [implemented] procedural mesh, border bands, classical labyrinth seed
#   relationships: pompeii_mosaic_floor (parent pattern), swastika_meander_floor (cousin)
#   truth: the classical labyrinth is a single algorithm that every ancient culture discovered independently

extends Node3D
class_name LabyrinthFloor

const MosaicPalette = preload("res://commons/artifacts/pompeii_mosaic_floor/mosaic_palette.gd")

@export var floor_size: Vector2 = Vector2(1.2, 1.2)
@export var grid_cells: int = 33  # Must be odd; 33 gives good resolution for 7-circuit
@export var border_widths: Array[int] = [2, 1, 1]
@export var color_dark: Color = MosaicPalette.DARK
@export var color_light: Color = MosaicPalette.LIGHT
@export var grout_color: Color = MosaicPalette.GROUT
@export_range(0.0, 0.1) var grout_width_fraction: float = 0.05
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
	wear_level = float(config.get("wear_level", wear_level))
	var bw = config.get("border_widths", null)
	if bw is Array:
		border_widths.clear()
		for v in bw:
			border_widths.append(int(v))
	_build()


## Generate a classical 7-circuit labyrinth on a boolean grid.
## Returns a 2D array (Array of Array[bool]) where true = path, false = wall.
## The labyrinth is centered in grid of size `s x s` (s should be odd).
static func _generate_classical_labyrinth(s: int) -> Array:
	# Ensure odd
	if s % 2 == 0:
		s += 1

	# Initialize grid: all walls (false)
	var grid: Array = []
	for _y in range(s):
		var row: Array = []
		row.resize(s)
		row.fill(false)
		grid.append(row)

	var cx: int = s / 2  # center x
	var cy: int = s / 2  # center y

	# The classical 7-circuit labyrinth can be constructed by drawing
	# concentric rings with specific connections.
	# We use the seed pattern method: start from center, draw 7 concentric
	# rectangular rings (path rings alternating with wall rings), then
	# carve the single-path connections between them.

	# Mark center as path
	grid[cy][cx] = true

	# Ring radii: 1 through 7 for path, walls are the spaces between
	# We'll draw rectangular rings. Each "circuit" is a rectangular path ring
	# at distance r from center. Path rings at odd r, wall at even r...
	# Actually, for a grid labyrinth: rings at r=1,2,3,...,7 from center.
	# Path rings: r = 1, 3, 5, 7 (and center)
	# Wall rings: r = 2, 4, 6 (these stay as walls to separate paths)
	#
	# But classical labyrinth has 7 circuits = 7 path rings + walls between.
	# We need radius up to ~15 cells from center for 7 circuits.
	# Each circuit is 2 cells wide (1 path + 1 wall).
	# Total radius = 7*2 + 1 = 15 cells from center.
	# So grid should be at least 31x31. With 33 we have 1 cell border.

	var max_r: int = mini(cx, cy) - 1  # leave 1 cell margin
	var num_circuits: int = 7
	# Each circuit occupies 2 cells radially (1 path + 1 gap)
	var ring_step: int = 2
	if max_r < num_circuits * ring_step:
		ring_step = maxi(1, max_r / num_circuits)

	# Draw concentric rectangular path rings
	# Path rings at radii: ring_step, ring_step*2, ..., ring_step*7
	var path_radii: Array[int] = []
	for i in range(1, num_circuits + 1):
		path_radii.append(i * ring_step)

	# Draw each path ring as a rectangular loop
	for r in path_radii:
		var x0: int = cx - r
		var x1: int = cx + r
		var y0: int = cy - r
		var y1: int = cy + r
		# Clamp to grid
		x0 = maxi(0, x0)
		x1 = mini(s - 1, x1)
		y0 = maxi(0, y0)
		y1 = mini(s - 1, y1)
		# Top edge
		for x in range(x0, x1 + 1):
			grid[y0][x] = true
		# Bottom edge
		for x in range(x0, x1 + 1):
			grid[y1][x] = true
		# Left edge
		for y in range(y0, y1 + 1):
			grid[y][x0] = true
		# Right edge
		for y in range(y0, y1 + 1):
			grid[y][x1] = true

	# Now we need to connect the rings to form a single path.
	# Classical 7-circuit labyrinth connection pattern:
	# The seed pattern defines which side each ring connects on.
	# Classical labyrinth path order (from outside in): 3-2-1-4-7-6-5-center
	# (i.e., you enter ring 3 first, then 2, 1, 4, 7, 6, 5, then center)
	#
	# We create openings and connections:
	# First, block off default connections by ensuring walls exist between rings.
	# Then carve specific radial passages to create the classical path.

	# Erase all path rings to start fresh — we'll redraw them with gaps
	for r in path_radii:
		var x0: int = maxi(0, cx - r)
		var x1: int = mini(s - 1, cx + r)
		var y0: int = maxi(0, cy - r)
		var y1: int = mini(s - 1, cy + r)
		for x in range(x0, x1 + 1):
			grid[y0][x] = false
			grid[y1][x] = false
		for y in range(y0, y1 + 1):
			grid[y][x0] = false
			grid[y][x1] = false

	# Reset center
	grid[cy][cx] = true

	# Build the classical labyrinth using the half-ring method.
	# Each ring is split into top-half and bottom-half arcs.
	# The classical 7-circuit labyrinth visits rings in order: 3,2,1,4,7,6,5,center
	#
	# We construct it by drawing half-ring arcs with specific openings.
	# Think of the labyrinth in 4 quadrants. The entrance is at bottom-center.
	#
	# The standard construction: draw the seed cross and dots, then connect.
	# For a grid, we implement this directly:

	# Re-approach: draw the labyrinth as connected half-rings.
	# Each ring i (1=innermost, 7=outermost) has radius path_radii[i-1].
	# The entrance is at the bottom.
	#
	# Classical labyrinth structure — each ring has an opening on the left
	# or right side of the bottom, creating the characteristic path.
	#
	# Use the direct construction: the path sequence from outside to center
	# visits the rings in order 3-2-1-4-7-6-5-0(center).
	#
	# Implementation: we draw each ring with specific gaps to create
	# the single-path topology.

	# Helper: draw a rectangular ring with gaps at specified positions
	# gap_bottom_left, gap_bottom_right, gap_top_left, gap_top_right
	# are booleans indicating if there's a gap at that position
	var _draw_ring = func(r_idx: int,
			gap_bl: bool, gap_br: bool, gap_tl: bool, gap_tr: bool) -> void:
		var r: int = path_radii[r_idx]
		var x0: int = maxi(0, cx - r)
		var x1: int = mini(s - 1, cx + r)
		var y0: int = maxi(0, cy - r)
		var y1: int = mini(s - 1, cy + r)

		# Top edge: left half and right half
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

		# Bottom edge: left half and right half
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

		# Left edge (full)
		for y in range(y0, y1 + 1):
			grid[y][x0] = true
		# Right edge (full)
		for y in range(y0, y1 + 1):
			grid[y][x1] = true

	# Classical 7-circuit labyrinth gap pattern:
	# Ring 1 (innermost): gap at bottom-right, top-left
	# Ring 2: gap at bottom-left, top-right
	# Ring 3: gap at bottom-right, top-left
	# Ring 4: gap at bottom-left, top-right
	# Ring 5: gap at bottom-right, top-left
	# Ring 6: gap at bottom-left, top-right
	# Ring 7 (outermost): gap at bottom-right only (entrance)
	#
	# This creates the classical alternating pattern.
	# gap params: (ring_index, gap_bl, gap_br, gap_tl, gap_tr)

	_draw_ring.call(0, false, true, true, false)   # Ring 1
	_draw_ring.call(1, true, false, false, true)    # Ring 2
	_draw_ring.call(2, false, true, true, false)    # Ring 3
	_draw_ring.call(3, true, false, false, true)    # Ring 4
	_draw_ring.call(4, false, true, true, false)    # Ring 5
	_draw_ring.call(5, true, false, false, true)    # Ring 6
	_draw_ring.call(6, false, true, false, false)   # Ring 7 — entrance at bottom-right

	# Draw radial connectors between rings
	# The vertical passages that connect adjacent rings at the gap points.
	# At each gap, we need a radial passage connecting the ring to the next one.

	# Left-side radial passages (at x = cx - 0.5, connecting rings on the left)
	# Right-side radial passages (at x = cx + 0.5, connecting rings on the right)
	# Actually at cx for left gaps and cx for right gaps.

	# Bottom connectors (at y = cy + r, connecting downward between rings)
	# We connect at the gap positions: bottom-left gaps at x slightly left of cx,
	# bottom-right gaps at x slightly right of cx.

	# Radial connections at the bottom — connect between adjacent rings
	# at the bottom center area. The gap is at cx (center column).
	# For bottom-right gaps: passage at cx going from ring r to ring r+1
	# For bottom-left gaps: passage at cx-1 going from ring r to ring r+1

	# Connect rings via radial passages at bottom-center and top-center
	for i in range(num_circuits - 1):
		var r_inner: int = path_radii[i]
		var r_outer: int = path_radii[i + 1]
		var y_bot_inner: int = mini(s - 1, cy + r_inner)
		var y_bot_outer: int = mini(s - 1, cy + r_outer)
		var y_top_inner: int = maxi(0, cy - r_inner)
		var y_top_outer: int = maxi(0, cy - r_outer)

		# Bottom-right gap on inner ring → connect on right side of center
		# Bottom-left gap on inner ring → connect on left side of center
		# Check what gaps exist on ring i and draw radial passages

		# For even-indexed rings (0,2,4,6): gap_br=true → right side connector at bottom
		# For odd-indexed rings (1,3,5): gap_bl=true → left side connector at bottom
		if i % 2 == 0:
			# Right-side bottom connector
			for y in range(y_bot_inner, y_bot_outer + 1):
				grid[y][cx] = true
			# Left-side top connector (gap_tl on even rings)
			for y in range(y_top_outer, y_top_inner + 1):
				grid[y][cx] = true
		else:
			# Left-side bottom connector
			for y in range(y_bot_inner, y_bot_outer + 1):
				grid[y][cx] = true
			# Right-side top connector (gap_tr on odd rings)
			for y in range(y_top_outer, y_top_inner + 1):
				grid[y][cx] = true

	# Entrance passage: from outermost ring bottom to edge of grid
	var r_outer: int = path_radii[num_circuits - 1]
	var y_entrance: int = mini(s - 1, cy + r_outer)
	for y in range(y_entrance, s):
		grid[y][cx] = true

	# Connect center to innermost ring
	var r_inner: int = path_radii[0]
	var y_center_connect: int = maxi(0, cy - r_inner)
	for y in range(y_center_connect, cy + 1):
		grid[y][cx] = true

	return grid


func _build() -> void:
	if _mi:
		_mi.queue_free()
		_mi = null
	if _body:
		_body.queue_free()
		_body = null

	# Grid dimensions
	var border_each: int = 0
	for bw in border_widths:
		border_each += bw

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

	# Field region (inside borders)
	var fx0 := border_each
	var fy0 := border_each
	var fx1 := gw - border_each
	var fy1 := gh - border_each

	var field_w := fx1 - fx0
	var field_h := fy1 - fy0

	# Grout absolute width
	var grout_w := ts * grout_width_fraction

	# Generate the labyrinth grid
	var lab_size := mini(field_w, field_h)
	if lab_size % 2 == 0:
		lab_size -= 1
	lab_size = maxi(lab_size, 15)  # minimum viable labyrinth

	var lab_grid: Array = _generate_classical_labyrinth(lab_size)

	# Offset to center the labyrinth in the field
	var lab_offset_x := fx0 + (field_w - lab_size) / 2
	var lab_offset_y := fy0 + (field_h - lab_size) / 2

	# Build vertex arrays
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

	# ── 1. Border bands: dark(2), light(1), dark(1) ──
	var inset: int = 0
	for i in border_widths.size():
		var bw: int = border_widths[i]
		var is_light: bool = (i % 2 == 1)
		# Draw a rectangular frame of width bw tiles
		var ox := inset * ts
		var oz := inset * ts
		var frame_w := (gw - inset * 2) * ts
		var frame_h := (gh - inset * 2) * ts
		var band_w := bw * ts
		var target := light_verts if is_light else dark_verts
		# Top band
		target = _add_rect.call(target, ox, oz, frame_w, band_w)
		# Bottom band
		target = _add_rect.call(target, ox, oz + frame_h - band_w, frame_w, band_w)
		# Left band (between top and bottom)
		target = _add_rect.call(target, ox, oz + band_w, band_w, frame_h - band_w * 2)
		# Right band
		target = _add_rect.call(target, ox + frame_w - band_w, oz + band_w, band_w, frame_h - band_w * 2)
		if is_light:
			light_verts = target
		else:
			dark_verts = target
		inset += bw

	# ── 2. Labyrinth field ──
	# Fill field background as light (walls), then overlay dark (paths)
	for gy in range(fy0, fy1):
		for gx in range(fx0, fx1):
			var x := gx * ts
			var z := gy * ts
			var lx := gx - lab_offset_x
			var ly := gy - lab_offset_y
			var is_path := false
			if lx >= 0 and lx < lab_size and ly >= 0 and ly < lab_size:
				is_path = lab_grid[ly][lx]
			if is_path:
				dark_verts = _add_rect.call(dark_verts, x, z, ts, ts)
			else:
				light_verts = _add_rect.call(light_verts, x, z, ts, ts)

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

	# ── StaticBody3D with CollisionShape3D ──
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(fw, 0.01, fh)
	col.shape = box
	_body.add_child(col)
	_body.position = Vector3(0, 0.005, 0)
	add_child(_body)

	print("[LabyrinthFloor] Built %dx%d grid, labyrinth %dx%d (%d dark tris, %d light tris, %d grout tris)" % [
		gw, gh, lab_size, lab_size,
		dark_verts.size() / 3,
		light_verts.size() / 3,
		grout_verts.size() / 3,
	])
