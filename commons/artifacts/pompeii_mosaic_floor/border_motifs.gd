# border_motifs.gd
# Composable border motif library for Pompeii mosaic floors.
# Each motif appends triangles to PackedVector3Array buffers.
# All geometry in XZ plane (y=0).

class_name BorderMotifs

enum Motif { SOLID, SAWTOOTH, GUILLOCHE, MEANDER, WAVE_SCROLL }

# Direction constants: which way the strip runs
const DIR_RIGHT = 0  # +X (top edge)
const DIR_DOWN  = 1  # +Z (right edge)
const DIR_LEFT  = 2  # -X (bottom edge)
const DIR_UP    = 3  # -Z (left edge)


## Draw a complete rectangular border frame with a given motif.
## Draws all 4 sides with solid corners.
## Returns { "dark": PackedVector3Array, "light": ..., "terra": ... }
static func draw_border_frame(
	dark_v: PackedVector3Array,
	light_v: PackedVector3Array,
	terra_v: PackedVector3Array,
	x0: float, z0: float,
	frame_w: float, frame_h: float,
	band_w: float, tile_size: float,
	motif: int, reverse_colors: bool = false
) -> Dictionary:
	if band_w <= 0.0 or frame_w <= 0.0 or frame_h <= 0.0:
		return { "dark": dark_v, "light": light_v, "terra": terra_v }

	# Solid corners (band_w x band_w squares at each corner)
	var corner_verts = light_v if reverse_colors else dark_v
	# Top-left corner
	corner_verts = _add_rect_verts(corner_verts, x0, z0, band_w, band_w)
	# Top-right corner
	corner_verts = _add_rect_verts(corner_verts, x0 + frame_w - band_w, z0, band_w, band_w)
	# Bottom-left corner
	corner_verts = _add_rect_verts(corner_verts, x0, z0 + frame_h - band_w, band_w, band_w)
	# Bottom-right corner
	corner_verts = _add_rect_verts(corner_verts, x0 + frame_w - band_w, z0 + frame_h - band_w, band_w, band_w)
	if reverse_colors:
		light_v = corner_verts
	else:
		dark_v = corner_verts

	# Strip lengths (excluding corners)
	var h_len: float = frame_w - band_w * 2  # horizontal strips
	var v_len: float = frame_h - band_w * 2  # vertical strips

	# Top strip (runs right, between corners)
	_draw_strip(dark_v, light_v, terra_v,
		x0 + band_w, z0, h_len, band_w, DIR_RIGHT, tile_size, motif, reverse_colors)
	# Bottom strip (runs right, between corners)
	_draw_strip(dark_v, light_v, terra_v,
		x0 + band_w, z0 + frame_h - band_w, h_len, band_w, DIR_RIGHT, tile_size, motif, reverse_colors)
	# Left strip (runs down, between corners)
	_draw_strip(dark_v, light_v, terra_v,
		x0, z0 + band_w, v_len, band_w, DIR_DOWN, tile_size, motif, reverse_colors)
	# Right strip (runs down, between corners)
	_draw_strip(dark_v, light_v, terra_v,
		x0 + frame_w - band_w, z0 + band_w, v_len, band_w, DIR_DOWN, tile_size, motif, reverse_colors)

	return { "dark": dark_v, "light": light_v, "terra": terra_v }


## Draw a single linear strip with the given motif.
static func _draw_strip(
	dark_v: PackedVector3Array,
	light_v: PackedVector3Array,
	terra_v: PackedVector3Array,
	origin_x: float, origin_z: float,
	strip_length: float, strip_width: float,
	direction: int, tile_size: float,
	motif: int, reverse: bool
) -> void:
	match motif:
		Motif.SOLID:
			_solid_strip(dark_v, light_v, origin_x, origin_z, strip_length, strip_width, direction, reverse)
		Motif.SAWTOOTH:
			_sawtooth_strip(dark_v, light_v, origin_x, origin_z, strip_length, strip_width, direction, tile_size, reverse)
		Motif.GUILLOCHE:
			_guilloche_strip(dark_v, light_v, terra_v, origin_x, origin_z, strip_length, strip_width, direction, tile_size, reverse)
		Motif.MEANDER:
			_meander_strip(dark_v, light_v, origin_x, origin_z, strip_length, strip_width, direction, tile_size, reverse)
		Motif.WAVE_SCROLL:
			_wave_scroll_strip(dark_v, light_v, origin_x, origin_z, strip_length, strip_width, direction, tile_size, reverse)
		_:
			_solid_strip(dark_v, light_v, origin_x, origin_z, strip_length, strip_width, direction, reverse)


# ── Direction transform ──────────────────────────────────────────
# Converts local strip coordinates (px along strip, pz across strip)
# to world XZ coordinates based on direction.

static func _tp(px: float, pz: float, ox: float, oz: float, dir: int) -> Vector3:
	match dir:
		DIR_RIGHT:
			return Vector3(ox + px, 0, oz + pz)
		DIR_DOWN:
			return Vector3(ox + (pz), 0, oz + px)  # swap axes: along=Z, across=X (but strip_width goes right)
		DIR_LEFT:
			return Vector3(ox + px, 0, oz + pz)  # same as RIGHT, caller adjusts origin
		DIR_UP:
			return Vector3(ox + pz, 0, oz + px)
		_:
			return Vector3(ox + px, 0, oz + pz)


# ── Helper: add a flat rect as 2 triangles ───────────────────────

static func _add_rect_verts(v: PackedVector3Array, x: float, z: float, w: float, h: float) -> PackedVector3Array:
	v.append(Vector3(x, 0, z))
	v.append(Vector3(x + w, 0, z))
	v.append(Vector3(x + w, 0, z + h))
	v.append(Vector3(x, 0, z))
	v.append(Vector3(x + w, 0, z + h))
	v.append(Vector3(x, 0, z + h))
	return v


# ── SOLID ────────────────────────────────────────────────────────

static func _solid_strip(
	dark_v: PackedVector3Array, light_v: PackedVector3Array,
	ox: float, oz: float, length: float, width: float,
	direction: int, reverse: bool
) -> void:
	var v = light_v if reverse else dark_v
	if direction == DIR_RIGHT or direction == DIR_LEFT:
		_add_rect_verts(v, ox, oz, length, width)
	else:  # DIR_DOWN or DIR_UP
		_add_rect_verts(v, ox, oz, width, length)


# ── SAWTOOTH ─────────────────────────────────────────────────────
# Zigzag row of right triangles alternating dark/light.

static func _sawtooth_strip(
	dark_v: PackedVector3Array, light_v: PackedVector3Array,
	ox: float, oz: float, length: float, width: float,
	direction: int, tile_size: float, reverse: bool
) -> void:
	var n_teeth: int = maxi(1, int(round(length / tile_size)))
	var tooth_w: float = length / float(n_teeth)

	for i in n_teeth:
		var is_dark: bool = (i % 2 == 0) != reverse
		var v = dark_v if is_dark else light_v
		var v2 = light_v if is_dark else dark_v

		if direction == DIR_RIGHT or direction == DIR_LEFT:
			var tx: float = ox + i * tooth_w
			# Each tooth's bounding rect [tx, tx+tooth_w] × [oz, oz+width] is
			# tiled by exactly 3 triangles: the up-tooth (bottom half-+-tip)
			# plus an upper-left and an upper-right fill (the negative space
			# above the diagonals). All three are needed for every tooth —
			# the corner squares at the strip ends do NOT overlap the strip
			# (they end flush at the strip's start/end), so skipping the end
			# fills leaves visible holes at the corners.
			# Up-tooth (covered by `v`):
			v.append(Vector3(tx, 0, oz + width))
			v.append(Vector3(tx + tooth_w, 0, oz + width))
			v.append(Vector3(tx + tooth_w * 0.5, 0, oz))
			# Upper-left fill (covered by `v2`):
			v2.append(Vector3(tx, 0, oz + width))
			v2.append(Vector3(tx + tooth_w * 0.5, 0, oz))
			v2.append(Vector3(tx, 0, oz))
			# Upper-right fill (covered by `v2`):
			v2.append(Vector3(tx + tooth_w * 0.5, 0, oz))
			v2.append(Vector3(tx + tooth_w, 0, oz + width))
			v2.append(Vector3(tx + tooth_w, 0, oz))
		else:  # DIR_DOWN or DIR_UP
			var tz: float = oz + i * tooth_w
			# Same structure rotated 90°: each tooth's bounding rect
			# [ox, ox+width] × [tz, tz+tooth_w] tiles into the right-tooth
			# plus left-upper + left-lower fills.
			# Right-tooth (covered by `v`):
			v.append(Vector3(ox, 0, tz))
			v.append(Vector3(ox, 0, tz + tooth_w))
			v.append(Vector3(ox + width, 0, tz + tooth_w * 0.5))
			# Upper fill (covered by `v2`):
			v2.append(Vector3(ox, 0, tz))
			v2.append(Vector3(ox + width, 0, tz + tooth_w * 0.5))
			v2.append(Vector3(ox + width, 0, tz))
			# Lower fill (covered by `v2`):
			v2.append(Vector3(ox + width, 0, tz + tooth_w * 0.5))
			v2.append(Vector3(ox, 0, tz + tooth_w))
			v2.append(Vector3(ox + width, 0, tz + tooth_w))


# ── MEANDER (pixel-grid Greek key) ───────────────────────────────

static func _meander_strip(
	dark_v: PackedVector3Array, light_v: PackedVector3Array,
	ox: float, oz: float, length: float, width: float,
	direction: int, tile_size: float, reverse: bool
) -> void:
	# 3-row-tall meander with 6-column repeat
	var pattern := [
		[1, 1, 1, 1, 1, 0],
		[0, 0, 0, 0, 1, 0],
		[0, 1, 1, 1, 1, 0],
	]
	_stamp_pixel_pattern(dark_v, light_v, ox, oz, length, width, direction, tile_size, pattern, reverse)


# ── GUILLOCHE (pixel-grid interlocking S-curves) ─────────────────

static func _guilloche_strip(
	dark_v: PackedVector3Array, light_v: PackedVector3Array,
	terra_v: PackedVector3Array,
	ox: float, oz: float, length: float, width: float,
	direction: int, tile_size: float, reverse: bool
) -> void:
	# 4-row-tall guilloche with 8-column repeat
	# 0=light, 1=dark, 2=terracotta
	var pattern := [
		[0, 1, 1, 0, 0, 1, 1, 0],
		[1, 2, 0, 1, 1, 0, 2, 1],
		[1, 0, 2, 1, 1, 2, 0, 1],
		[0, 1, 1, 0, 0, 1, 1, 0],
	]
	_stamp_pixel_pattern_3color(dark_v, light_v, terra_v, ox, oz, length, width, direction, tile_size, pattern, reverse)


# ── WAVE_SCROLL (pixel-grid running scroll) ──────────────────────

static func _wave_scroll_strip(
	dark_v: PackedVector3Array, light_v: PackedVector3Array,
	ox: float, oz: float, length: float, width: float,
	direction: int, tile_size: float, reverse: bool
) -> void:
	# 3-row-tall wave with 6-column repeat
	var pattern := [
		[0, 1, 1, 1, 0, 0],
		[1, 0, 0, 0, 1, 0],
		[1, 1, 0, 0, 1, 1],
	]
	_stamp_pixel_pattern(dark_v, light_v, ox, oz, length, width, direction, tile_size, pattern, reverse)


# ── Pixel-grid stamping (2-color) ────────────────────────────────

static func _stamp_pixel_pattern(
	dark_v: PackedVector3Array, light_v: PackedVector3Array,
	ox: float, oz: float, length: float, width: float,
	direction: int, tile_size: float,
	pattern: Array, reverse: bool
) -> void:
	var rows: int = pattern.size()
	var cols: int = pattern[0].size() if rows > 0 else 1

	# Pixel size: fit pattern rows into strip width, use tile_size for columns
	var px_w: float = tile_size * 0.5  # each pattern pixel is half a tile
	var px_h: float = width / float(rows)

	# How many repeats fit along the strip
	var repeat_w: float = cols * px_w
	var n_repeats: int = maxi(1, int(ceil(length / repeat_w)))

	for rep in n_repeats:
		for row in rows:
			for col in cols:
				var local_x: float = rep * repeat_w + col * px_w
				if local_x >= length:
					continue
				var local_z: float = row * px_h
				var cell_w: float = minf(px_w, length - local_x)

				var is_dark: bool = (pattern[row][col] == 1) != reverse
				var v = dark_v if is_dark else light_v

				if direction == DIR_RIGHT or direction == DIR_LEFT:
					_add_rect_verts(v, ox + local_x, oz + local_z, cell_w, px_h)
				else:
					_add_rect_verts(v, ox + local_z, oz + local_x, px_h, cell_w)


# ── Pixel-grid stamping (3-color) ────────────────────────────────

static func _stamp_pixel_pattern_3color(
	dark_v: PackedVector3Array, light_v: PackedVector3Array,
	terra_v: PackedVector3Array,
	ox: float, oz: float, length: float, width: float,
	direction: int, tile_size: float,
	pattern: Array, reverse: bool
) -> void:
	var rows: int = pattern.size()
	var cols: int = pattern[0].size() if rows > 0 else 1

	var px_w: float = tile_size * 0.5
	var px_h: float = width / float(rows)

	var repeat_w: float = cols * px_w
	var n_repeats: int = maxi(1, int(ceil(length / repeat_w)))

	for rep in n_repeats:
		for row in rows:
			for col in cols:
				var local_x: float = rep * repeat_w + col * px_w
				if local_x >= length:
					continue
				var local_z: float = row * px_h
				var cell_w: float = minf(px_w, length - local_x)

				var cell_val: int = pattern[row][col]
				if reverse and cell_val < 2:
					cell_val = 1 - cell_val  # swap dark/light but keep terracotta

				var v: PackedVector3Array
				match cell_val:
					0: v = light_v
					1: v = dark_v
					2: v = terra_v
					_: v = light_v

				if direction == DIR_RIGHT or direction == DIR_LEFT:
					_add_rect_verts(v, ox + local_x, oz + local_z, cell_w, px_h)
				else:
					_add_rect_verts(v, ox + local_z, oz + local_x, px_h, cell_w)
