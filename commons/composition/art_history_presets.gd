## ArtHistoryPresets
## 20 composition presets inspired by art history traditions.
## Stress-tests the SpatialComposition system with diverse region types,
## zone counts, modifiers, and complexities.
##
## Each preset returns a SpatialComposition with zones defined but properties
## empty — the pattern compositor fills in wallpaper groups per zone.

class_name ArtHistoryPresets extends RefCounted

# Helper — preload the composition script for _make
static var _SC: GDScript

static func _sc():
	if not _SC:
		_SC = load("res://commons/composition/spatial_composition.gd")
	return _SC

# ═══════════════════════════════════════════════════════════════════
# 1. PERSIAN CARPET — Traditional multi-border medallion carpet
#    Inspired by: Isfahan, Tabriz, Kashan carpet traditions
#    Tests: nested borders, ellipse, corners, kaleidoscope
# ═══════════════════════════════════════════════════════════════════

static func persian_carpet(w: int = 24, h: int = 32):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("field", sc.Region.fill(), {}, 0)
	comp.add_zone("guard_outer", sc.Region.border(0, 1), {"palette_index": 0}, 10)
	comp.add_zone("border_main", sc.Region.border(1, 3), {"palette_index": 1}, 15)
	comp.add_zone("guard_inner", sc.Region.border(4, 1), {"palette_index": 2}, 20)
	comp.add_zone("spandrel", sc.Region.border(5, 1), {"palette_index": 3}, 12)
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("medallion_outer", sc.Region.ellipse(cx, cy, float(w) * 0.35, float(h) * 0.25), {"palette_index": 4}, 25)
	comp.add_zone("medallion_inner", sc.Region.ellipse(cx, cy, float(w) * 0.2, float(h) * 0.15), {"palette_index": 6}, 30)
	comp.add_zone("pendant_top", sc.Region.ellipse(cx, cy - float(h) * 0.35, float(w) * 0.1, float(h) * 0.06), {"palette_index": 5}, 28)
	comp.add_zone("pendant_bottom", sc.Region.ellipse(cx, cy + float(h) * 0.35, float(w) * 0.1, float(h) * 0.06), {"palette_index": 5}, 28)
	comp.add_zone("corners", sc.Region.corners(1, 4), {"palette_index": 7}, 22)
	comp.add_modifier("kaleidoscope")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 2. ISLAMIC GEOMETRIC — Star and cross tessellation
#    Inspired by: Alhambra, Mosque of Córdoba
#    Tests: ring, ellipse overlay, high zone count
# ═══════════════════════════════════════════════════════════════════

static func islamic_geometric(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("ground", sc.Region.fill(), {}, 0)
	comp.add_zone("border", sc.Region.border(0, 1), {}, 10)
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	# Concentric rings like a rose window
	comp.add_zone("ring_outer", sc.Region.ring(cx, cy, 7.0, 9.0), {}, 15)
	comp.add_zone("ring_middle", sc.Region.ring(cx, cy, 4.5, 6.5), {}, 20)
	comp.add_zone("ring_inner", sc.Region.ring(cx, cy, 2.0, 4.0), {}, 25)
	comp.add_zone("star_center", sc.Region.ellipse(cx, cy, 2.0, 2.0), {}, 30)
	# Corner stars
	comp.add_zone("corner_star", sc.Region.corners(1, 3), {}, 18)
	comp.add_modifier("kaleidoscope")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 3. ROMAN MOSAIC — Opus tessellatum floor pattern
#    Inspired by: Pompeii, Antioch, Roman villa floors
#    Tests: rect panels in grid, border, many unique zones
# ═══════════════════════════════════════════════════════════════════

static func roman_mosaic(w: int = 24, h: int = 24):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("mortar", sc.Region.fill(), {}, 0)
	comp.add_zone("border_outer", sc.Region.border(0, 2), {}, 10)
	comp.add_zone("border_guilloche", sc.Region.border(2, 1), {}, 15)
	# Central emblema
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("emblema", sc.Region.ellipse(cx, cy, 4.0, 4.0), {}, 35)
	# Surrounding panels (4 quadrants)
	var panel_sz := 4; var idx := 0
	var py := 4
	while py + panel_sz <= h - 4:
		var px := 4
		while px + panel_sz <= w - 4:
			# Skip if overlapping center
			var pcx := float(px) + float(panel_sz) / 2.0
			var pcy := float(py) + float(panel_sz) / 2.0
			var dist := sqrt((pcx - cx) * (pcx - cx) + (pcy - cy) * (pcy - cy))
			if dist > 5.0:
				comp.add_zone("panel_%d" % idx, sc.Region.make_rect(px, py, panel_sz, panel_sz), {"panel_index": idx}, 20)
				idx += 1
			px += panel_sz + 1
		py += panel_sz + 1
	comp.add_zone("corners", sc.Region.corners(0, 3), {}, 25)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 4. ART DECO — Geometric sunburst / fan motif
#    Inspired by: Chrysler Building, Empire State, 1920s
#    Tests: stripes, columns, rect, mirror_x
# ═══════════════════════════════════════════════════════════════════

static func art_deco(w: int = 20, h: int = 28):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("background", sc.Region.fill(), {}, 0)
	# Vertical columns (pilasters)
	var col_positions: Array = [0, 4, 9, 14, 19]
	comp.add_zone("pilasters", sc.Region.columns(col_positions, 1, 0, h), {}, 15)
	# Horizontal bands
	comp.add_zone("frieze_top", sc.Region.stripe("y", 0, 2), {}, 20)
	comp.add_zone("frieze_mid", sc.Region.stripe("y", h / 2 - 1, 2), {}, 20)
	comp.add_zone("frieze_bottom", sc.Region.stripe("y", h - 2, 2), {}, 20)
	# Sunburst center
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("sunburst", sc.Region.ellipse(cx, cy, 5.0, 5.0), {}, 25)
	comp.add_zone("sunburst_core", sc.Region.ellipse(cx, cy, 2.0, 2.0), {}, 30)
	# Chevron corners
	comp.add_zone("corners", sc.Region.corners(0, 5), {}, 22)
	comp.add_modifier("mirror_x")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 5. DE STIJL — Mondrian-inspired primary color blocks
#    Inspired by: Piet Mondrian, Theo van Doesburg
#    Tests: many overlapping rects, no modifiers (asymmetric)
# ═══════════════════════════════════════════════════════════════════

static func de_stijl(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("white", sc.Region.fill(), {}, 0)
	# Black grid lines
	comp.add_zone("grid_v1", sc.Region.stripe("x", 4, 1), {}, 10)
	comp.add_zone("grid_v2", sc.Region.stripe("x", 12, 1), {}, 10)
	comp.add_zone("grid_v3", sc.Region.stripe("x", 16, 1), {}, 10)
	comp.add_zone("grid_h1", sc.Region.stripe("y", 3, 1), {}, 10)
	comp.add_zone("grid_h2", sc.Region.stripe("y", 8, 1), {}, 10)
	comp.add_zone("grid_h3", sc.Region.stripe("y", 14, 1), {}, 10)
	# Color blocks
	comp.add_zone("red_block", sc.Region.make_rect(0, 0, 4, 3), {"color": "red"}, 5)
	comp.add_zone("blue_block", sc.Region.make_rect(13, 9, 3, 5), {"color": "blue"}, 5)
	comp.add_zone("yellow_block", sc.Region.make_rect(17, 15, 3, 5), {"color": "yellow"}, 5)
	comp.add_zone("red_block_2", sc.Region.make_rect(5, 15, 7, 5), {"color": "red2"}, 5)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 6. BAUHAUS — Geometric abstraction / Klee grid
#    Inspired by: Paul Klee, Josef Albers, Wassily Kandinsky
#    Tests: dense rect grid, rotate_180
# ═══════════════════════════════════════════════════════════════════

static func bauhaus(w: int = 16, h: int = 16):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("canvas", sc.Region.fill(), {}, 0)
	# 4x4 block grid
	var block := 3; var gap := 1; var idx := 0
	var by := 1
	while by + block <= h - 1:
		var bx := 1
		while bx + block <= w - 1:
			comp.add_zone("cell_%d" % idx, sc.Region.make_rect(bx, by, block, block), {"panel_index": idx}, 20)
			idx += 1; bx += block + gap
		by += block + gap
	# Center circle overlay
	comp.add_zone("circle", sc.Region.ellipse(float(w) / 2.0, float(h) / 2.0, 3.0, 3.0), {}, 30)
	comp.add_modifier("rotate_180")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 7. CELTIC KNOT — Interlacing border pattern
#    Inspired by: Book of Kells, Irish crosses
#    Tests: nested borders, thick border zones, mirror_x + mirror_y
# ═══════════════════════════════════════════════════════════════════

static func celtic_knot(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("field", sc.Region.fill(), {}, 0)
	comp.add_zone("border_1", sc.Region.border(0, 1), {}, 10)
	comp.add_zone("interlace_1", sc.Region.border(1, 2), {}, 15)
	comp.add_zone("gap_1", sc.Region.border(3, 1), {}, 8)
	comp.add_zone("interlace_2", sc.Region.border(4, 2), {}, 15)
	comp.add_zone("gap_2", sc.Region.border(6, 1), {}, 8)
	# Central cross
	comp.add_zone("cross_h", sc.Region.stripe("y", h / 2 - 1, 2), {}, 20)
	comp.add_zone("cross_v", sc.Region.stripe("x", w / 2 - 1, 2), {}, 20)
	# Center knot
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("knot", sc.Region.ellipse(cx, cy, 2.5, 2.5), {}, 25)
	comp.add_modifier("mirror_x")
	comp.add_modifier("mirror_y")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 8. JAPANESE SASHIKO — Stitched textile grid
#    Inspired by: Edo period quilted cotton, hitomezashi
#    Tests: columns, stripes, many thin zones
# ═══════════════════════════════════════════════════════════════════

static func sashiko(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("indigo", sc.Region.fill(), {}, 0)
	# Stitch grid — alternating vertical and horizontal lines
	for i in range(0, w, 2):
		comp.add_zone("stitch_v_%d" % i, sc.Region.stripe("x", i, 1), {}, 10)
	for j in range(0, h, 2):
		comp.add_zone("stitch_h_%d" % j, sc.Region.stripe("y", j, 1), {}, 10)
	# Reinforced corners (patches)
	comp.add_zone("patch_tl", sc.Region.make_rect(0, 0, 4, 4), {}, 15)
	comp.add_zone("patch_br", sc.Region.make_rect(w - 4, h - 4, 4, 4), {}, 15)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 9. BYZANTINE ICON — Central figure surrounded by border scenes
#    Inspired by: Hagia Sophia, Ravenna mosaics, Russian icons
#    Tests: ellipse, rect panels around perimeter, border
# ═══════════════════════════════════════════════════════════════════

static func byzantine(w: int = 20, h: int = 24):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("gold_ground", sc.Region.fill(), {}, 0)
	comp.add_zone("border", sc.Region.border(0, 1), {}, 10)
	# Central icon frame
	comp.add_zone("icon_frame", sc.Region.make_rect(5, 3, 10, 14), {}, 15)
	comp.add_zone("halo", sc.Region.ellipse(float(w) / 2.0, 8.0, 3.5, 3.5), {}, 25)
	comp.add_zone("figure", sc.Region.make_rect(7, 5, 6, 10), {}, 20)
	# Side panels (narrative scenes)
	comp.add_zone("scene_left", sc.Region.make_rect(1, 3, 3, 6), {"panel_index": 0}, 18)
	comp.add_zone("scene_right", sc.Region.make_rect(w - 4, 3, 3, 6), {"panel_index": 1}, 18)
	# Predella (bottom panels)
	for i in range(4):
		var px := 2 + i * 4
		if px + 3 <= w - 2:
			comp.add_zone("predella_%d" % i, sc.Region.make_rect(px, h - 5, 3, 3), {"panel_index": i + 2}, 18)
	# Top inscription band
	comp.add_zone("inscription", sc.Region.stripe("y", 1, 1), {}, 12)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 10. NAVAJO WEAVING — Striped fields with stepped diamonds
#     Inspired by: Chief's blankets, Eye Dazzler textiles
#     Tests: stripes, ellipse, corners, mirror_y
# ═══════════════════════════════════════════════════════════════════

static func navajo_weaving(w: int = 20, h: int = 28):
	var sc = _sc()
	var comp = sc._make(w, h)
	# Horizontal bands
	comp.add_zone("band_bg", sc.Region.fill(), {}, 0)
	var band_h := 4; var idx := 0
	for by in range(0, h, band_h):
		var band_type := "band_a" if idx % 2 == 0 else "band_b"
		comp.add_zone("%s_%d" % [band_type, idx], sc.Region.make_rect(0, by, w, band_h), {"block_type": band_type, "block_index": idx}, 5)
		idx += 1
	# Central diamond
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("diamond_outer", sc.Region.ellipse(cx, cy, 6.0, 8.0), {}, 20)
	comp.add_zone("diamond_inner", sc.Region.ellipse(cx, cy, 3.0, 4.0), {}, 25)
	# Border stripes
	comp.add_zone("edge_left", sc.Region.stripe("x", 0, 1), {}, 15)
	comp.add_zone("edge_right", sc.Region.stripe("x", w - 1, 1), {}, 15)
	comp.add_modifier("mirror_y")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 11. CHINESE LATTICE — Window screen fretwork
#     Inspired by: Ming dynasty window screens, ice-ray patterns
#     Tests: columns, many stripes, dense grid
# ═══════════════════════════════════════════════════════════════════

static func chinese_lattice(w: int = 24, h: int = 24):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("void", sc.Region.fill(), {}, 0)
	comp.add_zone("frame", sc.Region.border(0, 2), {}, 10)
	# Grid lattice
	for i in range(3, w - 3, 3):
		comp.add_zone("lat_v_%d" % i, sc.Region.stripe("x", i, 1), {}, 15)
	for j in range(3, h - 3, 3):
		comp.add_zone("lat_h_%d" % j, sc.Region.stripe("y", j, 1), {}, 15)
	# Central rosette
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("rosette", sc.Region.ring(cx, cy, 3.0, 5.0), {}, 25)
	comp.add_zone("rosette_center", sc.Region.ellipse(cx, cy, 3.0, 3.0), {}, 30)
	# Corner ornaments
	comp.add_zone("corners", sc.Region.corners(2, 4), {}, 22)
	comp.add_modifier("kaleidoscope")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 12. GOTHIC ROSE WINDOW — Radial tracery
#     Inspired by: Notre-Dame, Chartres Cathedral
#     Tests: concentric rings, ellipse, ring, kaleidoscope
# ═══════════════════════════════════════════════════════════════════

static func gothic_rose(w: int = 24, h: int = 24):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("stone", sc.Region.fill(), {}, 0)
	comp.add_zone("frame", sc.Region.border(0, 1), {}, 10)
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	# Concentric rings of tracery
	comp.add_zone("tracery_outer", sc.Region.ring(cx, cy, 9.0, 11.0), {}, 15)
	comp.add_zone("glass_outer", sc.Region.ring(cx, cy, 7.0, 9.0), {}, 20)
	comp.add_zone("tracery_middle", sc.Region.ring(cx, cy, 5.5, 7.0), {}, 15)
	comp.add_zone("glass_middle", sc.Region.ring(cx, cy, 3.5, 5.5), {}, 22)
	comp.add_zone("tracery_inner", sc.Region.ring(cx, cy, 2.5, 3.5), {}, 15)
	comp.add_zone("oculus", sc.Region.ellipse(cx, cy, 2.5, 2.5), {}, 30)
	# Spandrel corners
	comp.add_zone("spandrel", sc.Region.corners(0, 5), {}, 12)
	comp.add_modifier("kaleidoscope")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 13. KENTE CLOTH — Warp and weft strip weaving
#     Inspired by: Ashanti/Ewe Kente from Ghana
#     Tests: columns, stripes, many zones per strip
# ═══════════════════════════════════════════════════════════════════

static func kente_cloth(w: int = 24, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("warp", sc.Region.fill(), {}, 0)
	# Vertical strips (warp strips of a kente loom)
	var strip_w := 3; var idx := 0
	for sx in range(0, w, strip_w + 1):
		var strip_type := "strip_a" if idx % 3 == 0 else ("strip_b" if idx % 3 == 1 else "strip_c")
		comp.add_zone("%s_%d" % [strip_type, idx], sc.Region.make_rect(sx, 0, strip_w, h), {"block_type": strip_type, "block_index": idx}, 10)
		idx += 1
	# Weft accent bands
	for by in range(2, h - 2, 5):
		comp.add_zone("weft_%d" % by, sc.Region.stripe("y", by, 2), {"block_index": by}, 20)
	# Separator lines
	for sx in range(strip_w, w, strip_w + 1):
		comp.add_zone("sep_%d" % sx, sc.Region.stripe("x", sx, 1), {}, 5)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 14. MOROCCAN ZELLIGE — Star-and-cross tile mosaic
#     Inspired by: Fez, Marrakech zellige tilework
#     Tests: ring + ellipse pattern on grid, kaleidoscope
# ═══════════════════════════════════════════════════════════════════

static func zellige(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("grout", sc.Region.fill(), {}, 0)
	comp.add_zone("border", sc.Region.border(0, 1), {}, 10)
	# Star at center
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("star_8", sc.Region.ellipse(cx, cy, 4.0, 4.0), {}, 25)
	comp.add_zone("star_core", sc.Region.ellipse(cx, cy, 1.5, 1.5), {}, 30)
	# Cross arms
	comp.add_zone("cross_h", sc.Region.make_rect(2, int(cy) - 1, w - 4, 2), {}, 15)
	comp.add_zone("cross_v", sc.Region.make_rect(int(cx) - 1, 2, 2, h - 4), {}, 15)
	# Corner stars
	comp.add_zone("corner_tl", sc.Region.ellipse(3.0, 3.0, 2.0, 2.0), {}, 20)
	comp.add_zone("corner_tr", sc.Region.ellipse(float(w) - 3.0, 3.0, 2.0, 2.0), {}, 20)
	comp.add_zone("corner_bl", sc.Region.ellipse(3.0, float(h) - 3.0, 2.0, 2.0), {}, 20)
	comp.add_zone("corner_br", sc.Region.ellipse(float(w) - 3.0, float(h) - 3.0, 2.0, 2.0), {}, 20)
	comp.add_modifier("kaleidoscope")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 15. AZTEC CALENDAR — Concentric rings with radial divisions
#     Inspired by: Sun Stone, Mesoamerican cosmology
#     Tests: 5+ rings, ellipse, high priority layering
# ═══════════════════════════════════════════════════════════════════

static func aztec_calendar(w: int = 24, h: int = 24):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("stone", sc.Region.fill(), {}, 0)
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	# 6 concentric rings
	comp.add_zone("ring_6", sc.Region.ring(cx, cy, 10.0, 11.5), {}, 10)
	comp.add_zone("ring_5", sc.Region.ring(cx, cy, 8.0, 10.0), {}, 15)
	comp.add_zone("ring_4", sc.Region.ring(cx, cy, 6.0, 8.0), {}, 20)
	comp.add_zone("ring_3", sc.Region.ring(cx, cy, 4.0, 6.0), {}, 25)
	comp.add_zone("ring_2", sc.Region.ring(cx, cy, 2.0, 4.0), {}, 30)
	comp.add_zone("sun_face", sc.Region.ellipse(cx, cy, 2.0, 2.0), {}, 35)
	# Cardinal points
	comp.add_zone("north", sc.Region.make_rect(int(cx) - 1, 0, 2, 2), {}, 40)
	comp.add_zone("south", sc.Region.make_rect(int(cx) - 1, h - 2, 2, 2), {}, 40)
	comp.add_zone("east", sc.Region.make_rect(w - 2, int(cy) - 1, 2, 2), {}, 40)
	comp.add_zone("west", sc.Region.make_rect(0, int(cy) - 1, 2, 2), {}, 40)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 16. VICTORIAN TILE — Encaustic floor tile pattern
#     Inspired by: Minton tiles, Albert Memorial, Gothic Revival
#     Tests: dense rect grid with alternating types, border
# ═══════════════════════════════════════════════════════════════════

static func victorian_tile(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("grout", sc.Region.fill(), {}, 0)
	comp.add_zone("border_outer", sc.Region.border(0, 1), {}, 10)
	comp.add_zone("border_key", sc.Region.border(1, 1), {}, 15)
	# Tile grid — alternating large and small tiles
	var idx := 0
	var py := 3
	while py + 2 <= h - 3:
		var px := 3
		while px + 2 <= w - 3:
			var tile_type := "tile_a" if (idx % 3) == 0 else ("tile_b" if (idx % 3) == 1 else "tile_c")
			comp.add_zone("%s_%d" % [tile_type, idx], sc.Region.make_rect(px, py, 2, 2), {"block_type": tile_type, "block_index": idx}, 20)
			idx += 1; px += 3
		py += 3
	# Center feature tile
	var cx := int(float(w) / 2.0) - 1; var cy := int(float(h) / 2.0) - 1
	comp.add_zone("feature", sc.Region.make_rect(cx, cy, 3, 3), {}, 30)
	comp.add_modifier("kaleidoscope")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 17. QUILTING BEE — Log cabin quilt block
#     Inspired by: American folk quilt traditions, Amish quilts
#     Tests: concentric rects building outward, mirror
# ═══════════════════════════════════════════════════════════════════

static func log_cabin_quilt(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("batting", sc.Region.fill(), {}, 0)
	comp.add_zone("sashing", sc.Region.border(0, 1), {}, 5)
	# Log cabin — concentric borders representing fabric strips
	comp.add_zone("log_1", sc.Region.border(1, 1), {}, 10)
	comp.add_zone("log_2", sc.Region.border(2, 1), {}, 15)
	comp.add_zone("log_3", sc.Region.border(3, 1), {}, 20)
	comp.add_zone("log_4", sc.Region.border(4, 1), {}, 25)
	comp.add_zone("log_5", sc.Region.border(5, 1), {}, 30)
	comp.add_zone("log_6", sc.Region.border(6, 1), {}, 35)
	comp.add_zone("log_7", sc.Region.border(7, 1), {}, 40)
	# Center hearth
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("hearth", sc.Region.ellipse(cx, cy, 2.0, 2.0), {}, 50)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 18. AFRICAN MUD CLOTH — Bògòlanfini geometric patterns
#     Inspired by: Malian Bamana textiles
#     Tests: stripes + rect blocks + no symmetry
# ═══════════════════════════════════════════════════════════════════

static func mud_cloth(w: int = 18, h: int = 28):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("cloth", sc.Region.fill(), {}, 0)
	# Horizontal row divisions
	var band_h := 4; var idx := 0
	for by in range(0, h, band_h):
		comp.add_zone("band_%d" % idx, sc.Region.make_rect(0, by, w, band_h), {"block_type": "band", "block_index": idx}, 5)
		idx += 1
	# Symbolic blocks within bands
	idx = 0
	for by in range(1, h - 3, band_h):
		for bx in range(1, w - 3, 4):
			comp.add_zone("symbol_%d" % idx, sc.Region.make_rect(bx, by, 3, 2), {"panel_index": idx}, 15)
			idx += 1
	# Edge trim
	comp.add_zone("trim_left", sc.Region.stripe("x", 0, 1), {}, 20)
	comp.add_zone("trim_right", sc.Region.stripe("x", w - 1, 1), {}, 20)
	return comp

# ═══════════════════════════════════════════════════════════════════
# 19. PALAZZO FLOOR — Italian Renaissance marble inlay
#     Inspired by: Siena Cathedral, Palazzo Ducale, Cosmati
#     Tests: ring + ellipse + rect combination, mirror_x + mirror_y
# ═══════════════════════════════════════════════════════════════════

static func palazzo_floor(w: int = 24, h: int = 24):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("marble_white", sc.Region.fill(), {}, 0)
	comp.add_zone("border_band", sc.Region.border(0, 2), {}, 10)
	comp.add_zone("border_inner", sc.Region.border(2, 1), {}, 15)
	# Central rondel
	var cx := float(w) / 2.0; var cy := float(h) / 2.0
	comp.add_zone("rondel_outer", sc.Region.ring(cx, cy, 5.0, 7.0), {}, 20)
	comp.add_zone("rondel_inner", sc.Region.ellipse(cx, cy, 5.0, 5.0), {}, 25)
	comp.add_zone("rondel_core", sc.Region.ellipse(cx, cy, 2.5, 2.5), {}, 30)
	# Cosmati panels in corners
	comp.add_zone("cosm_tl", sc.Region.make_rect(3, 3, 4, 4), {"panel_index": 0}, 18)
	comp.add_zone("cosm_tr", sc.Region.make_rect(w - 7, 3, 4, 4), {"panel_index": 1}, 18)
	comp.add_zone("cosm_bl", sc.Region.make_rect(3, h - 7, 4, 4), {"panel_index": 2}, 18)
	comp.add_zone("cosm_br", sc.Region.make_rect(w - 7, h - 7, 4, 4), {"panel_index": 3}, 18)
	# Axis lines
	comp.add_zone("axis_h", sc.Region.stripe("y", int(cy), 1), {}, 12)
	comp.add_zone("axis_v", sc.Region.stripe("x", int(cx), 1), {}, 12)
	comp.add_modifier("mirror_x")
	comp.add_modifier("mirror_y")
	return comp

# ═══════════════════════════════════════════════════════════════════
# 20. PIXEL ART QUILT — Modern digital patchwork (Art to Eat style)
#     Inspired by: Art to Eat installation, pixel art, 8-bit aesthetics
#     Tests: max zone count, small blocks, no modifiers
# ═══════════════════════════════════════════════════════════════════

static func pixel_quilt(w: int = 20, h: int = 20):
	var sc = _sc()
	var comp = sc._make(w, h)
	comp.add_zone("bg", sc.Region.fill(), {}, 0)
	# Dense 2x2 pixel blocks — maximizes zone count
	var idx := 0
	var block := 2
	for by in range(0, h, block):
		for bx in range(0, w, block):
			comp.add_zone("px_%d" % idx, sc.Region.make_rect(bx, by, block, block), {"panel_index": idx}, 10)
			idx += 1
	return comp

# ═══════════════════════════════════════════════════════════════════
# CATALOG & LOOKUP
# ═══════════════════════════════════════════════════════════════════

const PRESET_NAMES: Array = [
	"persian_carpet", "islamic_geometric", "roman_mosaic", "art_deco",
	"de_stijl", "bauhaus", "celtic_knot", "sashiko",
	"byzantine", "navajo_weaving", "chinese_lattice", "gothic_rose",
	"kente_cloth", "zellige", "aztec_calendar", "victorian_tile",
	"log_cabin_quilt", "mud_cloth", "palazzo_floor", "pixel_quilt",
]

static func get_preset(name: String, w: int = 20, h: int = 20):
	match name.to_lower():
		"persian_carpet": return persian_carpet(w, h)
		"islamic_geometric": return islamic_geometric(w, h)
		"roman_mosaic": return roman_mosaic(w, h)
		"art_deco": return art_deco(w, h)
		"de_stijl": return de_stijl(w, h)
		"bauhaus": return bauhaus(w, h)
		"celtic_knot": return celtic_knot(w, h)
		"sashiko": return sashiko(w, h)
		"byzantine": return byzantine(w, h)
		"navajo_weaving": return navajo_weaving(w, h)
		"chinese_lattice": return chinese_lattice(w, h)
		"gothic_rose": return gothic_rose(w, h)
		"kente_cloth": return kente_cloth(w, h)
		"zellige": return zellige(w, h)
		"aztec_calendar": return aztec_calendar(w, h)
		"victorian_tile": return victorian_tile(w, h)
		"log_cabin_quilt": return log_cabin_quilt(w, h)
		"mud_cloth": return mud_cloth(w, h)
		"palazzo_floor": return palazzo_floor(w, h)
		"pixel_quilt": return pixel_quilt(w, h)
		_:
			push_warning("[ArtHistoryPresets] Unknown preset: %s" % name)
			return persian_carpet(w, h)
