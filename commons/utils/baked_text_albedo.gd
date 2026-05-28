@tool
extends RefCounted
class_name BakedTextAlbedo

## Render arbitrary text into an ImageTexture by drawing glyph bitmaps
## directly into an Image via TextServer. No SubViewport, no render-loop
## dependency, works under --no-window / headless modes.
##
## The result is a transparent-bg image with the text painted in
## text_color (alpha taken from each glyph's coverage mask). Intended
## use is as the albedo of a Decal node projected onto an artifact's
## body — see commons/artifacts/fire_extinguisher for the canonical
## example.
##
## Process-level cache keys on (text + colour + size + font_size) so
## repeated calls with the same args reuse a single ImageTexture.

static var _texture_cache: Dictionary = {}


static func _cache_key(text: String, text_color: Color,
		image_size: Vector2i, font_size: int) -> String:
	return "%s|%s|%dx%d|%d" % [
		text, text_color, image_size.x, image_size.y, font_size]


## Render `text` into a transparent-bg ImageTexture at the given size.
## text_color tints the glyph mask. Image size should be large enough
## to contain the text at the chosen font_size — text is centred.
##
## Returns null if the font is unavailable or the text is empty.
static func generate_text_image(
		text: String,
		text_color: Color = Color.WHITE,
		image_size: Vector2i = Vector2i(512, 256),
		font_size: int = 160) -> ImageTexture:
	if text.is_empty():
		return null
	var key := _cache_key(text, text_color, image_size, font_size)
	if _texture_cache.has(key):
		return _texture_cache[key]

	var font: Font = ThemeDB.fallback_font
	if font == null:
		push_warning("BakedTextAlbedo: no fallback font")
		return null
	var font_rids: Array = font.get_rids()
	if font_rids.is_empty():
		push_warning("BakedTextAlbedo: font has no RIDs")
		return null
	var font_rid: RID = font_rids[0]
	var font_size_v := Vector2i(font_size, 0)

	var ts := TextServerManager.get_primary_interface()
	if ts == null:
		push_warning("BakedTextAlbedo: no TextServer interface")
		return null

	# Target image, fully transparent. set_pixel writes the tinted text.
	var img := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Measure total text width by summing advances. We also collect the
	# glyph data per character so we don't re-query TextServer for each
	# render pass.
	var glyphs: Array = []
	var text_width: float = 0.0
	for c in text:
		var unicode := c.unicode_at(0)
		var gi: int = ts.font_get_glyph_index(font_rid, font_size, unicode, 0)
		if gi == 0:
			# Skip unrenderable codepoints, still advance space-ish.
			text_width += float(font_size) * 0.3
			continue
		# Make sure the glyph is rendered into the atlas cache. This
		# call is idempotent for already-cached glyphs. Signature is
		# (font_rid, size_v: Vector2i, glyph_index: int).
		ts.font_render_glyph(font_rid, font_size_v, gi)
		var advance: Vector2 = ts.font_get_glyph_advance(font_rid, font_size, gi)
		glyphs.append({
			"index": gi,
			"advance": advance,
		})
		text_width += advance.x

	# Centred origin. baseline_y is the glyph baseline — font_get_glyph_offset
	# returns offsets relative to the baseline, with .y typically negative
	# (the glyph rises above its baseline).
	var origin_x: float = (float(image_size.x) - text_width) * 0.5
	var baseline_y: float = float(image_size.y) * 0.5 + float(font_size) * 0.32

	# Blit each glyph from its atlas tile into the target image.
	var cursor_x: float = origin_x
	for g in glyphs:
		var gi: int = g["index"]
		var advance: Vector2 = g["advance"]

		var tex_idx: int = ts.font_get_glyph_texture_idx(font_rid, font_size_v, gi)
		if tex_idx < 0:
			cursor_x += advance.x
			continue
		var atlas: Image = ts.font_get_texture_image(font_rid, font_size_v, tex_idx)
		if atlas == null:
			cursor_x += advance.x
			continue
		var uv: Rect2 = ts.font_get_glyph_uv_rect(font_rid, font_size_v, gi)
		var off: Vector2 = ts.font_get_glyph_offset(font_rid, font_size_v, gi)
		var glyph_w: int = int(uv.size.x)
		var glyph_h: int = int(uv.size.y)
		if glyph_w <= 0 or glyph_h <= 0:
			cursor_x += advance.x
			continue

		var dst_origin_x: int = int(round(cursor_x + off.x))
		var dst_origin_y: int = int(round(baseline_y + off.y))
		var aw: int = atlas.get_width()
		var ah: int = atlas.get_height()

		for gy in range(glyph_h):
			var ay: int = dst_origin_y + gy
			if ay < 0 or ay >= image_size.y:
				continue
			var sy: int = int(uv.position.y) + gy
			if sy < 0 or sy >= ah:
				continue
			for gx in range(glyph_w):
				var ax: int = dst_origin_x + gx
				if ax < 0 or ax >= image_size.x:
					continue
				var sx: int = int(uv.position.x) + gx
				if sx < 0 or sx >= aw:
					continue
				var src_px: Color = atlas.get_pixel(sx, sy)
				# Glyph atlas pixel coverage formula that works across
				# the three formats Godot rasterises into:
				#   L8   — luminance = coverage, alpha = 1.0
				#   LA8  — luminance = 1, alpha = coverage
				#   RGBA — RGB = white in glyph, alpha = coverage
				# Multiplying luminance by alpha collapses to coverage
				# in every case (max RGB gives 1 in LA8/RGBA cases and
				# the actual luminance in L8).
				var lum: float = max(src_px.r, max(src_px.g, src_px.b))
				var coverage: float = lum * src_px.a
				if coverage < 0.02:
					continue
				img.set_pixel(ax, ay, Color(
					text_color.r, text_color.g, text_color.b,
					coverage * text_color.a))

		cursor_x += advance.x

	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex


## Convenience for callers that want to embed the text into an opaque
## panel (band background + text on top). Returns an ImageTexture with
## the bg colour everywhere, a centred horizontal band, and the text
## painted over it. Useful when you want the result to look like a
## printed label patch rather than a decal sticker.
static func generate_panel_image(
		text: String,
		bg_color: Color = Color(0.85, 0.05, 0.05, 1.0),
		text_color: Color = Color.WHITE,
		image_size: Vector2i = Vector2i(512, 256),
		font_size: int = 160,
		band: Dictionary = {}) -> ImageTexture:
	# Render the text mask first (transparent bg).
	var text_tex: ImageTexture = generate_text_image(text, text_color, image_size, font_size)
	if text_tex == null:
		return null
	# Compose: bg + optional band + text mask.
	var panel := Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	panel.fill(bg_color)
	if band.has("color") and band.has("v_min") and band.has("v_max"):
		var band_color: Color = band["color"]
		var v_min: float = float(band["v_min"])
		var v_max: float = float(band["v_max"])
		var y0: int = int(v_min * image_size.y)
		var y1: int = int(v_max * image_size.y)
		for y in range(max(0, y0), min(image_size.y, y1)):
			for x in range(image_size.x):
				panel.set_pixel(x, y, band_color)
	# Blend text mask on top.
	var text_img: Image = text_tex.get_image()
	if text_img != null:
		for y in range(image_size.y):
			for x in range(image_size.x):
				var tpx: Color = text_img.get_pixel(x, y)
				if tpx.a < 0.02:
					continue
				var bpx: Color = panel.get_pixel(x, y)
				var out_r: float = tpx.r * tpx.a + bpx.r * (1.0 - tpx.a)
				var out_g: float = tpx.g * tpx.a + bpx.g * (1.0 - tpx.a)
				var out_b: float = tpx.b * tpx.a + bpx.b * (1.0 - tpx.a)
				panel.set_pixel(x, y, Color(out_r, out_g, out_b, 1.0))
	return ImageTexture.create_from_image(panel)
