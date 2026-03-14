## CompositionPresets
## Preset spatial compositions for common layout types.
## Returns SpatialComposition with zones defined but properties empty —
## consumers fill in their own content per zone.
##
## Presets:
##   carpet  — border, gutter, field, medallion, corners
##   facade  — base, columns, windows, cornice, pediment
##   mosaic  — background, border, panels
##   quilt   — blocks (alternating), sashing, border
##   tunnel  — floor, walls, ceiling, archway

class_name CompositionPresets extends RefCounted

# ═══════════════════════════════════════════════════════════════════
# CARPET — Traditional rug layout
# ═══════════════════════════════════════════════════════════════════

static func carpet(w: int = 20, h: int = 20) -> SpatialComposition:
	var comp := SpatialComposition.new(w, h)

	# Zones ordered by priority (lowest first)
	comp.add_zone("field", CompositionRegion.fill(), {}, 0)
	comp.add_zone("border_outer", CompositionRegion.border(0, 2), {}, 10)
	comp.add_zone("gutter", CompositionRegion.border(2, 1), {}, 20)
	comp.add_zone("border_inner", CompositionRegion.border(3, 1), {}, 15)

	# Medallion in center
	var cx := float(w) / 2.0
	var cy := float(h) / 2.0
	var rx := float(w) * 0.2
	var ry := float(h) * 0.2
	comp.add_zone("medallion", CompositionRegion.ellipse(cx, cy, rx, ry), {}, 30)

	# Corner ornaments
	comp.add_zone("corners", CompositionRegion.corners(0, 3), {}, 25)

	# Default: 4-way symmetry
	comp.add_modifier("kaleidoscope")

	return comp

# ═══════════════════════════════════════════════════════════════════
# FACADE — Architectural building front
# ═══════════════════════════════════════════════════════════════════

static func facade(w: int = 15, h: int = 10) -> SpatialComposition:
	var comp := SpatialComposition.new(w, h)

	# Base/foundation (bottom 2 rows)
	comp.add_zone("base", CompositionRegion.rect(0, h - 2, w, 2), {}, 10)

	# Wall field
	comp.add_zone("wall", CompositionRegion.fill(), {}, 0)

	# Cornice (top row)
	comp.add_zone("cornice", CompositionRegion.rect(0, 0, w, 1), {}, 15)

	# Frieze (second row from top)
	comp.add_zone("frieze", CompositionRegion.rect(0, 1, w, 1), {}, 12)

	# Columns — evenly spaced
	var col_spacing := w / 4
	var col_positions: Array = []
	for i in range(1, 4):
		col_positions.append(i * col_spacing)
	comp.add_zone("columns", CompositionRegion.columns(col_positions, 1, 2, h - 2), {}, 20)

	# Windows — between columns, in upper and lower rows
	var window_y_upper := 3
	var window_y_lower := h - 4
	for i in range(4):
		var wx := i * col_spacing + 1
		if wx + 2 < w:
			comp.add_zone(
				"window_%d_upper" % i,
				CompositionRegion.rect(wx, window_y_upper, 2, 2),
				{"window_tier": "upper"},
				25
			)
			if window_y_lower > window_y_upper + 2:
				comp.add_zone(
					"window_%d_lower" % i,
					CompositionRegion.rect(wx, window_y_lower, 2, 2),
					{"window_tier": "lower"},
					25
				)

	# Door — center bottom
	var door_x := w / 2 - 1
	comp.add_zone("door", CompositionRegion.rect(door_x, h - 4, 2, 4), {}, 30)

	# Mirror symmetry
	comp.add_modifier("mirror_x")

	return comp

# ═══════════════════════════════════════════════════════════════════
# MOSAIC — Paneled display
# ═══════════════════════════════════════════════════════════════════

static func mosaic(w: int = 16, h: int = 16) -> SpatialComposition:
	var comp := SpatialComposition.new(w, h)

	comp.add_zone("background", CompositionRegion.fill(), {}, 0)
	comp.add_zone("border", CompositionRegion.border(0, 1), {}, 10)

	# Create a grid of panels inside the border
	var panel_size := 3
	var gap := 1
	var start_x := 2
	var start_y := 2
	var panel_idx := 0

	var py := start_y
	while py + panel_size <= h - 2:
		var px := start_x
		while px + panel_size <= w - 2:
			comp.add_zone(
				"panel_%d" % panel_idx,
				CompositionRegion.rect(px, py, panel_size, panel_size),
				{"panel_index": panel_idx},
				20
			)
			panel_idx += 1
			px += panel_size + gap
		py += panel_size + gap

	return comp

# ═══════════════════════════════════════════════════════════════════
# QUILT — Alternating blocks with sashing
# ═══════════════════════════════════════════════════════════════════

static func quilt(w: int = 16, h: int = 16) -> SpatialComposition:
	var comp := SpatialComposition.new(w, h)

	comp.add_zone("sashing", CompositionRegion.fill(), {}, 0)
	comp.add_zone("border", CompositionRegion.border(0, 1), {}, 10)

	# Alternating blocks
	var block_size := 3
	var sash_width := 1
	var step := block_size + sash_width
	var block_idx := 0

	var by := 2
	while by + block_size <= h - 2:
		var bx := 2
		while bx + block_size <= w - 2:
			var block_type := "block_a" if (block_idx % 2) == 0 else "block_b"
			comp.add_zone(
				"%s_%d" % [block_type, block_idx],
				CompositionRegion.rect(bx, by, block_size, block_size),
				{"block_type": block_type, "block_index": block_idx},
				20
			)
			block_idx += 1
			bx += step
		by += step

	return comp

# ═══════════════════════════════════════════════════════════════════
# TUNNEL — Walkthrough tube layout (unfolded cross-section)
# ═══════════════════════════════════════════════════════════════════

static func tunnel(w: int = 20, h: int = 10) -> SpatialComposition:
	var comp := SpatialComposition.new(w, h)

	# h is the circumference: floor + left wall + ceiling + right wall
	var quarter := h / 4

	comp.add_zone("floor", CompositionRegion.rect(0, 0, w, quarter), {}, 10)
	comp.add_zone("wall_left", CompositionRegion.rect(0, quarter, w, quarter), {}, 10)
	comp.add_zone("ceiling", CompositionRegion.rect(0, quarter * 2, w, quarter), {}, 10)
	comp.add_zone("wall_right", CompositionRegion.rect(0, quarter * 3, w, h - quarter * 3), {}, 10)

	# Archway keystone at center-top of ceiling
	var arch_x := w / 2 - 1
	comp.add_zone("keystone", CompositionRegion.rect(arch_x, quarter * 2, 2, 1), {}, 25)

	return comp

# ═══════════════════════════════════════════════════════════════════
# LOOKUP
# ═══════════════════════════════════════════════════════════════════

static func get_preset(name: String, w: int = 20, h: int = 20) -> SpatialComposition:
	match name.to_lower():
		"carpet": return carpet(w, h)
		"facade": return facade(w, h)
		"mosaic": return mosaic(w, h)
		"quilt": return quilt(w, h)
		"tunnel": return tunnel(w, h)
		_:
			push_warning("[CompositionPresets] Unknown preset: %s" % name)
			return carpet(w, h)
